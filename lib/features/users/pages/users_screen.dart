import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../bloc/users_bloc.dart';
import '../models/users_model.dart';
import '../repository/users_repository.dart';
import '../widgets/booking_history_section.dart';
import '../widgets/live_tracking_section.dart';
import '../widgets/offers_used_section.dart';
import '../widgets/payment_history_section.dart';
import '../widgets/saved_locations_section.dart';
import '../widgets/user_details_panel.dart';
import '../widgets/users_header.dart';
import '../widgets/users_overview_cards.dart';
import '../widgets/users_table.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final UsersBloc _usersBloc;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usersBloc = UsersBloc(repository: UsersRepository())
      ..add(const UsersRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usersBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _usersBloc,
      child: BlocBuilder<UsersBloc, UsersState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UsersHeader(
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                ),
                SizedBox(height: AppSpacing.xl),
                switch (state) {
                  UsersLoading() || UsersInitial() => const _UsersStateCard(
                    title: 'Loading users',
                    message: 'Fetching users from Supabase.',
                    isLoading: true,
                  ),
                  UsersEmpty() => const _UsersStateCard(
                    title: 'No users found',
                    message: 'The user table does not have any records yet.',
                  ),
                  UsersFailure(:final message) => _UsersStateCard(
                    title: 'Unable to load users',
                    message: message,
                    icon: Icons.error_outline,
                  ),
                  UsersSuccess() => _UsersSuccessView(
                    state: state,
                    searchQuery: _searchController.text,
                  ),
                },
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UsersSuccessView extends StatelessWidget {
  const _UsersSuccessView({required this.state, required this.searchQuery});

  final UsersSuccess state;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final filteredUsers = filterUsersForUsersScreen(state.users, searchQuery);
    final selectedUser = state.selectedUser;
    final filteredSelectedIndex = selectedUser == null
        ? null
        : filteredUsers.indexWhere((user) => user.id == selectedUser.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UsersOverviewCards(users: state.users),
        SizedBox(height: AppSpacing.xl),
        UsersTable(
          users: filteredUsers,
          selectedIndex: filteredSelectedIndex ?? -1,
          onUserSelected: (index) {
            final selectedFilteredUser = filteredUsers[index];
            final sourceIndex = state.users.indexWhere(
              (user) => user.id == selectedFilteredUser.id,
            );
            if (sourceIndex == -1) {
              return;
            }

            context.read<UsersBloc>().add(UserSelected(sourceIndex));
          },
        ),
        SizedBox(height: AppSpacing.xl),
        _UserDetailsContent(
          user: selectedUser,
          detailsStatus: state.detailsStatus,
          detailsError: state.detailsError,
        ),
      ],
    );
  }
}

List<UserAdminViewData> filterUsersForUsersScreen(
  List<UserAdminViewData> users,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return users;
  }

  return users.where((user) {
    return user.name.toLowerCase().contains(normalizedQuery) ||
        user.phone.toLowerCase().contains(normalizedQuery) ||
        user.email.toLowerCase().contains(normalizedQuery);
  }).toList();
}

class _UserDetailsContent extends StatelessWidget {
  const _UserDetailsContent({
    required this.user,
    required this.detailsStatus,
    this.detailsError,
  });

  final UserAdminViewData? user;
  final UserDetailsStatus detailsStatus;
  final String? detailsError;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const _UsersStateCard(
        title: 'Select a user',
        message: 'Click View to load user details.',
      );
    }

    return switch (detailsStatus) {
      UserDetailsStatus.loading => const _UsersStateCard(
        title: 'Loading user details',
        message: 'Fetching profile activity, locations, bookings and payments.',
        isLoading: true,
      ),
      UserDetailsStatus.failure => _UsersStateCard(
        title: 'Unable to load user details',
        message: detailsError ?? 'Please try selecting this user again.',
        icon: Icons.error_outline,
      ),
      UserDetailsStatus.initial ||
      UserDetailsStatus.success => _UserDetailsShell(
        user: user!,
        child: _UserDetailsLayout(user: user!),
      ),
    };
  }
}

class _UserDetailsShell extends StatelessWidget {
  const _UserDetailsShell({required this.user, required this.child});

  final UserAdminViewData user;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailsHeader(user: user),
        SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.user});

  final UserAdminViewData user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Selected User', style: AppTextStyles.headingMedium),
          _HeaderPill(Icons.person_outline, user.name),
          _HeaderPill(Icons.phone_outlined, user.phone),
          _HeaderPill(
            Icons.event_note_outlined,
            '${user.bookingsCount} bookings',
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 260.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.r, color: AppColors.textMuted),
          SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDetailsLayout extends StatelessWidget {
  const _UserDetailsLayout({required this.user});

  final UserAdminViewData user;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    if (isDesktop) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: UserDetailsPanel(user: user)),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 3,
                child: LiveTrackingSection(tracking: user.liveTracking),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          SavedLocationsSection(locations: user.savedLocations),
          SizedBox(height: AppSpacing.lg),
          BookingHistorySection(bookings: user.bookingHistory),
          SizedBox(height: AppSpacing.lg),
          PaymentHistorySection(payments: user.paymentHistory),
          SizedBox(height: AppSpacing.lg),
          OffersUsedSection(offers: user.offersUsed),
        ],
      );
    }

    return Column(
      children: [
        UserDetailsPanel(user: user),
        SizedBox(height: AppSpacing.lg),
        LiveTrackingSection(tracking: user.liveTracking),
        SizedBox(height: AppSpacing.lg),
        SavedLocationsSection(locations: user.savedLocations),
        SizedBox(height: AppSpacing.lg),
        BookingHistorySection(bookings: user.bookingHistory),
        SizedBox(height: AppSpacing.lg),
        PaymentHistorySection(payments: user.paymentHistory),
        SizedBox(height: AppSpacing.lg),
        OffersUsedSection(offers: user.offersUsed),
      ],
    );
  }
}

class _UsersStateCard extends StatelessWidget {
  const _UsersStateCard({
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.isLoading = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.05),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 24.r,
              height: 24.r,
              child: CircularProgressIndicator(strokeWidth: 3.r),
            )
          else
            Icon(icon, color: AppColors.primaryBlue, size: 24.r),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingMedium),
                SizedBox(height: 6.h),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
