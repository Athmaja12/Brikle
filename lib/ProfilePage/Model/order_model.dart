/// Matches GET /api/my-orders/ response exactly
/// Order List Model for Flipkart-style order management
class OrderModel {
  final int id;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String itemsSubtotal;
  final String totalGstTax;
  final String deliveryCharge;
  final String grandTotal;
  final String shippingAddress;
  final String pincode;
  final String requestedDeliveryDateTime;
  final List<OrderItemModel> items;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.itemsSubtotal,
    required this.totalGstTax,
    required this.deliveryCharge,
    required this.grandTotal,
    required this.shippingAddress,
    required this.pincode,
    required this.requestedDeliveryDateTime,
    required this.items,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      // Safe int parsing - handles both String and int
      id: _parseInt(json['id']),
      paymentMethod: json['payment_method']?.toString() ?? 'COD',
      paymentStatus: json['payment_status']?.toString() ?? 'PENDING',
      orderStatus: json['order_status']?.toString() ?? 'PLACED',
      itemsSubtotal: json['items_subtotal']?.toString() ?? '0.00',
      totalGstTax: json['total_gst_tax']?.toString() ?? '0.00',
      deliveryCharge: json['delivery_charge']?.toString() ?? '0.00',
      grandTotal: json['grand_total']?.toString() ?? '0.00',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      requestedDeliveryDateTime:
          json['requested_delivery_date_time']?.toString() ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItemModel.fromJson(e))
          .toList(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'order_status': orderStatus,
    'items_subtotal': itemsSubtotal,
    'total_gst_tax': totalGstTax,
    'delivery_charge': deliveryCharge,
    'grand_total': grandTotal,
    'shipping_address': shippingAddress,
    'pincode': pincode,
    'requested_delivery_date_time': requestedDeliveryDateTime,
    'items': items.map((e) => e.toJson()).toList(),
    'created_at': createdAt,
  };

  // Safe int parser helper
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper for status color
  String get orderStatusDisplay {
    switch (orderStatus.toUpperCase()) {
      case 'PLACED':
        return 'Placed';
      case 'SHIPPED':
        return 'Shipped';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return orderStatus;
    }
  }

  String get paymentStatusDisplay {
    switch (paymentStatus.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'COMPLETED':
        return 'Completed';
      case 'FAILED':
        return 'Failed';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return paymentStatus;
    }
  }
}

class OrderItemModel {
  final int id;
  final int variant;
  final String materialName;
  final int quantity;
  final String priceAtPurchase;

  OrderItemModel({
    required this.id,
    required this.variant,
    required this.materialName,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      // Safe int parsing for all numeric fields
      id: _parseInt(json['id']),
      variant: _parseInt(json['variant']),
      materialName: json['material_name']?.toString() ?? '',
      quantity: _parseInt(json['quantity']),
      priceAtPurchase: json['price_at_purchase']?.toString() ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'variant': variant,
    'material_name': materialName,
    'quantity': quantity,
    'price_at_purchase': priceAtPurchase,
  };

  double get totalPrice => (double.tryParse(priceAtPurchase) ?? 0) * quantity;

  // Safe int parser helper
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
