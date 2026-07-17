// lib/AddtoCart/Model/address_model.dart
class AddressModel {
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? customerType;
  final String? gstNumber;
  final bool isVerified;
  final String address;
  final String pincode;

  AddressModel({
    this.fullName,
    this.email,
    this.phoneNumber,
    this.customerType,
    this.gstNumber,
    this.isVerified = false,
    required this.address,
    required this.pincode,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        fullName: json['full_name']?.toString(),
        email: json['email']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        customerType: json['customer_type']?.toString(),
        gstNumber: json['gst_number']?.toString(),
        isVerified: json['is_verified'] ?? false,
        address: json['address']?.toString() ?? '',
        pincode: json['pincode']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (customerType != null) 'customer_type': customerType,
        if (gstNumber != null) 'gst_number': gstNumber,
        'is_verified': isVerified,
        'address': address,
        'pincode': pincode,
      };
}

class PincodeCheckResponse {
  final String pincode;
  final bool isServiceable;
  final String message;

  PincodeCheckResponse({
    required this.pincode,
    required this.isServiceable,
    required this.message,
  });

  factory PincodeCheckResponse.fromJson(Map<String, dynamic> json) =>
      PincodeCheckResponse(
        pincode: json['pincode']?.toString() ?? '',
        isServiceable: json['is_serviceable'] ?? false,
        message: json['message']?.toString() ?? '',
      );
}

class VehicleModel {
  final int id;
  final String vehicleName;
  final String vehicleNumber;
  final int maxCapacityKg;
  final String driverName;
  final String driverPhone;
  final String status;
  final bool isActive;

  VehicleModel({
    required this.id,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.maxCapacityKg,
    required this.driverName,
    required this.driverPhone,
    required this.status,
    required this.isActive,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: json['id'] as int? ?? 0,
        vehicleName: json['vehicle_name']?.toString() ?? '',
        vehicleNumber: json['vehicle_number']?.toString() ?? '',
        maxCapacityKg: (json['max_capacity_kg'] as num?)?.toInt() ?? 0,
        driverName: json['driver_name']?.toString() ?? '',
        driverPhone: json['driver_phone']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        isActive: json['is_active'] ?? false,
      );
}

class DeliveryConfig {
  final String pincode;
  final double totalDistanceKm;
  final int freeDistanceLimitKm;
  final double chargePerExtraKm;

  DeliveryConfig({
    required this.pincode,
    required this.totalDistanceKm,
    required this.freeDistanceLimitKm,
    required this.chargePerExtraKm,
  });

  factory DeliveryConfig.fromJson(Map<String, dynamic> json) => DeliveryConfig(
        pincode: json['pincode']?.toString() ?? '',
        totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
        freeDistanceLimitKm: (json['free_distance_limit_km'] as num?)?.toInt() ?? 0,
        chargePerExtraKm: (json['charge_per_extra_km'] as num?)?.toDouble() ?? 0,
      );

  double get extraDistance => 
      totalDistanceKm > freeDistanceLimitKm 
          ? totalDistanceKm - freeDistanceLimitKm 
          : 0;
  
  double get extraCharge => extraDistance * chargePerExtraKm;
  
  String get distanceMessage {
    if (totalDistanceKm <= freeDistanceLimitKm) {
      return '📍 Delivery within ${freeDistanceLimitKm}km - No extra charge';
    }
    return '📍 Distance: ${totalDistanceKm.toStringAsFixed(1)}km | '
        'Extra: ${extraDistance.toStringAsFixed(1)}km × ₹${chargePerExtraKm.toStringAsFixed(0)} = ₹${extraCharge.toStringAsFixed(0)} extra';
  }
}

class PaymentSummary {
  final double itemsSubtotalBeforeGst;
  final double totalGstTax;
  final double itemsTotalWithGst;
  final double couponDiscount;
  final double deliveryCharge;
  final double grandTotal;

  PaymentSummary({
    required this.itemsSubtotalBeforeGst,
    required this.totalGstTax,
    required this.itemsTotalWithGst,
    required this.couponDiscount,
    required this.deliveryCharge,
    required this.grandTotal,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) => PaymentSummary(
        itemsSubtotalBeforeGst:
            (json['items_subtotal_before_gst'] as num?)?.toDouble() ?? 0,
        totalGstTax: (json['total_gst_tax'] as num?)?.toDouble() ?? 0,
        itemsTotalWithGst:
            (json['items_total_with_gst'] as num?)?.toDouble() ?? 0,
        couponDiscount: (json['coupon_discount'] as num?)?.toDouble() ?? 0,
        deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0,
        grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      );
}

class CheckoutResponse {
  final bool deliveryAvailable;
  final String message;
  final String scheduledDeliveryDate;
  final DeliveryConfig deliveryConfig;
  final Map<String, dynamic>? couponApplied;
  final PaymentSummary paymentSummary;

  CheckoutResponse({
    required this.deliveryAvailable,
    required this.message,
    required this.scheduledDeliveryDate,
    required this.deliveryConfig,
    this.couponApplied,
    required this.paymentSummary,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) => CheckoutResponse(
        deliveryAvailable: json['delivery_available'] ?? false,
        message: json['message']?.toString() ?? '',
        scheduledDeliveryDate: json['scheduled_delivery_date']?.toString() ?? '',
        deliveryConfig: DeliveryConfig.fromJson(
            json['delivery_config_applied'] ?? {}),
        couponApplied: json['coupon_applied'] as Map<String, dynamic>?,
        paymentSummary:
            PaymentSummary.fromJson(json['payment_summary'] ?? {}),
      );
}

class OrderPlacedResponse {
  final String message;
  final OrderDetails orderDetails;

  OrderPlacedResponse({
    required this.message,
    required this.orderDetails,
  });

  factory OrderPlacedResponse.fromJson(Map<String, dynamic> json) =>
      OrderPlacedResponse(
        message: json['message']?.toString() ?? '',
        orderDetails: OrderDetails.fromJson(json['order_details'] ?? {}),
      );
}

class OrderDetails {
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
  final String requestedDeliveryDate;
  final List<OrderItem> items;
  final String createdAt;

  OrderDetails({
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
    required this.requestedDeliveryDate,
    required this.items,
    required this.createdAt,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) => OrderDetails(
        id: json['id'] as int? ?? 0,
        paymentMethod: json['payment_method']?.toString() ?? '',
        paymentStatus: json['payment_status']?.toString() ?? '',
        orderStatus: json['order_status']?.toString() ?? '',
        itemsSubtotal: json['items_subtotal']?.toString() ?? '0',
        totalGstTax: json['total_gst_tax']?.toString() ?? '0',
        deliveryCharge: json['delivery_charge']?.toString() ?? '0',
        grandTotal: json['grand_total']?.toString() ?? '0',
        shippingAddress: json['shipping_address']?.toString() ?? '',
        pincode: json['pincode']?.toString() ?? '',
        requestedDeliveryDate: json['requested_delivery_date']?.toString() ?? '',
        items: (json['items'] as List? ?? [])
            .map((e) => OrderItem.fromJson(e))
            .toList(),
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class OrderItem {
  final int id;
  final int variant;
  final int quantity;
  final String priceAtPurchase;

  OrderItem({
    required this.id,
    required this.variant,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int? ?? 0,
        variant: json['variant'] as int? ?? 0,
        quantity: json['quantity'] as int? ?? 0,
        priceAtPurchase: json['price_at_purchase']?.toString() ?? '0',
      );
}