# SafeMama Complete Testing Documentation

## Pre-Testing Setup

### Step 1: Start Backend Server

```bash
cd safemama-backend
npm start
```

**Expected Output:**
```
✅ Connected to MongoDB: safemama_app
✅ Connected to Supabase
🚀 Server running on port 3001
[CRON] Cron jobs scheduled:
  - Premium expiry check: Daily at 00:00 IST (WITH RevenueCat verification)
  - Image cleanup: Daily at 02:00 IST
```

### Step 2: Start Admin Panel (Optional)

```bash
cd safemama-admin-panel
npm run dev
```

Access at: http://localhost:3000

### Step 3: Prepare Flutter App

In `lib/core/constants/app_constants.dart`:
```dart
static const String yourBackendBaseUrl = 'http://YOUR_LOCAL_IP:3001';
// Use your computer's IP (e.g., 192.168.1.5), NOT localhost
// Find IP: ipconfig (Windows) or ifconfig (Mac)
```

In `lib/core/services/revenuecat_service.dart`:
```dart
static const bool _useTestMode = true; // Enable for sandbox testing
```

---

## PHASE 1: Authentication Testing

### Test 1.1: New User Registration

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app | Onboarding/Welcome screen appears |
| 2 | Tap "Sign Up" | Registration form appears |
| 3 | Enter email + password | Form validates input |
| 4 | Tap "Create Account" | Success message, verification email sent |
| 5 | Check email | Verification link received |
| 6 | Click verification link | Email verified |
| 7 | Return to app, login | Login successful |

**Check in Supabase:**
- Go to Authentication → Users → New user should appear
- Go to Table Editor → profiles → New profile with `membership_tier: 'free'`

### Test 1.2: User Login

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app | Login screen |
| 2 | Enter valid credentials | Login successful |
| 3 | Enter wrong password | Error: "Invalid credentials" |
| 4 | Enter non-existent email | Error: "User not found" |

### Test 1.3: Password Reset

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Forgot Password" | Email input appears |
| 2 | Enter registered email | Success: "Reset email sent" |
| 3 | Check email | Reset link received |
| 4 | Click link, set new password | Password updated |
| 5 | Login with new password | Login successful |

### Test 1.4: Social Login (if implemented)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Sign in with Google" | Google auth popup |
| 2 | Select Google account | Login successful |
| 3 | Check Supabase | User created with Google provider |

---

## PHASE 2: Free Tier Feature Testing

### Test 2.1: Product Scanning (Free Limit: 3/day)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Scan screen | Camera/upload appears |
| 2 | Scan product #1 | Analysis result shown |
| 3 | Check remaining | "2 scans remaining" |
| 4 | Scan product #2 | Analysis result shown |
| 5 | Scan product #3 | Analysis result shown |
| 6 | Try scan #4 | **BLOCKED** - "Upgrade to Premium" |

**Check in Backend Logs:**
```
[Product Analysis] User xxx scan_count: 3
[Product Analysis] User xxx has reached daily limit
```

**Check in Supabase (profiles table):**
- `scan_count` should show 3

### Test 2.2: Ask Expert (Free Limit: 5/day)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Ask Expert | Chat interface appears |
| 2 | Ask question #1-5 | Responses received |
| 3 | Check count | "0 questions remaining" |
| 4 | Try question #6 | **BLOCKED** - "Upgrade to Premium" |

### Test 2.3: Personalized Guide (Free Limit: 1/week)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Personalized Guide | Guide form appears |
| 2 | Generate guide #1 | Guide created |
| 3 | Try generate #2 | **BLOCKED** - "Wait until next week" |

### Test 2.4: Document Analysis (Free Limit: 2/month)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Document Analysis | Upload interface |
| 2 | Upload document #1 | Analysis complete |
| 3 | Upload document #2 | Analysis complete |
| 4 | Try document #3 | **BLOCKED** - "Upgrade to Premium" |

### Test 2.5: Free Pregnancy Tools

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open Due Date Calculator | Tool works |
| 2 | Open Contraction Timer | Tool works |
| 3 | Open Baby Name Generator | Tool works |

### Test 2.6: Premium Pregnancy Tools (Should Be Locked)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Try Pregnancy Test Analysis | **LOCKED** - Shows paywall |
| 2 | Try Kick Counter | **LOCKED** - Shows paywall |

---

## PHASE 3: Subscription Purchase Testing

### Setup for Sandbox Testing

**iOS:**
1. Settings → App Store → Sandbox Account
2. Sign out of regular Apple ID
3. Use sandbox test account

**Android:**
1. Add your email to Play Console → License Testing
2. Use test card for purchases

### Test 3.1: View Subscription Options

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Upgrade to Premium" | Paywall screen appears |
| 2 | See plans | Weekly ($2.49), Monthly ($3.99), Yearly ($39.99) |
| 3 | Prices match RevenueCat | Correct prices shown |

**Check RevenueCat Dashboard:**
- Go to Product Catalog → Offerings
- Verify products are configured

### Test 3.2: Purchase Monthly Subscription

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Monthly Plan" | App Store/Play Store sheet |
| 2 | Authenticate purchase | Processing... |
| 3 | Purchase completes | Success message |
| 4 | App shows premium status | ✅ Premium badge visible |

**Check RevenueCat Dashboard:**
- Customers → Search your user ID
- Should show active entitlement

**Check Supabase (profiles table):**
```
membership_tier: "premium_monthly"
subscription_expires_at: "2026-02-03T..."
subscription_platform: "apple" or "google"
revenuecat_app_user_id: "user-uuid"
```

**Check Backend Logs:**
```
[RevenueCat Sync] Starting sync for user xxx, tier: premium_monthly
[RevenueCat Sync] SUCCESS: User xxx synced to premium_monthly
```

### Test 3.3: Premium Features Now Unlocked

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Scan products | Unlimited scans work |
| 2 | Ask Expert | Unlimited questions work |
| 3 | Pregnancy Test Analysis | Now accessible |
| 4 | All premium tools | All work |

### Test 3.4: Restore Purchases

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Logout | Logged out |
| 2 | Login again | Login successful |
| 3 | Check premium status | Still premium ✅ |
| 4 | Or tap "Restore Purchases" | Premium restored |

---

## PHASE 4: Subscription Lifecycle Testing

### Test 4.1: Subscription Renewal (Sandbox)

Sandbox subscriptions renew quickly:
- Weekly: 3 minutes
- Monthly: 5 minutes
- Yearly: 1 hour

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Purchase monthly | Active subscription |
| 2 | Wait 5 minutes | Auto-renewal occurs |
| 3 | Check RevenueCat | RENEWAL event logged |
| 4 | Check app | Still has premium |
| 5 | Check Supabase | `subscription_expires_at` updated |

### Test 4.2: Cancel Subscription

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | iOS: Settings → Subscriptions → Cancel | Marked "Won't Renew" |
| 2 | Check RevenueCat | CANCELLATION event |
| 3 | Check app | Still has premium (until expiry) |
| 4 | Wait for expiry | EXPIRATION event |
| 5 | Check app | Premium revoked |

### Test 4.3: Subscription Expiry (Cron Job Test)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Have cancelled subscription | Waiting for expiry |
| 2 | Go to Admin Panel | Login as admin |
| 3 | Click "Run Premium Expiry Check" | Cron job runs |
| 4 | Check logs | Shows verification with RevenueCat |
| 5 | If expired in RevenueCat | User downgraded to free |

**Check Backend Logs:**
```
[CRON] Verifying user xxx@email.com...
[CRON] ❌ User xxx@email.com has NO active subscription in RevenueCat
[CRON] ⬇️ Downgraded xxx@email.com to free tier
```

---

## PHASE 5: Admin Panel Testing

### Test 5.1: Admin Login

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open http://localhost:3000 | Login page |
| 2 | Enter admin credentials | Login successful |
| 3 | Non-admin tries login | Access denied |

**Note:** Set user's `role` to `admin` in Supabase profiles table first.

### Test 5.2: Dashboard Stats

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View dashboard | Stats loaded |
| 2 | Total Users | Matches Supabase count |
| 3 | Premium Users | Correct breakdown |
| 4 | Today's Activity | Shows recent data |

### Test 5.3: Users Management

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Users page | User list appears |
| 2 | Search for user | User found |
| 3 | View user details | Subscription info shown |

### Test 5.4: Sync User with RevenueCat

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Find a premium user | User shown |
| 2 | Click "Sync" | RevenueCat queried |
| 3 | See result | Current status from RevenueCat |
| 4 | Supabase updated | If different, updated |

### Test 5.5: Bulk Sync All Subscriptions

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Sync All Subscriptions" | Process starts |
| 2 | Wait for completion | Results shown |
| 3 | See summary | X synced, Y updated, Z failed |

### Test 5.6: Manually Grant Premium

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Find free user | User shown |
| 2 | Click "Grant Premium" | Form appears |
| 3 | Select tier + reason | Submit |
| 4 | User now premium | Supabase updated |

### Test 5.7: Run Cron Jobs Manually

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Cron Jobs section | Job list shown |
| 2 | Click "Run Premium Expiry" | Job executes |
| 3 | See results | Verified X, Renewed Y, Downgraded Z |

---

## PHASE 6: RevenueCat Dashboard Verification

### Test 6.1: Check Customer Created

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to RevenueCat → Customers | Customer list |
| 2 | Search user's Supabase ID | Customer found |
| 3 | See entitlements | Premium shown if active |

### Test 6.2: Check Events

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Charts → Events | Event list |
| 2 | Filter by user | User's events shown |
| 3 | See purchase history | INITIAL_PURCHASE, RENEWAL, etc. |

### Test 6.3: Check Revenue

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Charts → Revenue | Revenue graph |
| 2 | See MRR | Calculated correctly |
| 3 | See by product | Weekly/Monthly/Yearly breakdown |

---

## PHASE 7: Edge Cases & Error Handling

### Test 7.1: Network Error During Purchase

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Turn off internet | No connection |
| 2 | Try to purchase | Error: "Check connection" |
| 3 | Turn on internet | Can retry |

### Test 7.2: Backend Sync Fails But Purchase Succeeds

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Stop backend | Backend down |
| 2 | Make purchase | Purchase succeeds (App Store) |
| 3 | App shows warning | "Sync failed, contact support" |
| 4 | Start backend | Backend up |
| 5 | User can restore | "Restore Purchases" works |

### Test 7.3: User Not in RevenueCat Yet

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check old user (Phase 1) | No RevenueCat data |
| 2 | User opens updated app | Migration sync runs |
| 3 | Check RevenueCat | User now exists |

---

## Quick Reference: What to Check Where

| Check This | Where to Look |
|------------|---------------|
| User created | Supabase → Auth → Users |
| Profile exists | Supabase → profiles table |
| Membership tier | Supabase → profiles.membership_tier |
| Subscription expiry | Supabase → profiles.subscription_expires_at |
| Feature usage counts | Supabase → profiles.scan_count, etc. |
| RevenueCat sync | RevenueCat Dashboard → Customers |
| Purchase events | RevenueCat Dashboard → Events |
| Backend logs | Terminal running `npm start` |
| Cron job logs | Admin Panel → Cron Logs |

---

## Troubleshooting Common Issues

### Issue: "RevenueCat not initialized"
**Fix:** Check `_useTestMode` setting and API keys in `revenuecat_service.dart`

### Issue: Purchase succeeds but Supabase not updated
**Fix:** Check backend is running, check API URL in Flutter app constants

### Issue: User has premium in RevenueCat but not in app
**Fix:** Use "Restore Purchases" or Admin Panel → Sync User

### Issue: Cron job not verifying correctly
**Fix:** Check `REVENUECAT_SECRET_API_KEY` is set in backend .env

### Issue: Admin panel shows "Forbidden"
**Fix:** Set user's `role` to `admin` in Supabase profiles table
