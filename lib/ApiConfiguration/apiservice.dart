// lib/ApiConfiguration/apiservice.dart - Complete updated file with fix

import 'dart:convert';
import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/Calculation/Model/calculation_model.dart';
import 'package:brikle/Calculation/Model/productCalculator_model.dart';
import 'package:http/http.dart' as http;


class ApiService {
  ApiService._();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await SessionManager.getAccessToken();
    print("ACCESS TOKEN => $token");
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    required String pincode,
    required String streetAddress1,
    required String streetAddress2,
    required String customerType,
    String? gstNumber,
  }) {
    final body = <String, dynamic>{
      'full_name': fullName,
      'phone_number': phoneNumber,
      'pincode': pincode,
      'street_address1': streetAddress1,
      'street_address2': streetAddress2,
      'customer_type': customerType,
    };
    if (gstNumber != null && gstNumber.isNotEmpty) {
      body['gst_number'] = gstNumber;
    }
    return _post(ApiConfig.registerUrl, body);
  }

  static Future<Map<String, dynamic>> verifyRegisterOtp({
    required String phoneNumber,
    required String otp,
  }) {
    return _post(ApiConfig.verifyOtpUrl, {
      'phone_number': phoneNumber,
      'otp': otp,
    });
  }

  static Future<Map<String, dynamic>> resendOtp({required String phoneNumber}) {
    return _post(ApiConfig.resendOtpUrl, {'phone_number': phoneNumber});
  }

  static Future<Map<String, dynamic>> login({required String phoneNumber}) {
    return _post(ApiConfig.loginUrl, {'phone_number': phoneNumber});
  }

  static Future<Map<String, dynamic>> verifyLoginOtp({
    required String phoneNumber,
    required String otp,
  }) {
    return _post(ApiConfig.loginVerifyUrl, {
      'phone_number': phoneNumber,
      'otp': otp,
    });
  }

  static Future<Map<String, dynamic>> logout({
    required String refreshToken,
  }) async {
    return _post(ApiConfig.logoutUrl, {
      'refresh': refreshToken,
    }, headers: await _authHeaders());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getProfile() async {
    return _get(ApiConfig.profileUrl, headers: await _authHeaders());
  }

  /// ✅ FIXED: PATCH /api/customer-profile/ (without /edit/)
  /// body: { full_name, email, phone_number, address, pincode } (all optional)
  /// response: { full_name, email, phone_number, customer_type, gst_number, is_verified, address, pincode }
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? pincode,
    String? customerType,
    String? gstNumber,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (address != null) body['address'] = address;
    if (pincode != null) body['pincode'] = pincode;
    if (customerType != null) body['customer_type'] = customerType;
    if (gstNumber != null) body['gst_number'] = gstNumber;

    // ✅ FIX: Use profileUrl (without /edit/)
    return _patch(
      ApiConfig.profileUrl, // Changed from ApiConfig.profileEditUrl
      body,
      headers: await _authHeaders(),
    );
  }

  static Future<void> deleteAccount() async {
    await _delete(ApiConfig.deleteAccountUrl, headers: await _authHeaders());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PINCODE
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> checkPincode(String pincode) async {
    return _post(ApiConfig.checkPincodeUrl, {
      'pincode': pincode,
    }, headers: await _authHeaders());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VEHICLES
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<VehicleModel>> getAvailableVehicles() async {
    final response = await _get(
      ApiConfig.availableVehiclesUrl,
      headers: await _authHeaders(),
    );
    final results = response['results'] as List? ?? [];
    return results.map((e) => VehicleModel.fromJson(e)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHECKOUT & ORDER
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> checkout({
    required String pincode,
    required String requestedDeliveryDate,
    int? couponId,
  }) async {
    final body = <String, dynamic>{
      'pincode': pincode,
      'requested_delivery_date': requestedDeliveryDate,
    };
    if (couponId != null) body['coupon_id'] = couponId;
    return _post(ApiConfig.checkoutUrl, body, headers: await _authHeaders());
  }

  static Future<Map<String, dynamic>> placeOrder({
    required String paymentMethod,
    required String shippingAddress,
    required String pincode,
    required String requestedDeliveryDate,
  }) async {
    return _post(ApiConfig.placeOrderUrl, {
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
      'pincode': pincode,
      'requested_delivery_date': requestedDeliveryDate,
    }, headers: await _authHeaders());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CART
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getCart() async {
    return _get(ApiConfig.cartUrl, headers: await _authHeaders());
  }

  static Future<Map<String, dynamic>> addToCart({
    required int variantId,
    required int quantity,
  }) async {
    return _post(ApiConfig.cartUrl, {
      'variant': variantId,
      'quantity': quantity,
    }, headers: await _authHeaders());
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required int variantId,
    required int quantity,
  }) async {
    return _patch(ApiConfig.cartUrl, {
      'variant': variantId,
      'quantity': quantity,
    }, headers: await _authHeaders());
  }

  static Future<void> removeCartItem({required int variantId}) async {
    await _delete(
      ApiConfig.cartUrl,
      body: {'variant': variantId},
      headers: await _authHeaders(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CALCULATOR
  // ══════════════════════════════════════════════════════════════════════════

  /// GET api/calculator/
  /// Returns the 5-card list for the "Material Calculator" screen.
  static Future<CalculatorListResponse> getCalculatorList() async {
    final response = await _get(
      ApiConfig.calculatorListUrl,
      headers: await _authHeaders(),
    );
    return CalculatorListResponse.fromJson(response);
  }

  /// GET api/calculator/{id}/
  /// Called when a card's "Open Calculator" button is tapped. The
  /// `redirect_slug` in the result tells you which calculator screen to push.
  static Future<CalculatorDetailModel> getCalculatorDetail(int id) async {
    final response = await _get(
      ApiConfig.calculatorDetailUrl(id),
      headers: await _authHeaders(),
    );
    return CalculatorDetailModel.fromJson(response);
  }

  /// GET api/paint/drop-down/
  /// Populates the "Paint type" dropdown on the Paint Calculator screen.
  static Future<List<PaintDropdownItem>> getPaintDropdown() async {
    final response = await _get(
      ApiConfig.paintDropdownUrl,
      headers: await _authHeaders(),
    );
    final paints = response['paints'] as List? ?? [];
    return paints.map((e) => PaintDropdownItem.fromJson(e)).toList();
  }

  /// POST api/calculator/paint/
  /// Fired on "Calculate" and on debounced field changes.
  static Future<PaintEstimateModel> calculatePaint({
    required int materialId,
    required double wallLength,
    required double wallHeight,
    required int numberOfWalls,
    required int numberOfCoats,
  }) async {
    final response = await _post(
      ApiConfig.paintCalculateUrl,
      {
        'material_id': materialId,
        'wall_length': wallLength,
        'wall_height': wallHeight,
        'number_of_walls': numberOfWalls,
        'number_of_coats': numberOfCoats,
      },
      headers: await _authHeaders(),
    );
    return PaintEstimateModel.fromJson(response);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRODUCTS & CATEGORIES
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getCarousel() async {
    final response = await _get(
      ApiConfig.carouselUrl,
      headers: await _authHeaders(),
    );
    return response['carousels'] as List? ?? [];
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await _get(
      ApiConfig.categoriesUrl,
      headers: await _authHeaders(),
    );
    return response['results'] as List? ?? [];
  }

  static Future<List<dynamic>> getDealsOfWeek() async {
    final response = await _get(
      ApiConfig.dealsOfWeekUrl,
      headers: await _authHeaders(),
    );
    return response['results'] as List? ?? [];
  }

  static Future<List<dynamic>> getBestSelling(int categoryId) async {
    final response = await _get(
      ApiConfig.bestSellingUrl(categoryId),
      headers: await _authHeaders(),
    );
    return response['results'] as List? ?? [];
  }

  static Future<List<dynamic>> getProducts() async {
    final response = await _get(
      ApiConfig.customerProductsUrl,
      headers: await _authHeaders(),
    );
    return response['results'] ?? [];
  }

  static Future<List<dynamic>> getProductPriceTiers(int productId) async {
    final response = await _get(
      ApiConfig.productPriceTiersUrl(productId),
      headers: await _authHeaders(),
    );
    return response['results'] ?? [];
  }

  static Future<Map<String, dynamic>> getCategoryDetails(int categoryId) async {
    return _get(
      ApiConfig.categoryDetailsUrl(categoryId),
      headers: await _authHeaders(),
    );
  }

  static Future<Map<String, dynamic>> getCategoryFilterOptions(
    int categoryId,
  ) async {
    return _get(
      ApiConfig.categoryFilterOptionsUrl(categoryId),
      headers: await _authHeaders(),
    );
  }

  static Future<Map<String, dynamic>> getMaterialDetails(int materialId) async {
    return _get(
      ApiConfig.materialDetailsUrl(materialId),
      headers: await _authHeaders(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADDRESSES
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> addAddress({
    required String streetAddress1,
    required String streetAddress2,
    required String pincode,
    bool isPrimary = false,
    String? customerType,
    String? gstNumber,
  }) async {
    final body = <String, dynamic>{
      'street_address1': streetAddress1,
      'street_address2': streetAddress2,
      'pincode': pincode,
      'is_primary': isPrimary,
    };
    if (customerType != null) body['customer_type'] = customerType;
    if (gstNumber != null && gstNumber.isNotEmpty) {
      body['gst_number'] = gstNumber;
    }
    return _post(ApiConfig.addressListUrl, body, headers: await _authHeaders());
  }

  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    String? streetAddress1,
    String? streetAddress2,
    String? pincode,
    bool? isPrimary,
    String? customerType,
    String? gstNumber,
  }) async {
    final body = <String, dynamic>{};
    if (streetAddress1 != null) body['street_address1'] = streetAddress1;
    if (streetAddress2 != null) body['street_address2'] = streetAddress2;
    if (pincode != null) body['pincode'] = pincode;
    if (isPrimary != null) body['is_primary'] = isPrimary;
    if (customerType != null) body['customer_type'] = customerType;
    if (gstNumber != null) body['gst_number'] = gstNumber;

    return _patch(
      ApiConfig.addressDetailUrl(addressId),
      body,
      headers: await _authHeaders(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WISHLIST
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getWishlist() async {
    final response = await _get(
      ApiConfig.wishlistUrl,
      headers: await _authHeaders(),
    );
    return response["wishlist_items"] ?? [];
  }

  static Future<void> addToWishlist({required int variantId}) async {
    await _post(ApiConfig.wishlistUrl, {
      "variant": variantId,
    }, headers: await _authHeaders());
  }

  static Future<void> removeFromWishlist({required int variantId}) async {
    await _delete(
      ApiConfig.wishlistItemUrl(variantId),
      headers: await _authHeaders(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COUPONS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getMyCoupons() async {
    final response = await _get(
      ApiConfig.myCouponsUrl,
      headers: await _authHeaders(),
    );
    return response['results'] ?? [];
  }



  // ══════════════════════════════════════════════════════════════════════════
  // HTTP HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, String>? headers,
  }) async {
    http.Response response;
    try {
      response = await http
          .get(Uri.parse(url), headers: headers ?? _jsonHeaders)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: headers ?? _jsonHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _patch(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    http.Response response;
    try {
      response = await http
          .patch(
            Uri.parse(url),
            headers: headers ?? _jsonHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    return _handleResponse(response);
  }

  static Future<void> _delete(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse(url),
            headers: headers ?? _jsonHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final decoded = _decode(response);
    throw ApiException(
      _extractErrorMessage(decoded) ??
          'Something went wrong (code ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  static dynamic _decodeRaw(http.Response response) {
    print("_decodeRaw => statusCode: ${response.statusCode}");
    print("_decodeRaw => body: '${response.body}'");
    print("_decodeRaw => bodyLength: ${response.body.length}");
    try {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (e) {
      print("_decodeRaw => jsonDecode FAILED: $e");
      throw ApiException(
        'Unexpected server response. Please try again.',
        statusCode: response.statusCode,
      );
    }
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final raw = _decodeRaw(response);
    if (raw == null) return <String, dynamic>{};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List) return {'results': raw};
    throw ApiException(
      'Unexpected server response. Please try again.',
      statusCode: response.statusCode,
    );
  }

  static String? _extractErrorMessage(Map<String, dynamic> body) {
    if (body['detail'] is String) return body['detail'] as String;
    if (body['message'] is String) return body['message'] as String;
    for (final value in body.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String) return value;
    }
    return null;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Detect HTML error pages (Django debug page, nginx 502, etc.)
      final trimmed = response.body.trimLeft();
      if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html')) {
        throw ApiException(
          'Server error (${response.statusCode}). Please try again later.',
          statusCode: response.statusCode,
        );
      }

      String? message;
      try {
        final decoded = _decode(response);
        message = _extractErrorMessage(decoded);
      } catch (_) {}
      throw ApiException(
        message ?? 'Something went wrong (code ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return _decode(response);
  }
}