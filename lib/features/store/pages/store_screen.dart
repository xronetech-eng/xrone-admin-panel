import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/store_model.dart';
import '../repository/store_repository.dart';
import '../widgets/store_image_picker.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _repository = StoreRepository();

  final _categoryName = TextEditingController();
  final _categoryIcon = TextEditingController();
  final _categorySort = TextEditingController(text: '0');

  final _productName = TextEditingController();
  final _productShortDescription = TextEditingController();
  final _productDescription = TextEditingController();
  final _productPrice = TextEditingController();
  final _productCurrency = TextEditingController(text: 'INR');
  final _productGst = TextEditingController();
  final _productStock = TextEditingController();
  final _productSort = TextEditingController(text: '0');
  final _productSearch = TextEditingController();
  final _orderSearch = TextEditingController();

  StoreAdminData? _data;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  String? _editingCategoryId;
  bool _categoryActive = true;

  String? _editingProductId;
  String? _productCategoryId;
  String? _imageProductId;
  String? _filterCategoryId;
  String _stockStatus = 'in_stock';
  bool _productFeatured = false;
  bool _productActive = true;
  bool _showAllProducts = false;
  bool _showAllOrders = false;
  String _orderStatusFilter = 'all';
  String _orderPaymentFilter = 'all';

  final _orderStatusDrafts = <String, String>{};

  @override
  void initState() {
    super.initState();
    debugPrint('[StoreAdmin] review:start');
    _productSearch.addListener(() => setState(() {}));
    _orderSearch.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _categoryName.dispose();
    _categoryIcon.dispose();
    _categorySort.dispose();
    _productName.dispose();
    _productShortDescription.dispose();
    _productDescription.dispose();
    _productPrice.dispose();
    _productCurrency.dispose();
    _productGst.dispose();
    _productStock.dispose();
    _productSort.dispose();
    _productSearch.dispose();
    _orderSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Store', style: AppTextStyles.headingLarge),
                SizedBox(height: 8.h),
                Text(
                  'Manage store categories, products, product images, orders and wishlist analytics.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            );
            final refresh = FilledButton.icon(
              onPressed: _loading || _busy ? null : () => _load(),
              icon: Icon(Icons.refresh_rounded, size: 18.r),
              label: const Text('Refresh'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  SizedBox(height: AppSpacing.md),
                  refresh,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: title),
                refresh,
              ],
            );
          },
        ),
        SizedBox(height: AppSpacing.xl),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: _panelDecoration(),
            child: data == null && _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_loading) ...[
                          const LinearProgressIndicator(),
                          SizedBox(height: AppSpacing.lg),
                        ],
                        if (data != null) ...[
                          if (_showAllProducts)
                            _allProducts(data)
                          else if (_showAllOrders)
                            _allOrders(data)
                          else ...[
                            _dashboard(data),
                            _categories(data),
                            _products(data),
                            _images(data),
                            _orders(data),
                            _wishlistAnalytics(data),
                          ],
                        ] else if (!_loading)
                          _Empty(_error ?? 'Store data is unavailable.'),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _dashboard(StoreAdminData data) {
    final summary = data.summary;
    return _Section(
      title: 'Dashboard Summary',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          _Metric('Total Categories', summary.totalCategories.toString()),
          _Metric('Total Products', summary.totalProducts.toString()),
          _Metric('Total Orders', summary.totalOrders.toString()),
          _Metric(
            'Total Wishlist Items',
            summary.totalWishlistItems.toString(),
          ),
          _Metric('Total Cart Items', summary.totalCartItems.toString()),
        ],
      ),
    );
  }

  Widget _categories(StoreAdminData data) {
    return _Section(
      title: 'Category Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Field(_categoryName, 'Name', 260.w),
              _Toggle(
                label: 'Active',
                value: _categoryActive,
                onChanged: (value) => setState(() => _categoryActive = value),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _saveCategory,
                icon: Icon(Icons.save_outlined, size: 18.r),
                label: Text(
                  _editingCategoryId == null ? 'Add Category' : 'Save Category',
                ),
              ),
              if (_editingCategoryId != null)
                TextButton(
                  onPressed: _busy ? null : _clearCategoryForm,
                  child: const Text('Cancel'),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          if (data.categories.isEmpty)
            const _Empty('No categories found.')
          else
            _Table(
              width: 650.w,
              columns: const ['Name', 'Active', 'Actions'],
              rows: [
                for (final category in data.categories)
                  [
                    _Cell(category.name),
                    _SwitchCell(
                      label: category.isActive ? 'Active' : 'Inactive',
                      value: category.isActive,
                      onChanged: _busy
                          ? null
                          : (value) => _toggleCategoryActive(category, value),
                    ),
                    _Actions(
                      onEdit: () => _editCategory(category),
                      onDelete: () => _confirm(
                        'Delete Category',
                        'Delete ${category.name}?',
                        () => _deleteCategory(category.id),
                      ),
                    ),
                  ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _products(StoreAdminData data) {
    final products = _latestProducts(data);
    return _Section(
      title: 'Product Management',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final categoryWidth = _fitWidth(maxWidth, 260.w);
          final nameWidth = _fitWidth(maxWidth, 260.w);
          final shortDescriptionWidth = _fitWidth(maxWidth, 320.w);
          final priceWidth = _fitWidth(maxWidth, 140.w, minWidth: 120);
          final currencyWidth = _fitWidth(maxWidth, 130.w, minWidth: 110);
          final gstWidth = _fitWidth(maxWidth, 140.w, minWidth: 120);
          final stockWidth = _fitWidth(maxWidth, 170.w, minWidth: 130);
          final sortWidth = _fitWidth(maxWidth, 140.w, minWidth: 120);
          final descriptionWidth = _fitWidth(maxWidth, 520.w);
          final cardWidth = _fitWidth(maxWidth, 320.w, minWidth: 260);
          final buttonWidth = _buttonWidth(maxWidth, 170.w);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _CategorySelect(
                    value: _productCategoryId,
                    categories: data.categories,
                    label: 'Category',
                    width: categoryWidth,
                    onChanged: (value) =>
                        setState(() => _productCategoryId = value),
                  ),
                  _Field(_productName, 'Name', nameWidth),
                  _Field(
                    _productShortDescription,
                    'Short Description',
                    shortDescriptionWidth,
                  ),
                  _Field(
                    _productPrice,
                    'Price',
                    priceWidth,
                    keyboardType: TextInputType.number,
                  ),
                  _Field(_productCurrency, 'Currency', currencyWidth),
                  _Field(
                    _productGst,
                    'GST (%)',
                    gstWidth,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _Field(
                    _productStock,
                    'Stock Quantity',
                    stockWidth,
                    keyboardType: TextInputType.number,
                  ),
                  _Field(
                    _productSort,
                    'Sort Order',
                    sortWidth,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(
                    width: descriptionWidth,
                    child: TextField(
                      controller: _productDescription,
                      minLines: 1,
                      maxLines: 3,
                      decoration: _inputDecoration('Description'),
                    ),
                  ),
                  _Toggle(
                    label: 'Featured',
                    value: _productFeatured,
                    maxWidth: maxWidth,
                    onChanged: (value) =>
                        setState(() => _productFeatured = value),
                  ),
                  _Toggle(
                    label: 'Active',
                    value: _productActive,
                    maxWidth: maxWidth,
                    onChanged: (value) =>
                        setState(() => _productActive = value),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _saveProduct,
                      icon: Icon(Icons.save_outlined, size: 18.r),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _editingProductId == null
                              ? 'Add Product'
                              : 'Save Product',
                        ),
                      ),
                    ),
                  ),
                  if (_editingProductId != null)
                    SizedBox(
                      width: _buttonWidth(maxWidth, 100.w),
                      child: TextButton(
                        onPressed: _busy ? null : _clearProductForm,
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Cancel'),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: data.products.isEmpty
                      ? null
                      : () => setState(() => _showAllProducts = true),
                  icon: Icon(Icons.view_list_outlined, size: 18.r),
                  label: const Text('View All'),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              if (products.isEmpty)
                const _Empty('No products found.')
              else
                _productGrid(data, products, cardWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _allProducts(StoreAdminData data) {
    final products = _filteredProducts(data);
    return _Section(
      title: 'All Products',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final searchWidth = _fitWidth(maxWidth, 340.w);
          final categoryWidth = _fitWidth(maxWidth, 260.w);
          final cardWidth = _fitWidth(maxWidth, 320.w, minWidth: 260);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showAllProducts = false),
                    icon: Icon(Icons.arrow_back_rounded, size: 18.r),
                    label: const Text('Back'),
                  ),
                  _Field(
                    _productSearch,
                    'Search Product',
                    searchWidth,
                    prefixIcon: Icons.search_rounded,
                  ),
                  _CategorySelect(
                    value: _filterCategoryId ?? 'all',
                    categories: data.categories,
                    label: 'Category Filter',
                    width: categoryWidth,
                    includeAll: true,
                    onChanged: (value) => setState(() {
                      _filterCategoryId = value == 'all' ? null : value;
                    }),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              if (products.isEmpty)
                const _Empty('No products found.')
              else
                _productGrid(data, products, cardWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _images(StoreAdminData data) {
    final product = _productById(data, _imageProductId);
    final images = product == null
        ? <StoreProductImage>[]
        : data.imagesFor(product.id);
    return _Section(
      title: 'Product Image Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final productWidth = _fitWidth(maxWidth, 320.w);
              final buttonWidth = _buttonWidth(maxWidth, 160.w);
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: productWidth,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: product?.id,
                      decoration: _inputDecoration('Product'),
                      items: [
                        for (final item in data.products)
                          DropdownMenuItem(
                            value: item.id,
                            child: _DropdownText(item.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _imageProductId = value),
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: FilledButton.icon(
                      onPressed: _busy || product == null
                          ? null
                          : () => _uploadImage(product.id, images.length),
                      icon: Icon(Icons.upload_rounded, size: 18.r),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Upload Image'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: AppSpacing.lg),
          if (data.products.isEmpty)
            const _Empty('Add a product before uploading images.')
          else if (product == null)
            const _Empty('Select a product to manage images.')
          else if (images.isEmpty)
            const _Empty('No images uploaded for this product.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final imageWidth = _fitWidth(
                  constraints.maxWidth,
                  260.w,
                  minWidth: 220,
                );
                return Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    for (final image in images)
                      _ImageCard(
                        image: image,
                        width: imageWidth,
                        onPreview: () => _previewImage(image),
                        onPrimary: image.isPrimary
                            ? null
                            : () => _setPrimary(image),
                        onDelete: () => _confirm(
                          'Delete Image',
                          'Delete this product image?',
                          () => _deleteImage(image),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _orders(StoreAdminData data) {
    final orders = _latestOrders(data);
    return _Section(
      title: 'Order Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: data.orders.isEmpty
                  ? null
                  : () => setState(() => _showAllOrders = true),
              icon: Icon(Icons.receipt_long_outlined, size: 18.r),
              label: const Text('View All'),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          if (orders.isEmpty)
            const _Empty('No orders found.')
          else
            _orderList(data, orders),
        ],
      ),
    );
  }

  Widget _allOrders(StoreAdminData data) {
    final orders = _filteredOrders(data);
    return _Section(
      title: 'All Orders',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final searchWidth = _fitWidth(maxWidth, 340.w);
          final filterWidth = _fitWidth(maxWidth, 220.w, minWidth: 170);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showAllOrders = false),
                    icon: Icon(Icons.arrow_back_rounded, size: 18.r),
                    label: const Text('Back'),
                  ),
                  _Field(
                    _orderSearch,
                    'Search Orders',
                    searchWidth,
                    prefixIcon: Icons.search_rounded,
                  ),
                  _OrderFilterSelect(
                    value: _orderStatusFilter,
                    label: 'Status',
                    width: filterWidth,
                    options: const [
                      _FilterOption('all', 'All Statuses'),
                      _FilterOption('pending', 'Pending'),
                      _FilterOption('processing', 'Processing'),
                      _FilterOption('shipped', 'Shipped'),
                      _FilterOption('delivered', 'Delivered'),
                      _FilterOption('cancelled', 'Cancelled'),
                    ],
                    onChanged: (value) =>
                        setState(() => _orderStatusFilter = value ?? 'all'),
                  ),
                  _OrderFilterSelect(
                    value: _orderPaymentFilter,
                    label: 'Payment',
                    width: filterWidth,
                    options: const [
                      _FilterOption('all', 'All Payments'),
                      _FilterOption('pending', 'Pending'),
                      _FilterOption('paid', 'Paid'),
                      _FilterOption('failed', 'Failed'),
                      _FilterOption('refunded', 'Refunded'),
                    ],
                    onChanged: (value) =>
                        setState(() => _orderPaymentFilter = value ?? 'all'),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              if (orders.isEmpty)
                const _Empty('No orders found.')
              else
                _orderList(data, orders),
            ],
          );
        },
      ),
    );
  }

  Widget _wishlistAnalytics(StoreAdminData data) {
    final rows = data.wishlistAnalyticsRows;
    return _Section(
      title: 'Wishlist Analytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _Metric(
                'Total Wishlist Items',
                data.wishlistItems.length.toString(),
              ),
              _Metric('Customers', _wishlistCustomerCount(rows).toString()),
              _Metric('Products', data.wishlistCounts.length.toString()),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          if (rows.isEmpty)
            const _Empty('No wishlist activity found.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      for (final row in rows) _WishlistAnalyticsCard(row: row),
                    ],
                  );
                }

                return _Table(
                  width: 980.w,
                  columns: const [
                    'Name',
                    'Mobile',
                    'Product',
                    'Wishlist Date',
                    'Count',
                  ],
                  rows: [
                    for (final row in rows)
                      [
                        _Cell(row.customerName),
                        _Cell(row.customerMobile),
                        _Cell(row.productName),
                        _Cell(_date(row.wishlistDate)),
                        _Cell(row.count.toString()),
                      ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  int _wishlistCustomerCount(List<WishlistAnalyticsRow> rows) {
    return rows
        .map((row) => _firstVisible([row.customerMobile, row.customerName]))
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
  }

  Widget _productGrid(
    StoreAdminData data,
    List<StoreProduct> products,
    double cardWidth,
  ) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: [
        for (final product in products)
          _ProductCard(
            product: product,
            category: data.categoryName(product.categoryId),
            image: data.primaryImageFor(product.id),
            width: cardWidth,
            onEdit: () => _editProduct(product),
            onActiveChanged: _busy
                ? null
                : (value) => _toggleProductActive(product, value),
            onFeaturedChanged: _busy
                ? null
                : (value) => _toggleProductFeatured(product, value),
            onDelete: () => _confirm(
              'Delete Product',
              'Delete ${product.name}?',
              () => _deleteProduct(product.id),
            ),
          ),
      ],
    );
  }

  Widget _orderList(StoreAdminData data, List<StoreOrder> orders) {
    return Column(
      children: [
        for (final order in orders)
          _OrderCard(
            order: order,
            address: data.addressForOrder(order),
            items: data.itemsForOrder(order.id),
            productName: data.productName,
            draftStatus: _orderStatusDrafts[order.id] ?? order.status,
            onStatusChanged: (status) {
              setState(() => _orderStatusDrafts[order.id] = status);
            },
            onSave: () => _updateOrderStatus(
              order.id,
              _orderStatusDrafts[order.id] ?? order.status,
            ),
          ),
      ],
    );
  }

  List<StoreProduct> _filteredProducts(StoreAdminData data) {
    final search = _productSearch.text.trim().toLowerCase();
    return data.products.where((product) {
      final matchesSearch =
          search.isEmpty ||
          product.name.toLowerCase().contains(search) ||
          product.shortDescription.toLowerCase().contains(search) ||
          product.description.toLowerCase().contains(search);
      final matchesCategory =
          _filterCategoryId == null || product.categoryId == _filterCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<StoreProduct> _latestProducts(StoreAdminData data) {
    return data.products.reversed.take(4).toList();
  }

  List<StoreOrder> _filteredOrders(StoreAdminData data) {
    final search = _orderSearch.text.trim().toLowerCase();
    return data.orders.where((order) {
      final address = data.addressForOrder(order);
      final items = data.itemsForOrder(order.id);
      final matchesSearch =
          search.isEmpty ||
          order.orderNumber.toLowerCase().contains(search) ||
          order.customerName.toLowerCase().contains(search) ||
          order.customerMobile.toLowerCase().contains(search) ||
          order.status.toLowerCase().contains(search) ||
          order.paymentStatus.toLowerCase().contains(search) ||
          (address?.recipientName.toLowerCase().contains(search) ?? false) ||
          (address?.phone.toLowerCase().contains(search) ?? false) ||
          items.any(
            (item) =>
                item.productName.toLowerCase().contains(search) ||
                data.productName(item.productId).toLowerCase().contains(search),
          );
      final matchesStatus =
          _orderStatusFilter == 'all' ||
          _normalizedStatus(order.status) == _orderStatusFilter;
      final matchesPayment =
          _orderPaymentFilter == 'all' ||
          order.paymentStatus.toLowerCase().trim() == _orderPaymentFilter;
      return matchesSearch && matchesStatus && matchesPayment;
    }).toList();
  }

  List<StoreOrder> _latestOrders(StoreAdminData data) {
    return data.orders.take(4).toList();
  }

  StoreProduct? _productById(StoreAdminData data, String? id) {
    if (id == null) return data.products.isEmpty ? null : data.products.first;
    for (final product in data.products) {
      if (product.id == id) return product;
    }
    return data.products.isEmpty ? null : data.products.first;
  }

  Future<bool> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.load();
      if (!mounted) return false;
      setState(() {
        _data = data;
        _loading = false;
        _normalizeSelections(data);
      });
      debugPrint('[StoreAdmin] review:complete');
      return true;
    } catch (error) {
      if (!mounted) return false;
      final message = error.toString();
      setState(() {
        _loading = false;
        _error = message;
      });
      _showStoreSnackBar(message, type: _StoreSnackBarType.error);
      return false;
    }
  }

  Future<void> _action(Future<void> Function() run, String success) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await run();
      final refreshed = await _load();
      if (!mounted) return;
      if (!refreshed) return;
      _showStoreSnackBar(success, type: _StoreSnackBarType.success);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() => _error = message);
      _showStoreSnackBar(message, type: _StoreSnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveCategory() async {
    if (_categoryName.text.trim().isEmpty) {
      _showStoreSnackBar(
        'Category name is required.',
        type: _StoreSnackBarType.error,
      );
      return;
    }
    final draft = StoreCategoryDraft(
      name: _categoryName.text.trim(),
      iconKey: _categoryIcon.text.trim(),
      sortOrder: int.tryParse(_categorySort.text.trim()) ?? 0,
      isActive: _categoryActive,
    );
    await _action(
      () => _repository.saveCategory(_editingCategoryId, draft),
      'Category saved.',
    );
    if (mounted) _clearCategoryForm();
  }

  void _editCategory(StoreCategory category) {
    setState(() {
      _editingCategoryId = category.id;
      _categoryName.text = category.name;
      _categoryIcon.text = category.iconKey;
      _categorySort.text = category.sortOrder.toString();
      _categoryActive = category.isActive;
    });
  }

  void _clearCategoryForm() {
    setState(() {
      _editingCategoryId = null;
      _categoryName.clear();
      _categoryIcon.clear();
      _categorySort.text = '0';
      _categoryActive = true;
    });
  }

  Future<void> _deleteCategory(String id) {
    return _action(() => _repository.deleteCategory(id), 'Category deleted.');
  }

  Future<void> _toggleCategoryActive(StoreCategory category, bool value) {
    return _action(
      () => _repository.updateCategoryActive(category.id, value),
      value ? 'Category activated.' : 'Category deactivated.',
    );
  }

  Future<void> _saveProduct() async {
    final categoryId = _productCategoryId;
    if (categoryId == null || categoryId.isEmpty) {
      _showStoreSnackBar(
        'Product category is required.',
        type: _StoreSnackBarType.error,
      );
      return;
    }
    if (_productName.text.trim().isEmpty) {
      _showStoreSnackBar(
        'Product name is required.',
        type: _StoreSnackBarType.error,
      );
      return;
    }
    final gstText = _productGst.text.trim();
    final gstPercentage = gstText.isEmpty ? 0.0 : double.tryParse(gstText);
    if (gstPercentage == null || gstPercentage < 0 || gstPercentage > 100) {
      _showStoreSnackBar(
        'GST must be a percentage between 0 and 100.',
        type: _StoreSnackBarType.error,
      );
      return;
    }
    final draft = StoreProductDraft(
      categoryId: categoryId,
      name: _productName.text.trim(),
      shortDescription: _productShortDescription.text.trim(),
      description: _productDescription.text.trim(),
      price: double.tryParse(_productPrice.text.trim()) ?? 0,
      currency: _productCurrency.text.trim().isEmpty
          ? 'INR'
          : _productCurrency.text.trim(),
      gstPercentage: gstPercentage,
      stockQuantity: int.tryParse(_productStock.text.trim()) ?? 0,
      stockStatus: _stockStatus,
      isFeatured: _productFeatured,
      isActive: _productActive,
      sortOrder: int.tryParse(_productSort.text.trim()) ?? 0,
    );
    await _action(
      () => _repository.saveProduct(_editingProductId, draft),
      'Product saved.',
    );
    if (mounted) _clearProductForm();
  }

  void _editProduct(StoreProduct product) {
    setState(() {
      _editingProductId = product.id;
      _productCategoryId = product.categoryId;
      _productName.text = product.name;
      _productShortDescription.text = product.shortDescription;
      _productDescription.text = product.description;
      _productPrice.text = product.price.toStringAsFixed(2);
      _productCurrency.text = product.currency;
      _productGst.text = _formatPercent(product.gstPercentage);
      _productStock.text = product.stockQuantity.toString();
      _stockStatus = product.stockStatus;
      _productFeatured = product.isFeatured;
      _productActive = product.isActive;
      _productSort.text = product.sortOrder.toString();
      _showAllProducts = false;
    });
  }

  void _clearProductForm() {
    setState(() {
      _editingProductId = null;
      _productCategoryId = _data?.categories.isEmpty ?? true
          ? null
          : _data!.categories.first.id;
      _productName.clear();
      _productShortDescription.clear();
      _productDescription.clear();
      _productPrice.clear();
      _productCurrency.text = 'INR';
      _productGst.clear();
      _productStock.clear();
      _stockStatus = 'in_stock';
      _productFeatured = false;
      _productActive = true;
      _productSort.text = '0';
    });
  }

  Future<void> _deleteProduct(String id) {
    return _action(() => _repository.deleteProduct(id), 'Product deleted.');
  }

  Future<void> _toggleProductActive(StoreProduct product, bool value) {
    return _action(
      () => _repository.updateProductActive(product.id, value),
      value ? 'Product activated.' : 'Product deactivated.',
    );
  }

  Future<void> _toggleProductFeatured(StoreProduct product, bool value) {
    return _action(
      () => _repository.updateProductFeatured(product.id, value),
      value ? 'Product marked as featured.' : 'Product removed from featured.',
    );
  }

  Future<void> _uploadImage(String productId, int imageCount) async {
    final picked = await pickStoreImage();
    if (picked == null) {
      if (!mounted) return;
      _showStoreSnackBar('No image selected.', type: _StoreSnackBarType.info);
      return;
    }
    await _action(
      () => _repository.uploadProductImage(
        productId: productId,
        bytes: picked.bytes,
        fileName: picked.name,
        makePrimary: imageCount == 0,
        sortOrder: imageCount,
      ),
      'Image uploaded.',
    );
  }

  Future<void> _deleteImage(StoreProductImage image) {
    return _action(
      () => _repository.deleteProductImage(image),
      'Image deleted.',
    );
  }

  Future<void> _setPrimary(StoreProductImage image) {
    return _action(
      () => _repository.setPrimaryImage(image),
      'Primary image updated.',
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) {
    return _action(
      () => _repository.updateOrderStatus(orderId, status),
      'Order status updated.',
    );
  }

  Future<void> _confirm(
    String title,
    String message,
    Future<void> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }

  void _previewImage(StoreProductImage image) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Preview'),
        content: SizedBox(
          width: 560.w,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: image.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const _Empty('Image preview unavailable.'),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _normalizeSelections(StoreAdminData data) {
    _productCategoryId = _validProductCategoryId(data, _productCategoryId);
    _filterCategoryId = _validFilterCategoryId(data, _filterCategoryId);
    _imageProductId = _validProductId(data, _imageProductId);
  }

  String? _validProductCategoryId(StoreAdminData data, String? id) {
    if (data.categories.isEmpty) return null;
    if (id != null && data.categories.any((category) => category.id == id)) {
      return id;
    }
    return data.categories.first.id;
  }

  String? _validFilterCategoryId(StoreAdminData data, String? id) {
    if (id == null) return null;
    if (data.categories.any((category) => category.id == id)) return id;
    return null;
  }

  String? _validProductId(StoreAdminData data, String? id) {
    if (data.products.isEmpty) return null;
    if (id != null && data.products.any((product) => product.id == id)) {
      return id;
    }
    return data.products.first.id;
  }

  void _showStoreSnackBar(String message, {required _StoreSnackBarType type}) {
    if (!mounted) return;
    debugPrint('[StoreAdmin] snackbar:bottom');
    final color = switch (type) {
      _StoreSnackBarType.success => const Color(0xFF16A34A),
      _StoreSnackBarType.error => const Color(0xFFDC2626),
      _StoreSnackBarType.info => AppColors.primaryBlue,
    };
    final icon = switch (type) {
      _StoreSnackBarType.success => Icons.check_circle_outline_rounded,
      _StoreSnackBarType.error => Icons.error_outline_rounded,
      _StoreSnackBarType.info => Icons.info_outline_rounded,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          margin: EdgeInsets.all(AppSpacing.lg),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20.r),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

enum _StoreSnackBarType { success, error, info }

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingMedium),
          SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: _cardDecoration(),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220.w,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.headingMedium),
            SizedBox(height: 4.h),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(
    this.controller,
    this.label,
    this.width, {
    this.keyboardType,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final double width;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label, prefixIcon: prefixIcon),
      ),
    );
  }
}

class _CategorySelect extends StatelessWidget {
  const _CategorySelect({
    required this.value,
    required this.categories,
    required this.label,
    required this.onChanged,
    required this.width,
    this.includeAll = false,
  });

  final String? value;
  final List<StoreCategory> categories;
  final String label;
  final ValueChanged<String?> onChanged;
  final double width;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    final hasValidValue =
        value != null &&
        ((includeAll && value == 'all') ||
            categories.any((category) => category.id == value));
    final effectiveValue = hasValidValue ? value : (includeAll ? 'all' : null);
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: effectiveValue,
        decoration: _inputDecoration(label),
        items: [
          if (includeAll)
            const DropdownMenuItem(
              value: 'all',
              child: _DropdownText('All Categories'),
            ),
          for (final category in categories)
            DropdownMenuItem(
              value: category.id,
              child: _DropdownText(category.name),
            ),
        ],
        onChanged: categories.isEmpty && !includeAll ? null : onChanged,
      ),
    );
  }
}

class _OrderFilterSelect extends StatelessWidget {
  const _OrderFilterSelect({
    required this.value,
    required this.label,
    required this.width,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final String label;
  final double width;
  final List<_FilterOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = options.any((option) => option.value == value);
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: hasValue ? value : 'all',
        decoration: _inputDecoration(label),
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option.value,
              child: _DropdownText(option.label),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption(this.value, this.label);

  final String value;
  final String label;
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxWidth,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.category,
    required this.image,
    required this.width,
    required this.onEdit,
    required this.onActiveChanged,
    required this.onFeaturedChanged,
    required this.onDelete,
  });

  final StoreProduct product;
  final String category;
  final StoreProductImage? image;
  final double width;
  final VoidCallback onEdit;
  final ValueChanged<bool>? onActiveChanged;
  final ValueChanged<bool>? onFeaturedChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                child: image == null
                    ? Container(
                        color: AppColors.primaryBlueLight,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.primaryBlue,
                          size: 32.r,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: image!.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.primaryBlueLight,
                          child: Icon(Icons.broken_image_outlined, size: 28.r),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingMedium,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    product.shortDescription.isEmpty
                        ? product.description
                        : product.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    _money(product.price, product.currency),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'GST: ${_formatPercent(product.gstPercentage)}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Stock: ${product.stockQuantity} | ${product.stockStatus}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _Pill(product.isActive ? 'Active' : 'Inactive'),
                      if (product.isFeatured) const _Pill('Featured'),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  _CardSwitch(
                    label: 'Active',
                    value: product.isActive,
                    onChanged: onActiveChanged,
                  ),
                  _CardSwitch(
                    label: 'Featured',
                    value: product.isFeatured,
                    onChanged: onFeaturedChanged,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: width <= 72
                            ? width
                            : 96.w.clamp(72, width).toDouble(),
                        child: TextButton.icon(
                          onPressed: onEdit,
                          icon: Icon(Icons.edit_outlined, size: 18.r),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Edit'),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete Product',
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline, size: 18.r),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSwitch extends StatelessWidget {
  const _CardSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.image,
    required this.width,
    required this.onPreview,
    required this.onPrimary,
    required this.onDelete,
  });

  final StoreProductImage image;
  final double width;
  final VoidCallback onPreview;
  final VoidCallback? onPrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: image.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.primaryBlueLight,
                    child: Icon(Icons.broken_image_outlined, size: 28.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Pill(image.isPrimary ? 'Primary' : 'Gallery'),
                IconButton(
                  tooltip: 'Preview Image',
                  onPressed: onPreview,
                  icon: Icon(Icons.visibility_outlined, size: 18.r),
                ),
                IconButton(
                  tooltip: 'Set Primary',
                  onPressed: onPrimary,
                  icon: Icon(Icons.star_outline_rounded, size: 18.r),
                ),
                IconButton(
                  tooltip: 'Delete Image',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 18.r),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.address,
    required this.items,
    required this.productName,
    required this.draftStatus,
    required this.onStatusChanged,
    required this.onSave,
  });

  final StoreOrder order;
  final StoreAddress? address;
  final List<StoreOrderItem> items;
  final String Function(String?) productName;
  final String draftStatus;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final customerName = _firstVisible([
      order.customerName,
      address?.recipientName ?? '',
    ]);
    final mobile = _firstVisible([order.customerMobile, address?.phone ?? '']);
    final canonicalDeliveryAddress = _firstVisible([
      address?.address ?? '',
      order.deliveryAddress,
      order.fullAddress,
    ]);
    final city = _firstVisible([order.city, address?.city ?? '']);
    final state = _firstVisible([order.state, address?.state ?? '']);
    final pin = _firstVisible([order.postalCode, address?.postalCode ?? '']);

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: _cardDecoration(),
      child: ExpansionTile(
        title: Text(order.orderNumber, style: AppTextStyles.headingMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customerName, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              '${_money(order.totalAmount, order.currency)} | ${order.status} | Payment: ${order.paymentStatus} | ${_date(order.createdAt)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        childrenPadding: EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: _fitWidth(
                  MediaQuery.sizeOf(context).width,
                  180.w,
                  minWidth: 150,
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _normalizedStatus(draftStatus),
                  decoration: _inputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: _DropdownText('Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'processing',
                      child: _DropdownText('Processing'),
                    ),
                    DropdownMenuItem(
                      value: 'shipped',
                      child: _DropdownText('Shipped'),
                    ),
                    DropdownMenuItem(
                      value: 'delivered',
                      child: _DropdownText('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: _DropdownText('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onStatusChanged(value);
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: onSave,
                icon: Icon(Icons.save_outlined, size: 18.r),
                label: const Text('Save'),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _DetailGrid(
            items: [
              _DetailItem('Name', customerName),
              _DetailItem('Mobile', mobile),
              _DetailItem('Full Address', canonicalDeliveryAddress),
              _DetailItem('City', city),
              _DetailItem('State', state),
              _DetailItem('PIN', pin),
              _DetailItem('Order Date', _date(order.createdAt)),
              _DetailItem('Payment Status', order.paymentStatus),
              _DetailItem('Delivery Address', canonicalDeliveryAddress),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          if (items.isEmpty)
            const _Empty('No order items found.')
          else
            _Table(
              width: 780.w,
              columns: const ['Product', 'Quantity', 'Unit Price', 'Total'],
              rows: [
                for (final item in items)
                  [
                    _Cell(
                      item.productName.isEmpty
                          ? productName(item.productId)
                          : item.productName,
                    ),
                    _Cell(item.quantity.toString()),
                    _Cell(_money(item.unitPrice, order.currency)),
                    _Cell(_money(item.totalPrice, order.currency)),
                  ],
              ],
            ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.items});

  final List<_DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _fitWidth(constraints.maxWidth, 250.w, minWidth: 210);
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _DetailTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.item});

  final _DetailItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 76.h),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            item.value.isEmpty ? '-' : item.value,
            maxLines: item.label.contains('Address') ? null : 1,
            overflow: item.label.contains('Address')
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            softWrap: item.label.contains('Address'),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  const _DetailItem(this.label, this.value);

  final String label;
  final String value;
}

class _WishlistAnalyticsCard extends StatelessWidget {
  const _WishlistAnalyticsCard({required this.row});

  final WishlistAnalyticsRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  row.customerName.isEmpty ? '-' : row.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              _Pill('Count ${row.count}'),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _DetailGrid(
            items: [
              _DetailItem('Mobile', row.customerMobile),
              _DetailItem('Product', row.productName),
              _DetailItem('Wishlist Date', _date(row.wishlistDate)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.width,
    required this.columns,
    required this.rows,
  });

  final double width;
  final List<String> columns;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth.isFinite
            ? math.max(width, constraints.maxWidth)
            : width;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                _Row(
                  isHeader: true,
                  children: columns.map((column) => _Cell(column)).toList(),
                ),
                for (final row in rows) _Row(children: row),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DropdownText extends StatelessWidget {
  const _DropdownText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children, this.isHeader = false});

  final List<Widget> children;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 58.h),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10.h),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.surface : AppColors.background,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(children: children),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text.isEmpty ? '-' : text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SwitchCell extends StatelessWidget {
  const _SwitchCell({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, size: 18.r),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 18.r),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, {IconData? prefixIcon}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18.r),
    border: _border(),
    enabledBorder: _border(),
    focusedBorder: _border(color: AppColors.primaryBlue),
    filled: true,
    fillColor: AppColors.background,
  );
}

OutlineInputBorder _border({Color color = AppColors.borderLight}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8.r),
    borderSide: BorderSide(color: color),
  );
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(8.r),
    border: Border.all(color: AppColors.borderLight),
    boxShadow: [
      BoxShadow(
        color: AppColors.textDark.withValues(alpha: 0.05),
        blurRadius: 24.r,
        offset: Offset(0, 12.h),
      ),
    ],
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(8.r),
    border: Border.all(color: AppColors.borderLight),
  );
}

String _money(num amount, String currency) {
  final decimals = amount == amount.roundToDouble() ? 0 : 2;
  return '$currency ${amount.toStringAsFixed(decimals)}';
}

String _formatPercent(num value) {
  final decimals = value == value.roundToDouble() ? 0 : 2;
  return value.toStringAsFixed(decimals);
}

String _firstVisible(List<String> values) {
  for (final value in values) {
    final text = value.trim();
    if (text.isNotEmpty && text != '-') return text;
  }
  return '';
}

String _date(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

String _normalizedStatus(String status) {
  return switch (status.toLowerCase().trim()) {
    'processing' => 'processing',
    'shipped' => 'shipped',
    'delivered' => 'delivered',
    'cancelled' => 'cancelled',
    _ => 'pending',
  };
}

double _fitWidth(
  double availableWidth,
  double preferredWidth, {
  double minWidth = 160,
}) {
  if (!availableWidth.isFinite || availableWidth <= 0) return preferredWidth;
  if (availableWidth <= minWidth) return availableWidth;
  return preferredWidth.clamp(minWidth, availableWidth).toDouble();
}

double _buttonWidth(double availableWidth, double preferredWidth) {
  if (!availableWidth.isFinite || availableWidth <= 0) return preferredWidth;
  if (availableWidth < 120) return availableWidth;
  return preferredWidth.clamp(120, availableWidth).toDouble();
}
