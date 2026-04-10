/// A recipe returned from the backend AI agent.
/// Matches the Recipe type in backend/src/types/recipe.ts
class RecipeResult {
  final String id;
  final String title;
  final String description;
  final String image;
  final RecipeSource source;
  final RecipeRating rating;
  final RecipeTime time;
  final int? servings;
  final List<String> ingredients;
  final List<String> instructions;
  final double score;

  const RecipeResult({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.source,
    required this.rating,
    required this.time,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.score,
  });

  factory RecipeResult.fromJson(Map<String, dynamic> json) {
    return RecipeResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String? ?? '',
      source: RecipeSource.fromJson(
          (json['source'] as Map?)?.cast<String, dynamic>() ?? const {}),
      rating: RecipeRating.fromJson(
          (json['rating'] as Map?)?.cast<String, dynamic>() ?? const {}),
      time: RecipeTime.fromJson(
          (json['time'] as Map?)?.cast<String, dynamic>() ?? const {}),
      servings: (json['servings'] as num?)?.toInt(),
      ingredients: (json['ingredients'] as List?)?.cast<String>() ?? const [],
      instructions: (json['instructions'] as List?)?.cast<String>() ?? const [],
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'image': image,
        'source': source.toJson(),
        'rating': rating.toJson(),
        'time': time.toJson(),
        'servings': servings,
        'ingredients': ingredients,
        'instructions': instructions,
        'score': score,
      };
}

class RecipeSource {
  final String domain;
  final String name;
  final String url;

  const RecipeSource({
    required this.domain,
    required this.name,
    required this.url,
  });

  factory RecipeSource.fromJson(Map<String, dynamic> json) => RecipeSource(
        domain: json['domain'] as String? ?? '',
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'name': name,
        'url': url,
      };
}

class RecipeRating {
  final double value;
  final int count;

  const RecipeRating({required this.value, required this.count});

  factory RecipeRating.fromJson(Map<String, dynamic> json) => RecipeRating(
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'count': count,
      };
}

class RecipeTime {
  final int? prep;
  final int? cook;
  final int? total;
  final String display;

  const RecipeTime({
    required this.prep,
    required this.cook,
    required this.total,
    required this.display,
  });

  factory RecipeTime.fromJson(Map<String, dynamic> json) => RecipeTime(
        prep: (json['prep'] as num?)?.toInt(),
        cook: (json['cook'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt(),
        display: json['display'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'prep': prep,
        'cook': cook,
        'total': total,
        'display': display,
      };
}

/// The full response from the /api/search endpoint.
class SearchResponse {
  final String query;
  final List<RecipeResult> results;
  final int durationMs;
  final bool cached;

  const SearchResponse({
    required this.query,
    required this.results,
    required this.durationMs,
    required this.cached,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) => SearchResponse(
        query: json['query'] as String? ?? '',
        results: (json['results'] as List?)
                ?.map((e) =>
                    RecipeResult.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
        cached: json['cached'] as bool? ?? false,
      );
}
