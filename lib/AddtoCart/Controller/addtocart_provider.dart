// lib/AddtoCart/Controller/addtocart_provider.dart

import 'dart:async';

import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CartController extends GetxController {
  static const String _tag = '[CartController]';

  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxDouble grandTotal = 0.0.obs;
  final RxBool isLoading = true.obs;
  final RxBool cancellationPolicyExpanded = false.obs;

  // ── STATIC placeholders ──────────────────────────────────────
  final RxString couponCode = ''.obs;
  final RxBool gstinAdded = false.obs;
  static const double staticDiscount = 0;
  static const String staticDeliveryChargeLabel = 'FREE';
  static const double staticHandlingCharge = 0;

  // ── Payment Method State ──────────────────────────────
  // NOTE: values here must match what the backend expects, i.e.
  // "COD" or "RAZORPAY" — not "Online". See _PaymentMethodSelector.
  final RxString selectedPaymentMethod = 'COD'.obs;
  final RxBool hasSelectedPaymentMethod = false.obs;
  final RxBool showPaymentMethodSelector = false.obs;

  // ── Coupon State ──────────────────────────────────────
  final RxList<CouponModel> myCoupons = <CouponModel>[].obs;
  final RxBool isLoadingCoupons = false.obs;
  final Rx<CouponModel?> selectedCoupon = Rx<CouponModel?>(null);

  // ── Order Success State ──────────────────────────────
  final Rx<OrderPlacedResponse?> lastOrderResponse = Rx<OrderPlacedResponse?>(
    null,
  );
  final RxList<CouponModel> earnedCoupons = <CouponModel>[].obs;
  final RxInt earnedCouponsCount = 0.obs;

  // ── Razorpay State ──────────────────────────────────────────
  late final Razorpay _razorpay;
  Completer<bool>? _paymentCompleter;
  int? _pendingRazorpayOrderId;
  final Rx<EarnedRewardCoupon?> lastVerifiedRewardCoupon =
      Rx<EarnedRewardCoupon?>(null);

  // ── END STATIC ───────────────────────────────────────────────────────

  int get itemCount => cartItems.length;
  double get subTotal => grandTotal.value;
  double get total => subTotal - staticDiscount + staticHandlingCharge;

  @override
  void onInit() {
    super.onInit();
    debugPrint('$_tag onInit — controller created, fetching cart');
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchCart();
    fetchMyCoupons();
  }

  @override
  void onClose() {
    debugPrint('$_tag onClose — controller disposed');
    _razorpay.clear();
    super.onClose();
  }

  // ── Coupon Methods ──────────────────────────────────

  Future<void> fetchMyCoupons() async {
    debugPrint('$_tag fetchMyCoupons() called');
    isLoadingCoupons.value = true;
    try {
      final response = await ApiService.getMyCoupons();
      myCoupons.value = response;
      debugPrint('$_tag fetchMyCoupons success — ${myCoupons.length} coupons');
    } catch (e) {
      debugPrint('$_tag fetchMyCoupons failed: $e');
    } finally {
      isLoadingCoupons.value = false;
    }
  }

  void selectCoupon(CouponModel coupon) {
    debugPrint('$_tag selectCoupon: ${coupon.couponCode}');
    selectedCoupon.value = coupon;
    couponCode.value = coupon.couponCode;
    Get.snackbar(
      'Coupon Applied',
      '${coupon.couponCode} - ${coupon.discountPercentage}% off',
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
    );
  }

  void removeSelectedCoupon() {
    debugPrint('$_tag removeSelectedCoupon');
    selectedCoupon.value = null;
    couponCode.value = '';
  }

  // ── END Coupon Methods ──────────────────────────────
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

    final index = cartItems.indexWhere((i) => i.variantId == item.variantId);
    if (index != -1) {
      final unitPrice = item.unitPriceWithGst;
      cartItems[index] = item.copyWith(
        quantity: newQuantity,
        totalPriceWithGst: unitPrice * newQuantity,
      );
      cartItems.refresh();
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
      await fetchCart(showLoader: false);
    } on ApiException catch (e) {
      debugPrint('$_tag updateQuantity failed: ${e.message}');
      Get.snackbar('Could not update quantity', e.message);
      await fetchCart(showLoader: false);
    } catch (e, st) {
      debugPrint('$_tag updateQuantity unexpected error: $e');
      debugPrint('$_tag updateQuantity stack: $st');
      await fetchCart(showLoader: false);
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
      await fetchCart();
    } catch (e, st) {
      debugPrint('$_tag removeItem unexpected error: $e');
      debugPrint('$_tag removeItem stack: $st');
      await fetchCart(showLoader: false);
    }
  }

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
  final Rx<String?> selectedDeliveryTime = Rx<String?>(null);
  final Rx<VehicleModel?> selectedVehicle = Rx<VehicleModel?>(null);
  final Rx<CheckoutResponse?> checkoutResponse = Rx<CheckoutResponse?>(null);
  final RxBool isCheckingOut = false.obs;
  final Rx<String?> orderConfirmationMessage = Rx<String?>(null);

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
    required String deliveryTime, // NEW
    int? couponId,
  }) async {
    debugPrint(
      '$_tag processCheckout(pincode: "$pincode", deliveryDate: '
      '"$deliveryDate", deliveryTime: "$deliveryTime", couponId: $couponId)',
    );
    try {
      isCheckingOut.value = true;
      final response = await ApiService.checkout(
        pincode: pincode,
        requestedDeliveryDate: deliveryDate,
        requestedDeliveryTime: deliveryTime,
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

  // ── placeOrder method ──────────────────────────────
  //
  // For COD, behaviour is unchanged: place order -> success.
  //
  // For RAZORPAY, the backend places the order in PENDING state and
  // hands back razorpay_data. We then open the native Razorpay checkout
  // sheet and WAIT for the result before treating the order as placed —
  // clearing the cart / burning the coupon / navigating to the success
  // screen only happens after /api/verify-payment/ confirms the
  // signature server-side. If the user cancels or the payment fails,
  // placeOrder() returns null (same contract as any other failure) and
  // the order sits server-side as PENDING for a retry.
  Future<OrderPlacedResponse?> placeOrder({
    required String shippingAddress,
    required String pincode,
    required String deliveryDate,
    String? deliveryTime, // NEW
  }) async {
    debugPrint(
      '$_tag placeOrder(shippingAddress: "$shippingAddress", pincode: '
      '"$pincode", deliveryDate: "$deliveryDate", deliveryTime: '
      '"$deliveryTime", paymentMethod: "${selectedPaymentMethod.value}", '
      'couponId: ${selectedCoupon.value?.id})',
    );
    try {
      isCheckingOut.value = true;
      final response = await ApiService.placeOrder(
        paymentMethod: selectedPaymentMethod.value,
        shippingAddress: shippingAddress,
        pincode: pincode,
        requestedDeliveryDate: deliveryDate,
        requestedDeliveryTime: deliveryTime,
        couponId: selectedCoupon.value?.id, // NEW — was never sent
      );
      debugPrint('$_tag placeOrder response: $response');

      final result = OrderPlacedResponse.fromJson(response);

      // ── RAZORPAY branch: open checkout sheet and wait for verification.
      if (result.orderDetails.paymentMethod == 'RAZORPAY' &&
          result.razorpayData != null) {
        debugPrint(
          '$_tag placeOrder — RAZORPAY order created (id: '
          '${result.orderDetails.id}), opening checkout sheet',
        );
        final verified = await _openRazorpayCheckout(result);
        if (!verified) {
          debugPrint(
            '$_tag placeOrder — Razorpay payment not verified, aborting '
            'success flow. Order ${result.orderDetails.id} remains PENDING.',
          );
          return null;
        }
        debugPrint('$_tag placeOrder — Razorpay payment verified');
      }

      orderConfirmationMessage.value = result.message;

      if (result.earnedCoupons != null) {
        earnedCoupons.value = result.earnedCoupons!;
        earnedCouponsCount.value = result.earnedCouponsCount;
        debugPrint('$_tag placeOrder — earned ${earnedCoupons.length} coupons');
      }

      lastOrderResponse.value = result;

      debugPrint(
        '$_tag placeOrder parsed — orderId: ${result.orderDetails.id}, '
        'status: ${result.orderDetails.orderStatus}, grandTotal: '
        '${result.orderDetails.grandTotal}',
      );

      // The coupon that was just spent is no longer valid to reuse —
      // clear it locally so a fresh cart session doesn't show a "spent"
      // coupon as still applied.
      selectedCoupon.value = null;
      couponCode.value = '';

      debugPrint('$_tag placeOrder — clearing cart after successful order');
      await clearCart();
      await fetchMyCoupons();

      // FIX: ProfileController.coupons (rendered by the Coupon listing
      // page) is a completely separate RxList from this controller's
      // myCoupons — the line above only refreshes CartController's own
      // copy. Without this, a coupon just marked "used" server-side
      // stays showing as "Active" on the Coupon listing screen until the
      // user manually pull-to-refreshes it.
      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().fetchCoupons();
      }

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

  // ── Razorpay Checkout ──────────────────────────────────────

  /// Opens the native Razorpay checkout sheet for the just-created order
  /// and suspends until either:
  ///  - payment succeeds AND server-side signature verification passes
  ///    -> resolves true
  ///  - payment fails, is cancelled, or verification fails -> resolves false
  Future<bool> _openRazorpayCheckout(OrderPlacedResponse order) async {
    final data = order.razorpayData!;
    _pendingRazorpayOrderId = order.orderDetails.id;
    _paymentCompleter = Completer<bool>();

    final address = selectedAddress.value;

    final options = {
      'key': data.razorpayKeyId,
      // Razorpay expects amount in the smallest currency unit (paise for INR).
      // data.amount from the backend is already the grand total in rupees.
      'amount': (data.amount * 100).round(),
      'currency': data.currency,
      'name': 'Brikle',
      'description': 'Order #${order.orderDetails.id}',
      'order_id': data.razorpayOrderId,
      'prefill': {
        if (address?.email != null) 'email': address!.email,
        if (address?.phoneNumber != null) 'contact': address!.phoneNumber,
      },
      'theme': {
        'color':
            '#${AppColors.primaryGreen.value.toRadixString(16).substring(2)}',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('$_tag _openRazorpayCheckout — failed to open sheet: $e');
      Get.snackbar(
        'Payment Error',
        'Could not open the payment screen. Please try again.',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
      return false;
    }

    return _paymentCompleter!.future;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = _pendingRazorpayOrderId;
    debugPrint(
      '$_tag _handlePaymentSuccess — razorpayPaymentId: '
      '${response.paymentId}, razorpayOrderId: ${response.orderId}',
    );

    if (orderId == null ||
        response.orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      debugPrint('$_tag _handlePaymentSuccess — missing required fields');
      Get.snackbar(
        'Verification Error',
        'Payment succeeded but could not be verified. Contact support with '
            'your payment ID: ${response.paymentId ?? "unknown"}',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
      _paymentCompleter?.complete(false);
      return;
    }

    try {
      final verifyResult = await ApiService.verifyPayment(
        orderId: orderId,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );
      final parsed = PaymentVerificationResponse.fromJson(verifyResult);
      lastVerifiedRewardCoupon.value = parsed.rewardCoupon;

      debugPrint(
        '$_tag _handlePaymentSuccess — verified, paymentStatus: '
        '${parsed.paymentStatus}',
      );

      Get.snackbar(
        'Payment Successful',
        parsed.message.isNotEmpty ? parsed.message : 'Payment verified!',
        backgroundColor: AppColors.primaryGreen,
        colorText: Colors.white,
      );

      _paymentCompleter?.complete(true);
    } on ApiException catch (e) {
      debugPrint(
        '$_tag _handlePaymentSuccess — verify-payment failed: ${e.message}',
      );
      Get.snackbar(
        'Verification Failed',
        'Payment was received but verification failed: ${e.message}. '
            'Contact support with your payment ID: ${response.paymentId}',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
      _paymentCompleter?.complete(false);
    } catch (e) {
      debugPrint('$_tag _handlePaymentSuccess — unexpected error: $e');
      Get.snackbar(
        'Verification Failed',
        'Payment was received but verification failed. Contact support '
            'with your payment ID: ${response.paymentId}',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
      _paymentCompleter?.complete(false);
    } finally {
      _pendingRazorpayOrderId = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
      '$_tag _handlePaymentError — code: ${response.code}, message: '
      '${response.message}',
    );
    Get.snackbar(
      'Payment Failed',
      response.message?.isNotEmpty == true
          ? response.message!
          : 'Payment was not completed. Please try again.',
      backgroundColor: AppColors.errorRed,
      colorText: Colors.white,
    );
    _pendingRazorpayOrderId = null;
    _paymentCompleter?.complete(false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Fired when the user picks a wallet outside Razorpay's own flow
    // (e.g. Paytm). This does not by itself mean success or failure —
    // EVENT_PAYMENT_SUCCESS/EVENT_PAYMENT_ERROR still fire afterward.
    debugPrint('$_tag _handleExternalWallet — wallet: ${response.walletName}');
    Get.snackbar(
      'External Wallet Selected',
      response.walletName ?? 'Processing via external wallet...',
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
    );
  }

  void toggleCancellationPolicy() =>
      cancellationPolicyExpanded.value = !cancellationPolicyExpanded.value;
}
