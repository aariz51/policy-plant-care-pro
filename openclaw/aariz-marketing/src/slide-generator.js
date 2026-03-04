// ==========================================================
// slide-generator.js — Pro-quality slide image generator
// ==========================================================
// Uses REAL stock photos (Pexels API), actual SafeMama app
// screenshots, and the official SafeMama logo. NO DALL-E.
// Zero AI-generated backgrounds = zero gibberish/spelling errors.
// ==========================================================
import sharp from 'sharp';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import config from './config.js';
import { insertSlide, updateContentStatus, getDraftContent } from './database.js';
import { sendSlideCarousel, sendMessage } from './telegram.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SLIDES_DIR = path.join(__dirname, '..', 'data', 'slides');
const ASSETS_DIR = path.join(__dirname, '..', 'data', 'safemama correct ui deisgn');
const STOCK_DIR = path.join(SLIDES_DIR, 'stock');
if (!fs.existsSync(SLIDES_DIR)) fs.mkdirSync(SLIDES_DIR, { recursive: true });
if (!fs.existsSync(STOCK_DIR)) fs.mkdirSync(STOCK_DIR, { recursive: true });

// Slide dimensions (TikTok/Instagram: 1080x1920)
const SLIDE_WIDTH = 1080;
const SLIDE_HEIGHT = 1920;

// SafeMama brand colors
const BRAND = {
    pink: '#F5A6B8',
    pinkLight: '#FFF0F5',
    pinkDark: '#D4849A',
    purple: '#7C3AED',
    purpleDark: '#4A0E4E',
    teal: '#2D9C9C',
    white: '#FFFFFF',
    dark: '#1A1A2E',
    darkBlue: '#16213E',
    warmBg: '#FFF8F0',
};

// ==========================================================
// ASSET CATALOG — Map real screenshots by purpose
// ==========================================================
// We map the real SafeMama screenshots to their content types
const APP_SCREENSHOTS = {
    // Raw UI screenshots (phone screen captures)
    scan_barcode: '8133b66d-90dd-4411-865b-a2e3662b2376.png',
    ttc_tracker: '70259963-de77-4802-a80f-2984f287fef5.png',
    trimester_select: '2af02ff5-7651-4ce3-8d56-b7b118ce643c.png',
    pregnancy_tools: '32309b66-8df5-4066-abf2-3a8d8baf5ddc.png',
    document_analysis: '8d6dd855-1d5b-4e55-ae67-2c3b295f6a9b.png',
    ask_expert_chat: '5aecd821-96f8-4603-ad5b-2be043a588ca.png', // actually week 40
    detailed_analysis: '4e29fcff-b463-4a4a-99ec-85b6ee120ab8.png',
    scan_result_safe: 'bb9fbcb9-be32-4686-941c-61991e921d73.png',
    strip_analysis: 'ecfedc88-86ba-487e-beba-385f75e8a2dc.png',
    scan_result_banana: 'edda32aa-ceba-42d5-b2b3-574e71d60bca.png',
    enter_ingredients: 'e6c88a76-4f4e-4540-a770-0bab0247cf22.png',
    week_40: '5aecd821-96f8-4603-ad5b-2be043a588ca.png',
    ai_expert_chat: '8d1e4aa0-51bf-4079-85b1-20ec198eef56.png',
    pregnancy_test: '6a63ac36-358b-43b2-99eb-fec431b18136.png',

    // App Store promotional screenshots (with phone frames + backgrounds)
    appstore_journey: '4d8b2876-39f5-4804-ac59-2dde4a02da83.png',
    appstore_reports: '6055335d-35ed-495c-a297-4a346158441c.png',
};

// SafeMama logo  
const LOGO_FILE = 'deb9c780-94a6-498a-bc96-1414a70bb42e.png';

// Screenshots grouped by content angle for automatic selection
const SCREENSHOTS_BY_ANGLE = {
    fear_shock: ['detailed_analysis', 'scan_barcode', 'enter_ingredients', 'pregnancy_test'],
    mistake_based: ['detailed_analysis', 'scan_result_safe', 'scan_barcode', 'enter_ingredients'],
    curiosity: ['strip_analysis', 'scan_result_banana', 'document_analysis', 'ai_expert_chat'],
    before_after: ['scan_result_safe', 'detailed_analysis', 'pregnancy_tools', 'week_40'],
    relatability: ['trimester_select', 'pregnancy_tools', 'ai_expert_chat', 'ttc_tracker'],
    education: ['document_analysis', 'enter_ingredients', 'scan_result_banana', 'pregnancy_tools'],
    authority: ['detailed_analysis', 'ai_expert_chat', 'scan_result_safe', 'document_analysis'],
};

// ==========================================================
// PEXELS API — Real stock photos
// ==========================================================
const PEXELS_API_KEY = process.env.PEXELS_API_KEY || '';

// Curated search queries by content context  
const STOCK_QUERIES = {
    products: [
        'skincare products flat lay',
        'cosmetic bottles aesthetic',
        'bathroom products shelf',
        'organic skincare products',
        'beauty products marble',
        'supplement bottles vitamins',
    ],
    pregnancy: [
        'baby clothes folded',
        'baby shoes nursery',
        'nursery room decoration',
        'prenatal vitamins bottle',
        'baby crib blanket',
        'baby products basket',
    ],
    food: [
        'healthy food flat lay',
        'fresh fruits vegetables',
        'organic groceries',
        'healthy breakfast bowl',
        'meal prep containers',
    ],
    warning: [
        'product label closeup',
        'ingredient list label',
        'medicine bottles shelf',
        'chemical bottles laboratory',
    ],
    clean_bg: [
        'pastel gradient background',
        'soft pink background texture',
        'marble texture flat lay',
        'white fabric texture',
        'blush pink aesthetic',
    ],
};

async function fetchPexelsPhoto(query, orientation = 'portrait') {
    if (!PEXELS_API_KEY) return null;

    try {
        const url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}&orientation=${orientation}&per_page=15&size=large`;
        const resp = await fetch(url, {
            headers: { Authorization: PEXELS_API_KEY },
        });

        if (!resp.ok) {
            console.warn(`  [Pexels] API error: ${resp.status}`);
            return null;
        }

        const data = await resp.json();
        if (!data.photos || data.photos.length === 0) return null;

        // Pick a random photo from results for variety
        const photo = data.photos[Math.floor(Math.random() * data.photos.length)];
        const imageUrl = photo.src.large2x || photo.src.large || photo.src.original;

        const imgResp = await fetch(imageUrl);
        if (!imgResp.ok) return null;

        const buffer = Buffer.from(await imgResp.arrayBuffer());
        const filename = `stock_${Date.now()}_${Math.random().toString(36).slice(2, 6)}.jpg`;
        const stockPath = path.join(STOCK_DIR, filename);
        fs.writeFileSync(stockPath, buffer);

        console.log(`  [Pexels] ✅ Got "${query}" → ${filename}`);
        return stockPath;
    } catch (err) {
        console.warn(`  [Pexels] Fetch failed: ${err.message}`);
        return null;
    }
}

// ==========================================================
// SLIDE BACKGROUND STRATEGIES
// ==========================================================

// Strategy 1: Real stock photo from Pexels
async function getStockPhotoBackground(angle, slideNum) {
    let queryPool;
    if (angle === 'fear_shock' || angle === 'mistake_based') {
        queryPool = [...STOCK_QUERIES.products, ...STOCK_QUERIES.warning];
    } else if (angle === 'curiosity' || angle === 'before_after') {
        queryPool = [...STOCK_QUERIES.products, ...STOCK_QUERIES.pregnancy];
    } else if (angle === 'education') {
        queryPool = [...STOCK_QUERIES.food, ...STOCK_QUERIES.products];
    } else {
        queryPool = [...STOCK_QUERIES.pregnancy, ...STOCK_QUERIES.products];
    }

    const query = queryPool[(slideNum + Math.floor(Math.random() * 3)) % queryPool.length];
    return await fetchPexelsPhoto(query);
}

// Strategy 2: Real app screenshot composited into phone frame
async function getAppScreenshotBackground(angle, slideNum, ideaId) {
    const angleScreens = SCREENSHOTS_BY_ANGLE[angle] || SCREENSHOTS_BY_ANGLE.education;
    const screenKey = angleScreens[slideNum % angleScreens.length];
    const screenshotFile = APP_SCREENSHOTS[screenKey];

    if (!screenshotFile) return null;

    const screenshotPath = path.join(ASSETS_DIR, screenshotFile);
    if (!fs.existsSync(screenshotPath)) {
        console.warn(`  [Screenshot] File not found: ${screenshotFile}`);
        return null;
    }

    try {
        // Create a blurred, darkened version of the screenshot as full background
        // This gives a "real app" feel while keeping text readable
        const bgPath = path.join(SLIDES_DIR, `appbg_${ideaId}_s${slideNum}.png`);

        // Get the screenshot and create a composited background:
        // Full blurred screenshot underneath + centered sharp screenshot area
        const screenshot = sharp(screenshotPath);
        const meta = await screenshot.metadata();

        // Create a slightly blurred & darkened fullscreen version
        await sharp(screenshotPath)
            .resize(SLIDE_WIDTH, SLIDE_HEIGHT, { fit: 'cover' })
            .blur(20)
            .modulate({ brightness: 0.4 })
            .png()
            .toFile(bgPath);

        return bgPath;
    } catch (err) {
        console.warn(`  [Screenshot] Processing failed: ${err.message}`);
        return null;
    }
}

// Strategy 3: Gradient background with optional accents (always works)
async function getGradientBackground(slideNum, ideaId, isFirst, isLast) {
    let gradient, accentCircles = '';

    if (isFirst) {
        // Hook slide — bold, attention-grabbing
        gradient = { from: '#1A1A2E', via: '#16213E', to: '#0F3460' };
    } else if (isLast) {
        // CTA slide — warm SafeMama brand
        gradient = { from: '#FFF0F5', via: '#FFE4EC', to: '#F5A6B8' };
    } else {
        const gradients = [
            { from: '#0F0C29', via: '#302B63', to: '#24243E' },     // Deep space
            { from: '#2D1B69', via: '#7B2FBE', to: '#B721FF' },     // Purple glow
            { from: '#1A1A2E', via: '#16213E', to: '#0F3460' },     // Dark blue
            { from: '#0D0D0D', via: '#1A1A2E', to: '#2D2D44' },     // Near black
            { from: '#2C003E', via: '#512B58', to: '#8B2FC9' },     // Rich purple
            { from: '#0C1445', via: '#2D1B69', to: '#5B247A' },     // Night purple
            { from: '#1B1B1B', via: '#2D2D2D', to: '#404040' },     // Dark grey
        ];
        gradient = gradients[slideNum % gradients.length];
    }

    // Add decorative circles for depth
    if (!isLast) {
        const r = Math.floor(Math.random() * 4);
        const circleColors = [
            `rgba(245, 166, 184, 0.08)`,  // Pink
            `rgba(124, 58, 237, 0.08)`,    // Purple
            `rgba(45, 156, 156, 0.06)`,    // Teal
            `rgba(255, 255, 255, 0.04)`,   // White
        ];
        accentCircles = `
            <circle cx="${200 + r * 100}" cy="${400 + r * 50}" r="300" fill="${circleColors[0]}" />
            <circle cx="${800 + r * 50}" cy="${1200 + r * 80}" r="250" fill="${circleColors[1]}" />
            <circle cx="${150}" cy="${1600}" r="200" fill="${circleColors[2]}" />
        `;
    }

    const svg = `<svg width="${SLIDE_WIDTH}" height="${SLIDE_HEIGHT}" xmlns="http://www.w3.org/2000/svg">
        <defs>
            <linearGradient id="grad" x1="0%" y1="0%" x2="50%" y2="100%">
                <stop offset="0%" style="stop-color:${gradient.from};stop-opacity:1" />
                ${gradient.via ? `<stop offset="50%" style="stop-color:${gradient.via};stop-opacity:1" />` : ''}
                <stop offset="100%" style="stop-color:${gradient.to};stop-opacity:1" />
            </linearGradient>
        </defs>
        <rect width="100%" height="100%" fill="url(#grad)" />
        ${accentCircles}
    </svg>`;

    const bgPath = path.join(SLIDES_DIR, `gradient_${ideaId}_s${slideNum}.png`);
    await sharp(Buffer.from(svg)).png().toFile(bgPath);
    return bgPath;
}

// ==========================================================
// SMART BACKGROUND SELECTOR
// ==========================================================
// Picks the best background strategy per slide position
async function getBackgroundForSlide(slideNum, totalSlides, isFirst, isLast, ideaId, angle) {
    // Slide 1 (Hook): Dark gradient or stock photo — needs bold text readability
    if (isFirst) {
        // Try stock photo first, fall back to gradient
        const stockBg = await getStockPhotoBackground(angle, slideNum);
        if (stockBg) return stockBg;
        return await getGradientBackground(slideNum, ideaId, true, false);
    }

    // Last slide (CTA): Soft branded gradient with logo
    if (isLast) {
        return await getGradientBackground(slideNum, ideaId, false, true);
    }

    // Slide 2-3: Feature showcase — use real app screenshots as blurred bg
    if (slideNum <= 3 && slideNum > 1) {
        const appBg = await getAppScreenshotBackground(angle, slideNum, ideaId);
        if (appBg) return appBg;
    }

    // Middle slides: Alternate between stock photos and gradients
    if (slideNum % 2 === 0) {
        const stockBg = await getStockPhotoBackground(angle, slideNum);
        if (stockBg) return stockBg;
    }

    // Fallback: Beautiful gradient
    return await getGradientBackground(slideNum, ideaId, false, false);
}

// ==========================================================
// TEXT OVERLAY — Professional typography
// ==========================================================
async function overlayTextOnImage(bgPath, text, slideNum, ideaId, isFirst, isLast) {
    const fontSize = isFirst ? 76 : (isLast ? 60 : 58);
    const maxWidth = SLIDE_WIDTH - 140; // 70px padding each side
    const words = text.split(' ');

    // Word-wrap
    const lines = [];
    let currentLine = '';
    const charsPerLine = Math.floor(maxWidth / (fontSize * 0.52));

    for (const word of words) {
        if ((currentLine + ' ' + word).trim().length > charsPerLine) {
            if (currentLine) lines.push(currentLine.trim());
            currentLine = word;
        } else {
            currentLine = (currentLine + ' ' + word).trim();
        }
    }
    if (currentLine) lines.push(currentLine.trim());

    const lineHeight = fontSize * 1.35;
    const totalTextHeight = lines.length * lineHeight;
    let startY;

    if (isFirst) {
        // Hook text positioned slightly above center for impact
        startY = (SLIDE_HEIGHT - totalTextHeight) / 2 - 80;
    } else if (isLast) {
        // CTA text positioned in upper-center to leave room for logo below
        startY = SLIDE_HEIGHT * 0.2;
    } else {
        startY = (SLIDE_HEIGHT - totalTextHeight) / 2;
    }

    // Determine text color and style
    const textColor = isLast ? BRAND.dark : BRAND.white;
    const shadowColor = isLast ? 'rgba(0,0,0,0.15)' : 'rgba(0,0,0,0.9)';
    const shadowBlur = isLast ? 4 : 10;

    // Build text elements
    const textElements = lines.map((line, i) => {
        const y = startY + (i * lineHeight) + fontSize;
        return `
            <text x="50%" y="${y}" 
                font-family="'Segoe UI', 'Helvetica Neue', Arial, sans-serif" 
                font-size="${fontSize}" 
                font-weight="800" 
                fill="${textColor}" 
                text-anchor="middle"
                letter-spacing="-1"
                filter="url(#textShadow)">
                ${escapeXml(line)}
            </text>`;
    }).join('');

    // Semi-transparent overlay for photo backgrounds
    const needsOverlay = !isLast;
    const overlayOpacity = isFirst ? 0.55 : 0.50;

    // Build overlay with gradient fade (darker in text area, lighter elsewhere)
    const overlayRect = needsOverlay ? `
        <defs>
            <linearGradient id="fadeOverlay" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="black" stop-opacity="0.3" />
                <stop offset="30%" stop-color="black" stop-opacity="${overlayOpacity}" />
                <stop offset="70%" stop-color="black" stop-opacity="${overlayOpacity}" />
                <stop offset="100%" stop-color="black" stop-opacity="0.3" />
            </linearGradient>
        </defs>
        <rect width="100%" height="100%" fill="url(#fadeOverlay)" />
    ` : '';

    // Add a subtle brand accent line on first slide
    const accentLine = isFirst ? `
        <rect x="${SLIDE_WIDTH / 2 - 40}" y="${startY - 50}" width="80" height="4" rx="2" fill="${BRAND.pink}" opacity="0.9" />
    ` : '';

    const overlaySvg = `<svg width="${SLIDE_WIDTH}" height="${SLIDE_HEIGHT}" xmlns="http://www.w3.org/2000/svg">
        <defs>
            <filter id="textShadow" x="-20%" y="-20%" width="140%" height="140%">
                <feDropShadow dx="0" dy="3" stdDeviation="${shadowBlur}" flood-color="${shadowColor}" flood-opacity="0.9"/>
            </filter>
        </defs>
        ${overlayRect}
        ${accentLine}
        ${textElements}
    </svg>`;

    const finalPath = path.join(SLIDES_DIR, `slide_${ideaId}_s${slideNum}.png`);

    // Composite layers
    const composites = [{
        input: Buffer.from(overlaySvg),
        top: 0,
        left: 0,
    }];

    // Add SafeMama logo on CTA (last) slides
    if (isLast) {
        const logoPath = path.join(ASSETS_DIR, LOGO_FILE);
        if (fs.existsSync(logoPath)) {
            try {
                const logoBuffer = await sharp(logoPath)
                    .resize(280, 280, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
                    .png()
                    .toBuffer();

                composites.push({
                    input: logoBuffer,
                    top: Math.floor(SLIDE_HEIGHT * 0.55),
                    left: Math.floor((SLIDE_WIDTH - 280) / 2),
                });

                // Add "Download SafeMama" text below logo
                const ctaSvg = `<svg width="${SLIDE_WIDTH}" height="120" xmlns="http://www.w3.org/2000/svg">
                    <text x="50%" y="50" 
                        font-family="'Segoe UI', Arial, sans-serif" 
                        font-size="36" 
                        font-weight="700" 
                        fill="${BRAND.purple}" 
                        text-anchor="middle">
                        Download SafeMama
                    </text>
                    <text x="50%" y="95" 
                        font-family="'Segoe UI', Arial, sans-serif" 
                        font-size="26" 
                        fill="${BRAND.pinkDark}" 
                        text-anchor="middle">
                        Free on App Store &amp; Google Play
                    </text>
                </svg>`;

                composites.push({
                    input: Buffer.from(ctaSvg),
                    top: Math.floor(SLIDE_HEIGHT * 0.55) + 290,
                    left: 0,
                });
            } catch (err) {
                console.warn(`  [Logo] Could not add logo: ${err.message}`);
            }
        }
    }

    // No watermark on content slides — the CTA slide has the full logo.
    // The logo file has a non-transparent background that looks odd on dark slides.

    await sharp(bgPath)
        .resize(SLIDE_WIDTH, SLIDE_HEIGHT, { fit: 'cover' })
        .composite(composites)
        .png({ quality: 95 })
        .toFile(finalPath);

    return finalPath;
}

// ==========================================================
// GENERATE SLIDES FOR A CONTENT IDEA
// ==========================================================
export async function generateSlidesForContent(contentIdea) {
    const ideaId = contentIdea.id;
    const slideTexts = JSON.parse(contentIdea.slide_texts || '[]');
    const angle = contentIdea.angle || 'education';

    console.log(`\n🎨 Generating ${slideTexts.length} slides for: "${contentIdea.hook}"`);
    console.log(`   Strategy: Pexels stock + real screenshots + gradients (NO DALL-E)`);

    const imagePaths = [];

    for (let i = 0; i < slideTexts.length; i++) {
        const slideNum = i + 1;
        const text = slideTexts[i];
        const isLastSlide = i === slideTexts.length - 1;
        const isFirstSlide = i === 0;

        try {
            console.log(`  [Slide ${slideNum}/${slideTexts.length}] "${text.substring(0, 50)}..."`);

            // Get background using smart selection
            const bgPath = await getBackgroundForSlide(
                slideNum, slideTexts.length,
                isFirstSlide, isLastSlide,
                ideaId, angle
            );

            // Overlay professional text
            const finalPath = await overlayTextOnImage(
                bgPath, text, slideNum, ideaId,
                isFirstSlide, isLastSlide
            );

            imagePaths.push(finalPath);

            // Save to DB
            insertSlide({
                content_idea_id: ideaId,
                slide_number: slideNum,
                image_path: finalPath,
                text_overlay: text,
                image_prompt: `Strategy: stock+screenshot+gradient | Angle: ${angle}`,
            });

            console.log(`  [Slide ${slideNum}] ✅ Done`);

        } catch (err) {
            console.error(`  [Slide ${slideNum}] ❌ Failed: ${err.message}`);
            // Fallback: gradient + text (always works)
            try {
                const gradBg = await getGradientBackground(slideNum, ideaId, isFirstSlide, isLastSlide);
                const fallbackPath = await overlayTextOnImage(
                    gradBg, text, slideNum, ideaId, isFirstSlide, isLastSlide
                );
                imagePaths.push(fallbackPath);

                insertSlide({
                    content_idea_id: ideaId,
                    slide_number: slideNum,
                    image_path: fallbackPath,
                    text_overlay: text,
                    image_prompt: 'fallback-gradient',
                });
            } catch (fallbackErr) {
                console.error(`  [Slide ${slideNum}] ❌ Even fallback failed: ${fallbackErr.message}`);
            }
        }

        // Small delay between slides (for Pexels rate limiting)
        await new Promise(r => setTimeout(r, 800));
    }

    // Update content status
    updateContentStatus(ideaId, 'generated');

    // Send carousel preview to Telegram
    if (imagePaths.length > 0) {
        const caption = `🎨 <b>Slides Ready!</b> (Pro Quality)\nAngle: ${contentIdea.angle}\nHook: "${contentIdea.hook}"\n\n${contentIdea.caption || ''}\n\n${contentIdea.hashtags || ''}`;
        await sendSlideCarousel(imagePaths.slice(0, 10), caption);
    }

    console.log(`🎨 ✅ All ${imagePaths.length} slides generated for: "${contentIdea.hook}"`);
    return imagePaths;
}

// ==========================================================
// GENERATE ALL PENDING SLIDES
// ==========================================================
export async function generateAllPendingSlides() {
    const drafts = getDraftContent(10);
    if (drafts.length === 0) {
        console.log('[Slides] No draft content to generate slides for.');
        return;
    }

    console.log(`\n🎨 Generating slides for ${drafts.length} content ideas...`);
    console.log(`   Using: Pexels stock photos + real SafeMama screenshots + gradient designs`);
    console.log(`   NO DALL-E = NO gibberish text = professional quality`);
    await sendMessage(`🎨 <b>Generating ${drafts.length} posts...</b>\n📸 Real stock photos + app screenshots\n🚫 Zero AI-generated backgrounds`);

    for (const draft of drafts) {
        try {
            await generateSlidesForContent(draft);
        } catch (err) {
            console.error(`[Slides] ❌ Failed for "${draft.hook}": ${err.message}`);
        }
        await new Promise(r => setTimeout(r, 3000));
    }

    console.log(`[Slides] ✅ All pending slides generated!`);
    await sendMessage(`✅ <b>All slides generated!</b> Professional quality, ready for posting.`);
}

// ==========================================================
// XML ESCAPE HELPER
// ==========================================================
function escapeXml(str) {
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
}

export default { generateSlidesForContent, generateAllPendingSlides };
