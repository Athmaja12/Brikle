// lib/MyOrdersPage/Controller/order_controller.dart

import 'dart:convert';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/MyOrdersPage/Model/myorders_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class OrderController extends GetxController {
  // ── Orders list ────────────────────────────────────────────────────────────
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxBool isLoadingList = false.obs;
  final RxString listError = ''.obs;

  // ── Order detail ───────────────────────────────────────────────────────────
  final Rx<OrderModel?> selectedOrder = Rx<OrderModel?>(null);
  final RxBool isLoadingDetail = false.obs;
  final RxString detailError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[OrderController] onInit() called');
    fetchOrders();
  }

  // ── Auth headers via SessionManager (matches rest of app) ──────────────────
  Future<Map<String, String>> _authHeaders() async {
    final token = await SessionManager.getAccessToken();
    debugPrint(
      '[OrderController] access_token from SessionManager: '
      '${token == null ? "NULL ❌" : "${token.substring(0, token.length.clamp(0, 10))}... ✅"}',
    );
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Fetch order list ───────────────────────────────────────────────────────
  Future<void> fetchOrders() async {
    try {
      isLoadingList.value = true;
      listError.value = '';
      debugPrint('[OrderController] fetchOrders() started');

      final isLoggedIn = await SessionManager.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint(
          '[OrderController] ❌ Not logged in — no access_token in session',
        );
        listError.value = 'Not authenticated.';
        return;
      }

      final headers = await _authHeaders();
      final uri = Uri.parse(ApiConfig.customerOrdersUrl);
      debugPrint('[OrderController] GET → $uri');

      final response = await http.get(uri, headers: headers);
      debugPrint('[OrderController] Response status: ${response.statusCode}');
      debugPrint('[OrderController] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[OrderController] Decoded JSON type: ${data.runtimeType}');

        final List<dynamic> list = data is List
            ? data
            : (data['results'] ?? data['orders'] ?? []);
        debugPrint('[OrderController] Order count: ${list.length}');

        orders.value = list.map((e) => OrderModel.fromJson(e)).toList();
        debugPrint('[OrderController] ✅ Orders parsed successfully');
      } else {
        debugPrint(
          '[OrderController] ❌ Non-200: ${response.statusCode} — ${response.body}',
        );
        listError.value = 'Failed to load orders (${response.statusCode}).';
      }
    } catch (e, stackTrace) {
      debugPrint('[OrderController] ❌ Exception in fetchOrders: $e');
      debugPrint('[OrderController] StackTrace: $stackTrace');
      listError.value = 'Something went wrong. Please try again.';
    } finally {
      isLoadingList.value = false;
      debugPrint(
        '[OrderController] fetchOrders() finished. Orders count: ${orders.length}',
      );
    }
  }

  // ── Fetch order detail ─────────────────────────────────────────────────────
  Future<void> fetchOrderDetail(int orderId) async {
    try {
      isLoadingDetail.value = true;
      detailError.value = '';
      selectedOrder.value = null;
      debugPrint(
        '[OrderController] fetchOrderDetail() started — orderId: $orderId',
      );

      final isLoggedIn = await SessionManager.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint(
          '[OrderController] ❌ Not logged in — no access_token in session',
        );
        detailError.value = 'Not authenticated.';
        return;
      }

      final headers = await _authHeaders();
      final uri = Uri.parse(ApiConfig.customerOrderDetailUrl(orderId));
      debugPrint('[OrderController] GET → $uri');

      final response = await http.get(uri, headers: headers);
      debugPrint('[OrderController] Response status: ${response.statusCode}');
      debugPrint('[OrderController] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint(
          '[OrderController] Decoded JSON type: ${decoded.runtimeType}',
        );
        selectedOrder.value = OrderModel.fromJson(decoded);
        debugPrint(
          '[OrderController] ✅ Order detail parsed — #${selectedOrder.value?.orderNumber}',
        );
      } else {
        debugPrint(
          '[OrderController] ❌ Non-200: ${response.statusCode} — ${response.body}',
        );
        detailError.value =
            'Failed to load order details (${response.statusCode}).';
      }
    } catch (e, stackTrace) {
      debugPrint('[OrderController] ❌ Exception in fetchOrderDetail: $e');
      debugPrint('[OrderController] StackTrace: $stackTrace');
      detailError.value = 'Something went wrong. Please try again.';
    } finally {
      isLoadingDetail.value = false;
      debugPrint('[OrderController] fetchOrderDetail() finished');
    }
  }

  // ── Status helpers ─────────────────────────────────────────────────────────
  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF16A34A);
      case 'shipped':
      case 'out_for_delivery':
        return const Color(0xFF2563EB);
      case 'processing':
      case 'confirmed':
        return const Color(0xFFD97706);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFDCFCE7);
      case 'shipped':
      case 'out_for_delivery':
        return const Color(0xFFDBEAFE);
      case 'processing':
      case 'confirmed':
        return const Color(0xFFFEF3C7);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'out_for_delivery':
        return 'Out for Delivery';
      default:
        return status
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  /// Formats ISO date string to readable form: "24 Jun 2025"
  String formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
