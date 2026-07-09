/// MODEL — plain data holder, no Flutter/UI dependencies.
class LoginModel {
  String countryCode;
  String phoneNumber;

  LoginModel({this.countryCode = '', this.phoneNumber = ''});

  bool get isPhoneValid => phoneNumber.length == 10;
}
