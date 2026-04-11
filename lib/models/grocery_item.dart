/// A single grocery list item. May be auto-generated from a meal plan
/// (in which case sourceMealKey is set) or manually added by the user.
class GroceryItem {
  final String id;
  final String name;
  final String category;
  final bool checked;

  /// "Mon_Lunch" etc — set when this item came from a planned meal.
  /// Used by GroceryService.removeByMealKey to clean up when a meal
  /// is removed from the planner.
  final String? sourceMealKey;

  /// "Birria Tacos" — display label so the user knows where it came from
  final String? sourceMealName;

  const GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.checked,
    this.sourceMealKey,
    this.sourceMealName,
  });

  bool get isAuto => sourceMealKey != null;

  GroceryItem copyWith({
    String? name,
    String? category,
    bool? checked,
    String? sourceMealKey,
    String? sourceMealName,
  }) {
    return GroceryItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      checked: checked ?? this.checked,
      sourceMealKey: sourceMealKey ?? this.sourceMealKey,
      sourceMealName: sourceMealName ?? this.sourceMealName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'checked': checked,
        if (sourceMealKey != null) 'sourceMealKey': sourceMealKey,
        if (sourceMealName != null) 'sourceMealName': sourceMealName,
      };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? 'Other',
        checked: json['checked'] as bool? ?? false,
        sourceMealKey: json['sourceMealKey'] as String?,
        sourceMealName: json['sourceMealName'] as String?,
      );
}
