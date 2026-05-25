class User {
  final String username;
  final String role; // Admin, Staff
  final bool isLoggedIn;

  User({
    required this.username,
    required this.role,
    this.isLoggedIn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'role': role,
      'isLoggedIn': isLoggedIn ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] as String,
      role: map['role'] as String,
      isLoggedIn: (map['isLoggedIn'] as int? ?? 0) == 1,
    );
  }

  User copyWith({
    String? username,
    String? role,
    bool? isLoggedIn,
  }) {
    return User(
      username: username ?? this.username,
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}
