# RevenueCat Sandbox Testing - Quick Reference

## Test Product IDs Created

### These are the EXACT Product IDs you need to create in RevenueCat + Google Play Console:

```
safemama_test_premium_weekly
safemama_test_premium_monthly
safemama_test_premium_yearly
```

**Important**: Use these EXACT IDs (case-sensitive). They must match in:
- RevenueCat dashboard (Products section)
- Google Play Console (Monetize → Subscriptions)
- Flutter app (already configured in `app_constants.dart`)

---

## How to Create Test Products in RevenueCat

### Step 1: RevenueCat Dashboard → Products

1. Go to https://app.revenuecat.com
2. Select your SafeMama project
3. Navigate to **Products** tab
4. Click **+ New** three times to create 3 products

**Product 1:**
- Identifier (Google): `safemama_test_premium_weekly`
- Identifier (Apple): `safemama_test_premium_weekly`
- Type: Subscription
- Duration: 1 week

**Product 2:**
- Identifier (Google): `safemama_test_premium_monthly`
- Identifier (Apple): `safemama_test_premium_monthly`
- Type: Subscription
- Duration: 1 month

**Product 3:**
- Identifier (Google): `safemama_test_premium_yearly`
- Identifier (Apple): `safemama_test_premium_yearly`
- Type: Subscription
- Duration: 1 year

### Step 2: RevenueCat Dashboard → Entitlements

1. Navigate to **Entitlements** tab
2. Click **+ New Entitlement**
3. Name: `premium` (lowercase, exactly this)
4. Click **Attach Products**
5. Select all 3 test products:
   - ✅ safemama_test_premium_weekly
   - ✅ safemama_test_premium_monthly
   - ✅ safemama_test_premium_yearly
6. Save

### Step 3: RevenueCat Dashboard → Offerings

1. Navigate to **Offerings** tab
2. Click **+ New Offering**
3. Identifier: `default` (lowercase)
4. Make this the current offering (toggle switch)
5. Add all 3 products as packages:
   - Add safemama_test_premium_weekly (Package type: $rc_weekly)
   - Add safemama_test_premium_monthly (Package type: $rc_monthly)
   - Add safemama_test_premium_yearly (Package type: $rc_annual)
6. Save

### Step 4: Get API Keys

1. Navigate to **Project Settings** → **API Keys**
2. Copy your public SDK keys:
   - **Android (Google Play)**: `goog_...`
   - **iOS (App Store)**: `appl_...`
3. Update `revenuecat_service.dart`:
   ```dart
   static const String _androidApiKey = 'YOUR_GOOGLE_KEY_HERE';
   static const String _iosApiKey = 'YOUR_APPLE_KEY_HERE';
   ```

---

## How to Create Test Products in Google Play Console

### Prerequisites
- App must be published to at least Internal Testing track
- Service account linked between Play Console and RevenueCat

### Steps:

1. Go to https://play.google.com/console
2. Select SafeMama app
3. Navigate to **Monetize** → **Subscriptions**
4. Click **Create subscription** three times

**Subscription 1: Weekly**
- Product ID: `safemama_test_premium_weekly` (MUST match RevenueCat exactly)
- Title: "Premium Weekly (Test)"
- Description: "Access all premium features - Weekly subscription (Testing)"
- Base Plan:
  - Billing period: **1 week** (or choose **1 day** for accelerated testing)
  - Price: ₹149 or any test price
  - Renewal: Auto-renewing
- Click **Activate**

**Subscription 2: Monthly**
- Product ID: `safemama_test_premium_monthly`
- Title: "Premium Monthly (Test)"
- Base Plan:
  - Billing period: **1 month** (or **1 week** for accelerated)
  - Price: ₹499
- Click **Activate**

**Subscription 3: Yearly**
- Product ID: `safemama_test_premium_yearly`
- Title: "Premium Yearly (Test)"
- Base Plan:
  - Billing period: **1 year** (or **1 month** for accelerated)
  - Price: ₹3999
- Click **Activate**

### Add Test Accounts

1. Navigate to **Setup** → **License testing**
2. Under "License testers", click **Create list** or **Edit list**
3. Add test Google account email addresses:
   ```
   testaccount1@gmail.com
   testaccount2@gmail.com
   ```
4. Save

**Important**: Only these test accounts can make test purchases without being charged!

---

## Backend Setup

### Update .env File

Add this to `safemama-backend/.env`:

```env
# RevenueCat Test Mode Configuration
REVENUECAT_TEST_MODE=true
```

### Start Backend

```bash
cd safemama-backend
npm start
```

**Expected log output:**
```
🧪 RevenueCat TEST MODE enabled - test endpoints available
   Test Product IDs: safemama_test_premium_weekly/monthly/yearly
📝 Test sync routes mounted at /api/internal/test-*
```

---

## Frontend Setup (Already Done!)

The Flutter app is already configured with:
- Test product ID constants in `app_constants.dart`
- Test mode auto-enables in debug builds
- Test Mode UI screen at `lib/features/settings/screens/test_mode_screen.dart`

### Add Navigation to Test Mode Screen

In your settings screen (e.g., `settings_screen.dart`), add:

```dart
ListTile(
  leading: Icon(Icons.science, color: Colors.orange),
  title: Text('Test Mode'),
  subtitle: Text('RevenueCat Sandbox Testing'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestModeScreen(),
      ),
    );
  },
),
```

---

## Quick Testing Process

### Test 1: Verify Setup

1. Build and install debug version of app
2. Sign in with test Google account (must be license tester)
3. Navigate to Settings → Test Mode
4. **Expected**:
   - Environment shows: `SANDBOX`
   - Active Entitlements: `None`
   - Membership Tier: `free`

### Test 2: Simulate Purchase (No Google Play needed)

1. In Test Mode screen, tap **"Test: Weekly Plan"**
2. Wait 2 seconds
3. **Expected**:
   - Success message appears
   - Refresh screen
   - Active Entitlements: `premium`
   - Product ID: `safemama_test_premium_weekly`
   - Backend Profile shows `membership_tier = premium_weekly`

### Test 3: Verify Features Unlocked

1. Exit Test Mode screen
2. Try scanning a product → Should work (up to 20 times)
3. Try Document Analysis → Should work (up to 5 times)
4. Try Premium Pregnancy Tools → Should be accessible

### Test 4: Real Google Play Purchase

1. From Test Mode, tap **"Reset to Free Tier"**
2. Navigate to subscription/paywall screen in app
3. Select Premium plan
4. Complete purchase with test account
5. **Expected**:
   - Google Play shows "This is a test" banner
   - No money charged
   - Purchase completes
   - RevenueCat receives purchase
   - Backend syncs automatically

---

## Complete Documentation

### Detailed Guides:

1. **REVENUECAT_SANDBOX_SETUP.md**
   - Complete RevenueCat dashboard setup
   - Google Play Console configuration
   - Service account linking
   - Located at: `c:\Users\aariz\safemama-all-files\REVENUECAT_SANDBOX_SETUP.md`

2. **E2E_TESTING_GUIDE.md**
   - 10 comprehensive test scenarios
   - Feature quota testing
   - Restore purchases testing
   - Expiry and cancellation testing
   - Located at: `c:\Users\aariz\safemama-all-files\E2E_TESTING_GUIDE.md`

3. **walkthrough.md**
   - All code changes made
   - File-by-file breakdown
   - Environment variables
   - Troubleshooting guide
   - Located in task artifacts

---

## Test Endpoints (Backend)

When `REVENUECAT_TEST_MODE=true`, these endpoints are available:

### Simulate Purchase
```bash
curl -X POST http://localhost:3001/api/internal/test-sync-revenuecat \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"testProductId": "safemama_test_premium_weekly"}'
```

### Expire Subscription
```bash
curl -X POST http://localhost:3001/api/internal/test-expire-subscription \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Reset to Free
```bash
curl -X POST http://localhost:3001/api/internal/test-reset-to-free \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## Subscription Tier Quotas

| Tier | Scans | Doc Analysis | Ask Expert | Premium Tools |
|------|-------|--------------|------------|---------------|
| **Free** | 3/month | 0 | 3/month | ❌ Locked |
| **Weekly** | 20/week | 5/week | 10/week | ✅ Unlocked |
| **Monthly** | 100/month | 15/month | 40/month | ✅ Unlocked |
| **Yearly** | 1000/year | 200/year | 400/year | ✅ Unlocked |

---

## Troubleshooting

**Products not found in app:**
- Wait 2-4 hours after creating in Play Console (Google sync delay)
- Verify product IDs match EXACTLY
- Check RevenueCat offering includes products

**No entitlements after purchase:**
- Check RevenueCat dashboard: Products added to "premium" entitlement?
- Try "Restore Purchases" in Test Mode
- Check backend logs for sync errors

**Test purchases charge money:**
- Ensure using license tester account
- Check Play Store shows "This is a test" during purchase
- Verify account added in Play Console → License testing

**Backend sync fails:**
- Check logs: Look for `[RevenueCat Sync SANDBOX]` messages
- Verify `GOOGLE_APPLICATION_CREDENTIALS` path correct
- Confirm service account has Finance permissions

---

## Next Steps

1. ✅ Complete Rev enueCat dashboard setup (create 3 products, entitlement, offering)
2. ✅ Create 3 test subscriptions in Google Play Console
3. ✅ Add license tester accounts in Play Console
4. ✅ Update backend `.env` with `REVENUECAT_TEST_MODE=true`
5. ✅ Add navigation to Test Mode screen in Flutter app
6. ✅ Run quick tests to verify setup
7. ✅ Execute full E2E testing guide
8. ✅ For production: Set `REVENUECAT_TEST_MODE=false` and create production products

---

## Support

If you encounter issues:
1. Check backend logs for detailed error messages
2. Review RevenueCat dashboard → Customers to see purchase status
3. Check Supabase `profiles` table for database sync status
4. Refer to troubleshooting sections in detailed guides

**All implementation is complete and ready for testing!**
