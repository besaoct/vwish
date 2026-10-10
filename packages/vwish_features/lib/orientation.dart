/// Screen orientation ownership for screens outside `vwish_features` (the editor opens over the
/// player and must hand the orientation back correctly). Entry point:
/// `package:vwish_features/orientation.dart`.
library vwish_features_orientation;

export 'src/player/screen_orientation_policy.dart' show OrientationMode, ScreenOrientationPolicy;
