// lib/Calculation/View/steel_calculator_page.dart

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Calculation/Controller/steelCalculation_provider.dart';
import 'package:brikle/Calculation/Model/steelCalculation_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SteelCalculatorPage extends StatelessWidget {
  const SteelCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SteelCalculatorProvider(),
      child: const _SteelCalculatorView(),
    );
  }
}

class _SteelCalculatorView extends StatefulWidget {
  const _SteelCalculatorView();

  @override
  State<_SteelCalculatorView> createState() => _SteelCalculatorViewState();
}

class _SteelCalculatorViewState extends State<_SteelCalculatorView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text(
          'Steel Calculator',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<SteelCalculatorProvider>(
        builder: (context, provider, _) {
          if (provider.state == SteelLoadState.idle) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == SteelLoadState.error &&
              provider.estimate == null) {
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
                // ─── Form Card ──────────────────────────────────────────
                _FormCard(provider: provider),
                const SizedBox(height: 16),

                // ─── Estimate Card ──────────────────────────────────────
                if (provider.estimate != null) ...[
                  _EstimateCard(provider: provider),
                  const SizedBox(height: 16),
                ],

                // ─── Error Message ──────────────────────────────────────
                if (provider.state == SteelLoadState.error &&
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

// ─── Form Card ─────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final SteelCalculatorProvider provider;
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
            'Calculate Steel Weight',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter steel rod details. Tap Calculate to see weight and cost.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // ─── Price per KG ─────────────────────────────────────────────
          _NumberField(
            label: 'Price per kg (₹)',
            controller: provider.pricePerKgCtrl,
          ),
          const SizedBox(height: 16),

          // ─── Steel Items List ─────────────────────────────────────────
          const Text(
            'Steel Rod Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.steelItems.length,
            itemBuilder: (context, index) {
              return _SteelItemRow(
                index: index,
                item: provider.steelItems[index],
                provider: provider,
              );
            },
          ),

          // ─── Add Item Button ──────────────────────────────────────────
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: provider.addSteelItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Rod Size'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Calculate Button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.state == SteelLoadState.calculating
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
              child: provider.state == SteelLoadState.calculating
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
}

// ─── Steel Item Row ──────────────────────────────────────────────────────

class _SteelItemRow extends StatelessWidget {
  final int index;
  final SteelItem item;
  final SteelCalculatorProvider provider;

  const _SteelItemRow({
    required this.index,
    required this.item,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ItemNumberField(
                        label: 'Dia (mm)',
                        initialValue: item.diameter,
                        onChanged: (val) {
                          provider.updateSteelItem(
                            index,
                            SteelItem(
                              diameter: val,
                              noOfRods: item.noOfRods,
                              lengthPerRod: item.lengthPerRod,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ItemNumberField(
                        label: 'No. of rods',
                        initialValue: item.noOfRods,
                        onChanged: (val) {
                          provider.updateSteelItem(
                            index,
                            SteelItem(
                              diameter: item.diameter,
                              noOfRods: val,
                              lengthPerRod: item.lengthPerRod,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ItemNumberField(
                        label: 'Length (m)',
                        initialValue: item.lengthPerRod.toInt(),
                        onChanged: (val) {
                          provider.updateSteelItem(
                            index,
                            SteelItem(
                              diameter: item.diameter,
                              noOfRods: item.noOfRods,
                              lengthPerRod: val.toDouble(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.diameter} mm × ${item.noOfRods} rods × ${item.lengthPerRod.toStringAsFixed(1)} m',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (provider.steelItems.length > 1)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red[400], size: 20),
              onPressed: () => provider.removeSteelItem(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

// ─── Fixed Item Number Field ──────────────────────────────────────────────

class _ItemNumberField extends StatelessWidget {
  final String label;
  final int initialValue;
  final Function(int) onChanged;

  const _ItemNumberField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Create a controller with the initial value
    final controller = TextEditingController(text: initialValue.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
          onChanged: (val) {
            final intVal = int.tryParse(val) ?? 0;
            if (intVal > 0) onChanged(intVal);
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
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
  final SteelCalculatorProvider provider;
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

          // ─── Row Estimates ────────────────────────────────────────────
          ...estimate.rows.map(
            (row) => _row(
              row.description,
              '${row.rowWeightKg.toStringAsFixed(1)} kg',
            ),
          ),
          const SizedBox(height: 8),

          // ─── Total Weight ─────────────────────────────────────────────
          _row('Total weight', estimate.totalWeight),
          _row('In tonnes', estimate.inTonnes),
          const SizedBox(height: 16),

          // ─── Estimated Cost ───────────────────────────────────────────
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
                  estimate.userEstimatedCost,
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
