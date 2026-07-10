import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/BottomNavigation/bottomnavigation.dart';
import 'package:flutter/material.dart';

/// ── Paint Calculator page ───────────────────────────────────────────────
/// UI-only — the calculation logic API is still in progress. All input
/// fields are pre-filled with the same sample values shown in the Figma
/// (wall length 12ft, height 10ft, 4 walls, 8 coats) and "Your estimate"
/// shows static numbers matching the design. Wire real logic later by:
///   1. Turning this into a StatefulWidget (or GetView<PaintCalcController>)
///   2. Reading the TextField values on change / on Calculate tap
///   3. Replacing the static _EstimateCard values with computed ones
///
/// Pushed on top of MainScreen (back arrow, not a bottom-nav tab) — the
/// bottom bar shown here is CustomBottomNav for visual match with the
/// Figma frame; tapping it just pops back to MainScreen since this is a
/// stacked detail page, not one of the 5 real tabs.
class PaintCalculatorPage extends StatelessWidget {
  const PaintCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F6),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, 16),
                ),
                children: [
                  SizedBox(height: Responsive.space(context, 16)),
                  const _CalculateCard(),
                  SizedBox(height: Responsive.space(context, 16)),
                  const _EstimateCard(),
                  SizedBox(height: Responsive.space(context, 20)),
                  Text(
                    'Buy Paints Now',
                    style: AppTextStyles.welcomeBackTitle(
                      context,
                    ).copyWith(fontSize: 17),
                  ),
                  SizedBox(height: Responsive.space(context, 12)),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _buyNowProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 240,
                        ),
                    itemBuilder: (context, index) =>
                        _BuyNowCard(product: _buyNowProducts[index]),
                  ),
                  SizedBox(height: Responsive.space(context, 16)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (_) => Navigator.of(context).pop(),
      ),
    );
  }
}

// ── Top bar: back arrow + title ────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 8),
        vertical: Responsive.space(context, 8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Paint Calculator',
            style: AppTextStyles.welcomeBackTitle(
              context,
            ).copyWith(fontSize: 17),
          ),
        ],
      ),
    );
  }
}

// ── "Calculate Paint for your wall" input card ───────────────────────────
class _CalculateCard extends StatelessWidget {
  const _CalculateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculate Paint for your wall',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          SizedBox(height: Responsive.space(context, 4)),
          Text(
            'All measurements in feet. The calculator updates live with '
            'prices.',
            style: AppTextStyles.termsText(
              context,
            ).copyWith(color: AppColors.textGray, fontSize: 12.5),
          ),
          SizedBox(height: Responsive.space(context, 16)),

          _FieldLabel('Paint type'),
          SizedBox(height: Responsive.space(context, 6)),
          _ReadonlyField(value: 'Asian Paints Ultra Max'),
          SizedBox(height: Responsive.space(context, 16)),

          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'Wall length',
                  unit: '(ft)',
                  initialValue: '12',
                ),
              ),
              SizedBox(width: Responsive.space(context, 12)),
              Expanded(
                child: _LabeledInput(
                  label: 'Wall height',
                  unit: '(ft)',
                  initialValue: '10',
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, 16)),

          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'Number of walls',
                  initialValue: '4',
                ),
              ),
              SizedBox(width: Responsive.space(context, 12)),
              Expanded(
                child: _LabeledInput(
                  label: 'Number of coats',
                  initialValue: '8',
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, 20)),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calculation logic coming soon'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Calculate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.termsText(
        context,
      ).copyWith(color: AppColors.textGray, fontSize: 13),
    );
  }
}

// Read-only "dropdown-look" field for Paint type (no live options wired yet)
class _ReadonlyField extends StatelessWidget {
  final String value;
  const _ReadonlyField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(
        value,
        style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      ),
    );
  }
}

// Label + bordered numeric TextField, pre-filled with a static value
class _LabeledInput extends StatelessWidget {
  final String label;
  final String? unit;
  final String initialValue;

  const _LabeledInput({
    required this.label,
    required this.initialValue,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.termsText(
              context,
            ).copyWith(color: AppColors.textGray, fontSize: 13),
            children: [
              TextSpan(text: label),
              if (unit != null) TextSpan(text: ' $unit'),
            ],
          ),
        ),
        SizedBox(height: Responsive.space(context, 6)),
        TextField(
          controller: TextEditingController(text: initialValue),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
          ),
        ),
      ],
    );
  }
}

// ── "Your estimate" card ─────────────────────────────────────────────────
class _EstimateCard extends StatelessWidget {
  const _EstimateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your estimate',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          SizedBox(height: Responsive.space(context, 4)),
          Text(
            'Updates automatically as you type.',
            style: AppTextStyles.termsText(
              context,
            ).copyWith(color: AppColors.textGray, fontSize: 12.5),
          ),
          SizedBox(height: Responsive.space(context, 14)),

          const _EstimateRow(
            label: 'Product',
            value: 'Asian Paints Ace Exterior\nEmulsion White',
          ),
          const _EstimateRow(label: 'Wall area', value: '480 sqft'),
          const _EstimateRow(label: 'Total painting area', value: '960 sqft'),
          const _EstimateRow(label: 'Paint required', value: '8.7 L'),
          const _EstimateRow(
            label: 'Suggested pack',
            value: '2 x 4L + 1 x 1L',
          ),

          SizedBox(height: Responsive.space(context, 14)),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTIMATED COST',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '₹1,920',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'live price · ₹220/L · materials only',
                  style: AppTextStyles.termsText(
                    context,
                  ).copyWith(color: AppColors.textGray, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  final String label;
  final String value;
  const _EstimateRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.termsText(
              context,
            ).copyWith(color: AppColors.textGray, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── "Buy Paints Now" cross-sell cards ─────────────────────────────────────
class BuyNowProduct {
  final String name;
  final int originalPrice;
  final int discountedPrice;
  final int discountPercent;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const BuyNowProduct({
    required this.name,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

const List<BuyNowProduct> _buyNowProducts = [
  BuyNowProduct(
    name: 'Ultratech PPC Cement, 50 Kg Bag',
    originalPrice: 2999,
    discountedPrice: 1199,
    discountPercent: 60,
    icon: Icons.inventory_2_outlined,
    iconBackground: Color(0xFFE9F1FB),
    iconColor: Color(0xFF3B6FB0),
  ),
  BuyNowProduct(
    name: 'Birla White Activcoat Exterior Primer, 20 Litre Bucket',
    originalPrice: 2999,
    discountedPrice: 1199,
    discountPercent: 60,
    icon: Icons.format_paint_outlined,
    iconBackground: Color(0xFFFDEBEC),
    iconColor: Color(0xFFCC3B2F),
  ),
];

class _BuyNowCard extends StatelessWidget {
  final BuyNowProduct product;
  const _BuyNowCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  '${product.discountPercent}% Off',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.favorite_border, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: product.iconBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                child: Icon(product.icon, color: product.iconColor, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.fieldLabel(
              context,
            ).copyWith(color: AppColors.textDark, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '₹${product.discountedPrice}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '₹${product.originalPrice}',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textGray,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: wire to CartController.addToCart(...)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}