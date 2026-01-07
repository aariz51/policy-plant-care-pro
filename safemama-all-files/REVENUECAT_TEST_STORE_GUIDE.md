# RevenueCat Test Store Setup - Quick Guide

## What You Already Have ✅

From your screenshots, I can see you've already set up:

1. ✅ **Test Store** in RevenueCat Dashboard
   - Test Store ID: `app74237aaa96`
   - Public API Key: `test_xucvWgmwlf3r0oeLasmJAbosit`

2. ✅ **Production Apps** in RevenueCat
   - Safemama (App Store): `app39bc5f5a54`
   - Safemama (Play Store): `appd92b4fb47`

3. ✅ **Production Products** in Google Play Console & App Store
   - `safemama_premium_weekly`
   - `safemama_premium_monthly`
   - `safemama_premium_yearly`

---

## How RevenueCat Test Store Works

The **Test Store** is RevenueCat's built-in sandbox for testing. Key benefits:

- ✅ Uses your **SAME** production product IDs (`safemama_premium_weekly`, etc.)
- ✅ No need to create separate test products in Play Console
- ✅ All purchases are simulated - **NO REAL MONEY** charged
- ✅ Works for both iOS and Android with single API key
- ✅ All test transactions show up in RevenueCat dashboard under sandbox

---

## Setup Steps (VERY SIMPLE!)

### Step 1: Code Already Updated ✅

I've already updated your code to use the Test Store:

**`revenuecat_service.dart`:**
```dart
// Test Store API key from your screenshot
static const String _testStoreApiKey = 'test_xucvWgmwlf3r0oeLasmJAbosit';

// In debug builds: Uses Test Store automatically
// In release builds: Uses production keys
static const bool _useTestMode = kDebugMode;
```

### Step 2: Ensure Products are in RevenueCat Dashboard

You need to verify your production products are configured in RevenueCat:

1. Open RevenueCat Dashboard: https://app.revenuecat.com
2. Navigate to **Products** tab
3. Verify these 3 products exist:
   - `safemama_premium_weekly`
   - `safemama_premium_monthly`
   - `safemama_premium_yearly`

4. Navigate to **Entitlements** tab
5. Verify "premium" entitlement exists and contains all 3 products

6. Navigate to **Offerings** tab
7. Verify "default" offering exists and contains all 3 products as packages

> **Note**: If these aren't set up yet, see the detailed section below.

### Step 3: Enable Test Mode on Backend

Update `safemama-backend/.env`:

```env
# Add this line
REVENUECAT_TEST_MODE=true
```

### Step 4: Start Testing!

1. **Build debug version** of your Flutter app:
   ```bash
   cd safemama-done-1
   flutter run --debug
   ```

2. **Open Test Mode Screen** in the app
   - You'll need to add navigation to it from settings
   - File is at: `lib/features/settings/screens/test_mode_screen.dart`

3. **Check Environment**:
   - Should show: **"SANDBOX"** (not "PRODUCTION")
   - This confirms Test Store is active

4. **Navigate to your subscription/paywall screen**

5. **Select any plan** (Weekly/Monthly/Yearly)

6. **Complete the purchase**:
   - RevenueCat Test Store will simulate the purchase
   - No money charged
   - Purchase completes instantly

7. **Verify in Test Mode Screen**:
   - Active Entitlements should show: `premium`
   - Product ID should show: `safemama_premium_weekly` (or monthly/yearly)
   - Backend profile should update with correct tier

---

## Two Ways to Test

### Option 1: Real Test Store Purchase (RECOMMENDED)

This tests the full RevenueCat SDK flow:

1. Navigate to subscription screen in app
2. Tap on a plan (Weekly/Monthly/Yearly)
3. Complete purchase
4. RevenueCat Test Store handles it
5. Entitlements activate automatically
6. Backend syncs automatically

**This is the REAL end-to-end test!**

### Option 2: Backend Simulation (For Quick Testing)

This bypasses RevenueCat SDK entirely, just updates your backend database:

1. Open Test Mode screen
2. Tap **"Backend Test: Weekly Plan"** (or Monthly/Yearly)
3. Backend directly updates your Supabase profile
4. Good for quick quota testing

**Use this for rapid iteration, but Option 1 is the real test.**

---

## Expected Behavior

### In Debug Build (Test Store Active):

- Environment Label: `SANDBOX`
- API Key Used: `test_xucvWgmwlf3r0oeLasmJAbosit` (Test Store)
- Product IDs: `safemama_premium_weekly/monthly/yearly` (production IDs)
- Purchases: Simulated (no money charged)
- Backend Logs: `[RevenueCat Sync SANDBOX]`

### In Release Build (Production):

- Environment Label: `PRODUCTION`
- API Key Used: Platform-specific production keys
- Product IDs: Same (`safemama_premium_weekly/monthly/yearly`)
- Purchases: Real money transactions
- Backend Logs: `[RevenueCat Sync PRODUCTION]`

---

## Verifying Products in RevenueCat Dashboard

If you haven't set up products/entitlements/offerings yet:

### 1. Products

1. Go to RevenueCat Dashboard → **Products**
2. Click **+ New** for each subscription
3. Create these 3 products:

**Product 1: Weekly**
- Identifier (Google): `safemama_premium_weekly`
- Identifier (Apple): `safemama_premium_weekly`
- Type: Subscription
- Duration: 1 week

**Product 2: Monthly**
- Identifier (Google): `safemama_premium_monthly`
- Identifier (Apple): `safemama_premium_monthly`
- Type: Subscription
- Duration: 1 month

**Product 3: Yearly**
- Identifier (Google): `safemama_premium_yearly`
- Identifier (Apple): `safemama_premium_yearly`
- Type: Subscription
- Duration: 1 year

### 2. Entitlements

1. Navigate to **Entitlements** tab
2. Click **+ New Entitlement**
3. Identifier: `premium` (lowercase, exactly this)
4. Click **Attach Products**
5. Select all 3 products created above
6. Save

### 3. Offerings

1. Navigate to **Offerings** tab
2. Click **+ New Offering** (if no "default" offering exists)
3. Identifier: `default`
4. Make this the **Current Offering** (toggle switch ON)
5. Add packages:
   - Click **+ Add Package**
   - Select `safemama_premium_weekly` → Package type: `$rc_weekly`
   - Click **+ Add Package**
   - Select `safemama_premium_monthly` → Package type: `$rc_monthly`
   - Click **+ Add Package**
   - Select `safemama_premium_yearly` → Package type: `$rc_annual`
6. Save

---

## Testing Checklist

### Initial Setup Verification:

- [ ] Products exist in RevenueCat dashboard (weekly/monthly/yearly)
- [ ] "premium" entitlement contains all 3 products
- [ ] "default" offering contains all 3 products
- [ ] Backend `.env` has `REVENUECAT_TEST_MODE=true`
- [ ] Backend is running

### Test Flows:

- [ ] Debug build shows "SANDBOX" in Test Mode screen
- [ ] Can purchase weekly plan (no money charged)
- [ ] Entitlement shows as active after purchase
- [ ] Backend profile updates with `premium_weekly` tier
- [ ] Weekly quotas work (20 scans, 5 doc analysis)
- [ ] Can purchase monthly plan
- [ ] Monthly quotas work (100 scans, 15 doc analysis)
- [ ] Can purchase yearly plan
- [ ] Yearly quotas work (1000 scans, 200 doc analysis)
- [ ] Restore purchases works after app reinstall

---

## Add Navigation to Test Mode Screen

In your settings screen (e.g., `lib/features/settings/screens/settings_screen.dart`), add:

```dart
if (kDebugMode) {
  ListTile(
    leading: Icon(Icons.science, color: Colors.orange),
    title: Text('Test Mode'),
    subtitle: Text('RevenueCat Sandbox Testing'),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TestModeScreen(),
        ),
      );
    },
  ),
}
```

And import at the top:
```dart
import 'package:flutter/foundation.dart'; // for kDebugMode
import '../../../features/settings/screens/test_mode_screen.dart';
```

---

## Troubleshooting

### Products not showing in app:

**Cause**: Offerings not configured in RevenueCat
**Fix**: Complete the "Verifying Products" section above

### "No offerings found":

**Cause**: "default" offering doesn't exist or isn't current
**Fix**: RevenueCat Dashboard → Offerings → Make "default" the current offering

### Purchases not activating entitlements:

**Cause**: Products not attached to "premium" entitlement
**Fix**: RevenueCat Dashboard → Entitlements → Edit "premium" → Attach all 3 products

### Backend not syncing:

**Cause**: `REVENUECAT_TEST_MODE` not set
**Fix**: Add to `.env` file, restart backend

### Test Store charging real money:

**This won't happen!** Test Store is completely simulated. However, if you're using production keys instead of Test Store key, that could charge money. Verify your app is using the Test Store API key in debug mode.

---

## Production Deployment

When ready for production:

1. **Frontend**: Build release version
   ```bash
   flutter build appbundle --release
   ```
   - Release builds automatically use production API keys
   - Test Store is NOT active in release builds

2. **Backend**: Update `.env`
   ```env
   REVENUECAT_TEST_MODE=false
   ```

3. **Deploy**: Submit to Play Store / App Store

---

## Summary

**What's Different from Before:**

❌ **OLD Approach** (what I suggested earlier):
- Create separate test product IDs in Play Console
- Configure accelerated test periods
- Add license testers
- Create separate RevenueCat test products
- Complex setup!

✅ **NEW Approach** (using your Test Store):
- Use existing production product IDs
- Use Test Store API key in debug builds
- Test Store simulates all purchases
- Much simpler!

**The Test Store is RevenueCat's built-in sandbox - use it! It's perfect for your needs.**

---

## Next Steps

1. ✅ Code is already updated
2. ✅ Verify products/entitlements/offerings in RevenueCat dashboard (probably already done)
3. ✅ Add `REVENUECAT_TEST_MODE=true` to backend `.env`
4. ✅ Add navigation to Test Mode screen in settings
5. ✅ Build debug version and test!

You're already 90% there - just need to test it now!
