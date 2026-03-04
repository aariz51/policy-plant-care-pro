// ==========================================================
// database.js — SQLite database for marketing agent
// ==========================================================
import Database from 'better-sqlite3';
import { existsSync, mkdirSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, '..', 'data');
if (!existsSync(DATA_DIR)) mkdirSync(DATA_DIR, { recursive: true });

const db = new Database(path.join(DATA_DIR, 'marketing.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// ---- SCHEMA ----
db.exec(`
    -- Research reports
    CREATE TABLE IF NOT EXISTS research_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        research_type TEXT NOT NULL,           -- 'competitor', 'audience', 'trend', 'review_mining', 'reddit'
        platform TEXT,                          -- 'tiktok', 'instagram', 'appstore', 'reddit'
        raw_data TEXT,                          -- JSON: raw findings
        insights TEXT,                          -- JSON: AI-analyzed insights
        top_angles TEXT,                        -- JSON: best content angles found
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- Content ideas (generated from research)
    CREATE TABLE IF NOT EXISTS content_ideas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        angle TEXT NOT NULL,                    -- 'pain_awareness', 'myth_busting', 'before_after', 'micro_wins', 'mistake_based'
        hook TEXT NOT NULL,                     -- First slide text (the hook)
        slide_texts TEXT NOT NULL,              -- JSON: array of text for each slide
        caption TEXT,                           -- Instagram/TikTok caption
        hashtags TEXT,                          -- Comma-separated hashtags
        target_platform TEXT DEFAULT 'both',    -- 'tiktok', 'instagram', 'both'
        priority_score REAL DEFAULT 0,          -- Higher = post first (based on predicted performance)
        status TEXT DEFAULT 'draft',            -- 'draft', 'approved', 'generated', 'posted', 'skipped'
        performance_prediction TEXT,            -- JSON: predicted views/engagement
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- Generated slides (actual image files)
    CREATE TABLE IF NOT EXISTS generated_slides (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_idea_id INTEGER REFERENCES content_ideas(id),
        slide_number INTEGER NOT NULL,          -- 1-7 (position in carousel)
        image_path TEXT NOT NULL,               -- File path to generated image
        text_overlay TEXT,                      -- Text shown on the slide
        image_prompt TEXT,                      -- AI prompt used to generate background
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- Posts (tracking what was posted where)
    CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_idea_id INTEGER REFERENCES content_ideas(id),
        platform TEXT NOT NULL,                 -- 'tiktok', 'instagram'
        post_url TEXT,                          -- URL of the posted content
        posted_at DATETIME,
        status TEXT DEFAULT 'pending',          -- 'pending', 'posted', 'failed', 'scheduled'
        error TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- Analytics (performance tracking)
    CREATE TABLE IF NOT EXISTS post_analytics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER REFERENCES posts(id),
        views INTEGER DEFAULT 0,
        likes INTEGER DEFAULT 0,
        comments INTEGER DEFAULT 0,
        shares INTEGER DEFAULT 0,
        saves INTEGER DEFAULT 0,
        checked_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- Optimization log (self-improvement tracking)
    CREATE TABLE IF NOT EXISTS optimization_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis TEXT NOT NULL,                 -- JSON: what worked, what didn't
        recommendations TEXT NOT NULL,          -- JSON: AI recommendations
        applied_changes TEXT,                   -- JSON: what was actually changed
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
`);

// ---- HELPERS ----
export function insertResearch(data) {
    return db.prepare(`
        INSERT INTO research_reports (research_type, platform, raw_data, insights, top_angles)
        VALUES (?, ?, ?, ?, ?)
    `).run(data.research_type, data.platform, JSON.stringify(data.raw_data), JSON.stringify(data.insights), JSON.stringify(data.top_angles));
}

export function insertContentIdea(idea) {
    return db.prepare(`
        INSERT INTO content_ideas (angle, hook, slide_texts, caption, hashtags, target_platform, priority_score, performance_prediction)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(idea.angle, idea.hook, JSON.stringify(idea.slide_texts), idea.caption, idea.hashtags, idea.target_platform || 'both', idea.priority_score || 0, JSON.stringify(idea.performance_prediction || {}));
}

export function insertSlide(slide) {
    return db.prepare(`
        INSERT INTO generated_slides (content_idea_id, slide_number, image_path, text_overlay, image_prompt)
        VALUES (?, ?, ?, ?, ?)
    `).run(slide.content_idea_id, slide.slide_number, slide.image_path, slide.text_overlay, slide.image_prompt);
}

export function insertPost(post) {
    return db.prepare(`
        INSERT INTO posts (content_idea_id, platform, status)
        VALUES (?, ?, ?)
    `).run(post.content_idea_id, post.platform, post.status || 'pending');
}

export function updatePostStatus(postId, status, postUrl = null, error = null) {
    if (status === 'posted') {
        db.prepare(`UPDATE posts SET status = ?, post_url = ?, posted_at = CURRENT_TIMESTAMP WHERE id = ?`).run(status, postUrl, postId);
    } else {
        db.prepare(`UPDATE posts SET status = ?, error = ? WHERE id = ?`).run(status, error, postId);
    }
}

export function updateContentStatus(ideaId, status) {
    db.prepare(`UPDATE content_ideas SET status = ? WHERE id = ?`).run(status, ideaId);
}

export function insertAnalytics(data) {
    return db.prepare(`
        INSERT INTO post_analytics (post_id, views, likes, comments, shares, saves)
        VALUES (?, ?, ?, ?, ?, ?)
    `).run(data.post_id, data.views, data.likes, data.comments, data.shares, data.saves);
}

export function insertOptimization(data) {
    return db.prepare(`
        INSERT INTO optimization_log (analysis, recommendations, applied_changes)
        VALUES (?, ?, ?)
    `).run(JSON.stringify(data.analysis), JSON.stringify(data.recommendations), JSON.stringify(data.applied_changes || {}));
}

export function getNextContentToPost() {
    return db.prepare(`
        SELECT * FROM content_ideas 
        WHERE status = 'generated' 
        ORDER BY priority_score DESC 
        LIMIT 1
    `).get();
}

export function getPendingPosts() {
    return db.prepare(`SELECT * FROM posts WHERE status = 'pending' ORDER BY created_at ASC`).all();
}

export function getRecentPosts(limit = 20) {
    return db.prepare(`
        SELECT p.*, ci.angle, ci.hook, ci.slide_texts
        FROM posts p
        JOIN content_ideas ci ON p.content_idea_id = ci.id
        WHERE p.status = 'posted'
        ORDER BY p.posted_at DESC
        LIMIT ?
    `).all(limit);
}

export function getPerformanceStats() {
    return db.prepare(`
        SELECT 
            ci.angle,
            COUNT(p.id) as total_posts,
            AVG(pa.views) as avg_views,
            AVG(pa.likes) as avg_likes,
            AVG(pa.shares) as avg_shares,
            AVG(pa.saves) as avg_saves,
            MAX(pa.views) as best_views
        FROM posts p
        JOIN content_ideas ci ON p.content_idea_id = ci.id
        LEFT JOIN post_analytics pa ON p.id = pa.post_id
        WHERE p.status = 'posted'
        GROUP BY ci.angle
        ORDER BY avg_views DESC
    `).all();
}

export function getLatestResearch(type = null) {
    if (type) {
        return db.prepare(`SELECT * FROM research_reports WHERE research_type = ? ORDER BY created_at DESC LIMIT 1`).get(type);
    }
    return db.prepare(`SELECT * FROM research_reports ORDER BY created_at DESC LIMIT 5`).all();
}

export function getDraftContent(limit = 10) {
    return db.prepare(`SELECT * FROM content_ideas WHERE status = 'draft' ORDER BY priority_score DESC LIMIT ?`).all(limit);
}

export function getSlidesForContent(contentId) {
    return db.prepare(`SELECT * FROM generated_slides WHERE content_idea_id = ? ORDER BY slide_number ASC`).all(contentId);
}

export default db;
