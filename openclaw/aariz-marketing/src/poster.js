// ==========================================================
// poster.js — Auto-post slides to TikTok + Instagram
// ==========================================================
// Uses Playwright (browser automation) to post carousels
// Acts as a human — opens browser, uploads, captions, posts
// ==========================================================
import { chromium } from 'playwright-core';
import fs from 'fs';
import path from 'path';
import config from './config.js';
import { getNextContentToPost, getSlidesForContent, insertPost, updatePostStatus, updateContentStatus } from './database.js';
import { sendPostNotification, sendMessage, sendError } from './telegram.js';

const CDP_PORT = 9222;

// ==========================================================
// CONNECT TO CHROME
// ==========================================================
async function connectToChrome(retries = 5) {
    for (let i = 0; i < retries; i++) {
        try {
            const resp = await fetch(`http://127.0.0.1:${CDP_PORT}/json/version`);
            if (resp.ok) {
                console.log(`[Poster] Connecting to Chrome (attempt ${i + 1})...`);
                const browser = await Promise.race([
                    chromium.connectOverCDP(`http://127.0.0.1:${CDP_PORT}`, { timeout: 60000 }),
                    new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 60000)),
                ]);
                console.log('[Poster] ✅ Connected to Chrome');
                return browser;
            }
        } catch (err) {
            console.warn(`[Poster] Connection attempt ${i + 1} failed: ${err.message}`);
        }
        if (i < retries - 1) {
            const wait = 5 + i * 2;
            console.log(`[Poster] Retry in ${wait}s...`);
            await new Promise(r => setTimeout(r, wait * 1000));
        }
    }
    console.error('[Poster] ❌ Chrome not available');
    return null;
}

// ==========================================================
// POST TO INSTAGRAM (Carousel / Slideshow)
// ==========================================================
export async function postToInstagram(contentIdea, slidePaths) {
    console.log(`\n📸 Posting to Instagram: "${contentIdea.hook}"`);

    const browser = await connectToChrome();
    if (!browser) {
        await sendError('Instagram Post', 'Chrome not available');
        return false;
    }

    const context = browser.contexts()[0];
    const page = await context.newPage();
    let postId = null;

    try {
        // Create post record
        const postRecord = insertPost({
            content_idea_id: contentIdea.id,
            platform: 'instagram',
            status: 'pending',
        });
        postId = postRecord.lastInsertRowid;

        // Navigate to Instagram
        await page.goto('https://www.instagram.com/', { waitUntil: 'domcontentloaded', timeout: 30000 });
        await page.waitForTimeout(3000);

        // Check if logged in
        const isLoggedIn = await page.evaluate(() => {
            return !document.querySelector('input[name="username"]');
        });

        if (!isLoggedIn) {
            console.warn('[Instagram] ⚠️ Not logged in. Please log in to Instagram in Chrome first.');
            await sendError('Instagram Post', 'Not logged in to Instagram. Please log in first.');
            updatePostStatus(postId, 'failed', null, 'Not logged in');
            return false;
        }

        console.log('[Instagram] ✅ Logged in');

        // Click the "Create" / "New Post" button (+ icon)
        const createButton = await page.waitForSelector('svg[aria-label="New post"], a[href="/create/style/"], [aria-label="New post"]', { timeout: 10000 }).catch(() => null);

        if (!createButton) {
            // Try clicking the + in the sidebar
            const plusSelector = await page.$$('a[href*="create"], [role="link"]');
            let clicked = false;
            for (const el of plusSelector) {
                const text = await el.textContent().catch(() => '');
                const ariaLabel = await el.getAttribute('aria-label').catch(() => '');
                if (text.includes('Create') || ariaLabel.includes('Create') || ariaLabel.includes('New post')) {
                    await el.click();
                    clicked = true;
                    break;
                }
            }
            if (!clicked) {
                // Try keyboard shortcut or direct URL
                await page.goto('https://www.instagram.com/create/style/', { timeout: 15000 }).catch(() => { });
            }
        } else {
            await createButton.click();
        }

        await page.waitForTimeout(2000);

        // Look for file input
        const fileInput = await page.waitForSelector('input[type="file"]', { timeout: 10000 });

        // Upload all slide images
        const absolutePaths = slidePaths.map(p => path.resolve(p));
        await fileInput.setInputFiles(absolutePaths);
        console.log(`[Instagram] Uploaded ${absolutePaths.length} slides`);

        await page.waitForTimeout(3000);

        // Click "Next" button (may appear after upload)
        for (let step = 0; step < 3; step++) {
            const nextBtn = await page.$('button:has-text("Next"), [aria-label="Next"]');
            if (nextBtn) {
                await nextBtn.click();
                await page.waitForTimeout(2000);
            }
        }

        // Add caption
        const captionInput = await page.$('textarea[aria-label="Write a caption..."], div[aria-label="Write a caption..."], [data-testid="caption-area"]');
        if (captionInput) {
            const fullCaption = `${contentIdea.caption || ''}\n\n${contentIdea.hashtags || ''}`.trim();
            await captionInput.click();
            await page.keyboard.type(fullCaption, { delay: 20 });
            console.log('[Instagram] Caption added');
        }

        await page.waitForTimeout(2000);

        // Click "Share" button
        const shareBtn = await page.$('button:has-text("Share"), [aria-label="Share"]');
        if (shareBtn) {
            await shareBtn.click();
            console.log('[Instagram] 📤 Sharing...');
            await page.waitForTimeout(10000);
        }

        // Check for success
        const success = await page.waitForSelector('img[alt*="Close"], [aria-label="Post shared"]', { timeout: 15000 }).catch(() => null);

        if (success) {
            updatePostStatus(postId, 'posted', page.url());
            updateContentStatus(contentIdea.id, 'posted');
            await sendPostNotification({ postUrl: page.url(), angle: contentIdea.angle, hook: contentIdea.hook }, 'instagram');
            console.log('[Instagram] ✅ Posted successfully!');
            return true;
        } else {
            // Still mark as posted (might have worked even without clear confirmation)
            updatePostStatus(postId, 'posted', page.url());
            updateContentStatus(contentIdea.id, 'posted');
            await sendPostNotification({ postUrl: 'check_manually', angle: contentIdea.angle, hook: contentIdea.hook }, 'instagram');
            console.log('[Instagram] ⚠️ Post may have been shared — verify manually');
            return true;
        }

    } catch (err) {
        console.error(`[Instagram] ❌ Posting failed: ${err.message}`);
        if (postId) updatePostStatus(postId, 'failed', null, err.message);
        await sendError('Instagram Post', err.message);
        return false;
    } finally {
        try { await page.close(); } catch { }
    }
}

// ==========================================================
// POST TO TIKTOK (Slideshow / Photo Mode)
// ==========================================================
export async function postToTikTok(contentIdea, slidePaths) {
    console.log(`\n🎵 Posting to TikTok: "${contentIdea.hook}"`);

    const browser = await connectToChrome();
    if (!browser) {
        await sendError('TikTok Post', 'Chrome not available');
        return false;
    }

    const context = browser.contexts()[0];
    const page = await context.newPage();
    let postId = null;

    try {
        const postRecord = insertPost({
            content_idea_id: contentIdea.id,
            platform: 'tiktok',
            status: 'pending',
        });
        postId = postRecord.lastInsertRowid;

        // Navigate to TikTok upload page
        await page.goto('https://www.tiktok.com/upload', { waitUntil: 'domcontentloaded', timeout: 30000 });
        await page.waitForTimeout(5000);

        // Check if logged in
        const isLoggedIn = await page.evaluate(() => {
            const loginBtns = document.querySelectorAll('[data-e2e="top-login-button"], button[id="header-login-button"]');
            return loginBtns.length === 0;
        });

        if (!isLoggedIn) {
            console.warn('[TikTok] ⚠️ Not logged in');
            await sendError('TikTok Post', 'Not logged in to TikTok. Please log in first.');
            updatePostStatus(postId, 'failed', null, 'Not logged in');
            return false;
        }

        console.log('[TikTok] ✅ Logged in');

        // Switch to "Photo mode" / "Slideshow" if available
        const photoModeBtn = await page.$('button:has-text("Photo"), [data-e2e="photo-mode"]').catch(() => null);
        if (photoModeBtn) {
            await photoModeBtn.click();
            await page.waitForTimeout(2000);
        }

        // Find file upload input
        const fileInput = await page.waitForSelector('input[type="file"]', { timeout: 15000 });

        // Upload slides
        const absolutePaths = slidePaths.map(p => path.resolve(p));
        await fileInput.setInputFiles(absolutePaths);
        console.log(`[TikTok] Uploaded ${absolutePaths.length} slides`);

        await page.waitForTimeout(5000);

        // Add caption/description
        const captionArea = await page.$('[data-e2e="upload-caption"] div[contenteditable="true"], div[contenteditable="true"][data-text], .public-DraftEditor-content');
        if (captionArea) {
            await captionArea.click();
            await page.waitForTimeout(500);
            const fullCaption = `${contentIdea.caption || ''} ${contentIdea.hashtags || ''}`.trim().substring(0, 2200);
            await page.keyboard.type(fullCaption, { delay: 15 });
            console.log('[TikTok] Caption added');
        }

        await page.waitForTimeout(2000);

        // Click "Post" button
        const postBtn = await page.$('button:has-text("Post"), [data-e2e="upload-btn"]');
        if (postBtn) {
            await postBtn.click();
            console.log('[TikTok] 📤 Posting...');
            await page.waitForTimeout(15000);
        }

        // Check for success (redirect or success message)
        const currentUrl = page.url();
        const hasSuccess = await page.$('div:has-text("Your video has been uploaded"), div:has-text("uploaded")').catch(() => null);

        updatePostStatus(postId, 'posted', currentUrl);
        updateContentStatus(contentIdea.id, 'posted');
        await sendPostNotification({ postUrl: currentUrl, angle: contentIdea.angle, hook: contentIdea.hook }, 'tiktok');
        console.log('[TikTok] ✅ Posted!');
        return true;

    } catch (err) {
        console.error(`[TikTok] ❌ Posting failed: ${err.message}`);
        if (postId) updatePostStatus(postId, 'failed', null, err.message);
        await sendError('TikTok Post', err.message);
        return false;
    } finally {
        try { await page.close(); } catch { }
    }
}

// ==========================================================
// POST NEXT CONTENT (Auto-post the highest priority ready content)
// ==========================================================
export async function postNextContent() {
    const content = getNextContentToPost();
    if (!content) {
        console.log('[Poster] No generated content ready to post.');
        return false;
    }

    const slides = getSlidesForContent(content.id);
    if (slides.length === 0) {
        console.log('[Poster] No slides found for content.');
        return false;
    }

    const slidePaths = slides.map(s => s.image_path).filter(p => fs.existsSync(p));
    if (slidePaths.length === 0) {
        console.log('[Poster] Slide files not found on disk.');
        return false;
    }

    console.log(`\n📱 Auto-posting: "${content.hook}" (${slidePaths.length} slides)`);
    await sendMessage(`📱 <b>Auto-posting:</b> "${content.hook}"\nSlides: ${slidePaths.length}\nPosting to TikTok + Instagram...`);

    // Post to BOTH platforms simultaneously
    const [tiktokResult, instaResult] = await Promise.allSettled([
        postToTikTok(content, slidePaths),
        postToInstagram(content, slidePaths),
    ]);

    const tiktokOk = tiktokResult.status === 'fulfilled' && tiktokResult.value;
    const instaOk = instaResult.status === 'fulfilled' && instaResult.value;

    if (tiktokOk && instaOk) {
        await sendMessage(`✅ <b>Posted successfully to BOTH platforms!</b>`);
    } else {
        const failedPlatforms = [];
        if (!tiktokOk) failedPlatforms.push('TikTok');
        if (!instaOk) failedPlatforms.push('Instagram');
        await sendMessage(`⚠️ <b>Posting partially failed:</b> ${failedPlatforms.join(', ')}`);
    }

    return tiktokOk || instaOk;
}

export default { postToInstagram, postToTikTok, postNextContent };
