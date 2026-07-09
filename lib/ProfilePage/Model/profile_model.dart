/// Matches GET /api/customer-profile/ response exactly:
/// { full_name, email, phone_number, address, is_verified }
class ProfileModel {
  final String fullName;
  final String? email;
  final String phoneNumber;
  final String address;
  final bool isVerified;

  ProfileModel({
    this.fullName = '',
    this.email,
    this.phoneNumber = '',
    this.address = '',
    this.isVerified = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      fullName:    json['full_name']?.toString()    ?? '',
      email:       json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString() ?? '',
      address:     json['address']?.toString()      ?? '',
      isVerified:  json['is_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'full_name':    fullName,
        'email':        email,
        'phone_number': phoneNumber,
        'address':      address,
        'is_verified':  isVerified,
      };

  ProfileModel copyWith({
    String?  fullName,
    String?  email,
    String?  phoneNumber,
    String?  address,
    bool?    isVerified,
  }) {
    return ProfileModel(
      fullName:    fullName    ?? this.fullName,
      email:       email       ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address:     address     ?? this.address,
      isVerified:  isVerified  ?? this.isVerified,
    );
  }
}

/// Matches POST/PATCH /api/customer/addresses/ response — now aligned
/// with registration's address shape:
/// { id, street_address1, street_address2, pincode, is_primary,
///   customer_type, gst_number }
class AddressModel {
  final String id;
  final String streetAddress1;
  final String streetAddress2;
  final String pincode;
  final bool isPrimary;
  final String? customerType;
  final String? gstNumber;

  AddressModel({
    required this.id,
    this.streetAddress1 = '',
    this.streetAddress2 = '',
    this.pincode = '',
    this.isPrimary = false,
    this.customerType,
    this.gstNumber,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      // fallback to old `address_line` in case any legacy records
      // don't have street_address1 populated yet
      streetAddress1: json['street_address1']?.toString() ??
          json['address_line']?.toString() ??
          '',
      streetAddress2: json['street_address2']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      isPrimary: json['is_primary'] == true,
      customerType: json['customer_type']?.toString(),
      gstNumber: json['gst_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'street_address1': streetAddress1,
        'street_address2': streetAddress2,
        'pincode': pincode,
        'is_primary': isPrimary,
        if (customerType != null) 'customer_type': customerType,
        if (gstNumber != null) 'gst_number': gstNumber,
      };

  /// Combined display line for the address card, e.g.
  /// "Building 4B, Phase 1, Infopark Kakkanad - 682042"
  String get fullAddress {
    final parts = [streetAddress1, streetAddress2]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return pincode.trim().isNotEmpty ? '$parts - $pincode' : parts;
  }

  AddressModel copyWith({
    String? id,
    String? streetAddress1,
    String? streetAddress2,
    String? pincode,
    bool? isPrimary,
    String? customerType,
    String? gstNumber,
  }) {
    return AddressModel(
      id: id ?? this.id,
      streetAddress1: streetAddress1 ?? this.streetAddress1,
      streetAddress2: streetAddress2 ?? this.streetAddress2,
      pincode: pincode ?? this.pincode,
      isPrimary: isPrimary ?? this.isPrimary,
      customerType: customerType ?? this.customerType,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }
}