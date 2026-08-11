import 'dart:convert';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local, on-device cart storage for guests (not logged in). Once the
/// user logs in, CartController.mergeGuestCartAfterLogin() pushes these
/// items to the server cart and clears this store.
class GuestCartService {
  GuestCartService._();

  static const _key = 'guest_cart_items_v1';

  static Future<List<CartItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}