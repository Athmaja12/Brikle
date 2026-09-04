// lib/ProfilePage/View/coupon_screen.dart
// Restyled to match the rest of the app's design system:
// - Same scaffold background as Cart (F6F7F6)
// - Flat white cards, radius 14, no heavy shadow (like _CartItemsCard / _BillDetailsCard)
// - AppColors / AppTextStyles / Responsive used instead of hardcoded hex + raw padding
// - Coupon code chip uses the same green-tint style as the Cart coupon selector
// - Coupons are now split into Active and Expired sections
// - Share options now include the Play Store app link so recipients can install the app

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Link shared alongside coupon codes so the recipient can install the app.
const String kAppDownloadLink =
    'https://play.google.com/store/apps/details?id=com.brikle.app';

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

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
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
                  Icons.share_outlined,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Share Coupon',
                  style: AppTextStyles.welcomeBackTitle(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${coupon.couponCode} — ${coupon.discountPercentage}% off',
              style: const TextStyle(fontSize: 14, color: AppColors.textGray),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Option 1: Copy WhatsApp link (server-generated)
            _ShareOptionCard(
              icon: Icons.copy_outlined,
              title: 'Copy WhatsApp Link',
              subtitle: 'Copy share link to clipboard',
              color: Colors.green,
              onTap: () async {
                Navigator.pop(sheetContext);
                final phone = await _promptForRecipientPhone(context);
                if (phone == null) return;
                final controller = Get.find<ProfileController>();
                await controller.shareCouponViaWhatsapp(
                  couponCode: coupon.couponCode,
                  recipientPhone: phone,
                  openDirectly: false,
                );
              },
            ),

            const SizedBox(height: 12),

            // Option 2: Open WhatsApp directly (server-generated link)
            _ShareOptionCard(
              icon: Icons.message,
              title: 'Open WhatsApp',
              subtitle: 'Share directly via WhatsApp',
              color: Colors.green,
              onTap: () async {
                Navigator.pop(sheetContext);
                final phone = await _promptForRecipientPhone(context);
                if (phone == null) return;
                final controller = Get.find<ProfileController>();
                await controller.shareCouponViaWhatsapp(
                  couponCode: coupon.couponCode,
                  recipientPhone: phone,
                  openDirectly: true,
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Small dialog to collect the recipient's phone number — required by
  /// the /api/my-coupons/share/ endpoint. Returns null if cancelled or
  /// if the input isn't a plausible 10-digit number.
  Future<String?> _promptForRecipientPhone(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recipient\'s Phone Number'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter a valid phone number',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              onPressed: () {
                final value = controller.text.trim();
                if (RegExp(r'^\d{10}$').hasMatch(value)) {
                  Navigator.pop(dialogContext, value);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid 10-digit phone number'),
                    ),
                  );
                }
              },
              child: const Text('Share', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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
              onTap: () => _showShareOptions(context),
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
                    'Share coupon',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primaryGreen,
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

// Helper widget for share options
class _ShareOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShareOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
