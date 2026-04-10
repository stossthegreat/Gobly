import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_result.dart';
import 'user_profile_service.dart';

/// Calls the Recimo backend for AI-powered recipe search.
/// Configure BACKEND_URL via --dart-define at build time, or it
/// falls back to localhost for dev.
class RecipeSearchService {
  RecipeSearchService._();
  static final RecipeSearchService instance = RecipeSearchService._();

  // Override at build time:
  //   flutter run --dart-define=BACKEND_URL=https://recimo.up.railway.app
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Search for recipes matching [query].
  /// Automatically includes the user's profile as context so the agent
  /// respects allergies, diet, dislikes.
  Future<SearchResponse> search(String query) async {
    final userContext = UserProfileService.instance.profile.toAgentContext();

    final uri = Uri.parse('$_backendUrl/api/search');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': query,
            'userContext': userContext,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw RecipeSearchException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SearchResponse.fromJson(data);
  }

  /// Generate a 7-day meal plan with real recipes.
  /// Returns a map of day → meal → {name, recipe}.
  Future<Map<String, dynamic>> planWeek(String prompt) async {
    final userContext = UserProfileService.instance.profile.toAgentContext();

    final uri = Uri.parse('$_backendUrl/api/plan-week');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'prompt': prompt,
            'userContext': userContext,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw RecipeSearchException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['error'] ?? decoded['message'] ?? body;
    } catch (_) {
      return body;
    }
  }
}

class RecipeSearchException implements Exception {
  final int statusCode;
  final String message;

  RecipeSearchException({required this.statusCode, required this.message});

  @override
  String toString() => 'RecipeSearchException($statusCode): $message';
}
