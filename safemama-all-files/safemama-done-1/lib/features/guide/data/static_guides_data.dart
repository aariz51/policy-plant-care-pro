// lib/features/guide/data/static_guides_data.dart
import 'package:safemama/core/models/guide_model.dart';

// --- Static Markdown Content for Guides ---
// You can replace this with more detailed content as needed.

// Trimester 1 Content
const String _t1_nutrition_md = """
# First Trimester Nutrition: The Essentials

During the first trimester, your body is working hard to form your baby’s major organs. Focusing on key nutrients is vital.

## Key Nutrients
- **Folic Acid (Folate):** Crucial for preventing neural tube defects. Find it in leafy greens (spinach), lentils, beans, and fortified cereals.
- **Iron:** Supports your increased blood volume and helps prevent anemia. Good sources include lean red meat, poultry, fish, beans, and iron-fortified cereals.
- **Calcium:** Starts building your baby's bones and teeth. Dairy products, fortified plant milks, and leafy greens are excellent sources.

## Managing Morning Sickness
- Eat small, frequent meals throughout the day.
- Keep bland snacks like crackers by your bed.
- Ginger (tea, candies) can help soothe nausea.
- Stay hydrated with small sips of water.
""";

const String _t1_symptoms_md = """
# Navigating First Trimester Symptoms

The first trimester can be a rollercoaster of new physical and emotional changes due to hormonal shifts.

## Common Symptoms & Tips
- **Fatigue:** Your body is using a tremendous amount of energy. Listen to it and rest when you can.
- **Morning Sickness:** Nausea and vomiting can happen any time of day. See our nutrition guide for dietary tips.
- **Tender Breasts:** This is often one of the first signs of pregnancy. A supportive bra can provide comfort.
- **Frequent Urination:** Your uterus is growing and putting pressure on your bladder. This is normal.
""";

// Trimester 2 Content
const String _t2_exercise_md = """
# Staying Active in the Second Trimester

Many women find the second trimester to be the most comfortable. It's a great time to establish a safe exercise routine.

## Safe Exercises
- **Walking:** An excellent, low-impact cardiovascular workout.
- **Swimming:** Easy on the joints and can help with swelling.
- **Prenatal Yoga:** Improves flexibility, strength, and is great for relaxation.
- **Stationary Cycling:** A safe way to get your heart rate up.

## What to Avoid
- Exercises with a high risk of falling (e.g., skiing, contact sports).
- Activities that involve lying flat on your back for extended periods.
- Overheating. Drink plenty of water and don't exercise in hot, humid conditions.

**Always consult your doctor before starting any new exercise program.**
""";

const String _t2_checkups_md = """
# Your Second Trimester Check-ups

Your prenatal appointments in the second trimester often involve important screenings and monitoring your baby's growth.

## What to Expect
- **Anatomy Scan:** A detailed ultrasound, usually between 18-22 weeks, to check your baby's development from head to toe.
- **Glucose Screening:** A test for gestational diabetes, typically done between 24-28 weeks.
- **Measuring Growth:** Your doctor will measure your fundal height to track the baby's growth.
- **Listening to the Heartbeat:** A magical moment at every appointment!
""";

// Trimester 3 Content
const String _t3_labor_prep_md = """
# Preparing for Labor and Delivery

As you enter the third trimester, it's time to prepare for the big day.

## Know the Signs of Labor
- **Contractions:** Becoming stronger, longer, and closer together.
- **Water Breaking:** A gush or a trickle of amniotic fluid.
- **Loss of Mucus Plug / "Bloody Show":** A sign that your cervix is starting to change.

## What to Pack in Your Hospital Bag
- Comfortable clothes for labor and after delivery.
- Toiletries (toothbrush, lip balm).
- Phone and charger.
- Snacks and drinks.
- An outfit for the baby to wear home.
- Your ID, insurance information, and hospital paperwork.
""";

const String _t3_comfort_md = """
# Finding Comfort in the Third Trimester

The final stretch can bring some discomforts as your baby grows.

## Common Issues & Tips
- **Back Pain:** Practice good posture. Use a maternity support belt. Sleep on your side with pillows for support.
- **Swelling (Edema):** Elevate your feet when possible. Avoid standing for long periods. Stay hydrated.
- **Heartburn:** Eat small meals. Avoid spicy or greasy foods. Don't lie down right after eating.
- **Shortness of Breath:** Your growing uterus is pressing on your diaphragm. This is normal.

**Contact your doctor if you experience sudden or severe swelling.**
""";


// --- Data Provider Function ---

/// Returns a list of static, pre-defined guides for a specific trimester.
List<Guide> getStaticGuidesForTrimester(int trimester) {
  final now = DateTime.now(); // Use current time for creation date.
  final List<Guide> allStaticGuides = [
    // Trimester 1 Guides
    Guide(
      id: 'static_t1_nutri',
      createdAt: now,
      title: "First Trimester Nutrition",
      contentMarkdown: _t1_nutrition_md,
      category: "Nutrition",
      targetTrimesters: [1],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Learn about key nutrients and managing morning sickness in your first trimester."
    ),
    Guide(
      id: 'static_t1_symptoms',
      createdAt: now,
      title: "Navigating Early Symptoms",
      contentMarkdown: _t1_symptoms_md,
      category: "Wellbeing",
      targetTrimesters: [1],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Understand common first trimester symptoms like fatigue and what to expect."
    ),
    // Trimester 2 Guides
    Guide(
      id: 'static_t2_exercise',
      createdAt: now,
      title: "Safe Exercise in Trimester Two",
      contentMarkdown: _t2_exercise_md,
      category: "Fitness",
      targetTrimesters: [2],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Discover safe and beneficial exercises for the 'honeymoon' phase of pregnancy."
    ),
    Guide(
      id: 'static_t2_checkups',
      createdAt: now,
      title: "What to Expect at Check-ups",
      contentMarkdown: _t2_checkups_md,
      category: "Medical",
      targetTrimesters: [2],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "An overview of important second trimester screenings like the anatomy scan."
    ),
    // Trimester 3 Guides
    Guide(
      id: 'static_t3_labor',
      createdAt: now,
      title: "Preparing for Labor",
      contentMarkdown: _t3_labor_prep_md,
      category: "Preparation",
      targetTrimesters: [3],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Learn the signs of labor and what to pack in your hospital bag."
    ),
    Guide(
      id: 'static_t3_comfort',
      createdAt: now,
      title: "Third Trimester Comfort Tips",
      contentMarkdown: _t3_comfort_md,
      category: "Wellbeing",
      targetTrimesters: [3],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Tips for managing common discomforts like back pain and swelling."
    ),
  ];

  // Return guides that match the target trimester.
  return allStaticGuides.where((guide) {
    return guide.targetTrimesters?.contains(trimester) ?? false;
  }).toList();
}

// ADD THIS NEW FUNCTION AT THE BOTTOM
/// Returns a list of ALL static, pre-defined guides.
List<Guide> getAllStaticGuides() {
  final now = DateTime.now(); // Use current time for creation date.
  
  // This is the same list from your getStaticGuidesForTrimester function,
  // just returned without filtering.
  return [
    // Trimester 1 Guides
    Guide(
      id: 'static_t1_nutri',
      createdAt: now,
      title: "First Trimester Nutrition",
      contentMarkdown: _t1_nutrition_md,
      category: "Nutrition",
      targetTrimesters: [1],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Learn about key nutrients and managing morning sickness in your first trimester."
    ),
    Guide(
      id: 'static_t1_symptoms',
      createdAt: now,
      title: "Navigating Early Symptoms",
      contentMarkdown: _t1_symptoms_md,
      category: "Wellbeing",
      targetTrimesters: [1],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Understand common first trimester symptoms like fatigue and what to expect."
    ),
    // Trimester 2 Guides
    Guide(
      id: 'static_t2_exercise',
      createdAt: now,
      title: "Safe Exercise in Trimester Two",
      contentMarkdown: _t2_exercise_md,
      category: "Fitness",
      targetTrimesters: [2],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Discover safe and beneficial exercises for the 'honeymoon' phase of pregnancy."
    ),
    Guide(
      id: 'static_t2_checkups',
      createdAt: now,
      title: "What to Expect at Check-ups",
      contentMarkdown: _t2_checkups_md,
      category: "Medical",
      targetTrimesters: [2],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "An overview of important second trimester screenings like the anatomy scan."
    ),
    // Trimester 3 Guides
    Guide(
      id: 'static_t3_labor',
      createdAt: now,
      title: "Preparing for Labor",
      contentMarkdown: _t3_labor_prep_md,
      category: "Preparation",
      targetTrimesters: [3],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Learn the signs of labor and what to pack in your hospital bag."
    ),
    Guide(
      id: 'static_t3_comfort',
      createdAt: now,
      title: "Third Trimester Comfort Tips",
      contentMarkdown: _t3_comfort_md,
      category: "Wellbeing",
      targetTrimesters: [3],
      languageCode: 'en',
      isPremiumOnly: false,
      shortSummary: "Tips for managing common discomforts like back pain and swelling."
    ),
  ];
}