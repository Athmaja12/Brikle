// lib/Calculation/View/waterproofing_calculator_page.dart

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Calculation/Controller/waterproofCalculation_provider.dart';
import 'package:brikle/Calculation/Model/waterproofCalculation_model.dart';
import 'package:brikle/Calculation/product_Card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class WaterproofingCalculatorPage extends StatelessWidget {
  const WaterproofingCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WaterproofingCalculatorProvider(),
      child: const _WaterproofingCalculatorView(),
    );
  }
}

class _WaterproofingCalculatorView extends StatefulWidget {
  const _WaterproofingCalculatorView();

  @override
  State<_WaterproofingCalculatorView> createState() =>
      _WaterproofingCalculatorViewState();
}

class _WaterproofingCalculatorViewState
    extends State<_WaterproofingCalculatorView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: Consumer<WaterproofingCalculatorProvider>(
          builder: (context, provider, _) => Text(provider.currentTitle),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<WaterproofingCalculatorProvider>(
        builder: (context, provider, _) {
          if (provider.state == WaterproofingLoadState.idle) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == WaterproofingLoadState.error &&
              provider.calculationResult == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.calculate,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Type Selector (Pill Tabs) ────────────────────────
                _TypeSelector(provider: provider),
                const SizedBox(height: 16),

                // ─── Form Card ──────────────────────────────────────────
                _FormCard(provider: provider),
                const SizedBox(height: 16),

                // ─── Estimate Card ──────────────────────────────────────
                if (provider.calculationResult != null) ...[
                  _EstimateCard(provider: provider),
                  const SizedBox(height: 16),

                  // ─── Products Section ──────────────────────────────────
                  _ProductsSection(provider: provider),
                ],

                // ─── Error Message ──────────────────────────────────────
                if (provider.state == WaterproofingLoadState.error &&
                    provider.calculationResult != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Error: ${provider.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Type Selector (5 Pills) ──────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final WaterproofingCalculatorProvider provider;
  const _TypeSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _TypeChip(
            label: 'Terrace',
            isSelected: provider.currentType == WaterproofingType.terrace,
            onTap: () => provider.switchTo(WaterproofingType.terrace),
          ),
          _TypeChip(
            label: 'Bathroom',
            isSelected: provider.currentType == WaterproofingType.bathroom,
            onTap: () => provider.switchTo(WaterproofingType.bathroom),
          ),
          _TypeChip(
            label: 'Tank',
            isSelected: provider.currentType == WaterproofingType.tank,
            onTap: () => provider.switchTo(WaterproofingType.tank),
          ),
          _TypeChip(
            label: 'Wall',
            isSelected: provider.currentType == WaterproofingType.wall,
            onTap: () => provider.switchTo(WaterproofingType.wall),
          ),
          _TypeChip(
            label: 'LW+',
            isSelected:
                provider.currentType == WaterproofingType.liquidWaterproofing,
            onTap: () =>
                provider.switchTo(WaterproofingType.liquidWaterproofing),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

// ─── Form Card ─────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final WaterproofingCalculatorProvider provider;
  const _FormCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the dimensions. Tap Calculate to see your estimate.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // ─── Dynamic Fields ──────────────────────────────────────────
          if (provider.showTerraceFields) ...[_buildTerraceFields()],

          if (provider.showBathroomFields) ...[_buildBathroomFields()],

          if (provider.showTankFields) ...[_buildTankFields()],

          if (provider.showWallFields) ...[_buildWallFields()],

          if (provider.showLiquidWaterproofingFields) ...[
            _buildLiquidWaterproofingFields(),
          ],

          const SizedBox(height: 20),

          // ─── Calculate Button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.state == WaterproofingLoadState.calculating
                  ? null
                  : provider.calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: provider.state == WaterproofingLoadState.calculating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Calculate'),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerraceFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Terrace length (ft)',
                controller: provider.terraceLengthCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Terrace width (ft)',
                controller: provider.terraceWidthCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _NumberField(
          label: 'Coats applied',
          controller: provider.terraceCoatsCtrl,
        ),
      ],
    );
  }

  Widget _buildBathroomFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Floor length (ft)',
                controller: provider.bathroomFloorLengthCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Floor width (ft)',
                controller: provider.bathroomFloorWidthCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _NumberField(
          label: 'Wall height to coat (ft)',
          controller: provider.bathroomWallHeightCtrl,
        ),
      ],
    );
  }

  Widget _buildTankFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Tank length (ft)',
                controller: provider.tankLengthCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Tank width (ft)',
                controller: provider.tankWidthCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Tank height (ft)',
                controller: provider.tankHeightCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Number of walls',
                controller: provider.tankWallsCtrl,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWallFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Wall length (ft)',
                controller: provider.wallLengthCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Wall height (ft)',
                controller: provider.wallHeightCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _NumberField(
          label: 'Coats applied',
          controller: provider.wallCoatsCtrl,
        ),
      ],
    );
  }

  Widget _buildLiquidWaterproofingFields() {
    return Column(
      children: [
        _NumberField(
          label: 'Number of cement bags',
          controller: provider.cementBagsCtrl,
        ),
      ],
    );
  }
}

// ─── Number Field ──────────────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _NumberField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ─── Estimate Card ─────────────────────────────────────────────────────────

class _EstimateCard extends StatelessWidget {
  final WaterproofingCalculatorProvider provider;
  const _EstimateCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final result = provider.calculationResult!;
    final estimate = result.estimate;
    final inputs = result.inputs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your estimate',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // ─── Product ──────────────────────────────────────────────────
          _row('Product', inputs.selectedProduct),

          // ─── Dynamic Estimate Rows ───────────────────────────────────
          _buildEstimateRows(estimate),
          const SizedBox(height: 8),

          // ─── Total Estimate ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL ESTIMATE',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  estimate.totalEstimate,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),

          // ─── Tip ──────────────────────────────────────────────────────
          const SizedBox(height: 8),
          _buildTip(provider.currentType),
        ],
      ),
    );
  }

  Widget _buildEstimateRows(WaterproofingEstimate estimate) {
    List<Widget> rows = [];

    // Terrace or Wall
    if (estimate.materialRequiredLitres != null) {
      rows.add(_row('Material required', estimate.materialRequiredLitres!));
    }
    if (estimate.bucketsNeeded != null) {
      rows.add(_row('Buckets needed', estimate.bucketsNeeded!));
    }
    if (estimate.materialRequiredKg != null) {
      rows.add(_row('Material required', estimate.materialRequiredKg!));
    }
    if (estimate.packsNeeded != null) {
      rows.add(_row('Packs needed', estimate.packsNeeded!));
    }
    if (estimate.kitsNeeded != null) {
      rows.add(_row('Kits needed', estimate.kitsNeeded!));
    }
    if (estimate.totalDosage != null) {
      rows.add(_row('Total dosage', estimate.totalDosage!));
    }
    if (estimate.litresNeeded != null) {
      rows.add(_row('Litres needed', estimate.litresNeeded!));
    }
    if (estimate.suggestedPacks != null) {
      rows.add(_row('Suggested packs', estimate.suggestedPacks!));
    }

    // Always show material cost
    rows.add(_row('Material cost', estimate.materialCost));

    return Column(children: rows);
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(WaterproofingType type) {
    String tip;
    switch (type) {
      case WaterproofingType.terrace:
        tip =
            'Apply at least 2 coats for best results. Ensure surface is clean and dry before application.';
        break;
      case WaterproofingType.bathroom:
        tip =
            'Coat walls up to 3ft height and entire floor. Allow proper drying time between coats.';
        break;
      case WaterproofingType.tank:
        tip =
            'Coat all internal surfaces including floor and walls. Use food-grade waterproofing for drinking water tanks.';
        break;
      case WaterproofingType.wall:
        tip =
            'Apply on exterior walls facing rain. Consider 2-3 coats for maximum protection.';
        break;
      case WaterproofingType.liquidWaterproofing:
        tip =
            'Add LW+ to cement mortar at recommended dosage. Mix thoroughly for uniform protection.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tip, style: const TextStyle(fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─── Products Section ──────────────────────────────────────────────────────

// ─── Products Section ──────────────────────────────────────────────────────

class _ProductsSection extends StatelessWidget {
  final WaterproofingCalculatorProvider provider;
  const _ProductsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final related = provider.calculationResult?.relatedProducts;
    final products = related == null
        ? <WaterproofingProduct>[]
        : [...related.waterproofing, ...related.admixture];

    debugPrint(
      '[WaterproofingProductsSection] rendering ${products.length} card(s)',
    );
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buy Waterproofing Products',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SharedProductCard(
                title: product.name,
                subtitle: product.quantityDisplay,
                priceText: product.priceDisplay,
                imageUrl: provider.getProductImage(product.variantId),
                isImageLoading: provider.isLoadingImages,
                variantId: product.variantId,
                placeholderIcon: Icons.water_drop,
                // No stock field in this API — treat as always available.
                inStock: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

// // ─── Product Variant Card ──────────────────────────────────────────────────

// // lib/Calculation/View/waterproofing_calculator_page.dart

// // Replace the _ProductVariantCard class with this updated version:

// class _ProductVariantCard extends StatelessWidget {
//   final WaterproofingProduct product;
//   final WaterproofingCalculatorProvider provider;

//   static const double _cardWidth = 170;

//   const _ProductVariantCard({required this.product, required this.provider});

//   bool get _inStock => true;

//   Future<void> _handleAddToCart(BuildContext context) async {
//     final success = await provider.addVariantToCart(product.variantId);
//     if (!context.mounted) return;

//     if (!success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Could not add to cart: ${provider.errorMessage}'),
//         ),
//       );
//       return;
//     }

//     try {
//       final cartController = Get.find<CartController>();
//       await cartController.fetchCart(showLoader: false);
//     } catch (_) {}

//     Get.snackbar(
//       'Added to cart',
//       '${product.name} added successfully',
//       backgroundColor: const Color(0xFF2E7D32),
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 1),
//     );

//     if (!context.mounted) return;
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
//       (route) => false,
//     );
//   }

//   Widget _buildThumbnail() {
//     final imageUrl = provider.getProductImage(product.materialId);

//     return Container(
//       width: double.infinity,
//       height: 100, // Fixed height instead of AspectRatio
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFEFEFEF)),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: imageUrl != null && imageUrl.isNotEmpty
//           ? Padding(
//               padding: const EdgeInsets.all(8),
//               child: Image.network(
//                 imageUrl,
//                 fit: BoxFit.contain,
//                 loadingBuilder: (context, child, progress) {
//                   if (progress == null) return child;
//                   return const Center(
//                     child: SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                   );
//                 },
//                 errorBuilder: (context, error, stackTrace) =>
//                     const Icon(Icons.water_drop, size: 32, color: Colors.grey),
//               ),
//             )
//           : provider.isLoadingImages
//           ? const Center(
//               child: SizedBox(
//                 height: 20,
//                 width: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             )
//           : Center(
//               child: Icon(Icons.water_drop, size: 40, color: Colors.grey[400]),
//             ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isAdding = provider.addingToCartVariantIds.contains(
//       product.variantId,
//     );

//     return Container(
//       width: _cardWidth,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFEFEFEF)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // ─── Product Image ──────────────────────────────────────────
//           _buildThumbnail(),
//           const SizedBox(height: 8),

//           // ─── Product Name ───────────────────────────────────────────
//           Text(
//             product.name,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               height: 1.3,
//             ),
//           ),
//           const SizedBox(height: 2),

//           // ─── Packs Needed ───────────────────────────────────────────
//           Text(
//             '${product.packsNeeded} needed',
//             style: TextStyle(fontSize: 11, color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 4),

//           // ─── Price & Packs ──────────────────────────────────────────
//           Row(
//             children: [
//               Text(
//                 '₹${product.pricePerPack.toStringAsFixed(0)}/pack',
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(width: 4),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE8F5E9),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   '${product.rawPacks} packs',
//                   style: const TextStyle(
//                     fontSize: 9,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2E7D32),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),

//           // ─── Add to Cart Button ────────────────────────────────────
//           SizedBox(
//             width: double.infinity,
//             height: 32,
//             child: ElevatedButton(
//               onPressed: isAdding ? null : () => _handleAddToCart(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF2E7D32),
//                 foregroundColor: Colors.white,
//                 disabledBackgroundColor: Colors.grey[300],
//                 elevation: 0,
//                 padding: EdgeInsets.zero,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: isAdding
//                   ? const SizedBox(
//                       height: 14,
//                       width: 14,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                   : const Text(
//                       'Add to Cart',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
