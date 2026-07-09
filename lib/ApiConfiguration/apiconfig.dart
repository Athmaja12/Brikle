// lib/Core/api_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static String get registerUrl => '$baseUrl/api/customer-register/';
  static String get verifyOtpUrl => '$baseUrl/api/customer-verify-otp/';
  static String get resendOtpUrl => '$baseUrl/api/customer-resend-otp/';
  static String get loginUrl => '$baseUrl/api/customer-login/';
  static String get loginVerifyUrl => '$baseUrl/api/customer-login-verify/';
  static String get logoutUrl => '$baseUrl/api/customer-logout/';

  // ── Profile ────────────────────────────────────────────────────────────────
  static String get profileUrl => '$baseUrl/api/customer-profile/';
  static String get profileEditUrl => '$baseUrl/api/customer-profile/edit/';
  static String get deleteAccountUrl => '$baseUrl/api/customer-delete-account/';

  // ── Addresses ──────────────────────────────────────────────────────────────
  static String get addressListUrl => '$baseUrl/api/customer/addresses/';
  static String addressDetailUrl(String id) =>
      '$baseUrl/api/customer/addresses/$id/';

  // ── Products ───────────────────────────────────────────────────────────────
  static String get customerProductsUrl => '$baseUrl/api/customer/products/';

  static String productPriceTiersUrl(int productId) =>
      '$baseUrl/api/customer-products/$productId/price-tiers/';
  // ── Cart ───────────────────────────────────────────────────────────────────
  // GET → Fetch cart items
  static String get cartUrl => '$baseUrl/api/cart/add/';

  // POST → Add item
  static String get addToCartUrl => '$baseUrl/api/cart/add/';

  // PATCH / DELETE → Single cart item
  static String cartItemUrl(int productId) =>
      '$baseUrl/api/cart/add/$productId/';

  static String get carouselUrl => '$baseUrl/api/carousels/';
  static String get categoriesUrl => '$baseUrl/api/superadmin/categories/';
  static String get dealsOfWeekUrl => '$baseUrl/api/deals-of-the-week/';
  static String bestSellingUrl(int categoryId) =>
      '$baseUrl/api/best-selling/?category_id=$categoryId';

  static String categoryDetailsUrl(int categoryId) =>
      '$baseUrl/api/categories/$categoryId/details/';
  static String categoryFilterOptionsUrl(int categoryId) =>
      '$baseUrl/api/categories/filter-options/?category_id=$categoryId';

  // ── Address ─────────────────────────────────────────────
  static String get addressesUrl => '$baseUrl/api/customer/addresses/';

  static String addressByIdUrl(int id) =>
      '$baseUrl/api/customer/addresses/$id/';

  // ── Coupon ──────────────────────────────────────────────
  static String get applyCouponUrl => '$baseUrl/api/apply-coupon/';

  // ── Checkout ────────────────────────────────────────────
  static String get checkoutUrl => '$baseUrl/api/customer/checkout/';

  // ── Pincode ─────────────────────────────────────────────
  static String get checkPincodeUrl => '$baseUrl/api/customer-check-pincode/';
  // ── Orders ──────────────────────────────────────────────
  static String get customerOrdersUrl => '$baseUrl/api/customer-orders/';
  static String customerOrderDetailUrl(int orderId) =>
      '$baseUrl/api/customer-orders/$orderId/';

  // ── Wishlist ───────────────────────────────────────────────────────────────
  static String get wishlistUrl => '$baseUrl/api/wishlist/';
  static String wishlistItemUrl(int productId) =>
      '$baseUrl/api/wishlist/$productId/';
  static String wishlistMoveToCartUrl(int productId) =>
      '$baseUrl/api/wishlist/$productId/move-to-cart/';
  static String get wishlistMoveAllToCartUrl =>
      '$baseUrl/api/wishlist/move-all-to-cart/';
}

/// Thrown by ApiService on network errors or non-2xx responses.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
