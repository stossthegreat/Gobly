import OpenAI from 'openai';
import { config, assertKeysConfigured } from '../config.js';

let _client: OpenAI | null = null;
function getClient(): OpenAI {
  assertKeysConfigured();
  if (!_client) {
    _client = new OpenAI({ apiKey: config.openaiApiKey });
  }
  return _client;
}

/**
 * Normalize a raw user query into a web-search-friendly phrase.
 * "I want something cozy for a rainy day" → "cozy comfort food recipes"
 */
export async function normalizeQuery(query: string, userContext?: string): Promise<string> {
  const systemPrompt = `You convert casual user food requests into concise web search queries optimized for finding highly-rated recipes on cooking websites.

Rules:
- Output ONLY the search query, nothing else. No quotes, no explanation.
- Keep it 2-6 words
- Include the word "recipe" if it fits naturally
- Respect the user's context (allergies, diet, dislikes) — never suggest things they can't eat
- Prefer specific dish names over vague descriptions
- Remove first-person phrasing ("I want", "give me")

Examples:
Input: "I want mac and cheese" → "mac and cheese recipe"
Input: "something cozy for winter" → "cozy winter comfort food recipes"
Input: "quick dinner" → "quick weeknight dinner recipes"
Input: "impress my date" → "elegant date night dinner recipes"`;

  const userMessage = userContext
    ? `User context:\n${userContext}\n\nUser request: ${query}`
    : query;

  const response = await getClient().chat.completions.create({
    model: config.openaiModel,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userMessage },
    ],
    temperature: 0.3,
    max_tokens: 30,
  });

  const normalized = response.choices[0]?.message?.content?.trim() || query;
  return normalized.replace(/^["']|["']$/g, ''); // strip surrounding quotes
}

/**
 * Generate a 7-day meal plan as 21 specific dish names.
 * Returns an object with the structure: { Mon: { Breakfast, Lunch, Dinner }, ... }
 */
export async function generateWeekPlan(
  request: string,
  userContext?: string,
): Promise<Record<string, Record<string, string>>> {
  const systemPrompt = `You are a meal planning expert. Generate a 7-day meal plan with 21 specific dish names (one for each breakfast, lunch, and dinner from Monday to Sunday).

Rules:
- Return ONLY valid JSON, no markdown, no explanation
- Each dish must be a SPECIFIC recipe name that could be searched on a cooking website
- Respect user allergies, diet, and dislikes STRICTLY
- Vary cuisines, proteins, and cooking styles across the week
- Keep dishes realistic for the user's skill level and time preference
- Prefer dishes with established recipes (not made-up combinations)

Return format:
{
  "Mon": {"Breakfast": "...", "Lunch": "...", "Dinner": "..."},
  "Tue": {...},
  ...
  "Sun": {...}
}`;

  const userMessage = userContext
    ? `User context:\n${userContext}\n\nUser request: ${request}`
    : request;

  const response = await getClient().chat.completions.create({
    model: config.openaiModel,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userMessage },
    ],
    temperature: 0.7,
    max_tokens: 800,
    response_format: { type: 'json_object' },
  });

  const content = response.choices[0]?.message?.content || '{}';
  try {
    return JSON.parse(content);
  } catch {
    throw new Error('GPT returned invalid JSON for meal plan');
  }
}

/**
 * Fallback HTML parser — when a page has no JSON-LD, ask GPT to extract the recipe.
 * Expensive compared to JSON-LD parsing, so only use for top candidates.
 */
export async function extractRecipeFromHtmlWithLlm(
  html: string,
  sourceUrl: string,
): Promise<unknown | null> {
  // Strip HTML to roughly 4000 chars of visible text
  const cleaned = html
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 6000);

  const response = await getClient().chat.completions.create({
    model: config.openaiModel,
    messages: [
      {
        role: 'system',
        content: `Extract the recipe from the given webpage text. Return JSON only:
{
  "name": "...",
  "description": "...",
  "image": "",
  "recipeIngredient": ["..."],
  "recipeInstructions": ["step 1", "step 2"],
  "prepTime": "PT15M",
  "cookTime": "PT30M",
  "recipeYield": "4 servings"
}
If the page is not a recipe, return null.`,
      },
      { role: 'user', content: `URL: ${sourceUrl}\n\nText:\n${cleaned}` },
    ],
    temperature: 0.1,
    max_tokens: 1200,
    response_format: { type: 'json_object' },
  });

  const content = response.choices[0]?.message?.content || 'null';
  try {
    const parsed = JSON.parse(content);
    if (!parsed || !parsed.name) return null;
    return parsed;
  } catch {
    return null;
  }
}
