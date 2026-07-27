class ProfileModel {
  final String fullName;
  final String? email;
  final String phoneNumber;
  final String address;
  final String pincode;
  final String? customerType;
  final String? gstNumber;
  final bool isVerified;
  final String? registrationType;

  ProfileModel({
    this.fullName = '',
    this.email,
    this.phoneNumber = '',
    this.address = '',
    this.pincode = '',
    this.customerType,
    this.gstNumber,
    this.isVerified = false,
    this.registrationType,
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
      registrationType:
          json['registration_type']?.toString() ??
          _inferRegistrationType(json),
    );
  }

  /// Backend uses a placeholder like "GOOGLE-68" in phone_number for
  /// accounts that signed up/in via Google and never set a real phone.
  /// A real phone number is digits (with optional leading +), nothing else.
  static bool _isPlaceholderPhone(String phone) {
    if (phone.isEmpty) return false;
    return !RegExp(r'^\+?[0-9]+$').hasMatch(phone);
  }

  static String _inferRegistrationType(Map<String, dynamic> json) {
    final phone = json['phone_number']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';
    if (phone.isNotEmpty && !_isPlaceholderPhone(phone)) return 'phone';
    if (email.isNotEmpty) return 'email';
    return 'manual';
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
    'registration_type': registrationType,
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
    String? registrationType,
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
      registrationType: registrationType ?? this.registrationType,
    );
  }

  /// True when phone_number is a real number, not the "GOOGLE-xx" placeholder.
  bool get hasRealPhoneNumber =>
      phoneNumber.isNotEmpty && !_isPlaceholderPhone(phoneNumber);

  /// What to actually display/prefill anywhere in the UI — never the
  /// placeholder itself.
  String get displayPhoneNumber => hasRealPhoneNumber ? phoneNumber : '';

  String get customerTypeLabel {
    switch (customerType) {
      case 'individual':
        return 'Individual';
      case 'contractor':
        return 'Contractor';
      case 'reseller':
        return 'Reseller';
      case 'applicator':
        return 'Applicator';
      case 'seller':
        return 'Seller';
      default:
        return '—';
    }
  }

  String get fullAddress {
    if (address.trim().isEmpty) return '';
    return pincode.trim().isNotEmpty ? '$address - $pincode' : address;
  }
}