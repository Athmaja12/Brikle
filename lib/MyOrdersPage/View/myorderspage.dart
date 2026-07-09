// lib/OrdersPage/View/orders_list_view.dart

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/MyOrdersPage/Controller/myoders_provider.dart';
import 'package:brikle/MyOrdersPage/Model/myorders_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class OrdersListView extends StatelessWidget {
  OrdersListView({super.key});

  final OrderController _ctrl = Get.put(OrderController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (_ctrl.isLoadingList.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (_ctrl.listError.value.isNotEmpty) {
          return _buildErrorState(context);
        }

        if (_ctrl.orders.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _ctrl.fetchOrders,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 16),
              vertical: Responsive.space(context, 20),
            ),
            itemCount: _ctrl.orders.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: Responsive.space(context, 12)),
            itemBuilder: (context, index) =>
                _OrderCard(order: _ctrl.orders[index], ctrl: _ctrl),
          ),
        );
      }),
    );
  }

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
        'My Orders',
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: Responsive.space(context, 80),
            height: Responsive.space(context, 80),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: Responsive.space(context, 36),
              color: AppColors.primaryGreen,
            ),
          ),
          SizedBox(height: Responsive.space(context, 16)),
          Text(
            'No orders yet',
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 18),
              fontWeight: FontWeight.w700,
              color: AppColors.inputText,
            ),
          ),
          SizedBox(height: Responsive.space(context, 8)),
          Text(
            'Your order history will appear here.',
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 14),
              color: AppColors.textGray,
            ),
          ),
          SizedBox(height: Responsive.space(context, 24)),
          GestureDetector(
            onTap: () => Get.offAllNamed('/home'),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, 28),
                vertical: Responsive.space(context, 12),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, 24),
                ),
              ),
              child: Text(
                'Start Shopping',
                style: GoogleFonts.manrope(
                  fontSize: Responsive.font(context, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: Responsive.space(context, 48),
            color: AppColors.textGray,
          ),
          SizedBox(height: Responsive.space(context, 12)),
          Text(
            _ctrl.listError.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 14),
              color: AppColors.textGray,
            ),
          ),
          SizedBox(height: Responsive.space(context, 20)),
          GestureDetector(
            onTap: _ctrl.fetchOrders,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, 24),
                vertical: Responsive.space(context, 12),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryGreen),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, 24),
                ),
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
}

// ── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.ctrl});

  final OrderModel order;
  final OrderController ctrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed('/order-detail', arguments: order.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(Responsive.space(context, 14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderNumber}',
                          style: GoogleFonts.manrope(
                            fontSize: Responsive.font(context, 14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.inputText,
                          ),
                        ),
                        SizedBox(height: Responsive.space(context, 4)),
                        Text(
                          ctrl.formatDate(order.createdAt),
                          style: GoogleFonts.manrope(
                            fontSize: Responsive.font(context, 12),
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, 10),
                      vertical: Responsive.space(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: ctrl.statusBgColor(order.status),
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, 20),
                      ),
                    ),
                    child: Text(
                      ctrl.statusLabel(order.status),
                      style: GoogleFonts.manrope(
                        fontSize: Responsive.font(context, 11),
                        fontWeight: FontWeight.w600,
                        color: ctrl.statusColor(order.status),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Items preview ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, 14),
                vertical: Responsive.space(context, 10),
              ),
              child: Column(
                children: order.items
                    .take(2)
                    .map((item) => _ItemRow(item: item, context: context))
                    .toList(),
              ),
            ),

            if (order.items.length > 2) ...[
              Padding(
                padding: EdgeInsets.only(
                  left: Responsive.space(context, 14),
                  bottom: Responsive.space(context, 8),
                ),
                child: Text(
                  '+${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 12),
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Footer: total + arrow ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, 14),
                vertical: Responsive.space(context, 12),
              ),
              child: Row(
                children: [
                  Text(
                    'Total: ',
                    style: GoogleFonts.manrope(
                      fontSize: Responsive.font(context, 13),
                      color: AppColors.textGray,
                    ),
                  ),
                  Text(
                    '₹${order.totalAmount}',
                    style: GoogleFonts.manrope(
                      fontSize: Responsive.font(context, 14),
                      fontWeight: FontWeight.w700,
                      color: AppColors.inputText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'View Details',
                    style: GoogleFonts.manrope(
                      fontSize: Responsive.font(context, 12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, 4)),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Responsive.space(context, 12),
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.context});

  final OrderItem item;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.space(context, 6)),
      child: Row(
        children: [
          // Product thumbnail or placeholder
          Container(
            width: Responsive.space(context, 36),
            height: Responsive.space(context, 36),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(Responsive.space(context, 8)),
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
                    size: Responsive.space(context, 16),
                    color: AppColors.textGray,
                  )
                : null,
          ),
          SizedBox(width: Responsive.space(context, 10)),
          Expanded(
            child: Text(
              item.productName,
              style: GoogleFonts.manrope(
                fontSize: Responsive.font(context, 13),
                fontWeight: FontWeight.w500,
                color: AppColors.inputText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: Responsive.space(context, 8)),
          Text(
            'x${item.quantity}',
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 12),
              color: AppColors.textGray,
            ),
          ),
          SizedBox(width: Responsive.space(context, 8)),
          Text(
            '₹${item.totalPrice}',
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 13),
              fontWeight: FontWeight.w600,
              color: AppColors.inputText,
            ),
          ),
        ],
      ),
    );
  }
}
