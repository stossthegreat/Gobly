import 'dart:convert';

/// A user-created cookbook — a named collection of saved recipes.
/// Stores recipe data denormalized so cookbooks survive even if the
/// user removes the original from their main saved list.
class Cookbook {
  final String id;
  final String name;
  final String emoji;
  final List<Map<String, dynamic>> recipes;
  final DateTime createdAt;

  const Cookbook({
    required this.id,
    required this.name,
    required this.emoji,
    required this.recipes,
    required this.createdAt,
  });

  int get count => recipes.length;

  Cookbook copyWith({
    String? name,
    String? emoji,
    List<Map<String, dynamic>>? recipes,
  }) {
    return Cookbook(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      recipes: recipes ?? this.recipes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'recipes': recipes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Cookbook.fromJson(Map<String, dynamic> json) {
    return Cookbook(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Cookbook',
      emoji: json['emoji'] as String? ?? '\u{1F4D6}',
      recipes: ((json['recipes'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Cookbook.fromJsonString(String s) =>
      Cookbook.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
