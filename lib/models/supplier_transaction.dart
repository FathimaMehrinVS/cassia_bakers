class SupplierTransaction {
  final int? id;
  final int supplierId;
  final String productsPurchased;
  final int quantity;
  final double costPrice;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String transactionDate;
  final String? attachmentPath; // Local file path of attached bills
  final String? notes;

  SupplierTransaction({
    this.id,
    required this.supplierId,
    required this.productsPurchased,
    required this.quantity,
    required this.costPrice,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.transactionDate,
    this.attachmentPath,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplierId': supplierId,
      'productsPurchased': productsPurchased,
      'quantity': quantity,
      'costPrice': costPrice,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'transactionDate': transactionDate,
      'attachmentPath': attachmentPath,
      'notes': notes,
    };
  }

  factory SupplierTransaction.fromMap(Map<String, dynamic> map) {
    return SupplierTransaction(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int,
      productsPurchased: map['productsPurchased'] as String,
      quantity: map['quantity'] as int,
      costPrice: (map['costPrice'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      dueAmount: (map['dueAmount'] as num).toDouble(),
      transactionDate: map['transactionDate'] as String,
      attachmentPath: map['attachmentPath'] as String?,
      notes: map['notes'] as String?,
    );
  }

  SupplierTransaction copyWith({
    int? id,
    int? supplierId,
    String? productsPurchased,
    int? quantity,
    double? costPrice,
    double? totalAmount,
    double? paidAmount,
    double? dueAmount,
    String? transactionDate,
    String? attachmentPath,
    String? notes,
  }) {
    return SupplierTransaction(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      productsPurchased: productsPurchased ?? this.productsPurchased,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      notes: notes ?? this.notes,
    );
  }
}
