// view/material_calculator_screen.dart

import 'package:brikle/Calculation/Controller/calculation_provider.dart';
import 'package:brikle/Calculation/Model/calculation_model.dart';
import 'package:brikle/Calculation/calculatorRouter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Entry point — this is a StatelessWidget that PROVIDES CalculatorProvider
/// to everything below it, the same way PaintCalculatorScreen provides
/// PaintCalculatorProvider. This is the piece that was missing before.
class MaterialCalculatorScreen extends StatelessWidget {
  const MaterialCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalculatorProvider(),
      child: const _MaterialCalculatorView(),
    );
  }
}

class _MaterialCalculatorView extends StatefulWidget {
  const _MaterialCalculatorView();

  @override
  State<_MaterialCalculatorView> createState() =>
      _MaterialCalculatorViewState();
}

class _MaterialCalculatorViewState extends State<_MaterialCalculatorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalculatorProvider>().fetchCalculators();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text(
          'Material Calculator',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<CalculatorProvider>(
        builder: (context, provider, _) {
          switch (provider.state) {
            case CalculatorLoadState.loading:
            case CalculatorLoadState.idle:
              return const Center(child: CircularProgressIndicator());
            case CalculatorLoadState.error:
              return Center(child: Text('Error: ${provider.errorMessage}'));
            case CalculatorLoadState.loaded:
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 +
                      kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                ),
                itemCount: provider.calculators.length,
                itemBuilder: (context, index) {
                  final calc = provider.calculators[index];
                  return _CalculatorCard(calculator: calc);
                },
              );
          }
        },
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final CalculatorModel calculator;
  const _CalculatorCard({required this.calculator});

  /// Hardcoded per the Figma — each calculator shows its actual product
  /// photo (paint can, AAC blocks, cement bag, Dr. Fixit tub, TMT rods)
  /// rather than a generic icon. Swap these asset paths for your real
  /// product images; keep the `icon_type` -> image mapping so a new
  /// calculator only needs one new line here.
  static const Map<String, String> _images = {
    'paint': 'assets/images/paints.png',
    'blocks': 'assets/images/block.png',
    'cement': 'assets/images/cements.png',
    'steel': 'assets/images/steel.png',
    'waterproofing': 'assets/images/fixit.png',
  };

  IconData _fallbackIconFor(String iconType) {
    switch (iconType) {
      case 'paint':
        return Icons.format_paint;
      case 'blocks':
        return Icons.grid_view;
      case 'cement':
        return Icons.inventory_2;
      case 'steel':
        return Icons.linear_scale;
      case 'waterproofing':
        return Icons.water_drop;
      default:
        return Icons.calculate;
    }
  }

  Widget _buildThumbnail() {
    final path = _images[calculator.iconType];
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: path != null
          ? Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                _fallbackIconFor(calculator.iconType),
                size: 32,
                color: Colors.grey[600],
              ),
            )
          : Icon(
              _fallbackIconFor(calculator.iconType),
              size: 32,
              color: Colors.grey[600],
            ),
    );
  }

  Future<void> _openCalculator(BuildContext context) async {
    final provider = context.read<CalculatorProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final detail = await provider.resolveCalculator(calculator.id);

    if (context.mounted) Navigator.of(context).pop(); // dismiss loader

    if (detail == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open calculator: ${provider.errorMessage}',
            ),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      CalculatorRouter.openBySlug(context, detail.redirectSlug);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calculator.calculatorName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  calculator.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _openCalculator(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Open Calculator',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
