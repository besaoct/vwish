/// Shared screen chrome that `vwish_editor` (Projects screen, settings rows) reuses so it looks
/// like the rest of the library screens. Entry point: `package:vwish_features/chrome.dart`.
///
/// `vwish_features` never imports editor packages; this file only re-exports widgets that
/// already live here.
library vwish_features_chrome;

export 'src/library/library_widgets.dart'
    show
        VwishInlineEmpty,
        VwishLibraryFrame,
        VwishLibraryGroup,
        VwishLibrarySectionHeader,
        VwishLibraryTopBar,
        VwishRefreshOnReturn,
        vwishLibraryInsets;
