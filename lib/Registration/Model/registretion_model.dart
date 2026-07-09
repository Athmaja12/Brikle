enum CustomerType { homeOwner, contractor }

extension CustomerTypeApi on CustomerType {
  String get apiValue =>
      this == CustomerType.contractor ? 'contractor' : 'home_owner';
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
    this.customerType = CustomerType.homeOwner, // ← was CustomerType.individual
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
