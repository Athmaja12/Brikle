import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Calculation/View/calculatiorPage.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
import 'package:brikle/LoginScreen/View/loginscreen.dart';
import 'package:brikle/MyOrdersPage/View/myorderspage.dart';
import 'package:brikle/MyOrdersPage/View/orderdetailspage.dart';
import 'package:brikle/OnboardingScreens/View/onboardingscrenn.dart';
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

  Get.put(CartController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(WishlistController(), permanent: true);

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
        GetPage(name: '/splash', page: () => const SplashView()),
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/login', page: () => const LoginView()),
        // GetPage(name: '/register', page: () => const RegistrationScreen()),
        GetPage(name: '/home', page: () => const MainScreen()),
        GetPage(name: '/orders', page: () => OrdersListView()),
        GetPage(name: '/order-detail', page: () => const OrderDetailView()),
        GetPage(name: '/wishlist', page: () => const WishlistScreen()),
        GetPage(name: '/calculator', page: () => const MaterialCalculatorScreen()),
      ],
    );
  }
}
