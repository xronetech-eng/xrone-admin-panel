class PaymentAdminData {
  const PaymentAdminData({
    required this.userTransactions,
    required this.pilotTransactions,
    required this.storePayments,
  });

  final List<PaymentTransaction> userTransactions;
  final List<PaymentTransaction> pilotTransactions;
  final List<StorePaymentTransaction> storePayments;

  bool get isEmpty =>
      userTransactions.isEmpty &&
      pilotTransactions.isEmpty &&
      storePayments.isEmpty;

  PaymentSummary get summary {
    final payments = [...userTransactions, ...pilotTransactions];
    final storeRevenue = storePayments
        .where((payment) => payment.isSuccessful)
        .fold<double>(0, (total, payment) => total + payment.amountValue);
    final transactionRevenue = payments
        .where((payment) => payment.isSuccessful)
        .fold<double>(0, (total, payment) => total + payment.amountValue);

    return PaymentSummary(
      totalRevenue: _formatCurrency(transactionRevenue + storeRevenue),
      successfulPayments:
          payments.where((payment) => payment.isSuccessful).length +
          storePayments.where((payment) => payment.isSuccessful).length,
      pendingPayments:
          payments.where((payment) => payment.isPending).length +
          storePayments.where((payment) => payment.isPending).length,
      failedPayments:
          payments.where((payment) => payment.isFailed).length +
          storePayments.where((payment) => payment.isFailed).length,
    );
  }
}

class PaymentSummary {
  const PaymentSummary({
    required this.totalRevenue,
    required this.successfulPayments,
    required this.pendingPayments,
    required this.failedPayments,
  });

  final String totalRevenue;
  final int successfulPayments;
  final int pendingPayments;
  final int failedPayments;
}

class PaymentTransaction {
  const PaymentTransaction({
    required this.transactionId,
    required this.sourceType,
    required this.userName,
    required this.pilotName,
    required this.amount,
    required this.amountValue,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.date,
    required this.dateValue,
    required this.referenceId,
  });

  final String transactionId;
  final String sourceType;
  final String userName;
  final String pilotName;
  final String amount;
  final double amountValue;
  final String paymentMethod;
  final String paymentStatus;
  final String date;
  final DateTime? dateValue;
  final String referenceId;

  bool get isSuccessful => paymentStatus == PaymentStatusLabels.successful;
  bool get isPending => paymentStatus == PaymentStatusLabels.pending;
  bool get isFailed => paymentStatus == PaymentStatusLabels.failed;

  String get searchableText => [
    transactionId,
    sourceType,
    userName,
    pilotName,
    amount,
    paymentMethod,
    paymentStatus,
    date,
    referenceId,
  ].join(' ').toLowerCase();

  factory PaymentTransaction.fromUserRow({
    required Map<String, dynamic> row,
    Map<String, dynamic>? booking,
    String? userName,
    String? pilotName,
  }) {
    final amount = _firstAmount(row, const [
      'total_paid_amount',
      'paid_amount',
      'amount',
      'total_amount',
      'final_amount',
    ]);
    final dateValue = _firstDate(row, const [
      'transaction_date',
      'created_at',
      'createdAt',
      'updated_at',
    ]);

    return PaymentTransaction(
      transactionId: _displayId(
        _firstString(row, const [
          'transaction_id',
          'razorpay_payment_id',
          'payment_id',
          'id',
        ]),
      ),
      sourceType: 'User Booking',
      userName: _fallbackLabel(userName, 'User not available'),
      pilotName: _fallbackLabel(pilotName, '-'),
      amount: _formatCurrency(amount),
      amountValue: amount?.toDouble() ?? 0,
      paymentMethod: _firstString(row, const [
        'payment_method',
        'payment_mode',
        'method',
        'gateway',
        'transaction_type',
        'payment_type',
      ], fallback: '-'),
      paymentStatus: PaymentStatusLabels.from(row['status']),
      date: _formatDate(dateValue ?? row['transaction_date']),
      dateValue: dateValue,
      referenceId: _displayId(
        _firstString(
          row,
          const ['reference_id', 'booking_id', 'razorpay_order_id', 'order_id'],
          fallback: _firstString(booking, const [
            'booking_number',
            'booking_no',
            'booking_code',
            'booking_reference',
            'id',
          ]),
        ),
      ),
    );
  }

  factory PaymentTransaction.fromPilotRow({
    required Map<String, dynamic> row,
    Map<String, dynamic>? booking,
    String? userName,
    String? pilotName,
  }) {
    final amount = _firstAmount(row, const [
      'payout_amount',
      'pilot_charges',
      'amount',
      'total_amount',
    ]);
    final dateValue = _firstDate(row, const [
      'transaction_date',
      'created_at',
      'createdAt',
      'updated_at',
    ]);

    return PaymentTransaction(
      transactionId: _displayId(
        _firstString(row, const [
          'transaction_id',
          'razorpay_payment_id',
          'payment_id',
          'id',
        ]),
      ),
      sourceType: 'Pilot Payout',
      userName: _fallbackLabel(userName, '-'),
      pilotName: _fallbackLabel(pilotName, 'Pilot not available'),
      amount: _formatCurrency(amount),
      amountValue: amount?.toDouble() ?? 0,
      paymentMethod: _firstString(row, const [
        'payment_method',
        'payment_mode',
        'method',
        'gateway',
        'transaction_type',
        'payment_type',
      ], fallback: '-'),
      paymentStatus: PaymentStatusLabels.from(row['status']),
      date: _formatDate(dateValue ?? row['transaction_date']),
      dateValue: dateValue,
      referenceId: _displayId(
        _firstString(
          row,
          const ['reference_id', 'booking_id', 'razorpay_order_id', 'order_id'],
          fallback: _firstString(booking, const [
            'booking_number',
            'booking_no',
            'booking_code',
            'booking_reference',
            'id',
          ]),
        ),
      ),
    );
  }
}

class StorePaymentTransaction {
  const StorePaymentTransaction({
    required this.orderNumber,
    required this.amount,
    required this.amountValue,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdDate,
    required this.dateValue,
  });

  final String orderNumber;
  final String amount;
  final double amountValue;
  final String paymentMethod;
  final String paymentStatus;
  final String createdDate;
  final DateTime? dateValue;

  bool get isSuccessful => paymentStatus == PaymentStatusLabels.successful;
  bool get isPending => paymentStatus == PaymentStatusLabels.pending;
  bool get isFailed => paymentStatus == PaymentStatusLabels.failed;

  String get searchableText => [
    orderNumber,
    amount,
    paymentMethod,
    paymentStatus,
    createdDate,
  ].join(' ').toLowerCase();

  factory StorePaymentTransaction.fromRow(Map<String, dynamic> row) {
    final amount = _firstAmount(row, const [
      'total_amount',
      'paid_amount',
      'amount',
      'total',
    ]);
    final dateValue = _firstDate(row, const [
      'created_at',
      'createdAt',
      'order_date',
      'updated_at',
    ]);

    return StorePaymentTransaction(
      orderNumber: _displayId(
        _firstString(row, const [
          'order_number',
          'number',
          'order_id',
          'razorpay_order_id',
          'id',
        ]),
      ),
      amount: _formatCurrency(amount),
      amountValue: amount?.toDouble() ?? 0,
      paymentMethod: _firstString(row, const [
        'payment_method',
        'payment_mode',
        'method',
        'gateway',
        'payment_type',
      ], fallback: '-'),
      paymentStatus: PaymentStatusLabels.from(row['payment_status']),
      createdDate: _formatDate(dateValue ?? row['created_at']),
      dateValue: dateValue,
    );
  }
}

abstract final class PaymentStatusLabels {
  static const all = 'All';
  static const successful = 'Successful';
  static const pending = 'Pending';
  static const failed = 'Failed';

  static bool matchesFilter(Object? value, String filter) {
    if (filter == all) {
      return true;
    }

    return from(value) == from(filter);
  }

  static String from(Object? value) {
    final status = value?.toString().trim().toLowerCase() ?? '';
    return switch (status) {
      'paid' ||
      'success' ||
      'successful' ||
      'succeeded' ||
      'captured' ||
      'completed' ||
      'complete' ||
      'settled' => successful,
      'pending' || 'processing' || 'created' || 'initiated' => pending,
      'failed' ||
      'failure' ||
      'fail' ||
      'cancelled' ||
      'canceled' ||
      'rejected' ||
      'declined' => failed,
      _ => status.isEmpty ? pending : _titleCase(status),
    };
  }
}

String _fallbackLabel(String? value, String fallback) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _firstString(
  Map<String, dynamic>? row,
  List<String> keys, {
  String fallback = '-',
}) {
  if (row == null) {
    return fallback;
  }

  for (final key in keys) {
    final value = row[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return fallback;
}

num? _firstAmount(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final amount = _readAmount(row[key]);
    if (amount != null) {
      return amount;
    }
  }

  return null;
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

DateTime? _firstDate(Map<String, dynamic> row, List<String> keys) {
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

String _formatDate(Object? value) {
  final parsed = value is DateTime ? value : _parseDate(value);
  if (parsed == null) {
    final text = value?.toString().trim() ?? '';
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

String _formatCurrency(num? amount) {
  if (amount == null) {
    return '-';
  }

  return 'Rs. ${amount.toDouble().toStringAsFixed(2)}';
}

String _displayId(String value) {
  final text = value.trim();
  if (text.isEmpty || text == '-') {
    return '-';
  }
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
