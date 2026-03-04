# SafeMama Marketing Agent — OpenClaw

AI-powered marketing automation for **SafeMama** (pregnancy safety app).

## 🧠 What It Does

1. **Market Research** — AI analyzes competitors, audience language, content angles, and viral hooks
2. **Content Generation** — AI creates 5-7 slide carousel concepts with hooks, text overlays, captions & hashtags
3. **Slide Image Generation** — DALL-E creates stunning background images, Sharp overlays bold text
4. **Auto-Posting** — Playwright opens your Chrome and posts to TikTok + Instagram as a human
5. **Telegram Reports** — Every step is reported to your Telegram bot
6. **Self-Optimization** — Analyzes what worked and adjusts future content accordingly

## 📐 Architecture

```
aariz-marketing/
├── src/
│   ├── index.js            # Main scheduler & pipeline
│   ├── config.js           # Environment configuration
│   ├── database.js         # SQLite with full schema
│   ├── researcher.js       # AI market research engine
│   ├── content-engine.js   # Slide content idea generator
│   ├── slide-generator.js  # DALL-E backgrounds + text overlays
│   ├── poster.js           # Browser automation (TikTok + Instagram)
│   ├── analytics.js        # Performance tracking + optimization
│   └── telegram.js         # Telegram notifications
├── data/
│   ├── marketing.db        # SQLite database
│   ├── slides/             # Generated slide images
│   └── research/           # Research reports
└── .env                    # API keys & config
```

## 🚀 Getting Started

```bash
# Install dependencies
npm install

# Copy and fill in your .env
cp .env.example .env

# Run full pipeline (research → generate → slides → post loop)
npm start

# Or run individual stages:
npm run research    # Market research only
npm run content     # Content generation only
npm run slides      # Slide image generation only
npm run post        # Post next ready content
```

## ⚙️ Configuration

Set in `.env`:
- `POSTS_PER_DAY` — How many posts per day (default: 2)
- `POST_TIMES` — Comma-separated post times (default: 10:00,18:00)
- `TIMEZONE` — Your timezone (default: Asia/Kolkata)

## 🖼️ Content Rules

- **NO human faces, figures, or body parts** in any generated image (religious requirement)
- Only products, ingredients, objects, surfaces
- Bold white text with dark shadow overlay
- 1080x1920 portrait format (TikTok/Instagram ready)
- 5-7 slides per carousel following the viral hook → problem → solution → CTA formula

## 📊 Self-Optimization

Every 3 post cycles, the agent:
1. Analyzes which angles/hooks performed best
2. Doubles down on winning content types
3. Generates new content optimized based on data
4. Adjusts posting strategy automatically

## 📱 Platforms

- **TikTok** — Posts via browser automation (Playwright)
- **Instagram** — Posts via browser automation (Playwright)
- Both platforms posted to simultaneously
- Requires being logged into both in Chrome with `--remote-debugging-port=9222`

## 💬 Telegram Reports

You receive:
- 🔬 Market research summaries
- 🎨 Content idea previews
- 🖼️ Slide carousel previews (actual images)
- ✅ Post success notifications
- 📈 Performance reports
- ❌ Error alerts
