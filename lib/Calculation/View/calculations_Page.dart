// view/paint_calculator_screen.dart

import 'package:brikle/Calculation/Controller/productCalculation_provider.dart';
import 'package:brikle/Calculation/Model/productCalculator_model.dart';
import 'package:brikle/Calculation/product_Card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaintCalculatorScreen extends StatelessWidget {
  const PaintCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaintCalculatorProvider()..loadDropdown(),
      child: const _PaintCalculatorView(),
    );
  }
}

class _PaintCalculatorView extends StatelessWidget {
  const _PaintCalculatorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text('Paint Calculator'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<PaintCalculatorProvider>(
        builder: (context, provider, _) {
          if (provider.state == PaintLoadState.loadingDropdown) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.state == PaintLoadState.error &&
              provider.estimate == null &&
              provider.paintOptions.isEmpty) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormCard(provider: provider),
                const SizedBox(height: 16),
                if (provider.state == PaintLoadState.error &&
                    provider.estimate == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Error: ${provider.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (provider.estimate != null) ...[
                  _EstimateCard(provider: provider),
                  const SizedBox(height: 16),
                  _SuggestedProductsSection(provider: provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final PaintCalculatorProvider provider;
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
            'Calculate Paint for your Wall',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'All measurements are in feet. Tap Calculate to see your estimate and product options.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          const Text(
            'Paint type',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<PaintDropdownItem>(
            value: provider.selectedPaint,
            isExpanded: true,
            decoration: _fieldDecoration(),
            items: provider.paintOptions
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.displayName, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) provider.selectPaint(value);
            },
          ),
          const SizedBox(height: 16),

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
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Number of walls',
                  controller: provider.wallsCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: 'Number of coats',
                  controller: provider.coatsCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.state == PaintLoadState.calculating
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
              child: provider.state == PaintLoadState.calculating
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

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

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

class _EstimateCard extends StatelessWidget {
  final PaintCalculatorProvider provider;
  const _EstimateCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final estimate = provider.estimate!;
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
          _row('Product', estimate.product),
          _row('Wall area', estimate.wallArea),
          _row('Total painting area', estimate.totalPaintingArea),
          _row('Paint required', estimate.paintRequired),
          _row('Suggested pack', estimate.suggestedPack),
          const SizedBox(height: 16),
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
                  'ESTIMATED COST',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  estimate.estimatedCost,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

/// Renders "Available variants in DB" as fixed-width, horizontally
/// scrollable product cards (170px wide) — this fixes the earlier bug
/// where a card was stretching to the full screen width.
class _SuggestedProductsSection extends StatelessWidget {
  final PaintCalculatorProvider provider;
  const _SuggestedProductsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final variants = provider.estimate?.variants ?? [];
    if (variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buy Paints Now',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          // Card content is ~268px tall (144 image + text rows + button) —
          // plus the card's own 12px top/bottom padding (24px total).
          // Previous value (268) didn't leave room for that padding, which
          // is what caused the bottom overflow.
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: variants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ProductVariantCard(
                variant: variants[index],
                productName: provider.estimate!.product,
                provider: provider,
              );
            },
          ),
        ),
      ],
    );
  }
}

// class _ProductVariantCard extends StatelessWidget {
//   final PaintVariant variant;
//   final String productName;
//   final PaintCalculatorProvider provider;

//   static const double _cardWidth = 170;

//   const _ProductVariantCard({
//     required this.variant,
//     required this.productName,
//     required this.provider,
//   });

//   bool get _inStock => variant.stockStatus.toLowerCase().contains('in stock');

//   Future<void> _handleAddToCart(BuildContext context) async {
//     final success = await provider.addVariantToCart(variant.variantId);
//     if (!context.mounted) return;

//     if (!success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Could not add to cart: ${provider.errorMessage}'),
//         ),
//       );
//       return;
//     }

//     // Refresh the GetX CartController so the item you just added (added via
//     // a plain API call here, not through the controller) actually shows up
//     // when the Cart tab renders.
//     try {
//       final cartController = Get.find<CartController>();
//       await cartController.fetchCart(showLoader: false);
//     } catch (_) {
//       // CartController not registered yet somehow — cart screen will
//       // still fetch on its own init, so this is non-fatal.
//     }

//     Get.snackbar(
//       'Added to cart',
//       '${variant.packSize} pack added successfully',
//       backgroundColor: const Color(0xFF2E7D32),
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 1),
//     );

//     if (!context.mounted) return;

//     // Same navigation pattern your cart screen's own back button uses.
//     // NOTE: index assumes bottom-nav order Home(0) / Categories(1) /
//     // Calculate(2) / Cart(3) / Profile(4) per the Figma — adjust the
//     // initialIndex below if your MainScreen orders tabs differently.
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
//       (route) => false,
//     );
//   }

//   Widget _buildThumbnail() {
//     final imageUrl = provider.productImageUrl;

//     return AspectRatio(
//       aspectRatio: 1,
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: const Color(0xFFEFEFEF)),
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: imageUrl != null && imageUrl.isNotEmpty
//             ? Padding(
//                 // Contain + padding, not cover — avoids cropping labels/
//                 // logos on the product image awkwardly.
//                 padding: const EdgeInsets.all(8),
//                 child: Image.network(
//                   imageUrl,
//                   fit: BoxFit.contain,
//                   loadingBuilder: (context, child, progress) {
//                     if (progress == null) return child;
//                     return const Center(
//                       child: SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     );
//                   },
//                   errorBuilder: (context, error, stackTrace) => const Icon(
//                     Icons.format_paint,
//                     size: 32,
//                     color: Colors.grey,
//                   ),
//                 ),
//               )
//             : provider.isLoadingImage
//             ? const Center(
//                 child: SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//               )
//             : const Center(
//                 child: Icon(Icons.format_paint, size: 32, color: Colors.grey),
//               ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isAdding = provider.addingToCartVariantIds.contains(
//       variant.variantId,
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
//           _buildThumbnail(),
//           const SizedBox(height: 8),
//           Text(
//             productName,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               height: 1.3,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             variant.packSize,
//             style: TextStyle(fontSize: 11, color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             children: [
//               Text(
//                 variant.price,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   variant.stockStatus,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                     color: _inStock
//                         ? const Color(0xFF2E7D32)
//                         : Colors.orange[800],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             width: double.infinity,
//             height: 34,
//             child: ElevatedButton(
//               onPressed: (!_inStock || isAdding)
//                   ? null
//                   : () => _handleAddToCart(context),
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
//                   : Text(
//                       _inStock ? 'Add to Cart' : 'Out of Stock',
//                       style: const TextStyle(
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
