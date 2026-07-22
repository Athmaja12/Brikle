// lib/AddtoCart/View/ordersuccess_screen.dart
// Complete file with all fixes

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 6),
    );

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _bounceAnim = CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut);

    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final controller = Get.find<CartController>();
    final order = controller.lastOrderResponse.value;
    final earnedCoupons = controller.earnedCoupons;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryGreen.withOpacity(0.05),
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 15,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.yellow,
                Colors.purple,
                Colors.orange,
                Colors.pink,
                Colors.cyan,
                Colors.teal,
                Colors.indigo,
              ],
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),

          // FIX: was a plain Column with Spacer(flex:1) top/bottom and no
          // scroll fallback. With earnedCoupons non-empty (as it now is
          // after a real order), that content plus the illustration plus
          // two competing Spacers has nowhere to go on anything shorter
          // than a tall phone — guaranteed RenderFlex overflow. Wrapping
          // in a scroll view + a ConstrainedBox with minHeight keeps the
          // "centered on a tall screen" look while never overflowing on
          // a short one.
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.07,
                    vertical: sw * 0.05,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (sw * 0.05 * 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Success Illustration with bounce
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: AnimatedBuilder(
                            animation: _bounceAnim,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, -8 * _bounceAnim.value),
                                child: child,
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer glow
                                Container(
                                  width: sw * 0.48,
                                  height: sw * 0.48,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.primaryGreen.withOpacity(
                                          0.15,
                                        ),
                                        AppColors.primaryGreen.withOpacity(0.0),
                                      ],
                                      stops: const [0.3, 1.0],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Main circle — softened glow (was full
                                // opacity, which read as a hard block
                                // rather than a glow)
                                Container(
                                  width: sw * 0.42,
                                  height: sw * 0.42,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF27AE60),
                                        Color(0xFF2ECC71),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF27AE60,
                                        ).withOpacity(0.45),
                                        blurRadius: 30,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                                // Decorative emojis
                                const Positioned(
                                  top: -15,
                                  left: -10,
                                  child: Text(
                                    '🎉',
                                    style: TextStyle(fontSize: 32),
                                  ),
                                ),
                                const Positioned(
                                  top: -15,
                                  right: -10,
                                  child: Text(
                                    '🎊',
                                    style: TextStyle(fontSize: 32),
                                  ),
                                ),
                                const Positioned(
                                  bottom: -15,
                                  left: -10,
                                  child: Text(
                                    '✨',
                                    style: TextStyle(fontSize: 32),
                                  ),
                                ),
                                const Positioned(
                                  bottom: -15,
                                  right: -10,
                                  child: Text(
                                    '🌟',
                                    style: TextStyle(fontSize: 32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: sw * 0.06),

                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            children: [
                              Text(
                                "🎉 Order Placed\nSuccessfully!",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  // FIX: was a fixed 30 regardless of
                                  // screen width — clamped so it can't
                                  // push into overflow on narrow phones.
                                  fontSize: (sw * 0.075).clamp(22.0, 30.0),
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2D2D2D),
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (order != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Order #${order.orderDetails.id}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                "Your delivery request has been received.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  color: const Color(0xFF9E9E9E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "We'll notify you when it's on the way! 🚚",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: const Color(0xFFBDBDBD),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Earned Coupons Section ──
                        if (earnedCoupons.isNotEmpty) ...[
                          SizedBox(height: sw * 0.05),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade50,
                                      Colors.amber.shade100,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.amber.shade300,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          '🎁',
                                          style: TextStyle(fontSize: 28),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'You Earned ${earnedCoupons.length} Coupon${earnedCoupons.length > 1 ? 's' : ''}!',
                                            style: GoogleFonts.manrope(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...earnedCoupons.map(
                                      (coupon) => Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.local_offer,
                                                size: 18,
                                                color: AppColors.primaryGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    coupon.couponCode,
                                                    style: GoogleFonts.manrope(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${coupon.discountPercentage.toStringAsFixed(0)}% off on ${coupon.rewardMaterialName}',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Valid till ${coupon.formattedExpiryDate}',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: sw * 0.08),

                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
