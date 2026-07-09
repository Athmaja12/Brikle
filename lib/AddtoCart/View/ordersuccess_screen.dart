// lib/Cart/View/order_success_screen.dart

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderSuccessScreen extends StatefulWidget {
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final int itemCount;

  const OrderSuccessScreen({
    super.key,
    required this.totalAmount,
    required this.paymentMethod,
    required this.itemCount,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.07),
          child: Column(
            children: [
              const Spacer(),

              // Success Illustration
              ScaleTransition(
                scale: _scaleAnim,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: sw * 0.42,
                      height: sw * 0.42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF27AE60),
                        shape: BoxShape.circle,
                      ),
                    ),

                    Icon(
                      Icons.inventory_2_rounded,
                      size: sw * 0.18,
                      color: const Color(0xFFFFD180),
                    ),

                    Positioned(
                      right: sw * 0.02,
                      bottom: sw * 0.02,
                      child: Container(
                        width: sw * 0.12,
                        height: sw * 0.12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: sw * 0.08),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      "Order Placed\nSuccessfully !",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D2D2D),
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Your delivery request has been received.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: sw * 0.12),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    // Back To Home
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.offAll(() => const MainScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Back to Home",
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    GestureDetector(
                      onTap: () {
                        // Track Order Page
                      },
                      child: Text(
                        "Track Order",
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
