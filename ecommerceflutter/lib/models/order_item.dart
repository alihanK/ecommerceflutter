class OrderItem {
  final int quantity;
  final String productName;
  final double productPrice;
  OrderItem({
    required this.quantity,
    required this.productName,
    required this.productPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        quantity: j['quantity'] as int,
        productName: (j['product'] as Map<String, dynamic>)['name'] as String,
        productPrice:
            ((j['product'] as Map<String, dynamic>)['new_price'] as num)
                .toDouble(),
      );
}
