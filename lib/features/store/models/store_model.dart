class StoreAdminData {
  const StoreAdminData({
    required this.categories,
    required this.products,
    required this.images,
    required this.orders,
    required this.orderItems,
    required this.addresses,
    required this.carts,
    required this.cartItems,
    required this.wishlistItems,
  });

  final List<StoreCategory> categories;
  final List<StoreProduct> products;
  final List<StoreProductImage> images;
  final List<StoreOrder> orders;
  final List<StoreOrderItem> orderItems;
  final List<StoreAddress> addresses;
  final List<StoreCart> carts;
  final List<StoreCartItem> cartItems;
  final List<StoreWishlistItem> wishlistItems;

  StoreSummary get summary {
    return StoreSummary(
      totalCategories: categories.length,
      totalProducts: products.length,
      totalOrders: orders.length,
      totalWishlistItems: wishlistItems.length,
      totalCartItems: cartItems.length,
    );
  }

  String categoryName(String? id) {
    if (id == null || id.isEmpty) return 'Unassigned';
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return 'Unassigned';
  }

  String productName(String? id) {
    if (id == null || id.isEmpty) return 'Unknown product';
    for (final product in products) {
      if (product.id == id) return product.name;
    }
    return 'Unknown product';
  }

  StoreProductImage? primaryImageFor(String productId) {
    final matches = images.where((image) => image.productId == productId);
    if (matches.isEmpty) return null;
    for (final image in matches) {
      if (image.isPrimary) return image;
    }
    return matches.first;
  }

  List<StoreProductImage> imagesFor(String productId) {
    return images.where((image) => image.productId == productId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<StoreOrderItem> itemsForOrder(String orderId) {
    return orderItems.where((item) => item.orderId == orderId).toList();
  }

  StoreAddress? addressForOrder(StoreOrder order) {
    if (order.addressId.isEmpty) return null;
    for (final address in addresses) {
      if (address.id == order.addressId) return address;
    }
    return null;
  }

  StoreAddress? addressForCustomer(String customerId) {
    if (customerId.isEmpty) return null;
    final matches = addresses
        .where((address) => address.userId == customerId)
        .toList();
    if (matches.isEmpty) return null;
    return matches.first;
  }

  List<WishlistProductCount> get wishlistCounts {
    final counts = <String, int>{};
    for (final item in wishlistItems) {
      final productId = item.productId;
      if (productId.isEmpty) continue;
      counts[productId] = (counts[productId] ?? 0) + 1;
    }
    final rows = counts.entries
        .map(
          (entry) => WishlistProductCount(
            productId: entry.key,
            productName: productName(entry.key),
            count: entry.value,
          ),
        )
        .toList();
    rows.sort((a, b) => b.count.compareTo(a.count));
    return rows;
  }

  List<WishlistAnalyticsRow> get wishlistAnalyticsRows {
    final grouped = <String, List<StoreWishlistItem>>{};
    for (final item in wishlistItems) {
      final customerKey = _visibleString(item.customerId, item.customerMobile);
      final key =
          '${customerKey.isEmpty ? item.id : customerKey}|${item.productId}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final rows = <WishlistAnalyticsRow>[];
    for (final items in grouped.values) {
      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      final item = items.first;
      final address = addressForCustomer(item.customerId);
      rows.add(
        WishlistAnalyticsRow(
          customerName: _visibleString(
            item.customerName,
            address?.recipientName ?? '',
          ),
          customerMobile: _visibleString(
            item.customerMobile,
            address?.phone ?? '',
          ),
          productName: productName(item.productId),
          wishlistDate: item.createdAt,
          count: items.length,
        ),
      );
    }

    rows.sort((a, b) {
      final aDate = a.wishlistDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.wishlistDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateOrder = bDate.compareTo(aDate);
      if (dateOrder != 0) return dateOrder;
      return a.productName.compareTo(b.productName);
    });
    return rows;
  }
}

class StoreSummary {
  const StoreSummary({
    required this.totalCategories,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalWishlistItems,
    required this.totalCartItems,
  });

  final int totalCategories;
  final int totalProducts;
  final int totalOrders;
  final int totalWishlistItems;
  final int totalCartItems;
}

class StoreCategory {
  const StoreCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final String iconKey;
  final int sortOrder;
  final bool isActive;

  factory StoreCategory.fromMap(Map<String, dynamic> row) {
    return StoreCategory(
      id: _string(row, 'id'),
      name: _string(row, 'name'),
      iconKey: _string(row, 'icon_key'),
      sortOrder: _int(row, 'sort_order'),
      isActive: _bool(row, 'is_active', fallback: true),
    );
  }
}

class StoreCategoryDraft {
  const StoreCategoryDraft({
    required this.name,
    required this.iconKey,
    required this.sortOrder,
    required this.isActive,
  });

  final String name;
  final String iconKey;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toPayload() {
    return {
      'name': name,
      'icon_key': iconKey,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.price,
    required this.currency,
    required this.gstPercentage,
    required this.stockQuantity,
    required this.stockStatus,
    required this.isFeatured,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String categoryId;
  final String name;
  final String shortDescription;
  final String description;
  final double price;
  final String currency;
  final double gstPercentage;
  final int stockQuantity;
  final String stockStatus;
  final bool isFeatured;
  final bool isActive;
  final int sortOrder;

  factory StoreProduct.fromMap(Map<String, dynamic> row) {
    return StoreProduct(
      id: _string(row, 'id'),
      categoryId: _string(row, 'category_id'),
      name: _string(row, 'name'),
      shortDescription: _string(row, 'short_description'),
      description: _string(row, 'description'),
      price: _double(row, 'price'),
      currency: _string(row, 'currency', fallback: 'INR'),
      gstPercentage: _firstDouble(row, [
        'gst_percentage',
        'gst_percent',
        'gst',
        'tax_percentage',
        'tax_rate',
      ]),
      stockQuantity: _int(row, 'stock_quantity'),
      stockStatus: _string(row, 'stock_status', fallback: 'in_stock'),
      isFeatured: _bool(row, 'is_featured'),
      isActive: _bool(row, 'is_active', fallback: true),
      sortOrder: _int(row, 'sort_order'),
    );
  }
}

class StoreProductDraft {
  const StoreProductDraft({
    required this.categoryId,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.price,
    required this.currency,
    required this.gstPercentage,
    required this.stockQuantity,
    required this.stockStatus,
    required this.isFeatured,
    required this.isActive,
    required this.sortOrder,
  });

  final String categoryId;
  final String name;
  final String shortDescription;
  final String description;
  final double price;
  final String currency;
  final double gstPercentage;
  final int stockQuantity;
  final String stockStatus;
  final bool isFeatured;
  final bool isActive;
  final int sortOrder;

  Map<String, dynamic> toPayload() {
    return {
      'category_id': categoryId,
      'name': name,
      'short_description': shortDescription,
      'description': description,
      'price': price,
      'currency': currency,
      'gst_percentage': gstPercentage,
      'stock_quantity': stockQuantity,
      'stock_status': stockStatus,
      'is_featured': isFeatured,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}

class StoreProductImage {
  const StoreProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    required this.altText,
    required this.isPrimary,
    required this.sortOrder,
  });

  final String id;
  final String productId;
  final String imageUrl;
  final String altText;
  final bool isPrimary;
  final int sortOrder;

  factory StoreProductImage.fromMap(Map<String, dynamic> row) {
    return StoreProductImage(
      id: _string(row, 'id'),
      productId: _string(row, 'product_id'),
      imageUrl: _firstString(row, ['image_url', 'url', 'public_url']),
      altText: _string(row, 'alt_text'),
      isPrimary: _bool(row, 'is_primary'),
      sortOrder: _int(row, 'sort_order'),
    );
  }
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.customerId,
    required this.addressId,
    required this.orderNumber,
    required this.customerName,
    required this.customerMobile,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.deliveryAddress,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.paymentStatus,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final String addressId;
  final String orderNumber;
  final String customerName;
  final String customerMobile;
  final String fullAddress;
  final String city;
  final String state;
  final String postalCode;
  final String deliveryAddress;
  final String status;
  final double totalAmount;
  final String currency;
  final String paymentStatus;
  final DateTime? createdAt;

  factory StoreOrder.fromMap(Map<String, dynamic> row) {
    final id = _string(row, 'id');
    final savedDeliveryAddress = _firstString(row, [
      'delivery_address',
      'shipping_address',
      'full_address',
      'address',
    ]);
    return StoreOrder(
      id: id,
      customerId: _firstString(row, ['owner_id', 'user_id', 'customer_id']),
      addressId: _firstString(row, [
        'address_id',
        'store_address_id',
        'shipping_address_id',
        'delivery_address_id',
      ]),
      orderNumber: _firstString(row, ['order_number', 'number'], fallback: id),
      customerName: _firstString(row, [
        'customer_name',
        'recipient_name',
        'name',
      ], fallback: '-'),
      customerMobile: _firstString(row, [
        'customer_mobile',
        'customer_phone',
        'mobile',
        'phone',
        'phone_number',
        'contact_number',
      ]),
      fullAddress: savedDeliveryAddress,
      city: _firstString(row, ['delivery_city', 'shipping_city', 'city']),
      state: _firstString(row, ['delivery_state', 'shipping_state', 'state']),
      postalCode: _firstString(row, [
        'delivery_pin',
        'delivery_pincode',
        'shipping_pin',
        'shipping_pincode',
        'postal_code',
        'pincode',
        'pin',
        'zip',
      ]),
      deliveryAddress: savedDeliveryAddress,
      status: _string(row, 'status', fallback: 'pending'),
      totalAmount: _firstDouble(row, ['total_amount', 'amount', 'total']),
      currency: _string(row, 'currency', fallback: 'INR'),
      paymentStatus: _string(row, 'payment_status', fallback: 'pending'),
      createdAt: _date(row, 'created_at'),
    );
  }
}

class StoreOrderItem {
  const StoreOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  factory StoreOrderItem.fromMap(Map<String, dynamic> row) {
    final quantity = _int(row, 'quantity');
    final unitPrice = _firstDouble(row, ['unit_price', 'price']);
    return StoreOrderItem(
      id: _string(row, 'id'),
      orderId: _string(row, 'order_id'),
      productId: _string(row, 'product_id'),
      productName: _firstString(row, ['product_name', 'name']),
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: _firstDouble(row, [
        'total_price',
        'line_total',
        'total_amount',
      ], fallback: quantity * unitPrice),
    );
  }
}

class StoreAddress {
  const StoreAddress({
    required this.id,
    required this.userId,
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  final String id;
  final String userId;
  final String recipientName;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  factory StoreAddress.fromMap(Map<String, dynamic> row) {
    return StoreAddress(
      id: _string(row, 'id'),
      userId: _firstString(row, ['owner_id', 'user_id', 'customer_id']),
      recipientName: _firstString(row, [
        'recipient_name',
        'full_name',
        'name',
        'title',
      ]),
      phone: _firstString(row, [
        'phone',
        'phone_number',
        'mobile',
        'contact_number',
      ]),
      address: _pilotStoreAddressFromRow(row),
      city: _firstString(row, ['city', 'town']),
      state: _firstString(row, ['state', 'province']),
      postalCode: _firstString(row, ['postal_code', 'pincode', 'pin', 'zip']),
      country: _string(row, 'country'),
    );
  }
}

class StoreCart {
  const StoreCart({required this.id, required this.isActive});

  final String id;
  final bool isActive;

  factory StoreCart.fromMap(Map<String, dynamic> row) {
    final status = _string(row, 'status');
    return StoreCart(
      id: _string(row, 'id'),
      isActive: row.containsKey('is_active')
          ? _bool(row, 'is_active', fallback: true)
          : status.isEmpty || status == 'active',
    );
  }
}

class StoreCartItem {
  const StoreCartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String cartId;
  final String productId;
  final int quantity;
  final double unitPrice;

  factory StoreCartItem.fromMap(Map<String, dynamic> row) {
    return StoreCartItem(
      id: _string(row, 'id'),
      cartId: _string(row, 'cart_id'),
      productId: _string(row, 'product_id'),
      quantity: _int(row, 'quantity', fallback: 1),
      unitPrice: _firstDouble(row, ['unit_price', 'price']),
    );
  }
}

class StoreWishlistItem {
  const StoreWishlistItem({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String customerId;
  final String customerName;
  final String customerMobile;
  final DateTime? createdAt;

  factory StoreWishlistItem.fromMap(Map<String, dynamic> row) {
    return StoreWishlistItem(
      id: _string(row, 'id'),
      productId: _string(row, 'product_id'),
      customerId: _firstString(row, ['owner_id', 'user_id', 'customer_id']),
      customerName: _firstString(row, [
        'customer_name',
        'recipient_name',
        'full_name',
        'name',
      ]),
      customerMobile: _firstString(row, [
        'customer_mobile',
        'customer_phone',
        'mobile',
        'phone',
        'phone_number',
        'contact_number',
      ]),
      createdAt: _date(row, 'created_at'),
    );
  }
}

class WishlistProductCount {
  const WishlistProductCount({
    required this.productId,
    required this.productName,
    required this.count,
  });

  final String productId;
  final String productName;
  final int count;
}

class WishlistAnalyticsRow {
  const WishlistAnalyticsRow({
    required this.customerName,
    required this.customerMobile,
    required this.productName,
    required this.wishlistDate,
    required this.count,
  });

  final String customerName;
  final String customerMobile;
  final String productName;
  final DateTime? wishlistDate;
  final int count;
}

String _string(Map<String, dynamic> row, String key, {String fallback = ''}) {
  final value = row[key];
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _firstString(
  Map<String, dynamic> row,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = row[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
}

String _pilotStoreAddressFromRow(Map<String, dynamic> row) {
  final canonicalAddress = _string(row, 'address_line1');
  final postalCode = _string(row, 'postal_code');
  final containsSavedPin =
      postalCode.isNotEmpty && canonicalAddress.contains(postalCode);

  if (canonicalAddress.split(',').length >= 4 && containsSavedPin) {
    return canonicalAddress;
  }

  return [
    canonicalAddress,
    _string(row, 'address_line2'),
    _string(row, 'city'),
    _string(row, 'state'),
    postalCode,
    _string(row, 'country'),
  ].where((value) => value.trim().isNotEmpty).join(', ');
}

int _int(Map<String, dynamic> row, String key, {int fallback = 0}) {
  final value = row[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(Map<String, dynamic> row, String key, {double fallback = 0}) {
  final value = row[key];
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double _firstDouble(
  Map<String, dynamic> row,
  List<String> keys, {
  double fallback = 0,
}) {
  for (final key in keys) {
    if (row.containsKey(key)) return _double(row, key, fallback: fallback);
  }
  return fallback;
}

bool _bool(Map<String, dynamic> row, String key, {bool fallback = false}) {
  final value = row[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return fallback;
}

DateTime? _date(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String _visibleString(String primary, String fallback) {
  final value = primary.trim();
  if (value.isNotEmpty && value != '-') return value;
  final fallbackValue = fallback.trim();
  return fallbackValue == '-' ? '' : fallbackValue;
}
