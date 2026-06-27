import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/pilot_management_model.dart';

class PilotManagementRepository {
  PilotManagementRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  static const collectionPath = 'config';
  static const storagePath = 'pilot_management/banners';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  DocumentReference<Map<String, dynamic>>? _resolvedConfigDocument;

  Future<PilotManagementConfig> loadConfig() async {
    final document = await _configDocument();
    final snapshot = await document.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const PilotManagementRepositoryException(
        'Firebase config document was not found.',
      );
    }

    return PilotManagementConfig.fromMap(data);
  }

  Future<void> saveServicePrices({
    required String wedding,
    required String aerial,
    required String agriculture,
  }) async {
    final document = await _configDocument();
    await document.update({
      'service_prices.wedding': _valueForFirestore(wedding),
      'service_prices.aerial': _valueForFirestore(aerial),
      'service_prices.agriculture': _valueForFirestore(agriculture),
    });
  }

  Future<void> saveRequestRadius(String value) async {
    final document = await _configDocument();
    await document.update({'pilot.request_radius': _valueForFirestore(value)});
  }

  Future<void> saveServices(List<String> services) async {
    final document = await _configDocument();
    await document.update({
      'services': services
          .map((service) => service.trim())
          .where((service) => service.isNotEmpty)
          .toList(),
    });
  }

  Future<void> savePilotSettings({
    required String maxOngoingBookings,
    required String gstCharges,
    required String journeyBufferTime,
    required String currency,
    required String platformCharges,
    required String minimumWalletAmount,
    required String maxServiceRadius,
  }) async {
    final document = await _configDocument();
    await document.update({
      'pilot.max_ongoing_bookings': _valueForFirestore(maxOngoingBookings),
      'pilot.gst_charges': _valueForFirestore(gstCharges),
      'pilot.journey_buffer_time': _valueForFirestore(journeyBufferTime),
      'pilot.currency': currency.trim(),
      'pilot.platform_charges': _valueForFirestore(platformCharges),
      'pilot.minimum_wallet_amount': _valueForFirestore(minimumWalletAmount),
      'pilot.max_service_radius': _valueForFirestore(maxServiceRadius),
    });
  }

  Future<void> saveHelpPrivacy({
    required String help,
    required String privacyPolicy,
  }) async {
    final document = await _configDocument();
    await document.update({
      'pilot.help': help.trim(),
      'pilot.privacy_policy': privacyPolicy.trim(),
    });
  }

  Future<void> saveDefaultMarketPrice(String value) async {
    final document = await _configDocument();
    await document.update({'default_market_price': _valueForFirestore(value)});
  }

  Future<String> uploadBanner(PickedPilotBannerImage image) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(image.name)}';
    final reference = _storage.ref('$storagePath/$fileName');
    await reference.putData(
      Uint8List.fromList(image.bytes),
      SettableMetadata(
        contentType: image.contentType.isEmpty ? 'image/*' : image.contentType,
      ),
    );
    return reference.getDownloadURL();
  }

  Future<void> saveImages(List<String> images) async {
    final document = await _configDocument();
    await document.update({
      'images': images
          .map((image) => image.trim())
          .where((image) => image.isNotEmpty)
          .toList(),
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> _configDocument() async {
    final cachedDocument = _resolvedConfigDocument;
    if (cachedDocument != null) {
      return cachedDocument;
    }

    final snapshot = await _firestore.collection(collectionPath).limit(1).get();
    if (snapshot.docs.isEmpty) {
      throw const PilotManagementRepositoryException(
        'Firebase config document was not found.',
      );
    }

    final document = snapshot.docs.first.reference;
    _resolvedConfigDocument = document;
    return document;
  }

  Object _valueForFirestore(String value) {
    final text = value.trim();
    final parsed = num.tryParse(text);
    return parsed ?? text;
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitized.isEmpty ? 'banner.jpg' : sanitized;
  }
}

class PilotManagementRepositoryException implements Exception {
  const PilotManagementRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
