# SafeMama Subscription System - Key Code Snippets

This document shows the key code snippets for the fully functional subscription system as requested.

---

## 1. Purchase Callback - Maps Product IDs to Tiers and Updates Supabase

### Backend: Google Play Verification (`safemama-backend/src/controllers/paymentController.js`)

```javascript
/**
 * Verifies Google Play purchase and updates user's membership tier
 * Called by Flutter after successful purchase
 */
async function verifyGooglePlayPurchase(req, res) {
    const { productId, purchaseToken } = req.body;
    const userId = req.user.id;

    if (!productId || !purchaseToken) {
        return res.status(400).json({ 
            success: false, 
            error: 'Missing required fields: productId and purchaseToken' 
        });
    }

    console.log(`[Google Play Verify] Starting verification for user ${userId}, product: ${productId}`);

    try {
        const packageName = process.env.GOOGLE_PACKAGE_NAME || 'com.safemama.app';

        // Verify with Google Play Developer API
        const verificationResult = await verifyGooglePlaySubscription({
            packageName,
            productId,
            purchaseToken
        });

        if (!verificationResult.isValid) {
            console.log(`[Google Play Verify] FAILURE: ${verificationResult.error}`);
            return res.status(400).json({ 
                success: false, 
                error: verificationResult.error 
            });
        }

        const expiryTimeMillis = verificationResult.expiryTimeMillis;
        
        // ========================================
        // MAP GOOGLE PLAY PRODUCT IDS TO TIERS
        // ========================================
        let membershipTier = 'premium_monthly'; // default fallback
        
        if (productId === 'safemama_premium_weekly') {
            membershipTier = 'premium_weekly';
        } else if (productId === 'safemama_premium_monthly') {
            membershipTier = 'premium_monthly';
        } else if (productId === 'safemama_premium_yearly') {
            membershipTier = 'premium_yearly';
        } else {
            console.log(`[Google Play Verify] WARNING: Unknown product ID "${productId}". Defaulting to premium_monthly.`);
        }

        console.log(`[Google Play Verify] Mapped productId "${productId}" to tier "${membershipTier}"`);

        const subscriptionExpiresAt = new Date(expiryTimeMillis).toISOString();

        // ========================================
        // UPDATE USER'S PROFILE IN SUPABASE
        // ========================================
        const { error: updateError } = await supabaseAdminClient
            .from('profiles')
            .update({
                membership_tier: membershipTier,           // ← Grant membership
                subscription_platform: 'google',
                subscription_expires_at: subscriptionExpiresAt,  // ← Expiry date
            })
            .eq('id', userId);

        if (updateError) {
            console.error('[Google Play Verify] Database update error:', updateError);
            return res.status(500).json({ 
                success: false, 
                error: 'Failed to update user subscription in database.' 
            });
        }

        console.log(`[Google Play Verify] SUCCESS: User ${userId} upgraded to ${membershipTier}, expires at ${subscriptionExpiresAt}`);

        // Return success to Flutter
        res.status(200).json({ 
            success: true, 
            message: 'Google Play purchase verified', 
            membershipTier,
            subscriptionExpiresAt 
        });

    } catch (error) {
        console.error('[Google Play Verify] CRITICAL ERROR:', error.message);
        res.status(500).json({ 
            success: false, 
            error: 'Purchase could not be verified, please contact support.' 
        });
    }
}
```

### Backend: Apple IAP Verification (`safemama-backend/src/controllers/paymentController.js`)

```javascript
/**
 * Verifies Apple in-app purchase and updates user's membership tier
 * Called by Flutter after successful App Store purchase
 */
async function verifyAppleReceipt(req, res) {
    const { receiptData: signedTransactionInfo } = req.body;
    const userId = req.user.id;
    
    if (!signedTransactionInfo) {
        return res.status(400).json({ success: false, error: 'receiptData is missing.' });
    }

    try {
        // Verify JWT signature with Apple's public keys
        const verifiedTransaction = await verifyJws(signedTransactionInfo);
        console.log('[Apple API Verify] SUCCESS: Transaction verified.');

        const { productId, originalTransactionId, expiresDate } = verifiedTransaction;
        
        // ========================================
        // MAP APPLE PRODUCT IDS TO TIERS
        // ========================================
        let newMembershipTier = 'premium_monthly'; // default fallback
        
        const productIdLower = productId.toLowerCase();
        
        if (productIdLower.includes('weekly')) {
            newMembershipTier = 'premium_weekly';
        } else if (productIdLower.includes('yearly')) {
            newMembershipTier = 'premium_yearly';
        } else if (productIdLower.includes('monthly')) {
            newMembershipTier = 'premium_monthly';
        }
        // Legacy support for old product IDs
        else if (productIdLower === 'premium' || productIdLower.includes('premium')) {
            newMembershipTier = 'premium_monthly';
        }

        console.log(`[Apple IAP] Mapped productId "${productId}" to tier "${newMembershipTier}"`);

        // ========================================
        // UPDATE USER'S PROFILE IN SUPABASE
        // ========================================
        await supabaseAdminClient.from('profiles').update({
            membership_tier: newMembershipTier,              // ← Grant membership
            subscription_platform: 'apple',
            apple_original_transaction_id: originalTransactionId,
            subscription_expires_at: new Date(expiresDate).toISOString(),  // ← Expiry date
        }).eq('id', userId);
        
        res.status(200).json({ 
            success: true, 
            message: 'Purchase verified and user plan updated.',
            membershipTier: newMembershipTier
        });

    } catch (error) {
        console.error('[Apple API Verify] CRITICAL ERROR:', error.message);
        res.status(500).json({ 
            success: false, 
            error: 'Failed to verify purchase with Apple.' 
        });
    }
}
```

### Flutter: Purchase Flow (`safemama-done-1/lib/core/services/google_play_billing_service.dart`)

```dart
/// Listen to purchase updates and verify with backend
Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
  for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
    print("[GooglePlayBilling] Purchase update: ${purchaseDetails.productID} - Status: ${purchaseDetails.status}");
    
    if (purchaseDetails.status == PurchaseStatus.purchased || 
        purchaseDetails.status == PurchaseStatus.restored) {
      
      // ========================================
      // VERIFY PURCHASE WITH BACKEND
      // ========================================
      bool valid = await _verifyPurchaseWithBackend(purchaseDetails);
      
      if (valid) {
        print("[GooglePlayBilling] Purchase valid. Delivering content for ${purchaseDetails.productID}.");
        
        // ========================================
        // RELOAD USER PROFILE TO SHOW NEW MEMBERSHIP
        // ========================================
        await _ref.read(userProfileNotifierProvider.notifier).loadUserProfile();
      } else {
        print("[GooglePlayBilling] Purchase verification failed.");
      }
    }
    
    // Complete the purchase to remove it from the queue
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }
}

/// Verify the purchase with the backend
Future<bool> _verifyPurchaseWithBackend(PurchaseDetails purchaseDetails) async {
  final String? accessToken = _ref.read(supabaseServiceProvider).client.auth.currentSession?.accessToken;
  
  if (accessToken == null) {
    print("[GooglePlayBilling] No auth token available.");
    return false;
  }

  try {
    String purchaseToken = '';
    if (purchaseDetails is GooglePlayPurchaseDetails) {
      purchaseToken = purchaseDetails.billingClientPurchase.purchaseToken;
    }

    final String verificationEndpoint = '${AppConstants.yourBackendBaseUrl}/api/payments/verify-google-play';
    
    final response = await http.post(
      Uri.parse(verificationEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'productId': purchaseDetails.productID,      // e.g., "safemama_premium_weekly"
        'purchaseToken': purchaseToken,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (responseBody['success'] == true) {
        print("[GooglePlayBilling] Backend verified. New tier: ${responseBody['membershipTier']}");
        return true;
      }
    }
    
    return false;
  } catch (e) {
    print("[GooglePlayBilling] Exception: $e");
    return false;
  }
}
```

---

## 2. Membership Status Loading and Display in UI

### Flutter: Load Membership Status (`safemama-done-1/lib/navigation/providers/user_profile_provider.dart`)

```dart
/// Load user profile from Supabase
/// This is called on app startup and after purchases
Future<void> loadUserProfile() async {
  if (_isDisposed || _userId == null || _userId!.isEmpty) {
    return;
  }

  print("[UserProfileProvider] Loading profile for user $_userId");

  try {
    // ========================================
    // FETCH USER PROFILE FROM SUPABASE
    // ========================================
    final response = await _supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', _userId!)
      .maybeSingle();

    if (response != null && response.isNotEmpty) {
      print("[UserProfileProvider] Profile data received");
      print("[UserProfileProvider] membership_tier: ${response['membership_tier']}");
      print("[UserProfileProvider] subscription_expires_at: ${response['subscription_expires_at']}");
      
      // ========================================
      // PARSE INTO UserProfile MODEL
      // ========================================
      _userProfileModel = UserProfile.fromMap(response);
      
      print("[UserProfileProvider] Parsed - tier: ${_userProfileModel?.membershipTier}");
      print("[UserProfileProvider] Parsed - isPremiumUser: ${_userProfileModel?.isPremiumUser}");
      
      _updateLocalStateFromData(response);
      notifyListeners();
    }
  } catch (e) {
    print("[UserProfileProvider] Error loading profile: $e");
  }
}
```

### Flutter: Parse Membership from Database (`safemama-done-1/lib/core/models/user_profile.dart`)

```dart
/// Parse UserProfile from Supabase response
factory UserProfile.fromMap(Map<String, dynamic> map) {
  return UserProfile(
    id: map['id']?.toString() ?? '',
    email: map['email']?.toString(),
    fullName: map['full_name']?.toString(),
    
    // ========================================
    // READ MEMBERSHIP TIER
    // ========================================
    membershipTier: map['membership_tier']?.toString(),  // 'free', 'premium_weekly', etc.
    
    // ========================================
    // READ EXPIRY DATE (HANDLES BOTH FIELD NAMES)
    // ========================================
    membershipExpiry: map['subscription_expires_at'] != null 
        ? DateTime.parse(map['subscription_expires_at']) 
        : (map['membership_expiry'] != null 
            ? DateTime.parse(map['membership_expiry']) 
            : null),
    
    // Usage counters
    scanCount: map['scan_count'],
    askExpertCount: map['ask_expert_count'],
    
    // ... other fields
  );
}

/// Check if user is premium (any paid tier)
bool get isPremiumUser {
  final tier = membershipTier?.toLowerCase() ?? '';
  return tier == 'premium' || 
         tier == 'premium_weekly' || 
         tier == 'premium_monthly' || 
         tier == 'premium_yearly';
}
```

### Flutter: Display in Home Header (`safemama-done-1/lib/features/home/widgets/membership_status_chip.dart`)

```dart
/// Widget to display current membership plan
class MembershipStatusChip extends ConsumerWidget {
  const MembershipStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ========================================
    // GET USER'S CURRENT MEMBERSHIP
    // ========================================
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final userProfile = userProfileState.userProfile;

    if (userProfile == null) {
      return const SizedBox.shrink();
    }

    // ========================================
    // MAP TIER TO PLAN OBJECT
    // ========================================
    final plan = SubscriptionPlan.fromTier(userProfile.membershipTier);
    final bool isFree = plan.id == 'free';

    // Format expiry date
    String? expiryText;
    if (!isFree && userProfile.membershipExpiry != null) {
      final expiry = userProfile.membershipExpiry!;
      final now = DateTime.now();
      
      if (expiry.isBefore(now)) {
        expiryText = 'Expired';
      } else {
        final daysUntilExpiry = expiry.difference(now).inDays;
        if (daysUntilExpiry < 7) {
          expiryText = 'Expires in $daysUntilExpiry days';
        } else {
          expiryText = 'Renews ${DateFormat('MMM d').format(expiry)}';
        }
      }
    }

    // ========================================
    // DISPLAY PLAN CHIP
    // ========================================
    return GestureDetector(
      onTap: () {
        if (isFree) {
          context.push(AppRouter.upgradePath);  // Tap to upgrade
        } else {
          context.push(AppRouter.profilePath);  // Tap to manage
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isFree ? greyGradient : goldGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFree ? Icons.account_circle : Icons.workspace_premium,
              size: 16,
              color: isFree ? Colors.grey.shade700 : Colors.white,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.displayName,  // ← Shows "Free", "Premium Weekly", etc.
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isFree ? Colors.grey.shade800 : Colors.white,
                  ),
                ),
                if (expiryText != null)
                  Text(
                    expiryText,  // ← Shows "Renews Dec 24"
                    style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.9)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Flutter: Display in Drawer (`safemama-done-1/lib/core/widgets/app_drawer.dart`)

```dart
/// Premium status indicator in drawer
class _PremiumStatusIndicator extends ConsumerWidget {
  const _PremiumStatusIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ========================================
    // GET USER'S CURRENT MEMBERSHIP
    // ========================================
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final userProfile = userProfileState.userProfile;

    if (userProfile == null) {
      return const SizedBox.shrink();
    }

    final plan = SubscriptionPlan.fromTier(userProfile.membershipTier);
    
    // Format expiry/renewal date
    String expiryText = '';
    if (userProfile.membershipExpiry != null) {
      final expiry = userProfile.membershipExpiry!;
      final now = DateTime.now();
      
      if (expiry.isBefore(now)) {
        expiryText = 'Expired ${DateFormat('MMM d, y').format(expiry)}';
      } else {
        expiryText = 'Renews ${DateFormat('MMM d, y').format(expiry)}';
      }
    }

    // ========================================
    // DISPLAY PREMIUM CARD IN DRAWER
    // ========================================
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],  // Gold gradient
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  plan.displayName,  // ← Shows "Premium Weekly", "Premium Monthly", etc.
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            if (expiryText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                expiryText,  // ← Shows "Renews Dec 24, 2025"
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 3. Quota Enforcement Functions

### Backend: Centralized Quota Check (`safemama-backend/src/config/planLimits.js`)

```javascript
/**
 * Check if a user has exceeded their quota for a specific feature
 */
function checkQuota(tier, feature, currentCount) {
    const limits = getLimitsForTier(tier);
    const limit = limits[feature];
    
    // -1 means unlimited
    if (limit === -1) {
        return {
            allowed: true,
            limit: -1,
            remaining: -1,
            isUnlimited: true
        };
    }
    
    // 0 means feature not available for this tier
    if (limit === 0) {
        return {
            allowed: false,
            limit: 0,
            remaining: 0,
            isUnlimited: false,
            error: 'This feature is not available on your current plan.'
        };
    }
    
    // Check if user has exceeded limit
    const allowed = currentCount < limit;
    const remaining = Math.max(0, limit - currentCount);
    
    return {
        allowed,
        limit,
        remaining,
        isUnlimited: false,
        error: allowed ? null : `You have reached your ${feature} limit.`
    };
}

/**
 * Get user-friendly error message for quota exceeded
 */
function getQuotaExceededMessage(tier, feature) {
    const limits = getLimitsForTier(tier);
    const limit = limits[feature];
    const period = limits.period;
    
    if (tier === 'free') {
        return `You've used all ${limit} of your free ${feature}. Upgrade to Premium for more!`;
    }
    
    return `You've used all ${limit} ${feature} for this ${period}. Your quota will reset next ${period}.`;
}
```

### Backend: Scan Quota Enforcement (`safemama-backend/src/routes/product_analysis_routes.js`)

```javascript
const { checkQuota, getQuotaExceededMessage } = require('../config/planLimits');

router.post('/scan-product', requireAuth, upload.single('productImage'), async (req, res) => {
    try {
        const userId = req.user.id;

        // ========================================
        // FETCH USER PROFILE
        // ========================================
        const { data: profile, error: profileError } = await supabaseAdminClient
            .from('profiles')
            .select('membership_tier, scan_count')
            .eq('id', userId)
            .single();

        if (profileError) throw profileError;

        const tier = profile.membership_tier || 'free';
        const currentCount = profile.scan_count || 0;
        
        console.log(`Scan request from user: ${userId}, tier: ${tier}, count: ${currentCount}`);

        // ========================================
        // CHECK QUOTA USING CENTRALIZED SYSTEM
        // ========================================
        const quotaCheck = checkQuota(tier, 'scans', currentCount);
        
        if (!quotaCheck.allowed) {
            const limitMessage = getQuotaExceededMessage(tier, 'scans');
            console.log(`Scan blocked. Tier: ${tier}, Count: ${currentCount}, Limit: ${quotaCheck.limit}`);
            
            return res.status(429).json({ 
                error: limitMessage, 
                limitReached: true,
                limit: quotaCheck.limit,
                remaining: quotaCheck.remaining
            });
        }
        
        console.log(`Scan allowed. Remaining: ${quotaCheck.remaining}`);

        // ========================================
        // PROCESS SCAN (AI analysis)
        // ========================================
        const imageBuffer = req.file.buffer;
        const base64Image = imageBuffer.toString('base64');
        
        const completion = await openai.chat.completions.create({
            model: "gpt-4o",
            messages: [
                {
                    role: "user",
                    content: [
                        { type: "text", text: "Analyze this product for pregnancy safety..." },
                        { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } }
                    ]
                }
            ],
        });

        const analysisResult = completion.choices[0].message.content;

        // ========================================
        // INCREMENT SCAN COUNTER
        // ========================================
        await supabaseAdminClient
            .from('profiles')
            .update({ scan_count: currentCount + 1 })
            .eq('id', userId);

        // Return results
        res.status(200).json({ 
            analysis: analysisResult,
            scansRemaining: quotaCheck.remaining - 1
        });

    } catch (error) {
        console.error('Scan error:', error);
        res.status(500).json({ error: 'Product analysis failed' });
    }
});
```

### Backend: Ask Expert Quota Enforcement (`safemama-backend/src/routes/expert_consultation_routes.js`)

```javascript
const { checkQuota, getQuotaExceededMessage } = require('../config/planLimits');

router.post('/ask-expert', requireAuth, async (req, res) => {
    try {
        const userId = req.user.id;
        const { question } = req.body;

        // ========================================
        // FETCH USER PROFILE
        // ========================================
        const { data: profile, error: profileError } = await supabaseAdminClient
            .from('profiles')
            .select('membership_tier, ask_expert_count')
            .eq('id', userId)
            .single();

        if (profileError) throw profileError;

        const tier = profile.membership_tier || 'free';
        const currentCount = profile.ask_expert_count || 0;

        // ========================================
        // CHECK QUOTA
        // ========================================
        const quotaCheck = checkQuota(tier, 'askExpert', currentCount);
        
        if (!quotaCheck.allowed) {
            const limitMessage = getQuotaExceededMessage(tier, 'askExpert');
            return res.status(429).json({ 
                error: limitMessage, 
                limitReached: true,
                limit: quotaCheck.limit,
                remaining: quotaCheck.remaining
            });
        }

        // ========================================
        // PROCESS AI CONSULTATION
        // ========================================
        const stream = await openai.chat.completions.create({
            model: "gpt-4o",
            messages: [
                { role: "system", content: "You are a pregnancy expert..." },
                { role: "user", content: question }
            ],
            stream: true,
        });

        // Set up streaming response
        res.setHeader('Content-Type', 'text/event-stream');
        for await (const chunk of stream) {
            const content = chunk.choices[0]?.delta?.content || '';
            res.write(`data: ${JSON.stringify({ content })}\n\n`);
        }
        res.write('data: [DONE]\n\n');

        // ========================================
        // INCREMENT COUNTER
        // ========================================
        await supabaseAdminClient
            .from('profiles')
            .update({ ask_expert_count: currentCount + 1 })
            .eq('id', userId);

        res.end();

    } catch (error) {
        console.error('Ask Expert error:', error);
        res.status(500).json({ error: 'Expert consultation failed' });
    }
});
```

### Backend: AI Pregnancy Tools Rate Limiting (`safemama-backend/src/routes/pregnancy_tools_routes.js`)

```javascript
const { hasPremiumToolsAccess, checkQuota, getQuotaExceededMessage } = require('../config/planLimits');

// ========================================
// MIDDLEWARE: CHECK PREMIUM ACCESS
// ========================================
const checkPremiumAccess = async (req, res, next) => {
    const userId = req.user.id;
    
    const { data: profile, error } = await supabaseAdminClient
        .from('profiles')
        .select('membership_tier, subscription_expires_at, ai_pregnancy_tools_count')
        .eq('id', userId)
        .single();

    if (error) {
        return res.status(500).json({ error: 'Server error' });
    }

    const tier = profile.membership_tier || 'free';
    
    // Check if user has premium access
    const isPremium = hasPremiumToolsAccess(tier);

    if (!isPremium) {
        return res.status(403).json({ 
            error: 'Premium subscription required for this feature',
            currentTier: tier
        });
    }

    // Check subscription expiry
    if (profile.subscription_expires_at) {
        const expiresAt = new Date(profile.subscription_expires_at);
        if (new Date() > expiresAt) {
            return res.status(403).json({ 
                error: 'Your premium subscription has expired.',
                subscriptionExpired: true
            });
        }
    }

    req.userProfile = profile;
    next();
};

// ========================================
// MIDDLEWARE: CHECK AI TOOL RATE LIMIT
// ========================================
const checkAIToolRateLimit = async (req, res, next) => {
    const userId = req.user.id;
    const profile = req.userProfile;
    
    const tier = profile.membership_tier || 'free';
    const currentCount = profile.ai_pregnancy_tools_count || 0;

    // Check AI pregnancy tools quota
    const quotaCheck = checkQuota(tier, 'aiPregnancyTools', currentCount);
    
    if (!quotaCheck.allowed) {
        const limitMessage = getQuotaExceededMessage(tier, 'aiPregnancyTools');
        return res.status(429).json({ 
            error: limitMessage,
            limitReached: true,
            limit: quotaCheck.limit,
            remaining: quotaCheck.remaining
        });
    }

    console.log(`AI Tool allowed. Remaining: ${quotaCheck.remaining}`);
    next();
};

// ========================================
// APPLY MIDDLEWARE TO AI TOOLS
// ========================================
router.post('/ai-birth-plan', 
    requireAuth, 
    checkPremiumAccess, 
    checkAIToolRateLimit,  // ← Rate limit
    async (req, res) => {
        // Generate AI birth plan...
        
        // Increment counter
        await supabaseAdminClient
            .from('profiles')
            .update({ 
                ai_pregnancy_tools_count: (req.userProfile.ai_pregnancy_tools_count || 0) + 1 
            })
            .eq('id', req.user.id);
    }
);
```

### Flutter: Display Quota in UI (`safemama-done-1/lib/features/qna/scan/screens/scan_product_screen.dart`)

```dart
Widget _buildScanLimitIndicator() {
  return Consumer(
    builder: (context, ref, child) {
      final userProfile = ref.watch(userProfileNotifierProvider).userProfile;
      
      if (userProfile == null) return const SizedBox.shrink();
      
      // ========================================
      // GET PLAN AND LIMITS
      // ========================================
      final plan = SubscriptionPlan.fromTier(userProfile.membershipTier);
      final currentCount = userProfile.scanCount ?? 0;
      final limit = plan.limits.scans;
      final remaining = limit - currentCount;
      
      // ========================================
      // DISPLAY QUOTA INDICATOR
      // ========================================
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: remaining <= 3 
              ? Colors.red.shade50 
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 16,
              color: remaining <= 3 ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 6),
            Text(
              plan.id == 'premium_yearly' 
                  ? 'Unlimited scans' 
                  : '$remaining scans remaining',
              style: TextStyle(
                fontSize: 12,
                color: remaining <= 3 ? Colors.red.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

---

## Summary

These code snippets show the complete end-to-end flow:

1. **Purchase Callback**: Google Play and Apple purchases are verified backend-side, product IDs are mapped to internal tiers (`premium_weekly`, `premium_monthly`, `premium_yearly`), and Supabase is updated with the new `membership_tier` and `subscription_expires_at`.

2. **Membership Display**: Flutter loads the profile from Supabase, parses the `membership_tier` and `subscription_expires_at` fields, and displays the plan name prominently in the home header and drawer.

3. **Quota Enforcement**: Backend routes use centralized `checkQuota()` to verify limits before processing requests, return user-friendly error messages when limits are exceeded, and increment usage counters after successful operations.

The system is now fully functional and ensures that purchases immediately grant premium access, the correct plan is displayed throughout the UI, and all usage limits are enforced exactly as specified.

