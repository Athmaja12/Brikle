// lib/ProfilePage/View/coupon_screen.dart
// Restyled to match the rest of the app's design system:
// - Same scaffold background as Cart (F6F7F6)
// - Flat white cards, radius 14, no heavy shadow (like _CartItemsCard / _BillDetailsCard)
// - AppColors / AppTextStyles / Responsive used instead of hardcoded hex + raw padding
// - Coupon code chip uses the same green-tint style as the Cart coupon selector

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CouponScreen extends StatelessWidget {
  CouponScreen({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "My Coupons",
          style: AppTextStyles.welcomeBackTitle(context),
        ),
      ),
      body: Obx(() {
        if (controller.isCouponLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (controller.coupons.isEmpty) {
          return const _EmptyCoupons();
        }

        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: controller.fetchCoupons,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 16),
              vertical: Responsive.space(context, 12),
            ),
            itemCount: controller.coupons.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: Responsive.space(context, 12)),
            itemBuilder: (_, index) {
              final coupon = controller.coupons[index];
              return _CouponListCard(coupon: coupon);
            },
          ),
        );
      }),
    );
  }
}

class _EmptyCoupons extends StatelessWidget {
  const _EmptyCoupons();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            'No Coupons Available',
            style: AppTextStyles.welcomeBackTitle(
              context,
            ).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "You don't have any coupons yet.",
            style: AppTextStyles.termsText(context),
          ),
        ],
      ),
    );
  }
}

class _CouponListCard extends StatelessWidget {
  final dynamic coupon;

  const _CouponListCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final bool expired = coupon.isExpired;
    final bool used = coupon.isUsed;
    final bool active = !expired && !used;

    final Color accent = expired
        ? AppColors.errorRed
        : used
        ? AppColors.textGray
        : AppColors.primaryGreen;

    final String statusLabel = expired ? 'Expired' : (used ? 'Used' : 'Active');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discount badge — matches the icon-container radius used across the app
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${coupon.discountPercentage}%",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ),
          SizedBox(width: Responsive.space(context, 12)),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        coupon.rewardMaterialName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.fieldLabel(
                          context,
                        ).copyWith(color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, 8)),

                // Coupon code chip — same green-tint style as the Cart coupon selector
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FFF8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.confirmation_num_outlined,
                            size: 14,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            coupon.couponCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.5,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: coupon.couponCode),
                          );
                          Get.snackbar(
                            "Copied",
                            "Coupon code copied",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primaryGreen,
                            colorText: Colors.white,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.copy_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Responsive.space(context, 8)),

                // Expiry
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.textGray,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      coupon.formattedExpiryDate,
                      style: AppTextStyles.termsText(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
