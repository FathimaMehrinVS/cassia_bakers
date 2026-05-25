class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final String category; // Cakes, Pastries, Bread, Cookies, Beverages
  final String? imagePath;
  final int lowStockThreshold;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    this.imagePath,
    this.lowStockThreshold = 5,
  });

  bool get isLowStock => stock <= lowStockThreshold && stock > 0;
  bool get isOutOfStock => stock <= 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'imagePath': imagePath,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int,
      category: map['category'] as String,
      imagePath: map['imagePath'] as String?,
      lowStockThreshold: map['lowStockThreshold'] as int? ?? 5,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
    String? category,
    String? imagePath,
    int? lowStockThreshold,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}
