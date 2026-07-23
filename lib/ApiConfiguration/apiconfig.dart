// lib/Core/api_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  ApiConfig._();

  /// Base URL from .env
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  // ==========================================================================
  // AUTH
  // ==========================================================================

  static String get registerUrl => '$baseUrl/api/customer-register/';
  static String get verifyOtpUrl => '$baseUrl/api/customer-verify-otp/';
  static String get resendOtpUrl => '$baseUrl/api/customer-resend-otp/';
  static String get loginUrl => '$baseUrl/api/customer-login/';
  static String get loginVerifyUrl => '$baseUrl/api/customer-login-verify/';
  static String get logoutUrl => '$baseUrl/api/customer-logout/';

  /// JWT Refresh Token
  static String get tokenRefreshUrl => '$baseUrl/api/token/refresh/';
  // ==========================================================================
  // PROFILE
  // ==========================================================================

  static String get profileUrl => '$baseUrl/api/customer-profile/';
  static String get profileEditUrl => '$baseUrl/api/customer-profile/';
  static String get deleteAccountUrl => '$baseUrl/api/customer-delete-account/';

  // ==========================================================================
  // ADDRESS (multi-address book — separate from the single profile address)
  // ==========================================================================

  static String get addressesUrl => '$baseUrl/api/addresses/';

  static String addressByIdUrl(int id) => '$baseUrl/api/addresses/$id/';

  // ==========================================================================
  // PRODUCTS
  // ==========================================================================

  static String get customerProductsUrl => '$baseUrl/api/customer/products/';

  static String productPriceTiersUrl(int productId) =>
      '$baseUrl/api/customer-products/$productId/price-tiers/';

  static String materialDetailUrl(int materialId) =>
      '$baseUrl/api/superadmin/materials/$materialId/';

  static String materialSuggestionsUrl(int materialId) =>
      '$baseUrl/api/materials/$materialId/suggestions/';
  // ==========================================================================
  // HOME
  // ==========================================================================

  static String get carouselUrl => '$baseUrl/api/carousels/';

  static String get categoriesUrl => '$baseUrl/api/superadmin/categories/';

  static String get dealsOfWeekUrl => '$baseUrl/api/deals-of-the-week/';

  static String bestSellingUrl(int categoryId) =>
      '$baseUrl/api/best-selling/?category_id=$categoryId';

  static String categoryDetailsUrl(int categoryId) =>
      '$baseUrl/api/categories/$categoryId/details/';

  static String categoryFilterOptionsUrl(int categoryId) =>
      '$baseUrl/api/categories/filter-options/?category_id=$categoryId';

  // ==========================================================================
  // CART
  // ==========================================================================

  static String get cartUrl => '$baseUrl/api/cart/add/';

  // ==========================================================================
  // CHECKOUT
  // ==========================================================================

  static String get checkoutUrl => '$baseUrl/api/checkout/';

  static String get placeOrderUrl => '$baseUrl/api/order/place/';

  // ==========================================================================
  // PINCODE
  // ==========================================================================

  static String get checkPincodeUrl => '$baseUrl/api/customer-check-pincode/';

  // ==========================================================================
  // VEHICLES
  // ==========================================================================

  static String get availableVehiclesUrl =>
      '$baseUrl/api/user/vehicles/available/';

  // ==========================================================================
  // COUPONS
  // ==========================================================================

  static String get myCouponsUrl => '$baseUrl/api/user/my-coupons/';
  static String get shareCouponUrl => '$baseUrl/api/my-coupons/share/';

  // ==========================================================================
  // ORDERS
  // ==========================================================================

  static String get customerOrdersUrl => '$baseUrl/api/customer-orders/';

  static String customerOrderDetailUrl(int orderId) =>
      '$baseUrl/api/customer-orders/$orderId/';

  // ==========================================================================
  // WISHLIST
  // ==========================================================================

  static String get wishlistUrl => '$baseUrl/api/wishlist/';

  static String wishlistItemUrl(int variantId) =>
      '$baseUrl/api/wishlist/$variantId/';

  // ==========================================================================
  // CALCULATORS
  // ==========================================================================

  /// Calculator List
  static String get calculatorListUrl => '$baseUrl/api/calculator/';

  static String calculatorDetailUrl(int id) => '$baseUrl/api/calculator/$id/';

  // ---------------- Paint ----------------

  static String get paintDropdownUrl => '$baseUrl/api/paint/drop-down/';

  static String get paintCalculateUrl => '$baseUrl/api/calculator/paint/';

  // ---------------- Plastering ----------------

  static String get plasteringDropdownUrl => '$baseUrl/api/cement/drop-down/';

  static String get plasteringCalculateUrl =>
      '$baseUrl/api/calculator/plastering/';

  // ---------------- Column Concrete ----------------

  static String get columnConcreteCalculateUrl =>
      '$baseUrl/api/calculator/Column-concrete/';

  // ---------------- Roof Slab ----------------

  static String get roofSlabCalculateUrl =>
      '$baseUrl/api/calculator/roof-slab/';

  // ---------------- Steel ----------------

  static String get steelCalculateUrl => '$baseUrl/api/calculator/steel/';

  // ---------------- Block ----------------

  static String get blockDropdownUrl => '$baseUrl/api/block/drop-down/';

  static String get blockCalculateUrl => '$baseUrl/api/calculator/block/';

  // ---------------- Waterproofing ----------------

  static String get terraceWaterproofingUrl =>
      '$baseUrl/api/calculator/terrace-waterproofing/';

  static String get bathroomWaterproofingUrl =>
      '$baseUrl/api/calculator/bathroom-waterproofing/';

  static String get tankWaterproofingUrl =>
      '$baseUrl/api/calculator/tank-waterproofing/';

  static String get wallWaterproofingUrl =>
      '$baseUrl/api/calculator/wall-waterproofing/';

  static String get liquidWaterproofingUrl =>
      '$baseUrl/api/calculator/lw-waterproofing/';

  // ==========================================================================
  // ORDERS
  // ==========================================================================

  static String get myOrdersUrl => '$baseUrl/api/my-orders/';

  // ==========================================================================
  // REVIEWS & RATINGS
  // ==========================================================================

  static String materialReviewsUrl(int materialId) =>
      '$baseUrl/api/materials/$materialId/reviews/';
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// True only when the refresh token has expired or is invalid.
  /// Use this to redirect the user to Login.
  final bool sessionExpired;

  const ApiException(
    this.message, {
    this.statusCode,
    this.sessionExpired = false,
  });

  @override
  String toString() => message;
}
