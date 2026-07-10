import 'dart:convert';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
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

  /// POST /api/customer-register/
  /// body: { full_name, phone_number, pincode, street_address1,
  ///         street_address2, customer_type, gst_number? }
  /// response: { id, phone_number, customer_type, gst_number, is_verified,
  ///             otp, addresses: [...] }
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

  /// POST /api/customer-verify-otp/
  /// body:     { phone_number, otp }
  /// response: { message, access, refresh }
  static Future<Map<String, dynamic>> verifyRegisterOtp({
    required String phoneNumber,
    required String otp,
  }) {
    return _post(ApiConfig.verifyOtpUrl, {
      'phone_number': phoneNumber,
      'otp': otp,
    });
  }

  /// POST /api/customer-resend-otp/
  /// body:     { phone_number }
  /// response: { message }  (may also include otp in dev/test mode)
  static Future<Map<String, dynamic>> resendOtp({required String phoneNumber}) {
    return _post(ApiConfig.resendOtpUrl, {'phone_number': phoneNumber});
  }

  /// POST /api/customer-login/
  /// body:     { phone_number }
  /// response: { phone_number, otp }
  static Future<Map<String, dynamic>> login({required String phoneNumber}) {
    return _post(ApiConfig.loginUrl, {'phone_number': phoneNumber});
  }

  /// POST /api/customer-login-verify/
  /// body:     { phone_number, otp }
  /// response: { message, access, refresh, customer_id }
  static Future<Map<String, dynamic>> verifyLoginOtp({
    required String phoneNumber,
    required String otp,
  }) {
    return _post(ApiConfig.loginVerifyUrl, {
      'phone_number': phoneNumber,
      'otp': otp,
    });
  }

  /// POST /api/customer-logout/
  /// body:     { refresh: "your_refresh_token" }
  /// response: { refresh }
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

  /// GET /api/customer-profile/
  /// response: { full_name, email, phone_number, address, is_verified }
  static Future<Map<String, dynamic>> getProfile() async {
    return _get(ApiConfig.profileUrl, headers: await _authHeaders());
  }

  /// PUT/PATCH /api/customer-profile/edit/
  /// body:     { full_name, email, address }  (all optional for PATCH)
  /// response: { full_name, email, address }
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    if (address != null) body['address'] = address;

    return _patch(
      ApiConfig.profileEditUrl,
      body,
      headers: await _authHeaders(),
    );
  }

  /// DELETE /api/customer-delete-account/
  /// response: none (204)
  static Future<void> deleteAccount() async {
    await _delete(ApiConfig.deleteAccountUrl, headers: await _authHeaders());
  }

  /// POST /api/customer-check-pincode/
  /// body: { pincode }
  /// response: { pincode, is_serviceable, message }
  static Future<Map<String, dynamic>> checkPincode(String pincode) async {
    return _post(ApiConfig.checkPincodeUrl, {
      'pincode': pincode,
    }, headers: await _authHeaders());
  }

  /// GET /api/customer-carousel/
  /// The API returns a raw JSON List → _decode() wraps it as {'results': [...]}
  static Future<List<dynamic>> getCarousel() async {
    final response = await _get(
      ApiConfig.carouselUrl,
      headers: await _authHeaders(),
    );
    return response['carousels'] as List? ?? [];
  }
  // print("CAROUSEL RESPONSE => $response");

  /// GET /api/superadmin/categories/
  /// response: { count, next, previous, results: [...] }
  static Future<List<dynamic>> getCategories() async {
    final response = await _get(
      ApiConfig.categoriesUrl,
      headers: await _authHeaders(),
    );
    return response['results'] as List? ?? [];
  }

  /// GET /api/deals-of-the-week/
  /// response: { count, next, previous, results: [...] }
  static Future<List<dynamic>> getDealsOfWeek() async {
    final response = await _get(
      ApiConfig.dealsOfWeekUrl,
      headers: await _authHeaders(),
    );
    return response['results'] as List? ?? [];
  }

  /// GET /api/best-selling/?category_id={id}
  /// response: { count, next, previous, results: [...] }
  static Future<List<dynamic>> getBestSelling(int categoryId) async {
    final response = await _get(
      ApiConfig.bestSellingUrl(categoryId),
      headers: await _authHeaders(),
    );
    return response['results'] as List? ?? [];
  }

  // ══════════════════════════════════════════════════════════════════════
  // CART
  // ══════════════════════════════════════════════════════════════════════

  /// GET /api/cart/add/
  /// response: { grand_total_with_gst, cart_items: [...] }
  static Future<Map<String, dynamic>> getCart() async {
    return _get(ApiConfig.cartUrl, headers: await _authHeaders());
  }

  /// POST /api/cart/add/  — body: { variant, quantity }
  static Future<Map<String, dynamic>> addToCart({
    required int variantId,
    required int quantity,
  }) async {
    return _post(ApiConfig.cartUrl, {
      'variant': variantId,
      'quantity': quantity,
    }, headers: await _authHeaders());
  }

  /// PATCH /api/cart/add/  — body: { variant, quantity }
  static Future<Map<String, dynamic>> updateCartItem({
    required int variantId,
    required int quantity,
  }) async {
    return _patch(ApiConfig.cartUrl, {
      'variant': variantId,
      'quantity': quantity,
    }, headers: await _authHeaders());
  }

  /// DELETE /api/cart/add/  — body: { variant }
  static Future<void> removeCartItem({required int variantId}) async {
    await _delete(
      ApiConfig.cartUrl,
      body: {'variant': variantId},
      headers: await _authHeaders(),
    );
  }

  /// GET /api/superadmin/materials/{id}/
  static Future<Map<String, dynamic>> getMaterialDetails(int materialId) async {
    return _get(
      ApiConfig.materialDetailsUrl(materialId),
      headers: await _authHeaders(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADDRESSES
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/customer/addresses/
  /// body:     { street_address1, street_address2, pincode, is_primary,
  ///             customer_type?, gst_number? }
  /// response: { id, street_address1, street_address2, pincode, is_primary, ... }
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

  /// PATCH /api/customer/addresses/{id}/
  /// body:     { street_address1, street_address2, pincode, is_primary,
  ///             customer_type?, gst_number? }  (all optional for PATCH)
  /// response: { id, street_address1, street_address2, pincode, is_primary, ... }
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

  static Future<List<dynamic>> getProducts() async {
    print("PRODUCT URL => ${ApiConfig.customerProductsUrl}");

    final response = await _get(
      ApiConfig.customerProductsUrl,
      headers: await _authHeaders(),
    );

    print("PRODUCT RESPONSE => $response");

    return response['results'] ?? [];
  }

  // ADD THIS ↓
  static Future<List<dynamic>> getProductPriceTiers(int productId) async {
    print("PRICE TIERS URL => ${ApiConfig.productPriceTiersUrl(productId)}");

    final response = await _get(
      ApiConfig.productPriceTiersUrl(productId),
      headers: await _authHeaders(),
    );

    print("PRICE TIERS RESPONSE (product $productId) => $response");

    return response['results'] ?? [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WISHLIST
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/customer/wishlist/
 


  /// GET /api/categories/{id}/details/
  static Future<Map<String, dynamic>> getCategoryDetails(int categoryId) async {
    return _get(
      ApiConfig.categoryDetailsUrl(categoryId),
      headers: await _authHeaders(),
    );
  }

  /// GET /api/categories/filter-options/?category_id={id}
  static Future<Map<String, dynamic>> getCategoryFilterOptions(
    int categoryId,
  ) async {
    return _get(
      ApiConfig.categoryFilterOptionsUrl(categoryId),
      headers: await _authHeaders(),
    );
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
    // 204 No Content — success, nothing to parse
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final decoded = _decode(response);
    throw ApiException(
      _extractErrorMessage(decoded) ??
          'Something went wrong (code ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  // AFTER:
  static dynamic _decodeRaw(http.Response response) {
    print("_decodeRaw => statusCode: ${response.statusCode}");
    print("_decodeRaw => body: '${response.body}'"); // ✅ NEW
    print("_decodeRaw => bodyLength: ${response.body.length}"); // ✅ NEW
    try {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (e) {
      print("_decodeRaw => jsonDecode FAILED: $e"); // ✅ NEW
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
    // If server returned a List at the top level, wrap it
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
    print("STATUS CODE => ${response.statusCode}");
    print("RESPONSE BODY => ${response.body}");

    // Reject non-2xx before attempting JSON decode
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Try to extract a message, but don't crash if body isn't JSON
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

  // GET /api/wishlist/
 static Future<List<dynamic>> getWishlist() async {
  final response = await _get(
    ApiConfig.wishlistUrl,
    headers: await _authHeaders(),
  );

  return response["wishlist_items"] ?? [];
}
static Future<void> addToWishlist({
  required int variantId,
}) async {
  await _post(
    ApiConfig.wishlistUrl,
    {
      "variant": variantId,
    },
    headers: await _authHeaders(),
  );
}

  static Future<void> removeFromWishlist({
    required int wishlistId,
  }) async {
    await _delete(
      ApiConfig.wishlistItemUrl(wishlistId),
      headers: await _authHeaders(),
    );
  }
}
