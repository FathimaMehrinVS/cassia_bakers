class CakeOrder {
  final String id; // e.g. ORD-00032
  final String customerName;
  final String customerPhone;
  final String cakeDetails; // e.g. "2 Tier Chocolate Cake (2 Kg)"
  final String deliveryDate;
  final String deliveryTime;
  final double totalAmount;
  final double advanceAmount;
  final String status; // Pending, Preparing, Ready, Delivered
  final String? specialInstructions;
  final String createdAt;

  CakeOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.cakeDetails,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.totalAmount,
    required this.advanceAmount,
    required this.status,
    this.specialInstructions,
    required this.createdAt,
  });

  double get pendingAmount => totalAmount - advanceAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'cakeDetails': cakeDetails,
      'deliveryDate': deliveryDate,
      'deliveryTime': deliveryTime,
      'totalAmount': totalAmount,
      'advanceAmount': advanceAmount,
      'status': status,
      'specialInstructions': specialInstructions,
      'createdAt': createdAt,
    };
  }

  factory CakeOrder.fromMap(Map<String, dynamic> map) {
    return CakeOrder(
      id: map['id'] as String,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      cakeDetails: map['cakeDetails'] as String,
      deliveryDate: map['deliveryDate'] as String,
      deliveryTime: map['deliveryTime'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      advanceAmount: (map['advanceAmount'] as num).toDouble(),
      status: map['status'] as String,
      specialInstructions: map['specialInstructions'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  CakeOrder copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? cakeDetails,
    String? deliveryDate,
    String? deliveryTime,
    double? totalAmount,
    double? advanceAmount,
    String? status,
    String? specialInstructions,
    String? createdAt,
  }) {
    return CakeOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      cakeDetails: cakeDetails ?? this.cakeDetails,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      status: status ?? this.status,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
