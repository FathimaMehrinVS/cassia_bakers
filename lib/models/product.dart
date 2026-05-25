class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final String category;
  final String? imagePath;
  final int lowStockThreshold;
  final String barcode; // Unique product barcode for POS scans

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    this.imagePath,
    this.lowStockThreshold = 5,
    this.barcode = '',
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
      'barcode': barcode,
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
      barcode: map['barcode'] as String? ?? '',
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
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      barcode: barcode ?? this.barcode,
    );
  }
}
