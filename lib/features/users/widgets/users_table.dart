import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/users_model.dart';

class UsersTable extends StatefulWidget {
  const UsersTable({
    required this.users,
    required this.selectedIndex,
    required this.onUserSelected,
    super.key,
  });

  final List<UserAdminViewData> users;
  final int selectedIndex;
  final ValueChanged<int> onUserSelected;

  static const rowsPerPage = 5;
  static const rowHeight = 68.0;

  @override
  State<UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<UsersTable> {
  int _page = 0;

  @override
  void didUpdateWidget(UsersTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pageCount = _pageCount;
    if (_page >= pageCount) {
      _page = math.max(0, pageCount - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageUsers = _pageUsers;

    return _UsersCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Users Table', style: AppTextStyles.headingMedium),
          SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : _TableMetrics.minWidth;
              final metrics = _TableMetrics.forWidth(
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
                            (UsersTable.rowHeight * UsersTable.rowsPerPage).h,
                        child: ListView.builder(
                          primary: false,
                          physics: const ClampingScrollPhysics(),
                          itemExtent: UsersTable.rowHeight.h,
                          itemCount: UsersTable.rowsPerPage,
                          itemBuilder: (context, visibleIndex) {
                            if (visibleIndex >= pageUsers.length) {
                              return _EmptyUserRow(metrics: metrics);
                            }

                            final sourceIndex =
                                (_page * UsersTable.rowsPerPage) + visibleIndex;
                            return _UserTableRow(
                              user: pageUsers[visibleIndex],
                              metrics: metrics,
                              isSelected: sourceIndex == widget.selectedIndex,
                              onView: () => widget.onUserSelected(sourceIndex),
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
            totalRows: widget.users.length,
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
    if (widget.users.isEmpty) {
      return 1;
    }

    return (widget.users.length / UsersTable.rowsPerPage).ceil();
  }

  List<UserAdminViewData> get _pageUsers {
    final start = _page * UsersTable.rowsPerPage;
    final end = math.min(start + UsersTable.rowsPerPage, widget.users.length);
    if (start >= end) {
      return const [];
    }

    return widget.users.sublist(start, end);
  }
}

class _EmptyUserRow extends StatelessWidget {
  const _EmptyUserRow({required this.metrics});

  final _TableMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: UsersTable.rowHeight.h,
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
              'No user on this row.',
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
        : (currentPage * UsersTable.rowsPerPage) + 1;
    final endRow = math.min(startRow + UsersTable.rowsPerPage - 1, totalRows);

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

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.metrics});

  final _TableMetrics metrics;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeaderCell('Profile', width: metrics.profile),
          _HeaderCell('Name', width: metrics.name),
          _HeaderCell('Phone', width: metrics.phone),
          _HeaderCell('Email', width: metrics.email),
          _HeaderCell('Gender', width: metrics.gender),
          _HeaderCell('Latest Booking', width: metrics.latestBooking),
          _HeaderCell('Bookings Count', width: metrics.bookingsCount),
          _HeaderCell('Status', width: metrics.status),
          _HeaderCell('Actions', width: metrics.actions, isLast: true),
        ],
      ),
    );
  }
}

class _UserTableRow extends StatelessWidget {
  const _UserTableRow({
    required this.user,
    required this.metrics,
    required this.isSelected,
    required this.onView,
  });

  final UserAdminViewData user;
  final _TableMetrics metrics;
  final bool isSelected;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlueLight : AppColors.background,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _FixedCell(
            width: metrics.profile,
            child: _ProfileAvatar(label: user.profileLabel),
          ),
          _FixedCell(width: metrics.name, child: _BodyCell(user.name)),
          _FixedCell(width: metrics.phone, child: _BodyCell(user.phone)),
          _FixedCell(width: metrics.email, child: _BodyCell(user.email)),
          _FixedCell(width: metrics.gender, child: _BodyCell(user.gender)),
          _FixedCell(
            width: metrics.latestBooking,
            child: _BodyCell(user.latestBookingDate),
          ),
          _FixedCell(
            width: metrics.bookingsCount,
            child: _BodyCell(user.bookingsCount.toString()),
          ),
          _FixedCell(
            width: metrics.status,
            child: _StatusBadge(
              label: user.latestBookingStatusLabel,
              color: user.latestBookingStatusColor,
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
                label: const Text(
                  'View',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
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
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18.r,
      backgroundColor: AppColors.primaryBlue,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.background,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 118.w),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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

class _TableMetrics {
  const _TableMetrics({
    required this.profile,
    required this.name,
    required this.phone,
    required this.email,
    required this.gender,
    required this.latestBooking,
    required this.bookingsCount,
    required this.status,
    required this.actions,
  });

  static const minWidth = 1240.0;

  final double profile;
  final double name;
  final double phone;
  final double email;
  final double gender;
  final double latestBooking;
  final double bookingsCount;
  final double status;
  final double actions;

  static _TableMetrics forWidth(
    double availableWidth, {
    required double horizontalPadding,
  }) {
    final contentWidth = math.max(minWidth, availableWidth) - horizontalPadding;
    const weights = [0.9, 2.0, 1.45, 2.45, 1.0, 1.45, 1.2, 1.2, 1.8];
    final unit = contentWidth / weights.reduce((sum, item) => sum + item);

    return _TableMetrics(
      profile: unit * weights[0],
      name: unit * weights[1],
      phone: unit * weights[2],
      email: unit * weights[3],
      gender: unit * weights[4],
      latestBooking: unit * weights[5],
      bookingsCount: unit * weights[6],
      status: unit * weights[7],
      actions: unit * weights[8],
    );
  }

  double get contentWidth =>
      profile +
      name +
      phone +
      email +
      gender +
      latestBooking +
      bookingsCount +
      status +
      actions;

  double get totalWidth => contentWidth + (AppSpacing.md * 2);
}

class _UsersCard extends StatelessWidget {
  const _UsersCard({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}
