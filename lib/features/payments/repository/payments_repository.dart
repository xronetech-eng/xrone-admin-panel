import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payments_model.dart';

class PaymentsRepository {
  PaymentsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<PaymentAdminData> load() async {
    debugPrint('[PaymentAdmin] load:start');
    try {
      final results = await Future.wait([
        _fetchUserTransactions(),
        _fetchPilotTransactions(),
        _fetchStorePayments(),
      ]);

      debugPrint('[PaymentAdmin] load:success');
      return PaymentAdminData(
        userTransactions: results[0] as List<PaymentTransaction>,
        pilotTransactions: results[1] as List<PaymentTransaction>,
        storePayments: results[2] as List<StorePaymentTransaction>,
      );
    } on Object catch (error) {
      debugPrint('[PaymentAdmin] error=$error');
      throw PaymentsRepositoryException('Unable to load payment data.', error);
    }
  }

  Future<List<PaymentTransaction>> _fetchUserTransactions() async {
    debugPrint('[PaymentAdmin] source=booking');
    final rows = _rows(
      await _client
          .from('transaction_details_user')
          .select('*')
          .order('transaction_date', ascending: false),
    );

    final bookings = await _fetchBookings(_idsFromRows(rows, 'booking_id'));
    final users = await _fetchUserNames(
      _idsFromRows(bookings.values.toList(), 'user_id'),
    );
    final pilots = await _fetchPilotNames(
      _idsFromRows(bookings.values.toList(), 'pilot_id'),
    );

    return [
      for (final row in rows)
        PaymentTransaction.fromUserRow(
          row: row,
          booking: bookings[_rowText(row, 'booking_id')],
          userName:
              users[_rowText(bookings[_rowText(row, 'booking_id')], 'user_id')],
          pilotName:
              pilots[_rowText(
                bookings[_rowText(row, 'booking_id')],
                'pilot_id',
              )],
        ),
    ]..sort(_compareTransactionsByDate);
  }

  Future<List<PaymentTransaction>> _fetchPilotTransactions() async {
    debugPrint('[PaymentAdmin] source=pilot');
    final rows = _rows(
      await _client
          .from('transaction_details_pilot')
          .select('*')
          .order('transaction_date', ascending: false),
    );

    final bookings = await _fetchBookings(_idsFromRows(rows, 'booking_id'));
    final bookingRows = bookings.values.toList();
    final users = await _fetchUserNames(_idsFromRows(bookingRows, 'user_id'));
    final pilots = await _fetchPilotNames([
      ..._idsFromRows(rows, 'pilot_id'),
      ..._idsFromRows(bookingRows, 'pilot_id'),
    ]);

    return [
      for (final row in rows)
        PaymentTransaction.fromPilotRow(
          row: row,
          booking: bookings[_rowText(row, 'booking_id')],
          userName:
              users[_rowText(bookings[_rowText(row, 'booking_id')], 'user_id')],
          pilotName:
              pilots[_rowText(row, 'pilot_id')] ??
              pilots[_rowText(
                bookings[_rowText(row, 'booking_id')],
                'pilot_id',
              )],
        ),
    ]..sort(_compareTransactionsByDate);
  }

  Future<List<StorePaymentTransaction>> _fetchStorePayments() async {
    debugPrint('[PaymentAdmin] source=store');
    final rows = _rows(
      await _client
          .from('store_orders')
          .select('*')
          .order('created_at', ascending: false),
    );

    return rows.map(StorePaymentTransaction.fromRow).toList()
      ..sort((first, second) {
        final firstDate = first.dateValue;
        final secondDate = second.dateValue;
        if (firstDate == null && secondDate == null) return 0;
        if (firstDate == null) return 1;
        if (secondDate == null) return -1;
        return secondDate.compareTo(firstDate);
      });
  }

  Future<Map<String, Map<String, dynamic>>> _fetchBookings(
    List<String> bookingIds,
  ) async {
    if (bookingIds.isEmpty) {
      return const {};
    }

    final rows = await _fetchRowsByIds(
      table: 'request_bookings',
      ids: bookingIds,
      idColumn: 'id',
    );

    return {
      for (final row in rows)
        if (_rowText(row, 'id').isNotEmpty) _rowText(row, 'id'): row,
    };
  }

  Future<Map<String, String>> _fetchUserNames(List<String> userIds) async {
    final rows = await _fetchRowsByIds(
      table: 'user',
      ids: userIds,
      idColumn: 'id',
    );

    return _labelsById(rows, const [
      'name',
      'full_name',
      'display_name',
      'email',
      'phone',
    ]);
  }

  Future<Map<String, String>> _fetchPilotNames(List<String> pilotIds) async {
    final rows = await _fetchRowsByIds(
      table: 'pilot',
      ids: pilotIds,
      idColumn: 'id',
    );

    return _labelsById(rows, const [
      'name',
      'pilot_name',
      'full_name',
      'display_name',
      'email',
      'contact_number',
    ]);
  }

  Future<List<Map<String, dynamic>>> _fetchRowsByIds({
    required String table,
    required List<String> ids,
    required String idColumn,
  }) async {
    final uniqueIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id != '-')
        .toSet()
        .toList();
    if (uniqueIds.isEmpty) {
      return const [];
    }

    final rows = <Map<String, dynamic>>[];
    for (var index = 0; index < uniqueIds.length; index += 100) {
      final end = index + 100 > uniqueIds.length
          ? uniqueIds.length
          : index + 100;
      final batch = uniqueIds.sublist(index, end);
      rows.addAll(
        _rows(await _client.from(table).select('*').inFilter(idColumn, batch)),
      );
    }

    return rows;
  }

  Map<String, String> _labelsById(
    List<Map<String, dynamic>> rows,
    List<String> keys,
  ) {
    return {
      for (final row in rows)
        if (_rowText(row, 'id').isNotEmpty)
          _rowText(row, 'id'): _displayLabel(row, keys),
    };
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
    final name = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ').trim();
    return name.isEmpty ? '-' : name;
  }

  int _compareTransactionsByDate(
    PaymentTransaction first,
    PaymentTransaction second,
  ) {
    final firstDate = first.dateValue;
    final secondDate = second.dateValue;
    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    return secondDate.compareTo(firstDate);
  }

  List<String> _idsFromRows(List<Map<String, dynamic>> rows, String key) {
    return rows
        .map((row) => _rowText(row, key))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  String _rowText(Map<String, dynamic>? row, String key) {
    final value = row?[key]?.toString().trim();
    return value == null || value.isEmpty ? '' : value;
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

class PaymentsRepositoryException implements Exception {
  const PaymentsRepositoryException(this.message, [this.error]);

  final String message;
  final Object? error;

  @override
  String toString() => message;
}
