# SafeMama - Apple IAP Product ID Mapping Guide

## Overview

This guide documents how Apple In-App Purchase product IDs are mapped to SafeMama membership tiers in the backend.

---

## Product ID Mapping

### Implementation Location
**File:** `safemama-backend/src/controllers/paymentController.js`  
**Function:** `verifyAppleReceipt()`

### Mapping Logic

```javascript
const productIdLower = productId.toLowerCase();

if (productIdLower.includes('weekly')) {
    newMembershipTier = 'premium_weekly';
} else if (productIdLower.includes('yearly')) {
    newMembershipTier = 'premium_yearly';
} else if (productIdLower.includes('monthly')) {
    newMembershipTier = 'premium_monthly';
} else if (productIdLower === 'premium' || productIdLower.includes('premium')) {
    newMembershipTier = 'premium_monthly'; // Legacy fallback
}
```

### Key Features

1. **Case-Insensitive:** Works with any capitalization
2. **Keyword-Based:** Looks for 'weekly', 'monthly', 'yearly' in product ID
3. **Flexible:** Accepts various product ID formats
4. **Legacy Support:** Falls back to `premium_monthly` for old/unrecognized IDs

---

## Supported Product IDs

### Weekly Subscription

**Tier:** `premium_weekly`  
**Price:** ₹149/week

**Accepted Product IDs:**
- ✅ `safemama_premium_weekly`
- ✅ `Safemama_premium_weekly`
- ✅ `SAFEMAMA_PREMIUM_WEEKLY`
- ✅ `safemama_weekly`
- ✅ `weekly_premium`
- ✅ Any ID containing "weekly"

### Monthly Subscription

**Tier:** `premium_monthly`  
**Price:** ₹499/month

**Accepted Product IDs:**
- ✅ `safemama_premium_monthly`
- ✅ `Safemama_premium_monthly`
- ✅ `SAFEMAMA_PREMIUM_MONTHLY`
- ✅ `safemama_monthly`
- ✅ `monthly_premium`
- ✅ Any ID containing "monthly"

### Yearly Subscription

**Tier:** `premium_yearly`  
**Price:** ₹3,999/year

**Accepted Product IDs:**
- ✅ `safemama_premium_yearly`
- ✅ `Safemama_premium_yearly`
- ✅ `SAFEMAMA_PREMIUM_YEARLY`
- ✅ `safemama_yearly`
- ✅ `yearly_premium`
- ✅ Any ID containing "yearly"

### Legacy Products

**Fallback Tier:** `premium_monthly`

**Accepted Product IDs:**
- ✅ `premium`
- ✅ `safemama_premium`
- ✅ Any unrecognized ID containing "premium"

---

## App Store Connect Setup

### Step 1: Create Product IDs

1. Go to App Store Connect
2. Navigate to your app → Features → In-App Purchases
3. Create 3 new **Auto-Renewable Subscriptions**

### Step 2: Configure Products

#### Product 1: Weekly Subscription
- **Product ID:** `safemama_premium_weekly`
- **Reference Name:** SafeMama Premium Weekly
- **Subscription Group:** SafeMama Premium
- **Duration:** 1 week
- **Price:** Tier 5 (₹149)

#### Product 2: Monthly Subscription
- **Product ID:** `safemama_premium_monthly`
- **Reference Name:** SafeMama Premium Monthly
- **Subscription Group:** SafeMama Premium
- **Duration:** 1 month
- **Price:** Tier 14 (₹499)

#### Product 3: Yearly Subscription
- **Product ID:** `safemama_premium_yearly`
- **Reference Name:** SafeMama Premium Yearly
- **Subscription Group:** SafeMama Premium
- **Duration:** 1 year
- **Price:** Tier 47 (₹3,999)

### Step 3: Add Localizations

For each product, add English (India) localization:
- Display Name: "Premium Weekly/Monthly/Yearly"
- Description: Brief feature list

### Step 4: Submit for Review

Submit each product for review with screenshots if required.

---

## RevenueCat Setup

### Step 1: Create Entitlements

1. Go to RevenueCat Dashboard
2. Create entitlement: `premium_access`

### Step 2: Add Products

1. Navigate to Products
2. Add 3 products:
   - `safemama_premium_weekly` → `premium_access`
   - `safemama_premium_monthly` → `premium_access`
   - `safemama_premium_yearly` → `premium_access`

### Step 3: Configure Offerings

Create offering: `default_offering`
- Add all 3 products
- Set `premium_monthly` as default

### Step 4: Set App Store Connect API Key

Link your App Store Connect API key for automatic receipt verification.

---

## Testing

### Test in Sandbox

1. **Create Sandbox Tester:**
   - Go to App Store Connect → Users and Access → Sandbox Testers
   - Create test Apple ID

2. **Test Each Product:**
   ```bash
   # Test weekly subscription
   Product ID: safemama_premium_weekly
   Expected Result: membership_tier = 'premium_weekly'
   
   # Test monthly subscription
   Product ID: safemama_premium_monthly
   Expected Result: membership_tier = 'premium_monthly'
   
   # Test yearly subscription
   Product ID: safemama_premium_yearly
   Expected Result: membership_tier = 'premium_yearly'
   ```

3. **Verify Backend:**
   - Check `profiles` table in Supabase
   - Confirm `membership_tier` is set correctly
   - Verify `subscription_platform` = 'apple'
   - Check `apple_original_transaction_id` is populated

### Test Case Variations

Test that case variations work:
```bash
# These should all map to premium_weekly
- safemama_premium_weekly ✅
- Safemama_premium_weekly ✅
- SAFEMAMA_PREMIUM_WEEKLY ✅
- SafeMama_Premium_Weekly ✅
```

---

## Webhook Configuration (Optional)

### Apple Server Notifications

1. **Configure Webhook URL:**
   ```
   https://your-backend-url.com/api/payments/apple-webhook
   ```

2. **Select Notification Types:**
   - ✅ SUBSCRIBED
   - ✅ DID_RENEW
   - ✅ DID_CHANGE_RENEWAL_STATUS
   - ✅ EXPIRED
   - ✅ DID_FAIL_TO_RENEW

3. **Verify Webhook Signature:**
   Backend already validates using Apple's public keys

---

## Troubleshooting

### Issue: Product ID not mapping correctly

**Solution:**
- Check product ID contains keyword: 'weekly', 'monthly', or 'yearly'
- Verify case-insensitive check is working
- Check backend logs for mapping confirmation

### Issue: Receipt verification fails

**Solution:**
- Verify OPENAI_API_KEY is set (not related but commonly missing)
- Check Apple's public key cache is being fetched
- Verify signedTransactionInfo is valid JWS format

### Issue: User tier not updating

**Solution:**
- Check Supabase connection
- Verify user authentication token is valid
- Check database update query executed successfully

---

## Backend Logs

When verification succeeds, you'll see:
```
[Apple IAP] Using kid-based verification: XXXXXXXXX
[Apple IAP] JWS Header received: {...}
[Apple API Verify] SUCCESS: Transaction verified.
[Apple IAP] Mapped productId "safemama_premium_weekly" to tier "premium_weekly"
```

---

## Frontend Integration

### IapService Usage

The frontend `IapService` calls the backend endpoint:

```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/payments/verify-apple-receipt'),
  headers: {
    'Authorization': 'Bearer $accessToken',
  },
  body: jsonEncode({
    'receiptData': purchaseDetails.verificationData.serverVerificationData,
  }),
);
```

### Product IDs in Frontend

Defined in constants:
```dart
static const String productIdPremiumWeekly = 'safemama_premium_weekly';
static const String productIdPremiumMonthly = 'safemama_premium_monthly';
static const String productIdPremiumYearly = 'safemama_premium_yearly';
```

---

## Security Notes

1. **Never trust client-side verification** - Always verify on backend
2. **Always check signature** - Use Apple's public keys
3. **Store original_transaction_id** - Prevents duplicate purchases
4. **Check expiration dates** - Auto-renewable subscriptions expire
5. **Handle edge cases** - Trial periods, promotional offers, etc.

---

## Summary

✅ Case-insensitive product ID mapping  
✅ Keyword-based detection (weekly/monthly/yearly)  
✅ Legacy support for old product IDs  
✅ Proper receipt verification with Apple  
✅ Database update with tier, platform, transaction ID  
✅ Error handling and logging

**Status: Production Ready**

---

**Last Updated:** December 16, 2025  
**Backend Function:** `verifyAppleReceipt()` in `paymentController.js`  
**Supported Tiers:** free, premium_weekly, premium_monthly, premium_yearly

