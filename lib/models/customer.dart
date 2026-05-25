class Customer {
  final int? id;
  final String name;
  final String phone;
  final int loyaltyPoints;
  final double pendingDues;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.loyaltyPoints = 0,
    this.pendingDues = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'loyaltyPoints': loyaltyPoints,
      'pendingDues': pendingDues,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      loyaltyPoints: map['loyaltyPoints'] as int? ?? 0,
      pendingDues: (map['pendingDues'] as num? ?? 0.0).toDouble(),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    int? loyaltyPoints,
    double? pendingDues,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      pendingDues: pendingDues ?? this.pendingDues,
    );
  }
}
