// lib/models/verification_response.dart

class VerificationResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? errors;

  VerificationResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
      errors: json['errors'],
    );
  }
}