// ==========================================================
// content-engine.js — AI Content Generation for SafeMama
// ==========================================================
// Uses research findings to generate slide content ideas
// Each idea has: hook, 5-7 slide texts, caption, hashtags
// ==========================================================
import OpenAI from 'openai';
import config from './config.js';
import { insertContentIdea, getLatestResearch, getDraftContent } from './database.js';
import { sendContentIdea, sendMessage } from './telegram.js';

const openai = new OpenAI({ apiKey: config.openai.apiKey });

// ==========================================================
// SLIDE STRUCTURE TEMPLATE (Based on viral formula)
// ==========================================================
const SLIDE_STRUCTURE = `
## PROVEN VIRAL SLIDE STRUCTURE (5-7 slides):

SLIDE 1 — HOOK (Make them stop scrolling)
- Call out a pain, challenge a belief, or create massive curiosity
- Under 15 words
- Casual, spoken-word tone
- NO app name here
- Example: "I scanned my pregnancy moisturizer... the results shocked me"

SLIDE 2 — RELATABILITY (Make them say "that's me")
- Show you understand their situation
- Use audience language (exact phrases pregnant women say)
- Example: "I used this every single day of my first trimester"

SLIDE 3 — PROBLEM AMPLIFICATION (Show the consequence)
- Make the problem feel urgent
- Show what happens if they don't act
- Example: "turns out it contains retinol — an ingredient linked to birth defects"

SLIDE 4 — REFRAME / INSIGHT (New way of thinking)
- Introduce new information or perspective
- Position the problem as solvable
- Example: "most products don't warn you about pregnancy safety"

SLIDE 5 — SOFT SOLUTION (Introduce SafeMama without selling)
- Show the scan result / app screenshot concept
- Make it feel like a discovery, not an ad
- Example: "so I downloaded SafeMama and scanned everything in my bathroom"

SLIDE 6 — BENEFIT (What they gain — NOT features)
- Show the relief, peace of mind, confidence
- Example: "now I know exactly what's safe for me and my baby ✅"

SLIDE 7 — CTA (Soft, friendly)
- "SafeMama — link in bio"
- "Try it once — it's free"
- "Protect your baby 💛 link in bio"
`;

const CONTENT_RULES = `
## STRICT CONTENT RULES:
1. NO human faces or figures in any image description — NON-NEGOTIABLE
2. Text overlays: bold white text with dark shadow, centered on slide
3. Background images: product close-ups, ingredient lists, bathroom shelves, cosmetic bottles, food items, supplement bottles, blank aesthetic backgrounds
4. Tone: casual, warm, concerned-friend energy (NOT medical/clinical/scary)
5. Every post drives toward SafeMama download without being pushy
6. Last slide ALWAYS mentions SafeMama by name + "link in bio"
7. Language: simple English, no jargon, grade 6 reading level
8. Emotional journey: curiosity → revelation → concern → solution → relief
`;

// ==========================================================
// GENERATE BATCH OF CONTENT IDEAS
// ==========================================================
export async function generateContentBatch(count = 5) {
    console.log(`\n🎨 Generating ${count} content ideas...`);
    await sendMessage(`🎨 <b>Generating ${count} new content ideas...</b>`);

    // Pull latest research
    const latestResearch = getLatestResearch();
    let researchContext = '';

    if (latestResearch.length > 0) {
        researchContext = `\n## LATEST RESEARCH FINDINGS:\n`;
        for (const r of latestResearch) {
            try {
                const insights = JSON.parse(r.insights || '[]');
                const angles = JSON.parse(r.top_angles || '[]');
                researchContext += `\n### ${r.research_type} (${r.platform || 'all'}):\n`;
                researchContext += `Insights: ${insights.slice(0, 3).join(', ')}\n`;
                researchContext += `Top angles: ${angles.slice(0, 3).join(', ')}\n`;
            } catch { }
        }
    }

    // Check existing content to avoid duplicates
    const existingDrafts = getDraftContent(50);
    const existingHooks = existingDrafts.map(d => d.hook);
    const avoidList = existingHooks.length > 0
        ? `\n\n## AVOID THESE HOOKS (already used):\n${existingHooks.map(h => `- "${h}"`).join('\n')}`
        : '';

    const response = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [{
            role: 'user',
            content: `You are the #1 viral carousel/slide content creator for pregnancy apps on TikTok and Instagram. You create content that gets 100K+ views.

## APP INFORMATION:
- App: SafeMama
- What it does: AI-powered product safety scanner for pregnancy. Scan any barcode, ingredient list, or type manually → get pregnancy safety score + per-ingredient breakdown
- Also: AI pregnancy test checker, medical document analyzer, 15+ pregnancy tools
- Available: iOS App Store
- Tagline: AI-Powered Pregnancy Safety & Wellness Companion
- Target: Pregnant women 20-40 years old

${SLIDE_STRUCTURE}
${CONTENT_RULES}
${researchContext}
${avoidList}

## YOUR TASK:
Generate ${count} complete carousel/slide post concepts. Each must:
1. Follow the 5-7 slide structure above
2. Be unique (different angle, different product, different emotion)
3. Be ready to generate images for (with clear image descriptions)
4. Include a TikTok/Instagram caption with hashtags
5. Have a predicted engagement level

## MIX OF ANGLES (for ${count} posts):
- 2x Fear/Shock (hidden dangers in common products)
- 1x Curiosity (scanning challenge / reveal)
- 1x Education (things to avoid during pregnancy)
- 1x Relatability (pregnancy anxiety meets solution)
Adjust mix based on research findings if available.

## IMPORTANT IMAGE GUIDANCE:
For each slide, describe what IMAGE should be shown. REMEMBER:
- NO humans, NO faces, NO body parts
- Show: products, ingredient labels, phone screens, cosmetic bottles, bathroom shelves, food items, pill bottles, kitchen counters with products, close-ups of labels
- Style: clean, bright, lifestyle photography of OBJECTS

## RETURN FORMAT:
{
    "content_ideas": [
        {
            "angle": "fear_shock/curiosity/education/relatability/myth_busting/before_after",
            "hook": "first slide text (under 15 words)",
            "slides": [
                {
                    "slide_number": 1,
                    "text_overlay": "the text shown on this slide",
                    "image_description": "what the background image should show (NO HUMANS)"
                }
            ],
            "caption": "Instagram/TikTok caption text (2-3 sentences, emotional, with call to action)",
            "hashtags": "#pregnancy #pregnancysafe #safemama #momtobe #babysafety #pregnancytips",
            "predicted_engagement": "high/medium/low",
            "priority_score": 85,
            "reasoning": "why this will perform well"
        }
    ]
}

Return ONLY the JSON, no other text.`
        }],
        temperature: 0.9,
        max_tokens: 4000,
    });

    let result;
    try {
        result = JSON.parse(response.choices[0].message.content.replace(/```json\n?|\n?```/g, '').trim());
    } catch (err) {
        console.error('[Content] ❌ Failed to parse AI response:', err.message);
        console.log('[Content] Raw:', response.choices[0].message.content.substring(0, 200));
        return [];
    }

    const ideas = result.content_ideas || [];
    const savedIdeas = [];

    for (const idea of ideas) {
        try {
            const slideTexts = idea.slides.map(s => s.text_overlay);
            const dbResult = insertContentIdea({
                angle: idea.angle,
                hook: idea.hook,
                slide_texts: slideTexts,
                caption: idea.caption,
                hashtags: idea.hashtags,
                target_platform: 'both',
                priority_score: idea.priority_score || 50,
                performance_prediction: {
                    predicted_engagement: idea.predicted_engagement,
                    reasoning: idea.reasoning,
                },
            });

            const savedIdea = {
                id: dbResult.lastInsertRowid,
                ...idea,
                slide_texts: JSON.stringify(slideTexts),
            };
            savedIdeas.push(savedIdea);

            // Notify Telegram
            await sendContentIdea({
                angle: idea.angle,
                hook: idea.hook,
                slide_texts: JSON.stringify(slideTexts),
                caption: idea.caption,
                hashtags: idea.hashtags,
                priority_score: idea.priority_score,
                target_platform: 'both',
            });

            console.log(`[Content] ✅ Saved idea: "${idea.hook}" (score: ${idea.priority_score})`);
        } catch (err) {
            console.error(`[Content] ❌ Failed to save idea: ${err.message}`);
        }
    }

    console.log(`[Content] ✅ Generated ${savedIdeas.length}/${count} content ideas`);
    await sendMessage(`✅ <b>${savedIdeas.length} content ideas ready!</b>\nReady for slide generation.`);

    return savedIdeas;
}

// ==========================================================
// GENERATE OPTIMIZED CONTENT (based on performance data)
// ==========================================================
export async function generateOptimizedContent(optimizationData, count = 3) {
    console.log('[Content] 🧠 Generating optimized content based on performance...');

    const response = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [{
            role: 'user',
            content: `You are a data-driven content creator. Based on our performance analysis, create ${count} new content ideas that are optimized for maximum engagement.

## APP: SafeMama (AI-powered pregnancy safety scanner)

## OPTIMIZATION DATA:
${JSON.stringify(optimizationData, null, 2)}

${SLIDE_STRUCTURE}
${CONTENT_RULES}

Based on the optimization data:
- Focus on angles that performed BEST
- Apply the recommended changes
- Avoid patterns from low-performing content
- Double down on what works

## RETURN FORMAT:
{
    "content_ideas": [
        {
            "angle": "angle_name",
            "hook": "hook text",
            "slides": [
                { "slide_number": 1, "text_overlay": "text", "image_description": "image desc (NO HUMANS)" }
            ],
            "caption": "caption text",
            "hashtags": "hashtags",
            "predicted_engagement": "high/medium",
            "priority_score": 90,
            "optimization_applied": "what optimization insight was used"
        }
    ]
}

Return ONLY the JSON.`
        }],
        temperature: 0.8,
        max_tokens: 3000,
    });

    const result = JSON.parse(response.choices[0].message.content.replace(/```json\n?|\n?```/g, '').trim());
    const ideas = result.content_ideas || [];

    for (const idea of ideas) {
        const slideTexts = idea.slides.map(s => s.text_overlay);
        insertContentIdea({
            angle: idea.angle,
            hook: idea.hook,
            slide_texts: slideTexts,
            caption: idea.caption,
            hashtags: idea.hashtags,
            target_platform: 'both',
            priority_score: idea.priority_score || 70,
            performance_prediction: { predicted_engagement: idea.predicted_engagement, optimization: idea.optimization_applied },
        });
        console.log(`[Content] ✅ Optimized idea: "${idea.hook}"`);
    }

    return ideas;
}

export default { generateContentBatch, generateOptimizedContent };
