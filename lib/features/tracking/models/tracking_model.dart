enum TrackingTabType { bookings, pilots, store }

class TrackingData {
  const TrackingData({
    required this.summary,
    required this.bookings,
    required this.pilots,
    required this.storeOrders,
  });

  final TrackingSummary summary;
  final List<TrackingRowData> bookings;
  final List<TrackingRowData> pilots;
  final List<TrackingRowData> storeOrders;

  static const empty = TrackingData(
    summary: TrackingSummary.empty,
    bookings: [],
    pilots: [],
    storeOrders: [],
  );
}

class TrackingSummary {
  const TrackingSummary({
    required this.activeBookings,
    required this.activePilots,
    required this.activeStoreOrders,
    required this.completedDeliveries,
  });

  final int activeBookings;
  final int activePilots;
  final int activeStoreOrders;
  final int completedDeliveries;

  static const empty = TrackingSummary(
    activeBookings: 0,
    activePilots: 0,
    activeStoreOrders: 0,
    completedDeliveries: 0,
  );
}

class TrackingRowData {
  const TrackingRowData({
    required this.type,
    required this.id,
    required this.primaryName,
    required this.secondaryName,
    required this.firstDetail,
    required this.secondDetail,
    required this.status,
    required this.createdDate,
    required this.timelineSteps,
    required this.currentStepIndex,
    this.sortDate,
    this.amount = '-',
    this.paymentStatus = '-',
    this.assignedOrders = 0,
    this.activeDeliveries = 0,
  });

  final TrackingTabType type;
  final String id;
  final String primaryName;
  final String secondaryName;
  final String firstDetail;
  final String secondDetail;
  final String status;
  final String createdDate;
  final List<String> timelineSteps;
  final int currentStepIndex;
  final DateTime? sortDate;
  final String amount;
  final String paymentStatus;
  final int assignedOrders;
  final int activeDeliveries;

  String get bookingId => type == TrackingTabType.bookings ? id : '-';
  String get orderNumber => type == TrackingTabType.store ? id : '-';
  String get userName => type == TrackingTabType.bookings ? primaryName : '-';
  String get pilotName => switch (type) {
    TrackingTabType.bookings || TrackingTabType.pilots => secondaryName,
    TrackingTabType.store => '-',
  };
  String get bookingStatus => status;
  String get pilotLocation => firstDetail;
  String get userLocation => secondDetail;
  String get lastUpdated => createdDate;

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return [
      id,
      primaryName,
      secondaryName,
      firstDetail,
      secondDetail,
      status,
      amount,
      paymentStatus,
    ].join(' ').toLowerCase().contains(normalized);
  }

  bool matchesFilter(String filter) {
    final value = filter.trim().toLowerCase();
    if (value == 'all') {
      return true;
    }

    final normalizedStatus = normalizeTrackingStatus(status).toLowerCase();
    return switch (value) {
      'active' =>
        normalizedStatus == 'active' || normalizedStatus == 'in progress',
      'pending' => normalizedStatus == 'pending',
      'completed' =>
        normalizedStatus == 'completed' || normalizedStatus == 'delivered',
      'cancelled' => normalizedStatus == 'cancelled',
      _ => normalizedStatus == value,
    };
  }
}

String normalizeTrackingStatus(String status) {
  final value = status.trim().toLowerCase();
  return switch (value) {
    'accepted' || 'confirmed' => 'Accepted',
    'started' ||
    'working' ||
    'in_progress' ||
    'in progress' ||
    'processing' => 'In Progress',
    'completed' || 'complete' => 'Completed',
    'delivered' => 'Delivered',
    'cancelled' || 'canceled' => 'Cancelled',
    'shipped' => 'Shipped',
    'pending' || 'created' || 'initiated' || '' => 'Pending',
    _ => _titleCase(value),
  };
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'\s+|_+|-+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
