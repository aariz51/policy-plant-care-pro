// lib/core/utils/share_helper.dart
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static const String appLink = 'https://dub.sh/safemama';
  
  /// Share tool output with the app link
  /// 
  /// [toolName] - Name of the tool (e.g., "Birth Plan", "Hospital Bag Checklist")
  /// [userOutput] - The user's data/output from the tool (optional)
  /// [catchyHook] - Optional hook line to make it more engaging
  static Future<void> shareToolOutput({
    required String toolName,
    String? userOutput,
    String? catchyHook,
  }) async {
    String shareText;
    
    if (userOutput != null && userOutput.isNotEmpty) {
      // User has output - share it with app link
      final hook = catchyHook ?? '✨ Created with SafeMama - Your Pregnancy Companion!';
      shareText = '''
$hook

$userOutput

📱 Get $toolName and more pregnancy tools:
$appLink

#SafeMama #Pregnancy #MotherhoodJourney
''';
    } else {
      // No output yet - share catchy hook and app link
      final hook = catchyHook ?? '🤰 Preparing for your little one? Check out SafeMama!';
      shareText = '''
$hook

Discover amazing pregnancy tools like $toolName and more to support your journey to motherhood.

Download SafeMama now:
$appLink

#SafeMama #Pregnancy #PregnancyTools
''';
    }
    
    try {
      await Share.share(
        shareText,
        subject: '$toolName - SafeMama',
      );
    } catch (e) {
      print('[ShareHelper] Error sharing: $e');
      rethrow;
    }
  }
  
  /// Share Birth Plan with formatted output
  static Future<void> shareBirthPlan(Map<String, dynamic> planData) async {
    if (planData.isEmpty) {
      await shareToolOutput(
        toolName: 'Birth Plan Creator',
        catchyHook: '📋 Planning your perfect birth experience?',
      );
      return;
    }
    
    final StringBuffer output = StringBuffer();
    output.writeln('📋 My Birth Plan - SafeMama\n');
    
    // Labor Preferences
    if (planData.containsKey('pain_management') && planData['pain_management'] != '') {
      output.writeln('💊 Pain Management: ${planData['pain_management']}');
    }
    if (planData.containsKey('movement') && planData['movement'] != '') {
      output.writeln('🚶 Movement & Positions: ${planData['movement']}');
    }
    if (planData.containsKey('environment') && planData['environment'] != '') {
      output.writeln('🕯️ Environment: ${planData['environment']}');
    }
    
    // Delivery Preferences
    if (planData.containsKey('position') && planData['position'] != '') {
      output.writeln('\n🤱 Delivery Position: ${planData['position']}');
    }
    if (planData.containsKey('support') && planData['support'] != '') {
      output.writeln('👨‍👩‍👧 Support People: ${planData['support']}');
    }
    if (planData.containsKey('cutting') && planData['cutting'] != '') {
      output.writeln('✂️ Cord Cutting: ${planData['cutting']}');
    }
    
    // Postpartum Preferences
    if (planData.containsKey('feeding') && planData['feeding'] != '') {
      output.writeln('\n🍼 Feeding Plan: ${planData['feeding']}');
    }
    if (planData.containsKey('rooming') && planData['rooming'] != '') {
      output.writeln('🛏️ Rooming-In: ${planData['rooming']}');
    }
    
    // Special Considerations
    if (planData.containsKey('medical') && planData['medical'] != '') {
      output.writeln('\n⚕️ Medical History: ${planData['medical']}');
    }
    if (planData.containsKey('cultural') && planData['cultural'] != '') {
      output.writeln('🙏 Cultural Preferences: ${planData['cultural']}');
    }
    
    await shareToolOutput(
      toolName: 'Birth Plan Creator',
      userOutput: output.toString(),
      catchyHook: '📋 Here\'s my birth plan created with SafeMama!',
    );
  }
  
  /// Share Hospital Bag Checklist progress
  static Future<void> shareHospitalBag({
    required int completedItems,
    required int totalItems,
  }) async {
    final progressPercentage = totalItems > 0 
        ? ((completedItems / totalItems) * 100).toStringAsFixed(0) 
        : '0';
    
    final output = '''
🎒 Hospital Bag Checklist Progress

✅ Packed: $completedItems/$totalItems items ($progressPercentage%)
${completedItems == totalItems ? '🎉 All set for the big day!' : '📝 Still packing...'}
''';
    
    await shareToolOutput(
      toolName: 'Hospital Bag Checklist',
      userOutput: output,
      catchyHook: '🤰 Getting ready for hospital with SafeMama!',
    );
  }
  
  /// Share Postpartum Tracker summary
  static Future<void> sharePostpartumTracker({
    required int daysPostpartum,
    required int entriesCount,
    required int milestonesCount,
  }) async {
    final output = '''
🌸 Postpartum Journey Tracker

📅 Days Postpartum: $daysPostpartum
📝 Logged Entries: $entriesCount
🎯 Milestones Achieved: $milestonesCount

${daysPostpartum > 0 ? '💪 Tracking my recovery journey!' : '🆕 Just started tracking!'}
''';
    
    await shareToolOutput(
      toolName: 'Postpartum Tracker',
      userOutput: output,
      catchyHook: '🌸 Tracking my postpartum recovery with SafeMama!',
    );
  }
  
  /// Share Weight Gain Tracker progress
  static Future<void> shareWeightGainTracker({
    required double currentWeight,
    required double prePregnancyWeight,
    required int currentWeek,
    required String bmiCategory,
  }) async {
    final weightGain = (currentWeight - prePregnancyWeight).toStringAsFixed(1);
    
    final output = '''
⚖️ Pregnancy Weight Tracking

📊 Week: $currentWeek
📈 Weight Gain: $weightGain kg
🎯 Category: $bmiCategory
💪 Current: ${currentWeight.toStringAsFixed(1)} kg
''';
    
    await shareToolOutput(
      toolName: 'Weight Gain Tracker',
      userOutput: output,
      catchyHook: '📊 Tracking my healthy pregnancy with SafeMama!',
    );
  }
  
  /// Share Contraction Timer analysis
  static Future<void> shareContractionTimer({
    required int contractionsCount,
    required String averageInterval,
  }) async {
    final output = '''
⏱️ Contraction Timer

📊 Contractions Tracked: $contractionsCount
⏰ Average Interval: $averageInterval

${contractionsCount >= 5 ? '⚠️ Consider contacting your healthcare provider!' : '📝 Tracking contractions...'}
''';
    
    await shareToolOutput(
      toolName: 'Contraction Timer',
      userOutput: output,
      catchyHook: '⏱️ Tracking labor progress with SafeMama!',
    );
  }
  
  /// Share Vaccine Tracker
  static Future<void> shareVaccineTracker({
    required int completedVaccines,
    required int totalVaccines,
  }) async {
    final progress = totalVaccines > 0 
        ? ((completedVaccines / totalVaccines) * 100).toStringAsFixed(0)
        : '0';
    
    final output = '''
💉 Vaccine Tracker

✅ Completed: $completedVaccines/$totalVaccines vaccines ($progress%)
${completedVaccines == totalVaccines ? '🎉 All vaccines completed!' : '📝 Keeping track of immunizations...'}
''';
    
    await shareToolOutput(
      toolName: 'Vaccine Tracker',
      userOutput: output,
      catchyHook: '💉 Staying protected with SafeMama!',
    );
  }
  
  /// Share Kick Counter
  static Future<void> shareKickCounter({
    required int kicksCount,
    required String duration,
  }) async {
    final output = '''
👶 Kick Counter Session

👣 Total Kicks: $kicksCount
⏱️ Duration: $duration

${kicksCount >= 10 ? '✅ Great! Baby is active!' : '📝 Tracking baby\'s movements...'}
''';
    
    await shareToolOutput(
      toolName: 'Kick Counter',
      userOutput: output,
      catchyHook: '👶 Monitoring my baby\'s movements with SafeMama!',
    );
  }
  
  /// Share LMP Calculator results
  static Future<void> shareLMPCalculator({
    required String lmpDate,
    required String dueDate,
    required int currentWeek,
  }) async {
    final output = '''
📅 LMP Calculator Results

📆 Last Period: $lmpDate
🎯 Due Date: $dueDate
📊 Current Week: $currentWeek weeks

💪 Tracking my pregnancy journey!
''';
    
    await shareToolOutput(
      toolName: 'LMP Calculator',
      userOutput: output,
      catchyHook: '📅 Calculated my due date with SafeMama!',
    );
  }
  
  /// Share Due Date Calculator results
  static Future<void> shareDueDateCalculator({
    required String dueDate,
    required int weeksPregnant,
    required int daysRemaining,
  }) async {
    final output = '''
🎯 Due Date Calculator Results

📅 Due Date: $dueDate
📊 Weeks Pregnant: $weeksPregnant weeks
⏰ Days Remaining: $daysRemaining days

${daysRemaining < 30 ? '🎉 Almost there!' : '💪 Counting down the days!'}
''';
    
    await shareToolOutput(
      toolName: 'Due Date Calculator',
      userOutput: output,
      catchyHook: '🎯 Counting down to meet my baby with SafeMama!',
    );
  }
  
  /// Share TTC Tracker
  static Future<void> shareTTCTracker({
    required int cycleDay,
    required String fertilityStatus,
    required int cyclesTracked,
  }) async {
    final output = '''
🌸 TTC Tracker Progress

📅 Cycle Day: $cycleDay
💫 Status: $fertilityStatus
📊 Cycles Tracked: $cyclesTracked

💪 On my journey to motherhood!
''';
    
    await shareToolOutput(
      toolName: 'TTC Tracker',
      userOutput: output,
      catchyHook: '🌸 Tracking my fertility journey with SafeMama!',
    );
  }
  
  /// Share Baby Name Generator results
  static Future<void> shareBabyNameGenerator({
    required List<String> generatedNames,
    required String gender,
  }) async {
    if (generatedNames.isEmpty) {
      await shareToolOutput(
        toolName: 'Baby Name Generator',
        catchyHook: '👶 Finding the perfect name for my baby with SafeMama!',
      );
      return;
    }
    
    final namesText = generatedNames.take(10).join(', ');
    
    final output = '''
👶 Baby Name Ideas ($gender)

✨ Generated Names:
$namesText

🎉 Found some beautiful names for my little one!
''';
    
    await shareToolOutput(
      toolName: 'Baby Name Generator',
      userOutput: output,
      catchyHook: '👶 Discovered amazing baby names with SafeMama!',
    );
  }
}

