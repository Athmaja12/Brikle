// lib/OrdersPage/Model/order_model.dart

class OrderItem {
  final int id;
  final String productName;
  final String? productImage;
  final int quantity;
  final String unitPrice;
  final String totalPrice;

  OrderItem({
    required this.id,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] ?? 0,
        productName: json['product_name'] ?? json['product'] ?? '',
        productImage: json['product_image'],
        quantity: json['quantity'] ?? 1,
        unitPrice: (json['unit_price'] ?? json['price'] ?? '0').toString(),
        totalPrice: (json['total_price'] ?? '0').toString(),
      );
}

class OrderModel {
  final int id;
  final String orderNumber;
  final List<OrderItem> items;
  final String subtotal;
  final String productGst;
  final String deliveryCharge;
  final String deliveryGst;
  final String totalAmount;
  final String customerName;
  final String contactNumber;
  final String createdAt;
  final String? deliveredAt;
  final String shippingAddress;
  final String status;
  final String paymentMethod;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.productGst,
    required this.deliveryCharge,
    required this.deliveryGst,
    required this.totalAmount,
    required this.customerName,
    required this.contactNumber,
    required this.createdAt,
    this.deliveredAt,
    required this.shippingAddress,
    required this.status,
    required this.paymentMethod,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] ?? 0,
        orderNumber: json['order_number'] ?? '',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e))
            .toList(),
        subtotal: (json['subtotal'] ?? '0').toString(),
        productGst: (json['product_gst'] ?? '0').toString(),
        deliveryCharge: (json['delivery_charge'] ?? '0').toString(),
        deliveryGst: (json['delivery_gst'] ?? '0').toString(),
        totalAmount: (json['total_amount'] ?? '0').toString(),
        customerName: json['customer_name'] ?? '',
        contactNumber: json['contact_number'] ?? '',
        createdAt: json['created_at'] ?? '',
        deliveredAt: json['delivered_at'],
        shippingAddress: json['shipping_address'] ?? '',
        status: json['status'] ?? '',
        paymentMethod: json['payment_method'] ?? '',
      );
}