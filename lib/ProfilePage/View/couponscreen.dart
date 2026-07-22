// lib/ProfilePage/View/coupon_screen.dart
// Restyled to match the rest of the app's design system:
// - Same scaffold background as Cart (F6F7F6)
// - Flat white cards, radius 14, no heavy shadow (like _CartItemsCard / _BillDetailsCard)
// - AppColors / AppTextStyles / Responsive used instead of hardcoded hex + raw padding
// - Coupon code chip uses the same green-tint style as the Cart coupon selector
// - Coupons are now split into Active and Expired sections

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

        // Split coupons into active and expired
        final activeCoupons = controller.coupons
            .where((c) => !c.isExpired && !c.isUsed)
            .toList();
        final expiredCoupons = controller.coupons
            .where((c) => c.isExpired || c.isUsed)
            .toList();

        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: controller.fetchCoupons,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 16),
              vertical: Responsive.space(context, 12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Coupons Section
                if (activeCoupons.isNotEmpty) ...[
                  _SectionHeader(
                    title: "Active Coupons",
                    count: activeCoupons.length,
                    icon: Icons.check_circle_outline,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(height: Responsive.space(context, 12)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeCoupons.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: Responsive.space(context, 12)),
                    itemBuilder: (_, index) {
                      final coupon = activeCoupons[index];
                      return _CouponListCard(coupon: coupon);
                    },
                  ),
                  if (expiredCoupons.isNotEmpty)
                    SizedBox(height: Responsive.space(context, 24)),
                ],

                // Expired Coupons Section
                if (expiredCoupons.isNotEmpty) ...[
                  _SectionHeader(
                    title: "Expired Coupons",
                    count: expiredCoupons.length,
                    icon: Icons.hourglass_empty,
                    color: AppColors.errorRed,
                  ),
                  SizedBox(height: Responsive.space(context, 12)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expiredCoupons.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: Responsive.space(context, 12)),
                    itemBuilder: (_, index) {
                      final coupon = expiredCoupons[index];
                      return _CouponListCard(coupon: coupon);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.welcomeBackTitle(
            context,
          ).copyWith(fontSize: 16, color: AppColors.textDark),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
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

  void _showShareSheet(BuildContext context) {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inputBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard_outlined,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Share Coupon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${coupon.couponCode} — ${coupon.discountPercentage}% off',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                // Registered-users-only constraint is enforced by the
                // backend on submit — this note just sets expectations
                // up front instead of the user finding out after a failed
                // request.
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'The recipient must already have a Brikle account.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Recipient\'s Phone Number',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.length != 10 || int.tryParse(v) == null) {
                      return 'Enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isSubmitting = true);

                            final controller = Get.find<ProfileController>();
                            final result = await controller.shareCoupon(
                              couponCode: coupon.couponCode,
                              recipientPhone: phoneController.text.trim(),
                            );

                            if (!sheetContext.mounted) return;
                            setSheetState(() => isSubmitting = false);

                            Navigator.pop(sheetContext);
                            Get.snackbar(
                              result?.success == true
                                  ? 'Coupon Shared'
                                  : 'Could Not Share',
                              result?.message ??
                                  'Something went wrong. Please try again.',
                              backgroundColor: result?.success == true
                                  ? AppColors.primaryGreen
                                  : AppColors.errorRed,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send Coupon',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          // Share action — only for coupons that are still usable.
          // Expired/used coupons have nothing worth transferring.
          if (active) ...[
            const Divider(height: 20),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showShareSheet(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.share_outlined,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Share with a friend',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
