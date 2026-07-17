// view/calculator_router.dart
//
// This is the piece that makes the calculator page "dynamic": the list
// screen never hardcodes "card 1 -> PaintScreen". Instead it always asks
// api/calculator/{id}/ for a redirect_slug, and this router decides what
// to push based on that slug. Adding a 6th calculator later means adding
// one case here + one screen — nothing upstream changes.

import 'package:brikle/Calculation/View/calculations_Page.dart';
import 'package:brikle/Calculation/comingscreen.dart';
import 'package:flutter/material.dart';


class CalculatorRouter {
  static void openBySlug(BuildContext context, String slug) {
    Widget screen;

    switch (slug) {
      case 'paint-calculator':
        screen = const PaintCalculatorScreen();
        break;

      // These 4 follow the exact same pattern as Paint once you have their
      // POST payload/response — copy paint_calculator_(model/service/
      // provider/screen) and swap the fields.
      case 'aac-block-calculator':
        screen = const CalculatorComingSoonScreen(title: 'AAC Block Calculator');
        break;
      case 'cement-calculator':
        screen = const CalculatorComingSoonScreen(title: 'Cement Calculator');
        break;
      case 'steel-weight-calculator':
        screen = const CalculatorComingSoonScreen(title: 'TMT Steel Weight Calculator');
        break;
      case 'waterproofing-calculator':
        screen = const CalculatorComingSoonScreen(title: 'Dr. Fixit Waterproofing Calculator');
        break;

      default:
        screen = const CalculatorComingSoonScreen(title: 'Calculator');
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}