# Google Play Billing - Production Setup Checklist

## Before Going to Production

### ✅ Google Play Console Setup

- [ ] Create app listing in Google Play Console (if not already done)
- [ ] Set up subscription products with these exact IDs:
  - [ ] `safemama_premium_weekly` - Weekly, ₹149
  - [ ] `safemama_premium_monthly` - Monthly, ₹499
  - [ ] `safemama_premium_yearly` - Yearly, ₹3,999
- [ ] Activate all subscription products
- [ ] Configure subscription benefits and terms
- [ ] Set up tax and pricing for all regions

### ✅ Google Cloud Console Setup

- [ ] Create or select a Google Cloud project
- [ ] Enable "Google Play Android Developer API"
- [ ] Create a service account with these permissions:
  - [ ] Project Viewer
  - [ ] Link service account to Google Play Console
- [ ] Download service account JSON key file
- [ ] Store JSON key file securely on backend server

### ✅ Backend Configuration

- [ ] Install required npm package: `npm install googleapis`
- [ ] Set environment variables:
  ```bash
  GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
  GOOGLE_PACKAGE_NAME=com.safemama.app
  ```
- [ ] Replace placeholder verification code in `paymentController.js`
  - [ ] Remove the WARNING comment and simulated verification
  - [ ] Add actual Google Play Developer API calls
  - [ ] Test verification with real purchase tokens
- [ ] Deploy backend with new environment variables
- [ ] Verify backend can access Google Play Developer API

### ✅ Flutter/Android App Configuration

- [ ] Verify `applicationId` in `build.gradle.kts` matches Play Console
  - Should be: `com.safemama.app`
- [ ] Sign app with production keystore
- [ ] Build release APK/AAB
- [ ] Upload to Google Play Console internal test track
- [ ] Add test users to internal test track

### ✅ Testing Phase

- [ ] Install app from internal test track (not sideload)
- [ ] Verify Play Store is available on test device
- [ ] Test subscription product loading
  - [ ] All three products should appear with correct prices
  - [ ] Prices should match Google Play Console settings
- [ ] Test purchase flow for each tier:
  - [ ] Weekly subscription
  - [ ] Monthly subscription
  - [ ] Yearly subscription
- [ ] Verify backend receives and processes purchases:
  - [ ] Check backend logs for verification success
  - [ ] Query database to confirm membership tier update
  - [ ] Verify `subscription_platform` is set to `google`
  - [ ] Confirm `subscription_expires_at` is correct
- [ ] Test restore purchases functionality
- [ ] Test subscription features and limits
- [ ] Test subscription expiration (if possible with short test period)

### ✅ Database Verification

After a test purchase, verify the database:

```sql
SELECT 
  id, 
  email,
  membership_tier, 
  subscription_platform, 
  subscription_expires_at,
  updated_at
FROM profiles 
WHERE id = 'test_user_id';
```

Expected values:
- `membership_tier`: `premium_weekly`, `premium_monthly`, or `premium_yearly`
- `subscription_platform`: `google`
- `subscription_expires_at`: Future date matching subscription period

### ✅ Pre-Production Checklist

- [ ] Remove all test/debug code
- [ ] Verify all TODO comments are addressed
- [ ] Update backend production URL in app constants
- [ ] Enable ProGuard/R8 for release builds (if desired)
- [ ] Test on multiple Android versions (minimum API 23)
- [ ] Test on different device manufacturers
- [ ] Verify app works with poor network connectivity
- [ ] Check error messages are user-friendly

### ✅ Apple IAP Verification

Ensure Apple IAP still works (should be unchanged):
- [ ] Test iOS upgrade flow
- [ ] Verify Apple purchase verification endpoint works
- [ ] Confirm iOS users can purchase subscriptions
- [ ] Test iOS restore purchases

### ✅ Documentation

- [ ] Update user-facing documentation about subscriptions
- [ ] Create internal documentation for support team
- [ ] Document troubleshooting steps
- [ ] Update privacy policy (if needed for billing data)

### ✅ Production Deployment

- [ ] Deploy backend to production with proper credentials
- [ ] Upload release APK/AAB to Google Play Console
- [ ] Move app to closed testing or open testing
- [ ] Monitor backend logs for any errors
- [ ] Monitor Google Play Console for reports
- [ ] Set up alerts for failed purchase verifications

### ✅ Post-Launch Monitoring

- [ ] Monitor subscription purchase success rate
- [ ] Track verification failures
- [ ] Monitor user feedback
- [ ] Check for subscription cancellations
- [ ] Verify recurring billing works correctly
- [ ] Set up analytics for subscription events

## Common Gotchas

1. **Product IDs MUST match exactly** - Case-sensitive, no typos
2. **App must be signed** - Debug keystore won't work with Play Billing
3. **Install from Play Store** - Sideloaded APKs can't make purchases
4. **Test users required** - Regular users will be charged real money
5. **Service account permissions** - Must be linked in Play Console
6. **Backend accessibility** - App must be able to reach your backend
7. **Purchase tokens expire** - Don't store and reuse old tokens

## Support Resources

- **Google Play Billing Docs**: https://developer.android.com/google/play/billing
- **Google Play Developer API**: https://developers.google.com/android-publisher
- **in_app_purchase Flutter Plugin**: https://pub.dev/packages/in_app_purchase
- **SafeMama Backend Logs**: Check `[Google Play Verify]` log prefix

## Rollback Plan

If issues arise in production:

1. **Immediate**: Comment out the route in `paymentRoutes.js`
2. **Short-term**: Return placeholder error message
3. **Long-term**: Fix issues in test environment, redeploy

The Dodo payments code is commented out but can be quickly re-enabled if needed, though this is not recommended as it's being deprecated.

---

**Last Updated**: December 2025
**Implementation Version**: 1.0.0

