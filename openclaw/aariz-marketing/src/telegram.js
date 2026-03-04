// ==========================================================
// telegram.js — Telegram notifications & command center
// ==========================================================
import TelegramBot from 'node-telegram-bot-api';
import config from './config.js';
import fs from 'fs';

let bot = null;

function getBot() {
    if (!bot && config.telegram.botToken) {
        bot = new TelegramBot(config.telegram.botToken, { polling: false });
    }
    return bot;
}

// Send a text message
export async function sendMessage(text, parseMode = 'HTML') {
    const b = getBot();
    if (!b) { console.warn('[Telegram] No bot token configured.'); return; }
    try {
        await b.sendMessage(config.telegram.chatId, text, {
            parse_mode: parseMode,
            disable_web_page_preview: true
        });
        console.log('[Telegram] ✅ Message sent');
    } catch (err) {
        console.error('[Telegram] ❌ Send failed:', err.message);
    }
}

// Send a photo with caption
export async function sendPhoto(imagePath, caption = '') {
    const b = getBot();
    if (!b) return;
    try {
        await b.sendPhoto(config.telegram.chatId, fs.createReadStream(imagePath), {
            caption: caption.substring(0, 1024),
            parse_mode: 'HTML',
        });
        console.log('[Telegram] ✅ Photo sent');
    } catch (err) {
        console.error('[Telegram] ❌ Photo send failed:', err.message);
    }
}

// Send a group of photos (carousel preview)
export async function sendSlideCarousel(imagePaths, caption = '') {
    const b = getBot();
    if (!b) return;
    try {
        const media = imagePaths.map((p, i) => ({
            type: 'photo',
            media: fs.createReadStream(p),
            ...(i === 0 ? { caption: caption.substring(0, 1024), parse_mode: 'HTML' } : {}),
        }));
        await b.sendMediaGroup(config.telegram.chatId, media);
        console.log(`[Telegram] ✅ Carousel sent (${imagePaths.length} slides)`);
    } catch (err) {
        console.error('[Telegram] ❌ Carousel send failed:', err.message);
    }
}

// ---- Research Report ----
export async function sendResearchReport(research) {
    const msg = `
🔬 <b>MARKET RESEARCH REPORT</b>
━━━━━━━━━━━━━━━━━━━━━

📊 <b>Type:</b> ${research.type}
📱 <b>Platform:</b> ${research.platform || 'All'}

🎯 <b>Top Angles Found:</b>
${(research.topAngles || []).map((a, i) => `  ${i + 1}. ${a}`).join('\n')}

💡 <b>Key Insights:</b>
${(research.insights || []).slice(0, 5).map(i => `  • ${i}`).join('\n')}

🗣️ <b>Best Language Hooks:</b>
${(research.hooks || []).slice(0, 5).map(h => `  "${h}"`).join('\n')}

⏰ ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
`.trim();
    await sendMessage(msg);
}

// ---- Content Idea Notification ----
export async function sendContentIdea(idea) {
    const slides = JSON.parse(idea.slide_texts || '[]');
    const slidePreview = slides.map((t, i) => `  ${i + 1}. "${t.substring(0, 60)}${t.length > 60 ? '...' : ''}"`).join('\n');

    const msg = `
🎨 <b>NEW CONTENT READY</b>
━━━━━━━━━━━━━━━━━━━━━

📐 <b>Angle:</b> ${idea.angle}
🎣 <b>Hook:</b> "${idea.hook}"

📋 <b>Slides:</b>
${slidePreview}

📝 <b>Caption:</b>
${(idea.caption || '').substring(0, 200)}...

#️⃣ <b>Hashtags:</b> ${idea.hashtags || 'none'}

⭐ <b>Priority:</b> ${idea.priority_score}/100
📱 <b>Target:</b> ${idea.target_platform}

⏰ ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
`.trim();
    await sendMessage(msg);
}

// ---- Post Notification ----
export async function sendPostNotification(post, platform) {
    const msg = `
✅ <b>POST PUBLISHED</b>
━━━━━━━━━━━━━━━━━━━━━

📱 <b>Platform:</b> ${platform.toUpperCase()}
🔗 <b>URL:</b> ${post.postUrl || 'pending'}
📐 <b>Angle:</b> ${post.angle}
🎣 <b>Hook:</b> "${post.hook}"

⏰ ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
`.trim();
    await sendMessage(msg);
}

// ---- Performance Report ----
export async function sendPerformanceReport(stats) {
    const lines = stats.map(s =>
        `  ${s.angle}: ${s.total_posts} posts | Avg views: ${Math.round(s.avg_views || 0)} | Best: ${s.best_views || 0}`
    );
    const msg = `
📈 <b>PERFORMANCE REPORT</b>
━━━━━━━━━━━━━━━━━━━━━

${lines.join('\n')}

🏆 <b>Best Angle:</b> ${stats[0]?.angle || 'N/A'} (${Math.round(stats[0]?.avg_views || 0)} avg views)
📉 <b>Worst Angle:</b> ${stats[stats.length - 1]?.angle || 'N/A'} (${Math.round(stats[stats.length - 1]?.avg_views || 0)} avg views)

💡 <b>Recommendation:</b> Double down on "${stats[0]?.angle || 'top performing'}" content

⏰ ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
`.trim();
    await sendMessage(msg);
}

// ---- Error notification ----
export async function sendError(context, errorMsg) {
    const msg = `❌ <b>ERROR in ${context}</b>\n${errorMsg}`;
    await sendMessage(msg);
}

export default { sendMessage, sendPhoto, sendSlideCarousel, sendResearchReport, sendContentIdea, sendPostNotification, sendPerformanceReport, sendError };
