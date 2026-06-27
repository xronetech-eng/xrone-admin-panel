import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../bloc/pilots_bloc.dart';
import '../models/pilots_model.dart';
import '../repository/pilots_repository.dart';
import '../widgets/active_bookings_section.dart';
import '../widgets/bank_documents_section.dart';
import '../widgets/booking_history_section.dart';
import '../widgets/drones_section.dart';
import '../widgets/earnings_section.dart';
import '../widgets/invitations_section.dart';
import '../widgets/license_section.dart';
import '../widgets/live_tracking_section.dart';
import '../widgets/pilot_details_panel.dart';
import '../widgets/pilots_header.dart';
import '../widgets/pilots_overview_cards.dart';
import '../widgets/pilots_table.dart';
import '../widgets/services_section.dart';
import '../widgets/transactions_section.dart';
import '../widgets/wallet_history_section.dart';

class PilotsScreen extends StatefulWidget {
  const PilotsScreen({super.key});

  @override
  State<PilotsScreen> createState() => _PilotsScreenState();
}

class _PilotsScreenState extends State<PilotsScreen> {
  late final PilotsBloc _pilotsBloc;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pilotsBloc = PilotsBloc(repository: PilotsRepository())
      ..add(const PilotsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pilotsBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _pilotsBloc,
      child: BlocBuilder<PilotsBloc, PilotsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PilotsHeader(
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                ),
                SizedBox(height: AppSpacing.xl),
                switch (state) {
                  PilotsInitial() || PilotsLoading() => const _PilotsStateCard(
                    title: 'Loading pilots',
                    message: 'Fetching pilots from Supabase.',
                    isLoading: true,
                  ),
                  PilotsRefreshing(:final pilots, :final selectedIndex) =>
                    _PilotsSuccessView(
                      pilots: pilots,
                      selectedIndex: selectedIndex,
                      detailsStatus: PilotDetailsStatus.refreshing,
                      searchQuery: _searchController.text,
                    ),
                  PilotsError(:final message) => _PilotsStateCard(
                    title: 'Unable to load pilots',
                    message: message,
                    icon: Icons.error_outline,
                  ),
                  PilotsLoaded() => _PilotsSuccessView(
                    pilots: state.pilots,
                    selectedIndex: state.selectedIndex,
                    detailsStatus: state.detailsStatus,
                    detailsError: state.detailsError,
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

class _PilotsSuccessView extends StatelessWidget {
  const _PilotsSuccessView({
    required this.pilots,
    required this.selectedIndex,
    required this.detailsStatus,
    required this.searchQuery,
    this.detailsError,
  });

  final List<PilotAdminViewData> pilots;
  final int? selectedIndex;
  final PilotDetailsStatus detailsStatus;
  final String searchQuery;
  final String? detailsError;

  @override
  Widget build(BuildContext context) {
    if (pilots.isEmpty) {
      return const _PilotsStateCard(
        title: 'No pilots found',
        message: 'The pilot table does not have any records yet.',
      );
    }

    final filteredPilots = filterPilotsForPilotsScreen(pilots, searchQuery);
    final selectedPilot = _selectedPilot;
    final filteredSelectedIndex = selectedPilot == null
        ? null
        : filteredPilots.indexWhere((pilot) => pilot.id == selectedPilot.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PilotsOverviewCards(pilots: pilots),
        SizedBox(height: AppSpacing.xl),
        if (filteredPilots.isEmpty)
          const _PilotsStateCard(
            title: 'No matching pilots',
            message: 'Try a different name, phone, or email search.',
          )
        else
          PilotsTable(
            pilots: filteredPilots,
            selectedIndex: filteredSelectedIndex ?? -1,
            onPilotSelected: (index) {
              _selectPilot(context, filteredPilots, pilots, index);
            },
          ),
        SizedBox(height: AppSpacing.xl),
        _PilotDetailsContent(
          pilot: selectedPilot,
          detailsStatus: detailsStatus,
          detailsError: detailsError,
        ),
      ],
    );
  }

  void _selectPilot(
    BuildContext context,
    List<PilotAdminViewData> filteredPilots,
    List<PilotAdminViewData> pilots,
    int index,
  ) {
    final selectedFilteredPilot = filteredPilots[index];
    final sourceIndex = pilots.indexWhere(
      (pilot) => pilot.id == selectedFilteredPilot.id,
    );
    if (sourceIndex == -1) {
      return;
    }

    context.read<PilotsBloc>().add(PilotSelected(sourceIndex));
  }

  PilotAdminViewData? get _selectedPilot {
    final index = selectedIndex;
    if (index == null || index < 0 || index >= pilots.length) {
      return null;
    }

    return pilots[index];
  }
}

List<PilotAdminViewData> filterPilotsForPilotsScreen(
  List<PilotAdminViewData> pilots,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return pilots;
  }

  return pilots.where((pilot) {
    return pilot.name.toLowerCase().contains(normalizedQuery) ||
        pilot.phone.toLowerCase().contains(normalizedQuery) ||
        pilot.email.toLowerCase().contains(normalizedQuery);
  }).toList();
}

class _PilotDetailsContent extends StatelessWidget {
  const _PilotDetailsContent({
    required this.pilot,
    required this.detailsStatus,
    this.detailsError,
  });

  final PilotAdminViewData? pilot;
  final PilotDetailsStatus detailsStatus;
  final String? detailsError;

  @override
  Widget build(BuildContext context) {
    if (pilot == null) {
      return const _PilotsStateCard(
        title: 'Select a pilot',
        message: 'Click View to load Supabase-backed pilot details.',
      );
    }

    return switch (detailsStatus) {
      PilotDetailsStatus.loading => const _PilotsStateCard(
        title: 'Loading pilot details',
        message: 'Fetching profile, bookings, wallet, services and tracking.',
        isLoading: true,
      ),
      PilotDetailsStatus.error => _PilotsStateCard(
        title: 'Unable to load pilot details',
        message: detailsError ?? 'Please try selecting this pilot again.',
        icon: Icons.error_outline,
      ),
      PilotDetailsStatus.initial ||
      PilotDetailsStatus.loaded ||
      PilotDetailsStatus.refreshing => _PilotViewLayout(pilot: pilot!),
    };
  }
}

class _PilotViewLayout extends StatelessWidget {
  const _PilotViewLayout({required this.pilot});

  final PilotAdminViewData pilot;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final readonlyColumn = _PilotReadonlyColumn(pilot: pilot);
    final readonlySections = _PilotReadonlySections(pilot: pilot);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 390.w, child: readonlyColumn),
          SizedBox(width: AppSpacing.lg),
          Expanded(child: readonlySections),
        ],
      );
    }

    return Column(
      children: [
        readonlyColumn,
        SizedBox(height: AppSpacing.lg),
        readonlySections,
      ],
    );
  }
}

class _PilotReadonlyColumn extends StatelessWidget {
  const _PilotReadonlyColumn({required this.pilot});

  final PilotAdminViewData pilot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PilotDetailsPanel(pilot: pilot),
        SizedBox(height: AppSpacing.lg),
        LicenseSection(license: pilot.license),
        SizedBox(height: AppSpacing.lg),
        BankDocumentsSection(documents: pilot.bankDocuments),
        SizedBox(height: AppSpacing.lg),
        DronesSection(drones: pilot.drones),
      ],
    );
  }
}

class _PilotReadonlySections extends StatelessWidget {
  const _PilotReadonlySections({required this.pilot});

  final PilotAdminViewData pilot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ServicesSection(services: pilot.services),
        SizedBox(height: AppSpacing.lg),
        ActiveBookingsSection(bookings: pilot.activeBookings),
        SizedBox(height: AppSpacing.lg),
        InvitationsSection(invitations: pilot.invitations),
        SizedBox(height: AppSpacing.lg),
        BookingHistorySection(bookings: pilot.bookingHistory),
        SizedBox(height: AppSpacing.lg),
        EarningsSection(earnings: pilot.earnings),
        SizedBox(height: AppSpacing.lg),
        TransactionsSection(transactions: pilot.transactions),
        SizedBox(height: AppSpacing.lg),
        WalletHistorySection(walletHistory: pilot.walletHistory),
        SizedBox(height: AppSpacing.lg),
        LiveTrackingSection(tracking: pilot.liveTracking),
      ],
    );
  }
}

class _PilotsStateCard extends StatelessWidget {
  const _PilotsStateCard({
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
