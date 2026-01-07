// lib/core/models/user_pregnancy_details.dart
class UserPregnancyDetails {
  final String userId;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPregnancyDetails({
    required this.userId,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPregnancyDetails.fromJson(Map<String, dynamic> json) {
    return UserPregnancyDetails(
      userId: json['user_id'] as String,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'due_date': dueDate?.toIso8601String().substring(0,10), // Send as YYYY-MM-DD for 'date' type
      // createdAt and updatedAt are typically handled by the database
    };
  }

  UserPregnancyDetails copyWith({
    String? userId,
    DateTime? dueDate,
    bool clearDueDate = false, // To explicitly set dueDate to null
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPregnancyDetails(
      userId: userId ?? this.userId,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}