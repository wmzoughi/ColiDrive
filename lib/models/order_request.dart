// lib/models/order_request.dart
class OrderRequest {
  final String shippingAddress;
  final String shippingCity;
  final String shippingZip;
  final String shippingPhone;
  final String? notes;
  final String paymentMethod;

  OrderRequest({
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingZip,
    required this.shippingPhone,
    this.notes,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'shipping_address': shippingAddress,
      'shipping_city': shippingCity,
      'shipping_zip': shippingZip,
      'shipping_phone': shippingPhone,
      'notes': notes,
      'payment_method': paymentMethod,
    };
  }
}