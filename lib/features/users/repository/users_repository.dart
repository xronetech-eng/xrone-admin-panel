import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/users_model.dart';

class UsersRepository {
  UsersRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  Future<List<UserAdminViewData>> fetchUsers() async {
    _log('currentUser=${_client.auth.currentUser?.id}');
    _log('currentSession=${_client.auth.currentSession != null}');
    try {
      final userRows = _rows(
        await _client
            .from('user')
            .select(
              'id, created_at, name, email, phone, gender, profile_image, emergency_phone',
            )
            .order('created_at', ascending: false),
      );

      if (userRows.isEmpty) {
        return const [];
      }

      final bookingRows = await _client
          .from('request_bookings')
          .select('id, user_id, status, booking_date, createdAt')
          .order('createdAt', ascending: false);

      final summariesByUserId = {
        for (final summary in _bookingSummaries(_rows(bookingRows)))
          summary.userId: summary,
      };
      final createdAtByUserId = {
        for (final row in userRows) _rowText(row, 'id'): _userCreatedAt(row),
      };
      final seenUserIds = <String>{};
      final users = <UserAdminViewData>[];

      for (final row in userRows) {
        final userId = _rowText(row, 'id');
        if (userId.isEmpty || !seenUserIds.add(userId)) {
          continue;
        }

        final summary = summariesByUserId[userId];
        users.add(
          UserAdminViewData.fromUserRow(row).copyWith(
            bookingsCount: summary?.bookingCount ?? 0,
            latestBookingDate: summary == null
                ? '-'
                : _formatUserListDate(summary.latestBookingAt),
            latestBookingStatus: summary?.latestBookingStatus ?? '-',
          ),
        );
      }

      users.sort((first, second) {
        return _compareLatest(
          createdAtByUserId[first.id],
          createdAtByUserId[second.id],
        );
      });

      return users;
    } on Object catch (error) {
      _log('query failure fetchUsers', error);
      throw UsersRepositoryException('Unable to load users.', error);
    }
  }

  Future<UserAdminViewData> fetchUserDetails(UserAdminViewData user) async {
    try {
      final userRow = await _fetchUserRow(user.id);
      final baseUser = userRow == null
          ? user
          : UserAdminViewData.fromUserRow(userRow).copyWith(
              bookingsCount: user.bookingsCount,
              latestBookingDate: user.latestBookingDate,
              latestBookingStatus: user.latestBookingStatus,
              city: user.city,
            );

      final locations = await _fetchLocations(user.id);
      final bookings = await _fetchBookings(user.id);
      final bookingIds = bookings
          .map((booking) => booking.lookupBookingId)
          .where((id) => id != '-')
          .toList();

      final payments = await _fetchPayments(bookingIds);
      final offers = await _fetchOffers(user.id);
      final tracking = await _fetchLatestTracking(bookings);
      final activity = _activityFrom(bookings: bookings, payments: payments);

      return baseUser.copyWith(
        city: locations.isEmpty ? baseUser.city : locations.first.city,
        bookingsCount: bookings.length,
        savedLocations: locations,
        bookingHistory: bookings,
        paymentHistory: payments,
        activityHistory: activity,
        offersUsed: offers,
        liveTracking: tracking,
      );
    } on Object catch (error) {
      _log('query failure fetchUserDetails userId=${user.id}', error);
      throw UsersRepositoryException('Unable to load user details.', error);
    }
  }

  Future<Map<String, dynamic>?> _fetchUserRow(String userId) async {
    final rows = await _client
        .from('user')
        .select(
          'id, created_at, name, email, phone, gender, profile_image, emergency_phone',
        )
        .eq('id', userId)
        .limit(1);

    final data = _rows(rows);
    return data.isEmpty ? null : data.first;
  }

  Future<List<UserSavedLocationData>> _fetchLocations(String userId) async {
    final rows = await _client
        .from('location_details')
        .select(
          'id, user_id, title, line_1, state, city, pincode, latitude, longitude',
        )
        .eq('user_id', userId)
        .order('title');

    return _rows(rows).map(UserSavedLocationData.fromRow).toList();
  }

  Future<List<UserBookingHistoryData>> _fetchBookings(String userId) async {
    final rows = await _client
        .from('request_bookings')
        .select('*')
        .eq('user_id', userId)
        .order('createdAt', ascending: false);

    final bookingRows = _rows(rows);
    final enrichedRows = await _withBookingDisplayNames(bookingRows);
    return enrichedRows.map(UserBookingHistoryData.fromRow).toList()
      ..sort(_compareBookingLatest);
  }

  Future<List<Map<String, dynamic>>> _withBookingDisplayNames(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return rows;
    }

    final pilotLabels = await _fetchDisplayLabels(
      ids: _idsFromRows(rows, 'pilot_id'),
      candidates: const [
        _LookupCandidate('pilot', 'id'),
        _LookupCandidate('pilots', 'id'),
        _LookupCandidate('pilot_details', 'id'),
        _LookupCandidate('user', 'id'),
      ],
      labelKeys: const ['name', 'pilot_name', 'full_name', 'display_name'],
    );
    final serviceLabels = await _fetchDisplayLabels(
      ids: _idsFromRows(rows, 'service_id'),
      candidates: const [
        _LookupCandidate('services', 'id'),
        _LookupCandidate('service', 'id'),
        _LookupCandidate('service_details', 'id'),
        _LookupCandidate('pilot_services', 'id'),
      ],
      labelKeys: const [
        'name',
        'service_name',
        'title',
        'display_name',
        'category',
        'service',
      ],
    );

    return [
      for (final row in rows)
        {
          ...row,
          if (pilotLabels[_rowText(row, 'pilot_id')] != null)
            'pilot_name': pilotLabels[_rowText(row, 'pilot_id')],
          if (serviceLabels[_rowText(row, 'service_id')] != null)
            'service_name': serviceLabels[_rowText(row, 'service_id')],
        },
    ];
  }

  Future<Map<String, String>> _fetchDisplayLabels({
    required List<String> ids,
    required List<_LookupCandidate> candidates,
    required List<String> labelKeys,
  }) async {
    if (ids.isEmpty) {
      return const {};
    }

    for (final candidate in candidates) {
      try {
        final rows = _rows(
          await _client
              .from(candidate.table)
              .select('*')
              .inFilter(candidate.idColumn, ids),
        );
        final labelsById = <String, String>{};

        for (final row in rows) {
          final id = _rowText(row, candidate.idColumn);
          final label = _displayLabel(row, labelKeys);
          if (id.isNotEmpty && label.isNotEmpty) {
            labelsById[id] = label;
          }
        }

        if (labelsById.isNotEmpty) {
          return labelsById;
        }
      } on Object catch (error) {
        _log('display lookup failure table=${candidate.table}', error);
      }
    }

    return const {};
  }

  Future<List<UserPaymentHistoryData>> _fetchPayments(
    List<String> bookingIds,
  ) async {
    if (bookingIds.isEmpty) {
      return const [];
    }

    final rows = await _client
        .from('transaction_details_user')
        .select(
          'id, transaction_id, booking_id, transaction_type, status, total_paid_amount, transaction_date',
        )
        .inFilter('booking_id', bookingIds)
        .order('transaction_date', ascending: false);

    return _rows(rows).map(UserPaymentHistoryData.fromRow).toList()
      ..sort(_comparePaymentLatest);
  }

  Future<List<UserOfferUsedData>> _fetchOffers(String userId) async {
    final userOfferRows = _rows(
      await _client
          .from('user_offers')
          .select('*')
          .eq('user_id', userId)
          .order('used_at', ascending: false),
    );

    if (userOfferRows.isEmpty) {
      return const [];
    }

    final offerRowsByKey = await _fetchOfferRowsByKey();

    return userOfferRows.map((userOffer) {
      final offer = _matchingOffer(userOffer, offerRowsByKey);
      return UserOfferUsedData.fromRows(userOffer: userOffer, offer: offer);
    }).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchOfferRowsByKey() async {
    final offers = _rows(await _client.from('offers').select('*'));
    final keyedOffers = <String, Map<String, dynamic>>{};

    for (final offer in offers) {
      for (final key in _offerKeys(offer)) {
        keyedOffers[key] = offer;
      }
    }

    return keyedOffers;
  }

  Future<UserLiveTrackingData> _fetchLatestTracking(
    List<UserBookingHistoryData> bookings,
  ) async {
    final bookingIds = bookings
        .map((booking) => booking.lookupBookingId)
        .where((id) => id != '-')
        .toList();
    if (bookingIds.isEmpty) {
      return UserLiveTrackingData.empty;
    }
    final bookingsById = {
      for (final booking in bookings) booking.lookupBookingId: booking,
    };

    try {
      final rows = await _client
          .from('pilot_location_tracker')
          .select('*')
          .inFilter('booking_id', bookingIds)
          .order('created_at', ascending: false)
          .limit(1);

      final data = _rows(rows);
      return data.isEmpty
          ? _trackingFromLatestBooking(bookings)
          : UserLiveTrackingData.fromRow(
              _trackingRowWithBooking(data.first, bookingsById),
            );
    } on Object {
      final rows = await _client
          .from('pilot_location_tracker')
          .select('*')
          .inFilter('booking_id', bookingIds)
          .limit(1);

      final data = _rows(rows);
      return data.isEmpty
          ? _trackingFromLatestBooking(bookings)
          : UserLiveTrackingData.fromRow(
              _trackingRowWithBooking(data.first, bookingsById),
            );
    }
  }

  Map<String, dynamic> _trackingRowWithBooking(
    Map<String, dynamic> row,
    Map<String, UserBookingHistoryData> bookingsById,
  ) {
    final booking = bookingsById[_rowText(row, 'booking_id')];
    if (booking == null) {
      return row;
    }

    return {
      ...row,
      'booking_id': booking.lookupBookingId,
      'pilot_name': booking.pilot,
      'status': booking.status.label,
    };
  }

  UserLiveTrackingData _trackingFromLatestBooking(
    List<UserBookingHistoryData> bookings,
  ) {
    final active = bookings.where((booking) {
      return booking.status == BookingStatus.accepted ||
          booking.status == BookingStatus.started ||
          booking.status == BookingStatus.working ||
          booking.status == BookingStatus.requested;
    }).toList();
    final booking = active.isEmpty ? bookings.first : active.first;

    return UserLiveTrackingData(
      currentBooking: booking.bookingId,
      pilotName: booking.pilot,
      currentStatus: booking.status.label,
      latitude: '-',
      longitude: '-',
      trackingStatus: active.isEmpty ? 'inactive' : 'active',
      lastUpdated: booking.bookingDate,
    );
  }

  List<UserActivityData> _activityFrom({
    required List<UserBookingHistoryData> bookings,
    required List<UserPaymentHistoryData> payments,
  }) {
    final pilotByBooking = {
      for (final booking in bookings) booking.lookupBookingId: booking.pilot,
      for (final booking in bookings) booking.bookingId: booking.pilot,
    };
    final activities = <UserActivityData>[
      for (final booking in bookings)
        UserActivityData(
          bookingId: booking.bookingId,
          paymentId: '-',
          action: 'Booking ${booking.status.label}',
          status: booking.status.label,
          pilot: booking.pilot,
          dateTime: booking.bookingDate,
          source: 'Booking',
          sortDate: booking.sortDate,
        ),
      for (final payment in payments)
        UserActivityData(
          bookingId: payment.bookingId,
          paymentId: payment.transactionId,
          action: 'Payment ${payment.status}',
          status: payment.status,
          pilot:
              pilotByBooking[payment.lookupBookingId] ??
              pilotByBooking[payment.bookingId] ??
              '-',
          dateTime: payment.transactionDate,
          source: 'Payment',
          sortDate: payment.sortDate,
        ),
    ]..sort(_compareActivityLatest);

    return activities;
  }

  Map<String, dynamic>? _matchingOffer(
    Map<String, dynamic> userOffer,
    Map<String, Map<String, dynamic>> offerRowsByKey,
  ) {
    for (final key in _offerKeys(userOffer)) {
      final offer = offerRowsByKey[key];
      if (offer != null) {
        return offer;
      }
    }

    return null;
  }

  List<String> _offerKeys(Map<String, dynamic> row) {
    const columns = ['offer_id', 'id', 'offer_code', 'coupon_code', 'code'];

    return [
      for (final column in columns)
        if (row[column] != null && row[column].toString().trim().isNotEmpty)
          row[column].toString().trim(),
    ];
  }

  List<String> _idsFromRows(List<Map<String, dynamic>> rows, String key) {
    return rows
        .map((row) => _rowText(row, key))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  int _compareBookingLatest(
    UserBookingHistoryData first,
    UserBookingHistoryData second,
  ) {
    return _compareLatest(first.sortDate, second.sortDate);
  }

  int _comparePaymentLatest(
    UserPaymentHistoryData first,
    UserPaymentHistoryData second,
  ) {
    return _compareLatest(first.sortDate, second.sortDate);
  }

  int _compareActivityLatest(UserActivityData first, UserActivityData second) {
    return _compareLatest(first.sortDate, second.sortDate);
  }

  int _compareLatest(DateTime? first, DateTime? second) {
    if (first == null && second == null) return 0;
    if (first == null) return 1;
    if (second == null) return -1;
    return second.compareTo(first);
  }

  DateTime? _userCreatedAt(Map<String, dynamic> row) {
    return _parseDate(row['created_at'] ?? row['createdAt']);
  }

  String _formatUserListDate(Object? value) {
    if (value == null) {
      return '-';
    }

    final parsed = _parseDate(value);
    if (parsed == null) {
      final text = value.toString().trim();
      return text.isEmpty ? '-' : text;
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
    return '${parsed.day.toString().padLeft(2, '0')} '
        '${months[parsed.month - 1]} ${parsed.year}';
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
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

  String _rowText(Map<String, dynamic> row, String key) {
    final value = row[key]?.toString().trim();
    return value == null || value.isEmpty ? '' : value;
  }

  String _displayLabel(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _rowText(row, key);
      if (value.isNotEmpty) {
        return value;
      }
    }

    final firstName = _rowText(row, 'first_name');
    final lastName = _rowText(row, 'last_name');
    return [firstName, lastName].where((part) => part.isNotEmpty).join(' ');
  }

  List<Map<String, dynamic>> _rows(Object? value) {
    if (value is List) {
      return [
        for (final row in value)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    }

    return const [];
  }

  List<_BookingUserSummary> _bookingSummaries(List<Map<String, dynamic>> rows) {
    final summariesByUserId = <String, _BookingUserSummary>{};

    for (final row in rows) {
      final userId = row['user_id']?.toString().trim();

      if (userId == null || userId.isEmpty) {
        continue;
      }

      summariesByUserId
          .putIfAbsent(userId, () => _BookingUserSummary(userId))
          .add(row);
    }

    final summaries = summariesByUserId.values.toList()
      ..sort((first, second) => second.compareLatest(first));

    return summaries;
  }

  void _log(String message, [Object? error]) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[UsersRepository] $message${error == null ? '' : ' | $error'}');
  }
}

class _LookupCandidate {
  const _LookupCandidate(this.table, this.idColumn);

  final String table;
  final String idColumn;
}

class _BookingUserSummary {
  _BookingUserSummary(this.userId);

  final String userId;
  int bookingCount = 0;
  String latestBookingStatus = '-';
  Object? latestBookingAt;
  DateTime? _latestParsedAt;

  void add(Map<String, dynamic> row) {
    bookingCount++;

    final bookingAt = row['booking_date'] ?? row['createdAt'];
    final parsedAt = DateTime.tryParse(bookingAt?.toString() ?? '');

    if (_latestParsedAt == null ||
        (parsedAt != null && parsedAt.isAfter(_latestParsedAt!))) {
      _latestParsedAt = parsedAt;
      latestBookingAt = bookingAt;
      final status = row['status']?.toString().trim();
      latestBookingStatus = status == null || status.isEmpty ? '-' : status;
    }
  }

  int compareLatest(_BookingUserSummary other) {
    final thisDate = _latestParsedAt;
    final otherDate = other._latestParsedAt;

    if (thisDate == null && otherDate == null) {
      return 0;
    }
    if (thisDate == null) {
      return -1;
    }
    if (otherDate == null) {
      return 1;
    }

    return thisDate.compareTo(otherDate);
  }

  Map<String, dynamic> toRow() {
    return {
      'user_id': userId,
      'booking_count': bookingCount,
      'latest_booking_at': latestBookingAt,
      'latest_booking_status': latestBookingStatus,
    };
  }
}

class UsersRepositoryException implements Exception {
  const UsersRepositoryException(this.message, this.error);

  final String message;
  final Object error;

  @override
  String toString() => '$message $error';
}
