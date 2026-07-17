// provider/calculator_provider.dart

import 'package:brikle/Calculation/Model/calculation_model.dart';
import 'package:flutter/material.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';


enum CalculatorLoadState { idle, loading, loaded, error }

class CalculatorProvider extends ChangeNotifier {
  CalculatorLoadState state = CalculatorLoadState.idle;
  List<CalculatorModel> calculators = [];
  String errorMessage = '';

  /// Backs the "Material Calculator" list screen (api/calculator/).
  Future<void> fetchCalculators() async {
    state = CalculatorLoadState.loading;
    notifyListeners();
    try {
      final result = await ApiService.getCalculatorList();
      calculators = result.calculators;
      state = CalculatorLoadState.loaded;
    } catch (e) {
      errorMessage = e.toString();
      state = CalculatorLoadState.error;
    }
    notifyListeners();
  }

  /// Called on "Open Calculator" tap. Hits api/calculator/{id}/ to get the
  /// redirect_slug, which the router then uses to push the right screen.
  Future<CalculatorDetailModel?> resolveCalculator(int id) async {
    try {
      return await ApiService.getCalculatorDetail(id);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}