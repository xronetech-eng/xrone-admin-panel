import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class PilotsTable extends StatefulWidget {
  const PilotsTable({
    required this.pilots,
    required this.selectedIndex,
    required this.onPilotSelected,
    super.key,
  });

  final List<PilotAdminViewData> pilots;
  final int selectedIndex;
  final ValueChanged<int> onPilotSelected;

  static const rowsPerPage = 5;
  static const rowHeight = 68.0;

  @override
  State<PilotsTable> createState() => _PilotsTableState();
}

class _PilotsTableState extends State<PilotsTable> {
  int _page = 0;

  @override
  void didUpdateWidget(PilotsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pageCount = _pageCount;
    if (_page >= pageCount) {
      _page = math.max(0, pageCount - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagePilots = _pagePilots;

    return PilotSectionCard(
      title: 'Pilots Table',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : _PilotTableMetrics.minWidth;
              final metrics = _PilotTableMetrics.forWidth(
                availableWidth,
                horizontalPadding: AppSpacing.md * 2,
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: metrics.totalWidth,
                  child: Column(
                    children: [
                      _TableHeader(metrics: metrics),
                      SizedBox(
                        height:
                            (PilotsTable.rowHeight * PilotsTable.rowsPerPage).h,
                        child: ListView.builder(
                          primary: false,
                          physics: const ClampingScrollPhysics(),
                          itemExtent: PilotsTable.rowHeight.h,
                          itemCount: PilotsTable.rowsPerPage,
                          itemBuilder: (context, visibleIndex) {
                            if (visibleIndex >= pagePilots.length) {
                              return _EmptyPilotRow(metrics: metrics);
                            }

                            final sourceIndex =
                                (_page * PilotsTable.rowsPerPage) +
                                visibleIndex;
                            return _PilotRow(
                              pilot: pagePilots[visibleIndex],
                              metrics: metrics,
                              isSelected: sourceIndex == widget.selectedIndex,
                              onView: () => widget.onPilotSelected(sourceIndex),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: AppSpacing.lg),
          _PaginationControls(
            currentPage: _page,
            pageCount: _pageCount,
            totalRows: widget.pilots.length,
            onPrevious: _page == 0
                ? null
                : () => setState(() {
                    _page--;
                  }),
            onNext: _page >= _pageCount - 1
                ? null
                : () => setState(() {
                    _page++;
                  }),
          ),
        ],
      ),
    );
  }

  int get _pageCount {
    if (widget.pilots.isEmpty) {
      return 1;
    }

    return (widget.pilots.length / PilotsTable.rowsPerPage).ceil();
  }

  List<PilotAdminViewData> get _pagePilots {
    final start = _page * PilotsTable.rowsPerPage;
    final end = math.min(start + PilotsTable.rowsPerPage, widget.pilots.length);
    if (start >= end) {
      return const [];
    }

    return widget.pilots.sublist(start, end);
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.metrics});

  final _PilotTableMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _HeaderCell('Profile', width: metrics.profile),
          _HeaderCell('Name', width: metrics.name),
          _HeaderCell('Phone', width: metrics.phone),
          _HeaderCell('Email', width: metrics.email),
          _HeaderCell('License Number', width: metrics.license),
          _HeaderCell('Services Count', width: metrics.services),
          _HeaderCell('Bookings Count', width: metrics.bookings),
          _HeaderCell('Status', width: metrics.status),
          _HeaderCell('Actions', width: metrics.actions, isLast: true),
        ],
      ),
    );
  }
}

class _PilotRow extends StatelessWidget {
  const _PilotRow({
    required this.pilot,
    required this.metrics,
    required this.isSelected,
    required this.onView,
  });

  final PilotAdminViewData pilot;
  final _PilotTableMetrics metrics;
  final bool isSelected;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: PilotsTable.rowHeight.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlueLight : AppColors.background,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _FixedCell(
            width: metrics.profile,
            child: _ProfileAvatar(
              label: pilot.profileLabel,
              imageUrl: pilot.profileImage,
            ),
          ),
          _FixedCell(width: metrics.name, child: PilotTableText(pilot.name)),
          _FixedCell(width: metrics.phone, child: PilotTableText(pilot.phone)),
          _FixedCell(width: metrics.email, child: PilotTableText(pilot.email)),
          _FixedCell(
            width: metrics.license,
            child: PilotTableText(pilot.licenseNumber),
          ),
          _FixedCell(
            width: metrics.services,
            child: PilotTableText(pilot.servicesCount.toString()),
          ),
          _FixedCell(
            width: metrics.bookings,
            child: PilotTableText(pilot.bookingsCount.toString()),
          ),
          _FixedCell(
            width: metrics.status,
            child: PilotStatusPill(
              label: pilot.status.label,
              color: pilot.status.color,
            ),
          ),
          _FixedCell(
            width: metrics.actions,
            isLast: true,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onView,
                icon: Icon(Icons.visibility_outlined, size: 16.r),
                label: const Text('View'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPilotRow extends StatelessWidget {
  const _EmptyPilotRow({required this.metrics});

  final _PilotTableMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: PilotsTable.rowHeight.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _FixedCell(
            width: metrics.contentWidth,
            isLast: true,
            child: Text(
              'No pilot on this row.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.pageCount,
    required this.totalRows,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final int totalRows;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final startRow = totalRows == 0
        ? 0
        : (currentPage * PilotsTable.rowsPerPage) + 1;
    final endRow = math.min(startRow + PilotsTable.rowsPerPage - 1, totalRows);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing $startRow-$endRow of $totalRows',
            style: AppTextStyles.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Previous page',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          '${currentPage + 1} / $pageCount',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.width, this.isLast = false});

  final String text;
  final double width;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return _FixedCell(
      width: width,
      isLast: isLast,
      child: PilotTableText(text, isHeader: true),
    );
  }
}

class _FixedCell extends StatelessWidget {
  const _FixedCell({
    required this.width,
    required this.child,
    this.isLast = false,
  });

  final double width;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.md),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.label, required this.imageUrl});

  final String label;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18.r,
      backgroundColor: AppColors.primaryBlue,
      backgroundImage: imageUrl.trim().isEmpty
          ? null
          : NetworkImage(imageUrl.trim()),
      child: imageUrl.trim().isEmpty
          ? Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.background,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _PilotTableMetrics {
  const _PilotTableMetrics({
    required this.profile,
    required this.name,
    required this.phone,
    required this.email,
    required this.license,
    required this.services,
    required this.bookings,
    required this.status,
    required this.actions,
  });

  final double profile;
  final double name;
  final double phone;
  final double email;
  final double license;
  final double services;
  final double bookings;
  final double status;
  final double actions;

  static const minWidth = 1240.0;

  static _PilotTableMetrics forWidth(
    double width, {
    required double horizontalPadding,
  }) {
    final contentWidth = math.max(minWidth, width) - horizontalPadding;
    const weights = [1.0, 2.0, 2.0, 3.0, 2.0, 2.0, 2.0, 1.2, 2.8];
    final unit = contentWidth / weights.reduce((sum, item) => sum + item);

    return _PilotTableMetrics(
      profile: unit * weights[0],
      name: unit * weights[1],
      phone: unit * weights[2],
      email: unit * weights[3],
      license: unit * weights[4],
      services: unit * weights[5],
      bookings: unit * weights[6],
      status: unit * weights[7],
      actions: unit * weights[8],
    );
  }

  double get contentWidth =>
      profile +
      name +
      phone +
      email +
      license +
      services +
      bookings +
      status +
      actions;

  double get totalWidth => contentWidth + (AppSpacing.md * 2);
}
