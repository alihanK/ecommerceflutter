import 'order_item.dart';

class Order {
  final int id;
  final double total;
  final String createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as int,
        total: (j['total'] as num).toDouble(),
        createdAt: j['created_at'] as String,
        items: (j['order_items'] as List)
            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}
