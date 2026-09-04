// lib/Calculation/View/block_calculator_page.dart
import 'package:brikle/Calculation/Controller/blockCalculation_provider.dart';
import 'package:brikle/Calculation/Model/blockCalculation_model.dart';
import 'package:brikle/Calculation/product_Card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlockCalculatorPage extends StatelessWidget {
  const BlockCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BlockCalculatorProvider()..loadDropdown(),
      child: const _BlockCalculatorView(),
    );
  }
}

class _BlockCalculatorView extends StatelessWidget {
  const _BlockCalculatorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text(
          'Block Calculator',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<BlockCalculatorProvider>(
        builder: (context, provider, _) {
          if (provider.state == BlockLoadState.loadingDropdown) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == BlockLoadState.error &&
              provider.calculationResult == null) {
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

          // 🔎 DEBUG — confirms, on every rebuild, whether the provider
          // actually has related products to show at all.
          final related = provider.calculationResult?.relatedProducts;
          debugPrint(
            '[BlockCalculatorPage] build() — hasResult=${provider.calculationResult != null}, '
            'blocks=${related?.blocks.length ?? 0}, adhesives=${related?.adhesives.length ?? 0}',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Form Card ──────────────────────────────────────────
                _FormCard(provider: provider),
                const SizedBox(height: 16),

                // ─── Estimate Card ──────────────────────────────────────
                if (provider.calculationResult != null) ...[
                  _EstimateCard(provider: provider),
                  const SizedBox(height: 16),
                ],

                // ─── Related Products Section ────────────────────────────
                // ⚠️ THIS WAS MISSING — the widget existed but was never
                // added to the tree, so nothing rendered no matter what
                // the provider fetched.
                if (provider.calculationResult != null &&
                    ((related?.blocks.isNotEmpty ?? false) ||
                        (related?.adhesives.isNotEmpty ?? false))) ...[
                  _RelatedProductsSection(provider: provider),
                  const SizedBox(height: 16),
                ],

                // ─── Error Message ──────────────────────────────────────
                if (provider.state == BlockLoadState.error &&
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

// ─── Form Card ─────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final BlockCalculatorProvider provider;
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
            'Calculate Blocks for your Wall',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'All measurements are in feet. Select block size and wastage.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // ─── Block Size Dropdown ─────────────────────────────────────
          const Text(
            'Block Size',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<BlockSizeOption>(
            value: provider.selectedBlockSize,
            isExpanded: true,
            decoration: _fieldDecoration(),
            items:
                provider.dropdownData?.blockSizeOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList() ??
                [],
            onChanged: (value) {
              if (value != null) provider.selectBlockSize(value);
            },
          ),
          const SizedBox(height: 16),

          // ─── Wastage Dropdown ────────────────────────────────────────
          const Text(
            'Wastage',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<WastageOption>(
            value: provider.selectedWastage,
            isExpanded: true,
            decoration: _fieldDecoration(),
            items:
                provider.dropdownData?.wastageOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList() ??
                [],
            onChanged: (value) {
              if (value != null) provider.selectWastage(value);
            },
          ),
          const SizedBox(height: 16),

          // ─── Wall Dimensions ─────────────────────────────────────────
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
          const SizedBox(height: 20),

          // ─── Calculate Button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.state == BlockLoadState.calculating
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
              child: provider.state == BlockLoadState.calculating
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
  final BlockCalculatorProvider provider;
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

          // ─── Wall Area ────────────────────────────────────────────────
          _row('Wall area', '${inputs.wallAreaSqft.toStringAsFixed(1)} sqft'),

          // ─── Block Size ──────────────────────────────────────────────
          _row('Block size', inputs.selectedBlock),

          // ─── Blocks with Wastage ─────────────────────────────────────
          _row('Blocks required', '${estimate.blocksWithWastage} blocks'),
          const SizedBox(height: 4),

          // ─── Adhesive ─────────────────────────────────────────────────
          _row('Adhesive', estimate.adhesiveBags),
          const SizedBox(height: 8),

          // ─── Divider ──────────────────────────────────────────────────
          const Divider(),
          const SizedBox(height: 8),

          // ─── Cost Breakdown ──────────────────────────────────────────
          _row('Block cost', estimate.blockCost),
          _row('Adhesive cost', estimate.adhesiveCost),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orange[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Add 5-10% extra blocks for cuts and breakage during installation.',
                    style: TextStyle(fontSize: 12),
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

// ─── Related Products Section ───────────────────────────────────────────────

class _RelatedProductsSection extends StatelessWidget {
  final BlockCalculatorProvider provider;
  const _RelatedProductsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final related = provider.calculationResult!.relatedProducts;
    final items = [...related.blocks, ...related.adhesives];

    debugPrint('[RelatedProductsSection] rendering ${items.length} card(s)');
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Products',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return SharedProductCard(
                title: item.name,
                priceText: '₹${item.pricePerUnit.toStringAsFixed(2)} / unit',
                imageUrl: item.imageUrl,
                isImageLoading: item.imageLoading,
                variantId: item.variantId,
                materialId: item.materialId,
                price: item.pricePerUnit,
                placeholderIcon: Icons.grid_view_rounded,
                // Block API has no stock field — treat as always available.
                inStock: true,
              );
            },
          ),
        ),
      ],
    );
  }
}
