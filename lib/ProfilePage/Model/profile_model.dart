/// Matches GET /api/customer-profile/ response exactly:
/// { full_name, email, phone_number, address, pincode,
///   customer_type, gst_number, is_verified }
class ProfileModel {
  final String fullName;
  final String? email;
  final String phoneNumber;
  final String address;
  final String pincode;
  final String? customerType; // 'home_owner' | 'contractor'
  final String? gstNumber;
  final bool isVerified;

  ProfileModel({
    this.fullName = '',
    this.email,
    this.phoneNumber = '',
    this.address = '',
    this.pincode = '',
    this.customerType,
    this.gstNumber,
    this.isVerified = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      customerType: json['customer_type']?.toString(),
      gstNumber: json['gst_number']?.toString(),
      isVerified: json['is_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'phone_number': phoneNumber,
    'address': address,
    'pincode': pincode,
    'customer_type': customerType,
    'gst_number': gstNumber,
    'is_verified': isVerified,
  };

  ProfileModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? pincode,
    String? customerType,
    String? gstNumber,
    bool? isVerified,
  }) {
    return ProfileModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      customerType: customerType ?? this.customerType,
      gstNumber: gstNumber ?? this.gstNumber,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  /// Friendly label for the dialog, e.g. "Home Owner" / "Contractor"
  String get customerTypeLabel {
    switch (customerType) {
      case 'contractor':
        return 'Contractor';
      case 'home_owner':
        return 'Home Owner';
      default:
        return '—';
    }
  }

  /// Combined display line for the address card, e.g.
  /// "12/129 Grace Villa, kochi - 678001"
  String get fullAddress {
    if (address.trim().isEmpty) return '';
    return pincode.trim().isNotEmpty ? '$address - $pincode' : address;
  }
}



