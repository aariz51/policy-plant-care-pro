class FertilityTracker {
  final String id;
  final String userId;
  final DateTime recordDate;
  final String? menstrualPhase;
  final double? basalBodyTemp;
  final String? cervicalMucus;
  final List<String> symptoms;
  final bool isFertileDay;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FertilityTracker({
    required this.id,
    required this.userId,
    required this.recordDate,
    this.menstrualPhase,
    this.basalBodyTemp,
    this.cervicalMucus,
    this.symptoms = const [],
    this.isFertileDay = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FertilityTracker.fromMap(Map<String, dynamic> map) {
    return FertilityTracker(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      recordDate: DateTime.parse(map['record_date'] as String),
      menstrualPhase: map['menstrual_phase'] as String?,
      basalBodyTemp: map['basal_body_temp'] != null 
          ? double.parse(map['basal_body_temp'].toString()) 
          : null,
      cervicalMucus: map['cervical_mucus'] as String?,
      symptoms: (map['symptoms'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      isFertileDay: map['is_fertile_day'] as bool? ?? false,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'record_date': recordDate.toIso8601String().substring(0, 10),
      'menstrual_phase': menstrualPhase,
      'basal_body_temp': basalBodyTemp,
      'cervical_mucus': cervicalMucus,
      'symptoms': symptoms,
      'is_fertile_day': isFertileDay,
      'notes': notes,
    };
  }
}
