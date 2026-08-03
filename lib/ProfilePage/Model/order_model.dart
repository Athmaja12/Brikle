import 'package:brikle/ProfilePage/Model/review_model.dart';

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
  final int materialId;
  OrderReviewModel? review; // ← was ReviewModel?

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
    required this.materialId,
    this.review,
  });

  bool get isDelivered => orderStatus.toUpperCase() == 'DELIVERED';

  bool get hasReview => review != null;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
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
      materialId: _parseInt(json['material_id']),
      review: json['review'] != null
          ? OrderReviewModel.fromJson(json['review'] as Map<String, dynamic>)
          : null,
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
    'material_id': materialId,
    if (review != null) 'review': review!.toJson(),
  };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

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

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
/// Matches POST /api/orders/{orderId}/review/ response exactly:
/// { "id": 1, "order": 153, "customer_name": "Albert", "rating": 5,
///   "comment": "...", "created_at": "..." }
class OrderReviewModel {
  final int id;
  final int order;
  final String customerName;
  final int rating;
  final String comment;
  final String createdAt;

  OrderReviewModel({
    required this.id,
    required this.order,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory OrderReviewModel.fromJson(Map<String, dynamic> json) {
    return OrderReviewModel(
      id: _parseInt(json['id']),
      order: _parseInt(json['order']),
      customerName: json['customer_name']?.toString() ?? '',
      rating: _parseInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'customer_name': customerName,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt,
  };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Wrapper so the UI/controller gets a clean success/message/data contract
/// even on a 400 (e.g. "already reviewed this order").
class OrderReviewResponse {
  final bool success;
  final String message;
  final OrderReviewModel? review;

  OrderReviewResponse({
    required this.success,
    required this.message,
    this.review,
  });
}