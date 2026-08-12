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

  @override
  State<SharedProductCard> createState() => _SharedProductCardState();
}

class _SharedProductCardState extends State<SharedProductCard> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _unlockOverlay;
  Timer? _countdownTimer;

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
      _countdownTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) { if (mounted) setState(() {}); },
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _unlockOverlay?.remove();
    super.dispose();
  }

  String? get _countdownText {
    final end = widget.dealEndDate;
    if (end == null) return null;
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return null;
    if (diff.inDays >= 1) return 'Ends in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours >= 1) return 'Ends in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'Ends in ${diff.inMinutes}m';
  }

  void _maybeShowUnlockPopup(int newQuantity) {
    if (!product.hasTiers || product.priceTiers.isEmpty) return;
    final tier = product.priceTiers.firstWhereOrNull((t) => t.minQty == newQuantity);
    if (tier == null) return;
    _unlockOverlay?.remove();
    _unlockOverlay = null;
    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final buttonWidth = renderBox.size.width;
    final overlayState = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx,
        top: position.dy - 34,
        width: buttonWidth,
        child: _UnlockPill(price: tier.price),
      ),
    );
    _unlockOverlay = entry;
    overlayState.insert(entry);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (_unlockOverlay == entry) {
        entry.remove();
        _unlockOverlay = null;
      }
    });
  }

  void _showBulkPricingDialog(BuildContext context, CartController cartController) {
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
                    child: Text('Bulk Prices Launched',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, size: 20)),
                ],
              ),
              const SizedBox(height: 4),
              Text(product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
              const SizedBox(height: 12),
              ...product.priceTiers.map((t) => InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await cartController.addToCart(
                      variantId: product.variantId, quantity: t.minQty);
                  _maybeShowUnlockPopup(t.minQty);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.textGray),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Buy ${t.minQty}+ at',
                        style: const TextStyle(fontSize: 13))),
                    Text('₹${t.price.toStringAsFixed(0)}/unit',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen)),
                  ]),
                ),
              )),
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
      padding: const EdgeInsets.all(8),
      child: Obx(() {
        final cartItem = _canAddToCart
            ? cartController.cartItems
                .firstWhereOrNull((i) => i.variantId == product.variantId)
            : null;
        final quantity = cartItem?.quantity ?? 0;
        final unitPrice = product.unitPriceForQuantity(quantity == 0 ? 1 : quantity);
        final totalPrice = unitPrice * (quantity == 0 ? 1 : quantity);
        final hasBulkPricing = product.hasTiers && product.priceTiers.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge + wishlist row
            // Offer badge priority: explicit discountPercent param (deals section)
            // then product.offer from API (category/detail pages)
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
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
              child: Stack(children: [
                SizedBox(
                  height: 70,
                  width: double.infinity,
                  child: _isValidImageUrl(product.imageUrl)
                      ? Image.network(product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined, size: 50, color: Colors.black26))
                      : const Icon(Icons.inventory_2_outlined, size: 50, color: Colors.black26),
                ),
                if (widget.dealBadgeText != null && widget.dealBadgeText!.isNotEmpty)
                  Positioned(
                    top: 0, left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(widget.dealBadgeText!.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: Colors.white, letterSpacing: 0.3)),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 4),

            // Trusted badge
            Row(children: [
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle, size: 9, color: AppColors.primaryGreen),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text('100% TRUSTED',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen)),
                    ),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 4),

            // Product name
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
              child: Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.w400,
                      height: 15 / 12, color: const Color(0xFF212121))),
            ),
            const SizedBox(height: 4),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('₹${unitPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (widget.originalPrice != null && widget.originalPrice! > unitPrice) ...[
                  const SizedBox(width: 6),
                  Text('₹${widget.originalPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textGray, fontSize: 12)),
                ],
              ],
            ),

            // Total (only when qty > 1)
            if (quantity > 1) ...[
              const SizedBox(height: 2),
              Text('Total: ₹${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
            ],

            // Bulk pricing link (only when tiers exist)
            if (hasBulkPricing) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showBulkPricingDialog(context, cartController),
                child: Text(
                    'Unlock Bulk Prices of ₹${product.bestTierPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primaryGreen,
                        decoration: TextDecoration.underline),
                    overflow: TextOverflow.ellipsis),
              ),
            ],

            // Deal countdown
            if (_countdownText != null) ...[
              const SizedBox(height: 4),
              Text(_countdownText!,
                  style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600, color: Color(0xFFD9480F))),
            ],

            const SizedBox(height: 8),

            // Cart button
            if (!_canAddToCart)
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                child: Container(
                  key: _buttonKey,
                  width: double.infinity, height: 33,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFB1B1B1)),
                      color: const Color(0xFFF9F9F9)),
                  child: Text('View Details',
                      style: GoogleFonts.manrope(fontSize: 13,
                          fontWeight: FontWeight.w500, color: AppColors.textGray)),
                ),
              )
            else if (quantity == 0)
              GestureDetector(
                onTap: () async {
                  await cartController.addToCart(variantId: product.variantId, quantity: 1);
                  _maybeShowUnlockPopup(1);
                  if (widget.navigateToCartOnAdd && context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
                  }
                },
                child: Container(
                  key: _buttonKey,
                  width: double.infinity, height: 33,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFB1B1B1))),
                  child: Text('Add to Cart',
                      style: GoogleFonts.manrope(fontSize: 14,
                          fontWeight: FontWeight.w500, color: Colors.black)),
                ),
              )
            else
              Container(
                key: _buttonKey,
                width: double.infinity, height: 31,
                decoration: BoxDecoration(
                    color: const Color(0xFF15803D),
                    borderRadius: BorderRadius.circular(10)),
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
                    Text('$quantity',
                        style: GoogleFonts.manrope(fontSize: 12,
                            fontWeight: FontWeight.w700, color: Colors.white)),
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
        );
      }),
    );
  }
}

class _UnlockPill extends StatelessWidget {
  final double price;
  const _UnlockPill({required this.price});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: 0.7 + (0.3 * value), child: child),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD9F7E3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGreen),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text('🎉 You unlocked ₹${price.toStringAsFixed(0)}!',
                textAlign: TextAlign.start, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
          ),
        ),
      ),
    );
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
        child: Text(label,
            style: GoogleFonts.poppins(fontSize: 18,
                fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

// ── Offer badge widget ────────────────────────────────────────────────
// Resolves which label to show:
//   1. explicit discountPercent param (passed from home/deals sections)
//   2. product.offer from the API (category + product detail pages)
//   3. nothing — SizedBox.shrink()
class _OfferBadge extends StatelessWidget {
  final int? discountPercent;
  final dynamic offer; // OfferTag?

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