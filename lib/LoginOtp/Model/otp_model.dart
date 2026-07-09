/// MODEL — plain data holder, no Flutter/UI dependencies.
class OtpModel {
  final String phoneNumber; // full number, e.g. "9585258745"
  final String countryCode; // e.g. "+91"
  String otpCode;

  OtpModel({
    required this.phoneNumber,
    this.countryCode = '+91',
    this.otpCode = '',
  });

  bool get isOtpComplete => otpCode.length == 4;

  /// Masks the phone number to match the Figma format:
  /// "+91 XXXX-XXX-1150" — first 4 digits hidden, next 3 hidden,
  /// last 4 digits shown. Falls back gracefully if the number isn't
  /// exactly 10 digits.
  String get maskedPhoneNumber {
    if (phoneNumber.length != 10) {
      return '$countryCode $phoneNumber';
    }
    return '$countryCode ${phoneNumber.substring(0, 5)} ${phoneNumber.substring(5)}';
  }
}
