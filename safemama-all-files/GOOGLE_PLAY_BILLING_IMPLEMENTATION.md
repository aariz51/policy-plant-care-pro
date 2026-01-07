# Google Play Billing Integration - Implementation Guide

## Overview

This document describes the implementation of Google Play Billing for Android subscriptions in the SafeMama app. The integration removes the old Dodo payments system and implements native Google Play Store subscriptions alongside the existing Apple IAP functionality.

## What Was Changed

### 1. Android/Flutter Changes

#### Added Dependencies
- **File**: `safemama-done-1/android/app/build.gradle.kts`
- **Change**: Added Google Play Billing Library v6.2.1
```kotlin
implementation("com.android.billingclient:billing:6.2.1")
```

#### Added Permissions
- **File**: `safemama-done-1/android/app/src/main/AndroidManifest.xml`
- **Change**: Added billing permission
```xml
<uses-permission android:name="com.android.vending.BILLING"/>
```

#### New Service: Google Play Billing Wrapper
- **File**: `safemama-done-1/lib/core/services/google_play_billing_service.dart`
- **Purpose**: Wraps Google Play Billing functionality for subscriptions
- **Features**:
  - Product query for three subscription tiers (weekly, monthly, yearly)
  - Purchase flow initiation
  - Purchase verification with backend
  - Restore purchases functionality
  - Error handling and state management

#### Updated Upgrade Screen
- **File**: `safemama-done-1/lib/features/premium/screens/upgrade_screen.dart`
- **Changes**:
  - Imports Google Play Billing service
  - `AndroidUpgradeView` now uses Google Play Billing instead of Dodo payments
  - Displays products from Google Play Store with prices
  - Supports three tiers: weekly (₹149), monthly (₹499), yearly (₹3,999)
  - Handles purchase flow and verification

### 2. Backend Changes

#### New Verification Endpoint
- **File**: `safemama-backend/src/controllers/paymentController.js`
- **New Function**: `verifyGooglePlayPurchase(req, res)`
- **Endpoint**: `POST /api/payments/verify-google-play`
- **Purpose**: Verifies Google Play subscription purchases and updates user membership
- **Flow**:
  1. Receives `productId` and `purchaseToken` from client
  2. Verifies purchase with Google Play Developer API (placeholder implementation)
  3. Maps product ID to membership tier
  4. Updates user's profile with new tier and expiration date
  5. Returns success response with membership details

#### Product ID to Tier Mapping
```javascript
safemama_premium_weekly  → premium_weekly
safemama_premium_monthly → premium_monthly
safemama_premium_yearly  → premium_yearly
```

#### Updated Routes
- **File**: `safemama-backend/src/routes/paymentRoutes.js`
- **New Route**: `POST /verify-google-play` (requires authentication)
- **Disabled Routes**: Dodo payment routes are commented out

#### Dodo Payments Removed
- **Files**: `paymentController.js`, `paymentRoutes.js`
- **Changes**:
  - Dodo payment functions are commented out
  - Placeholder functions return 503 error indicating web payments are disabled
  - Routes are commented out
  - Clear comments indicate only App Store and Play Store subscriptions are supported

## Subscription Tiers

### Product IDs (Must match Google Play Console setup)

| Product ID | Duration | Price | Membership Tier |
|------------|----------|-------|-----------------|
| `safemama_premium_weekly` | 1 week | ₹149 | `premium_weekly` |
| `safemama_premium_monthly` | 1 month | ₹499 | `premium_monthly` |
| `safemama_premium_yearly` | 1 year | ₹3,999 | `premium_yearly` |

### Usage Limits (from AppConstants)

**Free Tier:**
- 3 scans
- 3 Ask Expert queries
- 0 AI guides
- 0 manual searches
- 0 document analysis
- 0 pregnancy test AI

**Premium Weekly:**
- 20 scans/week
- 10 Ask Expert queries/week
- 3 AI guides/week
- 10 manual searches/week
- 5 document analyses/week
- 3 pregnancy test AI/week

**Premium Monthly:**
- 100 scans/month
- 40 Ask Expert queries/month
- 10 AI guides/month
- 40 manual searches/month
- 15 document analyses/month
- 8 pregnancy test AI/month

**Premium Yearly:**
- 1,000 scans/year (practically unlimited)
- 400 Ask Expert queries/year
- 80 AI guides/year
- 400 manual searches/year
- 200 document analyses/year
- 40 pregnancy test AI/year

## Configuration Required for Production

### ⚠️ CRITICAL: Google Play Console Setup

1. **Create Subscription Products in Google Play Console**
   - Go to your app in Google Play Console
   - Navigate to: Monetize > In-app products > Subscriptions
   - Create three subscription products with these exact IDs:
     - `safemama_premium_weekly` - Weekly subscription, ₹149
     - `safemama_premium_monthly` - Monthly subscription, ₹499
     - `safemama_premium_yearly` - Yearly subscription, ₹3,999

2. **Set Up Google Play Developer API**
   - Go to Google Cloud Console
   - Create a new project or use existing one
   - Enable "Google Play Android Developer API"
   - Create a service account
   - Grant the service account "Viewer" role in Google Play Console
   - Download the service account JSON key file

3. **Backend Configuration**
   
   **Environment Variables Required:**
   ```bash
   # Add to your .env file
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
   GOOGLE_PACKAGE_NAME=com.safemama.app
   ```

4. **⚠️ IMPORTANT: Replace Placeholder Verification Code**
   
   The current implementation in `paymentController.js` has a **placeholder verification** that simulates success. You MUST replace it with actual Google Play Developer API calls.

   **Install required package:**
   ```bash
   npm install googleapis
   ```

   **Replace the TODO section in `verifyGooglePlayPurchase` with:**
   ```javascript
   const { google } = require('googleapis');
   
   const auth = new google.auth.GoogleAuth({
       keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
       scopes: ['https://www.googleapis.com/auth/androidpublisher'],
   });
   
   const authClient = await auth.getClient();
   const androidpublisher = google.androidpublisher('v3');
   
   const result = await androidpublisher.purchases.subscriptionsv2.get({
       auth: authClient,
       packageName: packageName,
       token: purchaseToken,
   });
   
   const subscriptionData = result.data;
   const expiryTimeMillis = subscriptionData.lineItems?.[0]?.expiryTime;
   
   // Verify the subscription is active
   if (!expiryTimeMillis || Date.now() > parseInt(expiryTimeMillis)) {
       throw new Error('Subscription is not active or has expired');
   }
   ```

### Testing Instructions

#### Local Testing (Before Publishing)

1. **Test with Google Play Billing Test Tracks**
   - Create an internal testing track in Google Play Console
   - Add test users
   - Upload a signed APK/AAB with version code > production
   - Install the app from Play Store (internal test track)
   - Test purchases (test users won't be charged)

2. **Backend Testing**
   - Ensure backend is accessible from your device
   - Check logs for verification attempts
   - Verify database updates for membership tier and expiration

3. **Check User Profile Update**
   ```sql
   SELECT id, membership_tier, subscription_platform, subscription_expires_at 
   FROM profiles 
   WHERE id = 'user_id';
   ```
   
   Should show:
   - `membership_tier`: `premium_weekly`, `premium_monthly`, or `premium_yearly`
   - `subscription_platform`: `google`
   - `subscription_expires_at`: ISO date string

#### Production Testing

1. Deploy backend with proper Google Play Developer API credentials
2. Publish app to internal/closed testing track
3. Test all three subscription tiers
4. Verify purchase restoration works
5. Test subscription expiration and renewal

## Apple IAP (Unchanged)

The existing Apple IAP functionality remains intact:
- Endpoint: `POST /api/payments/verify-apple-receipt`
- iOS upgrade view uses `IapService`
- Product verification via Apple's JWS tokens
- Supports same three tiers with different product IDs

## Database Schema

No changes required. The existing `profiles` table already supports:
- `membership_tier`: `free`, `premium_weekly`, `premium_monthly`, `premium_yearly`
- `subscription_platform`: `apple`, `google`, or `web`
- `subscription_expires_at`: timestamp
- Feature limits are enforced in application logic based on tier

## Troubleshooting

### Common Issues

1. **"Google Play Store is not available"**
   - Device doesn't have Play Store installed
   - Play Services is outdated
   - Running on emulator without Play Store

2. **"No products found"**
   - Product IDs don't match Google Play Console
   - App is not signed with the same key as Play Console
   - Products are not activated in Play Console

3. **"Purchase verification failed"**
   - Backend Google API credentials not configured
   - Network connectivity issue
   - Purchase token is invalid or expired

4. **Products show wrong prices**
   - Prices are set in Google Play Console
   - Flutter app shows prices from Play Store API
   - Check Google Play Console pricing settings

### Logs to Check

**Flutter/Android:**
```
[GooglePlayBilling] Initializing...
[GooglePlayBilling] Google Play Store available: true
[GooglePlayBilling] Found X products
[GooglePlayBilling] Starting purchase for: safemama_premium_monthly
[GooglePlayBilling] Purchase update: safemama_premium_monthly - Status: purchased
[GooglePlayBilling] Verifying purchase with backend
[GooglePlayBilling] Backend successfully verified purchase
```

**Backend:**
```
[Google Play Verify] Starting verification for user {userId}, product: safemama_premium_monthly
[Google Play Verify] Mapped productId "safemama_premium_monthly" to tier "premium_monthly"
[Google Play Verify] SUCCESS: User {userId} upgraded to premium_monthly, expires at {date}
```

## Security Considerations

1. **Never trust client-side verification** - Always verify purchases on the backend
2. **Protect Google API credentials** - Use environment variables, never commit to git
3. **Validate purchase tokens** - Check expiration and subscription status
4. **Use HTTPS** - All API communication should be encrypted
5. **Implement rate limiting** - Prevent abuse of verification endpoint

## Future Enhancements

1. **Webhook Integration**: Set up Google Play Real-Time Developer Notifications
2. **Grace Periods**: Handle subscription grace periods for payment issues
3. **Proration**: Implement upgrade/downgrade proration logic
4. **Analytics**: Track subscription events and revenue
5. **Subscription Management**: Allow users to manage subscriptions from app

## Support

For issues or questions:
- Check Google Play Billing documentation: https://developer.android.com/google/play/billing
- Review backend logs for verification errors
- Test with internal test track before production

## Changelog

### v1.0.0 - Initial Implementation
- Added Google Play Billing library v6.2.1
- Implemented `GooglePlayBillingService` for Flutter
- Created backend verification endpoint
- Updated Android upgrade UI
- Disabled Dodo payments
- Maintained Apple IAP compatibility

