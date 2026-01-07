# SafeMama - Quick Reference (4 Tiers)

## Active Membership Tiers

| Tier | Price | Period | Product ID |
|------|-------|--------|------------|
| **free** | ₹0 | Forever | - |
| **premium_weekly** | ₹149 | 1 week | `safemama_premium_weekly` |
| **premium_monthly** | ₹499 | 1 month | `safemama_premium_monthly` |
| **premium_yearly** | ₹3,999 | 1 year | `safemama_premium_yearly` |

---

## Feature Limits Quick Table

| Feature | Free | Weekly | Monthly | Yearly |
|---------|------|--------|---------|--------|
| Scans | 3 | 20 | 100 | 1000 |
| Ask Expert | 3 | 10 | 40 | 400 |
| Manual Search | 0 | 10 | 40 | 400 |
| AI Guides | 0 | 3 | 10 | 80 |
| Doc Analysis | 0 | 5 | 15 | 200 |
| Pregnancy Test AI | 0 | 3 | 8 | 40 |

---

## Backend LIMITS Constants

```javascript
const LIMITS = {
    free: { scans: 3, askExpert: 3, guides: 0, manualSearch: 0, documentAnalysis: 0, pregnancyTestAI: 0 },
    premium_weekly: { scans: 20, askExpert: 10, guides: 3, manualSearch: 10, documentAnalysis: 5, pregnancyTestAI: 3 },
    premium_monthly: { scans: 100, askExpert: 40, guides: 10, manualSearch: 40, documentAnalysis: 15, pregnancyTestAI: 8 },
    premium_yearly: { scans: 1000, askExpert: 400, guides: 80, manualSearch: 400, documentAnalysis: 200, pregnancyTestAI: 40 },
    premium: { scans: 100, askExpert: 40, guides: 10, manualSearch: 40, documentAnalysis: 15, pregnancyTestAI: 8 } // Legacy
};
```

---

## Apple IAP Mapping

```javascript
// Case-insensitive keyword detection
if (productIdLower.includes('weekly')) → 'premium_weekly'
if (productIdLower.includes('monthly')) → 'premium_monthly'
if (productIdLower.includes('yearly')) → 'premium_yearly'
else → 'premium_monthly' (legacy fallback)
```

**Accepted Variations:**
- `safemama_premium_weekly` ✅
- `Safemama_premium_weekly` ✅
- `SAFEMAMA_PREMIUM_WEEKLY` ✅

---

## Files Modified (9 total)

### Backend (7)
1. `src/controllers/paymentController.js` - IAP verification
2. `src/routes/product_analysis_routes.js` - Scan limits
3. `src/routes/expert_consultation_routes.js` - Ask expert limits
4. `src/routes/auth_routes.js` - Device limits
5. `server.js` - Document analysis limits
6. `src/routes/pregnancy_tools_routes.js` - Pregnancy test limits
7. `src/routes/config_routes.js` - Plans & features config

### Frontend (2)
8. `lib/core/constants/app_constants.dart` - Pricing & limits
9. `lib/core/models/user_profile.dart` - Premium status checks

---

## API Endpoints

### Subscription Plans
```
GET /api/config/subscription-plans
Returns: { plans: { free, premium_weekly, premium_monthly, premium_yearly } }
```

### Features Config
```
GET /api/config/features
Returns: Feature limits for all 4 tiers
```

### Pregnancy Test AI
```
POST /api/pregnancy-tools/pregnancy-test-ai
Limits: 0 (free), 3 (weekly), 8 (monthly), 40 (yearly)
```

---

## Testing Commands

### Check Config
```bash
curl https://your-api.com/api/config/subscription-plans
curl https://your-api.com/api/config/features
```

### Check Database
```sql
SELECT membership_tier, COUNT(*) 
FROM profiles 
GROUP BY membership_tier;
```

### Migrate Old Tiers (Optional)
```sql
UPDATE profiles 
SET membership_tier = 'premium_yearly' 
WHERE membership_tier IN ('premium_9month', 'premium9month');
```

---

## RevenueCat Setup

1. Create products: `safemama_premium_weekly`, `safemama_premium_monthly`, `safemama_premium_yearly`
2. Map to entitlement: `premium_access`
3. Set offering: `default_offering`
4. Link App Store Connect API key

---

## Deployment Checklist

- [ ] Backend deployed with updated LIMITS
- [ ] App Store Connect: 3 products created
- [ ] Google Play Console: 3 products created
- [ ] RevenueCat: Products configured
- [ ] Frontend: New version submitted
- [ ] Documentation: Updated user-facing pages
- [ ] Support: Team briefed on changes
- [ ] Monitoring: Alerts set for IAP failures

---

## Quick Troubleshooting

**Issue:** Product ID not recognized
- Check it contains 'weekly', 'monthly', or 'yearly'
- Verify case-insensitive check in `paymentController.js`

**Issue:** Limits not enforced
- Check LIMITS constant in relevant route file
- Verify tier name matches exactly (underscore format)

**Issue:** Frontend shows wrong limits
- Check `app_constants.dart` has correct values
- Verify `user_profile.dart` tier detection logic

---

## Support Queries

**Check user tier:**
```sql
SELECT id, email, membership_tier, subscription_expires_at 
FROM profiles 
WHERE id = 'user-uuid';
```

**Reset usage counts (testing only):**
```sql
UPDATE profiles 
SET scan_count = 0, 
    ask_expert_count = 0, 
    pregnancy_test_count = 0 
WHERE id = 'user-uuid';
```

---

## Key Changes Summary

✅ Removed `premium_9month` tier completely  
✅ Updated all LIMITS to 3 premium tiers  
✅ Enhanced Apple IAP with case-insensitive mapping  
✅ Updated config endpoints  
✅ Cleaned frontend constants  
✅ **Pregnancy Test Checker: WORKING**  
✅ **Scan Sharing: WORKING**  
✅ **No breaking changes**

---

**Status:** ✅ COMPLETE  
**Date:** December 16, 2025  
**Version:** 4-Tier Structure  
**Backward Compatible:** Yes (legacy support maintained)

