// lib/OrdersPage/View/order_detail_view.dart

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/MyOrdersPage/Controller/myoders_provider.dart';
import 'package:brikle/MyOrdersPage/Model/myorders_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetailView extends StatefulWidget {
  const OrderDetailView({super.key});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  late final OrderController _ctrl = Get.find<OrderController>();

  @override
  void initState() {
    super.initState();
    final int orderId = Get.arguments as int;
    _ctrl.fetchOrderDetail(orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (_ctrl.isLoadingDetail.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (_ctrl.detailError.value.isNotEmpty) {
          return _buildError(context);
        }

        final order = _ctrl.selectedOrder.value;
        if (order == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, 16),
            vertical: Responsive.space(context, 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBanner(context, order),
              SizedBox(height: Responsive.space(context, 16)),
              _buildOrderInfo(context, order),
              SizedBox(height: Responsive.space(context, 16)),
              _buildItemsCard(context, order),
              SizedBox(height: Responsive.space(context, 16)),
              _buildPriceSummary(context, order),
              SizedBox(height: Responsive.space(context, 16)),
              _buildDeliveryCard(context, order),
              SizedBox(height: Responsive.space(context, 24)),
            ],
          ),
        );
      }),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: Responsive.space(context, 20),
          color: AppColors.inputText,
        ),
      ),
      title: Text(
        'Order Details',
        style: GoogleFonts.manrope(
          fontSize: Responsive.font(context, 18),
          fontWeight: FontWeight.w700,
          color: AppColors.inputText,
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE5E7EB)),
      ),
    );
  }

  // ── Status Banner ──────────────────────────────────────────────────────────
  Widget _buildStatusBanner(BuildContext context, OrderModel order) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, 16)),
      decoration: BoxDecoration(
        color: _ctrl.statusBgColor(order.status),
        borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
        border: Border.all(
          color: _ctrl.statusColor(order.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: Responsive.space(context, 40),
            height: Responsive.space(context, 40),
            decoration: BoxDecoration(
              color: _ctrl.statusColor(order.status).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(order.status),
              color: _ctrl.statusColor(order.status),
              size: Responsive.space(context, 20),
            ),
          ),
          SizedBox(width: Responsive.space(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ctrl.statusLabel(order.status),
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 15),
                    fontWeight: FontWeight.w700,
                    color: _ctrl.statusColor(order.status),
                  ),
                ),
                if (order.deliveredAt != null) ...[
                  SizedBox(height: Responsive.space(context, 2)),
                  Text(
                    'Delivered on ${_ctrl.formatDate(order.deliveredAt!)}',
                    style: GoogleFonts.manrope(
                      fontSize: Responsive.font(context, 12),
                      color: _ctrl.statusColor(order.status).withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_outline_rounded;
      case 'shipped':
      case 'out_for_delivery':
        return Icons.local_shipping_outlined;
      case 'processing':
      case 'confirmed':
        return Icons.hourglass_top_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ── Order Info ─────────────────────────────────────────────────────────────
  Widget _buildOrderInfo(BuildContext context, OrderModel order) {
    return _SectionCard(
      context: context,
      title: 'Order Info',
      child: Column(
        children: [
          _infoRow(context, 'Order Number', '#${order.orderNumber}',
              valueBold: true),
          _divider(),
          _infoRow(context, 'Placed On', _ctrl.formatDate(order.createdAt)),
          _divider(),
          _infoRow(context, 'Payment Method',
              _formatPaymentMethod(order.paymentMethod)),
          _divider(),
          _infoRow(context, 'Customer', order.customerName),
          _divider(),
          _infoRow(context, 'Contact', order.contactNumber),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    return method
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // ── Items ──────────────────────────────────────────────────────────────────
  Widget _buildItemsCard(BuildContext context, OrderModel order) {
    return _SectionCard(
      context: context,
      title: 'Items (${order.items.length})',
      child: Column(
        children: List.generate(order.items.length * 2 - 1, (i) {
          if (i.isOdd) return _divider();
          final item = order.items[i ~/ 2];
          return _DetailItemRow(item: item, context: context);
        }),
      ),
    );
  }

  // ── Price Summary ──────────────────────────────────────────────────────────
  Widget _buildPriceSummary(BuildContext context, OrderModel order) {
    return _SectionCard(
      context: context,
      title: 'Price Summary',
      child: Column(
        children: [
          _infoRow(context, 'Subtotal', '₹${order.subtotal}'),
          _divider(),
          _infoRow(context, 'Product GST', '₹${order.productGst}'),
          _divider(),
          _infoRow(context, 'Delivery Charge', '₹${order.deliveryCharge}'),
          _divider(),
          _infoRow(context, 'Delivery GST', '₹${order.deliveryGst}'),
          _divider(),
          // Total row — highlighted
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 16),
              vertical: Responsive.space(context, 14),
            ),
            child: Row(
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 14),
                    fontWeight: FontWeight.w700,
                    color: AppColors.inputText,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${order.totalAmount}',
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Delivery Card ──────────────────────────────────────────────────────────
  Widget _buildDeliveryCard(BuildContext context, OrderModel order) {
    return _SectionCard(
      context: context,
      title: 'Delivery Address',
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, 16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: Responsive.space(context, 36),
              height: Responsive.space(context, 36),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryGreen,
                size: Responsive.space(context, 18),
              ),
            ),
            SizedBox(width: Responsive.space(context, 12)),
            Expanded(
              child: Text(
                order.shippingAddress,
                style: GoogleFonts.manrope(
                  fontSize: Responsive.font(context, 13),
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGray,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: Responsive.space(context, 48),
            color: AppColors.textGray,
          ),
          SizedBox(height: Responsive.space(context, 12)),
          Text(
            _ctrl.detailError.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 14),
              color: AppColors.textGray,
            ),
          ),
          SizedBox(height: Responsive.space(context, 20)),
          GestureDetector(
            onTap: () => _ctrl.fetchOrderDetail(Get.arguments as int),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, 24),
                vertical: Responsive.space(context, 12),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryGreen),
                borderRadius:
                    BorderRadius.circular(Responsive.space(context, 24)),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.manrope(
                  fontSize: Responsive.font(context, 14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _infoRow(BuildContext context, String label, String value,
      {bool valueBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: Responsive.space(context, 13),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 13),
              color: AppColors.textGray,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.manrope(
                fontSize: Responsive.font(context, 13),
                fontWeight:
                    valueBold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.inputText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFFE5E7EB));
}

// ── Reusable section card ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.context,
    required this.title,
    required this.child,
  });

  final BuildContext context;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: Responsive.font(context, 15),
            fontWeight: FontWeight.w600,
            color: AppColors.inputText,
          ),
        ),
        SizedBox(height: Responsive.space(context, 10)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(Responsive.space(context, 12)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(Responsive.space(context, 12)),
            child: child,
          ),
        ),
      ],
    );
  }
}

// ── Detail item row (full info) ───────────────────────────────────────────────

class _DetailItemRow extends StatelessWidget {
  const _DetailItemRow({required this.item, required this.context});

  final OrderItem item;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Responsive.space(context, 14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          Container(
            width: Responsive.space(context, 52),
            height: Responsive.space(context, 52),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius:
                  BorderRadius.circular(Responsive.space(context, 8)),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              image: item.productImage != null
                  ? DecorationImage(
                      image: NetworkImage(item.productImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.productImage == null
                ? Icon(
                    Icons.shopping_bag_outlined,
                    size: Responsive.space(context, 22),
                    color: AppColors.textGray,
                  )
                : null,
          ),
          SizedBox(width: Responsive.space(context, 12)),

          // Name + unit price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.inputText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.space(context, 4)),
                Text(
                  '₹${item.unitPrice} × ${item.quantity}',
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 12),
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: Responsive.space(context, 8)),

          // Total price
          Text(
            '₹${item.totalPrice}',
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 14),
              fontWeight: FontWeight.w700,
              color: AppColors.inputText,
            ),
          ),
        ],
      ),
    );
  }
}