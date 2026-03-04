// ==========================================================
// researcher.js — AI Market Research Engine for SafeMama
// ==========================================================
// Does: Competitive research, audience language mining,
//       trend analysis, content angle discovery
// ==========================================================
import OpenAI from 'openai';
import config from './config.js';
import { insertResearch, getLatestResearch, getPerformanceStats } from './database.js';
import { sendResearchReport, sendMessage } from './telegram.js';

const openai = new OpenAI({ apiKey: config.openai.apiKey });

// ==========================================================
// SAFEMAMA KNOWLEDGE BASE (from codebase analysis)
// ==========================================================
const SAFEMAMA_KNOWLEDGE = `
# SafeMama — AI-Powered Pregnancy Safety & Wellness Companion

## CORE FEATURES:
1. **AI Product Safety Scanner** — Scan ANY product via barcode, ingredient photo, or manual entry. Get pregnancy safety score (0-100), per-ingredient breakdown (safe🟢/caution🟡/avoid🔴), myth buster, doctor questions
2. **AI Pregnancy Test Checker** — Photo of test strip → instant AI result interpretation
3. **AI Medical Document Analyzer** — Upload ultrasounds, blood tests, prescriptions → pregnancy-specific AI interpretation
4. **Ask an Expert AI** — 24/7 pregnancy advisor with image attachment support
5. **Pregnancy Tracker Dashboard** — Week-by-week baby development, 3D baby view, daily logging
6. **15+ Pregnancy Tools** — Due date calculator, TTC tracker, kick counter, contraction timer, weight gain tracker, nutrition planner, mental health screening, hospital bag checklist, birth plan creator, vaccine tracker, postpartum tracker, baby name generator, baby shopping list
7. **Community Chat** — Real-time group chat for pregnant women
8. **Personalized AI Guides** — AI-generated pregnancy guides based on trimester, diet, allergies

## SUBSCRIPTION:
- Free: 3 scans, 3 expert queries
- Weekly: $1.99 | Monthly: $5.99 | Yearly: $39.99 (best value)

## USPs (What NO competitor has):
- Only app combining AI barcode + ingredient scanning specifically for pregnancy safety
- Only app with AI pregnancy test strip reading
- Only app with AI medical document analysis for pregnancy
- Dual AI engine (Google Gemini + OpenAI GPT-4o) with automatic failover
- 50+ features in ONE app

## APP STORE:
- iOS: https://apps.apple.com/app/safemama/id6748413103
- Android: Coming soon

## TARGET AUDIENCE:
- Pregnant women (all trimesters)
- Trying-to-conceive women
- New mothers (postpartum)
- Age: 20-40 years old
- Health-conscious, concerned about product safety
`;

// ==========================================================
// CONTENT RULES
// ==========================================================
const CONTENT_RULES = `
## STRICT RULES FOR ALL CONTENT:
1. NO human faces, no human figures visible — this is NON-NEGOTIABLE (religious requirement)
2. Focus on PRODUCTS, ingredients, phone screens, app mockups, abstract imagery
3. Never show the person — show what THEY SEE (the product, the screen, the result)
4. Use the "snugly" TikTok format: hook slide → problem → insight → solution → CTA
5. Every post must be emotionally driven — fear, curiosity, surprise, relief
6. Language should be casual, relatable, spoken-word style (like talking to a friend)
7. Always end with "link in bio" or "try it once" — soft CTA, never hard-sell
8. Products, cosmetics, food items, supplement bottles are PERFECT visual subjects
9. Include pregnancy-related products in imagery: lotions, vitamins, food, skincare
10. The image style should be: clean, bright, lifestyle photography of OBJECTS (not people)
`;

// ==========================================================
// 1. CORE RESEARCH: Competitive + Audience + Angles
// ==========================================================
export async function runFullResearch() {
    console.log('\n🔬 ═══════════════════════════════════════');
    console.log('   SafeMama Marketing Research Starting...');
    console.log('═══════════════════════════════════════════\n');

    await sendMessage('🔬 <b>Starting Full Market Research...</b>\nThis will take a few minutes.');

    // Get past performance to inform research
    const pastPerformance = getPerformanceStats();
    const performanceContext = pastPerformance.length > 0
        ? `\n\n## OUR PAST PERFORMANCE:\n${pastPerformance.map(p => `- ${p.angle}: ${p.total_posts} posts, avg ${Math.round(p.avg_views || 0)} views`).join('\n')}`
        : '\n\n## OUR PAST PERFORMANCE: No posts yet — this is our first research run.';

    try {
        // Run all research in parallel
        const [competitorRes, audienceRes, angleRes, hookRes] = await Promise.allSettled([
            doCompetitorResearch(performanceContext),
            doAudienceMining(performanceContext),
            doAngleDiscovery(performanceContext),
            doHookGeneration(performanceContext),
        ]);

        const results = {
            competitor: competitorRes.status === 'fulfilled' ? competitorRes.value : null,
            audience: audienceRes.status === 'fulfilled' ? audienceRes.value : null,
            angles: angleRes.status === 'fulfilled' ? angleRes.value : null,
            hooks: hookRes.status === 'fulfilled' ? hookRes.value : null,
        };

        // Log failures
        if (competitorRes.status === 'rejected') console.error('❌ Competitor research failed:', competitorRes.reason?.message);
        if (audienceRes.status === 'rejected') console.error('❌ Audience mining failed:', audienceRes.reason?.message);
        if (angleRes.status === 'rejected') console.error('❌ Angle discovery failed:', angleRes.reason?.message);
        if (hookRes.status === 'rejected') console.error('❌ Hook generation failed:', hookRes.reason?.message);

        // Compile and send report
        const compiledReport = compileResearchReport(results);
        await sendResearchReport(compiledReport);

        console.log('\n✅ Market research complete!');
        return compiledReport;

    } catch (err) {
        console.error('❌ Research failed:', err.message);
        await sendMessage(`❌ <b>Research failed:</b> ${err.message}`);
        return null;
    }
}

// ==========================================================
// 2. COMPETITOR RESEARCH
// ==========================================================
async function doCompetitorResearch(performanceContext) {
    console.log('[Research] 🏆 Running competitor analysis...');

    const response = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [{
            role: 'user',
            content: `You are a world-class social media marketing strategist specializing in health/pregnancy app marketing on TikTok and Instagram.

${SAFEMAMA_KNOWLEDGE}
${performanceContext}

## YOUR TASK:
Analyze the competitive landscape for pregnancy safety apps on TikTok and Instagram. Consider these competitor categories:

1. **Direct Competitors:** Ovia, The Bump, What to Expect, Pregnancy+, Glow Nurture, BabyCenter
2. **Indirect Competitors:** Yuka (food scanner), Think Dirty (ingredient scanner), general pregnancy influencers
3. **Content Competitors:** Pregnancy TikTok/Instagram creators, mommy bloggers, health influencers

For each, analyze:
- What content formats get the MOST views/engagement?
- What emotions do they trigger? (fear, curiosity, surprise, relief?)
- What patterns repeat in their top-performing posts?
- What gaps exist that SafeMama can fill?
- What words/phrases get the most engagement?

## FOCUS ON:
- Slide/carousel content specifically (no video analysis needed)
- Content that drives APP DOWNLOADS
- Content that goes VIRAL (25K+ views on TikTok)

Return your analysis as a JSON object with:
{
    "competitor_insights": ["insight1", "insight2", ...],
    "content_gaps": ["gap1", "gap2", ...],
    "winning_patterns": ["pattern1", "pattern2", ...],
    "emotional_triggers": ["trigger1", "trigger2", ...],
    "top_performing_formats": ["format1", "format2", ...]
}

Return ONLY the JSON, no other text.`
        }],
        temperature: 0.7,
        max_tokens: 2000,
    });

    const result = JSON.parse(response.choices[0].message.content.replace(/```json\n?|\n?```/g, '').trim());

    insertResearch({
        research_type: 'competitor',
        platform: 'tiktok_instagram',
        raw_data: result,
        insights: result.competitor_insights,
        top_angles: result.winning_patterns,
    });

    console.log('[Research] ✅ Competitor analysis complete');
    return result;
}

// ==========================================================
// 3. AUDIENCE LANGUAGE MINING
// ==========================================================
async function doAudienceMining(performanceContext) {
    console.log('[Research] 🗣️ Mining audience language...');

    const response = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [{
            role: 'user',
            content: `You are a copywriting expert specializing in audience language mining for pregnancy/maternal health apps.

${SAFEMAMA_KNOWLEDGE}
${performanceContext}

## YOUR TASK:
Mine the language that pregnant women ACTUALLY use when talking about:
1. Product safety concerns during pregnancy
2. Frustration with not knowing if something is safe
3. Pregnancy anxiety and worry
4. Finding out something they used was unsafe
5. Overwhelm with too much information

Think about what you would find on:
- App Store reviews for pregnancy apps
- Reddit (r/pregnant, r/BabyBumps, r/beyondthebump)
- TikTok comments on pregnancy content
- Instagram comments on mommy influencer posts
- Baby forums and Facebook groups

## PROVIDE:
{
    "pain_phrases": ["exact phrases women say about their pain/frustration", ...],
    "desire_phrases": ["what they WISH for / want", ...],
    "fear_phrases": ["what scares them about pregnancy safety", ...],
    "excitement_phrases": ["what excites them about helpful tools", ...],
    "frustration_phrases": ["what frustrates them about current solutions", ...],
    "question_phrases": ["the actual questions they ask", ...],
    "slang_and_tone": ["how they talk: casual phrases, abbreviations, emojis", ...],
    "recommended_tone_for_content": "description of the ideal tone for our content"
}

Return ONLY the JSON, no other text.`
        }],
        temperature: 0.8,
        max_tokens: 2000,
    });

    const result = JSON.parse(response.choices[0].message.content.replace(/```json\n?|\n?```/g, '').trim());

    insertResearch({
        research_type: 'audience',
        platform: 'all',
        raw_data: result,
        insights: [...(result.pain_phrases || []).slice(0, 5), ...(result.desire_phrases || []).slice(0, 5)],
        top_angles: result.fear_phrases || [],
    });

    console.log('[Research] ✅ Audience language mining complete');
    return result;
}

// ==========================================================
// 4. CONTENT ANGLE DISCOVERY
// ==========================================================
async function doAngleDiscovery(performanceContext) {
    console.log('[Research] 🎯 Discovering best content angles...');

    const response = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [{
            role: 'user',
            content: `You are a viral content strategist for TikTok and Instagram. You specialize in app promotion through slide/carousel posts.

${SAFEMAMA_KNOWLEDGE}
${CONTENT_RULES}
${performanceContext}

## TASK:
Based on the app features and target audience, identify the TOP 10 content angles that would perform best on TikTok and Instagram for SafeMama.

Each angle should:
- Be emotionally powerful
- Be repeatable (can make 20+ posts with same angle)
- Target a specific pain point or desire
- Work in slide/carousel format (5-7 slides)
- Drive app downloads

## PROVEN ANGLE CATEGORIES TO CONSIDER:
1. **Pain Awareness** — "You're unknowingly using unsafe products"
2. **Mistake-Based** — "Top 5 products pregnant women should NEVER use"
3. **Before vs After** — "Before vs after scanning my skincare routine"
4. **Myth Busting** — "This 'safe' ingredient is actually dangerous during pregnancy"
5. **Micro Wins** — "One scan that could protect your baby"
6. **Curiosity Gap** — "I scanned my entire bathroom cabinet... the results 😱"
7. **Fear/Shock** — "This popular moisturizer has a pregnancy-UNSAFE ingredient"
8. **Social Proof** — "Why 10K moms trust this app with their baby's safety"
9. **Education** — "3 ingredients to ALWAYS avoid when pregnant"
10. **Relatability** — "My pregnancy anxiety was out of control until I found this"

## RETURN:
{
    "top_angles": [
        {
            "name": "angle_name",
            "description": "what this angle is about",
            "emotional_trigger": "primary emotion it targets",
            "example_hooks": ["hook1", "hook2", "hook3"],
            "predicted_performance": "high/medium/low",
            "repeatability": "how many posts can we make with this angle"
        }
    ],
    "recommended_mix": "description of how to mix these angles (e.g., 40% fear, 30% curiosity, 20% education, 10% social proof)",
    "posting_order": "which angles to start with and why"
}

Return ONLY the JSON, no other text.`
        }],
        temperature: 0.7,
        max_tokens: 3000,
    });

    const result = JSON.parse(response.choices[0].message.content.replace(/```json\n?|\n?```/g, '').trim());

    insertResearch({
        research_type: 'angles',
        platform: 'both',
        raw_data: result,
        insights: result.top_angles.map(a => `${a.name}: ${a.description}`),
        top_angles: result.top_angles.map(a => a.name),
    });

    console.log('[Research] ✅ Angle discovery complete');
    return result;
}

// ==========================================================
// 5. VIRAL HOOK GENERATION
// ==========================================================
async function doHookGeneration(performanceContext) {
    console.log('[Research] 🎣 Generating viral hooks...');

    const response = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [{
            role: 'user',
            content: `You are a viral hook copywriter for TikTok/Instagram slide posts. You are the BEST at writing first-slide text that makes people STOP scrolling.

${SAFEMAMA_KNOWLEDGE}
${CONTENT_RULES}
${performanceContext}

## TASK:
Generate 30 viral hooks (first-slide text) for SafeMama slide posts.

## RULES:
- Short (under 15 words)
- Emotionally charged
- Creates curiosity gap ("I need to see what's next")
- Casual, spoken-word tone (like talking to a friend)
- NO app name in the hook (hook should be about the PROBLEM)
- Must make sense on a slide with a product/ingredient image background

## CATEGORIES NEEDED:
- 8 Fear/Shock hooks ("This ingredient in your moisturizer...")
- 6 Curiosity hooks ("I scanned my entire pregnancy kit...")
- 5 Before/After hooks ("Before vs after knowing what's in this...")
- 5 Myth-busting hooks ("Everyone says this is safe but...")
- 3 Relatability hooks ("Pregnancy anxiety is no joke...")
- 3 Challenge hooks ("Can your skincare pass a pregnancy safety test?")

## RETURN:
{
    "hooks": [
        {
            "text": "the hook text",
            "category": "fear/curiosity/before_after/myth_busting/relatability/challenge",
            "predicted_engagement": "high/medium/low",
            "suggested_image": "description of what image should be behind this text"
        }
    ]
}

Return ONLY the JSON, no other text.`
        }],
        temperature: 0.9,
        max_tokens: 3000,
    });

    const result = JSON.parse(response.choices[0].message.content.replace(/```json\n?|\n?```/g, '').trim());

    insertResearch({
        research_type: 'hooks',
        platform: 'both',
        raw_data: result,
        insights: result.hooks.filter(h => h.predicted_engagement === 'high').map(h => h.text),
        top_angles: result.hooks.map(h => h.category),
    });

    console.log(`[Research] ✅ Generated ${result.hooks.length} viral hooks`);
    return result;
}

// ==========================================================
// 6. COMPILE RESEARCH REPORT
// ==========================================================
function compileResearchReport(results) {
    const topAngles = [];
    const insights = [];
    const hooks = [];

    if (results.angles?.top_angles) {
        topAngles.push(...results.angles.top_angles.slice(0, 5).map(a => `${a.name} (${a.predicted_performance})`));
    }
    if (results.competitor?.competitor_insights) {
        insights.push(...results.competitor.competitor_insights.slice(0, 5));
    }
    if (results.audience?.pain_phrases) {
        insights.push(...results.audience.pain_phrases.slice(0, 3).map(p => `User says: "${p}"`));
    }
    if (results.hooks?.hooks) {
        hooks.push(...results.hooks.hooks.filter(h => h.predicted_engagement === 'high').slice(0, 5).map(h => h.text));
    }

    return {
        type: 'Full Market Research',
        platform: 'TikTok + Instagram',
        topAngles,
        insights,
        hooks,
        raw: results,
    };
}

// ==========================================================
// SELF-OPTIMIZATION: Analyze what worked and adjust
// ==========================================================
export async function runOptimizationAnalysis() {
    console.log('[Research] 🧠 Running self-optimization analysis...');

    const stats = getPerformanceStats();
    if (stats.length === 0) {
        console.log('[Research] No posts yet — skipping optimization.');
        return null;
    }

    const response = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [{
            role: 'user',
            content: `You are a data-driven social media optimization expert.

## OUR PERFORMANCE DATA:
${JSON.stringify(stats, null, 2)}

## TASK:
Analyze our content performance and provide actionable optimization recommendations.

For each angle, determine:
1. Is it performing well? Why?
2. Should we double down, modify, or abandon it?
3. What specific changes would improve low-performing angles?
4. What posting time recommendations can you infer?

## RETURN:
{
    "analysis": {
        "best_performing": "angle name",
        "worst_performing": "angle name",
        "key_finding": "main insight from the data"
    },
    "recommendations": [
        "specific recommendation 1",
        "specific recommendation 2"
    ],
    "angle_adjustments": {
        "double_down": ["angles to post more of"],
        "modify": ["angles that need tweaking"],
        "reduce": ["angles to post less of"]
    },
    "content_changes": ["specific changes to slide design, hooks, or caption style"]
}

Return ONLY the JSON.`
        }],
        temperature: 0.5,
        max_tokens: 1500,
    });

    const result = JSON.parse(response.choices[0].message.content.replace(/```json\n?|\n?```/g, '').trim());
    console.log('[Research] ✅ Optimization analysis complete');
    return result;
}

export default { runFullResearch, runOptimizationAnalysis };
