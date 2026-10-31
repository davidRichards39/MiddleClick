import Foundation

@MainActor
final class GlobalState {
  static let shared = GlobalState()
  private init() {
    Config.shared.$ignoredAppBundles.onSet {
      self.ignoredAppBundlesCache = $0
    }
    Config.shared.$onlyAppBundles.onSet {
      self.onlyAppBundlesCache = $0
    }
  }

  var threeDown = false
  var wasThreeDown = false
  var naturalMiddleClickLastTime: Date?
  /// The current touch has had three fingers down (until every finger lifts)
  var threeFingerTouch = false
  /// Drop the momentum scroll macOS sends after a three-finger touch ends, until the next real scroll
  var suppressScrollMomentum = false
  /// stored locally, since accessing the cache is more CPU-expensive than a local variable
  var ignoredAppBundlesCache = Config.shared.ignoredAppBundles
  var onlyAppBundlesCache = Config.shared.onlyAppBundles
}
