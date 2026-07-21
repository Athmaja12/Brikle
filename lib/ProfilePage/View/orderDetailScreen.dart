import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:brikle/ProfilePage/Model/order_model.dart';
import 'package:brikle/ProfilePage/View/reviewDialog.dart';
import 'package:brikle/ProfilePage/View/reviewListScreen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final ProfileController _ctrl = Get.find<ProfileController>();
  OrderModel? _order;
  bool _isLoading = true;
  final Map<int, Map<String, dynamic>> _materialDetails = {};

  @override
  void initState() {
    super.initState();
    debugPrint('[OrderDetailScreen] initState with orderId: ${widget.orderId}');
    _loadOrderDetail();
  }

  /// There is no separate order-detail API. /api/my-orders/ already returns
  /// everything (items, totals, address), so we look the order up from the
  /// list already held in ProfileController instead of hitting the network.
  Future<void> _loadOrderDetail() async {
    debugPrint('[OrderDetailScreen] _loadOrderDetail()');
    setState(() => _isLoading = true);

    var order = _ctrl.getOrderById(widget.orderId);

    // Fallback: orders list wasn't populated yet (e.g. deep link / cold start)
    if (order == null) {
      debugPrint('[OrderDetailScreen] Order not in memory, fetching list...');
      await _ctrl.fetchOrders();
      order = _ctrl.getOrderById(widget.orderId);
    }

    if (order == null) {
      debugPrint('[OrderDetailScreen] Order ${widget.orderId} not found');
      setState(() => _isLoading = false);

      Get.snackbar(
        'Error',
        'Failed to load order details. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.isDialogOpen != true) {
          Get.back();
        }
      });
      return;
    }

    debugPrint('[OrderDetailScreen] Order found: ${order.id}');
    debugPrint('[OrderDetailScreen] Items count: ${order.items.length}');

    // Fetch material details (for images) for each item — separate concern.
    for (var item in order.items) {
      try {
        final materialData = await ApiService.getMaterialDetails(item.variant);
        _materialDetails[item.variant] = materialData;
      } catch (e) {
        debugPrint(
          '[OrderDetailScreen] Failed to fetch material ${item.variant}: $e',
        );
      }
    }

    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.inputText,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          color: AppColors.inputText,
        ),
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _order == null
          ? const Center(child: Text('Order not found'))
          : _buildOrderDetail(context),
    );
  }

  // ── Shared card style (matches OrderListScreen exactly) ────────────────────
  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade100,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Widget _sectionCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(Responsive.space(context, 16)),
      decoration: _cardDecoration(context),
      child: child,
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.inputText,
    ),
  );

  Widget _buildOrderDetail(BuildContext context) {
    final order = _order!;
    final gap = SizedBox(height: Responsive.space(context, 16));

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.space(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context, order),
          gap,
          _buildDeliveryCard(context, order),
          // gap,
          // _buildOrderItems(context, order),
          gap,
          _buildPriceDetails(context, order),
        ],
      ),
    );
  }

  // ── Status card — pill badge, same as list screen ──────────────────────────
  Widget _buildStatusCard(BuildContext context, OrderModel order) {
    return _sectionCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inputText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.orderStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.orderStatusDisplay,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${order.grandTotal}',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inputText,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, 16)),
          _buildOrderProgress(order.orderStatus),
        ],
      ),
    );
  }

  Widget _buildOrderProgress(String status) {
    final upperStatus = status.toUpperCase();

    // Cancelled orders don't have a "progress" — show a standalone state instead
    if (upperStatus == 'CANCELLED') {
      return Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.errorRed, size: 18),
          const SizedBox(width: 8),
          Text(
            'This order was cancelled',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.errorRed,
            ),
          ),
        ],
      );
    }

    // Matches backend ORDER_STATUS exactly: PLACED → SHIPPED → DELIVERED
    final List<String> steps = ['PLACED', 'SHIPPED', 'DELIVERED'];
    final int currentIndex = steps.indexOf(upperStatus);
    final int activeIndex = currentIndex >= 0 ? currentIndex : 0;

    return Row(
      children: List.generate(steps.length, (index) {
        final bool isActive = index <= activeIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 4),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGreen
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[index][0] + steps[index].substring(1).toLowerCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? AppColors.primaryGreen
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Delivery card ────────────────────────────────────────────────────────
  Widget _buildDeliveryCard(BuildContext context, OrderModel order) {
    return _sectionCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Delivery Details'),
          const SizedBox(height: 12),
          _infoRow(
            Icons.location_on_outlined,
            order.shippingAddress,
            valueColor: AppColors.inputText,
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.pin_drop_outlined, 'Pincode: ${order.pincode}'),
          const SizedBox(height: 10),
          _infoRow(
            Icons.calendar_today_outlined,
            'Expected Delivery: ${_formatDate(order.requestedDeliveryDateTime)}',
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.access_time_outlined,
            'Ordered on: ${_formatDateTime(order.createdAt)}',
            valueColor: AppColors.textGray,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: valueColor ?? AppColors.inputText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Items card ───────────────────────────────────────────────────────────
  // Widget _buildOrderItems(BuildContext context, OrderModel order) {
  //   return _sectionCard(
  //     context: context,
  //     padding: EdgeInsets.zero,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: EdgeInsets.fromLTRB(
  //             Responsive.space(context, 16),
  //             Responsive.space(context, 16),
  //             Responsive.space(context, 16),
  //             Responsive.space(context, 8),
  //           ),
  //           child: _sectionTitle('Items (${order.items.length})'),
  //         ),
  //         ...order.items.map(
  //           (item) => Padding(
  //             padding: EdgeInsets.fromLTRB(
  //               Responsive.space(context, 16),
  //               0,
  //               Responsive.space(context, 16),
  //               Responsive.space(context, 12),
  //             ),
  //             child: _buildItemCard(context, item),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildItemCard(BuildContext context, OrderItemModel item) {
  //   // The variant ID IS the material ID
  //   final int materialId = item.variant;
  //   final materialData = _materialDetails[materialId];
  //   final String imageUrl = materialData?['image']?.toString() ?? '';

  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.grey.shade50,
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: Colors.grey.shade200),
  //     ),
  //     child: Column(
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.all(12),
  //           child: Row(
  //             children: [
  //               Container(
  //                 width: 56,
  //                 height: 56,
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(8),
  //                   border: Border.all(color: Colors.grey.shade200),
  //                 ),
  //                 child: imageUrl.isNotEmpty
  //                     ? ClipRRect(
  //                         borderRadius: BorderRadius.circular(8),
  //                         child: Image.network(
  //                           imageUrl,
  //                           width: 56,
  //                           height: 56,
  //                           fit: BoxFit.cover,
  //                           errorBuilder: (context, error, stackTrace) {
  //                             return const Icon(
  //                               Icons.inventory_2_outlined,
  //                               color: AppColors.primaryGreen,
  //                               size: 28,
  //                             );
  //                           },
  //                         ),
  //                       )
  //                     : const Icon(
  //                         Icons.inventory_2_outlined,
  //                         color: AppColors.primaryGreen,
  //                         size: 28,
  //                       ),
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       item.materialName,
  //                       style: GoogleFonts.manrope(
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w600,
  //                         color: AppColors.inputText,
  //                       ),
  //                       maxLines: 2,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Text(
  //                       'Qty: ${item.quantity} × ₹${item.priceAtPurchase}',
  //                       style: GoogleFonts.manrope(
  //                         fontSize: 12,
  //                         color: AppColors.textGray,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               Text(
  //                 '₹${item.totalPrice.toStringAsFixed(2)}',
  //                 style: GoogleFonts.manrope(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w700,
  //                   color: AppColors.inputText,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Divider(height: 1, color: Colors.grey.shade200),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: TextButton.icon(
  //                 onPressed: () {
  //                   Get.to(
  //                     () => ReviewListScreen(
  //                       materialId: materialId,
  //                       materialName: item.materialName,
  //                     ),
  //                     transition: Transition.rightToLeft,
  //                   );
  //                 },
  //                 icon: const Icon(
  //                   Icons.star_border_outlined,
  //                   size: 17,
  //                   color: AppColors.primaryGreen,
  //                 ),
  //                 label: Text(
  //                   'Reviews',
  //                   style: GoogleFonts.manrope(
  //                     fontSize: 13,
  //                     fontWeight: FontWeight.w600,
  //                     color: AppColors.primaryGreen,
  //                   ),
  //                 ),
  //                 style: TextButton.styleFrom(
  //                   padding: const EdgeInsets.symmetric(vertical: 10),
  //                 ),
  //               ),
  //             ),
  //             Container(width: 1, height: 20, color: Colors.grey.shade200),
  //             Expanded(
  //               child: TextButton.icon(
  //                 onPressed: () {
  //                   Get.dialog(
  //                     ReviewDialog(
  //                       materialId: materialId,
  //                       materialName: item.materialName,
  //                     ),
  //                     barrierDismissible: false,
  //                   );
  //                 },
  //                 icon: const Icon(
  //                   Icons.rate_review_outlined,
  //                   size: 17,
  //                   color: AppColors.primaryGreen,
  //                 ),
  //                 label: Text(
  //                   'Write Review',
  //                   style: GoogleFonts.manrope(
  //                     fontSize: 13,
  //                     fontWeight: FontWeight.w600,
  //                     color: AppColors.primaryGreen,
  //                   ),
  //                 ),
  //                 style: TextButton.styleFrom(
  //                   padding: const EdgeInsets.symmetric(vertical: 10),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ── Price details card ───────────────────────────────────────────────────
  Widget _buildPriceDetails(BuildContext context, OrderModel order) {
    return _sectionCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Price Details'),
          const SizedBox(height: 12),
          _priceRow('Items Subtotal', '₹${order.itemsSubtotal}'),
          _priceRow('GST Tax', '₹${order.totalGstTax}'),
          _priceRow('Delivery Charge', '₹${order.deliveryCharge}'),
          Divider(height: 20, color: Colors.grey.shade200),
          _priceRow('Grand Total', '₹${order.grandTotal}', isTotal: true),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Payment: ${order.paymentStatusDisplay}',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: order.paymentStatus == 'COMPLETED'
                    ? AppColors.primaryGreen
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal ? AppColors.inputText : AppColors.textGray,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? AppColors.primaryGreen : AppColors.inputText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return Colors.orange;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return AppColors.primaryGreen;
      case 'CANCELLED':
        return AppColors.errorRed;
      default:
        return AppColors.textGray;
    }
  }

  String _formatDate(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime);
      return '${parsed.day} ${_getMonth(parsed.month)} ${parsed.year}';
    } catch (_) {
      return dateTime;
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime);
      return '${parsed.day} ${_getMonth(parsed.month)} ${parsed.year}, ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTime;
    }
  }

  String _getMonth(int month) {
    const months = [
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
    return months[month - 1];
  }
}
