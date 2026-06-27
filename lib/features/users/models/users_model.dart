import 'package:flutter/material.dart';

class UserAdminViewData {
  const UserAdminViewData({
    required this.id,
    required this.profileLabel,
    required this.name,
    required this.phone,
    required this.email,
    required this.gender,
    required this.city,
    required this.bookingsCount,
    required this.latestBookingDate,
    required this.latestBookingStatus,
    required this.status,
    required this.emergencyPhone,
    required this.createdDate,
    required this.savedLocations,
    required this.bookingHistory,
    required this.paymentHistory,
    required this.offersUsed,
    required this.liveTracking,
    this.activityHistory = const [],
  });

  final String id;
  final String profileLabel;
  final String name;
  final String phone;
  final String email;
  final String gender;
  final String city;
  final int bookingsCount;
  final String latestBookingDate;
  final String latestBookingStatus;
  final UserStatus status;
  final String emergencyPhone;
  final String createdDate;
  final List<UserSavedLocationData> savedLocations;
  final List<UserBookingHistoryData> bookingHistory;
  final List<UserPaymentHistoryData> paymentHistory;
  final List<UserActivityData> activityHistory;
  final List<UserOfferUsedData> offersUsed;
  final UserLiveTrackingData liveTracking;

  factory UserAdminViewData.fromUserRow(Map<String, dynamic> row) {
    final name = _readName(row, 'name');

    return UserAdminViewData(
      id: _readString(row, 'id'),
      profileLabel: _profileLabel(name),
      name: name,
      phone: _readString(row, 'phone', fallback: 'No phone'),
      email: _readString(row, 'email', fallback: 'No email'),
      gender: _readString(row, 'gender', fallback: 'Not specified'),
      city: 'Not specified',
      bookingsCount: 0,
      latestBookingDate: '-',
      latestBookingStatus: '-',
      status: UserStatus.active,
      emergencyPhone: _readString(row, 'emergency_phone', fallback: 'No phone'),
      createdDate: _formatDate(row['createdAt'] ?? row['created_at']),
      savedLocations: const [],
      bookingHistory: const [],
      paymentHistory: const [],
      activityHistory: const [],
      offersUsed: const [],
      liveTracking: UserLiveTrackingData.empty,
    );
  }

  factory UserAdminViewData.fromBookingSummary(
    Map<String, dynamic> summary, {
    Map<String, dynamic>? profile,
  }) {
    final userId = _readString(summary, 'user_id');
    final name = _readName(profile ?? const {}, 'name');

    return UserAdminViewData(
      id: userId,
      profileLabel: _profileLabel(name),
      name: name,
      phone: _readString(profile ?? const {}, 'phone', fallback: 'No phone'),
      email: _readString(profile ?? const {}, 'email', fallback: 'No email'),
      gender: _readString(
        profile ?? const {},
        'gender',
        fallback: 'Not specified',
      ),
      city: 'Not specified',
      bookingsCount: _readInt(summary, 'booking_count'),
      latestBookingDate: _formatDate(summary['latest_booking_at']),
      latestBookingStatus: _readString(
        summary,
        'latest_booking_status',
        fallback: '-',
      ),
      status: UserStatus.active,
      emergencyPhone: _readString(
        profile ?? const {},
        'emergency_phone',
        fallback: 'No phone',
      ),
      createdDate: _formatDate(
        profile == null
            ? summary['latest_booking_at']
            : profile['createdAt'] ?? profile['created_at'],
      ),
      savedLocations: const [],
      bookingHistory: const [],
      paymentHistory: const [],
      activityHistory: const [],
      offersUsed: const [],
      liveTracking: UserLiveTrackingData.empty,
    );
  }

  UserAdminViewData copyWith({
    String? profileLabel,
    String? name,
    String? phone,
    String? email,
    String? gender,
    String? city,
    int? bookingsCount,
    String? latestBookingDate,
    String? latestBookingStatus,
    UserStatus? status,
    String? emergencyPhone,
    String? createdDate,
    List<UserSavedLocationData>? savedLocations,
    List<UserBookingHistoryData>? bookingHistory,
    List<UserPaymentHistoryData>? paymentHistory,
    List<UserActivityData>? activityHistory,
    List<UserOfferUsedData>? offersUsed,
    UserLiveTrackingData? liveTracking,
  }) {
    return UserAdminViewData(
      id: id,
      profileLabel: profileLabel ?? this.profileLabel,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      latestBookingDate: latestBookingDate ?? this.latestBookingDate,
      latestBookingStatus: latestBookingStatus ?? this.latestBookingStatus,
      status: status ?? this.status,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      createdDate: createdDate ?? this.createdDate,
      savedLocations: savedLocations ?? this.savedLocations,
      bookingHistory: bookingHistory ?? this.bookingHistory,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      activityHistory: activityHistory ?? this.activityHistory,
      offersUsed: offersUsed ?? this.offersUsed,
      liveTracking: liveTracking ?? this.liveTracking,
    );
  }

  String get latestBookingStatusLabel {
    final value = latestBookingStatus.trim();
    return value.isEmpty ? '-' : value;
  }

  Color get latestBookingStatusColor {
    if (latestBookingStatus.trim().isEmpty || latestBookingStatus == '-') {
      return const Color(0xFF64748B);
    }

    return BookingStatusX.fromValue(latestBookingStatus).color;
  }
}

enum UserStatus { active, inactive }

extension UserStatusLabel on UserStatus {
  String get label {
    return switch (this) {
      UserStatus.active => 'Active',
      UserStatus.inactive => 'Inactive',
    };
  }

  Color get color {
    return switch (this) {
      UserStatus.active => const Color(0xFF16A34A),
      UserStatus.inactive => const Color(0xFFDC2626),
    };
  }
}

class UserSavedLocationData {
  const UserSavedLocationData({
    required this.title,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String latitude;
  final String longitude;

  factory UserSavedLocationData.fromRow(Map<String, dynamic> row) {
    return UserSavedLocationData(
      title: _readString(row, 'title', fallback: '-'),
      address: _readString(row, 'line_1', fallback: '-'),
      city: _readString(row, 'city', fallback: '-'),
      state: _readString(row, 'state', fallback: '-'),
      pincode: _readString(row, 'pincode', fallback: '-'),
      latitude: _readString(row, 'latitude', fallback: '-'),
      longitude: _readString(row, 'longitude', fallback: '-'),
    );
  }
}

class UserBookingHistoryData {
  const UserBookingHistoryData({
    required this.bookingId,
    required this.service,
    required this.pilot,
    required this.bookingDate,
    required this.status,
    required this.amount,
    required this.discount,
    required this.couponCode,
    required this.finalAmount,
    required this.cancellationReason,
    this.bookingIdTooltip = '',
    this.rawBookingId = '',
    this.sortDate,
  });

  final String bookingId;
  final String service;
  final String pilot;
  final String bookingDate;
  final BookingStatus status;
  final String amount;
  final String discount;
  final String couponCode;
  final String finalAmount;
  final String cancellationReason;
  final String bookingIdTooltip;
  final String rawBookingId;
  final DateTime? sortDate;

  String get bookingIdTooltipText =>
      bookingIdTooltip.isEmpty ? bookingId : bookingIdTooltip;
  String get lookupBookingId => rawBookingId.isEmpty ? bookingId : rawBookingId;

  factory UserBookingHistoryData.fromRow(Map<String, dynamic> row) {
    final price = _readAmount(row, 'price');
    final finalAmount = _readAmount(row, 'final_amount');
    final bookingId = _formatBookingId(row);

    return UserBookingHistoryData(
      bookingId: bookingId.text,
      bookingIdTooltip: bookingId.tooltip,
      rawBookingId: _readString(row, 'id', fallback: '-'),
      service: _serviceLabel(row),
      pilot: _pilotLabel(row),
      bookingDate: _formatDate(
        row['booking_date'] ?? row['createdAt'] ?? row['created_at'],
      ),
      sortDate: _dateFromRow(row, const [
        'booking_date',
        'createdAt',
        'created_at',
      ]),
      status: BookingStatusX.fromValue(_readString(row, 'status')),
      amount: _formatCurrency(price),
      discount: _formatCurrency(_discountAmount(price, finalAmount)),
      couponCode: _readString(row, 'coupon_code', fallback: '-'),
      finalAmount: _formatCurrency(finalAmount),
      cancellationReason: _readString(row, 'cancel_reason', fallback: '-'),
    );
  }
}

enum BookingStatus {
  requested,
  accepted,
  started,
  working,
  completed,
  declined,
  cancelled,
}

extension BookingStatusLabel on BookingStatus {
  String get label {
    return switch (this) {
      BookingStatus.requested => 'requested',
      BookingStatus.accepted => 'accepted',
      BookingStatus.started => 'started',
      BookingStatus.working => 'working',
      BookingStatus.completed => 'completed',
      BookingStatus.declined => 'declined',
      BookingStatus.cancelled => 'cancelled',
    };
  }

  Color get color {
    return switch (this) {
      BookingStatus.requested => const Color(0xFFF59E0B),
      BookingStatus.accepted => const Color(0xFF0B5ED7),
      BookingStatus.started => const Color(0xFF0891B2),
      BookingStatus.working => const Color(0xFF7C3AED),
      BookingStatus.completed => const Color(0xFF16A34A),
      BookingStatus.declined => const Color(0xFFDC2626),
      BookingStatus.cancelled => const Color(0xFF64748B),
    };
  }
}

extension BookingStatusX on BookingStatus {
  static BookingStatus fromValue(String value) {
    return switch (value.toLowerCase()) {
      'pending' || 'requested' => BookingStatus.requested,
      'accepted' => BookingStatus.accepted,
      'started' => BookingStatus.started,
      'working' => BookingStatus.working,
      'completed' => BookingStatus.completed,
      'declined' => BookingStatus.declined,
      'cancelled' || 'canceled' => BookingStatus.cancelled,
      _ => BookingStatus.requested,
    };
  }
}

class UserPaymentHistoryData {
  const UserPaymentHistoryData({
    required this.transactionId,
    required this.bookingId,
    required this.paymentType,
    required this.status,
    required this.totalPaid,
    required this.pilotCharges,
    required this.adminCharges,
    required this.transactionDate,
    this.bookingIdTooltip = '',
    this.sortDate,
  });

  final String transactionId;
  final String bookingId;
  final String paymentType;
  final String status;
  final String totalPaid;
  final String pilotCharges;
  final String adminCharges;
  final String transactionDate;
  final String bookingIdTooltip;
  final DateTime? sortDate;

  String get bookingIdTooltipText =>
      bookingIdTooltip.isEmpty ? bookingId : bookingIdTooltip;
  String get lookupBookingId =>
      bookingIdTooltip.isEmpty ? bookingId : bookingIdTooltip;

  factory UserPaymentHistoryData.fromRow(Map<String, dynamic> row) {
    final bookingId = _formatBookingId(row, key: 'booking_id');

    return UserPaymentHistoryData(
      transactionId: _readString(row, 'transaction_id', fallback: '-'),
      bookingId: bookingId.text,
      bookingIdTooltip: bookingId.tooltip,
      paymentType: _readString(row, 'transaction_type', fallback: '-'),
      status: _readString(row, 'status', fallback: '-'),
      totalPaid: _formatCurrency(_readAmount(row, 'total_paid_amount')),
      pilotCharges: _formatCurrency(_readAmount(row, 'pilot_charges')),
      adminCharges: _formatCurrency(_readAmount(row, 'admin_charges')),
      transactionDate: _formatDate(
        row['transaction_date'] ?? row['created_at'],
      ),
      sortDate: _dateFromRow(row, const ['transaction_date', 'created_at']),
    );
  }
}

class UserActivityData {
  const UserActivityData({
    required this.bookingId,
    required this.paymentId,
    required this.action,
    required this.status,
    required this.pilot,
    required this.dateTime,
    required this.source,
    this.sortDate,
  });

  final String bookingId;
  final String paymentId;
  final String action;
  final String status;
  final String pilot;
  final String dateTime;
  final String source;
  final DateTime? sortDate;
}

class UserOfferUsedData {
  const UserOfferUsedData({
    required this.offerTitle,
    required this.couponCode,
    required this.discountAmount,
    required this.usageDate,
  });

  final String offerTitle;
  final String couponCode;
  final String discountAmount;
  final String usageDate;

  factory UserOfferUsedData.fromRows({
    required Map<String, dynamic> userOffer,
    Map<String, dynamic>? offer,
  }) {
    return UserOfferUsedData(
      offerTitle: _firstString(offer, const [
        'title',
        'offer_title',
        'name',
        'description',
      ], fallback: '-'),
      couponCode: _firstString(
        offer,
        const ['offer_code', 'coupon_code', 'code'],
        fallback: _firstString(userOffer, const [
          'offer_code',
          'coupon_code',
          'code',
        ], fallback: '-'),
      ),
      discountAmount: _discountLabel(offer ?? userOffer),
      usageDate: _formatDate(userOffer['used_at'] ?? userOffer['createdAt']),
    );
  }
}

class UserLiveTrackingData {
  const UserLiveTrackingData({
    required this.currentBooking,
    required this.pilotName,
    required this.currentStatus,
    required this.latitude,
    required this.longitude,
    required this.trackingStatus,
    this.lastUpdated = '-',
  });

  final String currentBooking;
  final String pilotName;
  final String currentStatus;
  final String latitude;
  final String longitude;
  final String trackingStatus;
  final String lastUpdated;

  static const empty = UserLiveTrackingData(
    currentBooking: '-',
    pilotName: '-',
    currentStatus: '-',
    latitude: '-',
    longitude: '-',
    trackingStatus: 'inactive',
    lastUpdated: '-',
  );

  factory UserLiveTrackingData.fromRow(Map<String, dynamic> row) {
    final bookingId = _formatBookingId(row, key: 'booking_id');

    return UserLiveTrackingData(
      currentBooking: bookingId.text,
      pilotName: _pilotLabel(row),
      currentStatus: _readString(row, 'status', fallback: 'active'),
      latitude: _readString(row, 'latitude', fallback: '-'),
      longitude: _readString(row, 'longitude', fallback: '-'),
      trackingStatus: _readString(row, 'tracking_status', fallback: 'active'),
      lastUpdated: _formatDate(
        row['created_at'] ?? row['createdAt'] ?? row['updated_at'],
      ),
    );
  }
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
  return text.isEmpty ? fallback : text;
}

String _readName(Map<String, dynamic> row, String key) {
  final value = _readString(row, key);
  if (value.isEmpty || value == '-' || _looksLikeUuid(value)) {
    return 'Name not available';
  }

  return value;
}

String _serviceLabel(Map<String, dynamic> row) {
  final label = _firstDisplayString(row, const [
    'service_name',
    'service_title',
    'service_display_name',
    'service',
    'title',
    'name',
    'service_id',
  ]);

  return label ?? 'Service not available';
}

String _pilotLabel(Map<String, dynamic> row) {
  final label = _firstDisplayString(row, const [
    'pilot_name',
    'pilot_full_name',
    'full_name',
    'display_name',
    'name',
    'pilot_id',
  ]);

  return label ?? 'Pilot not assigned';
}

bool _looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value.trim());
}

bool _looksLikeNumericId(String value) => RegExp(r'^\d+$').hasMatch(value);

bool _isReadableLabel(String value) {
  final text = value.trim();
  return text.isNotEmpty &&
      text != '-' &&
      text.toLowerCase() != 'null' &&
      !_looksLikeUuid(text) &&
      !_looksLikeNumericId(text);
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

String _firstString(
  Map<String, dynamic>? row,
  List<String> keys, {
  required String fallback,
}) {
  if (row == null) {
    return fallback;
  }

  for (final key in keys) {
    final value = _readString(row, key);
    if (value.isNotEmpty) {
      return value;
    }
  }

  return fallback;
}

String _profileLabel(String name) {
  if (name == 'Name not available') {
    return 'NA';
  }

  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) {
    return 'U';
  }

  return words.take(2).map((word) => word[0].toUpperCase()).join();
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

DateTime? _dateFromRow(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];
    if (value == null) {
      continue;
    }
    final parsed = _parseDate(value);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
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

_DisplayValue _formatBookingId(Map<String, dynamic> row, {String key = 'id'}) {
  final display = _firstDisplayString(row, const [
    'booking_number',
    'booking_no',
    'booking_code',
    'booking_reference',
    'booking_ref',
    'reference_id',
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

String _truncateId(String value) {
  if (value.length <= 18) {
    return value;
  }

  return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
}

class _DisplayValue {
  const _DisplayValue(this.text, this.tooltip);

  final String text;
  final String tooltip;
}

num? _readAmount(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value;
  }

  return num.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.-]'), ''));
}

int _readInt(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num? _discountAmount(num? price, num? finalAmount) {
  if (price == null || finalAmount == null || price < finalAmount) {
    return null;
  }

  return price - finalAmount;
}

String _formatCurrency(num? amount) {
  if (amount == null) {
    return '-';
  }

  return 'Rs. ${amount.toDouble().toStringAsFixed(2)}';
}

String _discountLabel(Map<String, dynamic> row) {
  final amount =
      _readAmount(row, 'discount_amount') ?? _readAmount(row, 'discount');
  if (amount != null) {
    return _formatCurrency(amount);
  }

  final percent =
      _readAmount(row, 'discount_percentage') ?? _readAmount(row, 'percentage');
  if (percent != null) {
    final value = percent % 1 == 0
        ? percent.toInt().toString()
        : percent.toDouble().toStringAsFixed(2);
    return '$value%';
  }

  return '-';
}
