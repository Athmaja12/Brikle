import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/ProfilePage/Model/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final Rx<ProfileModel> profile = ProfileModel().obs;
  final RxList<AddressModel> addresses = <AddressModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  // Coupons
  final RxList<CouponModel> coupons = <CouponModel>[].obs;
  final RxBool isCouponLoading = false.obs;

  // ── Convenience getters ────────────────────────────────────────────────────
  String get fullName => profile.value.fullName;
  String get phoneNumber => profile.value.phoneNumber;
  String get email => profile.value.email ?? '';
  String get address => profile.value.address;
  bool get isVerified => profile.value.isVerified;

  static final RegExp _gstRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  bool isGstValid(String gst) => _gstRegex.hasMatch(gst.trim().toUpperCase());
  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    debugPrint('[ProfileController] onInit');
    fetchProfile();
    fetchCoupons(); // Fetch coupons on initialization
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/customer-profile/
  /// response: { full_name, email, phone_number, address, is_verified }
  Future<void> fetchProfile() async {
    debugPrint('[ProfileController] fetchProfile()');
    isLoading.value = true;
    try {
      final response = await ApiService.getProfile();
      debugPrint('[ProfileController] fetchProfile SUCCESS → $response');
      profile.value = ProfileModel.fromJson(response);
      _syncPrimaryAddressFromProfile(); // ← NEW
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

  void _syncPrimaryAddressFromProfile() {
    if (profile.value.address.trim().isEmpty) return;

    final profileAddress = AddressModel(
      id: 'profile', // stable synthetic id — identifies this synced entry
      streetAddress1: profile.value.address,
      streetAddress2: '',
      pincode: profile.value.pincode,
      isPrimary: addresses.isEmpty, // only default if nothing else exists yet
    );

    final existingIndex = addresses.indexWhere((a) => a.id == 'profile');
    if (existingIndex != -1) {
      addresses[existingIndex] = profileAddress;
    } else {
      addresses.insert(0, profileAddress);
    }
  }

  /// PATCH /api/customer-profile/edit/
  /// body: { full_name, email, address }
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? address,
  }) async {
    debugPrint('[ProfileController] updateProfile()');
    isUpdating.value = true;
    try {
      final response = await ApiService.updateProfile(
        fullName: fullName,
        email: email,
        address: address,
      );

      print('UPDATE PROFILE RESPONSE => $response');

      // Merge returned fields back into local model
      // profile.value = profile.value.copyWith(
      //   fullName: response['full_name']?.toString(),
      //   email: response['email']?.toString(),
      //   address: response['address']?.toString(),
      // );
      await fetchProfile();
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Profile updated successfully",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] updateProfile ApiException → ${e.message}',
      );
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] updateProfile unexpected → $e');
      Get.snackbar('Error', 'Failed to update profile. Please try again.');
    } finally {
      isUpdating.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/customer-logout/
  /// body: { refresh: "your_refresh_token" }
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
      // Even if API fails, clear local session and redirect
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

  /// DELETE /api/customer-delete-account/
  /// response: none (204)
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
  // ADDRESSES
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/customer/addresses/
  Future<void> addAddress({
    required String streetAddress1,
    required String streetAddress2,
    required String pincode,
    bool isPrimary = false,
    String? customerType,
    String? gstNumber,
  }) async {
    debugPrint(
      '[ProfileController] addAddress(street1: $streetAddress1, pincode: $pincode, isPrimary: $isPrimary)',
    );
    try {
      final response = await ApiService.addAddress(
        streetAddress1: streetAddress1,
        streetAddress2: streetAddress2,
        pincode: pincode,
        isPrimary: isPrimary,
        customerType: customerType,
        gstNumber: gstNumber,
      );
      debugPrint('[ProfileController] addAddress SUCCESS → $response');
      final newAddress = AddressModel.fromJson(response);
      if (newAddress.isPrimary) {
        final updated = addresses
            .map((a) => a.copyWith(isPrimary: false))
            .toList();
        addresses.assignAll(updated);
      }
      addresses.add(newAddress);
      Get.snackbar('Success', 'Address added successfully.');
    } on ApiException catch (e) {
      debugPrint('[ProfileController] addAddress ApiException → ${e.message}');
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] addAddress unexpected → $e');
      Get.snackbar('Error', 'Failed to add address. Please try again.');
    }
  }

  /// PATCH /api/customer/addresses/{id}/
  Future<void> updateAddress({
    required String addressId,
    String? streetAddress1,
    String? streetAddress2,
    String? pincode,
    bool? isPrimary,
    String? customerType,
    String? gstNumber,
  }) async {
    debugPrint('[ProfileController] updateAddress(id: $addressId)');
    try {
      final response = await ApiService.updateAddress(
        addressId: addressId,
        streetAddress1: streetAddress1,
        streetAddress2: streetAddress2,
        pincode: pincode,
        isPrimary: isPrimary,
        customerType: customerType,
        gstNumber: gstNumber,
      );
      debugPrint('[ProfileController] updateAddress SUCCESS → $response');
      final updated = AddressModel.fromJson(response);
      final index = addresses.indexWhere((a) => a.id == addressId);
      if (index != -1) {
        if (updated.isPrimary) {
          final demoted = addresses
              .map((a) => a.copyWith(isPrimary: false))
              .toList();
          addresses.assignAll(demoted);
        }
        addresses[index] = updated;
      }
      Get.snackbar('Success', 'Address updated successfully.');
    } on ApiException catch (e) {
      debugPrint(
        '[ProfileController] updateAddress ApiException → ${e.message}',
      );
      Get.snackbar('Error', e.message);
    } catch (e) {
      debugPrint('[ProfileController] updateAddress unexpected → $e');
      Get.snackbar('Error', 'Failed to update address. Please try again.');
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

  Future<void> fetchCoupons() async {
    // await fetchCoupons();
    debugPrint('[ProfileController] fetchCoupons()');

    isCouponLoading.value = true;

    try {
      final response = await ApiService.getMyCoupons();

      coupons.assignAll(response.map((e) => CouponModel.fromJson(e)).toList());

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

  @override
  void onClose() {
    debugPrint('[ProfileController] onClose');
    super.onClose();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchProfile(), fetchCoupons()]);
  }
}
