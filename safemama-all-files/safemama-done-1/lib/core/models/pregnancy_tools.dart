class PregnancyCalculator {
  
  // ENHANCED: LMP Calculator with multiple features
  static Map<String, dynamic> calculateFromLMP(DateTime lmpDate) {
    final today = DateTime.now();
    final daysSinceLmp = today.difference(lmpDate).inDays;
    final currentWeek = (daysSinceLmp / 7).floor();
    final currentDay = daysSinceLmp % 7;
    
    // Calculate due date (280 days from LMP)
    final dueDate = lmpDate.add(const Duration(days: 280));
    final daysUntilDue = dueDate.difference(today).inDays;
    
    // Calculate conception date (approximately 14 days after LMP)
    final conceptionDate = lmpDate.add(const Duration(days: 14));
    
    // Determine trimester
    String trimester;
    if (currentWeek <= 12) {
      trimester = 'First Trimester';
    } else if (currentWeek <= 27) {
      trimester = 'Second Trimester';
    } else {
      trimester = 'Third Trimester';
    }
    
    // Calculate baby size estimation
    final babySize = _getBabySizeByWeek(currentWeek);
    
    // Calculate milestone dates
    final milestones = _calculateMilestones(lmpDate);
    
    return {
      'lmpDate': lmpDate,
      'dueDate': dueDate,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'daysUntilDue': daysUntilDue,
      'conceptionDate': conceptionDate,
      'trimester': trimester,
      'babySize': babySize,
      'milestones': milestones,
      'gestationalAge': '$currentWeek weeks, $currentDay days',
      'percentComplete': currentWeek / 40 * 100,
    };
  }

  // NEW: Multiple due date calculation methods
  static Map<String, dynamic> calculateDueDate({
    DateTime? lmp,
    DateTime? conceptionDate,
    DateTime? ivfTransferDate,
    DateTime? ultrasoundDate,
    int? ultrasoundWeeks,
  }) {
    DateTime calculatedDueDate;
    String calculationMethod;
    
    if (lmp != null) {
      calculatedDueDate = lmp.add(const Duration(days: 280));
      calculationMethod = 'Last Menstrual Period (LMP)';
    } else if (conceptionDate != null) {
      calculatedDueDate = conceptionDate.add(const Duration(days: 266));
      calculationMethod = 'Conception Date';
    } else if (ivfTransferDate != null) {
      calculatedDueDate = ivfTransferDate.add(const Duration(days: 266));
      calculationMethod = 'IVF Transfer Date';
    } else if (ultrasoundDate != null && ultrasoundWeeks != null) {
      final daysFromUltrasound = (40 - ultrasoundWeeks) * 7;
      calculatedDueDate = ultrasoundDate.add(Duration(days: daysFromUltrasound));
      calculationMethod = 'Ultrasound Dating';
    } else {
      throw ArgumentError('At least one calculation method must be provided');
    }
    
    final today = DateTime.now();
    final daysRemaining = calculatedDueDate.difference(today).inDays;
    final currentWeek = lmp != null 
        ? (today.difference(lmp).inDays / 7).floor()
        : null;
    
    return {
      'dueDate': calculatedDueDate,
      'method': calculationMethod,
      'daysRemaining': daysRemaining,
      'weeksRemaining': (daysRemaining / 7).floor(),
      'currentWeek': currentWeek,
      'calculatedOn': DateTime.now(),
    };
  }

  // NEW: Enhanced weight gain recommendations
  static Map<String, dynamic> getWeightGainRecommendations({
    required double prePregnancyBMI,
    required int currentWeek,
    required double currentWeight,
    required double prePregnancyWeight,
  }) {
    // Calculate current weight gain
    final currentGain = currentWeight - prePregnancyWeight;
    
    // Determine BMI category and recommendations
    String category;
    double minTotalGain;
    double maxTotalGain;
    double weeklyGainAfter12Weeks;
    
    if (prePregnancyBMI < 18.5) {
      category = 'Underweight';
      minTotalGain = 12.5;
      maxTotalGain = 18.0;
      weeklyGainAfter12Weeks = 0.51;
    } else if (prePregnancyBMI < 25.0) {
      category = 'Normal Weight';
      minTotalGain = 11.5;
      maxTotalGain = 16.0;
      weeklyGainAfter12Weeks = 0.42;
    } else if (prePregnancyBMI < 30.0) {
      category = 'Overweight';
      minTotalGain = 7.0;
      maxTotalGain = 11.5;
      weeklyGainAfter12Weeks = 0.28;
    } else {
      category = 'Obese';
      minTotalGain = 5.0;
      maxTotalGain = 9.0;
      weeklyGainAfter12Weeks = 0.22;
    }
    
    // Calculate expected gain for current week
    final expectedMinGain = currentWeek <= 12 
        ? (currentWeek * 0.1) // Minimal gain first trimester
        : 1.0 + ((currentWeek - 12) * weeklyGainAfter12Weeks);
    final expectedMaxGain = currentWeek <= 12 
        ? (currentWeek * 0.2)
        : 2.0 + ((currentWeek - 12) * weeklyGainAfter12Weeks);
    
    // Determine status
    String status;
    if (currentGain < expectedMinGain) {
      status = 'Below recommended';
    } else if (currentGain > expectedMaxGain) {
      status = 'Above recommended';
    } else {
      status = 'On track';
    }
    
    return {
      'currentGain': currentGain,
      'category': category,
      'status': status,
      'minTotalGain': minTotalGain,
      'maxTotalGain': maxTotalGain,
      'expectedMinGain': expectedMinGain,
      'expectedMaxGain': expectedMaxGain,
      'weeklyRecommendation': weeklyGainAfter12Weeks,
      'remainingMinGain': (minTotalGain - currentGain).clamp(0.0, double.infinity),
      'remainingMaxGain': (maxTotalGain - currentGain).clamp(0.0, double.infinity),
    };
  }

  // NEW: TTC/Ovulation calculations
  static Map<String, dynamic> calculateOvulation({
    required DateTime lmpDate,
    required int cycleLength,
    required int lutealPhaseLength,
  }) {
    final ovulationDay = lmpDate.add(Duration(days: cycleLength - lutealPhaseLength));
    final fertileWindowStart = ovulationDay.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDay.add(const Duration(days: 1));
    final nextPeriod = lmpDate.add(Duration(days: cycleLength));
    
    return {
      'ovulationDate': ovulationDay,
      'fertileWindowStart': fertileWindowStart,
      'fertileWindowEnd': fertileWindowEnd,
      'nextPeriodDate': nextPeriod,
      'cycleLength': cycleLength,
      'daysUntilOvulation': ovulationDay.difference(DateTime.now()).inDays,
      'isInFertileWindow': _isDateInRange(DateTime.now(), fertileWindowStart, fertileWindowEnd),
      'cyclePhase': _getCurrentCyclePhase(DateTime.now(), lmpDate, ovulationDay, cycleLength),
    };
  }

  // Helper methods
  static Map<String, String> _getBabySizeByWeek(int week) {
    final babySizes = {
      4: {'size': 'Poppy seed', 'length': '2mm'},
      5: {'size': 'Apple seed', 'length': '3mm'},
      6: {'size': 'Lentil', 'length': '5mm'},
      7: {'size': 'Blueberry', 'length': '8mm'},
      8: {'size': 'Kidney bean', 'length': '1.6cm'},
      9: {'size': 'Grape', 'length': '2.3cm'},
      10: {'size': 'Kumquat', 'length': '3.1cm'},
      11: {'size': 'Fig', 'length': '4.1cm'},
      12: {'size': 'Lime', 'length': '5.4cm'},
      13: {'size': 'Pea pod', 'length': '7.4cm'},
      14: {'size': 'Lemon', 'length': '8.7cm'},
      15: {'size': 'Apple', 'length': '10.1cm'},
      16: {'size': 'Avocado', 'length': '11.6cm'},
      20: {'size': 'Banana', 'length': '16.4cm'},
      24: {'size': 'Ear of corn', 'length': '21.3cm'},
      28: {'size': 'Eggplant', 'length': '25.6cm'},
      32: {'size': 'Jicama', 'length': '28.9cm'},
      36: {'size': 'Romaine lettuce', 'length': '32.2cm'},
      40: {'size': 'Small pumpkin', 'length': '35.6cm'},
    };
    
    // Find closest week
    final availableWeeks = babySizes.keys.toList()..sort();
    int closestWeek = availableWeeks.first;
    
    for (final availableWeek in availableWeeks) {
      if (week >= availableWeek) {
        closestWeek = availableWeek;
      } else {
        break;
      }
    }
    
    return babySizes[closestWeek] ?? {'size': 'Growing', 'length': 'Developing'};
  }

  static Map<String, DateTime> _calculateMilestones(DateTime lmpDate) {
    return {
      'firstTrimesterEnd': lmpDate.add(const Duration(days: 84)), // 12 weeks
      'secondTrimesterEnd': lmpDate.add(const Duration(days: 189)), // 27 weeks
      'viabilityDate': lmpDate.add(const Duration(days: 168)), // 24 weeks
      'fullTermStart': lmpDate.add(const Duration(days: 259)), // 37 weeks
      'dueDate': lmpDate.add(const Duration(days: 280)), // 40 weeks
      'postTermStart': lmpDate.add(const Duration(days: 294)), // 42 weeks
    };
  }

  static bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(days: 1))) && 
           date.isBefore(end.add(const Duration(days: 1)));
  }

  static String _getCurrentCyclePhase(DateTime today, DateTime lmp, DateTime ovulation, int cycleLength) {
    final daysSinceLmp = today.difference(lmp).inDays;
    final daysUntilOvulation = ovulation.difference(today).inDays;
    
    if (daysSinceLmp <= 5) {
      return 'Menstrual Phase';
    } else if (daysUntilOvulation > 5) {
      return 'Follicular Phase';
    } else if (daysUntilOvulation >= -1 && daysUntilOvulation <= 1) {
      return 'Ovulation';
    } else {
      return 'Luteal Phase';
    }
  }

  // NEW: Pregnancy risk assessment
  static Map<String, dynamic> assessPregnancyRisk({
    required int maternalAge,
    required List<String> medicalHistory,
    required Map<String, dynamic> vitals,
  }) {
    int riskScore = 0;
    List<String> riskFactors = [];
    
    // Age-based risk
    if (maternalAge < 18) {
      riskScore += 2;
      riskFactors.add('Maternal age under 18');
    } else if (maternalAge > 35) {
      riskScore += 3;
      riskFactors.add('Advanced maternal age (over 35)');
    }
    
    // Medical history risks
    final highRiskConditions = [
      'diabetes', 'hypertension', 'heart disease', 'kidney disease',
      'autoimmune disorder', 'previous pregnancy complications'
    ];
    
    for (final condition in medicalHistory) {
      if (highRiskConditions.contains(condition.toLowerCase())) {
        riskScore += 2;
        riskFactors.add('Medical history: $condition');
      }
    }
    
    // Vital signs assessment
    final systolic = vitals['systolic'] as double?;
    final diastolic = vitals['diastolic'] as double?;
    
    if (systolic != null && diastolic != null) {
      if (systolic >= 140 || diastolic >= 90) {
        riskScore += 3;
        riskFactors.add('High blood pressure');
      }
    }
    
    String riskLevel;
    String recommendation;
    
    if (riskScore <= 2) {
      riskLevel = 'Low Risk';
      recommendation = 'Standard prenatal care recommended';
    } else if (riskScore <= 5) {
      riskLevel = 'Moderate Risk';
      recommendation = 'Enhanced monitoring recommended';
    } else {
      riskLevel = 'High Risk';
      recommendation = 'Specialist consultation required';
    }
    
    return {
      'riskLevel': riskLevel,
      'riskScore': riskScore,
      'riskFactors': riskFactors,
      'recommendation': recommendation,
      'assessmentDate': DateTime.now(),
    };
  }
}
