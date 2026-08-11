import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/custombutton.dart';
import 'package:brikle/AppStyle/customtextfield.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/GoogleAuth/googleauthapiservice.dart';
import 'package:brikle/GoogleAuth/googleauthservice.dart';
import 'package:brikle/LoginOtp/Controller/loginotp_provider.dart';
import 'package:brikle/LoginOtp/View/logiotppage.dart';
import 'package:brikle/LoginScreen/Controller/login_controller.dart';
import 'package:brikle/Registration/View/regitration_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends GetView<LoginController> {
  /// Non-null when pushed from AuthGate (checkout-triggered). Controls
  /// both the copy shown and whether success pops `true` back to the
  /// caller instead of navigating into MainScreen.
  final String? checkoutReason;

  const LoginView({super.key, this.checkoutReason});

  bool get _isModal => checkoutReason != null;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LoginController>()) {
      debugPrint('[LoginView] registering LoginController');
      Get.put(LoginController());
    }

    final GoogleAuthService _googleAuthService = GoogleAuthService();
    final AuthApiService _authApiService = AuthApiService();

    Future<void> handleLogin() async {
      debugPrint('[LoginView] Continue tapped — calling controller.login()');
      final success = await controller.login();
      debugPrint('[LoginView] login() returned: $success');
      if (!success) return;
      if (!context.mounted) return;

      final otpResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpView(
            phoneNumber: controller.model.phoneNumber,
            countryCode: controller.model.countryCode,
            flow: OtpFlow.login,
            prefillOtp: controller.lastOtp,
            isModal: _isModal,
          ),
        ),
      );

      if (!context.mounted) return;

      if (_isModal && otpResult == true) {
        Navigator.pop(context, true);
      }
      // Non-modal flow: OtpController itself does Get.offAllNamed('/home')
      // on success, so there's nothing further to do here.
    }

    Future<void> handleGoogleSignIn() async {
      debugPrint('[LoginView] ── Google Sign-In button tapped ──');
      try {
        debugPrint(
          '[LoginView] Step 1: calling GoogleAuthService.signInWithGoogle()',
        );
        final String? idToken = await _googleAuthService.signInWithGoogle();

        if (idToken == null) {
          debugPrint(
            '[LoginView] ❌ No idToken returned — user likely cancelled. Aborting.',
          );
          return;
        }
        debugPrint('[LoginView] ✅ Got idToken from Google/Firebase');

        debugPrint(
          '[LoginView] Step 2: calling AuthApiService.loginWithGoogle()',
        );
        final data = await _authApiService.loginWithGoogle(idToken);
        debugPrint('[LoginView] ✅ Backend login successful. Response: $data');

        if (!context.mounted) {
          debugPrint(
            '[LoginView] ⚠️ Context unmounted after backend call — aborting navigation',
          );
          return;
        }

        if (_isModal) {
          debugPrint('[LoginView] Step 3 (modal) — popping true to AuthGate');
          Navigator.pop(context, true);
        } else {
          debugPrint('[LoginView] Step 3: navigating to MainScreen');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        }
        debugPrint('[LoginView] ── Google Sign-In flow COMPLETE ──');
      } catch (e, stack) {
        debugPrint('[LoginView] ❌ Google Sign-In error: $e');
        debugPrint('[LoginView] Stack trace: $stack');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: Responsive.space(context, 48)),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'B',
                            style: AppTextStyles.brikleLogoAccent(context),
                          ),
                          TextSpan(
                            text: 'rikle',
                            style: AppTextStyles.brikleLogoDark(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.space(context, 32)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, 24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          checkoutReason ?? 'Welcome Back',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.welcomeBackTitle(context),
                        ),
                        SizedBox(height: Responsive.space(context, 6)),
                        Text(
                          _isModal
                              ? "You're almost there — just log in to continue."
                              : 'Sign in to manage your construction materials.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.loginSubtitleCentered(context),
                        ),
                        SizedBox(height: Responsive.space(context, 32)),

                        CustomPhoneField(controller: controller),

                        SizedBox(height: Responsive.space(context, 24)),

                        Obx(
                          () => CustomButton(
                            label: 'Login',
                            isLoading: controller.isLoading.value,
                            onPressed: handleLogin,
                          ),
                        ),

                        SizedBox(height: Responsive.space(context, 20)),

                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(context, 12),
                              ),
                              child: Text(
                                'OR',
                                style: AppTextStyles.termsText(context),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        SizedBox(height: Responsive.space(context, 20)),

                        SizedBox(
                          width: double.infinity,
                          height: Responsive.space(context, 52),
                          child: OutlinedButton(
                            onPressed: handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.inputBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GoogleLogo(
                                  size: Responsive.space(context, 22),
                                ),
                                SizedBox(width: Responsive.space(context, 12)),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: Responsive.space(context, 15),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3C3C3C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: Responsive.space(context, 16)),
                        SizedBox(height: Responsive.space(context, 24)),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?  ",
                              style: AppTextStyles.termsText(context),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SignupView(isModal: _isModal),
                                  ),
                                );
                              },
                              child: Text(
                                'Register',
                                style: AppTextStyles.linkText(context),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: Responsive.space(context, 24)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);

    final strokeW = size.width * 0.09;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      -0.25,
      1.55,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      -1.85,
      1.1,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      2.2,
      0.95,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      3.15,
      0.65,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.72, cy), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}