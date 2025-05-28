class Product {
  final int id;
  final String name;
  final String? description;
  final double oldPrice;
  final double newPrice;
  final String? imageUrl;
  final int stock;
  final int categoryId;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.oldPrice,
    required this.newPrice,
    this.imageUrl,
    required this.stock,
    required this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        name: j['name'] as String,
        description: j['description'] as String?,
        oldPrice: (j['old_price'] as num).toDouble(),
        newPrice: (j['new_price'] as num).toDouble(),
        imageUrl: j['image_url'] as String?,
        stock: (j['stock'] as int?) ?? 0,
        categoryId: j['category_id'] as int,
      );
}
