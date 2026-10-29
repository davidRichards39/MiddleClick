import CoreGraphics
import MultitouchSupport

/// Turns a three-finger slide into a middle-button drag.
///
/// macOS doesn't move the pointer while three fingers slide on the trackpad (it reads them as a gesture),
/// so the drag movement is driven from the raw finger positions instead:
/// - holding a three-finger click: the button is already middle (see `Controller.mouseEventHandler`), only the movement is added
/// - tap to click: sliding three fingers without pressing holds the middle button until the fingers lift
@MainActor final class MiddleDrag {
  static let shared = MiddleDrag()
  private static let config = Config.shared
  private init() {}

  private var lastCentroid: SIMD2<Float>?
  private var lastFingerCount: Int32 = 0
  private var tapStartCentroid: SIMD2<Float>?
  /// A physical click happened during this touch, so its slide must not turn into a tap drag afterwards
  private var tapDragBlocked = false
  private var isTapDragging = false

  func handleFrame(
    data: UnsafePointer<MTTouch>?, nFingers: Int32, fingersQua: Int,
    isFingerCountAllowed: Bool, tapToClick: Bool
  ) {
    guard isFingerCountAllowed, let data else {
      reset()
      return
    }

    // Finger order and centroid jump when fingers are added or lifted, so start measuring afresh
    if nFingers != lastFingerCount {
      lastCentroid = nil
      lastFingerCount = nFingers
    }
    let centroid = Self.centroid(of: UnsafeBufferPointer(start: data, count: fingersQua))
    defer { lastCentroid = centroid }

    let state = GlobalState.shared
    if state.wasThreeDown {
      tapDragBlocked = true
    } else if !isTapDragging {
      guard tapToClick && Self.config.tapToDrag && !tapDragBlocked else { return }
      guard let tapStartCentroid else {
        tapStartCentroid = centroid
        return
      }
      guard centroid.delta(to: tapStartCentroid) >= Self.config.maxDistanceDelta else { return }

      isTapDragging = true
      Self.postMouseEvent(type: .otherMouseDown, location: Self.pointerLocation)
    }

    guard let lastCentroid else { return }
    movePointer(by: centroid - lastCentroid)
  }

  private func reset() {
    if isTapDragging {
      isTapDragging = false
      Self.postMouseEvent(type: .otherMouseUp, location: Self.pointerLocation)
    }
    lastCentroid = nil
    lastFingerCount = 0
    tapStartCentroid = nil
    tapDragBlocked = false
  }

  private func movePointer(by delta: SIMD2<Float>) {
    guard delta.isNonZero else { return }

    let current = Self.pointerLocation
    let bounds = Self.displayBounds(containing: current)
    let speed = CGFloat(Self.config.middleDragSpeed)
    let dx = CGFloat(delta.x) * bounds.width * speed
    // touch y grows upwards, screen y grows downwards
    let dy = -CGFloat(delta.y) * bounds.height * speed

    let target = CGPoint(
      x: min(max(current.x + dx, bounds.minX), bounds.maxX - 1),
      y: min(max(current.y + dy, bounds.minY), bounds.maxY - 1)
    )
    Self.postMouseEvent(type: .otherMouseDragged, location: target, delta: (dx, dy))
  }

  private static var pointerLocation: CGPoint { CGEvent(source: nil)?.location ?? .zero }

  private static func centroid(of touches: UnsafeBufferPointer<MTTouch>) -> SIMD2<Float> {
    let sum = touches.reduce(SIMD2<Float>.zero) { $0 + SIMD2($1.normalizedVector.position) }
    return sum / Float(max(touches.count, 1))
  }

  private static func displayBounds(containing point: CGPoint) -> CGRect {
    var display = CGDirectDisplayID()
    var count: UInt32 = 0
    CGGetDisplaysWithPoint(point, 1, &display, &count)
    return CGDisplayBounds(count > 0 ? display : CGMainDisplayID())
  }

  private static func postMouseEvent(
    type: CGEventType, location: CGPoint, delta: (CGFloat, CGFloat) = (0, 0)
  ) {
    let event = CGEvent(
      mouseEventSource: nil, mouseType: type, mouseCursorPosition: location,
      mouseButton: .center
    )
    event?.setIntegerValueField(.mouseEventDeltaX, value: Int64(delta.0.rounded()))
    event?.setIntegerValueField(.mouseEventDeltaY, value: Int64(delta.1.rounded()))
    event?.post(tap: .cghidEventTap)
  }
}
