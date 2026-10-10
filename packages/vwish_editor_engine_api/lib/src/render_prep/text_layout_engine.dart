// OWNER: API-04
//
// Placeholder (D-33, created by API-01). API-04 implements the text layout engine shared by the
// preview overlay, manipulation handles and export sprites (ARCH §10.3, D-05).

/// Maps a font id to a font family; unknown ids resolve to Figtree (ARCH §10.3, API-04).
typedef FontResolver = String Function(String fontId);

/// Lays out text with `ui.Paragraph` (ARCH §10.3, API-04).
class TextLayoutEngine {
  /// Creates the engine; [fontResolver] resolves font ids.
  TextLayoutEngine({required this.fontResolver});

  /// Font id -> family.
  final FontResolver fontResolver;

  /// Lays out the `TextLayoutSpec` JSON [spec] (API-04).
  Object layout(Map<String, Object?> spec) => throw UnimplementedError('TextLayoutEngine is implemented by API-04');
}
