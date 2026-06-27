import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilot_management_model.dart';
import '../repository/pilot_management_repository.dart';
import '../widgets/banner_html_image.dart';
import '../widgets/pilot_banner_image_picker.dart';
import '../widgets/pilot_service_management_section.dart';

class PilotManagementScreen extends StatefulWidget {
  const PilotManagementScreen({super.key});

  @override
  State<PilotManagementScreen> createState() => _PilotManagementScreenState();
}

class _PilotManagementScreenState extends State<PilotManagementScreen> {
  final _repository = PilotManagementRepository();
  final _servicePriceControllers = <String, TextEditingController>{};
  final _pilotSettingControllers = <String, TextEditingController>{};
  final _addServiceController = TextEditingController();
  final _helpController = TextEditingController();
  final _privacyController = TextEditingController();
  final _defaultMarketPriceController = TextEditingController();

  String? _error;
  String? _savingSection;
  bool _isLoading = true;
  var _services = <PilotServiceChipData>[];
  var _images = <String>[];

  @override
  void initState() {
    super.initState();
    for (final field in _servicePriceFields) {
      _servicePriceControllers[field.key] = TextEditingController();
    }
    for (final field in [..._pilotSettingFields, _requestRadiusField]) {
      _pilotSettingControllers[field.key] = TextEditingController();
    }
    _loadConfig();
  }

  @override
  void dispose() {
    for (final controller in _servicePriceControllers.values) {
      controller.dispose();
    }
    for (final controller in _pilotSettingControllers.values) {
      controller.dispose();
    }
    _addServiceController.dispose();
    _helpController.dispose();
    _privacyController.dispose();
    _defaultMarketPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeader(),
          SizedBox(height: AppSpacing.xl),
          if (_isLoading)
            const _StateCard(
              title: 'Loading pilot management',
              message: 'Fetching Firebase configuration.',
              isLoading: true,
            )
          else if (_error != null)
            _StateCard(
              title: 'Unable to load configuration',
              message: _error!,
              icon: Icons.error_outline,
            )
          else
            _SettingsBody(
              servicePriceFields: _servicePriceFields,
              servicePriceControllers: _servicePriceControllers,
              requestRadiusField: _requestRadiusField,
              requestRadiusController:
                  _pilotSettingControllers[_requestRadiusField.key]!,
              services: _services,
              addServiceController: _addServiceController,
              images: _images,
              pilotSettingFields: _pilotSettingFields,
              pilotSettingControllers: _pilotSettingControllers,
              helpController: _helpController,
              privacyController: _privacyController,
              defaultMarketPriceField: _defaultMarketPriceField,
              defaultMarketPriceController: _defaultMarketPriceController,
              savingSection: _savingSection,
              onSaveServicePrices: _saveServicePrices,
              onSaveRequestRadius: _saveRequestRadius,
              onAddService: _addService,
              onRemoveService: _removeService,
              onSaveServices: _saveServices,
              onUploadBanner: _uploadBanner,
              onDeleteBanner: _deleteBanner,
              onSaveImages: _saveImages,
              onSavePilotSettings: _savePilotSettings,
              onSaveHelpPrivacy: _saveHelpPrivacy,
              onSaveDefaultMarketPrice: _saveDefaultMarketPrice,
            ),
        ],
      ),
    );
  }

  Future<void> _loadConfig() async {
    debugPrint('[PilotManagement] load:start');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final config = await _repository.loadConfig();
      _applyConfig(config);
      setState(() {
        _isLoading = false;
      });
      debugPrint('[PilotManagement] load:success');
    } on Object catch (error) {
      final message = error.toString();
      debugPrint('[PilotManagement] error=$message');
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshConfig() async {
    final config = await _repository.loadConfig();
    _applyConfig(config);
    setState(() {});
  }

  void _applyConfig(PilotManagementConfig config) {
    _servicePriceControllers['wedding']!.text = config.servicePrices.wedding;
    _servicePriceControllers['aerial']!.text = config.servicePrices.aerial;
    _servicePriceControllers['agriculture']!.text =
        config.servicePrices.agriculture;
    _pilotSettingControllers['request_radius']!.text =
        config.pilot.requestRadius;
    _pilotSettingControllers['max_ongoing_bookings']!.text =
        config.pilot.maxOngoingBookings;
    _pilotSettingControllers['gst_charges']!.text = config.pilot.gstCharges;
    _pilotSettingControllers['journey_buffer_time']!.text =
        config.pilot.journeyBufferTime;
    _pilotSettingControllers['currency']!.text = config.pilot.currency;
    _pilotSettingControllers['platform_charges']!.text =
        config.pilot.platformCharges;
    _pilotSettingControllers['minimum_wallet_amount']!.text =
        config.pilot.minimumWalletAmount;
    _pilotSettingControllers['max_service_radius']!.text =
        config.pilot.maxServiceRadius;
    _helpController.text = config.pilot.help;
    _privacyController.text = config.pilot.privacyPolicy;
    _defaultMarketPriceController.text = config.defaultMarketPrice;
    _services = [
      for (final service in config.services)
        PilotServiceChipData(label: service, icon: Icons.apps),
    ];
    _images = [...config.images];
  }

  Future<void> _saveServicePrices() {
    return _saveSection('service_prices', () {
      return _repository.saveServicePrices(
        wedding: _servicePriceControllers['wedding']!.text,
        aerial: _servicePriceControllers['aerial']!.text,
        agriculture: _servicePriceControllers['agriculture']!.text,
      );
    });
  }

  Future<void> _saveRequestRadius() {
    return _saveSection('request_radius', () {
      return _repository.saveRequestRadius(
        _pilotSettingControllers['request_radius']!.text,
      );
    });
  }

  void _addService() {
    final service = _addServiceController.text.trim();
    if (service.isEmpty) {
      return;
    }

    setState(() {
      _services.add(PilotServiceChipData(label: service, icon: Icons.apps));
      _addServiceController.clear();
    });
  }

  void _removeService(PilotServiceChipData service) {
    setState(() {
      _services.remove(service);
    });
  }

  Future<void> _saveServices() {
    return _saveSection('services', () {
      return _repository.saveServices(
        _services.map((service) => service.label).toList(),
      );
    });
  }

  Future<void> _uploadBanner() async {
    debugPrint('[PilotManagement] banner:upload:start');
    final image = await pickPilotBannerImage();
    if (image == null) {
      return;
    }

    setState(() => _savingSection = 'banner_images');
    try {
      final url = await _repository.uploadBanner(image);
      final nextImages = [..._images, url];
      await _repository.saveImages(nextImages);
      setState(() => _images = nextImages);
      await _refreshConfig();
      _showSuccess('Banner uploaded.');
      debugPrint('[PilotManagement] banner:upload:success');
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _savingSection = null);
      }
    }
  }

  Future<void> _deleteBanner(String url) async {
    setState(() => _savingSection = 'banner_images');
    try {
      final nextImages = _images.where((image) => image != url).toList();
      await _repository.saveImages(nextImages);
      setState(() => _images = nextImages);
      await _refreshConfig();
      _showSuccess('Banner deleted.');
      debugPrint('[PilotManagement] banner:delete:success');
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _savingSection = null);
      }
    }
  }

  Future<void> _saveImages() {
    return _saveSection('banner_images', () {
      return _repository.saveImages(_images);
    });
  }

  Future<void> _savePilotSettings() {
    return _saveSection('pilot_settings', () {
      return _repository.savePilotSettings(
        maxOngoingBookings:
            _pilotSettingControllers['max_ongoing_bookings']!.text,
        gstCharges: _pilotSettingControllers['gst_charges']!.text,
        journeyBufferTime:
            _pilotSettingControllers['journey_buffer_time']!.text,
        currency: _pilotSettingControllers['currency']!.text,
        platformCharges: _pilotSettingControllers['platform_charges']!.text,
        minimumWalletAmount:
            _pilotSettingControllers['minimum_wallet_amount']!.text,
        maxServiceRadius: _pilotSettingControllers['max_service_radius']!.text,
      );
    });
  }

  Future<void> _saveHelpPrivacy() {
    return _saveSection('help_privacy', () {
      return _repository.saveHelpPrivacy(
        help: _helpController.text,
        privacyPolicy: _privacyController.text,
      );
    });
  }

  Future<void> _saveDefaultMarketPrice() {
    return _saveSection('default_market_price', () {
      return _repository.saveDefaultMarketPrice(
        _defaultMarketPriceController.text,
      );
    });
  }

  Future<void> _saveSection(
    String section,
    Future<void> Function() save,
  ) async {
    debugPrint('[PilotManagement] save:start section=$section');
    setState(() => _savingSection = section);
    try {
      await save();
      await _refreshConfig();
      _showSuccess('Saved successfully.');
      debugPrint('[PilotManagement] save:success section=$section');
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _savingSection = null);
      }
    }
  }

  void _showSuccess(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    final message = error.toString();
    debugPrint('[PilotManagement] error=$message');
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static const _servicePriceFields = [
    PilotSettingField(
      key: 'wedding',
      label: 'Wedding',
      icon: Icons.favorite_border_rounded,
      keyboardType: TextInputType.number,
      prefix: 'Rs ',
    ),
    PilotSettingField(
      key: 'aerial',
      label: 'Aerial',
      icon: Icons.flight_takeoff_outlined,
      keyboardType: TextInputType.number,
      prefix: 'Rs ',
    ),
    PilotSettingField(
      key: 'agriculture',
      label: 'Agriculture',
      icon: Icons.agriculture_outlined,
      keyboardType: TextInputType.number,
      prefix: 'Rs ',
    ),
  ];

  static const _requestRadiusField = PilotSettingField(
    key: 'request_radius',
    label: 'Request Radius',
    icon: Icons.radar_rounded,
    keyboardType: TextInputType.number,
    suffix: ' km',
  );

  static const _pilotSettingFields = [
    PilotSettingField(
      key: 'max_ongoing_bookings',
      label: 'Max Ongoing Bookings',
      icon: Icons.assignment_outlined,
      keyboardType: TextInputType.number,
    ),
    PilotSettingField(
      key: 'gst_charges',
      label: 'GST Charges',
      icon: Icons.receipt_long_outlined,
      keyboardType: TextInputType.number,
      suffix: ' %',
    ),
    PilotSettingField(
      key: 'journey_buffer_time',
      label: 'Journey Buffer Time',
      icon: Icons.more_time_rounded,
      keyboardType: TextInputType.number,
      suffix: ' min',
    ),
    PilotSettingField(
      key: 'currency',
      label: 'Currency',
      icon: Icons.currency_rupee_rounded,
    ),
    PilotSettingField(
      key: 'platform_charges',
      label: 'Platform Charges',
      icon: Icons.account_balance_outlined,
      keyboardType: TextInputType.number,
      suffix: ' %',
    ),
    PilotSettingField(
      key: 'minimum_wallet_amount',
      label: 'Minimum Wallet Amount',
      icon: Icons.account_balance_wallet_outlined,
      keyboardType: TextInputType.number,
      prefix: 'Rs ',
    ),
    PilotSettingField(
      key: 'max_service_radius',
      label: 'Max Service Radius',
      icon: Icons.social_distance_outlined,
      keyboardType: TextInputType.number,
      suffix: ' km',
    ),
  ];

  static const _defaultMarketPriceField = PilotSettingField(
    key: 'default_market_price',
    label: 'Default Market Price',
    icon: Icons.price_change_outlined,
    keyboardType: TextInputType.number,
    prefix: 'Rs ',
  );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.servicePriceFields,
    required this.servicePriceControllers,
    required this.requestRadiusField,
    required this.requestRadiusController,
    required this.services,
    required this.addServiceController,
    required this.images,
    required this.pilotSettingFields,
    required this.pilotSettingControllers,
    required this.helpController,
    required this.privacyController,
    required this.defaultMarketPriceField,
    required this.defaultMarketPriceController,
    required this.savingSection,
    required this.onSaveServicePrices,
    required this.onSaveRequestRadius,
    required this.onAddService,
    required this.onRemoveService,
    required this.onSaveServices,
    required this.onUploadBanner,
    required this.onDeleteBanner,
    required this.onSaveImages,
    required this.onSavePilotSettings,
    required this.onSaveHelpPrivacy,
    required this.onSaveDefaultMarketPrice,
  });

  final List<PilotSettingField> servicePriceFields;
  final Map<String, TextEditingController> servicePriceControllers;
  final PilotSettingField requestRadiusField;
  final TextEditingController requestRadiusController;
  final List<PilotServiceChipData> services;
  final TextEditingController addServiceController;
  final List<String> images;
  final List<PilotSettingField> pilotSettingFields;
  final Map<String, TextEditingController> pilotSettingControllers;
  final TextEditingController helpController;
  final TextEditingController privacyController;
  final PilotSettingField defaultMarketPriceField;
  final TextEditingController defaultMarketPriceController;
  final String? savingSection;
  final VoidCallback onSaveServicePrices;
  final VoidCallback onSaveRequestRadius;
  final VoidCallback onAddService;
  final ValueChanged<PilotServiceChipData> onRemoveService;
  final VoidCallback onSaveServices;
  final VoidCallback onUploadBanner;
  final ValueChanged<String> onDeleteBanner;
  final VoidCallback onSaveImages;
  final VoidCallback onSavePilotSettings;
  final VoidCallback onSaveHelpPrivacy;
  final VoidCallback onSaveDefaultMarketPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsiveTwoColumn(
          left: _ServicePricesSection(
            fields: servicePriceFields,
            controllers: servicePriceControllers,
            isSaving: savingSection == 'service_prices',
            onSave: onSaveServicePrices,
          ),
          right: _SingleSettingSection(
            icon: Icons.radar_rounded,
            title: 'Request Radius',
            subtitle: 'Control the default pilot request discovery range.',
            field: requestRadiusField,
            controller: requestRadiusController,
            isSaving: savingSection == 'request_radius',
            onSave: onSaveRequestRadius,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        PilotServiceManagementSection(
          controller: addServiceController,
          services: services,
          onAdd: onAddService,
          onRemove: onRemoveService,
          onSave: onSaveServices,
          isSaving: savingSection == 'services',
        ),
        SizedBox(height: AppSpacing.lg),
        _BannerImagesSection(
          images: images,
          isSaving: savingSection == 'banner_images',
          onUpload: onUploadBanner,
          onDelete: onDeleteBanner,
          onSave: onSaveImages,
        ),
        SizedBox(height: AppSpacing.lg),
        _PilotSettingsSection(
          fields: pilotSettingFields,
          controllers: pilotSettingControllers,
          isSaving: savingSection == 'pilot_settings',
          onSave: onSavePilotSettings,
        ),
        SizedBox(height: AppSpacing.lg),
        _ResponsiveTwoColumn(
          left: _TextAreaSection(
            icon: Icons.help_outline_rounded,
            title: 'Help',
            subtitle: 'Support URL shown inside the pilot app.',
            label: 'Help URL',
            controller: helpController,
          ),
          right: _TextAreaSection(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'Privacy policy URL shown inside the pilot app.',
            label: 'Privacy Policy URL',
            controller: privacyController,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.only(left: 1280.w),
          child: _SectionSaveButton(
            label: 'Save Help & Privacy',
            isSaving: savingSection == 'help_privacy',
            onPressed: onSaveHelpPrivacy,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        _SingleSettingSection(
          icon: Icons.price_change_outlined,
          title: 'Default Market Price',
          subtitle: 'Set the default comparison price for new services.',
          field: defaultMarketPriceField,
          controller: defaultMarketPriceController,
          isSaving: savingSection == 'default_market_price',
          onSave: onSaveDefaultMarketPrice,
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 30.r,
            offset: Offset(0, 16.h),
          ),
        ],
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 58.r,
            height: 58.r,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.background.withValues(alpha: 0.24),
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: AppColors.background,
              size: 30.r,
            ),
          ),
          SizedBox(
            width: 620.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilot Management',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.background,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Global pilot app configuration for pricing, services, '
                  'banners, operational limits and policy content.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.background.withValues(alpha: 0.82),
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

class _ServicePricesSection extends StatelessWidget {
  const _ServicePricesSection({
    required this.fields,
    required this.controllers,
    required this.isSaving,
    required this.onSave,
  });

  final List<PilotSettingField> fields;
  final Map<String, TextEditingController> controllers;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: Icons.payments_outlined,
      title: 'Service Prices',
      subtitle: 'Configure category level base prices.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final field in fields)
                SizedBox(
                  width: 240.w,
                  child: SettingsInput(
                    controller: controllers[field.key]!,
                    label: field.label,
                    icon: field.icon,
                    keyboardType: field.keyboardType,
                    prefix: field.prefix,
                    suffix: field.suffix,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _SectionSaveButton(
            label: 'Save Service Prices',
            isSaving: isSaving,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _SingleSettingSection extends StatelessWidget {
  const _SingleSettingSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.field,
    required this.controller,
    required this.isSaving,
    required this.onSave,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final PilotSettingField field;
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsInput(
            controller: controller,
            label: field.label,
            icon: field.icon,
            keyboardType: field.keyboardType,
            prefix: field.prefix,
            suffix: field.suffix,
          ),
          SizedBox(height: AppSpacing.lg),
          _SectionSaveButton(
            label: 'Save $title',
            isSaving: isSaving,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _BannerImagesSection extends StatelessWidget {
  const _BannerImagesSection({
    required this.images,
    required this.isSaving,
    required this.onUpload,
    required this.onDelete,
    required this.onSave,
  });

  final List<String> images;
  final bool isSaving;
  final VoidCallback onUpload;
  final ValueChanged<String> onDelete;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: Icons.image_outlined,
      title: 'Banner Images',
      subtitle: 'Firebase banner URLs shown in the pilot app.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (var index = 0; index < images.length; index++)
                _BannerImageCard(
                  index: index + 1,
                  url: images[index],
                  isSaving: isSaving,
                  onDelete: () => onDelete(images[index]),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              FilledButton.icon(
                onPressed: isSaving ? null : onUpload,
                icon: Icon(Icons.upload_rounded, size: 18.r),
                label: const Text('Upload Image'),
              ),
              _SectionSaveButton(
                label: 'Save Images',
                isSaving: isSaving,
                onPressed: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerImageCard extends StatelessWidget {
  const _BannerImageCard({
    required this.index,
    required this.url,
    required this.isSaving,
    required this.onDelete,
  });

  final int index;
  final String url;
  final bool isSaving;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.w,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: SizedBox(
              height: 132.h,
              width: double.infinity,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    debugPrint('[Banner] image loaded');
                    return child;
                  }
                  return const _BannerLoadingPlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  debugPrint('[Banner] url=$url');
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const _BannerLoadingPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('[Banner] url=$url');
                  debugPrint('[Banner] image failed=$error');
                  return PilotBannerHtmlImage(url: url);
                },
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Banner $index',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: isSaving ? null : onDelete,
            icon: Icon(Icons.delete_outline, size: 18.r),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BannerLoadingPlaceholder extends StatelessWidget {
  const _BannerLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.primaryBlueLight),
      child: Center(
        child: SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(strokeWidth: 2.r),
        ),
      ),
    );
  }
}

class _PilotSettingsSection extends StatelessWidget {
  const _PilotSettingsSection({
    required this.fields,
    required this.controllers,
    required this.isSaving,
    required this.onSave,
  });

  final List<PilotSettingField> fields;
  final Map<String, TextEditingController> controllers;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Pilot Settings',
      subtitle: 'Operational rules and financial limits for pilots.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final field in fields)
                SizedBox(
                  width: 280.w,
                  child: SettingsInput(
                    controller: controllers[field.key]!,
                    label: field.label,
                    icon: field.icon,
                    keyboardType: field.keyboardType,
                    prefix: field.prefix,
                    suffix: field.suffix,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _SectionSaveButton(
            label: 'Save Pilot Settings',
            isSaving: isSaving,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _TextAreaSection extends StatelessWidget {
  const _TextAreaSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.controller,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: TextFormField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          labelStyle: AppTextStyles.bodySmall,
          contentPadding: EdgeInsets.all(AppSpacing.md),
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
        ),
      ),
    );
  }
}

class _SectionSaveButton extends StatelessWidget {
  const _SectionSaveButton({
    required this.label,
    required this.isSaving,
    required this.onPressed,
  });

  final String label;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isSaving ? null : onPressed,
      icon: isSaving
          ? SizedBox(
              width: 16.r,
              height: 16.r,
              child: CircularProgressIndicator(strokeWidth: 2.r),
            )
          : Icon(Icons.save_outlined, size: 18.r),
      label: Text(isSaving ? 'Saving' : label),
    );
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  const _ResponsiveTwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980.w) {
          return Column(
            children: [
              left,
              SizedBox(height: AppSpacing.lg),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: AppSpacing.lg),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
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
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderLight),
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
