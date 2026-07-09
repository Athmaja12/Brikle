// lib/Cart/Controller/cart_controller.dart

import 'dart:convert';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

enum PaymentMethod { online, cod }

class CartController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<int, int> productCartMap = <int, int>{}.obs;

  // ── Coupon state ───────────────────────────────────────────────────────────
  final RxBool couponApplied = false.obs;
  final RxString appliedCouponCode = ''.obs;
  final RxDouble couponDiscount = 0.0.obs;

  // ── Payment & order state ──────────────────────────────────────────────────
  final Rx<PaymentMethod> selectedPayment = PaymentMethod.cod.obs;
  final RxBool isPlacingOrder = false.obs;

  // ── Pincode ───────────────────────────────────────────────────────────────
  final TextEditingController pincodeController = TextEditingController();
  @override
  void onClose() {
    pincodeController.dispose();
    super.onClose();
  }

  final RxBool isCheckingPincode = false.obs;

  // ── Address State ──────────────────────────────────────
  final Rx<AddressModel?> selectedAddress = Rx<AddressModel?>(null);
  final RxBool isAddressLoading = false.obs;

  // ── Computed Totals ────────────────────────────────────────────────────────
  double get subtotal => cartItems.fold(0.0, (sum, item) {
    final basePrice =
        double.tryParse(item.offerPrice) ?? double.tryParse(item.price) ?? 0;
    final multiplier = item.weight / 500;
    return sum + (basePrice * multiplier);
  });

  double get deliveryCharge => cartItems.isEmpty ? 0.0 : 10.0;

  double get gst => subtotal * 0.05;

  double get discount => cartItems.fold(0.0, (sum, item) {
    final original = double.tryParse(item.price) ?? 0;
    final offer = double.tryParse(item.offerPrice) ?? original;
    final multiplier = item.weight / 500;
    return sum + ((original - offer) * multiplier);
  });

  double get totalAmount =>
      subtotal + deliveryCharge + gst - discount - couponDiscount.value;

  int get cartCount => cartItems.length;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    debugPrint('[CartController] onInit → fetching existing cart');
    fetchCart();
    fetchAddress();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool isInCart(int productId) => productCartMap.containsKey(productId);
  int? cartItemIdFor(int productId) => productCartMap[productId];
  int weightFor(int productId) {
    final item = cartItems.firstWhereOrNull((c) => c.product == productId);
    return item?.weight ?? 500;
  }

  // ── Fetch Cart (GET) ───────────────────────────────────────────────────────
  Future<void> fetchCart() async {
    debugPrint('[CartController] fetchCart() → loading cart from server');
    isLoading.value = true;
    try {
      final token = await SessionManager.getAccessToken();
      debugPrint(
        '[CartController] fetchCart → token: ${token != null ? "present (${token.length} chars)" : "NULL ⚠️"}',
      );

      final url = Uri.parse(ApiConfig.cartUrl);
      debugPrint('[CartController] fetchCart → GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('[CartController] fetchCart → status: ${response.statusCode}');
      debugPrint(
        '[CartController] fetchCart → response body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        debugPrint(
          '[CartController] fetchCart → decoded type: ${decoded.runtimeType}',
        );
        debugPrint('[CartController] fetchCart → decoded: $decoded');

        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          data =
              (decoded['items'] as List<dynamic>?) ??
              (decoded['results'] as List<dynamic>?) ??
              (decoded['data'] as List<dynamic>?) ??
              [];
        } else {
          data = [];
        }

        debugPrint('[CartController] fetchCart → parsed ${data.length} items');

        final items = data.map((e) => CartItemModel.fromJson(e)).toList();
        cartItems.assignAll(items);
        productCartMap.assignAll({
          for (final item in items) item.product: item.id,
        });

        // Verify the map — should print {19: 5} NOT {19: 19}
        debugPrint('[CartController] productCartMap: $productCartMap');
      } else {
        debugPrint(
          '[CartController] fetchCart ❌ FAILED → status: ${response.statusCode}, body: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[CartController] fetchCart 💥 EXCEPTION: $e');
      debugPrint('[CartController] fetchCart stackTrace:\n$stackTrace');
    } finally {
      isLoading.value = false;
      await fetchAddress();
    }
  }

  // ── Add to Cart ────────────────────────────────────────────────────────────
  Future<bool> addToCart({required int productId, int weight = 500}) async {
    debugPrint(
      '[CartController] addToCart() → productId: $productId, weight: $weight',
    );
    try {
      final token = await SessionManager.getAccessToken();

      final url = Uri.parse(ApiConfig.addToCartUrl);
      final body = jsonEncode({'product_id': productId, 'weight': weight});
      debugPrint('[CartController] addToCart → POST $url');
      debugPrint('[CartController] addToCart → body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('[CartController] addToCart → status: ${response.statusCode}');
      debugPrint(
        '[CartController] addToCart → response body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newItem = CartItemModel.fromJson(data);

        cartItems.removeWhere((c) => c.product == productId);
        cartItems.add(newItem);
        productCartMap[productId] = newItem.id;

        Get.snackbar(
          '✅ Added',
          '${newItem.productName} added to cart',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else if (response.statusCode == 400) {
        final bodyDecoded = jsonDecode(response.body);
        final errorMsg = bodyDecoded['error']?.toString() ?? '';

        if (errorMsg.toLowerCase().contains('already in cart')) {
          await fetchCart();
          return true;
        }

        _showError('Failed to add to cart. Please try again.');
        return false;
      } else {
        _showError('Failed to add to cart. Please try again.');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[CartController] addToCart 💥 EXCEPTION: $e');
      debugPrint('[CartController] addToCart stackTrace:\n$stackTrace');
      _showError('Network error. Check your connection.');
      return false;
    }
  }

  // ── Update Weight (PATCH) ──────────────────────────────────────────────────
  Future<void> updateWeight({
    required int productId,
    required int weight,
  }) async {
    final index = cartItems.indexWhere((c) => c.product == productId);
    if (index == -1) return;

    final oldWeight = cartItems[index].weight;

    // Optimistic update
    cartItems[index] = cartItems[index].copyWith(weight: weight);
    cartItems.refresh();

    // Resolve cart item id from map — always up to date
    final cartItemId = productCartMap[productId];
    if (cartItemId == null) {
      debugPrint(
        '[CartController] updateWeight ⚠️ no cartItemId for productId: $productId — refreshing cart',
      );
      cartItems[index] = cartItems[index].copyWith(weight: oldWeight);
      cartItems.refresh();
      await fetchCart();
      return;
    }

    try {
      final token = await SessionManager.getAccessToken();
      final url = Uri.parse(ApiConfig.cartItemUrl(productId));

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': weight}),
      );

      debugPrint('PATCH URL: $url');
      debugPrint('PATCH STATUS: ${response.statusCode}');
      debugPrint('PATCH RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        cartItems[index] = cartItems[index].copyWith(weight: oldWeight);
        cartItems.refresh();
        _showError('Failed to update quantity');
      }
    } catch (e) {
      cartItems[index] = cartItems[index].copyWith(weight: oldWeight);
      cartItems.refresh();
      _showError('Network error. Check your connection.');
    }
  }

  // ── Remove from Cart (DELETE) ──────────────────────────────────────────────
  // AFTER
  Future<void> removeFromCart(int productId) async {
    final cartItemId = productCartMap[productId];
    debugPrint(
      '[CartController] removeFromCart() → productId: $productId, resolved cartItemId: $cartItemId',
    );

    if (cartItemId == null) {
      debugPrint(
        '[CartController] removeFromCart ⚠️ no cartItemId found for productId: $productId',
      );
      // Still clean up local state
      cartItems.removeWhere((c) => c.product == productId);
      productCartMap.remove(productId);
      cartItems.refresh();
      return;
    }

    try {
      final token = await SessionManager.getAccessToken();
      final url = Uri.parse(ApiConfig.cartItemUrl(productId));
      debugPrint('[CartController] removeFromCart → DELETE $url');

      final response = await http.delete(
        url,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      debugPrint(
        '[CartController] removeFromCart → status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        cartItems.removeWhere((c) => c.product == productId);
        productCartMap.remove(productId);
        cartItems.refresh();
      } else {
        _showError('Failed to remove item');
      }
    } catch (e) {
      _showError('Failed to remove item');
    }
  }

  // ── Fetch Address (GET) ────────────────────────────────────────────────────
  // ── Fetch Address (GET from profile) ──────────────────────────────────────
  Future<void> fetchAddress() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[fetchAddress] STARTED');
    debugPrint('[fetchAddress] URL => ${ApiConfig.profileUrl}');

    isAddressLoading.value = true;

    try {
      final token = await SessionManager.getAccessToken();
      debugPrint(
        '[fetchAddress] token => ${token != null ? "present (${token.length} chars)" : "NULL ⚠️"}',
      );

      final response = await http.get(
        Uri.parse(ApiConfig.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('[fetchAddress] STATUS => ${response.statusCode}');
      debugPrint('[fetchAddress] BODY   => ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addressLine = data['address']?.toString() ?? '';

        debugPrint('[fetchAddress] address from profile => "$addressLine"');

        if (addressLine.isEmpty) {
          debugPrint('[fetchAddress] ⚠️ address field is empty');
          selectedAddress.value = null;
        } else {
          selectedAddress.value = AddressModel(
            id: 0,
            addressLine: addressLine,
            isPrimary: true,
          );
          debugPrint('[fetchAddress] ✅ selectedAddress set => "$addressLine"');
        }
      } else {
        debugPrint('[fetchAddress] ❌ status: ${response.statusCode}');
        selectedAddress.value = null;
      }
    } catch (e, st) {
      debugPrint('[fetchAddress] 💥 EXCEPTION => $e');
      debugPrint('[fetchAddress] $st');
      selectedAddress.value = null;
    } finally {
      isAddressLoading.value = false;
      debugPrint(
        '[fetchAddress] done => ${selectedAddress.value?.addressLine ?? "null"}',
      );
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // ── Update Address (PATCH profile) ────────────────────────────────────────
  Future<bool> updateAddress({required int id, required String address}) async {
    if (address.trim().isEmpty) {
      _showError('Address cannot be empty');
      return false;
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[updateAddress] PATCH profile => "$address"');

    try {
      final token = await SessionManager.getAccessToken();

      final response = await http.patch(
        Uri.parse(ApiConfig.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'address': address}),
      );

      debugPrint('[updateAddress] STATUS => ${response.statusCode}');
      debugPrint('[updateAddress] BODY   => ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedAddress = data['address']?.toString() ?? address;

        selectedAddress.value = AddressModel(
          id: 0,
          addressLine: updatedAddress,
          isPrimary: true,
        );

        debugPrint('[updateAddress] ✅ updated => "$updatedAddress"');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return true;
      } else {
        debugPrint('[updateAddress] ❌ failed => ${response.statusCode}');
        _showError('Failed to update address. Please try again.');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return false;
      }
    } catch (e) {
      debugPrint('[updateAddress] 💥 EXCEPTION => $e');
      _showError('Network error. Check your connection.');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return false;
    }
  }

  // ── Apply Coupon ───────────────────────────────────────────────────────────
  Future<void> applyCoupon(String code) async {
    debugPrint('APPLY COUPON => $code');

    try {
      final token = await SessionManager.getAccessToken();

      final response = await http.post(
        Uri.parse(ApiConfig.applyCouponUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'coupon_code': code}),
      );

      debugPrint('COUPON STATUS => ${response.statusCode}');
      debugPrint('COUPON RESPONSE => ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isValid = data['valid'] == true;

        if (isValid) {
          final discountPercent = (data['discount_percent'] ?? 0).toDouble();
          final discountAmount = subtotal * (discountPercent / 100);

          couponDiscount.value = discountAmount;
          appliedCouponCode.value = data['code'] ?? code;
          couponApplied.value = true;

          showCartDialog(
            title: 'Coupon Applied',
            message: data['message'] ?? 'Discount applied successfully.',
            icon: Icons.local_offer_outlined,
            iconColor: AppColors.primaryGreen,
          );

          debugPrint('DISCOUNT AMOUNT => $discountAmount');
        } else {
          _showError('Invalid coupon');
        }
      } else {
        _showError('Invalid coupon');
      }
    } catch (e) {
      debugPrint('COUPON ERROR => $e');
      _showError('Coupon validation failed');
    }
  }

  // ── Remove Coupon ──────────────────────────────────────────────────────────
  void removeCoupon() {
    debugPrint(
      '[CartController] removeCoupon() → clearing coupon "${appliedCouponCode.value}"',
    );
    couponDiscount.value = 0.0;
    appliedCouponCode.value = '';
    couponApplied.value = false;
  }

  // ── Check Pincode ──────────────────────────────────────────────────────────
  Future<bool?> checkPincode() async {
    final pincode = pincodeController.text.trim();

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('CHECK PINCODE API STARTED');
    debugPrint('ENTERED PINCODE => $pincode');

    if (pincode.isEmpty) {
      debugPrint('PINCODE EMPTY');
      showCartDialog(
        title: 'Pincode Required',
        message: 'Please enter your delivery pincode to continue checkout.',
        icon: Icons.location_on_outlined,
        iconColor: Colors.orange,
      );
      return null;
    }

    isCheckingPincode.value = true;

    try {
      final token = await SessionManager.getAccessToken();
      debugPrint('TOKEN => $token');

      final url = Uri.parse(ApiConfig.checkPincodeUrl);
      debugPrint('API URL => $url');

      final body = jsonEncode({'pincode': pincode});
      debugPrint('REQUEST BODY => $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('STATUS CODE => ${response.statusCode}');
      debugPrint('RAW RESPONSE => ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('DECODED RESPONSE => $data');

        final isServiceable = data['is_serviceable'] == true;
        debugPrint('BACKEND is_serviceable => ${data['is_serviceable']}');
        debugPrint('FINAL SERVICEABLE STATUS => $isServiceable');
        debugPrint('CHECK PINCODE API SUCCESS');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return isServiceable;
      }

      return false;
    } catch (e, stackTrace) {
      debugPrint('CHECK PINCODE ERROR => $e');
      debugPrint('CHECK PINCODE STACKTRACE => $stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return false;
    } finally {
      isCheckingPincode.value = false;
    }
  }

  // ── Place Order ────────────────────────────────────────────────────────────
  Future<bool> placeOrder() async {
    debugPrint('[CartController] placeOrder() → payment: $selectedPayment');

    final bool? isServiceable = await checkPincode();
    debugPrint('FINAL PINCODE VALIDATION RESULT => $isServiceable');

    if (isServiceable == null) return false;

    if (isServiceable == false) {
      showCartDialog(
        title: 'Delivery Unavailable',
        message: 'Sorry, delivery is currently unavailable for this pincode.',
        icon: Icons.location_off_outlined,
        iconColor: Colors.redAccent,
      );
      return false;
    }

    isPlacingOrder.value = true;

    try {
      final token = await SessionManager.getAccessToken();

      final payload = {
        'payment_method': selectedPayment.value == PaymentMethod.cod
            ? 'COD'
            : 'ONLINE',
        'pincode': pincodeController.text.trim(),
        if (couponApplied.value) 'coupon_code': appliedCouponCode.value,
      };

      debugPrint('[CartController] placeOrder PAYLOAD => $payload');

      final response = await http.post(
        Uri.parse(ApiConfig.checkoutUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint(
        '[CartController] placeOrder STATUS => ${response.statusCode}',
      );
      debugPrint('[CartController] placeOrder BODY => ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('ORDER PLACED SUCCESSFULLY');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        cartItems.clear();
        productCartMap.clear();
        removeCoupon();
        return true;
      }

      debugPrint('ORDER FAILED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _showError('Failed to place order');
      return false;
    } catch (e) {
      debugPrint('placeOrder ERROR => $e');
      _showError('Something went wrong');
      return false;
    } finally {
      isPlacingOrder.value = false;
    }
  }

  void showCartDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    final sw = Get.width;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(sw * 0.06),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(sw * 0.05),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: sw * 0.18,
                height: sw * 0.18,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: sw * 0.09),
              ),

              SizedBox(height: sw * 0.05),

              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: sw * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inputText,
                ),
              ),

              SizedBox(height: sw * 0.025),

              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: sw * 0.034,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
              ),

              SizedBox(height: sw * 0.06),

              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    height: sw * 0.13,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(sw * 0.035),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'OK',
                      style: GoogleFonts.manrope(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error helper ───────────────────────────────────────────────────────────
  void _showError(String msg) {
    debugPrint('[CartController] _showError: $msg');
    Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM);
  }
}
