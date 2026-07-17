import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CouponScreen extends StatelessWidget {
  CouponScreen({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "My Coupons",
          style: GoogleFonts.manrope(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isCouponLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
            ),
          );
        }

        if (controller.coupons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 15),
                Text(
                  "No Coupons Available",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You don't have any coupons yet.",
                  style: GoogleFonts.manrope(
                    color: Colors.grey,
                  ),
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: controller.fetchCoupons,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, index) {
              final coupon = controller.coupons[index];

              return _CouponCard(coupon: coupon);
            },
          ),
        );
      }),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final dynamic coupon;

  const _CouponCard({
    required this.coupon,
  });

  @override
  Widget build(BuildContext context) {
    final expired = coupon.isExpired;
    final used = coupon.isUsed;

    Color color = AppColors.primaryGreen;

    if (expired) {
      color = Colors.red;
    } else if (used) {
      color = Colors.grey;
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 150,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      "${coupon.discountPercentage}% OFF",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.rewardMaterialName,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Coupon Code",
                        style: GoogleFonts.manrope(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          coupon.couponCode,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 15,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          // Text(
                          //   // "Valid till ${DateFormat('dd MMM yyyy').format(coupon.expiryDate)}",
                          //   style: GoogleFonts.manrope(
                          //     color: Colors.grey.shade600,
                          //     fontSize: 12,
                          //   ),
                          // ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              expired
                                  ? "Expired"
                                  : used
                                      ? "Used"
                                      : "Available",
                              style: GoogleFonts.manrope(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const Spacer(),

                          if (!expired && !used)
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: coupon.couponCode,
                                  ),
                                );

                                Get.snackbar(
                                  "Copied",
                                  "Coupon code copied",
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),

        Positioned(
          left: 78,
          top: -10,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xffF5F5F5),
          ),
        ),

        Positioned(
          left: 78,
          bottom: -10,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xffF5F5F5),
          ),
        ),
      ],
    );
  }
}