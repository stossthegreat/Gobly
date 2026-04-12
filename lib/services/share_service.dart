import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe_result.dart';
import '../widgets/share_recipe_card.dart';

/// Captures share card widgets as high-res PNGs and shares them
/// via the platform's native share sheet (iMessage, IG Stories, etc.).
class ShareService {
  ShareService._();

  /// Share a single recipe as a beautiful 1080x1920 card.
  static Future<void> shareRecipe(
    BuildContext context,
    RecipeResult recipe,
  ) async {
    final card = ShareRecipeCard(
      title: recipe.title,
      imageUrl: recipe.image,
      source: recipe.source.name,
      rating: recipe.rating.value,
      time: recipe.time.display,
      description: recipe.description.isNotEmpty ? recipe.description : null,
    );

    final file = await _captureWidgetToPng(context, card, 'gobly_recipe');
    if (file == null) return;

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '${recipe.title} — found on Gobly',
    );
  }

  /// Share a single recipe from a saved recipe map.
  static Future<void> shareRecipeFromMap(
    BuildContext context,
    Map<String, dynamic> recipe,
  ) async {
    final card = ShareRecipeCard(
      title: recipe['title'] as String? ?? '',
      imageUrl: (recipe['image'] as String?)?.startsWith('http') == true
          ? recipe['image'] as String
          : null,
      localImagePath: (recipe['image'] as String?)?.startsWith('/') == true
          ? recipe['image'] as String
          : null,
      source: recipe['source'] as String? ?? '',
      rating: (recipe['rating'] as num?)?.toDouble() ?? 0.0,
      time: recipe['time'] as String? ?? '',
      calories: null,
    );

    final file = await _captureWidgetToPng(context, card, 'gobly_recipe');
    if (file == null) return;

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '${recipe['title']} — found on Gobly',
    );
  }

  /// Share a carousel: cover card + individual recipe cards.
  /// [recipes] is the list of saved recipe maps to include.
  // ignore: use_build_context_synchronously
  static Future<void> shareCarousel(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> recipes,
  }) async {
    final files = <XFile>[];

    // Cover card
    final cover = ShareCarouselCover(
      title: title,
      mealCount: recipes.length,
      mealNames: recipes
          .map((r) => r['title'] as String? ?? 'Untitled')
          .toList(),
    );
    final coverFile = await _captureWidgetToPng(context, cover, 'gobly_cover');
    if (coverFile != null) files.add(XFile(coverFile.path));

    // Individual recipe cards
    for (var i = 0; i < recipes.length; i++) {
      final r = recipes[i];
      final card = ShareRecipeCard(
        title: r['title'] as String? ?? '',
        imageUrl: (r['image'] as String?)?.startsWith('http') == true
            ? r['image'] as String
            : null,
        localImagePath: (r['image'] as String?)?.startsWith('/') == true
            ? r['image'] as String
            : null,
        source: r['source'] as String? ?? '',
        rating: (r['rating'] as num?)?.toDouble() ?? 0.0,
        time: r['time'] as String? ?? '',
      );
      final f = await _captureWidgetToPng(context, card, 'gobly_meal_$i'); // ignore: use_build_context_synchronously
      if (f != null) files.add(XFile(f.path));
    }

    if (files.isEmpty) return;

    await Share.shareXFiles(
      files,
      text: '$title — ${recipes.length} meals planned with Gobly',
    );
  }

  /// Renders a widget offscreen at 3x resolution, captures as PNG,
  /// saves to temp directory, returns the file.
  static Future<File?> _captureWidgetToPng(
    BuildContext context,
    Widget widget,
    String filePrefix,
  ) async {
    try {
      const pixelRatio = 3.0; // 1080x1920 at 360x640 widget size

      final repaintBoundary = RenderRepaintBoundary();
      final view = View.of(context);

      final renderView = RenderView(
        view: view,
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          logicalConstraints: BoxConstraints.tight(
            const Size(1080 / 3, 1920 / 3),
          ),
          devicePixelRatio: pixelRatio,
        ),
      );

      final pipelineOwner = PipelineOwner()..rootNode = renderView;
      final buildOwner = BuildOwner(focusManager: FocusManager());

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: MediaQuery(
          data: MediaQueryData(
            devicePixelRatio: pixelRatio,
            size: const Size(1080 / 3, 1920 / 3),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              color: Colors.transparent,
              child: widget,
            ),
          ),
        ),
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Clean up
      buildOwner.finalizeTree();

      return file;
    } catch (e) {
      debugPrint('ShareService capture error: $e');
      return null;
    }
  }
}
