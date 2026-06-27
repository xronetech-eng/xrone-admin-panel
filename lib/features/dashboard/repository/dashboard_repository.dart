import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_model.dart';

class DashboardRepository {
  DashboardRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DashboardData> load() async {
    debugPrint('[Dashboard] load:start');
    try {
      final users = await _fetchUsers();
      final pilots = await _fetchPilots();
      final store = await _fetchStore();
      final payments = await _fetchPayments();

      final activities = <DashboardActivity>[
        ...users.activities,
        ...pilots.activities,
        ...store.activities,
        ...payments.activities,
      ]..sort(_compareActivityDates);

      debugPrint('[Dashboard] load:success');
      return DashboardData(
        users: users.summary,
        pilots: pilots.summary,
        store: store.summary,
        payments: payments.summary,
        bookings: users.bookings,
        bookingItems: users.bookingItems,
        recentActivities: activities.take(4).toList(),
        allActivities: activities,
        searchItems: [
          ...users.searchItems,
          ...pilots.searchItems,
          ...store.searchItems,
          ...payments.searchItems,
        ],
      );
    } on Object catch (error) {
      debugPrint('[Dashboard] error=$error');
      throw DashboardRepositoryException(
        'Unable to load dashboard data.',
        error,
      );
    }
  }

  Future<_UsersDashboardLoad> _fetchUsers() async {
    debugPrint('[Dashboard] source=users');
    final userRows = _rows(await _client.from('user').select('*'));
    final bookingRows = _rows(
      await _client.from('request_bookings').select('*'),
    );
    final userLabelsById = _labelsById(userRows, const [
      'name',
      'full_name',
      'display_name',
      'email',
      'phone',
    ]);

    final activeUsers =
        _hasAnyKey(userRows, const ['status', 'account_status', 'is_active'])
        ? userRows.where(_isActiveUser).length
        : userRows.length;
    final newUsers = userRows.where((row) {
      final createdAt = _rowDate(row, const ['createdAt', 'created_at']);
      return createdAt != null && _isInLastDays(createdAt, 30);
    }).length;
    final activeRequests = bookingRows.where(_isActiveBooking).length;

    final summary = DashboardUsersSummary(
      totalUsers: userRows.length,
      activeUsers: activeUsers,
      newUsers: newUsers,
      totalUsersGrowth: _growthLabel(userRows, _always),
      activeUsersGrowth: _growthLabel(userRows, _isActiveUser),
      newUsersGrowth: _growthLabel(userRows, _always),
    );

    final bookings = DashboardBookingsSummary(
      totalBookings: bookingRows.length,
      activeRequests: activeRequests,
      pending: bookingRows.where((row) => _statusEquals(row, 'pending')).length,
      accepted: bookingRows
          .where((row) => _statusEquals(row, 'accepted'))
          .length,
      working: bookingRows.where((row) => _statusEquals(row, 'working')).length,
      completed: bookingRows
          .where((row) => _statusEquals(row, 'completed'))
          .length,
      totalBookingsGrowth: _growthLabel(bookingRows, _always),
      activeRequestsGrowth: _growthLabel(bookingRows, _isActiveBooking),
    );

    final userActivities = [for (final row in userRows) _userActivity(row)];
    final bookingActivities = [
      for (final row in bookingRows) _bookingActivity(row, userLabelsById),
    ];

    return _UsersDashboardLoad(
      summary: summary,
      bookings: bookings,
      bookingItems:
          [for (final row in bookingRows) _bookingItem(row, userLabelsById)]
            ..sort((a, b) {
              final first = a.createdAt;
              final second = b.createdAt;
              if (first == null && second == null) return 0;
              if (first == null) return 1;
              if (second == null) return -1;
              return second.compareTo(first);
            }),
      activities: [...userActivities, ...bookingActivities],
      searchItems: [
        for (var index = 0; index < userRows.length; index++)
          DashboardSearchItem(
            source: DashboardSearchSource.user,
            searchableText: _joinSearchText(userRows[index], const [
              'name',
              'full_name',
              'display_name',
              'email',
              'phone',
              'emergency_phone',
              'id',
            ]),
            status: _isActiveUser(userRows[index]) ? 'active' : 'inactive',
            isActive: _isActiveUser(userRows[index]),
            isNew: _isInLastDays(
              _rowDate(userRows[index], const ['createdAt', 'created_at']) ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              30,
            ),
            createdAt: _rowDate(userRows[index], _dateKeys),
            activity: userActivities[index],
          ),
        for (var index = 0; index < bookingRows.length; index++)
          DashboardSearchItem(
            source: DashboardSearchSource.booking,
            searchableText: [
              _bookingReference(bookingRows[index]),
              _joinSearchText(bookingRows[index], const [
                'booking_number',
                'booking_no',
                'booking_code',
                'booking_reference',
                'reference_id',
                'id',
                'user_id',
                'pilot_id',
                'status',
              ]),
            ].join(' '),
            status: _firstString(bookingRows[index], const [
              'status',
            ], fallback: '').toLowerCase(),
            isActive: _isActiveBooking(bookingRows[index]),
            isNew: false,
            createdAt: _rowDate(bookingRows[index], _dateKeys),
            activity: bookingActivities[index],
          ),
      ],
    );
  }

  Future<_PilotsDashboardLoad> _fetchPilots() async {
    debugPrint('[Dashboard] source=pilots');
    final rows = _rows(await _client.from('pilot').select('*'));

    bool hasStatus = false;
    for (final row in rows) {
      if (_pilotApprovalStatus(row).isNotEmpty) {
        hasStatus = true;
        break;
      }
    }

    bool hasStatusValue(Map<String, dynamic> row, String expected) =>
        _pilotApprovalStatus(row) == expected;

    final summary = DashboardPilotsSummary(
      totalPilots: rows.length,
      approvedPilots: hasStatus
          ? rows.where((row) => hasStatusValue(row, 'approved')).length
          : 0,
      pendingPilots: hasStatus
          ? rows.where((row) => hasStatusValue(row, 'pending')).length
          : 0,
      rejectedPilots: hasStatus
          ? rows.where((row) => hasStatusValue(row, 'rejected')).length
          : 0,
      totalPilotsGrowth: _growthLabel(rows, _always),
      approvedPilotsGrowth: _growthLabel(
        rows,
        (row) => hasStatusValue(row, 'approved'),
      ),
      pendingPilotsGrowth: _growthLabel(
        rows,
        (row) => hasStatusValue(row, 'pending'),
      ),
      rejectedPilotsGrowth: _growthLabel(
        rows,
        (row) => hasStatusValue(row, 'rejected'),
      ),
    );

    final activities = [for (final row in rows) _pilotActivity(row)];

    return _PilotsDashboardLoad(
      summary: summary,
      activities: activities,
      searchItems: [
        for (var index = 0; index < rows.length; index++)
          DashboardSearchItem(
            source: DashboardSearchSource.pilot,
            searchableText: _joinSearchText(rows[index], const [
              'name',
              'pilot_name',
              'full_name',
              'display_name',
              'email',
              'contact_number',
              'phone',
              'id',
            ]),
            status: _pilotApprovalStatus(rows[index]),
            isActive: _pilotApprovalStatus(rows[index]) == 'approved',
            isNew: false,
            createdAt: _rowDate(rows[index], _dateKeys),
            activity: activities[index],
          ),
      ],
    );
  }

  Future<_StoreDashboardLoad> _fetchStore() async {
    debugPrint('[Dashboard] source=store');
    final categories = _rows(
      await _client.from('store_categories').select('*'),
    );
    final products = _rows(await _client.from('store_products').select('*'));
    final orders = _rows(await _client.from('store_orders').select('*'));
    final wishlistItems = _rows(
      await _client.from('store_wishlist_items').select('*'),
    );
    final cartItems = _rows(await _client.from('store_cart_items').select('*'));
    final customerLabelsById = await _fetchUserLabelsByIds(
      _idsFromRows(orders, const ['owner_id', 'user_id', 'customer_id']),
    );

    final summary = DashboardStoreSummary(
      totalCategories: categories.length,
      totalProducts: products.length,
      totalOrders: orders.length,
      totalWishlistItems: wishlistItems.length,
      totalCartItems: cartItems.length,
      totalCategoriesGrowth: _growthLabel(categories, _always),
      totalProductsGrowth: _growthLabel(products, _always),
      totalOrdersGrowth: _growthLabel(orders, _always),
      totalWishlistItemsGrowth: _growthLabel(wishlistItems, _always),
      totalCartItemsGrowth: _growthLabel(cartItems, _always),
    );

    final activities = [
      for (final row in orders) _storeOrderActivity(row, customerLabelsById),
    ];

    return _StoreDashboardLoad(
      summary: summary,
      activities: activities,
      searchItems: [
        for (var index = 0; index < orders.length; index++)
          DashboardSearchItem(
            source: DashboardSearchSource.storeOrder,
            searchableText: _joinSearchText(orders[index], const [
              'order_number',
              'number',
              'id',
              'user_id',
              'email',
              'phone',
              'status',
              'payment_status',
            ]),
            status: _firstString(orders[index], const [
              'status',
            ], fallback: '').toLowerCase(),
            isActive: false,
            isNew: false,
            createdAt: _rowDate(orders[index], _dateKeys),
            activity: activities[index],
          ),
      ],
    );
  }

  Future<_PaymentsDashboardLoad> _fetchPayments() async {
    debugPrint('[Dashboard] source=payments');
    final userPayments = _rows(
      await _client.from('transaction_details_user').select('*'),
    );
    final pilotPayments = _rows(
      await _client.from('transaction_details_pilot').select('*'),
    );
    final storeOrders = _rows(await _client.from('store_orders').select('*'));

    final paymentRows = [
      for (final row in userPayments)
        _paymentRow(
          row,
          source: 'User Booking',
          sourceTable: 'transaction_details_user',
          statusKey: 'status',
          isRevenue: true,
        ),
      for (final row in pilotPayments)
        _paymentRow(
          row,
          source: 'Pilot Payout',
          sourceTable: 'transaction_details_pilot',
          statusKey: 'status',
          isRevenue: false,
        ),
      for (final row in storeOrders)
        _paymentRow(
          row,
          source: 'Store Order',
          sourceTable: 'store_orders',
          statusKey: 'payment_status',
          isRevenue: true,
        ),
    ];

    final successful = paymentRows
        .where((payment) => payment.status == _PaymentStatus.successful)
        .toList();
    final successfulRevenue = successful
        .where((payment) => payment.isRevenue)
        .toList();
    final totalRevenue = successfulRevenue.fold<double>(
      0,
      (total, payment) => total + payment.amount,
    );
    final last30DaysRevenue = successfulRevenue
        .where((payment) {
          final date = payment.createdAt;
          return date != null && _isInLastDays(date, 30);
        })
        .fold<double>(0, (total, payment) => total + payment.amount);

    final summary = DashboardPaymentsSummary(
      totalRevenue: totalRevenue,
      totalRevenueLabel: _formatCurrency(totalRevenue),
      last30DaysRevenue: last30DaysRevenue,
      last30DaysRevenueLabel: _formatCurrency(last30DaysRevenue),
      successfulPayments: successful.length,
      pendingPayments: paymentRows
          .where((payment) => payment.status == _PaymentStatus.pending)
          .length,
      failedPayments: paymentRows
          .where((payment) => payment.status == _PaymentStatus.failed)
          .length,
      totalRevenueGrowth: _paymentGrowthLabel(successfulRevenue),
      successfulPaymentsGrowth: _paymentCountGrowthLabel(
        paymentRows,
        _PaymentStatus.successful,
      ),
      pendingPaymentsGrowth: _paymentCountGrowthLabel(
        paymentRows,
        _PaymentStatus.pending,
      ),
      failedPaymentsGrowth: _paymentCountGrowthLabel(
        paymentRows,
        _PaymentStatus.failed,
      ),
      revenueChartValues: _revenueChartValues(successfulRevenue),
    );

    final activities = [
      for (final payment in paymentRows) _paymentActivity(payment),
    ]..sort(_compareActivityDates);

    return _PaymentsDashboardLoad(
      summary: summary,
      activities: activities,
      searchItems: [
        for (final activity in activities)
          DashboardSearchItem(
            source: DashboardSearchSource.activity,
            searchableText:
                '${activity.name} ${activity.action} ${activity.source} ${activity.status} ${activity.time}',
            status: activity.status.toLowerCase(),
            isActive: false,
            isNew: false,
            createdAt: activity.createdAt,
            activity: activity,
          ),
      ],
    );
  }

  _PaymentRow _paymentRow(
    Map<String, dynamic> row, {
    required String source,
    required String sourceTable,
    required String statusKey,
    required bool isRevenue,
  }) {
    return _PaymentRow(
      source: source,
      sourceTable: sourceTable,
      referenceId: _firstString(row, const [
        'transaction_id',
        'payment_id',
        'razorpay_payment_id',
        'order_number',
        'number',
        'id',
      ]),
      amount: _firstAmount(row, const [
        'total_paid_amount',
        'paid_amount',
        'payout_amount',
        'pilot_charges',
        'total_amount',
        'amount',
        'total',
      ]),
      status: _PaymentStatusX.from(row[statusKey]),
      createdAt: _createdAt(row),
      isRevenue: isRevenue,
    );
  }

  Future<Map<String, String>> _fetchUserLabelsByIds(List<String> ids) async {
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
      final batch = uniqueIds.sublist(index, end);
      rows.addAll(
        _rows(await _client.from('user').select('*').inFilter('id', batch)),
      );
    }

    return _labelsById(rows, const [
      'name',
      'full_name',
      'display_name',
      'email',
      'phone',
    ]);
  }

  DashboardActivity _activityFromRow({
    required String sourceTable,
    required Map<String, dynamic> row,
    required String name,
    required String action,
    required String status,
    required String source,
  }) {
    final createdAt = _createdAt(row);
    _logActivity(
      sourceTable: sourceTable,
      row: row,
      createdAt: createdAt,
      title: name,
      subtitle: action,
    );
    return DashboardActivity(
      name: name,
      action: action,
      source: source,
      status: status,
      time: _formatDateTime(createdAt),
      createdAt: createdAt,
      type: name,
      description: action,
    );
  }

  DashboardActivity _userActivity(Map<String, dynamic> row) {
    final title = _labelFromRow(row, const [
      'name',
      'full_name',
      'display_name',
      'email',
      'phone',
      'id',
    ]);
    final action = 'Registered account';
    return _activityFromRow(
      sourceTable: 'user',
      row: row,
      name: title,
      action: action,
      status: _userStatusLabel(row),
      source: 'User',
    );
  }

  DashboardBookingItem _bookingItem(
    Map<String, dynamic> row,
    Map<String, String> userLabelsById,
  ) {
    final bookingId = _bookingReference(row);
    final userName = _relatedLabel(
      row: row,
      labelsById: userLabelsById,
      idKeys: const ['user_id', 'customer_id', 'owner_id'],
      directLabelKeys: const [
        'user_name',
        'customer_name',
        'name',
        'email',
        'phone',
      ],
      fallback: 'Unknown user',
    );
    final createdAt = _createdAt(row);
    return DashboardBookingItem(
      reference: 'Booking ${_displayId(bookingId)}',
      customerName: userName,
      status: _bookingStatusLabel(row),
      createdAt: createdAt,
      dateTimeLabel: _formatDateTime(createdAt),
    );
  }

  DashboardActivity _bookingActivity(
    Map<String, dynamic> row,
    Map<String, String> userLabelsById,
  ) {
    final bookingId = _bookingReference(row);
    final userName = _relatedLabel(
      row: row,
      labelsById: userLabelsById,
      idKeys: const ['user_id', 'customer_id', 'owner_id'],
      directLabelKeys: const [
        'user_name',
        'customer_name',
        'name',
        'email',
        'phone',
      ],
      fallback: 'Unknown user',
    );
    final action = 'Booking ${_bookingStatusLabel(row).toLowerCase()}';

    return _activityFromRow(
      sourceTable: 'request_bookings',
      row: row,
      name: userName,
      action: action,
      status: _bookingStatusLabel(row),
      source: 'Booking ${_displayId(bookingId)}',
    );
  }

  DashboardActivity _pilotActivity(Map<String, dynamic> row) {
    final title = _labelFromRow(row, const [
      'name',
      'pilot_name',
      'full_name',
      'display_name',
      'email',
      'contact_number',
      'phone',
      'id',
    ]);
    final status = _pilotApprovalStatus(row);
    final action = status.isEmpty
        ? 'Submitted pilot profile'
        : 'Pilot ${_titleCase(status).toLowerCase()}';

    return _activityFromRow(
      sourceTable: 'pilot',
      row: row,
      name: title,
      action: action,
      status: status.isEmpty ? 'Pending' : _titleCase(status),
      source: 'Pilot',
    );
  }

  DashboardActivity _storeOrderActivity(
    Map<String, dynamic> row,
    Map<String, String> customerLabelsById,
  ) {
    final orderId = _firstString(row, const ['order_number', 'number', 'id']);
    final customerName = _relatedLabel(
      row: row,
      labelsById: customerLabelsById,
      idKeys: const ['owner_id', 'user_id', 'customer_id'],
      directLabelKeys: const [
        'customer_name',
        'user_name',
        'name',
        'email',
        'phone',
      ],
      fallback: 'Unknown customer',
    );
    final action = 'Order ${_orderStatusLabel(row).toLowerCase()}';

    return _activityFromRow(
      sourceTable: 'store_orders',
      row: row,
      name: customerName,
      action: action,
      status: _orderStatusLabel(row),
      source: 'Order ${_displayId(orderId)}',
    );
  }

  DashboardActivity _paymentActivity(_PaymentRow payment) {
    final title = '${payment.source} ${_displayId(payment.referenceId)}';
    final action = '${_paymentStatusLabel(payment.status)} payment';
    debugPrint(
      '[DashboardActivity] source=${payment.sourceTable} row_id=${payment.referenceId} '
      'created_at=${payment.createdAt?.toIso8601String() ?? '-'} '
      'title="$title" subtitle="$action"',
    );
    return DashboardActivity(
      name: title,
      action: action,
      source: payment.source,
      status: _paymentStatusLabel(payment.status),
      time: _formatDateTime(payment.createdAt),
      createdAt: payment.createdAt,
      type: title,
      description: action,
    );
  }

  List<double> _revenueChartValues(List<_PaymentRow> successfulPayments) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final values = List<double>.filled(30, 0);
    var hasDatedPayment = false;

    for (final payment in successfulPayments) {
      final date = payment.createdAt;
      if (date == null) {
        continue;
      }

      final day = DateTime(date.year, date.month, date.day);
      if (day.isBefore(start)) {
        continue;
      }

      final index = day.difference(start).inDays;
      if (index >= 0 && index < values.length) {
        values[index] += payment.amount;
        hasDatedPayment = true;
      }
    }

    return hasDatedPayment ? values : const [];
  }

  String _growthLabel(
    List<Map<String, dynamic>> rows,
    bool Function(Map<String, dynamic> row) predicate,
  ) {
    final periods = _periodCounts(rows, predicate);
    return _percentageGrowthLabel(periods.current, periods.previous);
  }

  String _paymentCountGrowthLabel(
    List<_PaymentRow> rows,
    _PaymentStatus status,
  ) {
    final periods = _paymentPeriodCounts(
      rows.where((payment) => payment.status == status).toList(),
      amount: false,
    );
    return _percentageGrowthLabel(periods.current, periods.previous);
  }

  String _paymentGrowthLabel(List<_PaymentRow> rows) {
    final periods = _paymentPeriodCounts(rows, amount: true);
    return _percentageGrowthLabel(periods.current, periods.previous);
  }

  _PeriodValues _periodCounts(
    List<Map<String, dynamic>> rows,
    bool Function(Map<String, dynamic> row) predicate,
  ) {
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 30));
    final previousStart = now.subtract(const Duration(days: 60));
    var current = 0.0;
    var previous = 0.0;

    for (final row in rows) {
      if (!predicate(row)) {
        continue;
      }

      final date = _rowDate(row, _dateKeys);
      if (date == null) {
        continue;
      }
      if (!date.isBefore(currentStart) && !date.isAfter(now)) {
        current++;
      } else if (!date.isBefore(previousStart) && date.isBefore(currentStart)) {
        previous++;
      }
    }

    return _PeriodValues(current, previous);
  }

  _PeriodValues _paymentPeriodCounts(
    List<_PaymentRow> rows, {
    required bool amount,
  }) {
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 30));
    final previousStart = now.subtract(const Duration(days: 60));
    var current = 0.0;
    var previous = 0.0;

    for (final row in rows) {
      final date = row.createdAt;
      if (date == null) {
        continue;
      }
      final value = amount ? row.amount : 1.0;
      if (!date.isBefore(currentStart) && !date.isAfter(now)) {
        current += value;
      } else if (!date.isBefore(previousStart) && date.isBefore(currentStart)) {
        previous += value;
      }
    }

    return _PeriodValues(current, previous);
  }

  String _percentageGrowthLabel(double current, double previous) {
    if (previous == 0) {
      if (current == 0) {
        return '0%';
      }
      return '+100%';
    }

    final value = ((current - previous) / previous) * 100;
    final prefix = value > 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(1)}%';
  }

  String _userStatusLabel(Map<String, dynamic> row) {
    if (!_hasAnyKey([row], const ['status', 'account_status', 'is_active'])) {
      return 'Active';
    }
    return _isActiveUser(row) ? 'Active' : 'Inactive';
  }

  String _bookingStatusLabel(Map<String, dynamic> row) {
    return _titleCase(_firstString(row, const ['status'], fallback: 'Pending'));
  }

  String _orderStatusLabel(Map<String, dynamic> row) {
    return _titleCase(_firstString(row, const ['status'], fallback: 'Pending'));
  }

  String _paymentStatusLabel(_PaymentStatus status) {
    return switch (status) {
      _PaymentStatus.successful => 'Success',
      _PaymentStatus.pending => 'Pending',
      _PaymentStatus.failed => 'Failed',
      _PaymentStatus.other => 'Updated',
    };
  }

  bool _isActiveUser(Map<String, dynamic> row) {
    if (row.containsKey('is_active')) {
      return _readBool(row['is_active']);
    }

    final status = _firstString(row, const [
      'status',
      'account_status',
    ]).toLowerCase();
    return status.isEmpty ||
        status == 'active' ||
        status == 'enabled' ||
        status == 'verified';
  }

  bool _isActiveBooking(Map<String, dynamic> row) {
    final status = _firstString(row, const ['status']).toLowerCase();
    return status == 'pending' ||
        status == 'accepted' ||
        status == 'started' ||
        status == 'working';
  }

  bool _statusEquals(Map<String, dynamic> row, String status) {
    return _firstString(row, const ['status']).toLowerCase() == status;
  }

  String _pilotApprovalStatus(Map<String, dynamic> row) {
    final raw = _firstString(row, const [
      'approval_status',
      'verification_status',
      'kyc_status',
      'admin_status',
      'profile_status',
      'account_status',
      'status',
    ]).toLowerCase();

    return switch (raw) {
      'approved' || 'verified' || 'accepted' || 'active' => 'approved',
      'pending' ||
      'in_review' ||
      'review' ||
      'submitted' ||
      'unverified' => 'pending',
      'rejected' || 'declined' || 'blocked' || 'suspended' => 'rejected',
      _ => '',
    };
  }

  bool _hasAnyKey(List<Map<String, dynamic>> rows, List<String> keys) {
    for (final row in rows) {
      for (final key in keys) {
        if (row.containsKey(key)) {
          return true;
        }
      }
    }
    return false;
  }

  Map<String, String> _labelsById(
    List<Map<String, dynamic>> rows,
    List<String> labelKeys,
  ) {
    return {
      for (final row in rows)
        if (_firstString(row, const ['id'], fallback: '').isNotEmpty)
          _firstString(row, const ['id'], fallback: ''): _labelFromRow(
            row,
            labelKeys,
          ),
    };
  }

  List<String> _idsFromRows(
    List<Map<String, dynamic>> rows,
    List<String> keys,
  ) {
    return {
      for (final row in rows)
        for (final key in keys)
          if (_firstString(row, [key], fallback: '').isNotEmpty)
            _firstString(row, [key], fallback: ''),
    }.toList();
  }

  String _relatedLabel({
    required Map<String, dynamic> row,
    required Map<String, String> labelsById,
    required List<String> idKeys,
    required List<String> directLabelKeys,
    required String fallback,
  }) {
    final directLabel = _labelFromRow(row, directLabelKeys, fallback: '');
    if (directLabel.isNotEmpty) {
      return directLabel;
    }

    for (final key in idKeys) {
      final id = _firstString(row, [key], fallback: '');
      final label = labelsById[id];
      if (label != null && label.isNotEmpty) {
        return label;
      }
    }

    return fallback;
  }

  String _labelFromRow(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = _firstString(row, [key], fallback: '');
      if (value.isNotEmpty) {
        return value;
      }
    }

    final firstName = _firstString(row, const ['first_name'], fallback: '');
    final lastName = _firstString(row, const ['last_name'], fallback: '');
    final fullName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ').trim();
    return fullName.isEmpty ? fallback : fullName;
  }

  DateTime? _createdAt(Map<String, dynamic> row) {
    return _rowDate(row, const ['created_at', 'createdAt']);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}, $hour:$minute $period';
  }

  void _logActivity({
    required String sourceTable,
    required Map<String, dynamic> row,
    required DateTime? createdAt,
    required String title,
    required String subtitle,
  }) {
    debugPrint(
      '[DashboardActivity] source=$sourceTable '
      'row_id=${_firstString(row, const ['id'], fallback: '-')} '
      'created_at=${createdAt?.toIso8601String() ?? '-'} '
      'title="$title" subtitle="$subtitle"',
    );
  }

  bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.toLowerCase().trim();
      return text == 'true' || text == '1' || text == 'yes';
    }
    return false;
  }

  bool _always(Map<String, dynamic> row) => true;

  bool _isInLastDays(DateTime date, int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    return !date.isBefore(start) && !date.isAfter(now);
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

  String _month(int month) {
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
    return months[month - 1];
  }

  String _joinSearchText(Map<String, dynamic> row, List<String> keys) {
    return [
      for (final key in keys)
        if (_firstString(row, [key], fallback: '').isNotEmpty)
          _firstString(row, [key], fallback: ''),
    ].join(' ');
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

  String _firstString(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
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

  String _displayId(String value) {
    final text = value.trim();
    if (text.length <= 18) {
      return text;
    }
    return '${text.substring(0, 8)}...${text.substring(text.length - 4)}';
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+|_+|-+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatCurrency(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  int _compareActivityDates(DashboardActivity first, DashboardActivity second) {
    final firstDate = first.createdAt;
    final secondDate = second.createdAt;
    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    return secondDate.compareTo(firstDate);
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

class DashboardRepositoryException implements Exception {
  const DashboardRepositoryException(this.message, [this.error]);

  final String message;
  final Object? error;

  @override
  String toString() => message;
}

class _UsersDashboardLoad {
  const _UsersDashboardLoad({
    required this.summary,
    required this.bookings,
    required this.bookingItems,
    required this.activities,
    required this.searchItems,
  });

  final DashboardUsersSummary summary;
  final DashboardBookingsSummary bookings;
  final List<DashboardBookingItem> bookingItems;
  final List<DashboardActivity> activities;
  final List<DashboardSearchItem> searchItems;
}

class _PilotsDashboardLoad {
  const _PilotsDashboardLoad({
    required this.summary,
    required this.activities,
    required this.searchItems,
  });

  final DashboardPilotsSummary summary;
  final List<DashboardActivity> activities;
  final List<DashboardSearchItem> searchItems;
}

class _StoreDashboardLoad {
  const _StoreDashboardLoad({
    required this.summary,
    required this.activities,
    required this.searchItems,
  });

  final DashboardStoreSummary summary;
  final List<DashboardActivity> activities;
  final List<DashboardSearchItem> searchItems;
}

class _PaymentsDashboardLoad {
  const _PaymentsDashboardLoad({
    required this.summary,
    required this.activities,
    required this.searchItems,
  });

  final DashboardPaymentsSummary summary;
  final List<DashboardActivity> activities;
  final List<DashboardSearchItem> searchItems;
}

class _PeriodValues {
  const _PeriodValues(this.current, this.previous);

  final double current;
  final double previous;
}

enum _PaymentStatus { successful, pending, failed, other }

class _PaymentRow {
  const _PaymentRow({
    required this.source,
    required this.sourceTable,
    required this.referenceId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.isRevenue,
  });

  final String source;
  final String sourceTable;
  final String referenceId;
  final double amount;
  final _PaymentStatus status;
  final DateTime? createdAt;
  final bool isRevenue;
}

abstract final class _PaymentStatusX {
  static _PaymentStatus from(Object? value) {
    final status = value?.toString().trim().toLowerCase() ?? '';
    return switch (status) {
      'paid' ||
      'success' ||
      'successful' ||
      'succeeded' ||
      'captured' ||
      'completed' ||
      'complete' ||
      'settled' => _PaymentStatus.successful,
      'pending' ||
      'processing' ||
      'created' ||
      'initiated' => _PaymentStatus.pending,
      'failed' ||
      'failure' ||
      'fail' ||
      'cancelled' ||
      'canceled' ||
      'rejected' ||
      'declined' => _PaymentStatus.failed,
      _ => status.isEmpty ? _PaymentStatus.pending : _PaymentStatus.other,
    };
  }
}

const _dateKeys = [
  'created_at',
  'createdAt',
  'updated_at',
  'updatedAt',
  'transaction_date',
  'booking_date',
  'order_date',
];
