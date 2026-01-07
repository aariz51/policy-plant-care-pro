# Quick Start: RevenueCat Test Store Testing

## TL;DR - What You Need to Do

Based on your screenshots, you already have Test Store set up in RevenueCat. Here's all you need to do:

### 1. Backend Setup (30 seconds)

Add to `safemama-backend/.env`:
```env
REVENUECAT_TEST_MODE=true
```

Then restart backend:
```bash
cd safemama-backend
npm start
```

**Expected log**: `🧪 RevenueCat TEST MODE enabled`

### 2. Frontend Setup (Already Done! ✅)

Your Test Store API key is already in the code:
```dart
// In revenuecat_service.dart
static const String _testStoreApiKey = 'test_xucvWgmwlf3r0oeLasmJAbosit';
```

### 3. Add Navigation to Test Mode Screen

In your settings screen (`lib/features/settings/screens/settings_screen.dart` or similar):

```dart
import 'package:flutter/foundation.dart';
import '../../../features/settings/screens/test_mode_screen.dart';

// In your settings list:
if (kDebugMode) {
  ListTile(
    leading: Icon(Icons.science, color: Colors.orange),
    title: Text('Test Mode'),
    subtitle: Text('RevenueCat Sandbox'),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TestModeScreen()),
    ),
  ),
}
```

### 4. Test It!

```bash
cd safemama-done-1
flutter run --debug
```

Then:
1. Open app → Settings → Test Mode
2. Should see "Environment: SANDBOX"
3. Go to subscription screen
4. Purchase any plan (Weekly/Monthly/Yearly)
5. No money charged - Test Store simulates it!
6. Check Test Mode again → Should show "premium" entitlement active

---

## How It Works

### Debug Builds (Testing):
- Uses Test Store API key: `test_xucvWgmwlf3r0oeLasmJAbosit`
- Environment: **SANDBOX**
- All purchases simulated (NO MONEY)
- Uses production product IDs: `safemama_premium_weekly/monthly/yearly`

### Release Builds (Production):
- Uses production API keys (platform-specific)
- Environment: **PRODUCTION**
- Real money transactions
- Same product IDs: `safemama_premium_weekly/monthly/yearly`

**Key Insight**: You use the SAME product IDs for both testing and production! The Test Store API key makes them simulated.

---

## Verify RevenueCat Dashboard Setup

Quick checklist - make sure these exist:

### Products (3 products):
- `safemama_premium_weekly`
- `safemama_premium_monthly`
- `safemama_premium_yearly`

Navigate to: RevenueCat Dashboard → **Products**

### Entitlements (1 entitlement):
- Name: `premium`
- Attached products: All 3 above

Navigate to: RevenueCat Dashboard → **Entitlements**

### Offerings (1 offering):
- Identifier: `default`
- Current offering: ✅ YES
- Packages: All 3 products (as $rc_weekly, $rc_monthly, $rc_annual)

Navigate to: RevenueCat Dashboard → **Offerings**

**If any of these are missing**, see [`REVENUECAT_TEST_STORE_GUIDE.md`](./REVENUECAT_TEST_STORE_GUIDE.md) for detailed setup.

---

## Test Scenarios

### Test 1: Quick Backend Simulation

1. Open Test Mode screen
2. Tap **"Backend Test: Weekly Plan"**
3. Refresh → Should show `premium_weekly` tier
4. Try scanning products → Should allow 20 scans

### Test 2: Real RevenueCat Flow (RECOMMENDED)

1. Go to subscription/paywall screen
2. Select "Premium Weekly"
3. Complete purchase (Test Store = no charge)
4. Check Test Mode → Should show:
   - Active Entitlements: `premium`
   - Product ID: `safemama_premium_weekly`
   - Will Renew: `true`

### Test 3: Feature Quotas

- Weekly: 20 scans, 5 doc analysis
- Monthly: 100 scans, 15 doc analysis
- Yearly: 1000 scans, 200 doc analysis

Try exceeding limits → Should show paywall

### Test 4: Restore Purchases

1. Uninstall app
2. Reinstall
3. Sign in with same account
4. Test Mode → Tap "Restore/Sync Purchases"
5. Subscription should restore

---

## What Logs to Expect

### Backend Logs (when test purchasing):
```
🧪 RevenueCat TEST MODE enabled - test endpoints available
[RevenueCat Sync SANDBOX] Starting sync for user abc123, tier: premium_weekly
[RevenueCat Sync SANDBOX] Product ID: safemama_premium_weekly
[RevenueCat Sync SANDBOX] SUCCESS: User abc123 synced to premium_weekly
```

### Flutter Logs (when initializing):
```
[RevenueCat SANDBOX] Initializing RevenueCat for user: abc123
[RevenueCat SANDBOX] Using Test Store API key: test_xucvWgmwlf...
[RevenueCat SANDBOX] Test Store allows testing with PRODUCTION product IDs
[RevenueCat SANDBOX] Initialization successful
```

---

## Troubleshooting

**Test Mode shows "PRODUCTION" instead of "SANDBOX":**
- You're running a release build. Use `flutter run --debug`

**No offerings found:**
- Check RevenueCat Dashboard → Offerings → Make "default" current

**Purchases not activating:**
- Check RevenueCat Dashboard → Entitlements → Ensure "premium" contains all products

**Backend not syncing:**
- Check `.env` has `REVENUECAT_TEST_MODE=true`
- Restart backend

---

## Complete Documentation

For detailed information, see:
- **REVENUECAT_TEST_STORE_GUIDE.md** - Full setup guide with RevenueCat dashboard configuration
- **E2E_TESTING_GUIDE.md** - 10 comprehensive test scenarios
- **walkthrough.md** - All code changes explained

---

## You're Ready!

1. ✅ Code updated with Test Store API key
2. ✅ Backend just needs `.env` variable
3. ✅ Add navigation button to Test Mode screen
4. ✅ Build debug version and test

**No need to create separate test products in Google Play Console!**
**No need to configure license testers!**
**The Test Store handles everything!**
