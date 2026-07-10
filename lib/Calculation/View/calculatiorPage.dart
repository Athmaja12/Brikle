import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/Calculation/View/calculations_Page.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
import 'package:brikle/HomePage/View/notificationpage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ── Material Calculator listing page ────────────────────────────────────
/// UI-only for now — the calculation/BOM logic API is still in progress.
/// Each card's "Open Calculator" currently just calls [onOpen], which is
/// wired to a placeholder so nothing crashes; swap the callback for real
/// navigation (e.g. `Get.to(() => PaintCalculatorPage())`) once the
/// respective logic/controller is ready.
///
/// This page is rendered inside MainScreen's IndexedStack (index 2,
/// "Calculate" tab), so it does NOT provide its own bottomNavigationBar —
/// CustomBottomNav from MainScreen already wraps it, same pattern as
/// CartScreen / HomeScreen / ProfileView.
class CalculatorPage extends GetView<HomeController> {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F6),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(controller: controller),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, 16),
                ),
                children: [
                  SizedBox(height: Responsive.space(context, 16)),
                  Text(
                    'Material Calculator',
                    style: AppTextStyles.welcomeBackTitle(
                      context,
                    ).copyWith(fontSize: 18),
                  ),
                  SizedBox(height: Responsive.space(context, 12)),
                  for (final item in _calculatorItems) ...[
                    _CalculatorCard(item: item),
                    SizedBox(height: Responsive.space(context, 12)),
                  ],
                  SizedBox(height: Responsive.space(context, 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header: Deliver To + logo + icons, search bar ──────────────────────────
// Same header used on HomeScreen, kept inline here (not a shared file) per
// request. If the two ever need to diverge, this copy can be edited
// independently without touching homepage.dart.
class _Header extends StatelessWidget {
  final HomeController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: Responsive.space(context, 12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryGreen, size: 18),
              SizedBox(width: Responsive.space(context, 4)),
              Obx(
                () => GestureDetector(
                  onTap: () => _showPincodeSheet(context, controller),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Deliver To',
                        style: AppTextStyles.termsText(context),
                      ),
                      Row(
                        children: [
                          Text(
                            controller.deliverToPincode.value,
                            style: AppTextStyles.fieldLabel(context).copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Br',
                      style: AppTextStyles.brikleLogoAccent(
                        context,
                      ).copyWith(fontSize: 20),
                    ),
                    TextSpan(
                      text: 'ikle',
                      style: AppTextStyles.brikleLogoDark(
                        context,
                      ).copyWith(fontSize: 20),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // TODO: Navigate to Wishlist Screen
                  // Get.to(() => const WishlistScreen());
                },
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 22,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: Responsive.space(context, 16)),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Get.to(() => const NotificationScreen());
                },
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, 12)),
          Container(
            height: Responsive.height(context, 44),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 12),
            ),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textGray, size: 20),
                SizedBox(width: Responsive.space(context, 8)),
                Expanded(
                  child: Text(
                    "Search for 'Asian Paints'",
                    style: AppTextStyles.loginSubtitle(
                      context,
                    ).copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showPincodeSheet(BuildContext context, HomeController controller) {
  final textController = TextEditingController(
    text: controller.deliverToPincode.value,
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check delivery availability',
              style: AppTextStyles.welcomeBackTitle(
                context,
              ).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter pincode',
                counterText: '',
                filled: true,
                fillColor: AppColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.isCheckingPincode.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.pincodeMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  controller.pincodeMessage.value,
                  style: TextStyle(
                    color: controller.isPincodeServiceable.value
                        ? AppColors.primaryGreen
                        : AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final pin = textController.text.trim();
                  if (pin.length == 6) {
                    controller.checkPincode(pin);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Check',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ── Calculator card ─────────────────────────────────────────────────────
class _CalculatorCard extends StatelessWidget {
  final MaterialCalculatorItem item;
  const _CalculatorCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image / icon placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 76,
                  height: 76,
                  color: item.iconBackground,
                  child: Icon(item.icon, color: item.iconColor, size: 32),
                ),
              ),
              SizedBox(width: Responsive.space(context, 14)),

              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.fieldLabel(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    SizedBox(height: Responsive.space(context, 4)),
                    Text(
                      item.description,
                      style: AppTextStyles.termsText(
                        context,
                      ).copyWith(color: AppColors.textGray, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, 14)),

          // Full-width button spans the whole card, below the image+text row
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  item.onOpen ?? () => _openComingSoon(context, item.title),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Open Calculator',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model + static list (UI placeholder — swap onOpen for real nav
// once each calculator's logic/controller is ready) ───────────────────────
class MaterialCalculatorItem {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback? onOpen;

  const MaterialCalculatorItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.onOpen,
  });
}

void _openComingSoon(BuildContext context, String name) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$name — coming soon')));
}

final List<MaterialCalculatorItem> _calculatorItems = [
  MaterialCalculatorItem(
    title: 'Paint Calculator',
    description:
        'Asian Paints Tractor (interior, 140 sqft/L) or Ace (exterior, '
        '110 sqft/L). Wall area x coats -> litres, packs and cost.',
    icon: Icons.format_paint_outlined,
    iconBackground: const Color(0xFFEFEAFB),
    iconColor: const Color(0xFF6B4FBB),
    onOpen: () => Get.to(() => const PaintCalculatorPage()),
  ),
  MaterialCalculatorItem(
    title: 'AAC Block Calculator',
    description:
        '4", 6", 8" or 9" blocks for any wall area. Live block + adhesive '
        'bag prices. Adjustable wastage.',
    icon: Icons.view_module_outlined,
    iconBackground: const Color(0xFFEFEFEF),
    iconColor: const Color(0xFF8A8A8A),
  ),
  MaterialCalculatorItem(
    title: 'Cement Calculator',
    description:
        'Three jobs -- plastering, column concrete, roof slab. Cement '
        'bags + sand + 20mm aggregate by mix grade (M20 / M25 / M30).',
    icon: Icons.foundation_outlined,
    iconBackground: const Color(0xFFFDE9E7),
    iconColor: const Color(0xFFCC3B2F),
  ),
  MaterialCalculatorItem(
    title: 'Dr. Fixit Waterproofing',
    description:
        'Terrace, bathroom, water tank, exterior, LW+ dosage. Picks the '
        'right Dr. Fixit product per job with official coverage rates.',
    icon: Icons.water_drop_outlined,
    iconBackground: const Color(0xFFFFF3D9),
    iconColor: const Color(0xFFE0A200),
  ),
  MaterialCalculatorItem(
    title: 'TMT Steel Calculator',
    description:
        'Multi-row BOM: add 8 / 10 / 12 / 16 / 20mm rods with quantities. '
        'Total kg + tonnes via the D squared / 162 formula.',
    icon: Icons.construction_outlined,
    iconBackground: const Color(0xFFECECEC),
    iconColor: const Color(0xFF6B6B6B),
  ),
];
 