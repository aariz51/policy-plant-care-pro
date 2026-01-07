class UserProfile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? location;
  final String? membershipTier;
  final DateTime? membershipExpiry;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Existing scan limits
  final int scansUsed;
  final int scansLimit;
  final int premiumScansUsed;
  final int premiumScansLimit;
  
  // Existing Ask Expert limits
  final int askExpertCount;
  final int askExpertLimit;
  
  // NEW: Pregnancy Tools Count Fields
  final int? lmpCalculatorCount;
  final int? dueDateCalculatorCount;
  final int? ttcCalculatorCount;
  final int? babyNameGeneratorCount;
  final int? kickCounterSessions;
  final int? contractionTimerSessions;
  final int? weightGainTrackerCount;
  final int? hospitalBagChecklistCount;
  final int? babyShoppingListCount;
  final int? documentAnalysisCount;
  final int? appointmentSchedulerCount;
  
  // NEW: Advanced Features Count Fields
  final int? fertilityTrackerCount;
  final int? postpartumTrackerCount;
  final int? babyDevelopmentTrackerCount;
  final int? mentalHealthAssessments;
  final int? nutritionPlanningCount;
  final int? communityQnaQuestions;
  final int? weeklyUpdatesViewed;
  final int? partnerInvitationsSent;
  
  // User preferences
  final Map<String, dynamic>? preferences;
  final List<String>? allergies;
  final String? dietType;
  final String? pregnancyGoal;
  final int? currentTrimester;
  final DateTime? lmpDate;
  final DateTime? dueDate;
  final DateTime? deliveryDate; // For postpartum tracking

  // Add these MISSING properties after the existing ones:
  final String? selectedTrimester;
  final String? dietaryPreference;  
  final String? primaryGoal;
  final List<String>? knownAllergies;
  final String? customAllergies;
  final String? languagePref;
  final bool? emailNotifications;
  final bool? dataSharing;
  final String? mobileNumber;
  final String? countryCode;
  final bool? isPhoneVerified;
  final String? deviceId;
  final bool? isPremium;
  final bool isPersonalized;  // ADD THIS LINE
  final int? scanCount;
  final int? personalizedGuideCount;
  final int? manualSearchCount;

  const UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    this.dateOfBirth,
    this.location,
    this.membershipTier,
    this.membershipExpiry,
    this.createdAt,
    this.updatedAt,
    this.scansUsed = 0,
    this.scansLimit = 3,
    this.premiumScansUsed = 0,
    this.premiumScansLimit = 50,
    this.askExpertCount = 0,
    this.askExpertLimit = 3,
    // NEW: Default values for all pregnancy tools
    this.lmpCalculatorCount = 0,
    this.dueDateCalculatorCount = 0,
    this.ttcCalculatorCount = 0,
    this.babyNameGeneratorCount = 0,
    this.kickCounterSessions = 0,
    this.contractionTimerSessions = 0,
    this.weightGainTrackerCount = 0,
    this.hospitalBagChecklistCount = 0,
    this.babyShoppingListCount = 0,
    this.documentAnalysisCount = 0,
    this.appointmentSchedulerCount = 0,
    // NEW: Advanced features defaults
    this.fertilityTrackerCount = 0,
    this.postpartumTrackerCount = 0,
    this.babyDevelopmentTrackerCount = 0,
    this.mentalHealthAssessments = 0,
    this.nutritionPlanningCount = 0,
    this.communityQnaQuestions = 0,
    this.weeklyUpdatesViewed = 0,
    this.partnerInvitationsSent = 0,
    this.preferences,
    this.allergies,
    this.dietType,
    this.pregnancyGoal,
    this.currentTrimester,
    this.lmpDate,
    this.dueDate,
    this.deliveryDate,
    // Add these properties to the constructor:
    this.selectedTrimester,
    this.dietaryPreference,
    this.primaryGoal,
    this.knownAllergies,
    this.customAllergies,
    this.languagePref,
    this.emailNotifications,
    this.dataSharing,
    this.mobileNumber,
    this.countryCode,
    this.isPhoneVerified,
    this.deviceId,
    this.isPremium,
    this.isPersonalized = false,  // ADD THIS LINE
    this.scanCount,
    this.personalizedGuideCount,
    this.manualSearchCount,
  });

  // Helper method to determine premium status from map/json data
  static bool _determinePremiumStatus(Map<String, dynamic> data) {
    // First check explicit flags
    if (data['is_premium'] == true || data['is_pro_member'] == true) {
      return true;
    }
    // Then check membership_tier (IMPORTANT: .trim() to handle trailing whitespace in DB values)
    final tier = data['membership_tier']?.toString().toLowerCase().trim() ?? '';
    if (tier == 'premium' || 
        tier == 'premium_monthly' || tier == 'premiummonthly' ||
        tier == 'premium_yearly' || tier == 'premiumyearly' ||
        tier == 'premium_weekly' || tier == 'premiumweekly') {
      return true;
    }
    return false;
  }

  bool get isPremiumUser {
    // Check membership tier (IMPORTANT: .trim() to handle trailing whitespace in DB values)
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    if (tier == 'premium' || 
        tier == 'premium_monthly' || tier == 'premiummonthly' ||
        tier == 'premium_yearly' || tier == 'premiumyearly' ||
        tier == 'premium_weekly' || tier == 'premiumweekly') {
      return true;
    }
    // Also check isPremium flag and is_pro_member flag
    if (isPremium == true) {
      return true;
    }
    return false;
  }
  bool get isYearlyPremium {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    return tier == 'premium_yearly' || tier == 'premiumyearly';
  }

  // NEW: Tool-specific limit getters
  int get lmpCalculatorLimit {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
        return 30;
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return -1; // Unlimited
      default:
        return 3;
    }
  }

  int get dueDateCalculatorLimit {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
        return 30;
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return -1; // Unlimited
      default:
        return 3;
    }
  }

  int get ttcCalculatorLimit {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
        return 15;
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return -1; // Unlimited
      default:
        return 3;
    }
  }

  int get babyNameGeneratorLimit {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
        return 10;
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return 50;
      default:
        return 3;
    }
  }

  int get kickCounterLimit {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return -1; // Unlimited
      default:
        return 5; // Basic version max sessions
    }
  }

  int get contractionTimerLimit {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return -1; // Unlimited
      default:
        return 3; // Basic version max sessions
    }
  }

  int get documentAnalysisLimit {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_weekly':
      case 'premiumweekly':
        return 5;
      case 'premium_monthly':
      case 'premiummonthly':
      case 'premium':
        return 15;
      case 'premium_yearly':
      case 'premiumyearly':
        return 200;
      default:
        return 0; // Premium only
    }
  }

  // NEW: Pregnancy Test AI Checker limit
  int get pregnancyTestAILimit {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_weekly':
      case 'premiumweekly':
        return 3;
      case 'premium_monthly':
      case 'premiummonthly':
      case 'premium':
        return 8;
      case 'premium_yearly':
      case 'premiumyearly':
        return 40;
      default:
        return 0; // Premium only
    }
  }

  // Tool access checkers
 bool canUseLmpCalculator() => lmpCalculatorLimit == -1 || (lmpCalculatorCount ?? 0) < lmpCalculatorLimit;
bool canUseDueDateCalculator() => dueDateCalculatorLimit == -1 || (dueDateCalculatorCount ?? 0) < dueDateCalculatorLimit;
bool canUseTtcCalculator() => ttcCalculatorLimit == -1 || (ttcCalculatorCount ?? 0) < ttcCalculatorLimit;
bool canUseBabyNameGenerator() => babyNameGeneratorLimit == -1 || (babyNameGeneratorCount ?? 0) < babyNameGeneratorLimit;
bool canUseKickCounter() => kickCounterLimit == -1 || (kickCounterSessions ?? 0) < kickCounterLimit;
bool canUseContractionTimer() => contractionTimerLimit == -1 || (contractionTimerSessions ?? 0) < contractionTimerLimit;
bool canUseDocumentAnalysis() => isPremiumUser && documentAnalysisLimit != -1 && (documentAnalysisCount ?? 0) < documentAnalysisLimit;

  // Feature access checkers
  bool get canUseWeightGainTracker {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return true; // Full tracking
      default:
        return true; // View only for free users
    }
  }

  bool get canCustomizeHospitalBag {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return true;
      default:
        return false; // View only for free users
    }
  }

  bool get canSaveBabyShoppingList {
    final tier = membershipTier?.toLowerCase().trim() ?? '';
    switch (tier) {
      case 'premium_monthly':
      case 'premiummonthly':
        return (babyShoppingListCount ?? 0) < 3;
      case 'premium_yearly':
      case 'premiumyearly':
      case 'premium':
        return true; // Unlimited
      default:
        return false; // View only for free users
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      location: json['location'],
      membershipTier: json['membership_tier']?.toString().trim(),
      // Support both field names for backward compatibility
      membershipExpiry: json['subscription_expires_at'] != null 
          ? DateTime.parse(json['subscription_expires_at']) 
          : (json['membership_expiry'] != null ? DateTime.parse(json['membership_expiry']) : null),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      scansUsed: json['scans_used'] ?? 0,
      scansLimit: json['scans_limit'] ?? 3,
      premiumScansUsed: json['premium_scans_used'] ?? 0,
      premiumScansLimit: json['premium_scans_limit'] ?? 50,
      askExpertCount: json['ask_expert_count'] ?? 0,
      askExpertLimit: json['ask_expert_limit'] ?? 3,
      // NEW: Tool counts from JSON
      lmpCalculatorCount: json['lmp_calculator_count'] ?? 0,
      dueDateCalculatorCount: json['due_date_calculator_count'] ?? 0,
      ttcCalculatorCount: json['ttc_calculator_count'] ?? 0,
      babyNameGeneratorCount: json['baby_name_generator_count'] ?? 0,
      kickCounterSessions: json['kick_counter_sessions'] ?? 0,
      contractionTimerSessions: json['contraction_timer_sessions'] ?? 0,
      weightGainTrackerCount: json['weight_gain_tracker_count'] ?? 0,
      hospitalBagChecklistCount: json['hospital_bag_checklist_count'] ?? 0,
      babyShoppingListCount: json['baby_shopping_list_count'] ?? 0,
      documentAnalysisCount: json['document_analysis_count'] ?? 0,
      appointmentSchedulerCount: json['appointment_scheduler_count'] ?? 0,
      // NEW: Advanced features from JSON
      fertilityTrackerCount: json['fertility_tracker_count'] ?? 0,
      postpartumTrackerCount: json['postpartum_tracker_count'] ?? 0,
      babyDevelopmentTrackerCount: json['baby_development_tracker_count'] ?? 0,
      mentalHealthAssessments: json['mental_health_assessments'] ?? 0,
      nutritionPlanningCount: json['nutrition_planning_count'] ?? 0,
      communityQnaQuestions: json['community_qna_questions'] ?? 0,
      weeklyUpdatesViewed: json['weekly_updates_viewed'] ?? 0,
      partnerInvitationsSent: json['partner_invitations_sent'] ?? 0,
      preferences: json['preferences'],
      allergies: json['allergies'] != null ? List<String>.from(json['allergies']) : null,
      dietType: json['diet_type'],
      pregnancyGoal: json['pregnancy_goal'],
      currentTrimester: json['current_trimester'],
      lmpDate: json['lmp_date'] != null ? DateTime.parse(json['lmp_date']) : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
      // Add missing fromJson mappings:
      selectedTrimester: json['selected_trimester'],
      dietaryPreference: json['dietary_preference'],
      primaryGoal: json['primary_goal'],
      knownAllergies: json['known_allergies'] != null ? List<String>.from(json['known_allergies']) : null,
      customAllergies: json['custom_allergies'],
      languagePref: json['language_pref'],
      emailNotifications: json['email_notifications'],
      dataSharing: json['data_sharing'],
      mobileNumber: json['mobile_number'],
      countryCode: json['country_code'],
      isPhoneVerified: json['is_phone_verified'],
      deviceId: json['device_id'],
      // Check premium status from multiple sources: is_premium, is_pro_member, or membership_tier
      isPremium: _determinePremiumStatus(json),
      isPersonalized: json['is_personalized'] ?? false,  // ADD THIS LINE
      scanCount: json['scan_count'],
      personalizedGuideCount: json['personalized_guide_count'],
      manualSearchCount: json['manual_search_count'],
    );
  }

  // Add missing factory method
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString(),
      fullName: map['full_name']?.toString(),
      selectedTrimester: map['selected_trimx']?.toString(),
      dietaryPreference: map['dietary_preference']?.toString(),
      primaryGoal: map['primary_goal']?.toString(),
      knownAllergies: map['known_allergies'] != null ? List<String>.from(map['known_allergies']) : null,
      customAllergies: map['custom_allergies']?.toString(),
      languagePref: map['language_pref']?.toString(),
      emailNotifications: map['email_notifications'],
      dataSharing: map['data_sharing'],
      mobileNumber: map['mobile_number']?.toString(),
      countryCode: map['country_code']?.toString(),
      isPhoneVerified: map['is_phone_verified'],
      deviceId: map['device_id']?.toString(),
      // Check premium status from multiple sources: is_premium, is_pro_member, or membership_tier
      isPremium: _determinePremiumStatus(map),
      isPersonalized: map['is_personalized'] ?? false,  // ADD THIS LINE
      scanCount: map['scan_count'],
      personalizedGuideCount: map['personalized_guide_count'],
      manualSearchCount: map['manual_search_count'],
      // Add all your tool counts here too
      membershipTier: map['membership_tier']?.toString().trim(),
      phoneNumber: map['phone_number']?.toString(),
      profileImageUrl: map['profile_image_url']?.toString(),
      dateOfBirth: map['date_of_birth'] != null ? DateTime.parse(map['date_of_birth']) : null,
      location: map['location']?.toString(),
      // Support both field names for backward compatibility
      membershipExpiry: map['subscription_expires_at'] != null 
          ? DateTime.parse(map['subscription_expires_at']) 
          : (map['membership_expiry'] != null ? DateTime.parse(map['membership_expiry']) : null),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      scansUsed: map['scans_used'] ?? 0,
      scansLimit: map['scans_limit'] ?? 3,
      premiumScansUsed: map['premium_scans_used'] ?? 0,
      premiumScansLimit: map['premium_scans_limit'] ?? 50,
      askExpertCount: map['ask_expert_count'] ?? 0,
      askExpertLimit: map['ask_expert_limit'] ?? 3,
      lmpCalculatorCount: map['lmp_calculator_count'] ?? 0,
      dueDateCalculatorCount: map['due_date_calculator_count'] ?? 0,
      ttcCalculatorCount: map['ttc_calculator_count'] ?? 0,
      babyNameGeneratorCount: map['baby_name_generator_count'] ?? 0,
      kickCounterSessions: map['kick_counter_sessions'] ?? 0,
      contractionTimerSessions: map['contraction_timer_sessions'] ?? 0,
      weightGainTrackerCount: map['weight_gain_tracker_count'] ?? 0,
      hospitalBagChecklistCount: map['hospital_bag_checklist_count'] ?? 0,
      babyShoppingListCount: map['baby_shopping_list_count'] ?? 0,
      documentAnalysisCount: map['document_analysis_count'] ?? 0,
      appointmentSchedulerCount: map['appointment_scheduler_count'] ?? 0,
      fertilityTrackerCount: map['fertility_tracker_count'] ?? 0,
      postpartumTrackerCount: map['postpartum_tracker_count'] ?? 0,
      babyDevelopmentTrackerCount: map['baby_development_tracker_count'] ?? 0,
      mentalHealthAssessments: map['mental_health_assessments'] ?? 0,
      nutritionPlanningCount: map['nutrition_planning_count'] ?? 0,
      communityQnaQuestions: map['community_qna_questions'] ?? 0,
      weeklyUpdatesViewed: map['weekly_updates_viewed'] ?? 0,
      partnerInvitationsSent: map['partner_invitations_sent'] ?? 0,
      preferences: map['preferences'],
      allergies: map['allergies'] != null ? List<String>.from(map['allergies']) : null,
      dietType: map['diet_type']?.toString(),
      pregnancyGoal: map['pregnancy_goal']?.toString(),
      currentTrimester: map['current_trimester'],
      lmpDate: map['lmp_date'] != null ? DateTime.parse(map['lmp_date']) : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'location': location,
      'membership_tier': membershipTier,
      'membership_expiry': membershipExpiry?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'scans_used': scansUsed,
      'scans_limit': scansLimit,
      'premium_scans_used': premiumScansUsed,
      'premium_scans_limit': premiumScansLimit,
      'ask_expert_count': askExpertCount,
      'ask_expert_limit': askExpertLimit,
      // NEW: Tool counts to JSON
      'lmp_calculator_count': lmpCalculatorCount,
      'due_date_calculator_count': dueDateCalculatorCount,
      'ttc_calculator_count': ttcCalculatorCount,
      'baby_name_generator_count': babyNameGeneratorCount,
      'kick_counter_sessions': kickCounterSessions,
      'contraction_timer_sessions': contractionTimerSessions,
      'weight_gain_tracker_count': weightGainTrackerCount,
      'hospital_bag_checklist_count': hospitalBagChecklistCount,
      'baby_shopping_list_count': babyShoppingListCount,
      'document_analysis_count': documentAnalysisCount,
      'appointment_scheduler_count': appointmentSchedulerCount,
      // NEW: Advanced features to JSON
      'fertility_tracker_count': fertilityTrackerCount,
      'postpartum_tracker_count': postpartumTrackerCount,
      'baby_development_tracker_count': babyDevelopmentTrackerCount,
      'mental_health_assessments': mentalHealthAssessments,
      'nutrition_planning_count': nutritionPlanningCount,
      'community_qna_questions': communityQnaQuestions,
      'weekly_updates_viewed': weeklyUpdatesViewed,
      'partner_invitations_sent': partnerInvitationsSent,
      'preferences': preferences,
      'allergies': allergies,
      'diet_type': dietType,
      'pregnancy_goal': pregnancyGoal,
      'current_trimester': currentTrimester,
      'lmp_date': lmpDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      // Add missing toJson mappings:
      'selected_trimester': selectedTrimester,
      'dietary_preference': dietaryPreference,
      'primary_goal': primaryGoal,
      'known_allergies': knownAllergies,
      'custom_allergies': customAllergies,
      'language_pref': languagePref,
      'email_notifications': emailNotifications,
      'data_sharing': dataSharing,
      'mobile_number': mobileNumber,
      'country_code': countryCode,
      'is_phone_verified': isPhoneVerified,
      'device_id': deviceId,
      'is_premium': isPremium,
      'is_personalized': isPersonalized,  // ADD THIS LINE
      'scan_count': scanCount,
      'personalized_guide_count': personalizedGuideCount,
      'manual_search_count': manualSearchCount,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? location,
    String? membershipTier,
    DateTime? membershipExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? scansUsed,
    int? scansLimit,
    int? premiumScansUsed,
    int? premiumScansLimit,
    int? askExpertCount,
    int? askExpertLimit,
    // NEW: Tool count parameters
    int? lmpCalculatorCount,
    int? dueDateCalculatorCount,
    int? ttcCalculatorCount,
    int? babyNameGeneratorCount,
    int? kickCounterSessions,
    int? contractionTimerSessions,
    int? weightGainTrackerCount,
    int? hospitalBagChecklistCount,
    int? babyShoppingListCount,
    int? documentAnalysisCount,
    int? appointmentSchedulerCount,
    // NEW: Advanced feature parameters
    int? fertilityTrackerCount,
    int? postpartumTrackerCount,
    int? babyDevelopmentTrackerCount,
    int? mentalHealthAssessments,
    int? nutritionPlanningCount,
    int? communityQnaQuestions,
    int? weeklyUpdatesViewed,
    int? partnerInvitationsSent,
    Map<String, dynamic>? preferences,
    List<String>? allergies,
    String? dietType,
    String? pregnancyGoal,
    int? currentTrimester,
    DateTime? lmpDate,
    DateTime? dueDate,
    DateTime? deliveryDate,
    // Add missing copyWith parameters:
    String? selectedTrimester,
    String? dietaryPreference,
    String? primaryGoal,
    List<String>? knownAllergies,
    String? customAllergies,
    String? languagePref,
    bool? emailNotifications,
    bool? dataSharing,
    String? mobileNumber,
    String? countryCode,
    bool? isPhoneVerified,
    String? deviceId,
    bool? isPremium,
    bool? isPersonalized,  // ADD THIS LINE
    int? scanCount,
    int? personalizedGuideCount,
    int? manualSearchCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      membershipTier: membershipTier ?? this.membershipTier,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scansUsed: scansUsed ?? this.scansUsed,
      scansLimit: scansLimit ?? this.scansLimit,
      premiumScansUsed: premiumScansUsed ?? this.premiumScansUsed,
      premiumScansLimit: premiumScansLimit ?? this.premiumScansLimit,
      askExpertCount: askExpertCount ?? this.askExpertCount,
      askExpertLimit: askExpertLimit ?? this.askExpertLimit,
      // NEW: Tool counts
      lmpCalculatorCount: lmpCalculatorCount ?? this.lmpCalculatorCount,
      dueDateCalculatorCount: dueDateCalculatorCount ?? this.dueDateCalculatorCount,
      ttcCalculatorCount: ttcCalculatorCount ?? this.ttcCalculatorCount,
      babyNameGeneratorCount: babyNameGeneratorCount ?? this.babyNameGeneratorCount,
      kickCounterSessions: kickCounterSessions ?? this.kickCounterSessions,
      contractionTimerSessions: contractionTimerSessions ?? this.contractionTimerSessions,
      weightGainTrackerCount: weightGainTrackerCount ?? this.weightGainTrackerCount,
      hospitalBagChecklistCount: hospitalBagChecklistCount ?? this.hospitalBagChecklistCount,
      babyShoppingListCount: babyShoppingListCount ?? this.babyShoppingListCount,
      documentAnalysisCount: documentAnalysisCount ?? this.documentAnalysisCount,
      appointmentSchedulerCount: appointmentSchedulerCount ?? this.appointmentSchedulerCount,
      // NEW: Advanced features
      fertilityTrackerCount: fertilityTrackerCount ?? this.fertilityTrackerCount,
      postpartumTrackerCount: postpartumTrackerCount ?? this.postpartumTrackerCount,
      babyDevelopmentTrackerCount: babyDevelopmentTrackerCount ?? this.babyDevelopmentTrackerCount,
      mentalHealthAssessments: mentalHealthAssessments ?? this.mentalHealthAssessments,
      nutritionPlanningCount: nutritionPlanningCount ?? this.nutritionPlanningCount,
      communityQnaQuestions: communityQnaQuestions ?? this.communityQnaQuestions,
      weeklyUpdatesViewed: weeklyUpdatesViewed ?? this.weeklyUpdatesViewed,
      partnerInvitationsSent: partnerInvitationsSent ?? this.partnerInvitationsSent,
      preferences: preferences ?? this.preferences,
      allergies: allergies ?? this.allergies,
      dietType: dietType ?? this.dietType,
      pregnancyGoal: pregnancyGoal ?? this.pregnancyGoal,
      currentTrimester: currentTrimester ?? this.currentTrimester,
      lmpDate: lmpDate ?? this.lmpDate,
      dueDate: dueDate ?? this.dueDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      // Add missing copyWith assignments:
      selectedTrimester: selectedTrimester ?? this.selectedTrimester,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      knownAllergies: knownAllergies ?? this.knownAllergies,
      customAllergies: customAllergies ?? this.customAllergies,
      languagePref: languagePref ?? this.languagePref,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      dataSharing: dataSharing ?? this.dataSharing,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      countryCode: countryCode ?? this.countryCode,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      deviceId: deviceId ?? this.deviceId,
      isPremium: isPremium ?? this.isPremium,
      isPersonalized: isPersonalized ?? this.isPersonalized,  // ADD THIS LINE
      scanCount: scanCount ?? this.scanCount,
      personalizedGuideCount: personalizedGuideCount ?? this.personalizedGuideCount,
      manualSearchCount: manualSearchCount ?? this.manualSearchCount,
    );
  }
}
