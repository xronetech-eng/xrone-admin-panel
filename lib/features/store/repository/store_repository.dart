import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/store_model.dart';

class StoreRepository {
  StoreRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const storageBucket = 'pilot';
  static const productImageFolder = 'store/products/';

  final SupabaseClient _client;

  Future<StoreAdminData> load() async {
    debugPrint('[StoreAdmin] load:start');
    try {
      final results = await Future.wait([
        _select('store_categories'),
        _select('store_products'),
        _select('store_product_images'),
        _select('store_orders'),
        _select('store_order_items'),
        _select('store_addresses'),
        _select('store_carts'),
        _select('store_cart_items'),
        _select('store_wishlist_items'),
      ]);
      final orderRows = await _ordersWithUserNames(results[3]);

      final data = StoreAdminData(
        categories: results[0].map(StoreCategory.fromMap).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        products: results[1].map(StoreProduct.fromMap).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        images: results[2].map(StoreProductImage.fromMap).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        orders: orderRows.map(StoreOrder.fromMap).toList()
          ..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          }),
        orderItems: results[4].map(StoreOrderItem.fromMap).toList(),
        addresses: results[5].map(StoreAddress.fromMap).toList(),
        carts: results[6].map(StoreCart.fromMap).toList(),
        cartItems: results[7].map(StoreCartItem.fromMap).toList(),
        wishlistItems: results[8].map(StoreWishlistItem.fromMap).toList(),
      );
      debugPrint('[StoreAdmin] load:success');
      return data;
    } catch (error) {
      debugPrint('[StoreAdmin] error=$error');
      rethrow;
    }
  }

  Future<void> saveCategory(String? id, StoreCategoryDraft draft) async {
    await _save(
      section: 'category',
      action: () async {
        final payload = draft.toPayload();
        if (id == null || id.isEmpty) {
          await _client.from('store_categories').insert(payload);
        } else {
          await _client.from('store_categories').update(payload).eq('id', id);
        }
      },
    );
  }

  Future<void> deleteCategory(String id) async {
    await _delete(
      type: 'category',
      action: () => _client.from('store_categories').delete().eq('id', id),
    );
  }

  Future<void> updateCategoryActive(String id, bool isActive) async {
    debugPrint('[StoreAdmin] category-toggle');
    await _save(
      section: 'category_active',
      action: () => _client
          .from('store_categories')
          .update({'is_active': isActive})
          .eq('id', id),
    );
  }

  Future<void> saveProduct(String? id, StoreProductDraft draft) async {
    await _save(
      section: 'product',
      action: () async {
        final payload = draft.toPayload();
        if (id == null || id.isEmpty) {
          await _client.from('store_products').insert(payload);
        } else {
          await _client.from('store_products').update(payload).eq('id', id);
        }
      },
    );
  }

  Future<void> updateProductActive(String id, bool isActive) async {
    await _save(
      section: 'product_active',
      action: () => _client
          .from('store_products')
          .update({'is_active': isActive})
          .eq('id', id),
    );
  }

  Future<void> updateProductFeatured(String id, bool isFeatured) async {
    await _save(
      section: 'product_featured',
      action: () => _client
          .from('store_products')
          .update({'is_featured': isFeatured})
          .eq('id', id),
    );
  }

  Future<void> deleteProduct(String id) async {
    await _delete(
      type: 'product',
      action: () => _client.from('store_products').delete().eq('id', id),
    );
  }

  Future<void> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String fileName,
    required bool makePrimary,
    required int sortOrder,
  }) async {
    debugPrint('[StoreAdmin] upload:start');
    try {
      final safeName = fileName
          .trim()
          .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '-')
          .replaceAll(RegExp(r'-+'), '-');
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$productImageFolder$productId-$stamp-$safeName';
      await _client.storage
          .from(storageBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _contentType(fileName)),
          );
      final publicUrl = _client.storage.from(storageBucket).getPublicUrl(path);
      if (makePrimary) {
        await _client
            .from('store_product_images')
            .update({'is_primary': false})
            .eq('product_id', productId);
      }
      await _client.from('store_product_images').insert({
        'product_id': productId,
        'image_url': publicUrl,
        'alt_text': safeName,
        'sort_order': sortOrder,
        'is_primary': makePrimary,
      });
      debugPrint('[StoreAdmin] upload:success');
    } catch (error) {
      debugPrint('[StoreAdmin] error=$error');
      rethrow;
    }
  }

  Future<void> deleteProductImage(StoreProductImage image) async {
    await _delete(
      type: 'product_image',
      action: () async {
        await _client.from('store_product_images').delete().eq('id', image.id);
      },
    );
  }

  Future<void> setPrimaryImage(StoreProductImage image) async {
    await _save(
      section: 'product_image',
      action: () async {
        await _client
            .from('store_product_images')
            .update({'is_primary': false})
            .eq('product_id', image.productId);
        await _client
            .from('store_product_images')
            .update({'is_primary': true})
            .eq('id', image.id);
      },
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _save(
      section: 'order',
      action: () => _client
          .from('store_orders')
          .update({'status': status})
          .eq('id', orderId),
    );
  }

  Future<List<Map<String, dynamic>>> _select(String table) async {
    final rows = await _client.from(table).select();
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _ordersWithUserNames(
    List<Map<String, dynamic>> orderRows,
  ) async {
    debugPrint('[StoreOrderAdmin] load:user');
    final userNames = await _fetchPublicUserNames(
      _idsFromRows(orderRows, 'owner_id'),
    );

    return [for (final row in orderRows) _orderWithUserName(row, userNames)];
  }

  Map<String, dynamic> _orderWithUserName(
    Map<String, dynamic> row,
    Map<String, _CustomerNameResolution> userNames,
  ) {
    final orderId = _rowText(row, 'id');
    final ownerId = _rowText(row, 'owner_id');
    final resolution =
        userNames[ownerId] ?? const _CustomerNameResolution.fallback();
    debugPrint('[StoreOrderAdmin] orderId=$orderId');
    debugPrint('[StoreOrderAdmin] owner_id=$ownerId');
    debugPrint(
      '[StoreOrderAdmin] resolvedCustomerNameSource=${resolution.source}',
    );

    return {...row, 'customer_name': resolution.name};
  }

  Future<Map<String, _CustomerNameResolution>> _fetchPublicUserNames(
    List<String> ownerIds,
  ) async {
    final uniqueIds = ownerIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueIds.isEmpty) {
      return const {};
    }

    final rows = <Map<String, dynamic>>[];
    try {
      for (var index = 0; index < uniqueIds.length; index += 100) {
        final end = index + 100 > uniqueIds.length
            ? uniqueIds.length
            : index + 100;
        final batch = uniqueIds.sublist(index, end);
        rows.addAll(
          (await _client.from('user').select('*').inFilter('id', batch))
              .cast<Map<String, dynamic>>(),
        );
      }
    } catch (error) {
      debugPrint('[StoreOrderAdmin] publicUserLookupError=$error');
      return const {};
    }

    return {
      for (final row in rows)
        if (_rowText(row, 'id').isNotEmpty)
          _rowText(row, 'id'): _displayPublicUserName(row),
    };
  }

  List<String> _idsFromRows(List<Map<String, dynamic>> rows, String key) {
    return rows
        .map((row) => _rowText(row, key))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  _CustomerNameResolution _displayPublicUserName(Map<String, dynamic> row) {
    final fullName = _rowText(row, 'full_name');
    if (fullName.isNotEmpty) {
      return _CustomerNameResolution(fullName, 'public.user.full_name');
    }

    final name = _rowText(row, 'name');
    if (name.isNotEmpty) {
      return _CustomerNameResolution(name, 'public.user.name');
    }

    final displayName = _rowText(row, 'display_name');
    if (displayName.isNotEmpty) {
      return _CustomerNameResolution(displayName, 'public.user.display_name');
    }

    final email = _rowText(row, 'email');
    final prefix = email.split('@').first.trim();
    if (prefix.isNotEmpty) {
      return _CustomerNameResolution(prefix, 'public.user.email_prefix');
    }

    return const _CustomerNameResolution.fallback();
  }

  String _rowText(Map<String, dynamic> row, String key) {
    final value = row[key]?.toString().trim();
    return value == null || value.isEmpty ? '' : value;
  }

  Future<void> _save({
    required String section,
    required Future<void> Function() action,
  }) async {
    debugPrint('[StoreAdmin] save:start section=$section');
    try {
      await action();
      debugPrint('[StoreAdmin] save:success section=$section');
    } catch (error) {
      debugPrint('[StoreAdmin] error=$error');
      rethrow;
    }
  }

  Future<void> _delete({
    required String type,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
      debugPrint('[StoreAdmin] delete:success type=$type');
    } catch (error) {
      debugPrint('[StoreAdmin] error=$error');
      rethrow;
    }
  }

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

class _CustomerNameResolution {
  const _CustomerNameResolution(this.name, this.source);

  const _CustomerNameResolution.fallback() : name = '-', source = 'fallback';

  final String name;
  final String source;
}
