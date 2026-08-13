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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final RxBool isSubmittingReview = false.obs;

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

    _loadUserDataIfLoggedIn();
  }

  Future<void> _loadUserDataIfLoggedIn() async {
    final loggedIn = await SessionManager.isLoggedIn();

    debugPrint(
      '[ProfileController] Session status => '
      '${loggedIn ? "LOGGED IN" : "GUEST"}',
    );

    if (!loggedIn) {
      debugPrint(
        '[ProfileController] Guest user detected -> '
        'skipping profile, coupons, orders and addresses',
      );
      return;
    }

    await loadUserDataAfterLogin();
  }

  Future<void> loadUserDataAfterLogin() async {
    try {
      debugPrint('[ProfileController] Loading authenticated user data...');

      await Future.wait([
        fetchProfile(),
        fetchCoupons(),
        fetchOrders(),
        fetchAddresses(),
      ]);

      debugPrint(
        '[ProfileController] Authenticated user data loaded successfully',
      );
    } catch (e) {
      debugPrint('[ProfileController] loadUserDataAfterLogin error => $e');
    }
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

      // DEBUG — dump every order's parsed items so we can see exactly
      // what fields OrderItemModel captured (or silently dropped) from
      // the raw JSON above. This is the key thing to check when reviews
      // fail with "You can only review products you have actually
      // purchased" — item.variant is being used as a material id lookup
      // key, which may not be correct.
      for (final order in orders) {
        debugPrint(
          '[ProfileController] Order #${order.id} status=${order.orderStatus} '
          'materialId(order-level, likely unused/wrong)=${order.materialId}',
        );
        for (final item in order.items) {
          debugPrint(
            '[ProfileController]   item.id=${item.id} item.variant=${item.variant} '
            'materialName="${item.materialName}" qty=${item.quantity}',
          );
        }
      }
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

  Future<bool> submitOrderReview({
    required int orderId,
    required int rating,
    required String comment,
  }) async {
    debugPrint(
      '[ProfileController] submitOrderReview($orderId, rating: $rating)',
    );
    isSubmittingReview.value = true;
    try {
      final result = await ApiService.postOrderReview(
        orderId: orderId,
        rating: rating,
        comment: comment,
      );

      if (result.success && result.review != null) {
        final index = orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          orders[index].review = result.review;
          orders.refresh(); // trigger Obx rebuild on the order list screen
        }
        _showStatusSnackbar('Review submitted successfully');
        return true;
      } else {
        _showStatusSnackbar(result.message, isError: true);
        return false;
      }
    } catch (e) {
      debugPrint('[ProfileController] submitOrderReview unexpected => $e');
      _showStatusSnackbar(
        'Failed to submit review. Please try again.',
        isError: true,
      );
      return false;
    } finally {
      isSubmittingReview.value = false;
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

  // Generate coupon share link and copy to clipboard

// Replace the generateCouponShareLink method with this:
Future<void> generateCouponShareLink({
  required String couponCode,
  required double discountPercentage,
  required String materialName,
}) async {
  debugPrint('[ProfileController] generateCouponShareLink($couponCode)');
  
  try {
    // Build the WhatsApp message
    final String message = 
        "Hey! I'm sharing a $discountPercentage% discount coupon for $materialName on Brickle. "
        "Use my coupon code $couponCode at checkout!";
    
    // Create the WhatsApp link without phone number
    final String whatsappLink = 
        "https://wa.me/?text=${Uri.encodeComponent(message)}";
    
    debugPrint('[ProfileController] Generated link: $whatsappLink');
    
    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: whatsappLink));
    
    Get.snackbar(
      'Copied!',
      'WhatsApp share link copied to clipboard!',
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    
    // Remove the coupon after sharing
    coupons.removeWhere((c) => c.couponCode == couponCode);
    unawaited(fetchCoupons());
    
  } catch (e) {
    debugPrint('[ProfileController] generateCouponShareLink error: $e');
    Get.snackbar(
      'Error',
      'Failed to generate share link. Please try again.',
      backgroundColor: AppColors.errorRed,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

// Replace the shareCouponDirectly method with this:
Future<void> shareCouponDirectly({
  required String couponCode,
  required double discountPercentage,
  required String materialName,
}) async {
  debugPrint('[ProfileController] shareCouponDirectly($couponCode)');
  
  try {
    // Build the WhatsApp message
    final String message = 
        "Hey! I'm sharing a $discountPercentage% discount coupon for $materialName on Brickle. "
        "Use my coupon code $couponCode at checkout!";
    
    // Create the WhatsApp link without phone number
    final String whatsappLink = 
        "https://wa.me/?text=${Uri.encodeComponent(message)}";
    
    final Uri whatsappUri = Uri.parse(whatsappLink);
    
    debugPrint('[ProfileController] Opening: $whatsappLink');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      
      Get.snackbar(
        'Success',
        'Opening WhatsApp...',
        backgroundColor: AppColors.primaryGreen,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Remove the coupon after sharing
      coupons.removeWhere((c) => c.couponCode == couponCode);
      unawaited(fetchCoupons());
    } else {
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: whatsappLink));
      Get.snackbar(
        'Info',
        'WhatsApp not installed. Link copied to clipboard.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  } catch (e) {
    debugPrint('[ProfileController] shareCouponDirectly error: $e');
    Get.snackbar(
      'Error',
      'Failed to share. Please try again.',
      backgroundColor: AppColors.errorRed,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
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
