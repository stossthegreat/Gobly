/// Maps a raw ingredient string to one of the 5 grocery categories
/// using simple keyword matching. Reasonably accurate for common
/// ingredients without needing a backend call.
class IngredientCategorizer {
  IngredientCategorizer._();

  static const _produce = [
    'onion', 'garlic', 'tomato', 'lettuce', 'spinach', 'kale',
    'carrot', 'celery', 'pepper', 'cucumber', 'apple', 'banana',
    'lemon', 'lime', 'orange', 'avocado', 'potato', 'broccoli',
    'cauliflower', 'mushroom', 'zucchini', 'cabbage', 'parsley',
    'cilantro', 'basil', 'mint', 'thyme', 'rosemary', 'sage',
    'ginger', 'green onion', 'scallion', 'bell pepper', 'jalapeno',
    'chilli', 'chili pepper', 'corn', 'pea', 'sprout', 'leek',
    'shallot', 'fennel', 'asparagus', 'artichoke', 'eggplant',
    'aubergine', 'squash', 'pumpkin', 'sweet potato', 'radish',
    'beet', 'turnip', 'arugula', 'rocket', 'watercress', 'endive',
    'chard', 'okra', 'pomegranate', 'pineapple', 'mango', 'peach',
    'pear', 'grape', 'berry', 'blueberry', 'strawberry', 'raspberry',
    'cherry', 'fig', 'date', 'kiwi', 'melon', 'plum', 'apricot',
    'coconut', 'plantain', 'yam', 'kumquat', 'passion fruit',
  ];

  static const _protein = [
    'chicken', 'beef', 'pork', 'lamb', 'turkey', 'fish', 'salmon',
    'tuna', 'cod', 'shrimp', 'prawn', 'bacon', 'sausage', 'ham',
    'steak', 'tofu', 'tempeh', 'egg', 'mince', 'duck', 'venison',
    'crab', 'lobster', 'scallop', 'clam', 'mussel', 'octopus',
    'squid', 'anchovy', 'sardine', 'mackerel', 'trout', 'sea bass',
    'halibut', 'tilapia', 'snapper', 'tenderloin', 'ribeye', 'sirloin',
    'brisket', 'chop', 'cutlet', 'wing', 'thigh', 'drumstick',
    'breast', 'ground', 'patty', 'meatball', 'seitan', 'edamame',
  ];

  static const _dairy = [
    'milk', 'cream', 'cheese', 'butter', 'yogurt', 'yoghurt',
    'cheddar', 'mozzarella', 'parmesan', 'parmigiano', 'feta',
    'ricotta', 'cottage cheese', 'sour cream', 'half and half',
    'buttermilk', 'cream cheese', 'gruyere', 'gouda', 'brie',
    'camembert', 'goat cheese', 'mascarpone', 'creme fraiche',
    'evaporated milk', 'condensed milk', 'whipped cream', 'kefir',
  ];

  static const _pantry = [
    'flour', 'sugar', 'salt', 'pepper', 'oil', 'olive oil',
    'vegetable oil', 'sesame oil', 'vinegar', 'soy sauce', 'rice',
    'pasta', 'noodle', 'bread', 'oats', 'cereal', 'sauce', 'mustard',
    'ketchup', 'mayo', 'mayonnaise', 'honey', 'syrup', 'maple syrup',
    'baking', 'yeast', 'baking soda', 'baking powder', 'vanilla',
    'cumin', 'paprika', 'cinnamon', 'nutmeg', 'oregano', 'turmeric',
    'cardamom', 'coriander', 'allspice', 'clove', 'garlic powder',
    'onion powder', 'chili powder', 'curry', 'broth', 'stock',
    'tomato paste', 'tomato sauce', 'canned', 'jar', 'wine',
    'cornstarch', 'breadcrumb', 'panko', 'sesame seed', 'almond',
    'walnut', 'pecan', 'cashew', 'pistachio', 'peanut', 'pine nut',
    'chickpea', 'lentil', 'black bean', 'kidney bean', 'cannellini',
    'chocolate', 'cocoa', 'coffee', 'tea', 'molasses', 'agave',
    'tahini', 'miso', 'fish sauce', 'oyster sauce', 'hoisin',
    'sriracha', 'tabasco', 'worcestershire', 'capers', 'olives',
    'pickle', 'relish', 'jam', 'preserve', 'tortilla', 'pita',
    'wrap', 'cracker', 'biscuit', 'quinoa', 'couscous', 'bulgur',
    'farro', 'barley', 'polenta', 'cornmeal', 'powder',
  ];

  /// Returns one of: 'Produce', 'Protein', 'Dairy', 'Pantry', 'Other'
  static String categorize(String ingredient) {
    final lower = ingredient.toLowerCase();

    // Check protein first because "chicken broth" should be Pantry not Protein
    // — but "chicken breast" should be Protein. We achieve this by checking
    // pantry-specific protein-containing strings first.
    if (lower.contains('broth') || lower.contains('stock')) return 'Pantry';
    if (lower.contains('sauce') &&
        !lower.contains('hot sauce') &&
        !lower.contains('apple sauce')) {
      return 'Pantry';
    }

    for (final word in _protein) {
      if (_containsWord(lower, word)) return 'Protein';
    }
    for (final word in _dairy) {
      if (_containsWord(lower, word)) return 'Dairy';
    }
    for (final word in _produce) {
      if (_containsWord(lower, word)) return 'Produce';
    }
    for (final word in _pantry) {
      if (_containsWord(lower, word)) return 'Pantry';
    }
    return 'Other';
  }

  /// Word-boundary-aware contains so "ham" doesn't match "hamburger" twice
  /// and "pea" doesn't match "peach". For multi-word terms, fall back to
  /// substring contains.
  static bool _containsWord(String haystack, String needle) {
    if (needle.contains(' ')) return haystack.contains(needle);
    final pattern = RegExp('\\b${RegExp.escape(needle)}\\b');
    return pattern.hasMatch(haystack);
  }
}
