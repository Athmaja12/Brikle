class CustomerProfileModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final String pincode;
  final bool isVerified;

  const CustomerProfileModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.pincode,
    required this.isVerified,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      address: _extractPrimaryAddress(json['address']),
      pincode: json['pincode']?.toString() ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  /// Handles `address` coming back as:
  /// - a plain String (legacy/simple case)
  /// - a List of address objects: [{address_line, is_primary}, ...]
  /// - a List of plain strings
  /// - null / missing
  static String _extractPrimaryAddress(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;

    if (raw is List) {
      if (raw.isEmpty) return '';

      if (raw.first is Map) {
        final addresses = raw.cast<Map<String, dynamic>>();
        // Prefer the one marked is_primary; fall back to the first
        final primary = addresses.firstWhere(
          (a) => a['is_primary'] == true,
          orElse: () => addresses.first,
        );
        return (primary['address_line'] as String?) ?? '';
      }

      // List of plain strings
      return raw.first?.toString() ?? '';
    }

    return raw.toString();
  }
}
