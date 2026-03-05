import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'store_models.dart';

/// Repository that wraps Supabase calls for the medical store.
///
/// Handles products, cart items, and orders with caching.
class StoreRepository {
  StoreRepository._();
  static final StoreRepository instance = StoreRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Get current authenticated user ID, or null if not authenticated.
  String? get _userId => _client.auth.currentUser?.id;

  // ── Products ─────────────────────────────────────────────────────────────

  List<Product>? _productsCache;
  DateTime? _productsCacheTime;
  static const _productsTtl = Duration(minutes: 5);

  bool get _productsCacheValid =>
      _productsCache != null &&
      _productsCacheTime != null &&
      DateTime.now().difference(_productsCacheTime!) < _productsTtl;

  /// Fetch all products from Supabase.
  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _productsCacheValid) {
      return _productsCache!;
    }

    try {
      final data = await _client
          .from('products')
          .select()
          .order('name')
          .limit(100);

      final products = (data as List<dynamic>)
          .map((item) => Product.fromMap(item as Map<String, dynamic>))
          .toList();

      _productsCache = products;
      _productsCacheTime = DateTime.now();

      return products;
    } catch (e, st) {
      debugPrint('[StoreRepository] fetchProducts() error: $e\n$st');
      // Return empty list on error
      return [];
    }
  }

  /// Invalidate products cache.
  void invalidateProductsCache() {
    _productsCache = null;
    _productsCacheTime = null;
  }

  // ── Cart Items ───────────────────────────────────────────────────────────

  /// Fetch cart items for the current user with product details.
  Future<List<CartItemModel>> fetchCart() async {
    final userId = _userId;
    if (userId == null) {
      debugPrint('[StoreRepository] No authenticated user for fetchCart()');
      return [];
    }

    try {
      final data = await _client
          .from('cart_items')
          .select('''
            id,
            student_id,
            product_id,
            quantity,
            created_at,
            products (
              id,
              name,
              description,
              price,
              original_price,
              image_url,
              category,
              in_stock,
              rating,
              review_count,
              prescription_required
            )
          ''')
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('[StoreRepository] fetchCart() error: $e\n$st');
      return [];
    }
  }

  /// Add a product to the cart (or increment quantity if exists).
  Future<bool> addToCart(String productId, {int quantity = 1}) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint('[StoreRepository] No authenticated user for addToCart()');
      return false;
    }

    try {
      // Check if item already exists in cart
      final existing = await _client
          .from('cart_items')
          .select()
          .eq('student_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        // Update quantity (increment)
        final currentQty = existing['quantity'] as int? ?? 1;
        await _client
            .from('cart_items')
            .update({'quantity': currentQty + quantity})
            .eq('id', existing['id']);
      } else {
        // Insert new cart item
        await _client.from('cart_items').insert({
          'student_id': userId,
          'product_id': productId,
          'quantity': quantity,
        });
      }

      return true;
    } catch (e, st) {
      debugPrint('[StoreRepository] addToCart() error: $e\n$st');
      return false;
    }
  }

  /// Update the quantity of a cart item.
  Future<bool> updateCartQuantity(String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        await _client.from('cart_items').delete().eq('id', cartItemId);
      } else {
        await _client
            .from('cart_items')
            .update({'quantity': quantity})
            .eq('id', cartItemId);
      }
      return true;
    } catch (e, st) {
      debugPrint('[StoreRepository] updateCartQuantity() error: $e\n$st');
      return false;
    }
  }

  /// Remove a cart item.
  Future<bool> removeFromCart(String cartItemId) async {
    try {
      await _client.from('cart_items').delete().eq('id', cartItemId);
      return true;
    } catch (e, st) {
      debugPrint('[StoreRepository] removeFromCart() error: $e\n$st');
      return false;
    }
  }

  /// Clear all cart items for the current user.
  Future<bool> clearCart() async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }

    try {
      await _client.from('cart_items').delete().eq('student_id', userId);
      return true;
    } catch (e, st) {
      debugPrint('[StoreRepository] clearCart() error: $e\n$st');
      return false;
    }
  }

  // ── Orders ───────────────────────────────────────────────────────────────

  /// Create a new order and clear the cart.
  Future<String?> createOrder(
    List<CartItemModel> cartItems,
    double total,
  ) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint('[StoreRepository] No authenticated user for createOrder()');
      return null;
    }

    try {
      // Prepare order items as JSON
      final itemsJson = cartItems.map((item) {
        return {
          'product_id': item.productId,
          'product_name': item.product?.name ?? 'Unknown',
          'price': item.product?.price ?? 0,
          'quantity': item.quantity,
        };
      }).toList();

      // Insert order
      final orderData = await _client
          .from('orders')
          .insert({
            'student_id': userId,
            'items': itemsJson,
            'total_amount': total,
            'status': 'pending',
          })
          .select()
          .single();

      // Clear the cart after successful order
      await clearCart();

      final orderId = orderData['id'] as String;
      debugPrint('[StoreRepository] Order created: $orderId');
      return orderId;
    } catch (e, st) {
      debugPrint('[StoreRepository] createOrder() error: $e\n$st');
      return null;
    }
  }

  /// Fetch order history for the current user.
  Future<List<OrderModel>> fetchOrders() async {
    final userId = _userId;
    if (userId == null) {
      debugPrint('[StoreRepository] No authenticated user for fetchOrders()');
      return [];
    }

    try {
      final data = await _client
          .from('orders')
          .select()
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List<dynamic>)
          .map((item) => OrderModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('[StoreRepository] fetchOrders() error: $e\n$st');
      return [];
    }
  }
}
