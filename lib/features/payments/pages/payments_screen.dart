import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../bloc/payments_bloc.dart';
import '../repository/payments_repository.dart';
import '../widgets/payments_tabs.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late final PaymentsBloc _paymentsBloc;

  @override
  void initState() {
    super.initState();
    _paymentsBloc = PaymentsBloc(repository: PaymentsRepository())
      ..add(const PaymentsRequested());
  }

  @override
  void dispose() {
    _paymentsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _paymentsBloc,
      child: BlocBuilder<PaymentsBloc, PaymentsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PaymentsHeader(),
              SizedBox(height: AppSpacing.xl),
              Expanded(
                child: switch (state) {
                  PaymentsInitial() ||
                  PaymentsLoading() => const _PaymentsStateCard(
                    title: 'Loading payments',
                    message: 'Fetching payment records from Supabase.',
                    isLoading: true,
                  ),
                  PaymentsEmpty() => const _PaymentsStateCard(
                    title: 'No payments found',
                    message: 'No payment records are available yet.',
                  ),
                  PaymentsFailure(:final message) => _PaymentsStateCard(
                    title: 'Unable to load payments',
                    message: message,
                    icon: Icons.error_outline,
                  ),
                  PaymentsLoaded(:final data) => PaymentsTabs(data: data),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentsHeader extends StatelessWidget {
  const _PaymentsHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payments', style: AppTextStyles.headingLarge),
          SizedBox(height: 8.h),
          Text(
            'View user, pilot and store transactions.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsStateCard extends StatelessWidget {
  const _PaymentsStateCard({
    required this.title,
    required this.message,
    this.icon = Icons.payments_outlined,
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
