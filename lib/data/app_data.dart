import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/product.dart';

class AppData {
  static final List<Category> categories = [];
  static final List<Product> products = [];
  static String? shopId;
  static String? shopName;

  static SupabaseClient get _client => Supabase.instance.client;

  // ---------- Derived views (single source of truth for status) ----------

  /// Products that are active in the DB and NOT past their expiry date.
  static List<Product> get activeProducts => products
      .where((p) => p.status == ProductStatus.active && !p.isExpired)
      .toList();

  /// Products that are still marked active in the DB but past expiry.
  static List<Product> get expiredProducts =>
      products.where((p) => p.isExpired).toList();

  static List<Product> get soldProducts =>
      products.where((p) => p.status == ProductStatus.sold).toList();

  static List<Product> get removedProducts =>
      products.where((p) => p.status == ProductStatus.removed).toList();

  // ---------- Load ----------

  static Future<bool> load() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }

    final member = await _client
        .from('shop_members')
        .select('shop_id, shops(name)')
        .maybeSingle();

    if (member == null) {
      shopId = null;
      shopName = null;
      categories.clear();
      products.clear();
      return false;
    }

    shopId = member['shop_id'] as String;
    shopName = (member['shops'] as Map<String, dynamic>?)?['name'] as String?;

    await _loadShopData();
    return true;
  }

  static Future<void> _loadShopData() async {
    final categoryRows = await _client
        .from('categories')
        .select()
        .eq('shop_id', shopId!)
        .order('name');

    categories
      ..clear()
      ..addAll(
        (categoryRows as List).map((row) {
          final data = row as Map<String, dynamic>;
          return Category(
            id: data['id'] as String,
            name: data['name'] as String,
            removalDays: data['removal_days'] as int,
          );
        }),
      );

    final byId = {for (final category in categories) category.id: category};

    final productRows = await _client
        .from('products')
        .select()
        .eq('shop_id', shopId!)
        .order('current_removal_date');

    products
      ..clear()
      ..addAll(
        (productRows as List).map((row) {
          final data = row as Map<String, dynamic>;
          return Product(
            id: data['id'] as String,
            name: data['name'] as String,
            category:
                byId[data['category_id']] ??
                Category(name: 'Uncategorised', removalDays: 0),
            size: data['size'] as String,
            expiryDate: DateTime.parse(data['expiry_date'] as String),
            originalRemovalDate: DateTime.parse(
              data['original_removal_date'] as String,
            ),
            currentRemovalDate: DateTime.parse(
              data['current_removal_date'] as String,
            ),
            extensionDays: data['extension_days'] as int,
            status: Product.parseStatus(data['status'] as String?),
          );
        }),
      );
  }

  // ---------- Shop setup ----------

  static Future<void> createShop({
    required String name,
    required String code,
    required String displayName,
  }) async {
    await _client.rpc(
      'create_shop',
      params: {
        'p_shop_name': name,
        'p_join_code': code,
        'p_display_name': displayName,
      },
    );
    await load();
  }

  static Future<void> joinShop({
    required String code,
    required String displayName,
  }) async {
    await _client.rpc(
      'join_shop',
      params: {'p_join_code': code, 'p_display_name': displayName},
    );
    await load();
  }

  // ---------- Products ----------

  static Future<void> addProduct(Product product) async {
    await _client.from('products').insert({
      'shop_id': shopId,
      'category_id': product.category.id,
      'name': product.name,
      'size': product.size,
      'expiry_date': _date(product.expiryDate),
      'original_removal_date': _date(product.originalRemovalDate),
      'current_removal_date': _date(product.currentRemovalDate),
    });
    await _loadShopData();
  }

  static Future<void> updateProduct(
    Product product,
    ProductStatus status,
  ) async {
    await _client
        .from('products')
        .update({'status': status.name})
        .eq('id', product.id!);
    await _client.from('product_events').insert({
      'shop_id': shopId,
      'product_id': product.id,
      'event_type': status == ProductStatus.sold ? 'sold' : 'removed',
    });
    await _loadShopData();
  }

  static Future<void> extendProduct(Product product, int days) async {
    final date = product.currentRemovalDate.add(Duration(days: days));
    await _client
        .from('products')
        .update({
          'current_removal_date': _date(date),
          'extension_days': product.extensionDays + days,
        })
        .eq('id', product.id!);
    await _client.from('product_events').insert({
      'shop_id': shopId,
      'product_id': product.id,
      'event_type': 'extended',
      'details': {'days': days},
    });
    await _loadShopData();
  }

  // ---------- Categories ----------

  static Future<void> saveCategory(Category category) async {
    if (category.id == null) {
      await _client.from('categories').insert({
        'shop_id': shopId,
        'name': category.name,
        'removal_days': category.removalDays,
      });
    } else {
      await _client
          .from('categories')
          .update({'name': category.name, 'removal_days': category.removalDays})
          .eq('id', category.id!)
          .eq('shop_id', shopId!);
    }
    await _loadShopData();
  }

  static Future<void> deleteCategory(Category category) async {
    await _client
        .from('categories')
        .delete()
        .eq('id', category.id!)
        .eq('shop_id', shopId!);
    await _loadShopData();
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
