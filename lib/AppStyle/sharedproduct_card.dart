import 'dart:async';

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/AddtoCart/View/addtocart_view.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:brikle/Wishlist/View/wishlistheart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SharedProductCard extends StatefulWidget {
  final CategoryProductItem product;
  // final String? dealBadgeText; // custom_title, e.g. "monsoon week"
  final DateTime? dealEndDate; // end_date
  final double? originalPrice; // retail_price_with_gst
  final int? discountPercent; // discount_percentage

  const SharedProductCard({
    super.key,
    required this.product,
    // this.dealBadgeText,
    this.dealEndDate,
    this.originalPrice,
    this.discountPercent,
  });

  @override
  State<SharedProductCard> createState() => _SharedProductCardState();
}

class _SharedProductCardState extends State<SharedProductCard> {
  // Anchors the popup's position — placed on the outer Container so the
  // popup sits right above wherever this specific card is on screen.
  final GlobalKey _cardKey = GlobalKey();
  // Anchors specifically to the Add to Cart / stepper button, so the popup
  // appears right above the button (matching the reference screenshot)
  // instead of above the whole card.
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _unlockOverlay;
  Timer? _countdownTimer;

  // ── Manual quantity entry ────────────────────────────────────────────
  // Lets the user tap the count between the +/- buttons and type a
  // quantity directly, instead of only tapping +/- one at a time.
  final TextEditingController _qtyController = TextEditingController();
  final FocusNode _qtyFocusNode = FocusNode();
  CartItem? _currentCartItem;
  CartController? _cartController;

  CategoryProductItem get product => widget.product;

  // Guards against malformed/empty URLs (e.g. "", "http://", stray
  // whitespace) that pass a plain isNotEmpty check but aren't real
  // network URLs — these can crash image resolution with errors like
  // "No host specified in URI file:///".
  bool _isValidImageUrl(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (!(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) return false;
    if (uri.host.isEmpty) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (widget.dealEndDate != null) {
      // Refresh the countdown text every minute
      _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    // Commit whatever the user typed as soon as the field loses focus
    // (covers tapping elsewhere, not just pressing "done").
    _qtyFocusNode.addListener(() {
      if (!_qtyFocusNode.hasFocus) {
        _commitTypedQuantity();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _unlockOverlay?.remove();
    _qtyController.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  String? get _countdownText {
    final end = widget.dealEndDate;
    if (end == null) return null;
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return null; // safety net if it expires mid-session
    if (diff.inDays >= 1) {
      return 'Ends in ${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours >= 1) {
      return 'Ends in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return 'Ends in ${diff.inMinutes}m';
  }

  /// Call this right after a quantity change with the NEW quantity.
  /// Only fires when the new quantity lands exactly on a tier's minQty —
  /// i.e. the one tap that actually crosses the threshold — not on every
  /// subsequent tap while quantity stays above it.
  void _maybeShowUnlockPopup(int newQuantity) {
    if (!product.hasTiers || product.priceTiers.isEmpty) return;
    final tier = product.priceTiers.firstWhereOrNull(
      (t) => t.minQty == newQuantity,
    );
    if (tier == null) return;

    _unlockOverlay?.remove();
    _unlockOverlay = null;

    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final buttonWidth = renderBox.size.width;

    final overlayState = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx,
        top: position.dy - 34, // hovers just above the button
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

  // Reads whatever is currently typed in the quantity field, applies it
  // (removes the item on 0/empty/invalid, otherwise sets the new qty),
  // and fires the bulk-tier unlock popup if it lands on a tier threshold.
  void _commitTypedQuantity() {
    final cartItem = _currentCartItem;
    final cartController = _cartController;
    if (cartItem == null || cartController == null) return;

    final parsed = int.tryParse(_qtyController.text.trim());

    if (parsed == null || parsed <= 0) {
      cartController.removeItem(cartItem);
      return;
    }

    if (parsed != cartItem.quantity) {
      cartController.updateQuantity(cartItem, parsed);
      _maybeShowUnlockPopup(parsed);
    } else {
      // Nothing changed — just make sure the field shows the clean value.
      _qtyController.text = '$parsed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Container(
      key: _cardKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      padding: const EdgeInsets.all(8),
      child: Obx(() {
        final cartItem = cartController.cartItems.firstWhereOrNull(
          (i) => i.variantId == product.variantId,
        );
        final quantity = cartItem?.quantity ?? 0;
        final unitPrice = product.unitPriceForQuantity(
          quantity == 0 ? 1 : quantity,
        );
        final totalPrice = unitPrice * (quantity == 0 ? 1 : quantity);

        // Keep the manual-entry field + controller refs current so
        // _commitTypedQuantity() always acts on the latest cart item.
        _currentCartItem = cartItem;
        _cartController = cartController;
        if (!_qtyFocusNode.hasFocus) {
          final text = '$quantity';
          if (_qtyController.text != text) {
            _qtyController.text = text;
          }
        }

        return ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top row: discount badge (left) + wishlist heart (right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.discountPercent != null &&
                            widget.discountPercent! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFF5E3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.discountPercent}% Off',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        WishlistHeart(variantId: product.variantId),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // ── Image + custom_title ribbon
                    Stack(
                      children: [
                        SizedBox(
                          height: 70,
                          width: double.infinity,
                          child: _isValidImageUrl(product.imageUrl)
                              ? Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 60,
                                    color: Colors.black26,
                                  ),
                                )
                              : const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 60,
                                  color: Colors.black26,
                                ),
                        ),
                        // if (widget.dealBadgeText != null &&
                        // widget.dealBadgeText!.isNotEmpty)
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
                            // child: Text(
                            //   // widget.dealBadgeText!.toUpperCase(),
                            //   style: const TextStyle(
                            //     fontSize: 8,
                            //     fontWeight: FontWeight.w700,
                            //     color: Colors.white,
                            //     letterSpacing: 0.3,
                            //   ),
                            // ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // ── Trust badges: Assured + 100% Trusted (shown on every card)
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

                    // ── Name
                    SizedBox(
                      height: 26,
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
                    const SizedBox(height: 4),

                    // ── Price row: deal price + strikethrough + inline % off
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
                        if (widget.discountPercent != null &&
                            widget.discountPercent! > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${widget.discountPercent}% off',
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(
                      height: 11,
                      child: quantity > 1
                          ? Text(
                              'Total: ₹${totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textGray,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 15,
                child: (product.hasTiers && product.priceTiers.isNotEmpty)
                    ? GestureDetector(
                        onTap: () =>
                            _showBulkPricingDialog(context, cartController),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
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
                      )
                    : null,
              ),

              // ── Countdown from end_date
              if (_countdownText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _countdownText!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD9480F),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              quantity == 0
                  ? GestureDetector(
                      onTap: () async {
                        await cartController.addToCart(
                          variantId: product.variantId,
                          quantity: 1,
                        );
                        _maybeShowUnlockPopup(1);
                      },
                      child: Container(
                        key: _buttonKey,
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
                  : Container(
                      key: _buttonKey,
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
                            onTap: () => cartController.decrement(cartItem!),
                          ),
                          // ── Manually-editable quantity field ──
                          // Tap it to type a quantity directly; still stays
                          // in sync when +/- are tapped instead.
                          SizedBox(
                            width: 30,
                            height: 22,
                            child: TextField(
                              controller: _qtyController,
                              focusNode: _qtyFocusNode,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              cursorColor: Colors.white,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onTap: () {
                                // Select-all so typing replaces the value
                                // instead of appending to it.
                                _qtyController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _qtyController.text.length,
                                );
                              },
                              onSubmitted: (_) {
                                _commitTypedQuantity();
                                _qtyFocusNode.unfocus();
                              },
                            ),
                          ),
                          _StepperSymbol(
                            label: '+',
                            onTap: () {
                              final newQty = quantity + 1;
                              cartController.increment(cartItem!);
                              _maybeShowUnlockPopup(newQty);
                            },
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _addToCartAndNavigate(
    BuildContext context,
    CartController cartController,
    int quantity,
  ) async {
    await cartController.addToCart(
      variantId: product.variantId,
      quantity: quantity,
    );
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
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
}

// ── "🎉 You unlocked ₹X!" popup pill ───────────────────────────────────
// Fades + scales in, holds, then the parent removes it after ~1.6s.
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
              border: Border.all(color: AppColors.primaryGreen, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '🎉 You unlocked ₹${price.toStringAsFixed(0)}!',
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
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
