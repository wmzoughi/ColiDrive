import 'user.dart';
class Supplier {
  final int id;
  final String name;
  final String? companyName;
  final String? phone;
  final String? email;

  Supplier({
    required this.id,
    required this.name,
    this.companyName,
    this.phone,
    this.email,
  });

  // Factory constructor qui prend le JSON de l'API
  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'] ?? json['company_name'] ?? '',
      companyName: json['company_name'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  // Optionnel: créer un Supplier à partir d'un User
  factory Supplier.fromUser(User user) {
    return Supplier(
      id: user.id,
      name: user.name,
      companyName: user.companyName,
      phone: user.phone,
      email: user.email,
    );
  }
}