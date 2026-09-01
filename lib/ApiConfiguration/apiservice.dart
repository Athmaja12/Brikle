// lib/ApiConfiguration/apiservice.dart - Complete file with fixes + 401 debug logging

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/Calculation/Model/blockCalculation_model.dart';
import 'package:brikle/Calculation/Model/calculation_model.dart';
import 'package:brikle/Calculation/Model/cementCalculation_model.dart';
import 'package:brikle/Calculation/Model/productCalculator_model.dart';
import 'package:brikle/Calculation/Model/steelCalculation_model.dart';
import 'package:brikle/Calculation/Model/waterproofCalculation_model.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/HomePage/Model/search_model.dart';
import 'package:brikle/Product/Model/productdetails_model.dart';
import 'package:brikle/ProfilePage/Model/address_model.dart';
import 'package:brikle/ProfilePage/Model/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await SessionManager.getAccessToken();
    // FIX: if there's no token yet (e.g. logged out, or called before
    // login completes), the old code sent 'Authorization': 'Bearer null'
    // as a literal string instead of failing predictably. That silently
    // produces a 401 from the server with no useful signal locally.
    // Returning headers without an Authorization key instead makes
    // _wasAuthenticated() correctly report false, so callers don't
    // trigger the refresh-token flow for a request that was never
    // authenticated to begin with.
    if (token == null || token.isEmpty) {
      return {'Content-Type': 'application/json'};
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOKEN REFRESH
  // ══════════════════════════════════════════════════════════════════════════

  static Future<bool>? _refreshFuture;

  static Future<bool> _refreshAccessToken() {
    _refreshFuture ??= _performTokenRefresh().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  static bool _isForcingLogout = false;

  static void _forceLogoutAndRedirect() {
    if (_isForcingLogout) return;
    _isForcingLogout = true;
    Get.offAllNamed('/login');
    Future.delayed(const Duration(seconds: 2), () {
      _isForcingLogout = false;
    });
  }

  static Future<bool> _performTokenRefresh() async {
    final refreshToken = await SessionManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(ApiConfig.tokenRefreshUrl),
            headers: _jsonHeaders,
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // Network failure during refresh — don't clear the session here.
      // The refresh token itself may still be valid; this could just be
      // a dropped connection. Clearing session + force-logout on every
      // transient network blip would log the user out unnecessarily.
      return false;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // 🔎 DEBUG — shows exactly why the refresh call itself was rejected
      // (e.g. expired/invalid refresh token, wrong SECRET_KEY, etc.)
      debugPrint(
        '[ApiService] 🔎 refresh failed (${response.statusCode}): ${response.body}',
      );
      // Refresh token itself was rejected (expired/invalid) — this is
      // the only case that should actually force a logout.
      await SessionManager.clearSession();
      _forceLogoutAndRedirect();
      return false;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // 2xx but unparseable body — treat as a failed refresh rather than
      // crashing, but don't nuke the session for what might be a
      // transient server hiccup returning malformed JSON.
      return false;
    }

    final newAccess = decoded['access']?.toString();
    if (newAccess == null || newAccess.isEmpty) {
      // 2xx but missing the field we need — same reasoning as above.
      return false;
    }

    final newRefresh = decoded['refresh']?.toString();
    await SessionManager.saveSession(
      accessToken: newAccess,
      refreshToken: (newRefresh != null && newRefresh.isNotEmpty)
          ? newRefresh
          : refreshToken,
    );
    return true;
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

    return _patch(ApiConfig.profileUrl, body, headers: await _authHeaders());
  }

  static Future<void> deleteAccount() async {
    await _delete(ApiConfig.deleteAccountUrl, headers: await _authHeaders());
  }

  static Future<double> getTotalSaved() async {
    final response = await _get(
      ApiConfig.totalSavedUrl,
      headers: await _authHeaders(),
    );
    print("total saved ${response}");
    final raw = response['total_saved'];
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
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
    required String requestedDeliveryTime,
    int? couponId,
  }) async {
    final body = <String, dynamic>{
      'pincode': pincode,
      'requested_delivery_date': requestedDeliveryDate,
      'requested_delivery_time': requestedDeliveryTime,
    };
    if (couponId != null) body['coupon_id'] = couponId;
    return _post(ApiConfig.checkoutUrl, body, headers: await _authHeaders());
  }

  static Future<Map<String, dynamic>> placeOrder({
    required String paymentMethod,
    required String shippingAddress,
    required String pincode,
    required String requestedDeliveryDate,
    String? requestedDeliveryTime,
    int? couponId,
    String?
    alternativePhoneNumber, // NEW — was missing entirely; selected coupon never reached this call
  }) async {
    final body = <String, dynamic>{
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
      'pincode': pincode,
      'requested_delivery_date': requestedDeliveryDate,
    };
    if (requestedDeliveryTime != null && requestedDeliveryTime.isNotEmpty) {
      body['requested_delivery_time'] = requestedDeliveryTime;
    }
    if (couponId != null) body['coupon_id'] = couponId;
    return _post(ApiConfig.placeOrderUrl, body, headers: await _authHeaders());
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return _post(ApiConfig.verifyPaymentUrl, {
      'order_id': orderId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    }, headers: await _authHeaders());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CART
  // ══════════════════════════════════════════════════════════════════════════

  /// Headers used for the guest cart.
  ///
  /// Backend identifies a guest cart using:
  ///
  /// X-Device-ID: <device_id>
  ///
  /// If the user is logged in, Authorization is also included.
  static Future<Map<String, String>> _cartHeaders() async {
    final token = await SessionManager.getAccessToken();
    final deviceId = await SessionManager.getGuestDeviceId();

    final headers = <String, String>{'Content-Type': 'application/json'};

    // Logged-in user
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Guest cart / device cart
    if (deviceId != null && deviceId.isNotEmpty) {
      headers['X-Device-ID'] = deviceId;

      debugPrint('[ApiService] 🛒 X-Device-ID => $deviceId');
    } else {
      debugPrint('[ApiService] 🛒 No guest device ID saved yet');
    }

    return headers;
  }

  /// GET guest/customer cart.
  ///
  /// IMPORTANT:
  /// The same X-Device-ID returned by POST /api/cart/add/
  /// must be sent here.
  static Future<Map<String, dynamic>> getCart() async {
    final headers = await _cartHeaders();

    debugPrint('[ApiService] 🛒 GET CART');

    debugPrint('[ApiService] 🛒 URL => ${ApiConfig.cartUrl}');

    debugPrint('[ApiService] 🛒 Headers => $headers');

    final response = await _get(ApiConfig.cartUrl, headers: headers);

    // Backend returns the device_id.
    final deviceId = response['device_id']?.toString();

    if (deviceId != null && deviceId.isNotEmpty) {
      await SessionManager.saveGuestDeviceId(deviceId);

      debugPrint('[ApiService] 🛒 Saved device ID from GET => $deviceId');
    }

    debugPrint('[ApiService] 🛒 Cart response => $response');

    return response;
  }

  /// Add product to cart.
  ///
  /// Backend contract:
  ///
  /// POST /api/cart/add/
  ///
  /// {
  ///   "variant": 1,
  ///   "quantity": 1
  /// }
  ///
  /// Backend returns:
  ///
  /// {
  ///   "message": "Add to the cart!",
  ///   "device_id": "..."
  /// }
  static Future<Map<String, dynamic>> addToCart({
    required int variantId,
    required int quantity,
  }) async {
    final headers = await _cartHeaders();

    debugPrint('[ApiService] 🛒 ADD CART');

    debugPrint('[ApiService] 🛒 URL => ${ApiConfig.cartUrl}');

    debugPrint('[ApiService] 🛒 Headers => $headers');

    debugPrint(
      '[ApiService] 🛒 Body => '
      '{variant: $variantId, quantity: $quantity}',
    );

    final response = await _post(ApiConfig.cartUrl, {
      'variant': variantId,
      'quantity': quantity,
    }, headers: headers);

    // ⭐ CRITICAL
    //
    // Backend creates/returns the guest device ID when the
    // first product is added.
    final deviceId = response['device_id']?.toString();

    if (deviceId != null && deviceId.isNotEmpty) {
      await SessionManager.saveGuestDeviceId(deviceId);

      debugPrint('[ApiService] 🛒 Guest device ID SAVED => $deviceId');
    } else {
      debugPrint('[ApiService] ⚠️ Add cart response did not contain device_id');
    }

    debugPrint('[ApiService] 🛒 ADD CART response => $response');

    return response;
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
  // CALCULATOR - PAINT
  // ══════════════════════════════════════════════════════════════════════════

  static Future<CalculatorListResponse> getCalculatorList() async {
    final response = await _get(
      ApiConfig.calculatorListUrl,
      headers: await _authHeaders(),
    );
    return CalculatorListResponse.fromJson(response);
  }

  static Future<CalculatorDetailModel> getCalculatorDetail(int id) async {
    final response = await _get(
      ApiConfig.calculatorDetailUrl(id),
      headers: await _authHeaders(),
    );
    return CalculatorDetailModel.fromJson(response);
  }

  static Future<List<PaintDropdownItem>> getPaintDropdown() async {
    final response = await _get(
      ApiConfig.paintDropdownUrl,
      headers: await _authHeaders(),
    );
    final paints = response['paints'] as List? ?? [];
    return paints.map((e) => PaintDropdownItem.fromJson(e)).toList();
  }

  static Future<PaintEstimateModel> calculatePaint({
    required int materialId,
    required double wallLength,
    required double wallHeight,
    required int numberOfWalls,
    required int numberOfCoats,
  }) async {
    final response = await _post(ApiConfig.paintCalculateUrl, {
      'material_id': materialId,
      'wall_length': wallLength,
      'wall_height': wallHeight,
      'number_of_walls': numberOfWalls,
      'number_of_coats': numberOfCoats,
    }, headers: await _authHeaders());
    return PaintEstimateModel.fromJson(response);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CALCULATOR - CEMENT
  // ══════════════════════════════════════════════════════════════════════════

  static Future<CementDropdownResponse> getCementDropdown() async {
    final response = await _get(
      ApiConfig.plasteringDropdownUrl,
      headers: await _authHeaders(),
    );
    return CementDropdownResponse.fromJson(response);
  }

  static Future<PlasteringCalculatorResponse> calculatePlastering({
    required double wallArea,
    required double thicknessMm,
    required String mortarRatio,
    required double cementBagPrice,
  }) async {
    final response = await _post(ApiConfig.plasteringCalculateUrl, {
      'wall_area': wallArea,
      'thickness_mm': thicknessMm,
      'mortar_ratio': mortarRatio,
      'cement_bag_price': cementBagPrice,
    }, headers: await _authHeaders());
    return PlasteringCalculatorResponse.fromJson(response);
  }

  static Future<ColumnConcreteCalculatorResponse> calculateColumnConcrete({
    required int numberOfColumns,
    required String concreteGrade,
    required double columnWidthMm,
    required double columnDepthMm,
    required double columnHeightFt,
    required double cementBagPrice,
  }) async {
    final response = await _post(ApiConfig.columnConcreteCalculateUrl, {
      'number_of_columns': numberOfColumns,
      'concrete_grade': concreteGrade,
      'column_width_mm': columnWidthMm,
      'column_depth_mm': columnDepthMm,
      'column_height_ft': columnHeightFt,
      'cement_bag_price': cementBagPrice,
    }, headers: await _authHeaders());
    return ColumnConcreteCalculatorResponse.fromJson(response);
  }

  static Future<RoofSlabCalculatorResponse> calculateRoofSlab({
    required double slabLength,
    required double slabWidth,
    required double thicknessMm,
    required String concreteGrade,
    required double cementBagPrice,
  }) async {
    final response = await _post(ApiConfig.roofSlabCalculateUrl, {
      'slab_length': slabLength,
      'slab_width': slabWidth,
      'thickness_mm': thicknessMm,
      'concrete_grade': concreteGrade,
      'cement_bag_price': cementBagPrice,
    }, headers: await _authHeaders());
    return RoofSlabCalculatorResponse.fromJson(response);
  }

  static Future<SteelCalculatorResponse> calculateSteel({
    required double pricePerKg,
    required List<SteelItem> items,
  }) async {
    final response = await _post(ApiConfig.steelCalculateUrl, {
      'price_per_kg': pricePerKg,
      'items': items.map((e) => e.toJson()).toList(),
    }, headers: await _authHeaders());
    return SteelCalculatorResponse.fromJson(response);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BLOCK CALCULATOR
  // ══════════════════════════════════════════════════════════════════════════

  static Future<BlockDropdownResponse> getBlockDropdown() async {
    final response = await _get(
      ApiConfig.blockDropdownUrl,
      headers: await _authHeaders(),
    );
    return BlockDropdownResponse.fromJson(response);
  }

  static Future<BlockCalculatorResponse> calculateBlock({
    required double wallLengthFt,
    required double wallHeightFt,
    required int wastagePercent,
    required int blockLengthMm,
    required int blockHeightMm,
    required int blockThicknessMm,
  }) async {
    final response = await _post(ApiConfig.blockCalculateUrl, {
      'wall_length_ft': wallLengthFt,
      'wall_height_ft': wallHeightFt,
      'wastage_percent': wastagePercent,
      'block_length_mm': blockLengthMm,
      'block_height_mm': blockHeightMm,
      'block_thickness_mm': blockThicknessMm,
    }, headers: await _authHeaders());
    return BlockCalculatorResponse.fromJson(response);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WATERPROOFING CALCULATOR
  // ══════════════════════════════════════════════════════════════════════════

  static Future<WaterproofingCalculatorResponse> calculateTerraceWaterproofing({
    required double terraceLengthFt,
    required double terraceWidthFt,
    required int coatsApplied,
  }) async {
    final response = await _post(ApiConfig.terraceWaterproofingUrl, {
      'terrace_length_ft': terraceLengthFt,
      'terrace_width_ft': terraceWidthFt,
      'coats_applied': coatsApplied,
    }, headers: await _authHeaders());
    return WaterproofingCalculatorResponse.fromJson(response);
  }

  static Future<WaterproofingCalculatorResponse>
  calculateBathroomWaterproofing({
    required double floorLengthFt,
    required double floorWidthFt,
    required double wallHeightToCoatFt,
  }) async {
    final response = await _post(ApiConfig.bathroomWaterproofingUrl, {
      'floor_length_ft': floorLengthFt,
      'floor_width_ft': floorWidthFt,
      'wall_height_to_coat_ft': wallHeightToCoatFt,
    }, headers: await _authHeaders());
    return WaterproofingCalculatorResponse.fromJson(response);
  }

  static Future<WaterproofingCalculatorResponse> calculateTankWaterproofing({
    required double tankLengthFt,
    required double tankWidthFt,
    required double tankHeightFt,
    required int numberOfWalls,
  }) async {
    final response = await _post(ApiConfig.tankWaterproofingUrl, {
      'tank_length_ft': tankLengthFt,
      'tank_width_ft': tankWidthFt,
      'tank_height_ft': tankHeightFt,
      'number_of_walls': numberOfWalls,
    }, headers: await _authHeaders());
    return WaterproofingCalculatorResponse.fromJson(response);
  }

  static Future<WaterproofingCalculatorResponse> calculateWallWaterproofing({
    required double wallLengthFt,
    required double wallHeightFt,
    required int coatsApplied,
  }) async {
    final response = await _post(ApiConfig.wallWaterproofingUrl, {
      'wall_length_ft': wallLengthFt,
      'wall_height_ft': wallHeightFt,
      'coats_applied': coatsApplied,
    }, headers: await _authHeaders());
    return WaterproofingCalculatorResponse.fromJson(response);
  }

  static Future<WaterproofingCalculatorResponse> calculateLiquidWaterproofing({
    required int numberOfCementBags,
  }) async {
    final response = await _post(ApiConfig.liquidWaterproofingUrl, {
      'number_of_cement_bags': numberOfCementBags,
    }, headers: await _authHeaders());
    return WaterproofingCalculatorResponse.fromJson(response);
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

  // ADD after getBestSelling():
  // ADD a new method specifically for search debugging:
  static Future<List<SearchResultItem>> globalSearch(String query) async {
    final url = ApiConfig.globalSearchUrl(query);
    final headers = await _authHeaders();

    debugPrint('[Search] full URL: $url');
    debugPrint('[Search] headers: $headers');

    http.Response response;
    try {
      response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('[Search] network error: $e');
      throw ApiException('Network error');
    }

    debugPrint('[Search] status code: ${response.statusCode}');
    debugPrint('[Search] raw body: ${response.body}');

    if (response.statusCode != 200) {
      debugPrint('[Search] non-200 response!');
      return [];
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('[Search] decoded keys: ${decoded.keys.toList()}');
      final products = decoded['products'] as List? ?? [];
      debugPrint('[Search] products count: ${products.length}');
      return products.map((e) => SearchResultItem.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[Search] parse error: $e');
      return [];
    }
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

  static Future<CategoryProductItem?> getSuggestedProductDetail(
    int materialId, {
    Map<int, CategoryDetail>? categoryCache,
  }) async {
    final materialJson = await _get(
      ApiConfig.materialDetailUrl(materialId),
      headers: await _authHeaders(),
    );
    final detail = MaterialDetail.fromJson(materialJson);
    final categoryId = detail.categoryId;
    debugPrint(
      '[getSuggestedProductDetail] materialId=$materialId categoryId=$categoryId',
    );
    if (categoryId == null) return null;

    CategoryDetail? categoryDetail = categoryCache?[categoryId];
    if (categoryDetail == null) {
      final categoryJson = await _get(
        ApiConfig.categoryDetailsUrl(categoryId),
        headers: await _authHeaders(),
      );
      categoryDetail = CategoryDetail.fromJson(categoryJson);
      categoryCache?[categoryId] = categoryDetail;
      debugPrint(
        '[getSuggestedProductDetail] categoryId=$categoryId product count=${categoryDetail.products.length}',
      );
      debugPrint(
        '[getSuggestedProductDetail] product materialIds in category: ${categoryDetail.products.map((p) => p.materialId).toList()}',
      );
    }

    final match = categoryDetail.products.firstWhereOrNull(
      (p) => p.materialId == materialId,
    );
    debugPrint(
      '[getSuggestedProductDetail] match for materialId=$materialId: ${match != null}',
    );
    return match;
  }

  /// Get material details by ID
  static Future<Map<String, dynamic>> getMaterialDetails(int materialId) async {
    final response = await _get(
      ApiConfig.materialDetailUrl(materialId),
      headers: await _authHeaders(),
    );
    return response;
  }

  static Future<List<SmartSuggestion>> getMaterialSuggestions(
    int materialId,
  ) async {
    final response = await _get(
      ApiConfig.materialSuggestionsUrl(materialId),
      headers: await _authHeaders(),
    );
    debugPrint(
      '[getMaterialSuggestions] raw response for materialId=$materialId: $response',
    );

    final List list = response['results'] ?? response;
    debugPrint('[getMaterialSuggestions] parsed list length: ${list.length}');

    return list.map((e) => SmartSuggestion.fromJson(e)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADDRESSES (customer's saved delivery addresses)
  // ══════════════════════════════════════════════════════════════════════════

  /// Get all saved addresses for the current user
  static Future<List<DeliveryAddressModel>> getAddresses() async {
    final response = await _get(
      ApiConfig.addressesUrl,
      headers: await _authHeaders(),
    );
    final results = response['results'] as List? ?? [];
    return results.map((e) => DeliveryAddressModel.fromJson(e)).toList();
  }

  /// Get a single address by ID
  static Future<DeliveryAddressModel> getAddressById(int addressId) async {
    final response = await _get(
      ApiConfig.addressByIdUrl(addressId),
      headers: await _authHeaders(),
    );
    return DeliveryAddressModel.fromJson(response);
  }

  /// Add a new delivery address
  static Future<DeliveryAddressModel> addAddress({
    required String pincode,
    required String addressLine,
    bool isPrimary = false,
  }) async {
    final response = await _post(ApiConfig.addressesUrl, {
      'pincode': pincode,
      'address_line': addressLine,
      'is_primary': isPrimary,
    }, headers: await _authHeaders());
    return DeliveryAddressModel.fromJson(response);
  }

  /// Update an existing address (partial update — send only changed fields)
  static Future<DeliveryAddressModel> updateAddress({
    required int addressId,
    String? pincode,
    String? addressLine,
    bool? isPrimary,
  }) async {
    final body = <String, dynamic>{};
    if (pincode != null) body['pincode'] = pincode;
    if (addressLine != null) body['address_line'] = addressLine;
    if (isPrimary != null) body['is_primary'] = isPrimary;

    final response = await _patch(
      ApiConfig.addressByIdUrl(addressId),
      body,
      headers: await _authHeaders(),
    );
    return DeliveryAddressModel.fromJson(response);
  }

  /// Delete a saved address
  static Future<void> deleteAddress(int addressId) async {
    await _delete(
      ApiConfig.addressByIdUrl(addressId),
      headers: await _authHeaders(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WISHLIST
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getWishlist() async {
    final headers =
        await _cartHeaders(); // same X-Device-ID + Bearer pattern as cart
    final deviceId = await SessionManager.getGuestDeviceId();
    final url = ApiConfig.wishlistUrlForDevice(deviceId);

    debugPrint('[ApiService] 💚 GET WISHLIST');
    debugPrint('[ApiService] 💚 URL => $url');
    debugPrint('[ApiService] 💚 Headers => $headers');

    final response = await _get(url, headers: headers);

    final newDeviceId = response['device_id']?.toString().trim();
    if (newDeviceId != null && newDeviceId.isNotEmpty) {
      await SessionManager.saveGuestDeviceId(newDeviceId);
      debugPrint(
        '[ApiService] 💚 Saved device ID from GET wishlist => $newDeviceId',
      );
    }

    debugPrint('[ApiService] 💚 Wishlist response => $response');
    return response['wishlist_items'] as List? ?? [];
  }

  static Future<void> addToWishlist({required int variantId}) async {
    final headers = await _cartHeaders();

    debugPrint('[ApiService] 💚 ADD WISHLIST');
    debugPrint('[ApiService] 💚 URL => ${ApiConfig.wishlistUrl}');
    debugPrint('[ApiService] 💚 Headers => $headers');
    debugPrint('[ApiService] 💚 Body => {variant: $variantId}');

    final response = await _post(ApiConfig.wishlistUrl, {
      'variant': variantId,
    }, headers: headers);

    final deviceId = response['device_id']?.toString().trim();
    if (deviceId != null && deviceId.isNotEmpty) {
      await SessionManager.saveGuestDeviceId(deviceId);
      debugPrint('[ApiService] 💚 Guest device ID SAVED => $deviceId');
    } else {
      debugPrint(
        '[ApiService] ⚠️ Add wishlist response did not contain device_id',
      );
    }

    debugPrint('[ApiService] 💚 ADD WISHLIST response => $response');
  }

  static Future<void> removeFromWishlist({required int variantId}) async {
    final headers = await _cartHeaders();
    final deviceId = await SessionManager.getGuestDeviceId();
    final url = ApiConfig.wishlistItemUrl(variantId, deviceId: deviceId);

    debugPrint('[ApiService] 💚 REMOVE WISHLIST variantId=$variantId');
    debugPrint('[ApiService] 💚 URL => $url');
    debugPrint('[ApiService] 💚 Headers => $headers');

    await _delete(url, headers: headers);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COUPONS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<CouponModel>> getMyCoupons() async {
    final response = await _get(
      ApiConfig.myCouponsUrl,
      headers: await _authHeaders(),
    );
    final results = response['results'] as List? ?? [];
    return results.map((e) => CouponModel.fromJson(e)).toList();
  }
  // lib/ApiConfiguration/apiservice.dart

  // Update the shareCoupon method to make recipient_phone optional
  // lib/ApiConfiguration/apiservice.dart

  static Future<ShareCouponResponse> shareCoupon({
    required String couponCode,
    required String recipientPhone, // was optional — now always sent
  }) async {
    debugPrint('[ApiService] shareCoupon called with couponCode: $couponCode');

    final body = <String, dynamic>{
      'coupon_code': couponCode,
      'recipient_phone': recipientPhone,
    };

    debugPrint('[ApiService] Request body: $body');
    debugPrint('[ApiService] URL: ${ApiConfig.shareCouponUrl}');

    try {
      final response = await _postExpectingBody(
        ApiConfig.shareCouponUrl,
        body,
        headers: await _authHeaders(),
      );

      debugPrint('[ApiService] Response: $response');

      if (response.containsKey('success')) {
        return ShareCouponResponse.fromJson(response);
      }

      final fallbackMessage =
          _extractErrorMessage(response) ??
          'Failed to share coupon. Please try again.';
      return ShareCouponResponse(success: false, message: fallbackMessage);
    } catch (e) {
      debugPrint('[ApiService] shareCoupon error: $e');
      rethrow;
    }
  }
  // ══════════════════════════════════════════════════════════════════════════
  // ORDERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Get all orders for the current user (Flipkart-style order list)
  static Future<List<OrderModel>> getMyOrders() async {
    final response = await _get(
      ApiConfig.myOrdersUrl,
      headers: await _authHeaders(),
    );

    final results = response['results'] as List? ?? [];
    return results.map((e) => OrderModel.fromJson(e)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REVIEWS & RATINGS
  // ══════════════════════════════════════════════════════════════════════════

  /// Submit a review & rating for a whole ORDER (Flipkart-style).
  /// POST /api/orders/{orderId}/review/
  static Future<OrderReviewResponse> postOrderReview({
    required int orderId,
    required int rating,
    required String comment,
  }) async {
    debugPrint('[ApiService] postOrderReview($orderId, rating: $rating)');
    try {
      final response = await _post(ApiConfig.orderReviewUrl(orderId), {
        'rating': rating,
        'comment': comment,
      }, headers: await _authHeaders());

      debugPrint('[ApiService] postOrderReview response: $response');
      return OrderReviewResponse(
        success: true,
        message: 'Review submitted successfully',
        review: OrderReviewModel.fromJson(response),
      );
    } on ApiException catch (e) {
      debugPrint('[ApiService] postOrderReview ApiException: ${e.message}');
      // 400 here is almost always "already reviewed" or a validation error —
      // e.message already carries the server's real reason (see
      // _extractErrorMessage), so just surface it instead of masking it.
      return OrderReviewResponse(
        success: false,
        message: e.message.isNotEmpty
            ? e.message
            : 'You have already reviewed this order.',
      );
    } catch (e) {
      debugPrint('[ApiService] postOrderReview unexpected error: $e');
      return OrderReviewResponse(
        success: false,
        message: 'Failed to submit review. Please try again.',
      );
    }
  }

  // /// Get all reviews for a material (like Flipkart product reviews)
  // static Future<List<ReviewModel>> getMaterialReviews(int materialId) async {
  //   debugPrint('[ApiService] getMaterialReviews($materialId)');
  //   final response = await _get(
  //     ApiConfig.materialReviewsUrl(materialId),
  //     headers: await _authHeaders(),
  //   );

  //   debugPrint('[ApiService] getMaterialReviews response: $response');

  //   // // Handle different response formats
  //   // if (response is List) {
  //   //   return response.map((e) => ReviewModel.fromJson(e)).toList();
  //   // }

  //   final results = response['results'] as List? ?? [];
  //   return results.map((e) => ReviewModel.fromJson(e)).toList();
  // }

  // /// Post a review for a material (like Flipkart rating)
  // static Future<ReviewResponseModel> postMaterialReview({
  //   required int materialId,
  //   required int rating,
  //   required String comment,
  // }) async {
  //   debugPrint('[ApiService] postMaterialReview($materialId, rating: $rating)');

  //   try {
  //     final response = await _post(ApiConfig.materialReviewsUrl(materialId), {
  //       'rating': rating,
  //       'comment': comment,
  //     }, headers: await _authHeaders());

  //     debugPrint('[ApiService] postMaterialReview response: $response');
  //     return ReviewResponseModel.fromJson(response);
  //   } on ApiException catch (e) {
  //     debugPrint('[ApiService] postMaterialReview ApiException: ${e.message}');

  //     // If it's a 400 error, it might be "already reviewed"
  //     if (e.statusCode == 400) {
  //       return ReviewResponseModel(
  //         success: false,
  //         message: 'You have already reviewed this product.',
  //         review: null,
  //       );
  //     }

  //     return ReviewResponseModel(
  //       success: false,
  //       message: e.message,
  //       review: null,
  //     );
  //   } catch (e) {
  //     debugPrint('[ApiService] postMaterialReview error: $e');
  //     return ReviewResponseModel(
  //       success: false,
  //       message: 'Failed to submit review. Please try again.',
  //       review: null,
  //     );
  //   }
  // }
  // ══════════════════════════════════════════════════════════════════════════
  // HTTP HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static bool _wasAuthenticated(Map<String, String>? headers) {
    return headers != null && headers.containsKey('Authorization');
  }

  static Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, String>? headers,
    bool isRetry = false,
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

    if (response.statusCode == 401) {
      // 🔎 DEBUG — shows Django's actual rejection reason instead of
      // just the generic "session expired" message the app shows.
      debugPrint('[ApiService] 🔎 401 raw body (GET $url): ${response.body}');
    }

    if (response.statusCode == 401 && _wasAuthenticated(headers) && !isRetry) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _get(url, headers: await _authHeaders(), isRetry: true);
      }
      throw ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        sessionExpired: true,
      );
    }

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool isRetry = false,
  }) async {
    http.Response response;
    try {
      debugPrint('[ApiService] POST URL => $url');
      debugPrint('[ApiService] POST BODY => $body');

      response = await http
          .post(
            Uri.parse(url),
            headers: headers ?? _jsonHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('[ApiService] POST STATUS => ${response.statusCode}');

      debugPrint('[ApiService] POST RESPONSE => ${response.body}');
    } on TimeoutException catch (e) {
      debugPrint('[ApiService] POST TIMEOUT => $url');
      debugPrint('[ApiService] ERROR => $e');

      throw const ApiException('Server request timed out. Please try again.');
    } on SocketException catch (e) {
      debugPrint('[ApiService] POST SOCKET ERROR => $url');
      debugPrint('[ApiService] ERROR => $e');

      throw const ApiException(
        'Unable to connect to the server. Please check your internet connection.',
      );
    } catch (e, stack) {
      debugPrint('[ApiService] POST NETWORK ERROR => $url');
      debugPrint('[ApiService] ERROR TYPE => ${e.runtimeType}');
      debugPrint('[ApiService] ERROR => $e');
      debugPrint('[ApiService] STACK => $stack');

      throw ApiException('Unable to connect to the server. Please try again.');
    }

    if (response.statusCode == 401) {
      // 🔎 DEBUG
      debugPrint('[ApiService] 🔎 401 raw body (POST $url): ${response.body}');
    }

    if (response.statusCode == 401 && _wasAuthenticated(headers) && !isRetry) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _post(url, body, headers: await _authHeaders(), isRetry: true);
      }
      throw ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        sessionExpired: true,
      );
    }

    return _handleResponse(response);
  }

  /// Like _post, but never throws on 4xx — decodes and returns whatever
  /// JSON body the server sent regardless of status code. Needed for
  /// endpoints (like share-coupon) whose contract is "always respond with
  /// {success, message}", where a 400 for a business-rule failure (e.g.
  /// recipient not registered) still carries a real, useful message that
  /// the generic _handleResponse()/_extractErrorMessage() path was
  /// discarding in favor of a generic "Something went wrong" fallback.
  static Future<Map<String, dynamic>> _postExpectingBody(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool isRetry = false,
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

    if (response.statusCode == 401) {
      // 🔎 DEBUG
      debugPrint(
        '[ApiService] 🔎 401 raw body (POST-expecting-body $url): ${response.body}',
      );
    }

    if (response.statusCode == 401 && _wasAuthenticated(headers) && !isRetry) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _postExpectingBody(
          url,
          body,
          headers: await _authHeaders(),
          isRetry: true,
        );
      }
      throw ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        sessionExpired: true,
      );
    }

    try {
      return _decode(response);
    } catch (_) {
      throw ApiException(
        'Something went wrong (code ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
  }

  static Future<Map<String, dynamic>> _patch(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool isRetry = false,
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

    if (response.statusCode == 401) {
      // 🔎 DEBUG
      debugPrint('[ApiService] 🔎 401 raw body (PATCH $url): ${response.body}');
    }

    if (response.statusCode == 401 && _wasAuthenticated(headers) && !isRetry) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _patch(url, body, headers: await _authHeaders(), isRetry: true);
      }
      throw ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        sessionExpired: true,
      );
    }

    return _handleResponse(response);
  }

  static Future<void> _delete(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool isRetry = false,
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

    if (response.statusCode == 401) {
      // 🔎 DEBUG
      debugPrint(
        '[ApiService] 🔎 401 raw body (DELETE $url): ${response.body}',
      );
    }

    if (response.statusCode == 401 && _wasAuthenticated(headers) && !isRetry) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        await _delete(
          url,
          body: body,
          headers: await _authHeaders(),
          isRetry: true,
        );
        return;
      }
      throw ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        sessionExpired: true,
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
    try {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (e) {
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
