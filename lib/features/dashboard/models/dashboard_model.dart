class DashboardData {
  const DashboardData({
    required this.users,
    required this.pilots,
    required this.store,
    required this.payments,
    required this.bookings,
    required this.bookingItems,
    required this.recentActivities,
    required this.allActivities,
    required this.searchItems,
  });

  final DashboardUsersSummary users;
  final DashboardPilotsSummary pilots;
  final DashboardStoreSummary store;
  final DashboardPaymentsSummary payments;
  final DashboardBookingsSummary bookings;
  final List<DashboardBookingItem> bookingItems;
  final List<DashboardActivity> recentActivities;
  final List<DashboardActivity> allActivities;
  final List<DashboardSearchItem> searchItems;

  static const empty = DashboardData(
    users: DashboardUsersSummary.empty,
    pilots: DashboardPilotsSummary.empty,
    store: DashboardStoreSummary.empty,
    payments: DashboardPaymentsSummary.empty,
    bookings: DashboardBookingsSummary.empty,
    bookingItems: [],
    recentActivities: [],
    allActivities: [],
    searchItems: [],
  );

  DashboardData filteredBy(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return this;
    }

    final matches = searchItems
        .where((item) => item.matches(normalizedQuery))
        .toList();
    final users = matches
        .where((item) => item.source == DashboardSearchSource.user)
        .toList();
    final pilots = matches
        .where((item) => item.source == DashboardSearchSource.pilot)
        .toList();
    final orders = matches
        .where((item) => item.source == DashboardSearchSource.storeOrder)
        .toList();
    final bookingItems = matches
        .where((item) => item.source == DashboardSearchSource.booking)
        .toList();

    final activities = <DashboardActivity>[];
    final seenActivities = <String>{};
    for (final item in matches) {
      final activity = item.activity;
      if (activity == null) {
        continue;
      }

      final key =
          '${activity.name}|${activity.action}|${activity.source}|${activity.status}|${activity.time}';
      if (seenActivities.add(key)) {
        activities.add(activity);
      }
    }

    activities.sort(_compareActivitiesByDate);

    return DashboardData(
      users: DashboardUsersSummary(
        totalUsers: users.length,
        activeUsers: users.where((item) => item.isActive).length,
        newUsers: users.where((item) => item.isNew).length,
        totalUsersGrowth: users.isEmpty ? '0%' : this.users.totalUsersGrowth,
        activeUsersGrowth: users.isEmpty ? '0%' : this.users.activeUsersGrowth,
        newUsersGrowth: users.isEmpty ? '0%' : this.users.newUsersGrowth,
      ),
      pilots: DashboardPilotsSummary(
        totalPilots: pilots.length,
        approvedPilots: pilots
            .where((item) => item.status == 'approved')
            .length,
        pendingPilots: pilots.where((item) => item.status == 'pending').length,
        rejectedPilots: pilots
            .where((item) => item.status == 'rejected')
            .length,
        totalPilotsGrowth: pilots.isEmpty
            ? '0%'
            : this.pilots.totalPilotsGrowth,
        approvedPilotsGrowth: pilots.isEmpty
            ? '0%'
            : this.pilots.approvedPilotsGrowth,
        pendingPilotsGrowth: pilots.isEmpty
            ? '0%'
            : this.pilots.pendingPilotsGrowth,
        rejectedPilotsGrowth: pilots.isEmpty
            ? '0%'
            : this.pilots.rejectedPilotsGrowth,
      ),
      store: DashboardStoreSummary(
        totalCategories: 0,
        totalProducts: 0,
        totalOrders: orders.length,
        totalWishlistItems: 0,
        totalCartItems: 0,
        totalCategoriesGrowth: '0%',
        totalProductsGrowth: '0%',
        totalOrdersGrowth: orders.isEmpty ? '0%' : store.totalOrdersGrowth,
        totalWishlistItemsGrowth: '0%',
        totalCartItemsGrowth: '0%',
      ),
      payments: payments,
      bookings: DashboardBookingsSummary(
        totalBookings: bookingItems.length,
        activeRequests: bookingItems.where((item) => item.isActive).length,
        pending: bookingItems.where((item) => item.status == 'pending').length,
        accepted: bookingItems
            .where((item) => item.status == 'accepted')
            .length,
        working: bookingItems.where((item) => item.status == 'working').length,
        completed: bookingItems
            .where((item) => item.status == 'completed')
            .length,
        totalBookingsGrowth: bookingItems.isEmpty
            ? '0%'
            : bookings.totalBookingsGrowth,
        activeRequestsGrowth: bookingItems.isEmpty
            ? '0%'
            : bookings.activeRequestsGrowth,
      ),
      bookingItems: this.bookingItems
          .where((item) => item.matches(normalizedQuery))
          .toList(),
      recentActivities: activities.take(4).toList(),
      allActivities: activities,
      searchItems: matches,
    );
  }

  int searchResultCount(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return searchItems.length;
    }

    return searchItems.where((item) => item.matches(normalizedQuery)).length;
  }
}

class DashboardUsersSummary {
  const DashboardUsersSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.totalUsersGrowth,
    required this.activeUsersGrowth,
    required this.newUsersGrowth,
  });

  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final String totalUsersGrowth;
  final String activeUsersGrowth;
  final String newUsersGrowth;

  static const empty = DashboardUsersSummary(
    totalUsers: 0,
    activeUsers: 0,
    newUsers: 0,
    totalUsersGrowth: '0%',
    activeUsersGrowth: '0%',
    newUsersGrowth: '0%',
  );
}

class DashboardPilotsSummary {
  const DashboardPilotsSummary({
    required this.totalPilots,
    required this.approvedPilots,
    required this.pendingPilots,
    required this.rejectedPilots,
    required this.totalPilotsGrowth,
    required this.approvedPilotsGrowth,
    required this.pendingPilotsGrowth,
    required this.rejectedPilotsGrowth,
  });

  final int totalPilots;
  final int approvedPilots;
  final int pendingPilots;
  final int rejectedPilots;
  final String totalPilotsGrowth;
  final String approvedPilotsGrowth;
  final String pendingPilotsGrowth;
  final String rejectedPilotsGrowth;

  static const empty = DashboardPilotsSummary(
    totalPilots: 0,
    approvedPilots: 0,
    pendingPilots: 0,
    rejectedPilots: 0,
    totalPilotsGrowth: '0%',
    approvedPilotsGrowth: '0%',
    pendingPilotsGrowth: '0%',
    rejectedPilotsGrowth: '0%',
  );
}

class DashboardStoreSummary {
  const DashboardStoreSummary({
    required this.totalCategories,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalWishlistItems,
    required this.totalCartItems,
    required this.totalCategoriesGrowth,
    required this.totalProductsGrowth,
    required this.totalOrdersGrowth,
    required this.totalWishlistItemsGrowth,
    required this.totalCartItemsGrowth,
  });

  final int totalCategories;
  final int totalProducts;
  final int totalOrders;
  final int totalWishlistItems;
  final int totalCartItems;
  final String totalCategoriesGrowth;
  final String totalProductsGrowth;
  final String totalOrdersGrowth;
  final String totalWishlistItemsGrowth;
  final String totalCartItemsGrowth;

  static const empty = DashboardStoreSummary(
    totalCategories: 0,
    totalProducts: 0,
    totalOrders: 0,
    totalWishlistItems: 0,
    totalCartItems: 0,
    totalCategoriesGrowth: '0%',
    totalProductsGrowth: '0%',
    totalOrdersGrowth: '0%',
    totalWishlistItemsGrowth: '0%',
    totalCartItemsGrowth: '0%',
  );
}

class DashboardPaymentsSummary {
  const DashboardPaymentsSummary({
    required this.totalRevenue,
    required this.totalRevenueLabel,
    required this.last30DaysRevenue,
    required this.last30DaysRevenueLabel,
    required this.successfulPayments,
    required this.pendingPayments,
    required this.failedPayments,
    required this.totalRevenueGrowth,
    required this.successfulPaymentsGrowth,
    required this.pendingPaymentsGrowth,
    required this.failedPaymentsGrowth,
    required this.revenueChartValues,
  });

  final double totalRevenue;
  final String totalRevenueLabel;
  final double last30DaysRevenue;
  final String last30DaysRevenueLabel;
  final int successfulPayments;
  final int pendingPayments;
  final int failedPayments;
  final String totalRevenueGrowth;
  final String successfulPaymentsGrowth;
  final String pendingPaymentsGrowth;
  final String failedPaymentsGrowth;
  final List<double> revenueChartValues;

  static const empty = DashboardPaymentsSummary(
    totalRevenue: 0,
    totalRevenueLabel: 'Rs. 0.00',
    last30DaysRevenue: 0,
    last30DaysRevenueLabel: 'Rs. 0.00',
    successfulPayments: 0,
    pendingPayments: 0,
    failedPayments: 0,
    totalRevenueGrowth: '0%',
    successfulPaymentsGrowth: '0%',
    pendingPaymentsGrowth: '0%',
    failedPaymentsGrowth: '0%',
    revenueChartValues: [],
  );
}

class DashboardBookingsSummary {
  const DashboardBookingsSummary({
    required this.totalBookings,
    required this.activeRequests,
    required this.pending,
    required this.accepted,
    required this.working,
    required this.completed,
    required this.totalBookingsGrowth,
    required this.activeRequestsGrowth,
  });

  final int totalBookings;
  final int activeRequests;
  final int pending;
  final int accepted;
  final int working;
  final int completed;
  final String totalBookingsGrowth;
  final String activeRequestsGrowth;

  static const empty = DashboardBookingsSummary(
    totalBookings: 0,
    activeRequests: 0,
    pending: 0,
    accepted: 0,
    working: 0,
    completed: 0,
    totalBookingsGrowth: '0%',
    activeRequestsGrowth: '0%',
  );
}

class DashboardActivity {
  const DashboardActivity({
    required this.name,
    required this.action,
    required this.source,
    required this.status,
    required this.time,
    required this.createdAt,
    this.type = '',
    this.description = '',
  });

  final String name;
  final String action;
  final String source;
  final String type;
  final String description;
  final String status;
  final String time;
  final DateTime? createdAt;
}

class DashboardBookingItem {
  const DashboardBookingItem({
    required this.reference,
    required this.customerName,
    required this.status,
    required this.createdAt,
    required this.dateTimeLabel,
  });

  final String reference;
  final String customerName;
  final String status;
  final DateTime? createdAt;
  final String dateTimeLabel;

  bool matches(String normalizedQuery) {
    return '$reference $customerName $status $dateTimeLabel'
        .toLowerCase()
        .contains(normalizedQuery);
  }
}

enum DashboardSearchSource { user, pilot, storeOrder, booking, activity }

class DashboardSearchItem {
  const DashboardSearchItem({
    required this.source,
    required this.searchableText,
    required this.status,
    required this.isActive,
    required this.isNew,
    required this.createdAt,
    this.activity,
  });

  final DashboardSearchSource source;
  final String searchableText;
  final String status;
  final bool isActive;
  final bool isNew;
  final DateTime? createdAt;
  final DashboardActivity? activity;

  bool matches(String normalizedQuery) {
    return searchableText.toLowerCase().contains(normalizedQuery);
  }
}

int _compareActivitiesByDate(
  DashboardActivity first,
  DashboardActivity second,
) {
  final firstDate = first.createdAt;
  final secondDate = second.createdAt;
  if (firstDate == null && secondDate == null) return 0;
  if (firstDate == null) return 1;
  if (secondDate == null) return -1;
  return secondDate.compareTo(firstDate);
}
