import CoreGraphics
import Foundation
import CoreFoundation

extension Controller {
  private static let state = GlobalState.shared
  private static let kCGMouseButtonCenter = Int64(CGMouseButton.center.rawValue)

  static let mouseEventHandler = CGEventController {
    _, type, event, _ in

    let returnedEvent = Unmanaged.passUnretained(event)
    guard !AppUtils.isIgnoredAppBundle() else { return returnedEvent }

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
}
