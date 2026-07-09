import 'package:brikle/AppStyle/appcolors.dart';
import 'package:flutter/material.dart';

/// Bottom navigation bar — white bar, top corners rounded, icon+label per
/// tab, active state = primaryGreen, inactive = gray. Scaled via
/// MediaQuery against the 390px Figma frame, same overflow-safe approach
/// as before: each tab is Expanded rather than fixed-width, so the row
/// always divides real available width evenly — no hardcoded gap value
/// can ever push it past the screen edge on other device widths.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const double _figmaFrameWidth = 390;
  static const double _figmaBarHeight = 68;
  static const double _figmaRadius = 14;
  static const double _figmaPaddingTop = 8;
  static const double _figmaPaddingRight = 34.73;
  static const double _figmaPaddingBottom = 8;
  static const double _figmaPaddingLeft = 34.72;
  static const double _figmaIconSize = 22;

 static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.home_rounded,
      outlineIcon: Icons.home_outlined,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.category_rounded,
      outlineIcon: Icons.category_outlined,
      label: 'Category',
    ),
    _NavItemData(
      icon: Icons.receipt_long_rounded,
      outlineIcon: Icons.receipt_long_outlined,
      label: 'Orders',
    ),
    _NavItemData(
      icon: Icons.shopping_cart_rounded,
      outlineIcon: Icons.shopping_cart_outlined,
      label: 'Cart',
    ),
    _NavItemData(
      icon: Icons.person_rounded,
      outlineIcon: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.size.width / _figmaFrameWidth;

    final barHeight = _figmaBarHeight * scale;
    final radius = _figmaRadius * scale;
    final iconSize = _figmaIconSize * scale;

    final paddingTop = _figmaPaddingTop * scale;
    final paddingRight = _figmaPaddingRight * scale;
    final paddingBottom = _figmaPaddingBottom * scale + media.padding.bottom;
    final paddingLeft = _figmaPaddingLeft * scale;

    return Container(
      width: double.infinity,
      height: barHeight + media.padding.bottom,
      padding: EdgeInsets.only(
        top: paddingTop,
        right: paddingRight,
        bottom: paddingBottom,
        left: paddingLeft,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
        border: const Border(
          top: BorderSide(color: Color.fromRGBO(236, 236, 236, 0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4), // shadow cast upward, per spec
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int index = 0; index < _items.length; index++)
            Expanded(
              child: _NavTab(
                data: _items[index],
                isActive: index == currentIndex,
                iconSize: iconSize,
                onTap: () => onTap(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData outlineIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.outlineIcon,
    required this.label,
  });
}

class _NavTab extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final double iconSize;
  final VoidCallback onTap;

  const _NavTab({
    required this.data,
    required this.isActive,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryGreen : AppColors.textGray;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? data.icon : data.outlineIcon,
            size: iconSize,
            color: color,
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
            child: Text(data.label),
          ),
        ],
      ),
    );
  }
}
