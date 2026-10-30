import ConfigCore

final class Config: ConfigCore {
  required init() {
    Self.options.cacheAll = true
  }

  @UserDefault("fingers")
  var minimumFingers = 3

  @UserDefault var allowMoreFingers = false

  @UserDefault var maxDistanceDelta: Float = 0.05

  /// In milliseconds
  @UserDefault(transformGet: { $0 / 1000 })
  var maxTimeDelta = 300.0

  /// In milliseconds. Fingers landing further apart than this (e.g. a third finger joining two resting ones) don't middle-click
  @UserDefault(transformGet: { $0 / 1000 })
  var maxFingerLandingSpread = 150.0

  @UserDefault var tapToClick = SystemPermissions.getIsSystemTapToClickEnabled

  /// With tap to click, sliding the fingers without pressing holds the middle button
  @UserDefault var tapToDrag = true

  /// Pointer distance per finger distance while middle-dragging; 1 maps the trackpad onto the screen
  @UserDefault var middleDragSpeed: Float = 1.0

  @UserDefault var ignoredAppBundles = Set<String>()

  /// When not empty, MiddleClick only acts while one of these apps is focused
  @UserDefault var onlyAppBundles = Set<String>()
}
