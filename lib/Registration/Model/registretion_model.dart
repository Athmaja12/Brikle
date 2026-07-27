enum CustomerType { individual, contractor, reseller, applicator, seller }

extension CustomerTypeApi on CustomerType {
  /// Matches the backend's choices exactly:
  /// ('individual', 'Individual'), ('contractor', 'Contractor'),
  /// ('reseller', 'Reseller'), ('applicator', 'Applicator'),
  /// ('seller', 'Seller')
  String get apiValue {
    switch (this) {
      case CustomerType.individual:
        return 'individual';
      case CustomerType.contractor:
        return 'contractor';
      case CustomerType.reseller:
        return 'reseller';
      case CustomerType.applicator:
        return 'applicator';
      case CustomerType.seller:
        return 'seller';
    }
  }

  /// Display label for chips/dropdowns.
  String get label {
    switch (this) {
      case CustomerType.individual:
        return 'Individual';
      case CustomerType.contractor:
        return 'Contractor';
      case CustomerType.reseller:
        return 'Reseller';
      case CustomerType.applicator:
        return 'Applicator';
      case CustomerType.seller:
        return 'Seller';
    }
  }
}

class SignupModel {
  String fullName;
  String countryCode;
  String phoneNumber;
  String streetAddress1;
  String streetAddress2;
  String pincode;
  CustomerType customerType;
  String gstNumber;

  SignupModel({
    this.fullName = '',
    this.countryCode = '+91',
    this.phoneNumber = '',
    this.streetAddress1 = '',
    this.streetAddress2 = '',
    this.pincode = '',
    this.customerType = CustomerType.individual,
    this.gstNumber = '',
  });

  static final RegExp _gstRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  bool get isFullNameValid => fullName.trim().isNotEmpty;
  bool get isPhoneValid => phoneNumber.length == 10;
  bool get isStreetAddress1Valid => streetAddress1.trim().isNotEmpty;
  bool get isStreetAddress2Valid => streetAddress2.trim().isNotEmpty;
  bool get isPincodeValid =>
      pincode.trim().length == 6 && RegExp(r'^\d{6}$').hasMatch(pincode.trim());

  // ⚠️ ASSUMED — only 'contractor' requires GST, same as before. If
  // reseller/applicator/seller should also require GST on your backend,
  // just add them to this check.
  bool get isGstRequired => customerType == CustomerType.contractor;

  bool get isGstValid {
    if (!isGstRequired) return true;
    return _gstRegex.hasMatch(gstNumber.trim().toUpperCase());
  }

  bool get isFormValid =>
      isFullNameValid &&
      isPhoneValid &&
      isStreetAddress1Valid &&
      isStreetAddress2Valid &&
      isPincodeValid &&
      isGstValid;
}