// ==========================================================
// config.js — SafeMama Marketing Agent Configuration
// ==========================================================
import 'dotenv/config';

const config = {
    openai: {
        apiKey: process.env.OPENAI_API_KEY,
        model: process.env.OPENAI_MODEL || 'gpt-4o',
    },
    telegram: {
        botToken: process.env.TELEGRAM_BOT_TOKEN,
        chatId: process.env.TELEGRAM_CHAT_ID,
    },
    chrome: {
        userDataDir: process.env.CHROME_USER_DATA_DIR || '',
        profile: process.env.CHROME_PROFILE || 'Default',
    },
    schedule: {
        postsPerDay: parseInt(process.env.POSTS_PER_DAY || '2'),
        postTimes: (process.env.POST_TIMES || '10:00,18:00').split(',').map(t => t.trim()),
        timezone: process.env.TIMEZONE || 'Asia/Kolkata',
    },
    app: {
        name: process.env.APP_NAME || 'SafeMama',
        storeUrl: process.env.APP_STORE_URL || 'https://apps.apple.com/app/safemama/id6748413103',
        tagline: process.env.APP_TAGLINE || 'AI-Powered Pregnancy Safety & Wellness Companion',
        tiktokUsername: process.env.TIKTOK_USERNAME || '',
        instagramUsername: process.env.INSTAGRAM_USERNAME || '',
    },
};

export default config;
