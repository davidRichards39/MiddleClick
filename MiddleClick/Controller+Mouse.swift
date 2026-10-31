import CoreGraphics
import Foundation
import CoreFoundation

extension Controller {
  private static let state = GlobalState.shared
  private static let kCGMouseButtonCenter = Int64(CGMouseButton.center.rawValue)

  static let mouseEventHandler = CGEventController {
    _, type, event, _ in

    let returnedEvent = Unmanaged.passUnretained(event)

    // macOS disables a tap that stalls input, e.g. after Accessibility permission is revoked while running.
    // Only turn it back on while still trusted; otherwise remove it so every mouse and scroll event bypasses us.
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      DispatchQueue.main.async {
        if SystemPermissions.detectAccessibilityIsGranted(forcePrompt: false) {
          mouseEventHandler.reenable()
        } else {
          mouseEventHandler.stop()
        }
      }
      return returnedEvent
    }

    guard !AppUtils.isIgnoredAppBundle() else { return returnedEvent }

    if type == .scrollWheel {
      return shouldDropScroll(event) ? nil : returnedEvent
    }

    if state.threeDown && (type == .leftMouseDown || type == .rightMouseDown) {
      state.wasThreeDown = true
      state.threeDown = false
      state.naturalMiddleClickLastTime = Date()
      event.type = .otherMouseDown

      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
    }

    // Keep the button held as middle while the fingers move, so the click becomes a middle-drag
    if state.wasThreeDown && (type == .leftMouseDragged || type == .rightMouseDragged) {
      event.type = .otherMouseDragged

      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
    }

    if state.wasThreeDown && (type == .leftMouseUp || type == .rightMouseUp) {
      state.wasThreeDown = false
      event.type = .otherMouseUp

      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
    }
    return returnedEvent
  }

  /// In scroll mode, macOS's own two-finger scrolls (sent while fingers land or lift unevenly, plus their momentum)
  /// would reach the app as plain scrolls, i.e. zoom in RuneLite, so they are dropped around a three-finger touch.
  private static func shouldDropScroll(_ event: CGEvent) -> Bool {
    guard Config.shared.slideToScroll else { return false }
    guard event.getIntegerValueField(.eventSourceUserData) != MiddleDrag.syntheticEventTag else { return false }

    if state.threeFingerTouch { return true }
    if event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0 {
      return state.suppressScrollMomentum
    }
    state.suppressScrollMomentum = false
    return false
  }
}
