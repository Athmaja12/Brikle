import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:brikle/ProfilePage/Model/order_model.dart';
import 'package:brikle/ProfilePage/View/orderDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late final ProfileController _ctrl = Get.find<ProfileController>();

  // Cache material-detail futures by variant id so the same product image
  // isn't re-fetched every time the list rebuilds or repeats across orders.
  final Map<int, Future<Map<String, dynamic>>> _materialFutures = {};

  Future<Map<String, dynamic>> _materialFuture(int variantId) {
    return _materialFutures.putIfAbsent(
      variantId,
      () => ApiService.getMaterialDetails(variantId),
    );
  }

  @override
  void initState() {
    super.initState();
    _ctrl.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
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
      body: Obx(() {
        if (_ctrl.isOrdersLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (_ctrl.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Orders Yet',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inputText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start shopping to see your orders here',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Continue Shopping',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _ctrl.fetchOrders,
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.space(context, 12)),
            itemCount: _ctrl.orders.length,
            itemBuilder: (context, index) {
              final order = _ctrl.orders[index];
              return GestureDetector(
                onTap: () {
                  Get.to(
                    () => OrderDetailScreen(orderId: order.id),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                child: _buildOrderCard(context, order),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.space(context, 12)),
      padding: EdgeInsets.all(Responsive.space(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order #${order.id}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inputText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.orderStatus),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.orderStatusDisplay,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, 10)),
          ...order.items.map((item) => _buildItemRow(context, order, item)),
           if (order.hasReview) ...[
            SizedBox(height: Responsive.space(context, 8)),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < order.review!.rating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  'Your rating',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    OrderModel order,
    OrderItemModel item,
  ) {
    // The variant ID is the material ID
    final int materialId = item.variant;

    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.space(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _materialFuture(materialId),
              builder: (context, snapshot) {
                final imageUrl = snapshot.data?['image']?.toString() ?? '';
                return Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade100,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.primaryGreen,
                                size: 24,
                              ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Name + delivery date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.materialName,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inputText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  order.orderStatus.toUpperCase() == 'DELIVERED'
                      ? 'Delivered ${_formatDate(order.requestedDeliveryDateTime)}'
                      : 'Delivery by ${_formatDate(order.requestedDeliveryDateTime)}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Price
          Text(
            '₹${item.priceAtPurchase}',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inputText,
            ),
          ),
        ],
      ),
    );
  }

  // Matches backend ORDER_STATUS: PLACED, SHIPPED, DELIVERED, CANCELLED
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
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return dateTime;
    }
  }
}
