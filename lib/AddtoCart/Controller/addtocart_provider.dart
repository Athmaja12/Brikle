// lib/AddtoCart/Controller/addtocart_provider.dart - Corrected version
// DEBUG: verbose debugPrint logging added throughout to trace the
// address -> payment -> checkout -> place-order flow.

import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Real cart CRUD via API. Coupon/GSTIN/bill-breakdown/cancellation-policy
/// are intentionally static placeholders — no backend for those yet.
class CartController extends GetxController {
  static const String _tag = '[CartController]';

  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxDouble grandTotal = 0.0.obs;
  final RxBool isLoading = true.obs;
  final RxBool cancellationPolicyExpanded = false.obs;

  // ── STATIC placeholders — no API for these yet ──────────────────────
  final RxString couponCode = ''.obs;
  final RxBool gstinAdded = false.obs;
  static const double staticDiscount = 0;
  static const String staticDeliveryChargeLabel = 'FREE';
  static const double staticHandlingCharge = 0;

  // ── Payment Method State ──────────────────────────────
  final RxString selectedPaymentMethod = 'COD'.obs; // 'COD' or 'Online'
  // Tracks whether the user has *actively* tapped a payment option this
  // session — the cart page keeps showing "Add Your Address" (and, once an
  // address exists, the payment picker) until this becomes true; only then
  // does the button flip to "Proceed to Checkout".
  final RxBool hasSelectedPaymentMethod = false.obs;
  final RxBool showPaymentMethodSelector = false.obs;

  // ── END STATIC ───────────────────────────────────────────────────────

  int get itemCount => cartItems.length;
  double get subTotal => grandTotal.value;
  double get total => subTotal - staticDiscount + staticHandlingCharge;

  @override
  void onInit() {
    super.onInit();
    debugPrint('$_tag onInit — controller created, fetching cart');
    fetchCart();
  }

  @override
  void onClose() {
    debugPrint('$_tag onClose — controller disposed');
    super.onClose();
  }

  Future<void> fetchCart({bool showLoader = true}) async {
    debugPrint('$_tag fetchCart(showLoader: $showLoader) called');
    if (showLoader) {
      isLoading.value = true;
    }
    try {
      final response = await ApiService.getCart();
      debugPrint('$_tag fetchCart response: $response');
      final parsed = CartResponse.fromJson(response);
      cartItems.value = parsed.items;
      grandTotal.value = parsed.grandTotalWithGst;
      debugPrint(
        '$_tag fetchCart success — ${cartItems.length} items, '
        'grandTotal=${grandTotal.value}',
      );
    } on ApiException catch (e) {
      debugPrint(
        '$_tag fetchCart failed: ${e.message} (status ${e.statusCode})',
      );
      Get.snackbar('Could not load cart', e.message);
    } catch (e, st) {
      debugPrint('$_tag fetchCart unexpected error: $e');
      debugPrint('$_tag fetchCart stack: $st');
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
      debugPrint('$_tag fetchCart finished, isLoading=${isLoading.value}');
    }
  }

  Future<void> addToCart({required int variantId, int quantity = 1}) async {
    debugPrint('$_tag addToCart(variantId: $variantId, quantity: $quantity)');
    try {
      await ApiService.addToCart(variantId: variantId, quantity: quantity);
      debugPrint('$_tag addToCart API call succeeded, refreshing cart');
      await fetchCart();
      Get.snackbar('Added to Cart', 'Item added successfully');
    } on ApiException catch (e) {
      debugPrint('$_tag addToCart failed: ${e.message}');
      Get.snackbar('Could not add to cart', e.message);
    } catch (e, st) {
      debugPrint('$_tag addToCart unexpected error: $e');
      debugPrint('$_tag addToCart stack: $st');
    }
  }

  Future<void> updateQuantity(CartItem item, int newQuantity) async {
    debugPrint(
      '$_tag updateQuantity(variantId: ${item.variantId}, '
      'from: ${item.quantity}, to: $newQuantity)',
    );
    if (newQuantity < 1) {
      debugPrint('$_tag updateQuantity aborted — newQuantity < 1');
      return;
    }

    // Optimistic local update for instant UI feedback
    final index = cartItems.indexWhere((i) => i.variantId == item.variantId);
    if (index != -1) {
      final unitPrice = item.unitPriceWithGst;
      cartItems[index] = item.copyWith(
        quantity: newQuantity,
        totalPriceWithGst: unitPrice * newQuantity,
      );
      cartItems.refresh(); // Notify observers of the change
      _recalculateGrandTotal();
      debugPrint(
        '$_tag updateQuantity optimistic update applied at index $index, '
        'new grandTotal=${grandTotal.value}',
      );
    } else {
      debugPrint(
        '$_tag updateQuantity WARNING — variantId ${item.variantId} not '
        'found in local cartItems, skipping optimistic update',
      );
    }

    try {
      await ApiService.updateCartItem(
        variantId: item.variantId,
        quantity: newQuantity,
      );
      debugPrint(
        '$_tag updateQuantity API call succeeded, reconciling with server',
      );
      await fetchCart(
        showLoader: false,
      ); // reconcile with server truth (tiered pricing may change unit price)
    } on ApiException catch (e) {
      debugPrint('$_tag updateQuantity failed: ${e.message}');
      Get.snackbar('Could not update quantity', e.message);
      await fetchCart(showLoader: false); // revert optimistic update on failure
    } catch (e, st) {
      debugPrint('$_tag updateQuantity unexpected error: $e');
      debugPrint('$_tag updateQuantity stack: $st');
      await fetchCart(showLoader: false); // revert optimistic update on failure
    }
  }

  void increment(CartItem item) {
    debugPrint('$_tag increment(variantId: ${item.variantId})');
    updateQuantity(item, item.quantity + 1);
  }

  void decrement(CartItem item) {
    debugPrint('$_tag decrement(variantId: ${item.variantId})');
    updateQuantity(item, item.quantity - 1);
  }

  Future<void> removeItem(CartItem item) async {
    debugPrint('$_tag removeItem(variantId: ${item.variantId})');
    final removed = item;
    cartItems.removeWhere((i) => i.variantId == item.variantId);
    _recalculateGrandTotal();
    debugPrint(
      '$_tag removeItem — locally removed, new grandTotal=${grandTotal.value}',
    );

    try {
      await ApiService.removeCartItem(variantId: removed.variantId);
      debugPrint('$_tag removeItem API call succeeded');
    } on ApiException catch (e) {
      debugPrint('$_tag removeItem failed: ${e.message}');
      Get.snackbar('Could not remove item', e.message);
      await fetchCart(); // revert
    } catch (e, st) {
      debugPrint('$_tag removeItem unexpected error: $e');
      debugPrint('$_tag removeItem stack: $st');
      await fetchCart(showLoader: false); // revert
    }
  }

  /// "Clear" — no bulk-clear endpoint given, so this removes each item
  /// individually via the same DELETE endpoint.
  Future<void> clearCart() async {
    debugPrint('$_tag clearCart called — removing ${cartItems.length} items');
    final items = List<CartItem>.from(cartItems);
    cartItems.clear();
    grandTotal.value = 0;
    for (final item in items) {
      try {
        await ApiService.removeCartItem(variantId: item.variantId);
        debugPrint('$_tag clearCart: removed variant ${item.variantId}');
      } catch (e) {
        debugPrint(
          '$_tag clearCart: failed removing variant ${item.variantId}: $e',
        );
      }
    }
    await fetchCart(showLoader: false);
    debugPrint('$_tag clearCart finished');
  }

  void _recalculateGrandTotal() {
    grandTotal.value = cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPriceWithGst,
    );
    debugPrint('$_tag _recalculateGrandTotal -> ${grandTotal.value}');
  }

  // ── STATIC feature stubs ─────────────────────────────────────────────
  void applyCoupon(String code) {
    debugPrint(
      '$_tag applyCoupon(code: "$code") — static stub, no backend yet',
    );
    couponCode.value = code;
    Get.snackbar('Coupon', 'Coupon feature coming soon');
  }

  void addGstin() {
    debugPrint('$_tag addGstin() — static stub, no backend yet');
    gstinAdded.value = true;
    Get.snackbar('GSTIN', 'GSTIN feature coming soon');
  }

  // ── Address & Delivery State ──────────────────────────────
  final Rx<AddressModel?> selectedAddress = Rx<AddressModel?>(null);
  final Rx<String?> selectedDeliveryDate = Rx<String?>(null);
  final Rx<VehicleModel?> selectedVehicle = Rx<VehicleModel?>(null);
  final Rx<CheckoutResponse?> checkoutResponse = Rx<CheckoutResponse?>(null);
  final RxBool isCheckingOut = false.obs;
  final Rx<String?> orderConfirmationMessage = Rx<String?>(null);

  // ── Address & Delivery Methods ──────────────────────────────

  // ── Address & Delivery Methods ──────────────────────────────

  Future<void> updateAddress(AddressModel address) async {
    try {
      await ApiService.updateProfile(
        fullName: address.fullName,
        email: address.email,
        phoneNumber: address.phoneNumber,
        address: address.address,
        pincode: address.pincode,
      );

      final profile = await ApiService.getProfile();
      selectedAddress.value = AddressModel.fromJson(profile);

      Get.snackbar(
        'Address Updated',
        'Your address has been updated successfully',
        backgroundColor: AppColors.primaryGreen,
        colorText: Colors.white,
      );
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    }
  }

  Future<bool> checkPincode(String pincode) async {
    debugPrint('$_tag checkPincode(pincode: "$pincode") called');
    try {
      final response = await ApiService.checkPincode(pincode);
      debugPrint('$_tag checkPincode response: $response');
      final result = PincodeCheckResponse.fromJson(response);
      debugPrint(
        '$_tag checkPincode parsed — isServiceable: ${result.isServiceable}, '
        'message: "${result.message}"',
      );

      if (!result.isServiceable) {
        debugPrint('$_tag checkPincode — NOT serviceable, showing snackbar');
        Get.snackbar(
          'Not Serviceable',
          result.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      debugPrint(
        '$_tag checkPincode — serviceable, showing distance alert dialog',
      );
      // Show distance alert
      Get.dialog(
        AlertDialog(
          title: const Text('📍 Delivery Distance Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please note:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '• The delivery distance affects the final price',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                '• Longer distances may incur additional charges',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                '• You can review the delivery charge before placing your order',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Distance may increase the delivery charge',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('I Understand'),
            ),
          ],
        ),
      );

      return true;
    } on ApiException catch (e) {
      debugPrint(
        '$_tag checkPincode failed: ${e.message} (status ${e.statusCode})',
      );
      Get.snackbar('Error', e.message);
      return false;
    } catch (e, st) {
      debugPrint('$_tag checkPincode unexpected error: $e');
      debugPrint('$_tag checkPincode stack: $st');
      return false;
    }
  }

  Future<void> fetchAvailableVehicles() async {
    debugPrint('$_tag fetchAvailableVehicles called');
    try {
      final vehicles = await ApiService.getAvailableVehicles();
      debugPrint(
        '$_tag fetchAvailableVehicles — ${vehicles.length} vehicles returned',
      );
      if (vehicles.isNotEmpty) {
        selectedVehicle.value = vehicles.first;
        debugPrint(
          '$_tag fetchAvailableVehicles — auto-selected vehicle '
          '"${selectedVehicle.value?.vehicleName}" '
          '(${selectedVehicle.value?.vehicleNumber})',
        );
      } else {
        debugPrint('$_tag fetchAvailableVehicles — no vehicles available');
      }
    } on ApiException catch (e) {
      debugPrint('$_tag fetchAvailableVehicles failed: ${e.message}');
    } catch (e, st) {
      debugPrint('$_tag fetchAvailableVehicles unexpected error: $e');
      debugPrint('$_tag fetchAvailableVehicles stack: $st');
    }
  }

  /// Called when the user taps either "Cash on Delivery" or
  /// "Online Payment" on the cart page. This is the only place that flips
  /// `hasSelectedPaymentMethod` to true, so the checkout button only shows
  /// up after a deliberate choice — not just because 'COD' happens to be
  /// the default value.
  void selectPaymentMethod(String method) {
    debugPrint(
      '$_tag selectPaymentMethod("$method") — was: '
      '"${selectedPaymentMethod.value}", hasSelected was: '
      '${hasSelectedPaymentMethod.value}',
    );
    selectedPaymentMethod.value = method;
    hasSelectedPaymentMethod.value = true;
    debugPrint(
      '$_tag selectPaymentMethod — now: "${selectedPaymentMethod.value}", '
      'hasSelected: ${hasSelectedPaymentMethod.value}',
    );
  }

  // ── Checkout Process ──────────────────────────────────────
  Future<CheckoutResponse?> processCheckout({
    required String pincode,
    required String deliveryDate,
    int? couponId,
  }) async {
    debugPrint(
      '$_tag processCheckout(pincode: "$pincode", deliveryDate: '
      '"$deliveryDate", couponId: $couponId)',
    );
    try {
      isCheckingOut.value = true;
      final response = await ApiService.checkout(
        pincode: pincode,
        requestedDeliveryDate: deliveryDate,
        couponId: couponId,
      );
      debugPrint('$_tag processCheckout response: $response');

      final checkoutResult = CheckoutResponse.fromJson(response);
      checkoutResponse.value = checkoutResult;
      debugPrint(
        '$_tag processCheckout parsed — deliveryAvailable: '
        '${checkoutResult.deliveryAvailable}, grandTotal: '
        '${checkoutResult.paymentSummary.grandTotal}, deliveryCharge: '
        '${checkoutResult.paymentSummary.deliveryCharge}',
      );

      return checkoutResult;
    } on ApiException catch (e) {
      debugPrint(
        '$_tag processCheckout failed: ${e.message} (status ${e.statusCode})',
      );
      Get.snackbar('Checkout Error', e.message);
      return null;
    } catch (e, st) {
      debugPrint('$_tag processCheckout unexpected error: $e');
      debugPrint('$_tag processCheckout stack: $st');
      return null;
    } finally {
      isCheckingOut.value = false;
      debugPrint(
        '$_tag processCheckout finished, isCheckingOut=${isCheckingOut.value}',
      );
    }
  }

  // ── SINGLE placeOrder method that uses selected payment method ──
  Future<OrderPlacedResponse?> placeOrder({
    required String shippingAddress,
    required String pincode,
    required String deliveryDate,
  }) async {
    debugPrint(
      '$_tag placeOrder(shippingAddress: "$shippingAddress", pincode: '
      '"$pincode", deliveryDate: "$deliveryDate", paymentMethod: '
      '"${selectedPaymentMethod.value}")',
    );
    try {
      isCheckingOut.value = true;
      final response = await ApiService.placeOrder(
        paymentMethod:
            selectedPaymentMethod.value, // Uses selected payment method
        shippingAddress: shippingAddress,
        pincode: pincode,
        requestedDeliveryDate: deliveryDate,
      );
      debugPrint('$_tag placeOrder response: $response');

      final result = OrderPlacedResponse.fromJson(response);
      orderConfirmationMessage.value = result.message;
      debugPrint(
        '$_tag placeOrder parsed — orderId: ${result.orderDetails.id}, '
        'status: ${result.orderDetails.orderStatus}, grandTotal: '
        '${result.orderDetails.grandTotal}',
      );

      // Clear cart after successful order
      debugPrint('$_tag placeOrder — clearing cart after successful order');
      await clearCart();

      return result;
    } on ApiException catch (e) {
      debugPrint(
        '$_tag placeOrder failed: ${e.message} (status ${e.statusCode})',
      );
      Get.snackbar('Order Error', e.message);
      return null;
    } catch (e, st) {
      debugPrint('$_tag placeOrder unexpected error: $e');
      debugPrint('$_tag placeOrder stack: $st');
      return null;
    } finally {
      isCheckingOut.value = false;
      debugPrint(
        '$_tag placeOrder finished, isCheckingOut=${isCheckingOut.value}',
      );
    }
  }

  void toggleCancellationPolicy() =>
      cancellationPolicyExpanded.value = !cancellationPolicyExpanded.value;
}
