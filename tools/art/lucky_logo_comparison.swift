import AppKit
import Foundation

let items: [(String, String)] = [
    ("SPLASH HOOPS", "textures/menus/splashhoops_stacked.png"),
    ("TILT MAZE", "textures/menus/tiltmaze_pixel.png"),
    ("PAPER SUMO", "textures/menus/papersumo_pixel.png"),
    ("TOP SPIN", "textures/menus/topspin_pixel.png"),
    ("RC PRIX 2177", "textures/menus/rcprix2177_pixel.png"),
    ("LUCKY PINCH · NEW", "docs/mockups/lucky_pinch_redesign/option_b.png")
]
let board = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 900, pixelsHigh: 450,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                             isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: 0, bitsPerPixel: 0)!
let graphics = NSGraphicsContext(bitmapImageRep: board)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
graphics.imageInterpolation = .none
NSColor(deviceRed: 0.17, green: 0.15, blue: 0.20, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 900, height: 450)).fill()
for (i, item) in items.enumerated() {
    let x = (i % 3) * 300 + 20
    let y = (1 - i / 3) * 225
    (item.0 as NSString).draw(at: NSPoint(x: x, y: y + 188),
                              withAttributes: [.font: NSFont.boldSystemFont(ofSize: 13),
                                               .foregroundColor: NSColor.white])
    if let logo = NSImage(contentsOfFile: item.1) {
        logo.draw(in: NSRect(x: x, y: y + 22, width: 260, height: 141),
                  from: NSRect(x: 0, y: 0, width: 260, height: 141),
                  operation: .sourceOver, fraction: 1)
    }
}
NSGraphicsContext.restoreGraphicsState()
try board.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "docs/mockups/lucky_pinch_redesign/comparison.png"))
