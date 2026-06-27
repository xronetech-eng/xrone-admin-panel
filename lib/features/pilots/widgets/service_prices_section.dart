import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class ServicePricesSection extends StatefulWidget {
  const ServicePricesSection({
    required this.services,
    required this.onSave,
    this.savingServiceId,
    super.key,
  });

  final List<PilotServiceData> services;
  final void Function(
    PilotServiceData service,
    String price,
    String marketPrice,
  )
  onSave;
  final String? savingServiceId;

  @override
  State<ServicePricesSection> createState() => _ServicePricesSectionState();
}

class _ServicePricesSectionState extends State<ServicePricesSection> {
  final _priceControllers = <String, TextEditingController>{};
  final _marketPriceControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(ServicePricesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _marketPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Service Prices',
      subtitle: 'Saved to Supabase services table',
      child: widget.services.isEmpty
          ? const PilotEmptyState(message: 'No service prices found.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final service in widget.services)
                      _ServicePriceEditor(
                        service: service,
                        priceController: _priceControllers[service.id]!,
                        marketPriceController:
                            _marketPriceControllers[service.id]!,
                        isSaving: widget.savingServiceId == service.id,
                        onSave: () {
                          widget.onSave(
                            service,
                            _priceControllers[service.id]!.text.trim(),
                            _marketPriceControllers[service.id]!.text.trim(),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  void _syncControllers() {
    final serviceIds = widget.services.map((service) => service.id).toSet();

    for (final service in widget.services) {
      _priceControllers
              .putIfAbsent(
                service.id,
                () => TextEditingController(text: service.rawPrice),
              )
              .text =
          service.rawPrice;
      _marketPriceControllers
              .putIfAbsent(
                service.id,
                () => TextEditingController(text: service.rawMarketPrice),
              )
              .text =
          service.rawMarketPrice;
    }

    for (final id in _priceControllers.keys.toList()) {
      if (!serviceIds.contains(id)) {
        _priceControllers.remove(id)?.dispose();
      }
    }
    for (final id in _marketPriceControllers.keys.toList()) {
      if (!serviceIds.contains(id)) {
        _marketPriceControllers.remove(id)?.dispose();
      }
    }
  }
}

class _ServicePriceEditor extends StatelessWidget {
  const _ServicePriceEditor({
    required this.service,
    required this.priceController,
    required this.marketPriceController,
    required this.isSaving,
    required this.onSave,
  });

  final PilotServiceData service;
  final TextEditingController priceController;
  final TextEditingController marketPriceController;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.w,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: priceController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMedium,
            decoration: _inputDecoration('Price'),
          ),
          SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: marketPriceController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMedium,
            decoration: _inputDecoration('Market Price'),
          ),
          SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: CircularProgressIndicator(strokeWidth: 2.r),
                  )
                : Icon(Icons.save_outlined, size: 18.r),
            label: Text(isSaving ? 'Saving' : 'Save'),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: AppTextStyles.bodySmall,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14.h,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.primaryBlue),
    ),
  );
}
