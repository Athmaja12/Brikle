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
  static const int _tabCount = 5;

  late int _currentIndex;

  final _homeCtrl = Get.find<HomeController>();

  late final List<bool> _visited = List.generate(
    _tabCount,
    (i) => i == widget.initialIndex,
  );

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return CategoryPage();
      case 2:
        return const MaterialCalculatorScreen();
      case 3:
        return const CartScreen();
      case 4:
        return const ProfileView();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // FIX: Android back button — tab switching in the IndexedStack below
      // is driven by setState, not the Navigator, so there was never
      // anything for the system back button to "pop" while sitting on a
      // non-Home tab. That meant pressing back on Cart/Category/Calculate/
      // Profile closed the whole app instead of feeling like "go back".
      //
      // canPop is only true when already on the Home tab — in every other
      // case we intercept the back press ourselves (below) and switch to
      // Home instead of letting the system decide there's "nothing to pop"
      // and exit. Once on Home, canPop is true, so this defers entirely to
      // the normal Navigator behavior: pop if there's a previous route
      // (e.g. this screen was pushed on top of something), otherwise the
      // app closes exactly as an Android app is expected to at its root.
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // We only reach here when canPop was false, i.e. _currentIndex != 0.
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_tabCount, (i) {
            if (i == _currentIndex) _visited[i] = true;
            return _visited[i] ? _buildTab(i) : const SizedBox.shrink();
          }),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex == index) return;
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
