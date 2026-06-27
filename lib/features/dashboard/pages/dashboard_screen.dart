import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/routing/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/navigation/navigation_logger.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../bloc/dashboard_bloc.dart';
import '../models/dashboard_model.dart';
import '../repository/dashboard_repository.dart';
import '../widgets/booking_overview_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/revenue_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardBloc _dashboardBloc;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = DashboardBloc(repository: DashboardRepository())
      ..add(const DashboardRequested());
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dashboardBloc,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardHeader(),
                SizedBox(height: AppSpacing.xl),
                const _QuickActionsGrid(),
                SizedBox(height: AppSpacing.xl),
                switch (state) {
                  DashboardInitial() ||
                  DashboardLoading() => const _DashboardStateCard(
                    title: 'Loading dashboard',
                    message: 'Fetching dashboard data from Supabase.',
                    isLoading: true,
                  ),
                  DashboardFailure(:final message) => _DashboardStateCard(
                    title: 'Unable to load dashboard',
                    message: message,
                    icon: Icons.error_outline,
                  ),
                  DashboardLoaded(:final data) => _DashboardLoadedView(
                    data: data,
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

class _DashboardLoadedView extends StatefulWidget {
  const _DashboardLoadedView({required this.data});

  final DashboardData data;

  @override
  State<_DashboardLoadedView> createState() => _DashboardLoadedViewState();
}

class _DashboardLoadedViewState extends State<_DashboardLoadedView> {
  String? _bookingStatusFilter;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final statColumns = ResponsiveHelper.value<int>(
      context,
      mobile: 1,
      tablet: 3,
      desktop: 6,
    );
    final showSplitOverview = ResponsiveHelper.isDesktop(context);
    final stats = _statsFrom(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          itemCount: stats.length,
          columns: statColumns,
          mainAxisExtent: 168.h,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(
              title: stat.title,
              value: stat.value,
              growth: stat.growth,
              icon: stat.icon,
              accentColor: stat.accentColor,
              onTap: () => _openDashboardRoute(
                context,
                route: stat.route,
                source: 'DashboardScreen.statCard',
              ),
            );
          },
        ),
        SizedBox(height: AppSpacing.xl),
        if (showSplitOverview)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: RevenueCard(summary: data.payments)),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: BookingOverviewCard(
                  summary: data.bookings,
                  selectedStatus: _bookingStatusFilter,
                  onStatusTap: _selectBookingStatus,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              RevenueCard(summary: data.payments),
              SizedBox(height: AppSpacing.lg),
              BookingOverviewCard(
                summary: data.bookings,
                selectedStatus: _bookingStatusFilter,
                onStatusTap: _selectBookingStatus,
              ),
            ],
          ),
        if (_bookingStatusFilter != null) ...[
          SizedBox(height: AppSpacing.xl),
          _BookingListPanel(
            status: _bookingStatusFilter!,
            bookings: _bookingsForStatus(
              data.bookingItems,
              _bookingStatusFilter!,
            ),
            onClear: () => setState(() => _bookingStatusFilter = null),
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        RecentActivityCard(activities: data.recentActivities),
      ],
    );
  }

  void _selectBookingStatus(String status) {
    setState(() {
      _bookingStatusFilter = _bookingStatusFilter == status ? null : status;
    });
  }
}

List<DashboardBookingItem> _bookingsForStatus(
  List<DashboardBookingItem> bookings,
  String status,
) {
  final normalized = status.toLowerCase();
  return bookings
      .where((booking) => booking.status.toLowerCase() == normalized)
      .toList();
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final quickActionColumns = ResponsiveHelper.value<int>(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 4,
    );

    return _ResponsiveGrid(
      itemCount: _quickActions.length,
      columns: quickActionColumns,
      mainAxisExtent: 132.h,
      itemBuilder: (context, index) {
        final action = _quickActions[index];
        return QuickActionCard(
          title: action.title,
          subtitle: action.subtitle,
          icon: action.icon,
          onTap: () => _openQuickAction(context, action),
        );
      },
    );
  }
}

class _DashboardStateCard extends StatelessWidget {
  const _DashboardStateCard({
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

class _BookingListPanel extends StatelessWidget {
  const _BookingListPanel({
    required this.status,
    required this.bookings,
    required this.onClear,
  });

  final String status;
  final List<DashboardBookingItem> bookings;
  final VoidCallback onClear;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_titleCase(status)} Bookings',
                  style: AppTextStyles.headingMedium,
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, size: 18.r),
                label: const Text('Clear'),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          if (bookings.isEmpty)
            Text(
              'No bookings found for this status.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
            Column(
              children: [
                for (final booking in bookings)
                  Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            booking.reference,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: Text(
                            booking.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            booking.dateTimeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

void _openQuickAction(BuildContext context, _QuickActionData action) {
  _openDashboardRoute(
    context,
    route: action.route,
    source: 'DashboardScreen.quickAction',
  );

  final focusLabel = action.focusLabel;
  if (focusLabel == null) {
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _ensureVisibleText(focusLabel);
  });
}

void _openDashboardRoute(
  BuildContext context, {
  required String route,
  required String source,
}) {
  final currentRoute = ModalRoute.of(context)?.settings.name;
  if (currentRoute == route) {
    NavigationLogger.source(source, action: 'ignore-selected', to: route);
    return;
  }

  NavigationLogger.source(
    source,
    action: 'root-pushReplacementNamed',
    from: currentRoute,
    to: route,
  );
  Navigator.of(context, rootNavigator: true).pushReplacementNamed(route);
}

void _ensureVisibleText(String text) {
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Text && widget.data == text) {
      Scrollable.ensureVisible(
        element,
        duration: Duration.zero,
        alignment: 0.1,
      );
      return;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.itemCount,
    required this.columns,
    required this.mainAxisExtent,
    required this.itemBuilder,
  });

  final int itemCount;
  final int columns;
  final double mainAxisExtent;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisSpacing: AppSpacing.lg,
        mainAxisExtent: mainAxisExtent,
      ),
      itemBuilder: itemBuilder,
    );
  }
}

List<_StatData> _statsFrom(DashboardData data) {
  return [
    _StatData(
      title: 'Total Users',
      value: _formatInt(data.users.totalUsers),
      growth: data.users.totalUsersGrowth,
      icon: Icons.people_outline,
      accentColor: const Color(0xFF0B5ED7),
      route: AppRoutes.users,
    ),
    _StatData(
      title: 'Active Users',
      value: _formatInt(data.users.activeUsers),
      growth: data.users.activeUsersGrowth,
      icon: Icons.verified_user_outlined,
      accentColor: const Color(0xFF16A34A),
      route: AppRoutes.users,
    ),
    _StatData(
      title: 'New Users',
      value: _formatInt(data.users.newUsers),
      growth: data.users.newUsersGrowth,
      icon: Icons.person_add_alt_outlined,
      accentColor: const Color(0xFF0891B2),
      route: AppRoutes.users,
    ),
    _StatData(
      title: 'Total Pilots',
      value: _formatInt(data.pilots.totalPilots),
      growth: data.pilots.totalPilotsGrowth,
      icon: Icons.badge_outlined,
      accentColor: const Color(0xFF14B8A6),
      route: AppRoutes.pilots,
    ),
    _StatData(
      title: 'Approved Pilots',
      value: _formatInt(data.pilots.approvedPilots),
      growth: data.pilots.approvedPilotsGrowth,
      icon: Icons.task_alt_outlined,
      accentColor: const Color(0xFF16A34A),
      route: AppRoutes.pilots,
    ),
    _StatData(
      title: 'Pending Pilots',
      value: _formatInt(data.pilots.pendingPilots),
      growth: data.pilots.pendingPilotsGrowth,
      icon: Icons.pending_actions_outlined,
      accentColor: const Color(0xFFF59E0B),
      route: AppRoutes.pilots,
    ),
    _StatData(
      title: 'Rejected Pilots',
      value: _formatInt(data.pilots.rejectedPilots),
      growth: data.pilots.rejectedPilotsGrowth,
      icon: Icons.block_outlined,
      accentColor: const Color(0xFFDC2626),
      route: AppRoutes.pilots,
    ),
    _StatData(
      title: 'Total Categories',
      value: _formatInt(data.store.totalCategories),
      growth: data.store.totalCategoriesGrowth,
      icon: Icons.category_outlined,
      accentColor: const Color(0xFF7C3AED),
      route: AppRoutes.store,
    ),
    _StatData(
      title: 'Total Products',
      value: _formatInt(data.store.totalProducts),
      growth: data.store.totalProductsGrowth,
      icon: Icons.inventory_2_outlined,
      accentColor: const Color(0xFFEA580C),
      route: AppRoutes.store,
    ),
    _StatData(
      title: 'Total Orders',
      value: _formatInt(data.store.totalOrders),
      growth: data.store.totalOrdersGrowth,
      icon: Icons.storefront_outlined,
      accentColor: const Color(0xFFEA580C),
      route: AppRoutes.store,
    ),
    _StatData(
      title: 'Wishlist Items',
      value: _formatInt(data.store.totalWishlistItems),
      growth: data.store.totalWishlistItemsGrowth,
      icon: Icons.favorite_border_outlined,
      accentColor: const Color(0xFFDB2777),
      route: AppRoutes.store,
    ),
    _StatData(
      title: 'Cart Items',
      value: _formatInt(data.store.totalCartItems),
      growth: data.store.totalCartItemsGrowth,
      icon: Icons.shopping_cart_outlined,
      accentColor: const Color(0xFF0891B2),
      route: AppRoutes.store,
    ),
    _StatData(
      title: 'Total Revenue',
      value: data.payments.totalRevenueLabel,
      growth: data.payments.totalRevenueGrowth,
      icon: Icons.trending_up_outlined,
      accentColor: const Color(0xFF16A34A),
      route: AppRoutes.payments,
    ),
    _StatData(
      title: 'Successful Payments',
      value: _formatInt(data.payments.successfulPayments),
      growth: data.payments.successfulPaymentsGrowth,
      icon: Icons.payments_outlined,
      accentColor: const Color(0xFF16A34A),
      route: AppRoutes.payments,
    ),
    _StatData(
      title: 'Pending Payments',
      value: _formatInt(data.payments.pendingPayments),
      growth: data.payments.pendingPaymentsGrowth,
      icon: Icons.hourglass_top_outlined,
      accentColor: const Color(0xFFF59E0B),
      route: AppRoutes.payments,
    ),
    _StatData(
      title: 'Failed Payments',
      value: _formatInt(data.payments.failedPayments),
      growth: data.payments.failedPaymentsGrowth,
      icon: Icons.error_outline,
      accentColor: const Color(0xFFDC2626),
      route: AppRoutes.payments,
    ),
  ];
}

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    final position = text.length - index;
    buffer.write(text[index]);
    if (position > 1 && position % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'\s+|_+|-+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.growth,
    required this.icon,
    required this.accentColor,
    required this.route,
  });

  final String title;
  final String value;
  final String growth;
  final IconData icon;
  final Color accentColor;
  final String route;
}

class _QuickActionData {
  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.focusLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String? focusLabel;
}

const _quickActions = <_QuickActionData>[
  _QuickActionData(
    title: 'Add Service',
    subtitle: 'Create a new service',
    icon: Icons.add_circle_outline,
    route: AppRoutes.pilots,
    focusLabel: 'Services',
  ),
  _QuickActionData(
    title: 'Add Product',
    subtitle: 'Publish store item',
    icon: Icons.inventory_2_outlined,
    route: AppRoutes.store,
    focusLabel: 'Products',
  ),
  _QuickActionData(
    title: 'View Users',
    subtitle: 'Review user activity',
    icon: Icons.group_outlined,
    route: AppRoutes.users,
  ),
  _QuickActionData(
    title: 'View Pilots',
    subtitle: 'Manage pilot profiles',
    icon: Icons.flight_takeoff_outlined,
    route: AppRoutes.pilots,
  ),
];
