import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tracking_model.dart';

class TrackingRepository {
  TrackingRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<TrackingData> load() async {
    debugPrint('[Tracking] load:start');
    try {
      final bookingRows = await _fetchBookings();
      final pilotRows = await _fetchPilots();
      final storeRows = await _fetchStoreOrders();
      final orderItemRows = await _fetchStoreOrderItems();

      final userNames = await _fetchNames(
        table: 'user',
        ids: _idsFromRows([...bookingRows, ...storeRows], 'user_id'),
        nameKeys: const ['name', 'full_name', 'display_name', 'email', 'phone'],
      );
      final pilotNames = await _fetchNames(
        table: 'pilot',
        ids:
            _idsFromRows([...bookingRows, ...pilotRows], 'pilot_id') +
            _idsFromRows(pilotRows, 'id'),
        nameKeys: const [
          'name',
          'pilot_name',
          'full_name',
          'display_name',
          'email',
          'contact_number',
        ],
      );

      final bookingRowsData = _bookingRows(
        bookingRows,
        userNames: userNames,
        pilotNames: pilotNames,
      );
      final pilotRowsData = _pilotRows(
        pilotRows,
        bookingRows: bookingRows,
        pilotNames: pilotNames,
      );
      final storeRowsData = _storeRows(
        storeRows,
        orderItemRows: orderItemRows,
        userNames: userNames,
      );

      debugPrint('[Tracking] load:success');
      return TrackingData(
        summary: TrackingSummary(
          activeBookings: bookingRowsData
              .where((row) => row.matchesFilter('Active'))
              .length,
          activePilots: pilotRowsData
              .where((row) => row.matchesFilter('Active'))
              .length,
          activeStoreOrders: storeRowsData
              .where((row) => row.matchesFilter('Active'))
              .length,
          completedDeliveries: storeRowsData
              .where((row) => row.matchesFilter('Completed'))
              .length,
        ),
        bookings: bookingRowsData,
        pilots: pilotRowsData,
        storeOrders: storeRowsData,
      );
    } on Object catch (error) {
      debugPrint('[Tracking] error=$error');
      throw TrackingRepositoryException('Unable to load tracking data.', error);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    debugPrint('[Tracking] source=bookings');
    return _rows(await _client.from('request_bookings').select('*'));
  }

  Future<List<Map<String, dynamic>>> _fetchPilots() async {
    debugPrint('[Tracking] source=pilots');
    return _rows(await _client.from('pilot').select('*'));
  }

  Future<List<Map<String, dynamic>>> _fetchStoreOrders() async {
    debugPrint('[Tracking] source=store');
    return _rows(await _client.from('store_orders').select('*'));
  }

  Future<List<Map<String, dynamic>>> _fetchStoreOrderItems() async {
    return _rows(await _client.from('store_order_items').select('*'));
  }

  List<TrackingRowData> _bookingRows(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> userNames,
    required Map<String, String> pilotNames,
  }) {
    final data = [
      for (final row in rows)
        TrackingRowData(
          type: TrackingTabType.bookings,
          id: _displayId(_bookingReference(row)),
          primaryName:
              userNames[_rowText(row, 'user_id')] ??
              _firstString(row, const ['user_name', 'customer_name']),
          secondaryName:
              pilotNames[_rowText(row, 'pilot_id')] ??
              _firstString(row, const ['pilot_name']),
          firstDetail: _locationText(row, const [
            'pickup_location',
            'pickup_address',
            'source_location',
            'location',
            'address',
          ]),
          secondDetail: _locationText(row, const [
            'drop_location',
            'drop_address',
            'destination_location',
            'service_location',
          ]),
          status: normalizeTrackingStatus(_firstString(row, const ['status'])),
          createdDate: _formatDate(_rowDate(row, _dateKeys)),
          sortDate: _rowDate(row, _dateKeys),
          timelineSteps: const [
            'Pending',
            'Accepted',
            'In Progress',
            'Completed',
            'Cancelled',
          ],
          currentStepIndex: _bookingStepIndex(
            _firstString(row, const ['status']),
          ),
        ),
    ]..sort(_compareRowsByDate);

    return data;
  }

  List<TrackingRowData> _pilotRows(
    List<Map<String, dynamic>> pilotRows, {
    required List<Map<String, dynamic>> bookingRows,
    required Map<String, String> pilotNames,
  }) {
    final bookingsByPilot = <String, List<Map<String, dynamic>>>{};
    for (final booking in bookingRows) {
      final pilotId = _rowText(booking, 'pilot_id');
      if (pilotId.isEmpty) {
        continue;
      }
      bookingsByPilot.putIfAbsent(pilotId, () => []).add(booking);
    }

    final data = [
      for (final pilot in pilotRows)
        _pilotRow(
          pilot,
          bookings: bookingsByPilot[_rowText(pilot, 'id')] ?? const [],
          pilotName:
              pilotNames[_rowText(pilot, 'id')] ??
              _firstString(pilot, const ['name', 'pilot_name', 'email']),
        ),
    ]..sort(_compareRowsByDate);

    return data;
  }

  TrackingRowData _pilotRow(
    Map<String, dynamic> pilot, {
    required List<Map<String, dynamic>> bookings,
    required String pilotName,
  }) {
    final activeBookings = bookings.where(_isActiveBooking).toList();
    final latestActivity = _latestDate([
      _rowDate(pilot, _dateKeys),
      for (final booking in bookings) _rowDate(booking, _dateKeys),
    ]);
    final status = activeBookings.isEmpty ? 'Pending' : 'Active';

    return TrackingRowData(
      type: TrackingTabType.pilots,
      id: _displayId(_rowText(pilot, 'id')),
      primaryName: pilotName,
      secondaryName: pilotName,
      firstDetail: activeBookings.length.toString(),
      secondDetail: bookings.length.toString(),
      status: status,
      createdDate: _formatDate(latestActivity),
      sortDate: latestActivity,
      timelineSteps: const ['Pending', 'Active', 'Completed', 'Cancelled'],
      currentStepIndex: status == 'Active' ? 1 : 0,
      assignedOrders: bookings.length,
      activeDeliveries: activeBookings.length,
    );
  }

  List<TrackingRowData> _storeRows(
    List<Map<String, dynamic>> rows, {
    required List<Map<String, dynamic>> orderItemRows,
    required Map<String, String> userNames,
  }) {
    final itemCounts = <String, int>{};
    for (final item in orderItemRows) {
      final orderId = _rowText(item, 'order_id');
      if (orderId.isEmpty) {
        continue;
      }
      itemCounts[orderId] = (itemCounts[orderId] ?? 0) + 1;
    }

    final data = [
      for (final row in rows)
        TrackingRowData(
          type: TrackingTabType.store,
          id: _displayId(
            _firstString(row, const ['order_number', 'number', 'id']),
          ),
          primaryName:
              userNames[_rowText(row, 'user_id')] ??
              _firstString(row, const ['customer_name', 'name', 'email']),
          secondaryName: '${itemCounts[_rowText(row, 'id')] ?? 0} items',
          firstDetail: _formatCurrency(
            _firstAmount(row, const ['total_amount', 'amount', 'total']),
          ),
          secondDetail: normalizeTrackingStatus(
            _firstString(row, const ['payment_status']),
          ),
          status: normalizeTrackingStatus(_firstString(row, const ['status'])),
          createdDate: _formatDate(_rowDate(row, _dateKeys)),
          sortDate: _rowDate(row, _dateKeys),
          timelineSteps: const [
            'Pending',
            'Confirmed',
            'Processing',
            'Shipped',
            'Delivered',
            'Cancelled',
          ],
          currentStepIndex: _storeStepIndex(
            _firstString(row, const ['status']),
          ),
          amount: _formatCurrency(
            _firstAmount(row, const ['total_amount', 'amount', 'total']),
          ),
          paymentStatus: normalizeTrackingStatus(
            _firstString(row, const ['payment_status']),
          ),
        ),
    ]..sort(_compareRowsByDate);

    return data;
  }

  Future<Map<String, String>> _fetchNames({
    required String table,
    required List<String> ids,
    required List<String> nameKeys,
  }) async {
    final uniqueIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id != '-')
        .toSet()
        .toList();
    if (uniqueIds.isEmpty) {
      return const {};
    }

    final rows = <Map<String, dynamic>>[];
    for (var index = 0; index < uniqueIds.length; index += 100) {
      final end = index + 100 > uniqueIds.length
          ? uniqueIds.length
          : index + 100;
      rows.addAll(
        _rows(
          await _client
              .from(table)
              .select('*')
              .inFilter('id', uniqueIds.sublist(index, end)),
        ),
      );
    }

    return {
      for (final row in rows)
        if (_rowText(row, 'id').isNotEmpty)
          _rowText(row, 'id'): _displayLabel(row, nameKeys),
    };
  }

  int _bookingStepIndex(String status) {
    final normalized = normalizeTrackingStatus(status);
    return switch (normalized) {
      'Pending' => 0,
      'Accepted' => 1,
      'In Progress' => 2,
      'Completed' => 3,
      'Cancelled' => 4,
      _ => 0,
    };
  }

  int _storeStepIndex(String status) {
    final normalized = normalizeTrackingStatus(status);
    return switch (normalized) {
      'Pending' => 0,
      'Accepted' => 1,
      'In Progress' => 2,
      'Shipped' => 3,
      'Delivered' || 'Completed' => 4,
      'Cancelled' => 5,
      _ => 0,
    };
  }

  bool _isActiveBooking(Map<String, dynamic> row) {
    final status = normalizeTrackingStatus(_firstString(row, const ['status']));
    return status == 'Accepted' || status == 'In Progress';
  }

  DateTime? _latestDate(List<DateTime?> dates) {
    DateTime? latest;
    for (final date in dates) {
      if (date == null) {
        continue;
      }
      if (latest == null || date.isAfter(latest)) {
        latest = date;
      }
    }
    return latest;
  }

  int _compareRowsByDate(TrackingRowData first, TrackingRowData second) {
    final firstDate = first.sortDate;
    final secondDate = second.sortDate;
    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    return secondDate.compareTo(firstDate);
  }

  String _bookingReference(Map<String, dynamic> row) {
    return _firstString(row, const [
      'booking_number',
      'booking_no',
      'booking_code',
      'booking_reference',
      'booking_ref',
      'reference_id',
      'id',
    ]);
  }

  String _locationText(Map<String, dynamic> row, List<String> keys) {
    final value = _firstString(row, keys, fallback: '');
    if (value.isNotEmpty) {
      return value;
    }

    final city = _firstString(row, const ['city'], fallback: '');
    final state = _firstString(row, const ['state'], fallback: '');
    final parts = [city, state].where((part) => part.isNotEmpty).join(', ');
    return parts.isEmpty ? '-' : parts;
  }

  List<String> _idsFromRows(List<Map<String, dynamic>> rows, String key) {
    return rows
        .map((row) => _rowText(row, key))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  String _displayLabel(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _rowText(row, key);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '-';
  }

  String _rowText(Map<String, dynamic> row, String key) {
    final value = row[key]?.toString().trim();
    return value == null || value.isEmpty || value.toLowerCase() == 'null'
        ? ''
        : value;
  }

  String _firstString(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = _rowText(row, key);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  double _firstAmount(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final amount = _readAmount(row[key]);
      if (amount != null) {
        return amount.toDouble();
      }
    }
    return 0;
  }

  num? _readAmount(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.-]'), ''));
  }

  DateTime? _rowDate(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final date = _parseDate(row[key]);
      if (date != null) {
        return date;
      }
    }
    return null;
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

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
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

    return '${value.day.toString().padLeft(2, '0')} '
        '${months[value.month - 1]} ${value.year}';
  }

  String _formatCurrency(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  String _displayId(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return '-';
    }
    if (text.length <= 18) {
      return text;
    }
    return '${text.substring(0, 8)}...${text.substring(text.length - 4)}';
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
}

class TrackingRepositoryException implements Exception {
  const TrackingRepositoryException(this.message, [this.error]);

  final String message;
  final Object? error;

  @override
  String toString() => message;
}

const _dateKeys = [
  'created_at',
  'createdAt',
  'updated_at',
  'updatedAt',
  'booking_date',
  'order_date',
  'last_activity',
  'last_active_at',
];
