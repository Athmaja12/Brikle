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
  double get itemsAmountInclGst {
    final subtotal = double.tryParse(itemsSubtotal) ?? 0.0;
    final gst = double.tryParse(totalGstTax) ?? 0.0;
    return subtotal + gst;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final dynamic reviewJson =
        json['review'] ?? json['order_review'] ?? json['rating_review'];
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
      review: reviewJson is Map<String, dynamic>
          ? OrderReviewModel.fromJson(reviewJson)
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
  final String materialImage; // image URL sent directly in items[]
  final int quantity;
  final String priceAtPurchase; // GST-inclusive unit price
  final double? explicitTotalPrice; // GST-inclusive line total

  OrderItemModel({
    required this.id,
    required this.variant,
    required this.materialName,
    this.materialImage = '',
    required this.quantity,
    required this.priceAtPurchase,
    this.explicitTotalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawQtyStr =
        (json['quantity'] ??
                json['qty'] ??
                json['count'] ??
                json['number_of_items'])
            ?.toString();
    final double parsedQty = double.tryParse(rawQtyStr ?? '') ?? 0;
    final int qty = parsedQty > 0 ? parsedQty.round() : 1;

    final double? apiTotalWithTax = json['total_item_price_with_tax'] != null
        ? double.tryParse(json['total_item_price_with_tax'].toString())
        : null;

    double unitPriceInclGst;
    if (apiTotalWithTax != null && apiTotalWithTax > 0 && qty > 0) {
      unitPriceInclGst = apiTotalWithTax / qty;
    } else {
      final double basePrice =
          double.tryParse(json['price_at_purchase']?.toString() ?? '') ?? 0.0;
      final double gstPerUnit =
          double.tryParse(json['gst_amount_per_unit']?.toString() ?? '') ?? 0.0;
      if (basePrice > 0) {
        unitPriceInclGst = basePrice + gstPerUnit;
      } else {
        final rawPrice =
            json['unit_price_with_gst'] ??
            json['price_with_gst'] ??
            json['price'] ??
            json['unit_price'] ??
            json['amount'] ??
            json['total'];
        unitPriceInclGst = double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;
      }
    }

    final double explicitTotal = apiTotalWithTax ?? (unitPriceInclGst * qty);

    return OrderItemModel(
      id: _parseInt(json['id']),
      variant: _parseInt(
        json['variant'] ??
            json['variant_id'] ??
            json['material'] ??
            json['material_id'],
      ),
      materialName:
          json['material_name']?.toString() ??
          json['name'] ??
          json['material_title'] ??
          '',
      // Real field from your payload: "material_image".
      // A couple of alternate spellings kept as fallback only.
      materialImage:
          json['material_image']?.toString() ??
          json['image']?.toString() ??
          json['material_image_url']?.toString() ??
          '',
      quantity: qty,
      priceAtPurchase: unitPriceInclGst > 0
          ? unitPriceInclGst.toStringAsFixed(2)
          : '0.00',
      explicitTotalPrice: explicitTotal > 0 ? explicitTotal : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'variant': variant,
    'material_name': materialName,
    'material_image': materialImage,
    'quantity': quantity,
    'price_at_purchase': priceAtPurchase,
    if (explicitTotalPrice != null) 'total_price': explicitTotalPrice,
  };

  double get unitPrice => double.tryParse(priceAtPurchase) ?? 0.0;

  double get totalPrice {
    if (explicitTotalPrice != null && explicitTotalPrice! > 0) {
      return explicitTotalPrice!;
    }
    return unitPrice * (quantity <= 0 ? 1 : quantity);
  }

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
      order: _parseInt(json['order'] ?? json['order_id']),
      customerName:
          (json['customer_name'] ??
                  json['user_name'] ??
                  json['reviewer_name'] ??
                  json['name'])
              ?.toString() ??
          '',
      rating: _parseInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      createdAt:
          (json['created_at'] ?? json['createdAt'] ?? json['date'])
              ?.toString() ??
          '',
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
