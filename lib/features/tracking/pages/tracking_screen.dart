import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../bloc/tracking_bloc.dart';
import '../models/tracking_model.dart';
import '../repository/tracking_repository.dart';
import '../widgets/tracking_details_panel.dart';
import '../widgets/tracking_filters.dart';
import '../widgets/tracking_table.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final TrackingBloc _trackingBloc;
  String _query = '';
  String _status = 'All';
  TrackingTabType _tab = TrackingTabType.bookings;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _trackingBloc = TrackingBloc(repository: TrackingRepository())
      ..add(const TrackingRequested());
  }

  @override
  void dispose() {
    _trackingBloc.close();
    super.dispose();
  }

  List<TrackingRowData> _filteredRows(TrackingData data) {
    return _rowsForTab(data).where((row) {
      return row.matchesSearch(_query) && row.matchesFilter(_status);
    }).toList();
  }

  List<TrackingRowData> _rowsForTab(TrackingData data) {
    return switch (_tab) {
      TrackingTabType.bookings => data.bookings,
      TrackingTabType.pilots => data.pilots,
      TrackingTabType.store => data.storeOrders,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocProvider.value(
      value: _trackingBloc,
      child: BlocBuilder<TrackingBloc, TrackingState>(
        builder: (context, state) {
          final data = state is TrackingLoaded
              ? state.data
              : TrackingData.empty;
          final rows = _filteredRows(data);
          final selectedIndex = rows.isEmpty
              ? 0
              : _selectedIndex.clamp(0, rows.length - 1);
          final selected = rows.isEmpty ? null : rows[selectedIndex];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tracking', style: AppTextStyles.headingLarge),
                SizedBox(height: 8.h),
                Text(
                  'View active pilot tracking for accepted, started and working bookings.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                _SummaryCards(summary: data.summary),
                SizedBox(height: AppSpacing.xl),
                TrackingFilters(
                  status: _status,
                  onSearchChanged: (value) => setState(() {
                    _query = value;
                    _selectedIndex = 0;
                  }),
                  onStatusChanged: (value) => setState(() {
                    _status = value;
                    _selectedIndex = 0;
                  }),
                ),
                SizedBox(height: AppSpacing.xl),
                _TrackingTabs(
                  selected: _tab,
                  onChanged: (tab) => setState(() {
                    _tab = tab;
                    _selectedIndex = 0;
                  }),
                ),
                SizedBox(height: AppSpacing.lg),
                if (state is TrackingInitial || state is TrackingLoading)
                  const _TrackingStateCard(
                    title: 'Loading tracking',
                    message: 'Fetching tracking data from Supabase.',
                    isLoading: true,
                  )
                else if (state is TrackingFailure)
                  _TrackingStateCard(
                    title: 'Unable to load tracking',
                    message: state.message,
                    icon: Icons.error_outline,
                  )
                else if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TrackingTable(
                          type: _tab,
                          rows: rows,
                          selectedIndex: selectedIndex,
                          onView: (index) =>
                              setState(() => _selectedIndex = index),
                        ),
                      ),
                      SizedBox(width: AppSpacing.lg),
                      SizedBox(
                        width: 440.w,
                        child: TrackingDetailsPanel(row: selected),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TrackingTable(
                        type: _tab,
                        rows: rows,
                        selectedIndex: selectedIndex,
                        onView: (index) =>
                            setState(() => _selectedIndex = index),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      TrackingDetailsPanel(row: selected),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrackingTabs extends StatelessWidget {
  const _TrackingTabs({required this.selected, required this.onChanged});

  final TrackingTabType selected;
  final ValueChanged<TrackingTabType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _TabButton(
          label: 'User Bookings',
          isSelected: selected == TrackingTabType.bookings,
          onTap: () => onChanged(TrackingTabType.bookings),
        ),
        _TabButton(
          label: 'Pilot Tracking',
          isSelected: selected == TrackingTabType.pilots,
          onTap: () => onChanged(TrackingTabType.pilots),
        ),
        _TabButton(
          label: 'Store Orders',
          isSelected: selected == TrackingTabType.store,
          onTap: () => onChanged(TrackingTabType.store),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryBlueLight,
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: isSelected ? AppColors.primaryBlue : AppColors.textMuted,
        fontWeight: FontWeight.w800,
      ),
      side: const BorderSide(color: AppColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final TrackingSummary summary;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.value<int>(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 4,
    );
    final items = [
      _SummaryItem('Active Bookings', summary.activeBookings),
      _SummaryItem('Active Pilots', summary.activePilots),
      _SummaryItem('Active Store Orders', summary.activeStoreOrders),
      _SummaryItem('Completed Deliveries', summary.completedDeliveries),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisSpacing: AppSpacing.lg,
        mainAxisExtent: 112.h,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                item.value.toString(),
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value);

  final String label;
  final int value;
}

class _TrackingStateCard extends StatelessWidget {
  const _TrackingStateCard({
    required this.title,
    required this.message,
    this.icon = Icons.location_searching_outlined,
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
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, color: AppColors.textMuted),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
