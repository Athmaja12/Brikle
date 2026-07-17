// model/calculator_model.dart
//
// Maps to:
//   GET api/calculator/          -> CalculatorListResponse
//   GET api/calculator/{id}/     -> CalculatorDetailModel

class CalculatorModel {
  final int id;
  final String calculatorName;
  final String redirectSlug;
  final String iconType;
  final String description;

  CalculatorModel({
    required this.id,
    required this.calculatorName,
    required this.redirectSlug,
    required this.iconType,
    required this.description,
  });

  factory CalculatorModel.fromJson(Map<String, dynamic> json) {
    return CalculatorModel(
      id: json['id'] ?? 0,
      calculatorName: json['calculator_name'] ?? '',
      redirectSlug: json['redirect_slug'] ?? '',
      iconType: json['icon_type'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class CalculatorListResponse {
  final String status;
  final String action;
  final int totalCalculators;
  final List<CalculatorModel> calculators;

  CalculatorListResponse({
    required this.status,
    required this.action,
    required this.totalCalculators,
    required this.calculators,
  });

  factory CalculatorListResponse.fromJson(Map<String, dynamic> json) {
    return CalculatorListResponse(
      status: json['status'] ?? '',
      action: json['action'] ?? '',
      totalCalculators: json['total_calculators'] ?? 0,
      calculators: (json['calculators'] as List? ?? [])
          .map((e) => CalculatorModel.fromJson(e))
          .toList(),
    );
  }
}

/// Response of GET api/calculator/{id}/
/// `redirectSlug` is the thing you use to decide which screen to push.
class CalculatorDetailModel {
  final String status;
  final int calculatorId;
  final String redirectAction;
  final String calculatorName;
  final String redirectSlug;
  final String description;

  CalculatorDetailModel({
    required this.status,
    required this.calculatorId,
    required this.redirectAction,
    required this.calculatorName,
    required this.redirectSlug,
    required this.description,
  });

  factory CalculatorDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return CalculatorDetailModel(
      status: json['status'] ?? '',
      calculatorId: json['calculator_id'] ?? 0,
      redirectAction: json['redirect_action'] ?? '',
      calculatorName: data['calculator_name'] ?? '',
      redirectSlug: data['redirect_slug'] ?? '',
      description: data['description'] ?? '',
    );
  }
}