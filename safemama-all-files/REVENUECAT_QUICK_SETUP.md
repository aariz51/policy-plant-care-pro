# RevenueCat Integration - Quick Setup Guide

## 🚀 Integration Status: COMPLETE ✅

All code changes have been implemented. Follow this guide to configure and deploy.

## ⚠️ Critical TODO Items Before Production

### 1. Add RevenueCat API Keys (REQUIRED)

**File:** `safemama-done-1/lib/core/services/revenuecat_service.dart`  
**Lines:** 22-23

**Current Code:**
```dart
static const String _iosApiKey = 'TODO_ADD_YOUR_IOS_REVENUECAT_API_KEY_HERE';
static const String _androidApiKey = 'TODO_ADD_YOUR_ANDROID_REVENUECAT_API_KEY_HERE';
```

**Action Required:**
1. Go to https://app.revenuecat.com
2. Navigate to: Project Settings > API Keys
3. Copy your iOS API key and replace `TODO_ADD_YOUR_IOS_REVENUECAT_API_KEY_HERE`
4. Copy your Android API key and replace `TODO_ADD_YOUR_ANDROID_REVENUECAT_API_KEY_HERE`

**Example:**
```dart
static const String _iosApiKey = 'appl_aBcDeFgHiJkLmNoPqRsTuV';
static const String _androidApiKey = 'goog_XyZaBcDeFgHiJkLmNoPqRs';
```

### 2. Create Products in RevenueCat Dashboard

**Product IDs to Create:**
- `safemama_premium_weekly`
- `safemama_premium_monthly`
- `safemama_premium_yearly`

**Steps:**
1. Log into RevenueCat dashboard
2. Go to: Products > + New Product
3. Create each product with matching ID
4. Set subscription duration (weekly/monthly/yearly)

### 3. Connect App Stores to RevenueCat

#### Apple App Store Connect
1. In RevenueCat: Go to Integrations > Apple App Store
2. Upload App Store Connect API Key
3. Enable Server-to-Server notifications

#### Google Play Console
1. In RevenueCat: Go to Integrations > Google Play
2. Upload Google Play Service Account JSON
3. Enable Real-time Developer Notifications

### 4. Optional: Update Supabase Database Schema

Add columns to track RevenueCat data (optional but recommended):

```sql
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS revenuecat_app_user_id TEXT,
ADD COLUMN IF NOT EXISTS last_purchase_product_id TEXT;
```

## 📱 Testing Checklist

### Before Production Deploy

- [ ] Added RevenueCat API keys to `revenuecat_service.dart`
- [ ] Created products in RevenueCat dashboard
- [ ] Connected App Store Connect to RevenueCat
- [ ] Connected Google Play Console to RevenueCat
- [ ] Tested iOS purchase in sandbox mode
- [ ] Tested Android purchase with test account
- [ ] Tested restore purchases on both platforms
- [ ] Verified backend sync endpoint works
- [ ] Checked Supabase database updates correctly
- [ ] Tested with existing subscriber (migration sync)

### Sandbox/Test Environment Testing

#### iOS Testing (Sandbox)
1. Create sandbox test account in App Store Connect
2. Sign out of App Store on test device
3. Launch app, go to upgrade screen
4. Select plan and purchase
5. Use sandbox account when prompted
6. Verify purchase completes successfully
7. Check Supabase database for updated tier
8. Test restore purchases

#### Android Testing (Test Account)
1. Add test account in Google Play Console
2. Install app from internal testing track
3. Go to upgrade screen
4. Select plan and purchase
5. Verify purchase completes successfully
6. Check Supabase database for updated tier
7. Test restore purchases

## 🔧 Build and Deploy

### Flutter App

```bash
# Install dependencies
cd safemama-done-1
flutter pub get

# Build iOS
flutter build ios --release

# Build Android
flutter build appbundle --release
```

### Backend

No backend changes needed - the endpoint is already deployed.

## 📊 Monitoring After Deploy

### RevenueCat Dashboard
- Monitor active subscriptions
- Check subscription events (new, renewal, cancellation)
- Review revenue analytics
- Monitor integration health

### Backend Logs
Check for sync errors:
```
[RevenueCat Sync] Starting sync for user...
[RevenueCat Sync] SUCCESS: User upgraded to...
```

### Supabase Database
Verify profiles table updates:
- `membership_tier` updates to premium_weekly/monthly/yearly
- `subscription_expires_at` set correctly
- `subscription_platform` set to apple/google/revenuecat
- `revenuecat_app_user_id` populated

## 🆘 Troubleshooting

### Issue: "RevenueCat not initialized"
**Solution:** Check API keys are added to `revenuecat_service.dart`

### Issue: "No products found"
**Solution:** 
1. Verify products created in RevenueCat dashboard
2. Check product IDs match exactly
3. Ensure App Store/Play Store integration is connected

### Issue: "Purchase failed"
**Solution:**
1. Check logs for specific error
2. Verify App Store/Play Store products exist
3. Ensure subscription is available in user's country
4. Check test account setup

### Issue: "Backend sync failed"
**Solution:**
1. Check backend endpoint is accessible
2. Verify user authentication token is valid
3. Check backend logs for errors
4. Ensure Supabase connection is working

## 📚 Key Files Reference

### Flutter App
- **RevenueCat Service:** `lib/core/services/revenuecat_service.dart`
- **Upgrade Screen:** `lib/features/premium/screens/upgrade_screen.dart`
- **User Profile Provider:** `lib/navigation/providers/user_profile_provider.dart`
- **Dependencies:** `pubspec.yaml`

### Backend
- **Sync Endpoint:** `src/controllers/paymentController.js` → `syncRevenueCatPurchase()`
- **Route:** `src/routes/paymentRoutes.js` → `/api/payments/sync-revenuecat-purchase`

## 🎯 Migration Strategy

For existing subscribers:

**First Launch After Update:**
1. User logs in
2. RevenueCat initializes automatically
3. `syncPurchasesForMigration()` runs once
4. Existing subscriptions are imported
5. Backend syncs to Supabase
6. User retains premium access seamlessly

**Tracked via SharedPreferences:**
- Key: `revenuecat_migration_synced`
- Safe to call multiple times
- Won't duplicate syncs

## 🔒 Security Notes

1. **API Keys:** Keep RevenueCat API keys secure
2. **Backend Endpoint:** Uses JWT authentication (already implemented)
3. **Receipt Validation:** Handled server-side by RevenueCat
4. **Webhooks:** Configure webhook secret in RevenueCat dashboard

## 📞 Support

- **RevenueCat Docs:** https://docs.revenuecat.com/
- **Flutter SDK Docs:** https://docs.revenuecat.com/docs/flutter
- **Community:** RevenueCat Community Slack
- **Support:** support@revenuecat.com

---

## ✅ Ready to Deploy?

Once you've completed all items in the **Critical TODO Items** section and passed all tests in the **Testing Checklist**, you're ready to deploy!

**Deployment Order:**
1. ✅ Backend is already deployed (endpoint added)
2. Configure RevenueCat dashboard
3. Build and deploy iOS app
4. Build and deploy Android app
5. Monitor first few purchases closely

**Good luck! 🚀**

