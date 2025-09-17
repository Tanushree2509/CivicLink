class UserModel {
  String? id;
  String name;
  String email;
  String role;
  String? department;
  String? phone;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'phone': phone,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: map['role'],
      department: map['department'],
      phone: map['phone'],
    );
  }
}