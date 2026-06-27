import 'package:flutter/material.dart';

class PilotAdminViewData {
  const PilotAdminViewData({
    required this.id,
    required this.profileLabel,
    required this.name,
    required this.phone,
    required this.email,
    required this.gender,
    required this.contactNumber,
    required this.createdDate,
    required this.profileImage,
    required this.licenseNumber,
    required this.servicesCount,
    required this.bookingsCount,
    required this.activeBookingsCount,
    required this.latestActivityDate,
    required this.status,
    required this.license,
    required this.bankDocuments,
    required this.drones,
    required this.services,
    required this.activeBookings,
    required this.invitations,
    required this.bookingHistory,
    required this.earnings,
    required this.transactions,
    required this.walletHistory,
    required this.liveTracking,
    required this.locations,
    required this.banners,
  });

  final String id;
  final String profileLabel;
  final String name;
  final String phone;
  final String email;
  final String gender;
  final String contactNumber;
  final String createdDate;
  final String profileImage;
  final String licenseNumber;
  final int servicesCount;
  final int bookingsCount;
  final int activeBookingsCount;
  final String latestActivityDate;
  final PilotStatus status;
  final PilotLicenseData license;
  final PilotBankDocumentsData bankDocuments;
  final List<PilotDroneData> drones;
  final List<PilotServiceData> services;
  final List<PilotActiveBookingData> activeBookings;
  final List<PilotInvitationData> invitations;
  final List<PilotBookingHistoryData> bookingHistory;
  final PilotEarningsData earnings;
  final List<PilotTransactionData> transactions;
  final List<PilotWalletHistoryData> walletHistory;
  final PilotLiveTrackingData liveTracking;
  final List<PilotLocationData> locations;
  final List<PilotBannerImageData> banners;

  factory PilotAdminViewData.fromPilotRow(
    Map<String, dynamic> row, {
    int servicesCount = 0,
    int bookingsCount = 0,
    int activeBookingsCount = 0,
    Object? latestActivity,
  }) {
    final name = _readName(row, 'name', fallback: 'Pilot not available');
    final latestActivityDate = _formatDate(latestActivity);

    return PilotAdminViewData(
      id: _readString(row, 'id'),
      profileLabel: _profileLabel(name),
      name: name,
      phone: _readString(row, 'contact_number', fallback: 'No phone'),
      email: _readString(row, 'email', fallback: 'No email'),
      gender: _readString(row, 'gender', fallback: 'Not specified'),
      contactNumber: _readString(row, 'contact_number', fallback: 'No phone'),
      createdDate: _formatDate(row['created_at'] ?? row['createdAt']),
      profileImage: _readString(row, 'profile_image'),
      licenseNumber: _readString(row, 'license_number', fallback: '-'),
      servicesCount: servicesCount,
      bookingsCount: bookingsCount,
      activeBookingsCount: activeBookingsCount,
      latestActivityDate: latestActivityDate,
      status: _derivePilotStatus(activeBookingsCount, latestActivity),
      license: PilotLicenseData.fromPilotRow(row),
      bankDocuments: PilotBankDocumentsData.empty,
      drones: const [],
      services: const [],
      activeBookings: const [],
      invitations: const [],
      bookingHistory: const [],
      earnings: PilotEarningsData.empty,
      transactions: const [],
      walletHistory: const [],
      liveTracking: PilotLiveTrackingData.empty,
      locations: const [],
      banners: const [],
    );
  }

  PilotAdminViewData copyWith({
    String? profileLabel,
    String? name,
    String? phone,
    String? email,
    String? gender,
    String? contactNumber,
    String? createdDate,
    String? profileImage,
    String? licenseNumber,
    int? servicesCount,
    int? bookingsCount,
    int? activeBookingsCount,
    String? latestActivityDate,
    PilotStatus? status,
    PilotLicenseData? license,
    PilotBankDocumentsData? bankDocuments,
    List<PilotDroneData>? drones,
    List<PilotServiceData>? services,
    List<PilotActiveBookingData>? activeBookings,
    List<PilotInvitationData>? invitations,
    List<PilotBookingHistoryData>? bookingHistory,
    PilotEarningsData? earnings,
    List<PilotTransactionData>? transactions,
    List<PilotWalletHistoryData>? walletHistory,
    PilotLiveTrackingData? liveTracking,
    List<PilotLocationData>? locations,
    List<PilotBannerImageData>? banners,
  }) {
    return PilotAdminViewData(
      id: id,
      profileLabel: profileLabel ?? this.profileLabel,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      contactNumber: contactNumber ?? this.contactNumber,
      createdDate: createdDate ?? this.createdDate,
      profileImage: profileImage ?? this.profileImage,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      servicesCount: servicesCount ?? this.servicesCount,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      activeBookingsCount: activeBookingsCount ?? this.activeBookingsCount,
      latestActivityDate: latestActivityDate ?? this.latestActivityDate,
      status: status ?? this.status,
      license: license ?? this.license,
      bankDocuments: bankDocuments ?? this.bankDocuments,
      drones: drones ?? this.drones,
      services: services ?? this.services,
      activeBookings: activeBookings ?? this.activeBookings,
      invitations: invitations ?? this.invitations,
      bookingHistory: bookingHistory ?? this.bookingHistory,
      earnings: earnings ?? this.earnings,
      transactions: transactions ?? this.transactions,
      walletHistory: walletHistory ?? this.walletHistory,
      liveTracking: liveTracking ?? this.liveTracking,
      locations: locations ?? this.locations,
      banners: banners ?? this.banners,
    );
  }
}

enum PilotStatus { active, inactive }

extension PilotStatusLabel on PilotStatus {
  String get label {
    return switch (this) {
      PilotStatus.active => 'Active',
      PilotStatus.inactive => 'Inactive',
    };
  }

  Color get color {
    return switch (this) {
      PilotStatus.active => const Color(0xFF16A34A),
      PilotStatus.inactive => const Color(0xFFDC2626),
    };
  }
}

class PilotLicenseData {
  const PilotLicenseData({
    required this.licenseNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.licenseImage,
  });

  final String licenseNumber;
  final String issueDate;
  final String expiryDate;
  final String licenseImage;

  static const empty = PilotLicenseData(
    licenseNumber: '-',
    issueDate: '-',
    expiryDate: '-',
    licenseImage: '-',
  );

  factory PilotLicenseData.fromPilotRow(Map<String, dynamic> row) {
    return PilotLicenseData(
      licenseNumber: _readString(row, 'license_number', fallback: '-'),
      issueDate: _formatDate(row['issue_date']),
      expiryDate: _formatDate(row['expiry_date']),
      licenseImage: _readString(row, 'license_image', fallback: '-'),
    );
  }
}

class PilotBankDocumentsData {
  const PilotBankDocumentsData({
    required this.bankName,
    required this.accountNumber,
    required this.ifsc,
    required this.upiId,
    required this.panNumber,
    required this.panImage,
    required this.aadhaarNumber,
    required this.aadhaarImage,
  });

  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String upiId;
  final String panNumber;
  final String panImage;
  final String aadhaarNumber;
  final String aadhaarImage;

  static const empty = PilotBankDocumentsData(
    bankName: '-',
    accountNumber: '-',
    ifsc: '-',
    upiId: '-',
    panNumber: '-',
    panImage: '-',
    aadhaarNumber: '-',
    aadhaarImage: '-',
  );

  factory PilotBankDocumentsData.fromRow(Map<String, dynamic> row) {
    return PilotBankDocumentsData(
      bankName: _readString(row, 'bank_name', fallback: '-'),
      accountNumber: _maskLastFour(_readString(row, 'account_number')),
      ifsc: _readString(row, 'ifsc', fallback: '-'),
      upiId: _readString(row, 'upi_id', fallback: '-'),
      panNumber: _maskPan(_readString(row, 'pan_number')),
      panImage: _readString(row, 'pan_image', fallback: '-'),
      aadhaarNumber: _maskAadhaar(_readString(row, 'adhaar_number')),
      aadhaarImage: _readString(row, 'adhaar_image', fallback: '-'),
    );
  }
}

class PilotDroneData {
  const PilotDroneData({
    required this.id,
    required this.droneName,
    required this.droneType,
  });

  final String id;
  final String droneName;
  final String droneType;

  factory PilotDroneData.fromRow(Map<String, dynamic> row) {
    return PilotDroneData(
      id: _readString(row, 'id'),
      droneName: _readString(row, 'name', fallback: '-'),
      droneType: _readString(row, 'type', fallback: '-'),
    );
  }
}

class PilotServiceData {
  const PilotServiceData({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.marketPrice,
    required this.platformCharges,
    required this.gst,
    required this.area,
    required this.serviceRadius,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.rawPrice,
    required this.rawMarketPrice,
    required this.rawPlatformCharges,
    required this.rawGst,
    required this.rawServiceRadius,
  });

  final String id;
  final String title;
  final String category;
  final String price;
  final String marketPrice;
  final String platformCharges;
  final String gst;
  final String area;
  final String serviceRadius;
  final String latitude;
  final String longitude;
  final bool isActive;
  final String rawPrice;
  final String rawMarketPrice;
  final String rawPlatformCharges;
  final String rawGst;
  final String rawServiceRadius;

  factory PilotServiceData.fromRow(Map<String, dynamic> row) {
    final price = row['price'];
    final marketPrice = row['market_price'];

    return PilotServiceData(
      id: _readString(row, 'id'),
      title: _readString(row, 'title', fallback: '-'),
      category: _readString(row, 'category', fallback: '-'),
      price: _formatCurrency(_readAmountValue(price)),
      marketPrice: _formatCurrency(_readAmountValue(marketPrice)),
      platformCharges: _percentLabel(row['platform_charges_percent']),
      gst: _percentLabel(row['gst_percent_charges']),
      area: _readString(row, 'area', fallback: '-'),
      serviceRadius: _readString(row, 'service_radius', fallback: '-'),
      latitude: _readString(row, 'latitude', fallback: '-'),
      longitude: _readString(row, 'longitude', fallback: '-'),
      isActive: _readBool(row, 'is_active', fallback: true),
      rawPrice: _rawAmount(price),
      rawMarketPrice: _rawAmount(marketPrice),
      rawPlatformCharges: _rawAmount(row['platform_charges_percent']),
      rawGst: _rawAmount(row['gst_percent_charges']),
      rawServiceRadius: _readString(row, 'service_radius'),
    );
  }

  PilotServiceData copyWith({
    String? rawPrice,
    String? rawMarketPrice,
    String? rawPlatformCharges,
    String? rawGst,
    String? rawServiceRadius,
  }) {
    final nextRawPrice = rawPrice ?? this.rawPrice;
    final nextRawMarketPrice = rawMarketPrice ?? this.rawMarketPrice;
    final nextRawPlatformCharges =
        rawPlatformCharges ?? this.rawPlatformCharges;
    final nextRawGst = rawGst ?? this.rawGst;
    final nextRawServiceRadius = rawServiceRadius ?? this.rawServiceRadius;

    return PilotServiceData(
      id: id,
      title: title,
      category: category,
      price: _formatCurrency(_readAmountValue(nextRawPrice)),
      marketPrice: _formatCurrency(_readAmountValue(nextRawMarketPrice)),
      platformCharges: _percentLabel(nextRawPlatformCharges),
      gst: _percentLabel(nextRawGst),
      area: area,
      serviceRadius: nextRawServiceRadius.trim().isEmpty
          ? '-'
          : nextRawServiceRadius,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive,
      rawPrice: nextRawPrice,
      rawMarketPrice: nextRawMarketPrice,
      rawPlatformCharges: nextRawPlatformCharges,
      rawGst: nextRawGst,
      rawServiceRadius: nextRawServiceRadius,
    );
  }
}

class PilotServiceMutationData {
  const PilotServiceMutationData({
    required this.title,
    required this.category,
    required this.price,
    required this.marketPrice,
    required this.platformCharges,
    required this.gst,
    required this.area,
    required this.serviceRadius,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  final String title;
  final String category;
  final String price;
  final String marketPrice;
  final String platformCharges;
  final String gst;
  final String area;
  final String serviceRadius;
  final String latitude;
  final String longitude;
  final bool isActive;

  Map<String, Object?> toServiceColumns({
    required String pilotId,
    required num Function(String value) parseAmount,
    required num Function(String value) parsePercent,
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw const PilotsModelException('Enter a service title.');
    }

    return {
      'pilot_id': pilotId,
      'title': normalizedTitle,
      'category': category.trim(),
      'price': parseAmount(price),
      'market_price': parseAmount(marketPrice),
      'platform_charges_percent': parsePercent(platformCharges),
      'gst_percent_charges': parsePercent(gst),
      'area': area.trim(),
      'service_radius': serviceRadius.trim(),
      'latitude': latitude.trim(),
      'longitude': longitude.trim(),
      'is_active': isActive,
    };
  }
}

class PilotsModelException implements Exception {
  const PilotsModelException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PilotActiveBookingData {
  const PilotActiveBookingData({
    required this.bookingId,
    required this.bookingIdTooltip,
    required this.user,
    required this.customerPhone,
    required this.service,
    required this.status,
    required this.bookingDate,
    required this.location,
    required this.area,
    required this.price,
  });

  final String bookingId;
  final String bookingIdTooltip;
  final String user;
  final String customerPhone;
  final String service;
  final ActiveBookingStatus status;
  final String bookingDate;
  final String location;
  final String area;
  final String price;

  String get bookingIdTooltipText =>
      bookingIdTooltip.isEmpty ? bookingId : bookingIdTooltip;

  factory PilotActiveBookingData.fromRow(Map<String, dynamic> row) {
    final bookingId = _formatRecordId(row);

    return PilotActiveBookingData(
      bookingId: bookingId.text,
      bookingIdTooltip: bookingId.tooltip,
      user: _readString(
        row,
        'customer_name',
        fallback: 'Customer not available',
      ),
      customerPhone: _readString(row, 'customer_phone', fallback: '-'),
      service: _readString(row, 'service_title', fallback: '-'),
      status: ActiveBookingStatusX.fromValue(_readString(row, 'status')),
      bookingDate: _formatDate(
        row['booking_date'] ?? row['created_at'] ?? row['createdAt'],
      ),
      location: _readString(row, 'location', fallback: '-'),
      area: _readString(row, 'area', fallback: '-'),
      price: _formatCurrency(
        _firstAmount(row, const ['price', 'final_amount']),
      ),
    );
  }
}

enum ActiveBookingStatus { accepted, started, working, requested }

extension ActiveBookingStatusLabel on ActiveBookingStatus {
  String get label {
    return switch (this) {
      ActiveBookingStatus.accepted => 'accepted',
      ActiveBookingStatus.started => 'started',
      ActiveBookingStatus.working => 'working',
      ActiveBookingStatus.requested => 'requested',
    };
  }

  Color get color {
    return switch (this) {
      ActiveBookingStatus.accepted => const Color(0xFF0B5ED7),
      ActiveBookingStatus.started => const Color(0xFF0891B2),
      ActiveBookingStatus.working => const Color(0xFF7C3AED),
      ActiveBookingStatus.requested => const Color(0xFFF59E0B),
    };
  }
}

extension ActiveBookingStatusX on ActiveBookingStatus {
  static ActiveBookingStatus fromValue(String value) {
    return switch (value.toLowerCase()) {
      'accepted' => ActiveBookingStatus.accepted,
      'started' => ActiveBookingStatus.started,
      'working' => ActiveBookingStatus.working,
      _ => ActiveBookingStatus.requested,
    };
  }
}

class PilotInvitationData {
  const PilotInvitationData({
    required this.invitationId,
    required this.invitationIdTooltip,
    required this.user,
    required this.service,
    required this.bookingDate,
    required this.area,
    required this.price,
    required this.status,
  });

  final String invitationId;
  final String invitationIdTooltip;
  final String user;
  final String service;
  final String bookingDate;
  final String area;
  final String price;
  final String status;

  String get invitationIdTooltipText =>
      invitationIdTooltip.isEmpty ? invitationId : invitationIdTooltip;

  factory PilotInvitationData.fromRow(Map<String, dynamic> row) {
    final invitationId = _formatRecordId(row);

    return PilotInvitationData(
      invitationId: invitationId.text,
      invitationIdTooltip: invitationId.tooltip,
      user: _readString(
        row,
        'customer_name',
        fallback: 'Customer not available',
      ),
      service: _readString(row, 'service_title', fallback: '-'),
      bookingDate: _formatDate(
        row['booking_date'] ?? row['created_at'] ?? row['createdAt'],
      ),
      area: _readString(row, 'area', fallback: '-'),
      price: _formatCurrency(
        _firstAmount(row, const ['price', 'final_amount']),
      ),
      status: _readString(row, 'status', fallback: '-'),
    );
  }
}

class PilotBookingHistoryData {
  const PilotBookingHistoryData({
    required this.bookingId,
    required this.bookingIdTooltip,
    required this.user,
    required this.service,
    required this.status,
    required this.bookingDate,
    required this.location,
    required this.price,
  });

  final String bookingId;
  final String bookingIdTooltip;
  final String user;
  final String service;
  final BookingHistoryStatus status;
  final String bookingDate;
  final String location;
  final String price;

  String get bookingIdTooltipText =>
      bookingIdTooltip.isEmpty ? bookingId : bookingIdTooltip;

  factory PilotBookingHistoryData.fromRow(Map<String, dynamic> row) {
    final bookingId = _formatRecordId(row);

    return PilotBookingHistoryData(
      bookingId: bookingId.text,
      bookingIdTooltip: bookingId.tooltip,
      user: _readString(
        row,
        'customer_name',
        fallback: 'Customer not available',
      ),
      service: _readString(row, 'service_title', fallback: '-'),
      status: BookingHistoryStatusX.fromValue(_readString(row, 'status')),
      bookingDate: _formatDate(
        row['booking_date'] ?? row['created_at'] ?? row['createdAt'],
      ),
      location: _readString(row, 'location', fallback: '-'),
      price: _formatCurrency(
        _firstAmount(row, const ['price', 'final_amount']),
      ),
    );
  }
}

enum BookingHistoryStatus { completed, cancelled }

extension BookingHistoryStatusLabel on BookingHistoryStatus {
  String get label {
    return switch (this) {
      BookingHistoryStatus.completed => 'completed',
      BookingHistoryStatus.cancelled => 'cancelled',
    };
  }

  Color get color {
    return switch (this) {
      BookingHistoryStatus.completed => const Color(0xFF16A34A),
      BookingHistoryStatus.cancelled => const Color(0xFF64748B),
    };
  }
}

extension BookingHistoryStatusX on BookingHistoryStatus {
  static BookingHistoryStatus fromValue(String value) {
    return switch (value.toLowerCase()) {
      'completed' => BookingHistoryStatus.completed,
      _ => BookingHistoryStatus.cancelled,
    };
  }
}

class PilotEarningsData {
  const PilotEarningsData({
    required this.currentBalance,
    required this.totalEarnings,
    required this.totalTrips,
    required this.lastUpdated,
  });

  final String currentBalance;
  final String totalEarnings;
  final String totalTrips;
  final String lastUpdated;

  static const empty = PilotEarningsData(
    currentBalance: '-',
    totalEarnings: '-',
    totalTrips: '-',
    lastUpdated: '-',
  );

  factory PilotEarningsData.fromRow(Map<String, dynamic> row) {
    return PilotEarningsData(
      currentBalance: _formatCurrency(_readAmount(row, 'current_balance')),
      totalEarnings: _formatCurrency(_readAmount(row, 'total_earnings')),
      totalTrips: _readString(row, 'total_trips', fallback: '-'),
      lastUpdated: _formatDate(
        row['last_updated'] ?? row['updated_at'] ?? row['created_at'],
      ),
    );
  }
}

class PilotTransactionData {
  const PilotTransactionData({
    required this.transactionId,
    required this.bookingId,
    required this.bookingIdTooltip,
    required this.transactionType,
    required this.status,
    required this.pilotCharges,
    required this.adminCharges,
    required this.transactionDate,
  });

  final String transactionId;
  final String bookingId;
  final String bookingIdTooltip;
  final String transactionType;
  final String status;
  final String pilotCharges;
  final String adminCharges;
  final String transactionDate;

  String get bookingIdTooltipText =>
      bookingIdTooltip.isEmpty ? bookingId : bookingIdTooltip;

  factory PilotTransactionData.fromRow(Map<String, dynamic> row) {
    final bookingId = _formatRecordId(row, key: 'booking_id');

    return PilotTransactionData(
      transactionId: _readString(row, 'transaction_id', fallback: '-'),
      bookingId: bookingId.text,
      bookingIdTooltip: bookingId.tooltip,
      transactionType: _readString(row, 'transaction_type', fallback: '-'),
      status: _readString(row, 'status', fallback: '-'),
      pilotCharges: _formatCurrency(_readAmount(row, 'pilot_charges')),
      adminCharges: _formatCurrency(_readAmount(row, 'admin_charges')),
      transactionDate: _formatDate(row['transaction_date']),
    );
  }
}

class PilotWalletHistoryData {
  const PilotWalletHistoryData({
    required this.amount,
    required this.type,
    required this.description,
    required this.balanceAfterTransaction,
    required this.createdDate,
  });

  final String amount;
  final String type;
  final String description;
  final String balanceAfterTransaction;
  final String createdDate;

  factory PilotWalletHistoryData.fromRow(Map<String, dynamic> row) {
    return PilotWalletHistoryData(
      amount: _formatCurrency(_readAmount(row, 'amount')),
      type: _readString(row, 'type', fallback: '-'),
      description: _readString(row, 'description', fallback: '-'),
      balanceAfterTransaction: _formatCurrency(
        _readAmount(row, 'balance_after_transaction'),
      ),
      createdDate: _formatDate(row['created_at'] ?? row['createdAt']),
    );
  }
}

class PilotLiveTrackingData {
  const PilotLiveTrackingData({
    required this.bookingId,
    required this.bookingIdTooltip,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.currentStatus,
    required this.latestTrackingUpdate,
  });

  final String bookingId;
  final String bookingIdTooltip;
  final String currentLatitude;
  final String currentLongitude;
  final String currentStatus;
  final String latestTrackingUpdate;

  static const empty = PilotLiveTrackingData(
    bookingId: '-',
    bookingIdTooltip: '-',
    currentLatitude: '-',
    currentLongitude: '-',
    currentStatus: '-',
    latestTrackingUpdate: '-',
  );

  factory PilotLiveTrackingData.fromRow(Map<String, dynamic> row) {
    final bookingId = _formatRecordId(row, key: 'booking_id');

    return PilotLiveTrackingData(
      bookingId: bookingId.text,
      bookingIdTooltip: bookingId.tooltip,
      currentLatitude: _readString(row, 'latitude', fallback: '-'),
      currentLongitude: _readString(row, 'longitude', fallback: '-'),
      currentStatus: _readString(row, 'status', fallback: '-'),
      latestTrackingUpdate: _formatDate(row['created_at'] ?? row['updated_at']),
    );
  }
}

class PilotLocationData {
  const PilotLocationData({
    required this.title,
    required this.line1,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final String line1;
  final String city;
  final String state;
  final String pincode;
  final String latitude;
  final String longitude;

  factory PilotLocationData.fromRow(Map<String, dynamic> row) {
    return PilotLocationData(
      title: _readString(row, 'title', fallback: '-'),
      line1: _readString(row, 'line_1', fallback: '-'),
      city: _readString(row, 'city', fallback: '-'),
      state: _readString(row, 'state', fallback: '-'),
      pincode: _readString(row, 'pincode', fallback: '-'),
      latitude: _readString(row, 'latitude', fallback: '-'),
      longitude: _readString(row, 'longitude', fallback: '-'),
    );
  }
}

class PilotBannerImageData {
  const PilotBannerImageData({
    required this.name,
    required this.path,
    required this.url,
  });

  final String name;
  final String path;
  final String url;
}

class PilotBookingCollections {
  const PilotBookingCollections({
    required this.activeBookings,
    required this.bookingHistory,
  });

  final List<PilotActiveBookingData> activeBookings;
  final List<PilotBookingHistoryData> bookingHistory;
}

bool isActivePilotBookingStatus(String status) {
  final value = status.toLowerCase().trim();
  return value == 'accepted' || value == 'started' || value == 'working';
}

bool isHistoryPilotBookingStatus(String status) {
  final value = status.toLowerCase().trim();
  return value == 'completed' || value == 'cancelled' || value == 'canceled';
}

String pilotDisplayDate(Object? value) => _formatDate(value);

String pilotDisplayCurrency(Object? value) =>
    _formatCurrency(_readAmountValue(value));

String pilotRawAmount(Object? value) => _rawAmount(value);

String pilotReadString(
  Map<String, dynamic> row,
  String key, {
  String fallback = '',
}) {
  return _readString(row, key, fallback: fallback);
}

String _readString(
  Map<String, dynamic> row,
  String key, {
  String fallback = '',
}) {
  final value = row[key];
  if (value == null) {
    return fallback;
  }

  final text = value.toString().trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? fallback : text;
}

String _readName(
  Map<String, dynamic> row,
  String key, {
  required String fallback,
}) {
  final value = _readString(row, key);
  if (value.isEmpty || value == '-' || _looksLikeUuid(value)) {
    return fallback;
  }

  return value;
}

String _profileLabel(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty || name == 'Pilot not available') {
    return 'P';
  }

  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

PilotStatus _derivePilotStatus(
  int activeBookingsCount,
  Object? latestActivity,
) {
  if (activeBookingsCount > 0) {
    return PilotStatus.active;
  }

  if (latestActivity == null) {
    return PilotStatus.inactive;
  }

  final parsed = _parseDate(latestActivity);
  if (parsed == null) {
    return PilotStatus.inactive;
  }

  return DateTime.now().difference(parsed).inDays <= 30
      ? PilotStatus.active
      : PilotStatus.inactive;
}

String _formatDate(Object? value) {
  if (value == null) {
    return '-';
  }

  final parsed = _parseDate(value);
  if (parsed == null) {
    final text = value.toString().trim();
    return text.isEmpty || _looksLikeNumericId(text) ? '-' : text;
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final date =
      '${parsed.day.toString().padLeft(2, '0')} '
      '${months[parsed.month - 1]} ${parsed.year}';
  if (parsed.hour == 0 && parsed.minute == 0 && parsed.second == 0) {
    return date;
  }

  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '$date, $hour:$minute $period';
}

DateTime? _parseDate(Object value) {
  if (value is num) {
    return _parseEpoch(value);
  }

  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }

  final numeric = num.tryParse(text);
  if (numeric != null && RegExp(r'^\d{10,}$').hasMatch(text)) {
    return _parseEpoch(numeric);
  }

  return DateTime.tryParse(text);
}

DateTime? _parseEpoch(num value) {
  if (value <= 0) {
    return null;
  }

  final milliseconds = value > 9999999999
      ? value.toInt()
      : value.toInt() * 1000;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds);
}

bool _readBool(Map<String, dynamic> row, String key, {required bool fallback}) {
  final value = row[key];
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }

  return switch (value?.toString().toLowerCase().trim()) {
    'true' || '1' || 'yes' || 'active' => true,
    'false' || '0' || 'no' || 'inactive' => false,
    _ => fallback,
  };
}

bool _looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value.trim());
}

bool _looksLikeNumericId(String value) => RegExp(r'^\d+$').hasMatch(value);

num? _readAmount(Map<String, dynamic> row, String key) {
  return _readAmountValue(row[key]);
}

num? _firstAmount(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final amount = _readAmount(row, key);
    if (amount != null) {
      return amount;
    }
  }
  return null;
}

num? _readAmountValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value;
  }

  return num.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.-]'), ''));
}

String _rawAmount(Object? value) {
  final amount = _readAmountValue(value);
  if (amount == null) {
    return '';
  }
  return amount % 1 == 0
      ? amount.toInt().toString()
      : amount.toDouble().toStringAsFixed(2);
}

String _formatCurrency(num? amount) {
  if (amount == null) {
    return '-';
  }

  return 'Rs. ${amount.toDouble().toStringAsFixed(2)}';
}

String _percentLabel(Object? value) {
  final amount = _readAmountValue(value);
  if (amount == null) {
    return '-';
  }

  final text = amount % 1 == 0
      ? amount.toInt().toString()
      : amount.toDouble().toStringAsFixed(2);
  return '$text%';
}

_DisplayValue _formatRecordId(Map<String, dynamic> row, {String key = 'id'}) {
  final display = _firstDisplayString(row, const [
    'booking_number',
    'booking_no',
    'booking_code',
    'booking_reference',
    'booking_ref',
    'reference_id',
    'invitation_number',
    'invitation_code',
  ]);
  if (display != null) {
    return _DisplayValue(display, display);
  }

  final raw = _readString(row, key, fallback: '-');
  if (raw == '-' || raw.isEmpty) {
    return const _DisplayValue('-', '-');
  }

  if (_looksLikeUuid(raw) || raw.length > 18) {
    return _DisplayValue(_truncateId(raw), raw);
  }

  return _DisplayValue(raw, raw);
}

String? _firstDisplayString(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = _readString(row, key);
    if (_isReadableLabel(value)) {
      return value;
    }
  }

  return null;
}

bool _isReadableLabel(String value) {
  final text = value.trim();
  return text.isNotEmpty &&
      text != '-' &&
      text.toLowerCase() != 'null' &&
      !_looksLikeUuid(text) &&
      !_looksLikeNumericId(text);
}

String _truncateId(String value) {
  if (value.length <= 18) {
    return value;
  }

  return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
}

String _maskLastFour(String value) {
  final digits = value.replaceAll(RegExp(r'\s+'), '');
  if (digits.isEmpty) {
    return '-';
  }
  final suffix = digits.length <= 4
      ? digits
      : digits.substring(digits.length - 4);
  return 'XXXXXX$suffix';
}

String _maskPan(String value) {
  final text = value.trim().toUpperCase();
  if (text.isEmpty) {
    return '-';
  }
  if (text.length <= 6) {
    return '${text.substring(0, 1)}****${text.substring(text.length - 1)}';
  }
  return '${text.substring(0, 5)}****${text.substring(text.length - 1)}';
}

String _maskAadhaar(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return '-';
  }
  final suffix = digits.length <= 4
      ? digits
      : digits.substring(digits.length - 4);
  return 'XXXX XXXX $suffix';
}

class _DisplayValue {
  const _DisplayValue(this.text, this.tooltip);

  final String text;
  final String tooltip;
}
