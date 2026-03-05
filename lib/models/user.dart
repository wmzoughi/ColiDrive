// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final String userType;
  final String? phone;
  final String? companyName;
  final bool isActive;
  final String? siret;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.phone,
    this.companyName,
    required this.isActive,
    this.siret,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      userType: json['user_type'],
      phone: json['phone'],
      companyName: json['company_name'],
      isActive: json['is_active'] ?? true,
      siret: json['siret'],
    );
  }

  bool get isMerchant => userType == 'commercant';
  bool get isSupplier => userType == 'fournisseur';
}