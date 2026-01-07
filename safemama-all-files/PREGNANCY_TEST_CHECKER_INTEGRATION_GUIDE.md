# Pregnancy Test Checker - Integration Guide

## Adding to Pregnancy Tools Hub

To make the Pregnancy Test Checker accessible from the Pregnancy Tools Hub screen, add it to the appropriate tools list.

### File to Modify
`safemama-done-1/lib/features/pregnancy_tools/screens/pregnancy_tools_hub_screen.dart`

### Recommended Location
Add it to the **Preparation** tab (or create a new tab for "Assessment Tools")

### Code to Add

Add this to the `preparationTools` list (around line 90-120):

```dart
{
  'title': 'Pregnancy Test Checker',
  'subtitle': 'AI-powered pregnancy likelihood assessment',
  'icon': Icons.pregnant_woman,
  'color': AppTheme.primaryPurple,
  'route': AppRouter.pregnancyTestCheckerPath,
  'isPremium': true, // Premium only
},
```

### Alternative: Create New "Assessment" Tab

If you want a dedicated tab for assessment tools, add this to the `_tabController` setup:

```dart
final List<Map<String, dynamic>> assessmentTools = [
  {
    'title': 'Pregnancy Test Checker',
    'subtitle': 'AI-powered pregnancy likelihood assessment',
    'icon': Icons.pregnant_woman,
    'color': AppTheme.primaryPurple,
    'route': AppRouter.pregnancyTestCheckerPath,
    'isPremium': true,
  },
];
```

Then add the tab to the TabBar:

```dart
TabBar(
  controller: _tabController,
  tabs: const [
    Tab(text: 'Calculators'),
    Tab(text: 'Monitoring'),
    Tab(text: 'Preparation'),
    Tab(text: 'Assessment'), // NEW TAB
  ],
)
```

And add the TabBarView:

```dart
TabBarView(
  controller: _tabController,
  children: [
    _buildToolsGrid(calculatorTools, isPremium),
    _buildToolsGrid(monitoringTools, isPremium),
    _buildToolsGrid(preparationTools, isPremium),
    _buildToolsGrid(assessmentTools, isPremium), // NEW
  ],
)
```

### Visual Design

The tool card will display:
- **Free Users:** Black/grayscale with "PRO" badge
- **Premium Users:** Purple color with full access
- **Icon:** `Icons.pregnant_woman`
- **Color:** `AppTheme.primaryPurple`

### Usage Flow

1. User taps on "Pregnancy Test Checker" card
2. Screen loads and checks premium status
3. **If Free:** Shows paywall dialog immediately
4. **If Premium:** Shows input form
5. User fills out form and submits
6. AI analyzes data and shows results
7. Results include usage counter (e.g., "5/8 used this month")

### Screenshots Location

Consider adding illustrative screenshots or icons:
- Form screen showing input fields
- Results dialog with likelihood assessment
- Premium badge on the hub card

---

## Quick Access Route

You can also make it accessible from other locations:

### 1. From Profile/Settings
Add a quick link in the profile screen under "Premium Tools"

### 2. From Home Screen
Add it to the home screen shortcuts if you want to highlight it

### 3. From Onboarding
Mention it in the premium features showcase during user onboarding

---

## Feature Highlights to Promote

When showcasing this feature:

✅ **AI-Powered Analysis** - Uses OpenAI GPT-4o for intelligent assessment
✅ **Personalized Results** - Based on cycle data, symptoms, and test results
✅ **Compassionate Messaging** - Addresses user anxiety with supportive guidance
✅ **Medical Disclaimers** - Clear educational-only messaging
✅ **Usage Limits** - Transparent counter showing remaining checks
✅ **Urgent Warnings** - Flags symptoms requiring immediate medical attention

---

## Marketing Copy Ideas

### Short Description (for hub card)
"AI-powered pregnancy likelihood assessment"

### Long Description (for feature page)
"Get personalized insights about your pregnancy likelihood based on your menstrual cycle, symptoms, and test results. Our AI analyzes your data to provide educational guidance, next steps, and when to test. This is not a medical diagnosis—always consult your healthcare provider."

### Call-to-Action
"Check Pregnancy Likelihood" or "Analyze My Symptoms"

---

## Common User Questions

**Q: Is this a replacement for a pregnancy test?**
A: No, this is educational only. Users should always take a home pregnancy test and consult their doctor.

**Q: How accurate is the AI?**
A: The AI provides likelihood assessments based on typical cycle patterns and symptoms, but only a medical test can confirm pregnancy.

**Q: What if I have irregular cycles?**
A: The tool still works, but results may be less predictive. The AI will provide appropriate guidance for irregular cycles.

**Q: Can I use this multiple times?**
A: Yes, within your tier limits. Monthly users get 8 uses, yearly users get 40 per year, etc.

**Q: What happens to my data?**
A: All data is stored securely in Supabase with RLS policies. Only you can access your pregnancy test analyses.

---

## Support Team Training

### Key Points for Support
1. This is a **premium-only** feature
2. Free users need to upgrade to access it
3. Usage limits apply per tier
4. All results include medical disclaimers
5. The AI does NOT diagnose—it provides educational likelihood assessments

### Common Issues

**Issue:** "I can't access the pregnancy test checker"
**Solution:** Check if user is on premium tier. If free, explain upgrade benefits.

**Issue:** "I've used all my checks"
**Solution:** Explain the tier limits. Suggest upgrade to higher tier if needed frequently.

**Issue:** "The AI result doesn't match my home test"
**Solution:** Explain this is educational only. Home tests and doctor confirmations are authoritative.

---

## Future Enhancements (Ideas)

- [ ] Save analysis history with ability to track changes over time
- [ ] Add export/share feature for results
- [ ] Integration with fertility tracking tools
- [ ] Push notifications for optimal testing dates
- [ ] Partner with pregnancy test brands for discounts
- [ ] Add educational articles about early pregnancy signs

---

## Analytics to Track

- Number of premium users accessing the feature
- Completion rate (% who fill out form vs abandon)
- Usage patterns (time of day, day of cycle)
- Correlation with premium upgrades (did it drive conversions?)
- Support tickets related to this feature

---

**Status:** Feature is fully implemented and ready to be added to the UI hub.

