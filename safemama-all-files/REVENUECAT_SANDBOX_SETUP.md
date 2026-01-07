# RevenueCat Sandbox Setup Guide

Complete step-by-step guide for setting up RevenueCat sandbox testing for SafeMama app.

## Prerequisites

- RevenueCat account (free tier is sufficient for testing)
- Google Play Console access with app set up
- SafeMama app integrated with RevenueCat SDK (already done)

---

## Part 1: RevenueCat Dashboard Setup

### Step 1: Access Your RevenueCat Project

1. Go to [https://app.revenuecat.com](https://app.revenuecat.com)
2. Log in to your account
3. Select your SafeMama project (or create one if it doesn't exist)

### Step 2: Configure Test Environment

RevenueCat automatically provides sandbox testing capabilities. You don't need a separate "sandbox project" - purchases made with Google Play test accounts automatically go to sandbox mode.

**Important**: RevenueCat treats all purchases from test accounts as sandbox purchases automatically.

### Step 3: Get Your API Keys

1. Navigate to **Project Settings** → **API Keys**
2. You'll see two sections:
   - **Public SDK keys** (for your app)
   - **Secret keys** (for backend - NOT needed for this integration)

3. Copy your API keys:
   - **Google Play (Android)**: Starts with `goog_`
   - **App Store (iOS)**: Starts with `appl_`

4. **Update your Flutter app**:
   - Open `lib/core/services/revenuecat_service.dart`
   - Replace the production keys:
     ```dart
     static const String _androidApiKey = 'goog_YOUR_ANDROID_KEY_HERE';
     static const String _iosApiKey = 'appl_YOUR_IOS_KEY_HERE';
     ```
   - For testing, you can use the same keys for both test and production
   - Or create a separate app in RevenueCat for testing and use those keys in `_androidTestApiKey` and `_iosTestApiKey`

### Step 4: Create Test Products

1. Go to **Products** tab in RevenueCat dashboard
2. Click **+ New** to add products
3. Create 3 test products with these EXACT IDs:

#### Product 1: Test Weekly Subscription
- **Product identifier (Google)**: `safemama_test_premium_weekly`
- **Product identifier (Apple)**: `safemama_test_premium_weekly`
- **Type**: Subscription
- **Duration**: 1 week (or use 1 day for accelerated testing in Google Play)
- **Description**: "Premium Weekly Test Plan"

#### Product 2: Test Monthly Subscription
- **Product identifier (Google)**: `safemama_test_premium_monthly`
- **Product identifier (Apple)**: `safemama_test_premium_monthly`
- **Type**: Subscription
- **Duration**: 1 month
- **Description**: "Premium Monthly Test Plan"

#### Product 3: Test Yearly Subscription
- **Product identifier (Google)**: `safemama_test_premium_yearly`
- **Product identifier (Apple)**: `safemama_test_premium_yearly`
- **Type**: Subscription
- **Duration**: 1 year
- **Description**: "Premium Yearly Test Plan"

**Note**: These product IDs MUST match exactly. RevenueCat will link them to the actual products you create in Google Play Console (next section).

### Step 5: Configure Entitlements

1. Go to **Entitlements** tab
2. Click **+ New Entitlement**
3. Create an entitlement called **premium** (lowercase)
4. Add all 3 test products to this entitlement:
   - `safemama_test_premium_weekly`
   - `safemama_test_premium_monthly`
   - `safemama_test_premium_yearly`

**Why?** Your Flutter app checks for the "premium" entitlement. All subscription tiers unlock this same entitlement, but the backend knows which tier based on the product ID.

### Step 6: Create an Offering

1. Go to **Offerings** tab
2. Click **+ New Offering**
3. Name it **default** (lowercase - this is important!)
4. Add all 3 test products as packages:
   - Package type: `$rc_weekly`, `$rc_monthly`, `$rc_annual`
   - Or custom package identifiers

**Note**: Your app calls `getOfferings()` and expects a "current" offering. RevenueCat will automatically designate one offering as "current."

### Step 7: (Optional) Set Up Webhooks for Backend Sync

If you want RevenueCat to automatically notify your backend of subscription changes:

1. Go to **Integrations** → **Webhooks**
2. Add your backend URL: `https://your-backend.com/api/payments/webhook/revenuecat` (if you implement this endpoint)
3. For testing, this is optional - the app syncs manually via the sync endpoint

---

## Part 2: Google Play Console Setup

### Step 1: Create Test Subscriptions in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your SafeMama app
3. Navigate to **Monetize** → **Subscriptions**
4. Click **Create subscription** for each of the 3 test tiers

#### Test Product 1: Weekly
- **Product ID**: `safemama_test_premium_weekly`
- **Name**: "Premium Weekly (Test)"
- **Description**: "Access all premium features - Weekly subscription (Testing)"
- **Base plans and offers**: 
  - Create a base plan
  - Billing period: **1 week** (or for faster testing, choose "1 day")
  - Price: ₹149 (or any test price)
  - Free trial: Optional (you can add 3-day trial for testing)

#### Test Product 2: Monthly
- **Product ID**: `safemama_test_premium_monthly`
- **Name**: "Premium Monthly (Test)"
- **Description**: "Access all premium features - Monthly subscription (Testing)"
- **Base plans**:
  - Billing period: **1 month** (or "1 week" for accelerated testing)
  - Price: ₹499

#### Test Product 3: Yearly
- **Product ID**: `safemama_test_premium_yearly`
- **Name**: "Premium Yearly (Test)"
- **Description**: "Access all premium features - Yearly subscription (Testing)"
- **Base plans**:
  - Billing period: **1 year** (or "1 month" for accelerated testing)
  - Price: ₹3999

**Important for Testing**: You can use accelerated billing periods:
- Set weekly plan to 1 day → expires in 24 hours
- Set monthly plan to 1 week → expires in 7 days
- Set yearly plan to 1 month → expires in 30 days

This lets you test subscription expiry without waiting a full year!

### Step 2: Activate Subscriptions

After creating each product:
1. Review the product details
2. Click **Activate** to make it available for testing

### Step 3: Add License Testers

1. Go to **Setup** → **License testing**
2. Under **License testers**, add test Google accounts (email addresses)
3. These accounts can make test purchases without being charged real money

**Recommended**: Add at least 2-3 test accounts for different scenarios.

### Step 4: Link to RevenueCat (if not already done)

RevenueCat needs access to verify Google Play purchases:

1. In Google Play Console, go to **Setup** → **API access**
2. Link a Google Cloud project (if not already linked)
3. Create a service account with "Finance" permissions
4. Download the service account JSON key
5. In RevenueCat dashboard:
   - Go to **Project Settings** → **Integrations**
   - Find **Google Play**
   - Upload the service account JSON
   - Enter your package name: `com.safemama.app` (or your actual package)

---

## Part 3: Backend Configuration (.env)

Update your backend `.env` file with test mode flags:

```env
# RevenueCat Test Mode Configuration
REVENUECAT_TEST_MODE=true
TEST_MODE_BYPASS_VERIFICATION=false

# Google Play Package Name
GOOGLE_PACKAGE_NAME=com.safemama.app

# Existing Google credentials path (already set)
GOOGLE_APPLICATION_CREDENTIALS=./safamama-1eec02dfd205.json
```

- `REVENUECAT_TEST_MODE=true`: Enables test endpoints and logging
- `TEST_MODE_BYPASS_VERIFICATION=false`: Still verify with actual Google Play API even in test mode

---

## Part 4: Flutter App Configuration

### Update RevenueCat Service

The code is already configured! Just make sure:

1. `revenuecat_service.dart` has your API keys filled in
2. Test mode automatically activates in debug builds (`kDebugMode`)

### Access Test Mode Screen

1. Build and install the app (debug build)
2. Navigate to:
   - **Settings** → **Developer Options** → **Test Mode**
   - Or add a navigation button to `test_mode_screen.dart`

---

## Testing Checklist

✅ RevenueCat project created
✅ API keys copied to Flutter app
✅ 3 test products created in RevenueCat (with exact IDs)
✅ "premium" entitlement configured
✅ "default" offering created with all 3 products
✅ 3 test subscriptions created in Google Play Console (with same IDs)
✅ License testers added to Google Play Console
✅ Service account linked between Play Console and RevenueCat
✅ Backend `.env` has REVENUECAT_TEST_MODE=true
✅ Flutter app has API keys configured

---

## Quick Test

1. Install app on device/emulator with test Google account
2. Open app and navigate to Test Mode screen
3. Tap "Test: Weekly Plan" button
4. Check logs - should see:
   ```
   [RevenueCat Sync SANDBOX] Starting sync...
   [RevenueCat Sync SANDBOX] SUCCESS: User synced to premium_weekly
   ```
5. Refresh Test Mode screen - should show active "premium" entitlement

---

## Troubleshooting

**"Product ID not found"**
- Double-check product IDs match exactly in RevenueCat, Google Play, and app constants
- Ensure subscriptions are activated in Google Play Console
- Wait 2-4 hours after creating products (Google Play sync delay)

**"No active entitlements"**
- Check that product is added to "premium" entitlement in RevenueCat
- Ensure offering includes the product
- Verify app is using test Google account (license tester)

**Backend sync fails**
- Check backend logs for errors
- Verify `GOOGLE_APPLICATION_CREDENTIALS` path is correct
- Confirm service account has Finance permissions in Play Console

**Purchases charge real money**
- Ensure you're using a license tester account
- Check that test account is added in Play Console → License testing
- Test accounts see "This is a test" banner during purchase

---

## Next Steps

After setup is complete, proceed to the **E2E Testing Guide** (`E2E_TESTING_GUIDE.md`) to run comprehensive tests of all subscription flows.
