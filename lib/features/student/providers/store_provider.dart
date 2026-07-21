import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_models.dart';
import '../data/store_repository.dart';

// ── State ───────────────────────────────────────────────────────────────────

enum StoreStatus { idle, loading, error }

class StoreState {
  // Products
  final List<Product> products;
  final StoreStatus productsStatus;
  final String? productsError;

  // Cart
  final List<CartItemModel> cartItems;
  final StoreStatus cartStatus;
  final String? cartError;
  final bool isPlacingOrder;
  final String? lastOrderId;
  final String? orderError;

  // Orders
  final List<OrderModel> orders;
  final StoreStatus ordersStatus;
  final String? ordersError;

  // UI State
  final String? successMessage;

  const StoreState({
    this.products = const [],
    this.productsStatus = StoreStatus.idle,
    this.productsError,
    this.cartItems = const [],
    this.cartStatus = StoreStatus.idle,
    this.cartError,
    this.isPlacingOrder = false,
    this.lastOrderId,
    this.orderError,
    this.orders = const [],
    this.ordersStatus = StoreStatus.idle,
    this.ordersError,
    this.successMessage,
  });

  // Computed properties
  bool get isLoadingProducts => productsStatus == StoreStatus.loading;
  bool get isLoadingCart => cartStatus == StoreStatus.loading;

  double get cartTotal => cartItems.fold(
    0,
    (sum, item) => sum + ((item.product?.price ?? 0) * item.quantity),
  );

  int get cartItemCount =>
      cartItems.fold(0, (sum, item) => sum + item.quantity);

  StoreState copyWith({
    List<Product>? products,
    StoreStatus? productsStatus,
    String? productsError,
    List<CartItemModel>? cartItems,
    StoreStatus? cartStatus,
    String? cartError,
    bool? isPlacingOrder,
    String? lastOrderId,
    String? orderError,
    List<OrderModel>? orders,
    StoreStatus? ordersStatus,
    String? ordersError,
    String? successMessage,
  }) => StoreState(
    products: products ?? this.products,
    productsStatus: productsStatus ?? this.productsStatus,
    productsError: productsError,
    cartItems: cartItems ?? this.cartItems,
    cartStatus: cartStatus ?? this.cartStatus,
    cartError: cartError,
    isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
    lastOrderId: lastOrderId,
    orderError: orderError,
    orders: orders ?? this.orders,
    ordersStatus: ordersStatus ?? this.ordersStatus,
    ordersError: ordersError,
    successMessage: successMessage,
  );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class StoreNotifier extends StateNotifier<StoreState> {
  StoreNotifier() : super(const StoreState()) {
    loadProducts();
    loadCart();
    loadOrders();
  }

  final _repo = StoreRepository.instance;

  // ── Products ────────────────────────────────────────────────────────────

  /// Load all products from the database.
  Future<void> loadProducts({bool forceRefresh = false}) async {
    state = state.copyWith(productsStatus: StoreStatus.loading);
    try {
      final products = await _repo.fetchProducts(forceRefresh: forceRefresh);
      state = state.copyWith(
        products: products,
        productsStatus: StoreStatus.idle,
      );
    } catch (e, st) {
      debugPrint('[StoreNotifier] loadProducts() error: $e\n$st');
      state = state.copyWith(
        productsStatus: StoreStatus.error,
        productsError: e.toString(),
      );
    }
  }

  /// Refresh products (force network call).
  Future<void> refreshProducts() => loadProducts(forceRefresh: true);

  // ── Cart ─────────────────────────────────────────────────────────────────

  /// Load cart items for the current user.
  Future<void> loadCart() async {
    state = state.copyWith(cartStatus: StoreStatus.loading);
    try {
      final cartItems = await _repo.fetchCart();
      state = state.copyWith(
        cartItems: cartItems,
        cartStatus: StoreStatus.idle,
      );
    } catch (e, st) {
      debugPrint('[StoreNotifier] loadCart() error: $e\n$st');
      state = state.copyWith(
        cartStatus: StoreStatus.error,
        cartError: e.toString(),
      );
    }
  }

  /// Add a product to the cart.
  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    try {
      final success = await _repo.addToCart(product.id, quantity: quantity);
      if (success) {
        // Reload cart to get updated data
        await loadCart();
        state = state.copyWith(successMessage: '${product.name} added to cart');
      }
      return success;
    } catch (e, st) {
      debugPrint('[StoreNotifier] addToCart() error: $e\n$st');
      return false;
    }
  }

  /// Update quantity of a cart item.
  Future<void> updateCartQuantity(CartItemModel cartItem, int quantity) async {
    try {
      await _repo.updateCartQuantity(cartItem.id, quantity);
      await loadCart();
    } catch (e, st) {
      debugPrint('[StoreNotifier] updateCartQuantity() error: $e\n$st');
    }
  }

  /// Remove a cart item.
  Future<void> removeFromCart(CartItemModel cartItem) async {
    try {
      await _repo.removeFromCart(cartItem.id);
      await loadCart();
    } catch (e, st) {
      debugPrint('[StoreNotifier] removeFromCart() error: $e\n$st');
    }
  }

  /// Clear all cart items.
  Future<void> clearCart() async {
    try {
      await _repo.clearCart();
      await loadCart();
    } catch (e, st) {
      debugPrint('[StoreNotifier] clearCart() error: $e\n$st');
    }
  }

  /// Place an order with current cart items.
  Future<String?> placeOrder() async {
    if (state.cartItems.isEmpty) {
      state = state.copyWith(orderError: 'Cart is empty');
      return null;
    }

    state = state.copyWith(isPlacingOrder: true, orderError: null);
    try {
      final orderId = await _repo.createOrder(state.cartItems, state.cartTotal);

      if (orderId != null) {
        state = state.copyWith(
          isPlacingOrder: false,
          lastOrderId: orderId,
          successMessage: 'Order placed successfully! Order ID: $orderId',
        );
        // Reload cart and orders
        await loadCart();
        await loadOrders();
        return orderId;
      } else {
        state = state.copyWith(
          isPlacingOrder: false,
          orderError: 'Failed to create order',
        );
        return null;
      }
    } catch (e, st) {
      debugPrint('[StoreNotifier] placeOrder() error: $e\n$st');
      state = state.copyWith(isPlacingOrder: false, orderError: e.toString());
      return null;
    }
  }

  // ── Orders ───────────────────────────────────────────────────────────────

  /// Load order history.
  Future<void> loadOrders() async {
    state = state.copyWith(ordersStatus: StoreStatus.loading);
    try {
      final orders = await _repo.fetchOrders();
      state = state.copyWith(orders: orders, ordersStatus: StoreStatus.idle);
    } catch (e, st) {
      debugPrint('[StoreNotifier] loadOrders() error: $e\n$st');
      state = state.copyWith(
        ordersStatus: StoreStatus.error,
        ordersError: e.toString(),
      );
    }
  }

  /// Refresh orders.
  Future<void> refreshOrders() async {
    state = state.copyWith(ordersStatus: StoreStatus.loading);
    try {
      final orders = await _repo.fetchOrders();
      state = state.copyWith(orders: orders, ordersStatus: StoreStatus.idle);
    } catch (e, st) {
      debugPrint('[StoreNotifier] refreshOrders() error: $e\n$st');
      state = state.copyWith(
        ordersStatus: StoreStatus.error,
        ordersError: e.toString(),
      );
    }
  }

  // ── UI Helpers ───────────────────────────────────────────────────────────

  /// Clear success message after it's been shown.
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear order error.
  void clearOrderError() {
    state = state.copyWith(orderError: null);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final storeProvider =
    StateNotifierProvider.autoDispose<StoreNotifier, StoreState>(
      (ref) => StoreNotifier(),
    );
