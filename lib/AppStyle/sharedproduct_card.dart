import 'dart:async';
import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/View/addtocart_view.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:brikle/Wishlist/View/wishlistheart.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SharedProductCard extends StatefulWidget {
  final CategoryProductItem product;
  final String? dealBadgeText;
  final DateTime? dealEndDate;
  final double? originalPrice;
  final int? discountPercent;
  final bool navigateToCartOnAdd;

  const SharedProductCard({
    super.key,
    required this.product,
    this.dealBadgeText,
    this.dealEndDate,
    this.originalPrice,
    this.discountPercent,
    this.navigateToCartOnAdd = true,
  });

  static const double gridMainAxisExtent = 300;

  @override
  State<SharedProductCard> createState() => _SharedProductCardState();
}

class _SharedProductCardState extends State<SharedProductCard> {
  Timer? _countdownTimer;
  Timer? _unlockHideTimer;

  double? _unlockedPrice;
  bool _showConfetti = false;
  Key _confettiKey =
      UniqueKey(); // new key each trigger forces the animation to restart from scratch
  Timer? _confettiHideTimer;
  // non-null while this card's own popup is visible

  CategoryProductItem get product => widget.product;
  bool get _canAddToCart => product.variantId > 0;

  bool _isValidImageUrl(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (!(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) return false;
    return uri.host.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (widget.dealEndDate != null) {
      _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _unlockHideTimer?.cancel();
    _confettiHideTimer?.cancel();
    super.dispose();
  }

  String? get _countdownText {
    final end = widget.dealEndDate;
    if (end == null) return null;
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return null;
    if (diff.inDays >= 1)
      return 'Ends in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours >= 1)
      return 'Ends in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'Ends in ${diff.inMinutes}m';
  }

  /// Local, in-tree popup — no OverlayEntry, no GlobalKey/RenderBox
  /// coordinate math, no snackbar. Setting this triggers a rebuild of
  /// THIS card's own Stack only, so it's structurally impossible for it
  /// to render on top of a sibling card in the grid.
  void _maybeShowUnlockPopup(int newQuantity) {
    if (!product.hasTiers || product.priceTiers.isEmpty) return;
    final tier = product.priceTiers.firstWhereOrNull(
      (t) => t.minQty == newQuantity,
    );
    if (tier == null) return;

    _unlockHideTimer?.cancel();
    _confettiHideTimer?.cancel();
    setState(() {
      _unlockedPrice = tier.price;
      _showConfetti = true;
      _confettiKey =
          UniqueKey(); // restart animation even if triggered again quickly
    });

    _unlockHideTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _unlockedPrice = null);
    });
    _confettiHideTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  /// Shows a lightweight "added to cart" confirmation without navigating
  /// away from wherever the user currently is (grid, search results, etc).
  void _showAddedToCartSnackbar() {
    final context = this.context;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Item added to cart successfully',
                style: GoogleFonts.manrope(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBulkPricingDialog(
    BuildContext context,
    CartController cartController,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Bulk Prices Launched',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...product.priceTiers.map(
                (t) => InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await cartController.addToCart(
                      variantId: product.variantId,
                      quantity: t.minQty,
                    );
                    _maybeShowUnlockPopup(t.minQty);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.textGray,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Buy ${t.minQty}+ at',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₹${t.price.toStringAsFixed(0)}/unit',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      // Clip so the popup's slide/fade-in never visually spills outside
      // this card's own rounded border into whatever sits next to it.
      clipBehavior: Clip.antiAlias,
      child: Obx(() {
        final cartItem = _canAddToCart
            ? cartController.cartItems.firstWhereOrNull(
                (i) => i.variantId == product.variantId,
              )
            : null;
        final quantity = cartItem?.quantity ?? 0;
        final unitPrice = product.unitPriceForQuantity(
          quantity == 0 ? 1 : quantity,
        );
        final totalPrice = unitPrice * (quantity == 0 ? 1 : quantity);
        final hasBulkPricing =
            product.hasTiers && product.priceTiers.isNotEmpty;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge + wishlist row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _OfferBadge(
                                discountPercent: widget.discountPercent,
                                offer: product.offer,
                              ),
                              if (_canAddToCart)
                                WishlistHeart(variantId: product.variantId)
                              else
                                const SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Product image
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            ),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 70,
                                  width: double.infinity,
                                  child: _isValidImageUrl(product.imageUrl)
                                      ? Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.inventory_2_outlined,
                                                size: 50,
                                                color: Colors.black26,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 50,
                                          color: Colors.black26,
                                        ),
                                ),
                                if (widget.dealBadgeText != null &&
                                    widget.dealBadgeText!.isNotEmpty)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF7A00),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.dealBadgeText!.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Trusted badge
                          Row(
                            children: [
                              const SizedBox(width: 4),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 9,
                                        color: AppColors.primaryGreen,
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          '100% TRUSTED',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.manrope(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Product name — fixed height, prevents row misalignment
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            ),
                            child: SizedBox(
                              height: 30,
                              child: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 15 / 12,
                                  color: const Color(0xFF212121),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${unitPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (widget.originalPrice != null &&
                                  widget.originalPrice! > unitPrice) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '₹${widget.originalPrice!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.textGray,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (quantity > 1) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Total: ₹${totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],

                          if (hasBulkPricing) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _showBulkPricingDialog(
                                context,
                                cartController,
                              ),
                              child: Text(
                                'Unlock Bulk Prices of ₹${product.bestTierPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryGreen,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],

                          if (_countdownText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _countdownText!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD9480F),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Cart button
                  if (!_canAddToCart)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 33,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFB1B1B1)),
                          color: const Color(0xFFF9F9F9),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textGray,
                          ),
                        ),
                      ),
                    )
                  else if (quantity == 0)
                    GestureDetector(
                      onTap: () async {
                        await cartController.addToCart(
                          variantId: product.variantId,
                          quantity: 1,
                        );
                        // Just confirm the add — don't navigate away to the
                        // cart page (that was the bug being fixed here).
                        _showAddedToCartSnackbar();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 33,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFB1B1B1)),
                        ),
                        child: Text(
                          'Add to Cart',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 31,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StepperSymbol(
                            label: '-',
                            onTap: () {
                              if (quantity <= 1) {
                                cartController.removeItem(cartItem!);
                              } else {
                                cartController.decrement(cartItem!);
                              }
                            },
                          ),
                          Text(
                            '$quantity',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          _StepperSymbol(
                            label: '+',
                            onTap: () {
                              cartController.increment(cartItem!);
                              _maybeShowUnlockPopup(quantity + 1);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            if (_showConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: _CardConfettiRain(key: _confettiKey),
                ),
              ),

            // ── Unlock popup — sits INSIDE this card's own Stack, so it
            // can only ever cover THIS card, never a neighbor. Positioned
            // to overlay the bottom (button) area since that's the most
            // visible spot without pushing/reflowing any other content.
            if (_unlockedPrice != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _unlockedPrice != null ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      height: 33,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '🎉 Unlocked ₹${_unlockedPrice!.toStringAsFixed(0)}/unit',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _CardConfettiRain extends StatefulWidget {
  const _CardConfettiRain({super.key});

  @override
  State<_CardConfettiRain> createState() => _CardConfettiRainState();
}

class _CardConfettiRainState extends State<_CardConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<_ConfettiPiece> _pieces = List.generate(
    28,
    (index) => _ConfettiPiece(
      x: (index * 0.173) % 1.0,
      delay: (index % 7) / 7,
      size: 3.0 + (index % 4),
      rotation: (index * 0.71),
      horizontalDrift: ((index % 5) - 2) * 0.018,
    ),
  );

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: _controller.value,
              pieces: _pieces,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double delay;
  final double size;
  final double rotation;
  final double horizontalDrift;

  const _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.size,
    required this.rotation,
    required this.horizontalDrift,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiPiece> pieces;

  _ConfettiPainter({required this.progress, required this.pieces});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final localProgress = ((progress - piece.delay) / (1 - piece.delay))
          .clamp(0.0, 1.0);

      if (localProgress <= 0) continue;

      final x = (piece.x + piece.horizontalDrift * localProgress) * size.width;

      final y = localProgress * size.height;

      final opacity = localProgress < 0.15
          ? localProgress / 0.15
          : (1 - localProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = [
          const Color(0xFFFFD54F),
          const Color(0xFFFF7043),
          const Color(0xFF42A5F5),
          const Color(0xFF66BB6A),
          const Color(0xFFAB47BC),
        ][pieces.indexOf(piece) % 5].withOpacity(opacity);

      canvas.save();

      canvas.translate(x, y);

      canvas.rotate(piece.rotation + localProgress * 4);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.size,
        height: piece.size * 1.8,
      );

      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StepperSymbol extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepperSymbol({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  final int? discountPercent;
  final dynamic offer;

  const _OfferBadge({this.discountPercent, this.offer});

  String? get _label {
    if (discountPercent != null && discountPercent! > 0) {
      return '$discountPercent% Off';
    }
    if (offer != null) {
      final pct = (offer.discountPercentage as double);
      if (pct > 0) return '${pct.toInt()}% Off';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox.shrink();
    return Container( 
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF5E3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
