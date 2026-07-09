// lib/Cart/View/cart_screen.dart

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/AddtoCart/View/ordersuccess_screen.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// AFTER
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with RouteAware {
  late final CartController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<CartController>();
    // Refresh cart every time this screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[CartScreen] build() called');
    final sw = MediaQuery.of(context).size.width;
    final hp = sw * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (ctrl.cartItems.isEmpty) {
            return _EmptyCart(sw: sw);
          }

          return Column(
            children: [
              _CartAppBar(sw: sw, hp: hp),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: () => ctrl.fetchCart(), // pull-to-refresh
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: sw * 0.03),
                        Text(
                          'Items on cart',
                          style: GoogleFonts.manrope(
                            fontSize: sw * 0.038,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inputText,
                          ),
                        ),
                        SizedBox(height: sw * 0.025),
                        ...ctrl.cartItems.map(
                          (item) => Padding(
                            padding: EdgeInsets.only(bottom: sw * 0.03),
                            child: _CartItemCard(
                              sw: sw,
                              item: item,
                              ctrl: ctrl,
                            ),
                          ),
                        ),
                        SizedBox(height: sw * 0.01),
                        _DeliveryAddressCard(sw: sw, ctrl: ctrl),
                        SizedBox(height: sw * 0.04),
                        _CouponCard(sw: sw, ctrl: ctrl),
                        SizedBox(height: sw * 0.04),
                        _PincodeCard(sw: sw, ctrl: ctrl),
                        SizedBox(height: sw * 0.04),
                        _PaymentMethodCard(sw: sw, ctrl: ctrl),
                        SizedBox(height: sw * 0.04),
                        _CartSummaryCard(sw: sw, ctrl: ctrl),
                        SizedBox(height: sw * 0.04),
                      ],
                    ),
                  ),
                ),
              ),
              _CheckoutBar(sw: sw, hp: hp, ctrl: ctrl),
            ],
          );
        }),
      ),
    );
  }
}

// ── App Bar ────────────────────────────────────────────────────────────────────
class _CartAppBar extends StatelessWidget {
  final double sw, hp;
  const _CartAppBar({required this.sw, required this.hp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: sw * 0.03),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: AppColors.primaryGreen,
            size: sw * 0.065,
          ),
          SizedBox(width: sw * 0.02),
          Text(
            'Cart',
            style: GoogleFonts.manrope(
              fontSize: sw * 0.05,
              fontWeight: FontWeight.w700,
              color: AppColors.inputText,
            ),
          ),
          const Spacer(),
          Obx(() {
            final ctrl = Get.find<CartController>();
            return Container(
              width: sw * 0.1,
              height: sw * 0.1,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.inputText,
                    size: sw * 0.05,
                  ),
                  if (ctrl.cartCount > 0)
                    Positioned(
                      top: sw * 0.01,
                      right: sw * 0.01,
                      child: Container(
                        width: sw * 0.038,
                        height: sw * 0.038,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${ctrl.cartCount}',
                          style: GoogleFonts.manrope(
                            fontSize: sw * 0.02,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Cart Item Card ─────────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final double sw;
  final CartItemModel item;
  final CartController ctrl;

  const _CartItemCard({
    required this.sw,
    required this.item,
    required this.ctrl,
  });

  static const _weightStep = 500;
  static const _minWeight = 500;

  void _decrease(BuildContext context) {
    final newWeight = item.weight - _weightStep;
    if (newWeight < _minWeight) {
      _confirmDelete(context);
    } else {
      ctrl.updateWeight(productId: item.product, weight: newWeight);
    }
  }

  void _increase() {
    ctrl.updateWeight(
      productId: item.product,
      weight: item.weight + _weightStep,
    );
  }

  String _formatWeight(int grams) {
    if (grams >= 1000) {
      final kg = grams / 1000;
      return '${kg % 1 == 0 ? kg.toInt() : kg} Kg';
    }
    return '${grams} gm';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sw * 0.04),
        ),
        title: Text(
          'Remove Item?',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.inputText,
          ),
        ),
        content: Text(
          'Remove "${item.productName}" from your cart?',
          style: GoogleFonts.manrope(color: AppColors.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColors.textGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.removeFromCart(item.product);
            },
            child: Text(
              'Remove',
              style: GoogleFonts.manrope(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(sw * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(sw * 0.025),
            child: item.productImage != null && item.productImage!.isNotEmpty
                ? Image.network(
                    item.productImage!,
                    width: sw * 0.2,
                    height: sw * 0.2,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _CartImagePlaceholder(sw: sw),
                  )
                : _CartImagePlaceholder(sw: sw),
          ),
          SizedBox(width: sw * 0.03),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: sw * 0.035,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inputText,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: sw * 0.012),
                Row(
                  children: [
                    Text(
                      '₹ ${item.offerPrice.isNotEmpty && item.offerPrice != '0' ? item.offerPrice : item.price}',
                      style: GoogleFonts.manrope(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inputText,
                      ),
                    ),
                    if (item.discountPercent != '0' &&
                        item.discountPercent.isNotEmpty) ...[
                      SizedBox(width: sw * 0.015),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sw * 0.018,
                          vertical: sw * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(sw * 0.02),
                        ),
                        child: Text(
                          '${item.discountPercent}% off',
                          style: GoogleFonts.manrope(
                            fontSize: sw * 0.025,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: sw * 0.02),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Container(
                  width: sw * 0.08,
                  height: sw * 0.08,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: sw * 0.042,
                  ),
                ),
              ),
              SizedBox(height: sw * 0.025),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryGreen, width: 1.2),
                  borderRadius: BorderRadius.circular(sw * 0.06),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _decrease(context),
                      child: Container(
                        width: sw * 0.085,
                        height: sw * 0.085,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.remove,
                          size: sw * 0.04,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.018),
                      child: Text(
                        _formatWeight(item.weight),
                        style: GoogleFonts.manrope(
                          fontSize: sw * 0.03,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _increase,
                      child: Container(
                        width: sw * 0.085,
                        height: sw * 0.085,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add,
                          size: sw * 0.04,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Delivery Address Card ──────────────────────────────────────────────────────

// FIX #1 & #2: Extracted edit dialog into its own StatefulWidget so the
// TextEditingController is properly created in initState and disposed in dispose().
class _EditAddressDialog extends StatefulWidget {
  final double sw;
  final CartController ctrl;
  final int addressId; // ← pass id directly
  final String currentAddress; // ← pass current text directly

  const _EditAddressDialog({
    required this.sw,
    required this.ctrl,
    required this.addressId,
    required this.currentAddress,
  });

  @override
  State<_EditAddressDialog> createState() => _EditAddressDialogState();
}

class _EditAddressDialogState extends State<_EditAddressDialog> {
  late final TextEditingController _addressCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: widget.currentAddress);
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[EditAddressDialog] opened');
    debugPrint('[EditAddressDialog] addressId: ${widget.addressId}');
    debugPrint('[EditAddressDialog] pre-filled: "${widget.currentAddress}"');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final ctrl = widget.ctrl;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sw * 0.05),
      ),
      child: Padding(
        padding: EdgeInsets.all(sw * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Address',
              style: GoogleFonts.manrope(
                fontSize: sw * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.inputText,
              ),
            ),
            SizedBox(height: sw * 0.008),
            Text(
              'Update your delivery address below',
              style: GoogleFonts.manrope(
                fontSize: sw * 0.028,
                color: AppColors.textGray,
              ),
            ),
            SizedBox(height: sw * 0.04),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter delivery address',
                hintStyle: GoogleFonts.manrope(color: AppColors.textGray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(sw * 0.03),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(sw * 0.03),
                  borderSide: BorderSide(color: AppColors.primaryGreen),
                ),
              ),
            ),
            SizedBox(height: sw * 0.04),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('[EditAddressDialog] Cancel tapped');
                      Get.back();
                    },
                    child: Container(
                      height: sw * 0.12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(sw * 0.03),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: sw * 0.03),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _isSaving
                        ? null
                        : () async {
                            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                            debugPrint('[EditAddressDialog] Save tapped');
                            debugPrint(
                              '[EditAddressDialog] addressId: ${widget.addressId}',
                            );

                            final newText = _addressCtrl.text.trim();
                            debugPrint(
                              '[EditAddressDialog] new text: "$newText"',
                            );

                            if (newText.isEmpty) {
                              debugPrint(
                                '[EditAddressDialog] ⚠️ empty — aborting',
                              );
                              return;
                            }

                            setState(() => _isSaving = true);

                            final success = await ctrl.updateAddress(
                              id: widget.addressId,
                              address: newText,
                            );

                            debugPrint(
                              '[EditAddressDialog] updateAddress returned: $success',
                            );
                            debugPrint(
                              '[EditAddressDialog] selectedAddress after: ${ctrl.selectedAddress.value?.addressLine}',
                            );

                            setState(() => _isSaving = false);

                            if (success) {
                              debugPrint(
                                '[EditAddressDialog] ✅ closing dialog',
                              );
                              Get.back();
                            } else {
                              debugPrint(
                                '[EditAddressDialog] ❌ failed — staying open',
                              );
                            }
                            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                          },
                    child: Container(
                      height: sw * 0.12,
                      decoration: BoxDecoration(
                        color: _isSaving
                            ? AppColors.primaryGreen.withOpacity(0.6)
                            : AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(sw * 0.03),
                      ),
                      alignment: Alignment.center,
                      child: _isSaving
                          ? SizedBox(
                              width: sw * 0.045,
                              height: sw * 0.045,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Address',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// FIX #3: ctrl is now a required constructor parameter, consistent with all
// other cards (_CouponCard, _PincodeCard, _PaymentMethodCard, _CartSummaryCard)
class _DeliveryAddressCard extends StatelessWidget {
  final double sw;
  final CartController ctrl;

  const _DeliveryAddressCard({required this.sw, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryGreen,
                size: sw * 0.045,
              ),
              SizedBox(width: sw * 0.015),
              Text(
                'Delivery address',
                style: GoogleFonts.manrope(
                  fontSize: sw * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inputText,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final address = ctrl.selectedAddress.value;
                  if (address == null) return; // safety check
                  Get.dialog(
                    _EditAddressDialog(
                      sw: sw,
                      ctrl: ctrl,
                      addressId: address.id, // ← pass id directly
                      currentAddress:
                          address.addressLine, // ← pass text directly
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryGreen,
                      size: sw * 0.038,
                    ),
                    SizedBox(width: sw * 0.01),
                    Text(
                      'Edit',
                      style: GoogleFonts.manrope(
                        fontSize: sw * 0.03,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: sw * 0.03),

          // ── Address content ──────────────────────────────────────
          Obx(() {
            if (ctrl.isAddressLoading.value) {
              return const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                  strokeWidth: 2,
                ),
              );
            }

            final address = ctrl.selectedAddress.value;

            if (address == null) {
              return Text(
                'No delivery address found',
                style: GoogleFonts.manrope(
                  fontSize: sw * 0.03,
                  color: AppColors.textGray,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.isPrimary)
                  Container(
                    margin: EdgeInsets.only(bottom: sw * 0.01),
                    padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.02,
                      vertical: sw * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(sw * 0.02),
                    ),
                    child: Text(
                      'Primary',
                      style: GoogleFonts.manrope(
                        fontSize: sw * 0.025,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                Text(
                  address.addressLine,
                  style: GoogleFonts.manrope(
                    fontSize: sw * 0.032,
                    color: AppColors.textGray,
                    height: 1.5,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final double sw;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({
    required this.sw,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: sw * 0.028,
          horizontal: sw * 0.025,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(sw * 0.025),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: sw * 0.038, color: AppColors.primaryGreen),
            SizedBox(width: sw * 0.012),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: sw * 0.028,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inputText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coupon Code Card ──────────────────────────────────────────────────────────
class _CouponCard extends StatefulWidget {
  final double sw;
  final CartController ctrl;
  const _CouponCard({required this.sw, required this.ctrl});

  @override
  State<_CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<_CouponCard> {
  final TextEditingController _couponCtrl = TextEditingController();
  bool _isApplying = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'Enter Coupon',
        'Please enter a coupon code first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return;
    }
    setState(() => _isApplying = true);
    await widget.ctrl.applyCoupon(code);
    setState(() => _isApplying = false);
  }

  void _removeCoupon() {
    _couponCtrl.clear();
    widget.ctrl.removeCoupon();
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    return Obx(() {
      final isApplied = widget.ctrl.couponApplied.value;
      final couponCode = widget.ctrl.appliedCouponCode.value;
      final couponDiscount = widget.ctrl.couponDiscount.value;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: AppColors.primaryGreen,
                  size: sw * 0.048,
                ),
                SizedBox(width: sw * 0.02),
                Text(
                  'Coupon Code',
                  style: GoogleFonts.manrope(
                    fontSize: sw * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inputText,
                  ),
                ),
              ],
            ),
            SizedBox(height: sw * 0.03),

            if (isApplied) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04,
                  vertical: sw * 0.035,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(sw * 0.03),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(sw * 0.015),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.primaryGreen,
                        size: sw * 0.04,
                      ),
                    ),
                    SizedBox(width: sw * 0.025),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            couponCode.toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: sw * 0.036,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: sw * 0.005),
                          Text(
                            'You save ₹${couponDiscount.toStringAsFixed(2)}',
                            style: GoogleFonts.manrope(
                              fontSize: sw * 0.028,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _removeCoupon,
                      child: Container(
                        padding: EdgeInsets.all(sw * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: sw * 0.038,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: sw * 0.13,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(sw * 0.03),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: _couponCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.manrope(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inputText,
                          letterSpacing: 1.1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: sw * 0.032,
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                          prefixIcon: Icon(
                            Icons.confirmation_number_outlined,
                            color: AppColors.textGray,
                            size: sw * 0.042,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: sw * 0.03,
                            vertical: sw * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: sw * 0.025),
                  GestureDetector(
                    onTap: _isApplying ? null : _applyCoupon,
                    child: Container(
                      height: sw * 0.13,
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.05),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(sw * 0.03),
                      ),
                      alignment: Alignment.center,
                      child: _isApplying
                          ? SizedBox(
                              width: sw * 0.045,
                              height: sw * 0.045,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Apply',
                              style: GoogleFonts.manrope(
                                fontSize: sw * 0.036,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: sw * 0.02),
              Text(
                'Have a discount code? Apply it here.',
                style: GoogleFonts.manrope(
                  fontSize: sw * 0.028,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Pincode Card ───────────────────────────────────────────────────────────
class _PincodeCard extends StatelessWidget {
  final double sw;
  final CartController ctrl;

  const _PincodeCard({required this.sw, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Pincode',
            style: GoogleFonts.manrope(
              fontSize: sw * 0.038,
              fontWeight: FontWeight.w700,
              color: AppColors.inputText,
            ),
          ),

          SizedBox(height: sw * 0.03),

          Container(
            height: sw * 0.13,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(sw * 0.03),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: ctrl.pincodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Enter delivery pincode',
                hintStyle: GoogleFonts.manrope(color: AppColors.textGray),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04,
                  vertical: sw * 0.035,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Method Card ───────────────────────────────────────────────────────
class _PaymentMethodCard extends StatelessWidget {
  final double sw;
  final CartController ctrl;
  const _PaymentMethodCard({required this.sw, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment_outlined,
                  color: AppColors.primaryGreen,
                  size: sw * 0.048,
                ),
                SizedBox(width: sw * 0.02),
                Text(
                  'Payment Method',
                  style: GoogleFonts.manrope(
                    fontSize: sw * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inputText,
                  ),
                ),
              ],
            ),
            SizedBox(height: sw * 0.025),

            _PaymentTile(
              sw: sw,
              icon: Icons.credit_card_rounded,
              title: 'Online Payment',
              subtitle: 'UPI, Cards, Net Banking',
              value: PaymentMethod.online,
              groupValue: ctrl.selectedPayment.value,
              onTap: () => ctrl.selectedPayment.value = PaymentMethod.online,
            ),
            SizedBox(height: sw * 0.025),

            _PaymentTile(
              sw: sw,
              icon: Icons.money_rounded,
              title: 'Cash on Delivery',
              subtitle: 'Pay when your order arrives',
              value: PaymentMethod.cod,
              groupValue: ctrl.selectedPayment.value,
              onTap: () => ctrl.selectedPayment.value = PaymentMethod.cod,
            ),
          ],
        ),
      );
    });
  }
}

class _PaymentTile extends StatelessWidget {
  final double sw;
  final IconData icon;
  final String title;
  final String subtitle;
  final PaymentMethod value;
  final PaymentMethod groupValue;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.sw,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(sw * 0.035),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withOpacity(0.06)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(sw * 0.03),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: sw * 0.11,
              height: sw * 0.11,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withOpacity(0.12)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(sw * 0.025),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryGreen : AppColors.textGray,
                size: sw * 0.055,
              ),
            ),
            SizedBox(width: sw * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: sw * 0.035,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.inputText
                          : AppColors.textGray,
                    ),
                  ),
                  SizedBox(height: sw * 0.005),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: sw * 0.028,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sw * 0.055,
              height: sw * 0.055,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: sw * 0.032)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cart Summary ───────────────────────────────────────────────────────────────
class _CartSummaryCard extends StatelessWidget {
  final double sw;
  final CartController ctrl;
  const _CartSummaryCard({required this.sw, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cart Summary',
              style: GoogleFonts.manrope(
                fontSize: sw * 0.038,
                fontWeight: FontWeight.w700,
                color: AppColors.inputText,
              ),
            ),
            SizedBox(height: sw * 0.025),

            _SummaryRow(
              sw: sw,
              label: 'Subtotal',
              value: '₹${ctrl.subtotal.toStringAsFixed(2)}',
            ),
            SizedBox(height: sw * 0.018),
            _SummaryRow(
              sw: sw,
              label: 'Delivery Charge',
              value: '₹${ctrl.deliveryCharge.toStringAsFixed(2)}',
              strikeValue: ctrl.deliveryCharge < 20 ? '₹20.00' : null,
            ),
            SizedBox(height: sw * 0.018),
            _SummaryRow(
              sw: sw,
              label: 'GST (5%)',
              value: '₹${ctrl.gst.toStringAsFixed(2)}',
            ),
            if (ctrl.discount > 0) ...[
              SizedBox(height: sw * 0.018),
              _SummaryRow(
                sw: sw,
                label: 'Discount',
                value: '- ₹${ctrl.discount.toStringAsFixed(2)}',
                valueColor: AppColors.primaryGreen,
              ),
            ],

            if (ctrl.couponApplied.value) ...[
              SizedBox(height: sw * 0.018),
              _SummaryRow(
                sw: sw,
                label: 'Coupon (${ctrl.appliedCouponCode.value.toUpperCase()})',
                value: '- ₹${ctrl.couponDiscount.value.toStringAsFixed(2)}',
                valueColor: AppColors.primaryGreen,
              ),
            ],

            SizedBox(height: sw * 0.025),
            Divider(color: const Color(0xFFE5E7EB), thickness: 1),
            SizedBox(height: sw * 0.025),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.manrope(
                        fontSize: sw * 0.03,
                        color: AppColors.textGray,
                      ),
                    ),
                    Text(
                      '₹${ctrl.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontSize: sw * 0.05,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inputText,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.04,
                    vertical: sw * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(sw * 0.02),
                  ),
                  child: Text(
                    '${ctrl.cartCount} item${ctrl.cartCount > 1 ? 's' : ''}',
                    style: GoogleFonts.manrope(
                      fontSize: sw * 0.03,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryRow extends StatelessWidget {
  final double sw;
  final String label;
  final String value;
  final String? strikeValue;
  final Color? valueColor;

  const _SummaryRow({
    required this.sw,
    required this.label,
    required this.value,
    this.strikeValue,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: sw * 0.033,
            color: AppColors.textGray,
          ),
        ),
        Row(
          children: [
            if (strikeValue != null) ...[
              Text(
                strikeValue!,
                style: GoogleFonts.manrope(
                  fontSize: sw * 0.03,
                  color: AppColors.textGray,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              SizedBox(width: sw * 0.012),
            ],
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: sw * 0.034,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.inputText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Checkout Bottom Bar ────────────────────────────────────────────────────────
class _CheckoutBar extends StatelessWidget {
  final double sw, hp;
  final CartController ctrl;
  const _CheckoutBar({required this.sw, required this.hp, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPlacing = ctrl.isPlacingOrder.value;
      return Container(
        padding: EdgeInsets.fromLTRB(hp, sw * 0.03, hp, sw * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.manrope(
                    fontSize: sw * 0.028,
                    color: AppColors.textGray,
                  ),
                ),
                Text(
                  '₹${ctrl.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(
                    fontSize: sw * 0.044,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inputText,
                  ),
                ),
              ],
            ),
            SizedBox(width: sw * 0.04),

            Expanded(
              child: GestureDetector(
                onTap: isPlacing
                    ? null
                    : () async {
                        debugPrint(
                          '[_CheckoutBar] "Proceed to Checkout" tapped → payment: ${ctrl.selectedPayment.value}, total: ${ctrl.totalAmount}',
                        );
                        final success = await ctrl.placeOrder();
                        if (success) {
                          Get.off(
                            () => OrderSuccessScreen(
                              totalAmount: ctrl.totalAmount,
                              paymentMethod: ctrl.selectedPayment.value,
                              itemCount: ctrl.cartCount,
                            ),
                          );
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: sw * 0.13,
                  decoration: BoxDecoration(
                    color: isPlacing
                        ? AppColors.primaryGreen.withOpacity(0.6)
                        : AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(sw * 0.035),
                  ),
                  alignment: Alignment.center,
                  child: isPlacing
                      ? SizedBox(
                          width: sw * 0.055,
                          height: sw * 0.055,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Proceed to Checkout',
                          style: GoogleFonts.manrope(
                            fontSize: sw * 0.036,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Empty Cart ─────────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final double sw;
  const _EmptyCart({required this.sw});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: sw * 0.35,
            height: sw * 0.35,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: sw * 0.2,
              color: AppColors.primaryGreen.withOpacity(0.4),
            ),
          ),
          SizedBox(height: sw * 0.06),
          Text(
            'Your cart is empty',
            style: GoogleFonts.manrope(
              fontSize: sw * 0.048,
              fontWeight: FontWeight.w700,
              color: AppColors.inputText,
            ),
          ),
          SizedBox(height: sw * 0.02),
          Text(
            'Add items from the store to get started',
            style: GoogleFonts.manrope(
              fontSize: sw * 0.034,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sw * 0.08),
          GestureDetector(
            onTap: () {
              Get.offAll(() => const MainScreen(initialIndex: 1));
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.1,
                vertical: sw * 0.04,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(sw * 0.04),
              ),
              child: Text(
                'Browse Products',
                style: GoogleFonts.manrope(
                  fontSize: sw * 0.038,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image Placeholder ──────────────────────────────────────────────────────────
class _CartImagePlaceholder extends StatelessWidget {
  final double sw;
  const _CartImagePlaceholder({required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sw * 0.2,
      height: sw * 0.2,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(sw * 0.025),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: sw * 0.1,
        color: Colors.black12,
      ),
    );
  }
}
