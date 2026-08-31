// import 'package:brikle/AddtoCart/View/addtocart_view.dart';
// import 'package:brikle/BottomNavigation/bottomnavigation.dart';
// import 'package:brikle/Calculation/View/calculatiorPage.dart';
// import 'package:brikle/HomePage/Controller/home_provider.dart';
// import 'package:brikle/HomePage/View/homepage.dart';
// import 'package:brikle/Category/View/category_page.dart';
// import 'package:brikle/ProfilePage/View/profilescreen.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class MainScreen extends StatefulWidget {
//   final int initialIndex;

//   const MainScreen({super.key, this.initialIndex = 0});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   late int _currentIndex;

//   final _homeCtrl = Get.find<HomeController>();

//   late final List<Widget> _pages = [
//     const HomeScreen(),
//     CategoryPage(), // Category
//     const MaterialCalculatorScreen(), // Orders
//     const CartScreen(),
//     const ProfileView(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true,
//       body: IndexedStack(index: _currentIndex, children: _pages),
//       bottomNavigationBar: CustomBottomNav(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
// }

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

  // ---------------------------------------------------------
  // IMPORTANT:
  // HomeController must already be registered before MainScreen
  // is built (e.g. right after Google sign-in succeeds, before
  // navigating here) so that HomeController.refresh() has a
  // head start loading data while sign-in/navigation completes.
  // ---------------------------------------------------------
  final _homeCtrl = Get.find<HomeController>();

  // Tracks which tabs have been visited at least once. Only visited
  // tabs get built — this keeps the very first frame after sign-in
  // limited to just the Home tab instead of building all 5 screens
  // (and firing all their initState/onInit) at once.
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
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_tabCount, (i) {
          if (i == _currentIndex) _visited[i] = true;
          // Only build a tab once it has actually been visited.
          // Once built it stays in the tree (IndexedStack keeps it
          // alive), so switching back to it afterward is instant.
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
    );
  }
}
