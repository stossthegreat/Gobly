import type { Recipe } from '../types/recipe.js';

/**
 * Rank recipes by a weighted score combining:
 * - Rating (40%): the actual star rating
 * - Review count (40%): log-scaled so 1000 reviews isn't 10x better than 100
 * - Domain authority (20%): trusted publishers rank higher
 *
 * Returns the recipes sorted descending with the `score` field populated.
 */
export function rankRecipes(recipes: Recipe[]): Recipe[] {
  const withScores = recipes.map((recipe) => ({
    ...recipe,
    score: computeScore(recipe),
  }));

  return withScores.sort((a, b) => b.score - a.score);
}

function computeScore(recipe: Recipe): number {
  const ratingValue = recipe.rating.value;
  const reviewCount = recipe.rating.count;

  // Unrated recipes get a neutral default so they don't always lose
  const ratingScore = ratingValue > 0 ? ratingValue / 5 : 0.6;

  // Log-scale review count: log10(0+1)=0, log10(99+1)=2, log10(999+1)=3, log10(9999+1)=4
  const reviewScore = Math.min(Math.log10(reviewCount + 1) / 4, 1);

  // Domain authority is 0-100; normalize
  // We get it from the source.name field indirectly - actually from getDomainInfo
  // But we need to pass it through. For now, use a neutral 0.7 default.
  // TODO: Thread domain authority through normalizeRecipe into the Recipe type.
  const authorityScore = 0.7;

  return ratingScore * 0.4 + reviewScore * 0.4 + authorityScore * 0.2;
}

/**
 * Filter out recipes that fall below quality thresholds.
 * Better to return fewer results than mediocre ones.
 */
export function filterQuality(
  recipes: Recipe[],
  options: { minRating?: number; minImage?: boolean } = {},
): Recipe[] {
  const { minRating = 0, minImage = true } = options;
  return recipes.filter((r) => {
    if (minImage && !r.image) return false;
    if (r.rating.value > 0 && r.rating.value < minRating) return false;
    if (r.ingredients.length === 0) return false;
    if (r.instructions.length === 0) return false;
    return true;
  });
}
