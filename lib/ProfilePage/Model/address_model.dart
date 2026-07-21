/// Matches GET/POST/PATCH /api/addresses/ response exactly:
/// { id, pincode, address_line, is_primary }
///
/// Named DeliveryAddressModel (not AddressModel) to avoid colliding with the
/// existing AddressModel in AddtoCart/Model/address_model.dart, which is a
/// different shape used elsewhere (street_address1/street_address2 etc).
class DeliveryAddressModel {
  final int id;
  final String pincode;
  final String addressLine;
  final bool isPrimary;

  DeliveryAddressModel({
    required this.id,
    required this.pincode,
    required this.addressLine,
    required this.isPrimary,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      id: _parseInt(json['id']),
      pincode: json['pincode']?.toString() ?? '',
      addressLine: json['address_line']?.toString() ?? '',
      isPrimary: json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pincode': pincode,
    'address_line': addressLine,
    'is_primary': isPrimary,
  };

  DeliveryAddressModel copyWith({
    String? pincode,
    String? addressLine,
    bool? isPrimary,
  }) {
    return DeliveryAddressModel(
      id: id,
      pincode: pincode ?? this.pincode,
      addressLine: addressLine ?? this.addressLine,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  /// Display line for cards, e.g. "Flat 4B, Sky Towers, Palakkad - 678001"
  String get fullAddress =>
      pincode.trim().isNotEmpty ? '$addressLine - $pincode' : addressLine;

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}