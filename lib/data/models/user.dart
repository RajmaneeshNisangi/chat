class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String city;
  final String state;
  final String? profile;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.city,
    required this.state,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      profile: json['profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'city': city,
      'state': state,
      'profile': profile,
    };
  }
}
