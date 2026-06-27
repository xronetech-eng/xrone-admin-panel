import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class InvitationsSection extends StatelessWidget {
  const InvitationsSection({required this.invitations, super.key});

  final List<PilotInvitationData> invitations;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Invitations',
      subtitle: 'Read only',
      child: invitations.isEmpty
          ? const PilotEmptyState(message: 'No invitations.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 900.w,
                child: Column(
                  children: [
                    const _RowShell(
                      isHeader: true,
                      children: [
                        _Cell('Invitation ID', flex: 2, isHeader: true),
                        _Cell('User', flex: 2, isHeader: true),
                        _Cell('Service', flex: 2, isHeader: true),
                        _Cell('Booking Date', flex: 2, isHeader: true),
                        _Cell('Area', flex: 2, isHeader: true),
                        _Cell('Price', flex: 2, isHeader: true),
                        _Cell('Status', flex: 2, isHeader: true),
                      ],
                    ),
                    for (final invitation in invitations)
                      _RowShell(
                        children: [
                          _Cell(invitation.invitationId, flex: 2),
                          _Cell(invitation.user, flex: 2),
                          _Cell(invitation.service, flex: 2),
                          _Cell(invitation.bookingDate, flex: 2),
                          _Cell(invitation.area, flex: 2),
                          _Cell(invitation.price, flex: 2),
                          _Cell(invitation.status, flex: 2),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({required this.children, this.isHeader = false});

  final List<Widget> children;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 58.h),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10.h),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.surface : AppColors.background,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(children: children),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {required this.flex, this.isHeader = false});

  final String text;
  final int flex;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: PilotTableText(text, isHeader: isHeader),
    );
  }
}
