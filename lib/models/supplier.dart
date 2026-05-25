class Supplier {
  final int? id;
  final String name;
  final String phone;
  final String? email;
  final double pendingDues;
  final double paidAmount;
  final String? notes;

  Supplier({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.pendingDues = 0.0,
    this.paidAmount = 0.0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'pendingDues': pendingDues,
      'paidAmount': paidAmount,
      'notes': notes,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      pendingDues: (map['pendingDues'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
    );
  }

  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    double? pendingDues,
    double? paidAmount,
    String? notes,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      pendingDues: pendingDues ?? this.pendingDues,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
    );
  }
}
