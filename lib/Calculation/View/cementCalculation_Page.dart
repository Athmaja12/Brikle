// lib/Calculation/View/cementcalculation_page.dart

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Calculation/Controller/cementcalculation_provider.dart';
import 'package:brikle/Calculation/Model/cementCalculation_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CementCalculationPage extends StatelessWidget {
  const CementCalculationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CementCalculationProvider()..loadDropdown(),
      child: const _CementCalculationView(),
    );
  }
}

class _CementCalculationView extends StatefulWidget {
  const _CementCalculationView();

  @override
  State<_CementCalculationView> createState() => _CementCalculationViewState();
}

class _CementCalculationViewState extends State<_CementCalculationView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: Consumer<CementCalculationProvider>(
          builder: (context, provider, _) => Text(provider.currentTitle),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<CementCalculationProvider>(
        builder: (context, provider, _) {
          if (provider.state == CementLoadState.loadingDropdown) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == CementLoadState.error &&
              provider.estimate == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.loadDropdown,
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
                // ─── Type Selector ──────────────────────────────────────
                _TypeSelector(provider: provider),
                const SizedBox(height: 16),

                // ─── Form Card ──────────────────────────────────────────
                _FormCard(provider: provider),
                const SizedBox(height: 16),

                // ─── Estimate Card ──────────────────────────────────────
                if (provider.estimate != null) ...[
                  _EstimateCard(provider: provider),
                  const SizedBox(height: 16),
                ],

                // ─── Similar Products ──────────────────────────────────
                if (provider.similarProducts.isNotEmpty) ...[
                  _SimilarProductsSection(provider: provider),
                ],

                if (provider.state == CementLoadState.error &&
                    provider.estimate != null)
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

// ─── Type Selector ──────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final CementCalculationProvider provider;
  const _TypeSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TypeTab(
            label: 'Plastering',
            isSelected: provider.currentType == CementCalculatorType.plastering,
            onTap: () => provider.switchTo(CementCalculatorType.plastering),
          ),
          _TypeTab(
            label: 'Column Concrete',
            isSelected:
                provider.currentType == CementCalculatorType.columnConcrete,
            onTap: () => provider.switchTo(CementCalculatorType.columnConcrete),
          ),
          _TypeTab(
            label: 'Roof Slab',
            isSelected: provider.currentType == CementCalculatorType.roofSlab,
            onTap: () => provider.switchTo(CementCalculatorType.roofSlab),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TypeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form Card ─────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final CementCalculationProvider provider;
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
          const SizedBox(height: 16),

          // ─── Plastering Fields ──────────────────────────────────────
          if (provider.showPlasteringFields) ...[_buildPlasteringFields()],

          // ─── Column Concrete Fields ────────────────────────────────
          if (provider.showColumnConcreteFields) ...[
            _buildColumnConcreteFields(),
          ],

          // ─── Roof Slab Fields ───────────────────────────────────────
          if (provider.showRoofSlabFields) ...[_buildRoofSlabFields()],

          const SizedBox(height: 16),

          // ─── Shared Fields ──────────────────────────────────────────
          _NumberField(
            label: 'Cement bag price (₹/50kg)',
            controller: provider.cementPriceCtrl,
          ),
          const SizedBox(height: 20),

          // ─── Calculate Button ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.state == CementLoadState.calculating
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
              child: provider.state == CementLoadState.calculating
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

  Widget _buildPlasteringFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plaster Thickness
        const Text(
          'Plaster Thickness — pick your job',
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children:
              provider.dropdownData?.plasteringOptions.thicknessOptions
                  .map(
                    (option) => ChoiceChip(
                      label: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.selectedThickness == option
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      selected: provider.selectedThickness == option,
                      onSelected: (_) => provider.selectThickness(option),
                      selectedColor: const Color(0xFF2E7D32),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                  .toList() ??
              [],
        ),
        const SizedBox(height: 12),

        // Or enter thickness
        _NumberField(
          label: 'Or enter thickness (mm)',
          controller: provider.plasterThicknessCtrl,
          onChanged: (_) => provider.selectedThickness = null,
        ),
        const SizedBox(height: 16),

        // Mortar Ratio
        const Text(
          'Mortar Ratio',
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children:
              provider.dropdownData?.plasteringOptions.mortarRatios
                  .map(
                    (ratio) => ChoiceChip(
                      label: Text(
                        ratio.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.selectedMortarRatio == ratio
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      selected: provider.selectedMortarRatio == ratio,
                      onSelected: (_) => provider.selectMortarRatio(ratio),
                      selectedColor: const Color(0xFF2E7D32),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                  .toList() ??
              [],
        ),
        const SizedBox(height: 16),

        // Wall Area
        _NumberField(
          label: 'Wall area (sqft)',
          controller: provider.wallAreaCtrl,
        ),
      ],
    );
  }

  Widget _buildColumnConcreteFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number of Columns
        _NumberField(
          label: 'Number of Columns',
          controller: provider.columnCountCtrl,
        ),
        const SizedBox(height: 16),

        // Concrete Grade
        const Text(
          'Concrete Grade',
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: provider.concreteGrades
              .map(
                (grade) => ChoiceChip(
                  label: Text(
                    grade.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: provider.selectedConcreteGrade == grade.value
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  selected: provider.selectedConcreteGrade == grade.value,
                  onSelected: (_) => provider.selectConcreteGrade(grade.value),
                  selectedColor: const Color(0xFF2E7D32),
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),

        // Column Dimensions
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Column width (mm)',
                controller: provider.columnWidthCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Column depth (mm)',
                controller: provider.columnDepthCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _NumberField(
          label: 'Column height (ft)',
          controller: provider.columnHeightCtrl,
        ),
      ],
    );
  }

  Widget _buildRoofSlabFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slab Dimensions
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Slab length (ft)',
                controller: provider.slabLengthCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Slab width (ft)',
                controller: provider.slabWidthCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Thickness
        _NumberField(
          label: 'Thickness (mm) — 125 mm standard',
          controller: provider.roofThicknessCtrl,
        ),
        const SizedBox(height: 16),

        // Concrete Grade
        const Text(
          'Concrete Grade',
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: provider.concreteGrades
              .map(
                (grade) => ChoiceChip(
                  label: Text(
                    grade.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: provider.selectedConcreteGrade == grade.value
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  selected: provider.selectedConcreteGrade == grade.value,
                  onSelected: (_) => provider.selectConcreteGrade(grade.value),
                  selectedColor: const Color(0xFF2E7D32),
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(String)? onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    this.onChanged,
  });

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
          onChanged: onChanged,
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

// ─── Estimate Card ──────────────────────────────────────────────────────────

class _EstimateCard extends StatelessWidget {
  final CementCalculationProvider provider;
  const _EstimateCard({required this.provider});

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
            'Your estimate',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildEstimateRows(),
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
                  'CEMENT COST',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCost(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          _buildTip(),
        ],
      ),
    );
  }

  String _getCost() {
    final estimate = provider.estimate;
    if (estimate is PlasteringEstimate) {
      return estimate.userEstimatedCost;
    } else if (estimate is ColumnConcreteEstimate) {
      return estimate.userEstimatedCost;
    } else if (estimate is RoofSlabEstimate) {
      return estimate.userEstimatedCost;
    }
    return '';
  }

  Widget _buildEstimateRows() {
    final estimate = provider.estimate;

    if (estimate is PlasteringEstimate) {
      return Column(
        children: [
          _row('Wet mortar volume', estimate.wetMortarVolume),
          _row('Cement bags', estimate.cementBags),
          _row('Sand', estimate.sand),
        ],
      );
    } else if (estimate is ColumnConcreteEstimate) {
      return Column(
        children: [
          _row('Concrete volume', estimate.concreteVolume),
          _row('Cement bags', estimate.cementBags),
          _row('Sand', estimate.sand),
          _row('20mm aggregate', estimate.aggregate),
        ],
      );
    } else if (estimate is RoofSlabEstimate) {
      return Column(
        children: [
          _row('Concrete volume', estimate.concreteVolume),
          _row('Cement bags', estimate.cementBags),
          _row('Sand', estimate.sand),
          _row('20mm aggregate', estimate.aggregate),
        ],
      );
    }
    return const SizedBox.shrink();
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

  Widget _buildTip() {
    String tip = '';
    if (provider.currentType == CementCalculatorType.plastering) {
      tip =
          'Buy sand by the tonne — ~1 tonne = 22 cft of M-sand. We deliver same day.';
    } else if (provider.currentType == CementCalculatorType.columnConcrete) {
      tip = 'For M20, use min Fe 500D TMT rebar (Fe 550D for G+1 and above).';
    } else if (provider.currentType == CementCalculatorType.roofSlab) {
      tip =
          'Pour the whole slab in one day to avoid cold joints. Order all cement and steel the night before.';
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// ─── Similar Products Section ──────────────────────────────────────────────

class _SimilarProductsSection extends StatelessWidget {
  final CementCalculationProvider provider;
  const _SimilarProductsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final products = provider.similarProducts;
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buy Cement Now',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _ProductVariantCard(
                product: products[index],
                provider: provider,
              );
            },
          ),
        ),
      ],
    );
  }
}

// lib/Calculation/View/cementcalculation_page.dart

// Replace the _ProductVariantCard class with this updated version:

class _ProductVariantCard extends StatelessWidget {
  final SimilarProduct product;
  final CementCalculationProvider provider;

  static const double _cardWidth = 170;

  const _ProductVariantCard({required this.product, required this.provider});

  bool get _inStock => product.stockStatus.toLowerCase().contains('in stock');

  Future<void> _handleAddToCart(BuildContext context) async {
    final success = await provider.addVariantToCart(product.variantId);
    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add to cart: ${provider.errorMessage}'),
        ),
      );
      return;
    }

    try {
      final cartController = Get.find<CartController>();
      await cartController.fetchCart(showLoader: false);
    } catch (_) {}

    Get.snackbar(
      'Added to cart',
      '${product.packSize} added successfully',
      backgroundColor: const Color(0xFF2E7D32),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
      (route) => false,
    );
  }

  Widget _buildThumbnail() {
    final imageUrl = provider.getProductImage(product.materialId);

    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.inventory_2, size: 32, color: Colors.grey),
              ),
            )
          : provider.isLoadingImages
          ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Center(
              child: Icon(Icons.inventory_2, size: 40, color: Colors.grey[400]),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdding = provider.addingToCartVariantIds.contains(
      product.variantId,
    );

    return Container(
      width: _cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThumbnail(),
          const SizedBox(height: 8),
          Text(
            product.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.packSize,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                product.pricePerBag,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  product.stockStatus,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _inStock
                        ? const Color(0xFF2E7D32)
                        : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              onPressed: (!_inStock || isAdding)
                  ? null
                  : () => _handleAddToCart(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isAdding
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _inStock ? 'Add to Cart' : 'Out of Stock',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
