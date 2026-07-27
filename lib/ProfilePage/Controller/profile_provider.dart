// lib/ProfilePage/Controller/profile_controller.dart

import 'dart:async';

import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/ProfilePage/Model/address_model.dart';
import 'package:brikle/ProfilePage/Model/order_model.dart';
import 'package:brikle/ProfilePage/Model/profile_model.dart';
// Import CouponModel from address_model.dart
import 'package:brikle/AddtoCart/Model/address_model.dart'; // <-- ADD THIS
import 'package:brikle/ProfilePage/Model/review_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final Rx<ProfileModel> profile = ProfileModel().obs;
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  // Coupons - Uses CouponModel from address_model.dart
  final RxList<CouponModel> coupons = <CouponModel>[].obs;
  final RxBool isCouponLoading = false.obs;
  // Orders - NEW
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxBool isOrdersLoading = false.obs;
  // Delivery Addresses (multi-address book)
  final RxList<DeliveryAddressModel> addresses = <DeliveryAddressModel>[].obs;
  final RxBool isAddressesLoading = false.obs;
  final RxBool isAddressSaving = false.obs;

  // Reviews - NEW
  final RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  final RxBool isReviewsLoading = false.obs;
  final RxBool isReviewSubmitting = false.obs;

  // ── Convenience getters ────────────────────────────────────────────────────
  String get fullName => profile.value.fullName;
  String get phoneNumber => profile.value.phoneNumber;
  String get email => profile.value.email ?? '';
  String get address => profile.value.address;
  String get pincode => profile.value.pincode;
  bool get isVerified => profile.value.isVerified;

  static final RegExp _gstRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  bool isGstValid(String gst) => _gstRegex.hasMatch(gst.trim().toUpperCase());

  bool get isPhoneRegistered =>
      profile.value.registrationType == 'phone' &&
      profile.value.hasRealPhoneNumber;

  bool get canEditPhoneNumber => !isPhoneRegistered;

  bool get isManualEntry => profile.value.registrationType == 'manual';

  // Use this instead of `phoneNumber` anywhere the UI shows/prefills it.
  String get displayPhoneNumber => profile.value.displayPhoneNumber;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    debugPrint('[ProfileController] onInit');
    fetchProfile();
    fetchCoupons();
    fetchOrders();
    fetchAddresses();
  }

  Future<void> refreshOnProfileOpen() async {
    if (isManualEntry) {
      await fetchProfile();
    } else {
      unawaited(fetchProfile());
    }
  }
  // ══════════════════════════════════════════════════════════════════════════
  // SHARED SNACKBAR HELPER
  // ══════════════════════════════════════════════════════════════════════════

  void _showStatusSnackbar(String message, {bool isError = false}) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchProfile() async {
    debugPrint('[ProfileController] fetchProfile()');
    isLoading.value = true;
    try {
      final response = await ApiService.getProfile();
      debugPrint('[ProfileController] fetchProfile SUCCESS → $response');
      profile.value = ProfileModel.fromJson(response);
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] fetchProfile ApiException → ${e.message}',
      );
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] fetchProfile unexpected → $e');
      Get.snackbar('Error', 'Failed to load profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? pincode,
    String? customerType,
    String? gstNumber,
  }) async {
    debugPrint('[ProfileController] updateProfile()');
    isUpdating.value = true;
    try {
      final response = await ApiService.updateProfile(
        fullName: fullName,
        email: email,
        // Only ever send a phone number if this account is actually
        // allowed to change it — belt-and-braces on top of the UI gate.
        phoneNumber: canEditPhoneNumber ? phoneNumber : null,
        address: address,
        pincode: pincode,
        customerType: customerType,
        gstNumber: gstNumber,
      );

      debugPrint('[ProfileController] updateProfile RESPONSE → $response');

      await fetchProfile();
      _showStatusSnackbar('Profile updated successfully');
      return true;
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] updateProfile ApiException → ${e.message}',
      );
      _showStatusSnackbar(e.message, isError: true);
      return false;
    } catch (e) {
      debugPrint('[ProfileController] updateProfile unexpected → $e');
      _showStatusSnackbar(
        'Failed to update profile. Please try again.',
        isError: true,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> logout() async {
    debugPrint('[ProfileController] logout()');
    final confirmed = await _confirm(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
    );
    if (!confirmed) return;

    try {
      final refreshToken = await SessionManager.getRefreshToken();
      if (refreshToken != null) {
        await ApiService.logout(refreshToken: refreshToken);
        debugPrint('[ProfileController] logout API SUCCESS');
      }
      await SessionManager.clearSession();
      debugPrint('[ProfileController] session cleared — going to /login');
      Get.offAllNamed('/login');
    } on ApiException catch (e) {
      debugPrint('[ProfileController] logout ApiException → ${e.message}');
      await SessionManager.clearSession();
      Get.offAllNamed('/login');
    } catch (e) {
      debugPrint('[ProfileController] logout unexpected → $e');
      await SessionManager.clearSession();
      Get.offAllNamed('/login');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DELETE ACCOUNT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> deleteAccount() async {
    debugPrint('[ProfileController] deleteAccount()');
    final confirmed = await _confirm(
      title: 'Delete Account',
      message:
          'This will permanently delete your account and all data. This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    isDeleting.value = true;
    try {
      await ApiService.deleteAccount();
      debugPrint('[ProfileController] deleteAccount SUCCESS');
      await SessionManager.clearSession();
      Get.offAllNamed('/login');
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] deleteAccount ApiException → ${e.message}',
      );
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] deleteAccount unexpected → $e');
      Get.snackbar('Error', 'Failed to delete account. Please try again.');
    } finally {
      isDeleting.value = false;
    }
  }
  // ══════════════════════════════════════════════════════════════════════════
  // ORDERS - NEW (Flipkart-style)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchOrders() async {
    debugPrint('[ProfileController] fetchOrders()');
    isOrdersLoading.value = true;

    try {
      final response = await ApiService.getMyOrders();
      // Print the raw response to see the data structure
      debugPrint('[ProfileController] fetchOrders RAW RESPONSE: $response');

      orders.clear();
      orders.addAll(response);
      debugPrint('[ProfileController] Orders Loaded => ${orders.length}');
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] fetchOrders ApiException => ${e.message}',
      );
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] fetchOrders unexpected => $e');
      Get.snackbar('Error', 'Failed to load orders.');
    } finally {
      isOrdersLoading.value = false;
    }
  }

  OrderModel? getOrderById(int orderId) {
    try {
      return orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REVIEWS - NEW (Flipkart-style)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchReviews(int materialId) async {
    debugPrint('[ProfileController] fetchReviews($materialId)');

    isReviewsLoading.value = true;

    try {
      final List<ReviewModel> reviewList = await ApiService.getMaterialReviews(
        materialId,
      );
      reviews.clear();
      reviews.addAll(reviewList);
      debugPrint('[ProfileController] Reviews Loaded => ${reviews.length}');
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] fetchReviews ApiException => ${e.message}',
      );
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] fetchReviews unexpected => $e');
      Get.snackbar('Error', 'Failed to load reviews.');
    } finally {
      isReviewsLoading.value = false;
    }
  }

  Future<bool> submitReview({
    required int materialId,
    required int rating,
    required String comment,
  }) async {
    debugPrint(
      '[ProfileController] submitReview(materialId: $materialId, rating: $rating)',
    );

    isReviewSubmitting.value = true;

    try {
      final ReviewResponseModel response = await ApiService.postMaterialReview(
        materialId: materialId,
        rating: rating,
        comment: comment,
      );

      if (response.success) {
        // Re-fetch from GET /api/materials/{id}/reviews/ so what the user
        // sees always matches the server, rather than trusting the local
        // POST response shape.
        await fetchReviews(materialId);
        _showStatusSnackbar(response.message);
        return true;
      } else {
        _showStatusSnackbar(response.message, isError: true);
        return false;
      }
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] submitReview ApiException => ${e.message}',
      );
      _showStatusSnackbar(e.message, isError: true);
      return false;
    } catch (e) {
      debugPrint('[ProfileController] submitReview unexpected => $e');
      _showStatusSnackbar(
        'Failed to submit review. Please try again.',
        isError: true,
      );
      return false;
    } finally {
      isReviewSubmitting.value = false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── FIXED: fetchCoupons method ────────────────────────────────────────────
  Future<void> fetchCoupons() async {
    debugPrint('[ProfileController] fetchCoupons()');

    isCouponLoading.value = true;

    try {
      // ApiService.getMyCoupons() returns List<CouponModel> from address_model.dart
      final List<CouponModel> couponList = await ApiService.getMyCoupons();

      // Clear and add all coupons
      coupons.clear();
      coupons.addAll(couponList);

      debugPrint('[ProfileController] Coupons Loaded => ${coupons.length}');
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] fetchCoupons ApiException => ${e.message}',
      );
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] fetchCoupons unexpected => $e');
      Get.snackbar('Error', 'Failed to load coupons.');
    } finally {
      isCouponLoading.value = false;
    }
  }

  Future<ShareCouponResponse> shareCoupon({
    required String couponCode,
    required String recipientPhone,
  }) async {
    debugPrint(
      '[ProfileController] shareCoupon($couponCode -> $recipientPhone)',
    );
    try {
      final result = await ApiService.shareCoupon(
        couponCode: couponCode,
        recipientPhone: recipientPhone,
      );
      if (result.success) {
        // Remove immediately from the local list so the UI updates the
        // instant the user sees the success snackbar, instead of waiting
        // on a full fetchCoupons() round-trip to reflect it.
        coupons.removeWhere((c) => c.couponCode == couponCode);

        // Still resync with the server in the background — covers cases
        // like server-side side effects (e.g. earning a new coupon back)
        // that a purely local removal wouldn't know about.
        unawaited(fetchCoupons());
      }
      return result;
    } on ApiException catch (e) {
      debugPrint('[ProfileController] shareCoupon failed: ${e.message}');
      return ShareCouponResponse(success: false, message: e.message);
    } catch (e) {
      debugPrint('[ProfileController] shareCoupon unexpected error: $e');
      return ShareCouponResponse(
        success: false,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADDRESSES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchAddresses() async {
    debugPrint('[ProfileController] fetchAddresses()');
    isAddressesLoading.value = true;
    try {
      final list = await ApiService.getAddresses();
      addresses.clear();
      addresses.addAll(list);
      debugPrint('[ProfileController] Addresses Loaded => ${addresses.length}');
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] fetchAddresses unexpected => $e');
      Get.snackbar('Error', 'Failed to load addresses.');
    } finally {
      isAddressesLoading.value = false;
    }
  }

  Future<bool> addAddress({
    required String pincode,
    required String addressLine,
    bool isPrimary = false,
  }) async {
    isAddressSaving.value = true;
    try {
      final created = await ApiService.addAddress(
        pincode: pincode,
        addressLine: addressLine,
        isPrimary: isPrimary,
      );
      // If this was set as primary, reflect that locally on the rest too
      if (isPrimary) {
        for (var i = 0; i < addresses.length; i++) {
          if (addresses[i].isPrimary) {
            addresses[i] = addresses[i].copyWith(isPrimary: false);
          }
        }
      }
      addresses.add(created);
      _showStatusSnackbar('Address added successfully');
      return true;
    } on ApiException catch (e) {
      _showStatusSnackbar(e.message, isError: true);
      return false;
    } catch (e) {
      debugPrint('[ProfileController] addAddress unexpected => $e');
      _showStatusSnackbar(
        'Failed to add address. Please try again.',
        isError: true,
      );
      return false;
    } finally {
      isAddressSaving.value = false;
    }
  }

  Future<bool> updateAddress({
    required int addressId,
    String? pincode,
    String? addressLine,
    bool? isPrimary,
  }) async {
    isAddressSaving.value = true;
    try {
      final updated = await ApiService.updateAddress(
        addressId: addressId,
        pincode: pincode,
        addressLine: addressLine,
        isPrimary: isPrimary,
      );

      if (isPrimary == true) {
        for (var i = 0; i < addresses.length; i++) {
          if (addresses[i].id != addressId && addresses[i].isPrimary) {
            addresses[i] = addresses[i].copyWith(isPrimary: false);
          }
        }
      }

      final index = addresses.indexWhere((a) => a.id == addressId);
      if (index != -1) {
        addresses[index] = updated;
      }

      _showStatusSnackbar('Address updated successfully');
      return true;
    } on ApiException catch (e) {
      _showStatusSnackbar(e.message, isError: true);
      return false;
    } catch (e) {
      debugPrint('[ProfileController] updateAddress unexpected => $e');
      _showStatusSnackbar(
        'Failed to update address. Please try again.',
        isError: true,
      );
      return false;
    } finally {
      isAddressSaving.value = false;
    }
  }

  /// Convenience: mark one address primary (others auto-demoted server-side
  /// or locally, depending on backend behavior).
  Future<bool> setPrimaryAddress(int addressId) {
    return updateAddress(addressId: addressId, isPrimary: true);
  }

  Future<bool> deleteAddress(int addressId) async {
    final confirmed = await _confirm(
      title: 'Delete Address',
      message: 'Are you sure you want to remove this address?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return false;

    try {
      await ApiService.deleteAddress(addressId);
      addresses.removeWhere((a) => a.id == addressId);
      _showStatusSnackbar('Address removed');
      return true;
    } on ApiException catch (e) {
      _showStatusSnackbar(e.message, isError: true);
      return false;
    } catch (e) {
      debugPrint('[ProfileController] deleteAddress unexpected => $e');
      _showStatusSnackbar(
        'Failed to remove address. Please try again.',
        isError: true,
      );
      return false;
    }
  }

  DeliveryAddressModel? get primaryAddress {
    try {
      return addresses.firstWhere((a) => a.isPrimary);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  @override
  void onClose() {
    debugPrint('[ProfileController] onClose');
    super.onClose();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchProfile(), fetchCoupons()]);
  }
}
