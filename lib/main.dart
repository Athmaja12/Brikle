// lib/main.dart

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Calculation/View/blockCalculation_Page.dart';
import 'package:brikle/Calculation/View/calculatiorPage.dart';
import 'package:brikle/Calculation/View/cementcalculation_page.dart';
import 'package:brikle/Calculation/View/steelCalculation_Page.dart';
import 'package:brikle/Calculation/View/waterproofCalculation_Page.dart';
import 'package:brikle/GoogleAuth/googleauthapiservice.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
import 'package:brikle/HomePage/Controller/search_Provider.dart';
import 'package:brikle/LoginScreen/View/loginscreen.dart';
import 'package:brikle/OnboardingScreens/View/onboardingscrenn.dart';
import 'package:brikle/ProfilePage/View/orderDetailScreen.dart';
import 'package:brikle/SplashScreen/View/splashscreen.dart';
import 'package:brikle/Wishlist/Controller/wishlist_provider.dart';
import 'package:brikle/Wishlist/View/wishlist_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: '.env');

  debugPrint('[DEBUG] ApiConfig.baseUrl      = ${ApiConfig.baseUrl}');
  debugPrint('[DEBUG] AuthApiService.baseUrl = ${AuthApiService.baseUrl}');
  Get.put(CartController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(WishlistController(), permanent: true);
  Get.put(GlobalSearchController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Brikle',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: [
        // ─── Auth & Onboarding ──────────────────────────────────────────
        GetPage(name: '/splash', page: () => const SplashView()),
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/login', page: () => const LoginView()),

        // ─── Main App ──────────────────────────────────────────────────
        GetPage(name: '/home', page: () => const MainScreen()),
        GetPage(name: '/wishlist', page: () => const WishlistScreen()),

        // ─── Calculators ──────────────────────────────────────────────
        GetPage(
          name: '/calculator',
          page: () => const MaterialCalculatorScreen(),
        ),
        GetPage(
          name: '/cement-calculator',
          page: () => const CementCalculationPage(),
        ),
        GetPage(
          name: '/steel-calculator',
          page: () => const SteelCalculatorPage(),
        ),
        GetPage(
          name: '/block-calculator',
          page: () => const BlockCalculatorPage(),
        ),
        GetPage(
          name: '/waterproofing-calculator',
          page: () => const WaterproofingCalculatorPage(),
        ),

        // In your route configuration file
        GetPage(
          name: '/order-detail',
          page: () => OrderDetailScreen(
            orderId: int.parse(Get.parameters['orderId'] ?? '0'),
          ),
        ),
      ],
    );
  }
}
