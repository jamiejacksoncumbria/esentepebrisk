class Staff {
  final String id;
  final String name;
  final String lastName;
  final String phone;
  final String email;

  Staff({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.email,
  });

  factory Staff.fromFirestore(Map<String, dynamic> json, String id) => Staff(
    id: id,
    name: json['name'] as String,
    lastName: json['lastName'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'lastName': lastName,
    'phone': phone,
    'email': email,
  };
}
