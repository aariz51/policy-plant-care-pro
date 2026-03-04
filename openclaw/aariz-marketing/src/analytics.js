// ==========================================================
// analytics.js — Performance tracking & self-optimization
// ==========================================================
import { chromium } from 'playwright-core';
import config from './config.js';
import { getRecentPosts, insertAnalytics, getPerformanceStats, insertOptimization } from './database.js';
import { sendPerformanceReport, sendMessage } from './telegram.js';
import { runOptimizationAnalysis } from './researcher.js';
import { generateOptimizedContent } from './content-engine.js';

const CDP_PORT = 9222;

// ==========================================================
// CHECK ANALYTICS FOR RECENT POSTS
// ==========================================================
export async function checkPostAnalytics() {
    console.log('\n📊 Checking post analytics...');

    const recentPosts = getRecentPosts(20);
    if (recentPosts.length === 0) {
        console.log('[Analytics] No posted content to check.');
        return;
    }

    await sendMessage(`📊 <b>Checking analytics for ${recentPosts.length} recent posts...</b>`);

    // For now, since we can't easily scrape exact analytics from TikTok/Instagram
    // via automation (they require being on the exact post page), we'll use
    // a manual input system via Telegram or estimate based on available data.

    console.log(`[Analytics] ${recentPosts.length} posts tracked.`);

    // Generate performance report from DB data
    const stats = getPerformanceStats();
    if (stats.length > 0) {
        await sendPerformanceReport(stats);
    }
}

// ==========================================================
// SELF-OPTIMIZATION CYCLE
// ==========================================================
export async function runSelfOptimization() {
    console.log('\n🧠 Running self-optimization cycle...');

    const stats = getPerformanceStats();
    if (stats.length === 0) {
        console.log('[Optimization] Not enough data yet. Need at least some posted content with analytics.');
        return;
    }

    try {
        // 1. Analyze what worked
        const optimization = await runOptimizationAnalysis();
        if (!optimization) return;

        // 2. Save optimization record
        insertOptimization({
            analysis: optimization.analysis,
            recommendations: optimization.recommendations,
            applied_changes: optimization.angle_adjustments,
        });

        // 3. Generate new optimized content
        await generateOptimizedContent(optimization, 3);

        // 4. Report to Telegram
        const recMsg = optimization.recommendations.map((r, i) => `  ${i + 1}. ${r}`).join('\n');
        await sendMessage(`
🧠 <b>SELF-OPTIMIZATION COMPLETE</b>
━━━━━━━━━━━━━━━━━━━━━

📊 <b>Best:</b> ${optimization.analysis.best_performing}
📉 <b>Worst:</b> ${optimization.analysis.worst_performing}

💡 <b>Key Finding:</b>
${optimization.analysis.key_finding}

📋 <b>Recommendations:</b>
${recMsg}

✅ Generated 3 new optimized content ideas!
        `.trim());

        console.log('[Optimization] ✅ Self-optimization complete');

    } catch (err) {
        console.error('[Optimization] ❌ Failed:', err.message);
    }
}

// ==========================================================
// MANUAL ANALYTICS INPUT (via Telegram or direct)
// ==========================================================
export function recordAnalytics(postId, views, likes, comments, shares, saves) {
    insertAnalytics({ post_id: postId, views, likes, comments, shares, saves });
    console.log(`[Analytics] Recorded: Post #${postId} — ${views} views, ${likes} likes`);
}

export default { checkPostAnalytics, runSelfOptimization, recordAnalytics };
