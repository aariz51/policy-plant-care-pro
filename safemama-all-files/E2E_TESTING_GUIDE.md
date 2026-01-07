# End-to-End Testing Guide for RevenueCat Sandbox

Complete test scenarios for SafeMama subscription system using RevenueCat sandbox mode.

## Prerequisites

✅ Completed [REVENUECAT_SANDBOX_SETUP.md](./REVENUECAT_SANDBOX_SETUP.md)
✅ Test products created in Google Play Console
✅ License tester accounts added
✅ Backend running with `REVENUECAT_TEST_MODE=true`
✅ Flutter app installed from Play internal test track or built locally

---

## Test Environment Setup

### Before Each Test Session

1. **Start Backend**:
   ```bash
   cd safemama-backend
   npm start
   ```
   Verify logs show: `🧪 RevenueCat TEST MODE enabled`

2. **Install Test App**:
   - Option A: Internal test track on Play Store
   - Option B: Build and install locally: `flutter run --release`

3. **Use Test Google Account**:
   - Must be added as license tester in Play Console
   - Sign in to Play Store with this account on device

4. **Clear Previous State** (if needed):
   - Uninstall app completely
   - Or use Test Mode screen → "Reset to Free Tier"

---

## Test Scenarios

### TEST 1: Fresh Install - Free Tier Verification

**Objective**: Verify free tier limits are enforced correctly

**Steps**:
1. Install app fresh (or reset to free tier)
2. Sign up with new test account
3. Complete onboarding
4. Navigate to Test Mode screen:
   - Settings → Developer Options → Test Mode (if available)
   - Or add temporary button in settings

**Expected Results**:
- Test Mode shows:
  - Environment: `SANDBOX`
  - Active Entitlements: `None`
  - Membership Tier: `free`
- Backend Profile Data:
  - `membership_tier`: `free`
  - `subscription_expires_at`: `null`

**Test Free Tier Limits**:
1. Perform 3 scans successfully
2. Attempt 4th scan → **EXPECT**: Paywall shows "Upgrade to Premium"
3. Try "Ask Expert" 3 times successfully
4. Attempt 4th Ask Expert → **EXPECT**: Paywall
5. Try Document Analysis → **EXPECT**: "Premium feature only" message

✅ **Pass Criteria**: All limits enforced, paywalls shown correctly

---

### TEST 2: Purchase Weekly Test Subscription

**Objective**: Test weekly subscription purchase flow end-to-end

**Steps**:
1. From free tier state, tap Upgrade button
2. Select "Premium Weekly (Test)" plan
3. Complete purchase flow with Google Play test account
   - Should see "This is a test"banner (confirms sandbox mode)
4. Wait for purchase completion

**Watch Backend Logs**:
```
[RevenueCat Sync SANDBOX] Starting sync...
[RevenueCat Sync SANDBOX] Product ID: safemama_test_premium_weekly
[RevenueCat Sync SANDBOX] SUCCESS: User synced to premium_weekly
```

**Navigate to Test Mode Screen**:
**Expected Results**:
- RevenueCat Customer Info:
  - Active Entitlements: `premium`
  - Product ID: `safemama_test_premium_weekly`
  - Expiry: ~7 days from now (or 24 hours if using accelerated testing)
  - Will Renew: `true`
  - Store: `PLAY_STORE`
- Backend Profile Data:
  - `membership_tier`: `premium_weekly`
  - `subscription_platform`: `revenuecat_test` or `google`
  - `subscription_expires_at`: Date in future

✅ **Pass Criteria**: Purchase completes, entitlement active, backend synced

---

### TEST 3: Feature Access - Weekly Tier Quotas

**Objective**: Verify premium weekly tier quotas (20 scans, 5 doc analysis per week)

**Prerequisite**: Active weekly subscription from TEST 2

**Steps**:
1. Navigate to main app (exit Test Mode)
2. Perform product scans:
   - Scan 1-20: Should work without paywall
   - Scan 21: **EXPECT** "You've used all 20 scans for this week" message
3. Test Document Analysis:
   - Upload 1-5 documents: Should analyze successfully
   - Upload 6th document: **EXPECT** "You've used all 5 document analyses for this week"
4. Test AI Pregnancy Tools:
   - All should be accessible (hasPremiumTools = true)
   - Baby Name Generator, Weight Tracker, etc.

**Backend Logs Check**:
- Each feature call should log quota checking
- Logs should show tier = `premium_weekly`

✅ **Pass Criteria**: Weekly quotas enforced correctly, premium tools accessible

---

### TEST 4: Restore Purchases

**Objective**: Test subscription restoration after app reinstall/data clear

**Steps**:
1. While weekly subscription is active, note product ID and expiry
2. Uninstall app completely
3. Reinstall app
4. Sign in with same test account
5. Navigate to subscription/premium screen
6. Tap "Restore Purchases" button

**Expected Results**:
- Loading indicator shows
- Success message: "Purchases restored successfully"
- Navigate to Test Mode:
  - Same entitlements restored
  - Same product ID
  - Same expiry date
- Features immediately unlocked (scans work, premium tools accessible)

**Backend Logs**:
```
[RevenueCat Sync SANDBOX] Starting sync...
[RevenueCat Sync SANDBOX] SUCCESS: User synced to premium_weekly
```

✅ **Pass Criteria**: Subscription fully restored, no data loss

---

### TEST 5: Purchase Monthly Plan (Upgrade)

**Objective**: Test upgrading from weekly to monthly subscription

**Prerequisite**: Active weekly subscription

**Steps**:
1. Navigate to subscription management screen
2. Select "Premium Monthly (Test)" plan
3. Complete purchase
   - Google Play handles proration automatically

**Expected Results**:
- Test Mode shows:
  - Product ID changed to: `safemama_test_premium_monthly`
  - Expiry updated (30 days or accelerated duration)
- Backend Profile:
  - `membership_tier`: `premium_monthly`
  - New quotas: 100 scans, 15 doc analysis per month

**Test New Quotas**:
- Scan limit should now be 100 (not 20)
- Document analysis limit: 15 (not 5)

✅ **Pass Criteria**: Upgrade successful, quotas updated immediately

---

### TEST 6: Purchase Yearly Plan

**Objective**: Test yearly subscription with highest quotas

**Steps**:
1. From any state, purchase "Premium Yearly (Test)"
2. Wait for purchase completion

**Expected Results**:
- Test Mode:
  - Product ID: `safemama_test_premium_yearly`
  - Expiry: 365 days (or accelerated: 30 days)
- Backend:
  - `membership_tier`: `premium_yearly`
- UI should show:
  - Scans: "Unlimited" (enforced as 1000)
  - Document Analysis: 200 per year

**Test Quotas**:
- Perform 50+ scans: All should work
- Perform 20+ document analyses: All should work
- Verify in Test Mode that usage counter increments

✅ **Pass Criteria**: Yearly tier activated with correct high limits

---

### TEST 7: Subscription Expiry Simulation

**Objective**: Test behavior when subscription expires

**Option A: Accelerated Expiry** (Recommended)
1. Use accelerated test subscriptions:
   - Weekly → 1 day duration
   - Wait 24+ hours for expiry

**Option B: Manual Expiry** (Faster)
1. In Test Mode screen, tap "Reset to Free Tier"
   - Or use backend directly: 
     ```bash
     curl -X POST http://localhost:3001/api/internal/test-expire-subscription \
       -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
     ```

**After Expiry**:
1. Refresh Test Mode screen
2. Check entitlements: Should show `None`
3. Check Backend Profile:
   - `membership_tier`: Should auto-downgrade to `free` OR still show old tier with past expiry date
4. Test features:
   - Scan attempt → **EXPECT**: Free tier limit (3 scans)
   - Document analysis → **EXPECT**: "Premium feature only"
   - Premium tools → **EXPECT**: Locked with paywall

✅ **Pass Criteria**: App correctly handles expired subscription, features locked

---

### TEST 8: Backend Sync Verification

**Objective**: Ensure RevenueCat → Backend sync is working correctly

**Steps**:
1. Make any purchase (weekly/monthly/yearly)
2. Watch backend console logs in real-time

**Expected Log Pattern**:
```
[RevenueCat Sync SANDBOX] Starting sync for user abc123, tier: premium_weekly, platform: google
[RevenueCat Sync SANDBOX] Product ID: safemama_test_premium_weekly
[RevenueCat Sync SANDBOX] Updating profile with data: { membership_tier: 'premium_weekly', ... }
[RevenueCat Sync SANDBOX] SUCCESS: User abc123 synced to premium_weekly, expires at 2025-...
```

**Manual Database Check**:
1. Open Supabase dashboard
2. Navigate to `profiles` table
3. Find your test user row
4. Verify fields:
   - `membership_tier` matches purchase
   - `subscription_expires_at` is in future
   - `subscription_platform` = `google` or `revenuecat_test`
   - `last_purchase_product_id` = correct product ID

✅ **Pass Criteria**: Every purchase triggers backend sync successfully

---

### TEST 9: Cancel Subscription (Google Play)

**Objective**: Test cancellation flow through Google Play

**Steps**:
1. While subscription is active, open Google Play Store
2 Navigate to: Menu → Subscriptions
3. Find SafeMama subscription
4. Tap "Cancel subscription"
5. Confirm cancellation

**Expected Results**:
- Subscription remains active until expiry date
- Test Mode shows:
  - Will Renew: `false`
  - Expiry date unchanged
- Features remain accessible until expiry
- After expiry, downgrade to free tier

**RevenueCat Dashboard Check**:
1. Go to RevenueCat dashboard → Customers
2. Find your test user
3. Should show subscription as "cancelled" but still active until expiry

✅ **Pass Criteria**: Cancellation handled correctly, grace period honored

---

### TEST 10: Offline Mode

**Objective**: Ensure app handles offline subscription checks gracefully

**Steps**:
1. With active subscription, enable airplane mode
2. Force close and reopen app
3. Try to use premium features

**Expected Results**:
- RevenueCat uses cached customer info
- Premium features remain accessible
- Test Mode shows last cached data
- No crashes or errors

**Reconnect Internet**:
- App should sync automatically
- Test Mode data refreshes

✅ **Pass Criteria**: App works offline, syncs when reconnected

---

## Test Simulation Endpoints (Backend)

For faster testing without actual Google Play purchases:

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

**Note**: These endpoints are only active when `REVENUECAT_TEST_MODE=true`

---

## Automated Test Checklist

Track your progress through all test scenarios:

- [ ] TEST 1: Fresh install - free tier verification
- [ ] TEST 2: Purchase weekly subscription
- [ ] TEST 3: Weekly tier quota enforcement
- [ ] TEST 4: Restore purchases after reinstall
- [ ] TEST 5: Upgrade to monthly plan
- [ ] TEST 6: Purchase yearly plan
- [ ] TEST 7: Subscription expiry handling
- [ ] TEST 8: Backend sync verification
- [ ] TEST 9: Cancellation through Google Play
- [ ] TEST 10: Offline mode behavior

---

## Common Issues & Solutions

### Purchase doesn't complete
- **Check**: Using license tester account?
- **Check**: Test subscriptions activated in Play Console?
- **Check**: Backend logs for errors
- **Fix**: Wait 2-4 hours after creating products (Google sync delay)

### Entitlements not showing in app
- **Check**: Product added to "premium" entitlement in RevenueCat?
- **Check**: Offering configured with products?
- **Fix**: Call `restorePurchases()` manually

### Backend sync fails
- **Check**: Backend logs show error details
- **Check**: `GOOGLE_APPLICATION_CREDENTIALS` path correct
- **Check**: Service account has Finance permissions
- **Fix**: Verify service account JSON is valid

### Quotas not enforcing
- **Check**: Backend `planLimits.js` has correct limits
- **Check**: Frontend calls backend endpoints for quota checks
- **Fix**: Ensure `membership_tier` in database matches expected tier

---

## Success Criteria Summary

All tests passing means:
✅ Free tier limits enforce correctly (3 scans, 3 Ask Expert)
✅ Each subscription tier (weekly/monthly/yearly) purchases successfully
✅ Quotas enforce per tier (20/100/1000 scans, 5/15/200 doc analysis)
✅ Backend syncs subscription data from RevenueCat
✅ Restore purchases works after app reinstall
✅ Subscription expiry downgrades to free tier
✅ Premium tools lock/unlock based on subscription status
✅ Test purchases appear in RevenueCat SANDBOX (not production customers)

**Once all tests pass, you're ready for production deployment!**

---

## Next Steps After Testing

1. Switch backend to production mode: `REVENUECAT_TEST_MODE=false`
2. Update Flutter app API keys to production (if using separate test keys)
3. Create PRODUCTION subscription products in:
   - RevenueCat (IDs: `safemama_premium_weekly/monthly/yearly`)
   - Google Play Console (same IDs, real prices)
4. Submit app update to Play Store
5. Monitor RevenueCat dashboard for real customer purchases
