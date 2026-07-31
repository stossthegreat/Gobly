import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Container-path-safe storage for user recipe photos.
///
/// iOS (and to a lesser extent Android) changes the app's Documents container
/// path on every update/reinstall, so an ABSOLUTE path saved today becomes
/// invalid tomorrow — which is why manually-added photos "disappeared" while
/// AI recipes (which use `http` URLs) survived.
///
/// The fix: persist only a container-independent marker (`local://<filename>`)
/// and rebuild the absolute path at read time from the *current* Documents
/// directory. Legacy absolute paths are salvaged by filename.
class LocalImageStore {
  LocalImageStore._();

  static const _scheme = 'local://';
  static String? _docsPath;

  /// Cache the Documents directory once at startup so [resolveFile] can stay
  /// synchronous (build methods can't await). Safe to call more than once.
  static Future<void> init() async {
    if (_docsPath != null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _docsPath = dir.path;
    } catch (_) {
      // Leave null — resolveFile falls back to any still-valid absolute path.
    }
  }

  /// Copy a freshly-picked image into the Documents directory and return the
  /// storable marker (`local://recipe_123.jpg`). Returns null on failure.
  static Future<String?> savePickedFile(String sourcePath) async {
    try {
      _docsPath ??= (await getApplicationDocumentsDirectory()).path;
      final name = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(sourcePath).copy('$_docsPath/$name');
      return '$_scheme$name';
    } catch (_) {
      return null;
    }
  }

  /// True if [stored] points at a remote (network) image.
  static bool isNetwork(String? stored) =>
      stored != null && stored.startsWith('http');

  /// Resolve a stored image value to an absolute, on-disk file path for a
  /// LOCAL photo — or null if it's a network image, empty, or missing.
  ///
  /// Handles every format we've ever written: `local://name`, a bare
  /// filename, and legacy absolute paths (rebuilt against the current
  /// Documents dir by filename, so old broken references self-heal).
  static String? resolveFile(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (stored.startsWith('http')) return null;

    final name = stored.startsWith(_scheme)
        ? stored.substring(_scheme.length)
        : stored.split('/').last;

    final docs = _docsPath;
    if (docs != null && name.isNotEmpty) {
      final rebuilt = '$docs/$name';
      if (File(rebuilt).existsSync()) return rebuilt;
    }
    // Last resort: a legacy absolute path that still happens to be valid.
    if (stored.startsWith('/') && File(stored).existsSync()) return stored;
    return null;
  }
}
