// lib/AddtoCart/View/ordersuccess_screen.dart

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _confettiAnim;

  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble() * 1.0,
        y: _random.nextDouble() * 1.0,
        size: 4 + _random.nextDouble() * 8,
        color: [
          Colors.red,
          Colors.green,
          Colors.blue,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          Colors.cyan,
        ][_random.nextInt(8)],
        speed: 0.5 + _random.nextDouble() * 1.5,
        angle: _random.nextDouble() * 2 * 3.14159,
        rotationSpeed: _random.nextDouble() * 4 - 2,
      ));
    }

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _confettiAnim = CurvedAnimation(parent: _confettiCtrl, curve: Curves.linear);

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
    _confettiCtrl.dispose();
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
          // Confetti particles
          AnimatedBuilder(
            animation: _confettiAnim,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _confettiAnim.value,
                ),
                size: Size(sw, MediaQuery.of(context).size.height),
              );
            },
          ),

          SafeArea(
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
                            gradient: LinearGradient(
                              colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Icon(
                          Icons.check_rounded,
                          size: sw * 0.18,
                          color: Colors.white,
                        ),
                        // Party Popper emojis around the circle
                        Positioned(
                          top: -10,
                          left: 0,
                          child: const Text('🎉', style: TextStyle(fontSize: 28)),
                        ),
                        Positioned(
                          top: -10,
                          right: 0,
                          child: const Text('🎊', style: TextStyle(fontSize: 28)),
                        ),
                        Positioned(
                          bottom: -10,
                          left: 0,
                          child: const Text('✨', style: TextStyle(fontSize: 28)),
                        ),
                        Positioned(
                          bottom: -10,
                          right: 0,
                          child: const Text('🌟', style: TextStyle(fontSize: 28)),
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
                          "🎉 Order Placed\nSuccessfully!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2D2D2D),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (order != null)
                          Text(
                            'Order #${order.orderDetails.id}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 4),
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

                  // ── Earned Coupons Section ──
                  if (earnedCoupons.isNotEmpty) ...[
                    SizedBox(height: sw * 0.06),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
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
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🎁', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Text(
                                  'You Earned ${earnedCoupons.length} Coupon${earnedCoupons.length > 1 ? 's' : ''}!',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...earnedCoupons.map((coupon) => Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.local_offer,
                                        size: 16,
                                        color: AppColors.primaryGreen,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              coupon.couponCode,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '${coupon.discountPercentage.toStringAsFixed(0)}% off on ${coupon.rewardMaterialName}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          coupon.formattedExpiryDate,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: sw * 0.06),

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
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Get.offAll(() => const MainScreen(initialIndex: 3));
                          },
                          child: Text(
                            "View My Orders",
                            style: GoogleFonts.manrope(
                              fontSize: 14,
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
        ],
      ),
    );
  }
}

// ── Confetti Particle Model ──────────────────────────────────
class ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double angle;
  final double rotationSpeed;
  double rotation = 0;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
    required this.rotationSpeed,
  });
}

// ── Confetti Painter ──────────────────────────────────────────
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      // Update rotation
      particle.rotation += particle.rotationSpeed * 0.02;

      // Calculate position with gravity effect
      final yOffset = (progress * 0.5 + particle.y * 0.5) * size.height;
      final xOffset = (particle.x + sin(progress * particle.speed + particle.angle) * 0.05) * size.width;

      // Fade out at the bottom
      final opacity = 1.0 - (yOffset / size.height) * 0.7;

      paint.color = particle.color.withOpacity(opacity);

      // Draw rotated rectangle as confetti
      canvas.save();
      canvas.translate(xOffset, yOffset);
      canvas.rotate(particle.rotation);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}