// ==========================================================
// index.js — SafeMama Marketing Agent (OpenClaw)
// ==========================================================
// AI-powered marketing automation:
//   1. Market research (competitor, audience, angles)
//   2. Content generation (slide concepts + AI images)
//   3. Auto-posting to TikTok + Instagram via browser
//   4. Performance tracking + self-optimization
//   5. Everything reported to Telegram
// ==========================================================
import config from './config.js';
import { runFullResearch, runOptimizationAnalysis } from './researcher.js';
import { generateContentBatch } from './content-engine.js';
import { generateAllPendingSlides } from './slide-generator.js';
import { postNextContent } from './poster.js';
import { checkPostAnalytics, runSelfOptimization } from './analytics.js';
import { sendMessage } from './telegram.js';
import { getDraftContent, getNextContentToPost } from './database.js';

// ==========================================================
// SCHEDULING HELPERS
// ==========================================================
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function getNextPostTime() {
    const now = new Date();
    const tz = config.schedule.timezone;
    const today = now.toLocaleDateString('en-CA', { timeZone: tz }); // YYYY-MM-DD
    const currentTime = now.toLocaleTimeString('en-GB', { timeZone: tz, hour: '2-digit', minute: '2-digit' });

    for (const time of config.schedule.postTimes) {
        if (time > currentTime) {
            return { date: today, time, isToday: true };
        }
    }

    // All post times have passed — schedule for tomorrow
    const tomorrow = new Date(now.getTime() + 86400000);
    const tomorrowStr = tomorrow.toLocaleDateString('en-CA', { timeZone: tz });
    return { date: tomorrowStr, time: config.schedule.postTimes[0], isToday: false };
}

function msUntilTime(targetTime) {
    const now = new Date();
    const tz = config.schedule.timezone;
    const currentTime = now.toLocaleTimeString('en-GB', { timeZone: tz, hour: '2-digit', minute: '2-digit', second: '2-digit' });

    const [targetH, targetM] = targetTime.split(':').map(Number);
    const [currH, currM, currS] = currentTime.split(':').map(Number);

    let diffMs = ((targetH - currH) * 3600 + (targetM - currM) * 60 - currS) * 1000;
    if (diffMs < 0) diffMs += 86400000; // Next day

    return diffMs;
}

// ==========================================================
// MAIN PIPELINE
// ==========================================================
async function runPipeline() {
    console.log('\n╔════════════════════════════════════════════════════╗');
    console.log('║     SafeMama Marketing Agent — OpenClaw v1.0      ║');
    console.log('║  Research → Create → Generate → Post → Optimize   ║');
    console.log('╚════════════════════════════════════════════════════╝\n');

    await sendMessage(`
🚀 <b>SafeMama Marketing Agent Started!</b>
━━━━━━━━━━━━━━━━━━━━━
📊 Posts per day: ${config.schedule.postsPerDay}
⏰ Post times: ${config.schedule.postTimes.join(', ')}
📱 Platforms: TikTok + Instagram
🧠 Self-optimization: Enabled
    `.trim());

    // ---- STEP 1: Run initial market research ----
    console.log('\n📍 STEP 1: Market Research');
    console.log('─'.repeat(40));
    const research = await runFullResearch();

    // ---- STEP 2: Generate content ideas from research ----
    console.log('\n📍 STEP 2: Content Generation');
    console.log('─'.repeat(40));
    const contentCount = Math.max(config.schedule.postsPerDay * 2, 5); // Buffer of 2x
    await generateContentBatch(contentCount);

    // ---- STEP 3: Generate slide images ----
    console.log('\n📍 STEP 3: Slide Image Generation');
    console.log('─'.repeat(40));
    await generateAllPendingSlides();

    // ---- STEP 4: Enter posting loop ----
    console.log('\n📍 STEP 4: Entering Post Scheduling Loop');
    console.log('─'.repeat(40));

    await runPostingLoop();
}

// ==========================================================
// POSTING LOOP (Runs continuously)
// ==========================================================
async function runPostingLoop() {
    let cycleCount = 0;

    while (true) {
        cycleCount++;
        const nextPost = getNextPostTime();
        const waitMs = msUntilTime(nextPost.time);
        const waitMinutes = Math.round(waitMs / 60000);

        console.log(`\n⏰ Next post at ${nextPost.time} (${nextPost.date}) — waiting ${waitMinutes} minutes`);
        await sendMessage(`⏰ Next post scheduled at <b>${nextPost.time}</b> (in ~${waitMinutes} min)`);

        // Wait until post time
        await sleep(waitMs);

        // ---- POST ----
        console.log(`\n📱 POST TIME! (Cycle ${cycleCount})`);

        const content = getNextContentToPost();
        if (content) {
            await postNextContent();
        } else {
            console.log('[Loop] No content ready. Generating more...');
            await generateContentBatch(3);
            await generateAllPendingSlides();
            // Try again
            await postNextContent();
        }

        // ---- Every 3 cycles: Run analytics + optimization ----
        if (cycleCount % 3 === 0) {
            console.log('\n🧠 Running periodic optimization...');
            await checkPostAnalytics();
            await runSelfOptimization();
        }

        // ---- Every 6 cycles: Fresh research ----
        if (cycleCount % 6 === 0) {
            console.log('\n🔬 Running fresh market research...');
            await runFullResearch();
            await generateContentBatch(5);
            await generateAllPendingSlides();
        }

        // Small delay before checking next post time
        await sleep(60000); // 1 minute buffer
    }
}

// ==========================================================
// ONE-SHOT MODES (for testing individual stages)
// ==========================================================
export async function runResearchOnly() {
    console.log('🔬 Running research only...');
    const research = await runFullResearch();
    console.log('✅ Research complete!');
    return research;
}

export async function runContentOnly() {
    console.log('🎨 Running content generation only...');
    await generateContentBatch(5);
    console.log('✅ Content generation complete!');
}

export async function runSlidesOnly() {
    console.log('🖼️ Running slide generation only...');
    await generateAllPendingSlides();
    console.log('✅ Slide generation complete!');
}

export async function runPostOnly() {
    console.log('📱 Running post only...');
    await postNextContent();
    console.log('✅ Posting complete!');
}

// ==========================================================
// CLI MODE HANDLER
// ==========================================================
const args = process.argv.slice(2);
const mode = args[0] || 'full';

console.log(`\n🏁 Mode: ${mode}`);

switch (mode) {
    case 'research':
        runResearchOnly().catch(console.error);
        break;
    case 'content':
        runContentOnly().catch(console.error);
        break;
    case 'slides':
        runSlidesOnly().catch(console.error);
        break;
    case 'post':
        runPostOnly().catch(console.error);
        break;
    case 'full':
    default:
        runPipeline().catch(console.error);
        break;
}

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('\n👋 Shutting down Marketing Agent...');
    await sendMessage('👋 Marketing Agent shutting down.');
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\n👋 Shutting down Marketing Agent...');
    process.exit(0);
});
