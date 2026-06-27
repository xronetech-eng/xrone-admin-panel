import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pilots_model.dart';
import '../widgets/banner_image_picker.dart';

class PilotsRepository {
  PilotsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const _bannerBucket = 'pilot';
  final SupabaseClient _client;

  Future<List<PilotAdminViewData>> fetchPilots() async {
    try {
      final pilotRows = _rows(await _client.from('pilot').select('*'));
      _sortRowsByLatest(pilotRows, const ['created_at', 'createdAt']);
      final uniquePilotRows = _uniqueRowsById(pilotRows);

      if (uniquePilotRows.isEmpty) {
        return const [];
      }

      final pilotIds = _idsFromRows(uniquePilotRows, 'id');
      final serviceRows = await _fetchRowsForPilotIds(
        table: 'services',
        pilotIds: pilotIds,
        select: 'id, pilot_id',
      );
      final bookingRows = await _fetchRowsForPilotIds(
        table: 'request_bookings',
        pilotIds: pilotIds,
      );

      final serviceCounts = _countByPilotId(serviceRows);
      final bookingCounts = _countByPilotId(bookingRows);
      final activeBookingCounts = _countByPilotId(
        bookingRows
            .where((row) => isActivePilotBookingStatus(_rowText(row, 'status')))
            .toList(),
      );
      final latestActivity = _latestActivityByPilotId(bookingRows);

      return [
        for (final row in uniquePilotRows)
          PilotAdminViewData.fromPilotRow(
            row,
            servicesCount: serviceCounts[_rowText(row, 'id')] ?? 0,
            bookingsCount: bookingCounts[_rowText(row, 'id')] ?? 0,
            activeBookingsCount: activeBookingCounts[_rowText(row, 'id')] ?? 0,
            latestActivity:
                latestActivity[_rowText(row, 'id')] ??
                row['created_at'] ??
                row['createdAt'],
          ),
      ];
    } on Object catch (error) {
      _log('query failure fetchPilots', error);
      throw PilotsRepositoryException('Unable to load pilots.', error);
    }
  }

  Future<PilotAdminViewData> fetchPilotDetails(String pilotId) async {
    try {
      final row = await _fetchPilotRow(pilotId);
      if (row == null) {
        throw const PilotsRepositoryException('Pilot record was not found.');
      }

      final details = await Future.wait<Object>([
        fetchPilotBookings(pilotId),
        fetchPilotInvitations(pilotId),
        fetchPilotServices(pilotId),
        fetchPilotDrones(pilotId),
        fetchPilotBankDetails(pilotId),
        fetchPilotWallet(pilotId),
        fetchPilotWalletHistory(pilotId),
        fetchPilotTransactions(pilotId),
        fetchPilotTracking(pilotId),
        fetchPilotLocations(pilotId),
        fetchPilotBanners(pilotId),
      ]);

      final bookings = details[0] as PilotBookingCollections;
      final invitations = details[1] as List<PilotInvitationData>;
      final services = details[2] as List<PilotServiceData>;
      final drones = details[3] as List<PilotDroneData>;
      final bankDetails = details[4] as PilotBankDocumentsData;
      final wallet = details[5] as PilotEarningsData;
      final walletHistory = details[6] as List<PilotWalletHistoryData>;
      final transactions = details[7] as List<PilotTransactionData>;
      final tracking = details[8] as PilotLiveTrackingData;
      final locations = details[9] as List<PilotLocationData>;
      final banners = details[10] as List<PilotBannerImageData>;

      return PilotAdminViewData.fromPilotRow(
        row,
        servicesCount: services.length,
        bookingsCount:
            bookings.activeBookings.length + bookings.bookingHistory.length,
        activeBookingsCount: bookings.activeBookings.length,
        latestActivity: row['created_at'] ?? row['createdAt'],
      ).copyWith(
        bankDocuments: bankDetails,
        drones: drones,
        services: services,
        activeBookings: bookings.activeBookings,
        invitations: invitations,
        bookingHistory: bookings.bookingHistory,
        earnings: wallet,
        transactions: transactions,
        walletHistory: walletHistory,
        liveTracking: tracking,
        locations: locations,
        banners: banners,
      );
    } on PilotsRepositoryException catch (error, stackTrace) {
      _logDetailFailure('pilot_details', pilotId, error, stackTrace);
      rethrow;
    } on Object catch (error, stackTrace) {
      _logDetailFailure('pilot_details', pilotId, error, stackTrace);
      throw PilotsRepositoryException(
        _detailFailureMessage('pilot_details', pilotId, error),
        error,
        stackTrace,
      );
    }
  }

  Future<PilotBookingCollections> fetchPilotBookings(String pilotId) async {
    return _runDetailQuery(
      table: 'request_bookings',
      pilotId: pilotId,
      query: () async {
        final rows = _rows(
          await _client
              .from('request_bookings')
              .select('*')
              .eq('pilot_id', pilotId),
        );
        _sortRowsByLatest(rows, const [
          'booking_date',
          'createdAt',
          'created_at',
        ]);
        final enrichedRows = await _withBookingDisplayData(rows);

        return PilotBookingCollections(
          activeBookings: [
            for (final row in enrichedRows)
              if (isActivePilotBookingStatus(_rowText(row, 'status')))
                PilotActiveBookingData.fromRow(row),
          ],
          bookingHistory: [
            for (final row in enrichedRows)
              if (isHistoryPilotBookingStatus(_rowText(row, 'status')))
                PilotBookingHistoryData.fromRow(row),
          ],
        );
      },
    );
  }

  Future<List<PilotInvitationData>> fetchPilotInvitations(
    String pilotId,
  ) async {
    return _runDetailQuery(
      table: 'invitations',
      pilotId: pilotId,
      query: () async {
        final rows = _rows(
          await _client.from('invitations').select('*').eq('pilot_id', pilotId),
        );
        _sortRowsByLatest(rows, const [
          'booking_date',
          'createdAt',
          'created_at',
        ]);
        final enrichedRows = await _withBookingDisplayData(rows);

        return enrichedRows.map(PilotInvitationData.fromRow).toList();
      },
    );
  }

  Future<List<PilotServiceData>> fetchPilotServices(String pilotId) async {
    return _runDetailQuery(
      table: 'services',
      pilotId: pilotId,
      query: () async {
        final rows = _rows(
          await _client
              .from('services')
              .select('*')
              .eq('pilot_id', pilotId)
              .order('title'),
        );

        return rows.map(PilotServiceData.fromRow).toList();
      },
    );
  }

  Future<List<PilotDroneData>> fetchPilotDrones(String pilotId) async {
    return _runDetailQuery(
      table: 'drones',
      pilotId: pilotId,
      query: () async {
        final rows = _rows(
          await _client
              .from('drones')
              .select('*')
              .eq('pilot_id', pilotId)
              .order('name'),
        );

        return rows.map(PilotDroneData.fromRow).toList();
      },
    );
  }

  Future<PilotBankDocumentsData> fetchPilotBankDetails(String pilotId) async {
    return _runDetailQuery(
      table: 'bank_details',
      pilotId: pilotId,
      query: () async {
        final rows = await _fetchFirstRowsByOwner(
          table: 'bank_details',
          ownerId: pilotId,
          ownerColumns: const ['pilot_id'],
        );

        return rows.isEmpty
            ? PilotBankDocumentsData.empty
            : PilotBankDocumentsData.fromRow(rows.first);
      },
    );
  }

  Future<PilotEarningsData> fetchPilotWallet(String pilotId) async {
    return _runDetailQuery(
      table: 'wallet',
      pilotId: pilotId,
      query: () async {
        final rows = await _fetchFirstRowsByOwner(
          table: 'wallet',
          ownerId: pilotId,
          ownerColumns: const ['pilot_id', 'user_id'],
        );

        return rows.isEmpty
            ? PilotEarningsData.empty
            : PilotEarningsData.fromRow(rows.first);
      },
    );
  }

  Future<List<PilotWalletHistoryData>> fetchPilotWalletHistory(
    String pilotId,
  ) async {
    return _runDetailQuery(
      table: 'wallet_history',
      pilotId: pilotId,
      query: () async {
        final rows = await _fetchRowsByOwner(
          table: 'wallet_history',
          ownerId: pilotId,
          ownerColumns: const ['pilot_id'],
        );
        _sortRowsByLatest(rows, const ['createdAt', 'created_at']);

        return rows.map(PilotWalletHistoryData.fromRow).toList();
      },
    );
  }

  Future<List<PilotTransactionData>> fetchPilotTransactions(
    String pilotId,
  ) async {
    return _runDetailQuery(
      table: 'transaction_details_pilot',
      pilotId: pilotId,
      query: () async {
        final rows = _rows(
          await _client
              .from('transaction_details_pilot')
              .select('*')
              .eq('pilot_id', pilotId)
              .order('transaction_date', ascending: false),
        );

        return rows.map(PilotTransactionData.fromRow).toList();
      },
    );
  }

  Future<PilotLiveTrackingData> fetchPilotTracking(String pilotId) async {
    return _runDetailQuery(
      table: 'pilot_location_tracker',
      pilotId: pilotId,
      query: () async {
        var rows = await _fetchRowsByOwner(
          table: 'pilot_location_tracker',
          ownerId: pilotId,
          ownerColumns: const ['pilot_id'],
        );

        if (rows.isEmpty) {
          final bookingRows = _rows(
            await _client
                .from('request_bookings')
                .select('id')
                .eq('pilot_id', pilotId),
          );
          final bookingIds = _idsFromRows(bookingRows, 'id');
          rows = await _fetchRowsByIds(
            table: 'pilot_location_tracker',
            ids: bookingIds,
            idColumn: 'booking_id',
          );
        }

        _sortRowsByLatest(rows, const [
          'createdAt',
          'created_at',
          'updatedAt',
          'updated_at',
        ]);

        return rows.isEmpty
            ? PilotLiveTrackingData.empty
            : PilotLiveTrackingData.fromRow(rows.first);
      },
    );
  }

  Future<List<PilotLocationData>> fetchPilotLocations(String pilotId) async {
    return _runDetailQuery(
      table: 'location_details',
      pilotId: pilotId,
      query: () async {
        final rows = _rows(
          await _client
              .from('location_details')
              .select('*')
              .eq('user_id', pilotId)
              .order('title'),
        );

        return rows.map(PilotLocationData.fromRow).toList();
      },
    );
  }

  Future<List<PilotBannerImageData>> fetchPilotBanners(String pilotId) async {
    return _runDetailQuery(
      table: 'storage:pilot',
      pilotId: pilotId,
      query: () async {
        final folder = _bannerFolder(pilotId);
        final objects = await _client.storage
            .from(_bannerBucket)
            .list(path: folder);

        return [
          for (final object in objects)
            if (object.name.trim().isNotEmpty)
              PilotBannerImageData(
                name: object.name,
                path: '$folder/${object.name}',
                url: _client.storage
                    .from(_bannerBucket)
                    .getPublicUrl('$folder/${object.name}'),
              ),
        ];
      },
    );
  }

  Future<T> _runDetailQuery<T>({
    required String table,
    required String pilotId,
    required Future<T> Function() query,
  }) async {
    try {
      return await query();
    } on PilotsRepositoryException {
      rethrow;
    } on Object catch (error, stackTrace) {
      _logDetailFailure(table, pilotId, error, stackTrace);
      throw PilotsRepositoryException(
        _detailFailureMessage(table, pilotId, error),
        error,
        stackTrace,
      );
    }
  }

  Future<void> updateServicePrices({
    required String serviceId,
    required String price,
    required String marketPrice,
  }) async {
    await _client
        .from('services')
        .update({
          'price': _parseEditableAmount(price),
          'market_price': _parseEditableAmount(marketPrice),
        })
        .eq('id', serviceId);
  }

  Future<void> createPilotService({
    required String pilotId,
    required PilotServiceMutationData service,
  }) async {
    try {
      await _client
          .from('services')
          .insert(
            service.toServiceColumns(
              pilotId: pilotId,
              parseAmount: _parseEditableAmount,
              parsePercent: _parseEditablePercent,
            ),
          );
    } on PilotsModelException catch (error) {
      throw PilotsRepositoryException(error.message, error);
    }
  }

  Future<void> updatePilotService({
    required String pilotId,
    required String serviceId,
    required PilotServiceMutationData service,
  }) async {
    try {
      final columns = service.toServiceColumns(
        pilotId: pilotId,
        parseAmount: _parseEditableAmount,
        parsePercent: _parseEditablePercent,
      )..remove('pilot_id');

      await _client.from('services').update(columns).eq('id', serviceId);
    } on PilotsModelException catch (error) {
      throw PilotsRepositoryException(error.message, error);
    }
  }

  Future<void> deletePilotService({required String serviceId}) async {
    await _client.from('services').delete().eq('id', serviceId);
  }

  Future<PilotBannerImageData> uploadPilotBanner({
    required String pilotId,
    required PickedBannerImage image,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(image.name)}';
    final path = '${_bannerFolder(pilotId)}/$fileName';

    await _client.storage
        .from(_bannerBucket)
        .uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: image.contentType.isEmpty
                ? 'image/*'
                : image.contentType,
          ),
        );

    return PilotBannerImageData(
      name: fileName,
      path: path,
      url: _client.storage.from(_bannerBucket).getPublicUrl(path),
    );
  }

  Future<void> deletePilotBanner({required String path}) async {
    await _client.storage.from(_bannerBucket).remove([path]);
  }

  Future<Map<String, dynamic>?> _fetchPilotRow(String pilotId) async {
    final rows = _rows(
      await _client.from('pilot').select('*').eq('id', pilotId).limit(1),
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> _fetchRowsForPilotIds({
    required String table,
    required List<String> pilotIds,
    String select = '*',
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (var index = 0; index < pilotIds.length; index += 100) {
      final end = index + 100 > pilotIds.length ? pilotIds.length : index + 100;
      final batch = pilotIds.sublist(index, end);
      rows.addAll(
        _rows(
          await _client.from(table).select(select).inFilter('pilot_id', batch),
        ),
      );
    }

    return rows;
  }

  Future<List<Map<String, dynamic>>> _fetchFirstRowsByOwner({
    required String table,
    required String ownerId,
    required List<String> ownerColumns,
  }) async {
    for (final ownerColumn in ownerColumns) {
      try {
        final rows = _rows(
          await _client
              .from(table)
              .select('*')
              .eq(ownerColumn, ownerId)
              .limit(1),
        );
        if (rows.isNotEmpty) {
          return rows;
        }
      } on PostgrestException catch (error, stackTrace) {
        _logDetailFailure('$table.$ownerColumn', ownerId, error, stackTrace);
      }
    }

    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> _fetchRowsByOwner({
    required String table,
    required String ownerId,
    required List<String> ownerColumns,
  }) async {
    for (final ownerColumn in ownerColumns) {
      try {
        final rows = _rows(
          await _client.from(table).select('*').eq(ownerColumn, ownerId),
        );
        if (rows.isNotEmpty) {
          return rows;
        }
      } on PostgrestException catch (error, stackTrace) {
        _logDetailFailure('$table.$ownerColumn', ownerId, error, stackTrace);
      }
    }

    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> _fetchRowsByIds({
    required String table,
    required List<String> ids,
    required String idColumn,
  }) async {
    final rows = <Map<String, dynamic>>[];
    if (ids.isEmpty) {
      return rows;
    }

    for (var index = 0; index < ids.length; index += 100) {
      final end = index + 100 > ids.length ? ids.length : index + 100;
      final batch = ids.sublist(index, end);
      try {
        rows.addAll(
          _rows(
            await _client.from(table).select('*').inFilter(idColumn, batch),
          ),
        );
      } on PostgrestException catch (error, stackTrace) {
        _logDetailFailure('$table.$idColumn', idColumn, error, stackTrace);
      }
    }

    return rows;
  }

  Future<List<Map<String, dynamic>>> _withBookingDisplayData(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return rows;
    }

    final customers = await _fetchRowsById(
      table: 'user',
      ids: _idsFromRows(rows, 'user_id'),
      select: '*',
    );
    final services = await _fetchRowsById(
      table: 'services',
      ids: _idsFromRows(rows, 'service_id'),
      select: '*',
    );

    return [
      for (final row in rows)
        {
          ...row,
          if (customers[_rowText(row, 'user_id')] != null) ...{
            'customer_name': _firstString(
              customers[_rowText(row, 'user_id')]!,
              ['name', 'full_name', 'display_name'],
              fallback: 'Customer not available',
            ),
            'customer_phone': _firstString(
              customers[_rowText(row, 'user_id')]!,
              ['phone', 'contact_number'],
              fallback: '-',
            ),
          },
          if (services[_rowText(row, 'service_id')] != null) ...{
            'service_title': _firstString(
              services[_rowText(row, 'service_id')]!,
              ['title', 'category', 'name'],
              fallback: '-',
            ),
            'area': _firstString(
              services[_rowText(row, 'service_id')]!,
              ['area'],
              fallback: _rowText(row, 'area').isEmpty
                  ? '-'
                  : _rowText(row, 'area'),
            ),
            if (_rowText(row, 'price').isEmpty)
              'price': services[_rowText(row, 'service_id')]!['price'],
          },
          if (_rowText(row, 'location').isEmpty)
            'location': _firstString(row, [
              'address',
              'line_1',
              'area',
            ], fallback: '-'),
        },
    ];
  }

  Future<Map<String, Map<String, dynamic>>> _fetchRowsById({
    required String table,
    required List<String> ids,
    required String select,
    String idColumn = 'id',
  }) async {
    if (ids.isEmpty) {
      return const {};
    }

    final byId = <String, Map<String, dynamic>>{};
    for (var index = 0; index < ids.length; index += 100) {
      final end = index + 100 > ids.length ? ids.length : index + 100;
      final batch = ids.sublist(index, end);
      final rows = _rows(
        await _client.from(table).select(select).inFilter(idColumn, batch),
      );

      for (final row in rows) {
        final id = _rowText(row, idColumn);
        if (id.isNotEmpty) {
          byId[id] = row;
        }
      }
    }

    return byId;
  }

  Map<String, int> _countByPilotId(List<Map<String, dynamic>> rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      final pilotId = _rowText(row, 'pilot_id');
      if (pilotId.isEmpty) {
        continue;
      }
      counts[pilotId] = (counts[pilotId] ?? 0) + 1;
    }

    return counts;
  }

  Map<String, Object?> _latestActivityByPilotId(
    List<Map<String, dynamic>> rows,
  ) {
    final latest = <String, Object?>{};
    final parsedLatest = <String, DateTime>{};

    for (final row in rows) {
      final pilotId = _rowText(row, 'pilot_id');
      if (pilotId.isEmpty) {
        continue;
      }
      final value =
          row['booking_date'] ?? row['created_at'] ?? row['createdAt'];
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed == null) {
        latest.putIfAbsent(pilotId, () => value);
        continue;
      }
      if (parsedLatest[pilotId] == null ||
          parsed.isAfter(parsedLatest[pilotId]!)) {
        parsedLatest[pilotId] = parsed;
        latest[pilotId] = value;
      }
    }

    return latest;
  }

  void _sortRowsByLatest(
    List<Map<String, dynamic>> rows,
    List<String> dateColumns,
  ) {
    rows.sort((first, second) {
      final firstDate = _firstParsedDate(first, dateColumns);
      final secondDate = _firstParsedDate(second, dateColumns);

      if (firstDate == null && secondDate == null) {
        return 0;
      }
      if (firstDate == null) {
        return 1;
      }
      if (secondDate == null) {
        return -1;
      }

      return secondDate.compareTo(firstDate);
    });
  }

  DateTime? _firstParsedDate(
    Map<String, dynamic> row,
    List<String> dateColumns,
  ) {
    for (final column in dateColumns) {
      final value = row[column];
      if (value == null) {
        continue;
      }
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  List<String> _idsFromRows(List<Map<String, dynamic>> rows, String key) {
    return rows
        .map((row) => _rowText(row, key))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  List<Map<String, dynamic>> _uniqueRowsById(List<Map<String, dynamic>> rows) {
    final seenIds = <String>{};
    final uniqueRows = <Map<String, dynamic>>[];

    for (final row in rows) {
      final id = _rowText(row, 'id');
      if (id.isEmpty || !seenIds.add(id)) {
        continue;
      }
      uniqueRows.add(row);
    }

    return uniqueRows;
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
    required String fallback,
  }) {
    for (final key in keys) {
      final value = _rowText(row, key);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  List<Map<String, dynamic>> _rows(Object? value) {
    if (value is List) {
      final response = [
        for (final row in value)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
      final rows = List<Map<String, dynamic>>.from(response);
      return rows;
    }

    return <Map<String, dynamic>>[];
  }

  num _parseEditableAmount(String value) {
    final parsed = num.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), ''));
    if (parsed == null || parsed < 0) {
      throw const PilotsRepositoryException(
        'Enter a valid non-negative amount.',
      );
    }

    return parsed;
  }

  num _parseEditablePercent(String value) {
    final parsed = num.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), ''));
    if (parsed == null || parsed < 0) {
      throw const PilotsRepositoryException(
        'Enter a valid non-negative percent.',
      );
    }

    return parsed;
  }

  String _bannerFolder(String pilotId) => '$pilotId/banners';

  String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return sanitized.isEmpty ? 'banner.jpg' : sanitized;
  }

  void _log(String message, [Object? error]) {
    debugPrint(
      '[PilotsRepository] $message${error == null ? '' : ' | $error'}',
    );
  }

  void _logDetailFailure(
    String table,
    String pilotId,
    Object error,
    StackTrace stackTrace,
  ) {
    _log(
      'detail query failure table=$table pilotId=$pilotId '
      'message=${_exceptionMessage(error)}',
    );
    debugPrintStack(
      label: '[PilotsRepository] stack table=$table pilotId=$pilotId',
      stackTrace: stackTrace,
    );
  }

  String _detailFailureMessage(String table, String pilotId, Object error) {
    return 'Pilot detail query failed. table=$table pilotId=$pilotId '
        'message=${_exceptionMessage(error)}';
  }

  String _exceptionMessage(Object error) {
    if (error is PostgrestException) {
      final parts = [
        error.message,
        if (error.code != null) 'code=${error.code}',
        if (error.details != null) 'details=${error.details}',
        if (error.hint != null) 'hint=${error.hint}',
      ];
      return parts.join(' | ');
    }

    if (error is PilotsRepositoryException) {
      return error.message;
    }

    return error.toString();
  }
}

class PilotsRepositoryException implements Exception {
  const PilotsRepositoryException(this.message, [this.error, this.stackTrace]);

  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}
