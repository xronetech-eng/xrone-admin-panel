import 'package:flutter/material.dart';

class PilotManagementConfig {
  const PilotManagementConfig({
    required this.defaultMarketPrice,
    required this.servicePrices,
    required this.services,
    required this.images,
    required this.pilot,
  });

  final String defaultMarketPrice;
  final PilotServicePrices servicePrices;
  final List<String> services;
  final List<String> images;
  final PilotAppSettings pilot;

  factory PilotManagementConfig.fromMap(Map<String, dynamic> data) {
    return PilotManagementConfig(
      defaultMarketPrice: _stringValue(data['default_market_price']),
      servicePrices: PilotServicePrices.fromMap(
        _mapValue(data['service_prices']),
      ),
      services: _stringList(data['services']),
      images: _stringList(data['images']),
      pilot: PilotAppSettings.fromMap(_mapValue(data['pilot'])),
    );
  }
}

class PilotServicePrices {
  const PilotServicePrices({
    required this.wedding,
    required this.aerial,
    required this.agriculture,
  });

  final String wedding;
  final String aerial;
  final String agriculture;

  factory PilotServicePrices.fromMap(Map<String, dynamic> data) {
    return PilotServicePrices(
      wedding: _stringValue(data['wedding']),
      aerial: _stringValue(data['aerial']),
      agriculture: _stringValue(data['agriculture']),
    );
  }
}

class PilotAppSettings {
  const PilotAppSettings({
    required this.cancellationTillInMinutes,
    required this.currency,
    required this.gstCharges,
    required this.help,
    required this.journeyBufferTime,
    required this.maxOngoingBookings,
    required this.maxServiceRadius,
    required this.minimumWalletAmount,
    required this.platformCharges,
    required this.privacyPolicy,
    required this.requestRadius,
  });

  final String cancellationTillInMinutes;
  final String currency;
  final String gstCharges;
  final String help;
  final String journeyBufferTime;
  final String maxOngoingBookings;
  final String maxServiceRadius;
  final String minimumWalletAmount;
  final String platformCharges;
  final String privacyPolicy;
  final String requestRadius;

  factory PilotAppSettings.fromMap(Map<String, dynamic> data) {
    return PilotAppSettings(
      cancellationTillInMinutes: _stringValue(
        data['cancellation_till_in_minutes'],
      ),
      currency: _stringValue(data['currency']),
      gstCharges: _stringValue(data['gst_charges']),
      help: _stringValue(data['help']),
      journeyBufferTime: _stringValue(data['journey_buffer_time']),
      maxOngoingBookings: _stringValue(data['max_ongoing_bookings']),
      maxServiceRadius: _stringValue(data['max_service_radius']),
      minimumWalletAmount: _stringValue(data['minimum_wallet_amount']),
      platformCharges: _stringValue(data['platform_charges']),
      privacyPolicy: _stringValue(data['privacy_policy']),
      requestRadius: _stringValue(data['request_radius']),
    );
  }
}

class PilotSettingField {
  const PilotSettingField({
    required this.key,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
  });

  final String key;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? prefix;
  final String? suffix;
}

class PilotServiceChipData {
  const PilotServiceChipData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class PickedPilotBannerImage {
  const PickedPilotBannerImage({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final List<int> bytes;
  final String contentType;
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return [
      for (final item in value)
        if (_stringValue(item).isNotEmpty) _stringValue(item),
    ];
  }

  return const [];
}

String _stringValue(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.toLowerCase() == 'null' ? '' : text;
}
