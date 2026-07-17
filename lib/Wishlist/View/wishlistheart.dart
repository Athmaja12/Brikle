import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/Wishlist/Controller/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Drop-in heart toggle button.
/// Place on any product card, detail page, or home screen.
///
/// Plain icon (for product cards):
///   WishlistHeart(variantId: product.variantId)
///
/// White circle background (for image overlays on detail page):
///   WishlistHeart(variantId: product.variantId, withBackground: true)
class WishlistHeart extends StatelessWidget {
  final int variantId;
  final double size;
  final bool withBackground;

  const WishlistHeart({
    super.key,
    required this.variantId,
    this.size = 20,
    this.withBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WishlistController>();

    return Obx(() {
      final liked = controller.isWishlisted(variantId);

      final icon = AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(liked),
          size: size,
          color: liked ? Colors.red : AppColors.textGray,
        ),
      );

      if (!withBackground) {
        return GestureDetector(
          onTap: () => controller.toggle(variantId),
          behavior: HitTestBehavior.opaque,
          child: Padding(padding: const EdgeInsets.all(4), child: icon),
        );
      }

      // White circle variant — for product detail image gallery overlay
      return GestureDetector(
        onTap: () => controller.toggle(variantId),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: icon,
        ),
      );
    });
  }
}