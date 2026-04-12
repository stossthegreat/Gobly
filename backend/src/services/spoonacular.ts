import type { TrendingRecipe } from '../data/trending.js';

const SPOON_BASE = 'https://api.spoonacular.com';

/**
 * Fetch popular/random recipes from Spoonacular.
 * Free tier: 150 points/day. This call costs ~1.2 points for 10 recipes.
 * Images are hosted on Spoonacular's CDN — always load, never get blocked.
 */
export async function fetchSpoonacularTrending(
  apiKey: string,
  count: number = 10,
): Promise<TrendingRecipe[]> {
  // Rotate tags by day of week for variety
  const tagRotations = [
    'dinner',
    'lunch,healthy',
    'breakfast',
    'dessert',
    'vegetarian',
    'dinner,quick',
    'brunch',
  ];
  const todayTags = tagRotations[new Date().getDay()];

  const url =
    `${SPOON_BASE}/recipes/random?number=${count}` +
    `&tags=${encodeURIComponent(todayTags)}` +
    `&apiKey=${apiKey}`;

  const response = await fetch(url);
  if (!response.ok) {
    const body = await response.text().catch(() => '');
    throw new Error(`Spoonacular ${response.status}: ${body.slice(0, 200)}`);
  }

  const data = (await response.json()) as {
    recipes?: Array<{
      id: number;
      title: string;
      image?: string;
      sourceUrl?: string;
      sourceName?: string;
      readyInMinutes?: number;
      servings?: number;
      aggregateLikes?: number;
      summary?: string;
      spoonacularScore?: number;
    }>;
  };

  return (data.recipes ?? [])
    .filter((r) => r.title && r.image) // must have title + image
    .map((r, i) => ({
      id: `spoon_${r.id}`,
      title: r.title,
      source: r.sourceName || 'Spoonacular',
      sourceUrl: r.sourceUrl || '',
      image: r.image || '',
      emoji: _pickEmoji(r.title),
      rating: r.spoonacularScore
        ? Math.round((r.spoonacularScore / 20) * 10) / 10 // 0-100 → 0-5
        : 4.5 + Math.random() * 0.4, // reasonable default
      time: r.readyInMinutes ? `${r.readyInMinutes} min` : '',
      category: i < 3 ? 'TRENDING' : i < 6 ? 'POPULAR' : 'QUICK',
      description: _stripHtml(r.summary || '').slice(0, 120),
    }));
}

function _stripHtml(html: string): string {
  return html.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
}

function _pickEmoji(title: string): string {
  const t = title.toLowerCase();
  if (t.includes('chicken')) return '🍗';
  if (t.includes('pasta') || t.includes('spaghetti') || t.includes('noodle')) return '🍝';
  if (t.includes('burger')) return '🍔';
  if (t.includes('pizza')) return '🍕';
  if (t.includes('taco') || t.includes('burrito')) return '🌮';
  if (t.includes('salad')) return '🥗';
  if (t.includes('soup') || t.includes('stew')) return '🍲';
  if (t.includes('cake') || t.includes('brownie')) return '🍰';
  if (t.includes('fish') || t.includes('salmon') || t.includes('shrimp')) return '🐟';
  if (t.includes('steak') || t.includes('beef')) return '🥩';
  if (t.includes('egg') || t.includes('omelette')) return '🍳';
  if (t.includes('rice') || t.includes('curry')) return '🍛';
  if (t.includes('bread') || t.includes('toast')) return '🍞';
  if (t.includes('pancake') || t.includes('waffle')) return '🥞';
  if (t.includes('smoothie') || t.includes('juice')) return '🥤';
  if (t.includes('cookie') || t.includes('chocolate')) return '🍪';
  return '🍽️';
}
