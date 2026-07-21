import 'package:brikle/AddtoCart/View/addtocart_view.dart';
import 'package:brikle/BottomNavigation/bottomnavigation.dart';
import 'package:brikle/Calculation/View/calculatiorPage.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
import 'package:brikle/HomePage/View/homepage.dart';
import 'package:brikle/Category/View/category_page.dart';
import 'package:brikle/ProfilePage/View/profilescreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final _homeCtrl = Get.find<HomeController>();

  late final List<Widget> _pages = [
    const HomeScreen(),
    CategoryPage(), // Category
    const MaterialCalculatorScreen(), // Orders
    const CartScreen(),
    const ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
