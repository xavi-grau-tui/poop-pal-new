import AppKit
import Foundation

// Fits a transparent generated Lucky Pinch logo onto the same 260x141 canvas
// as the other game titles using nearest-neighbour sampling and binary alpha.
let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
guard let source = NSBitmapImageRep(data: try Data(contentsOf: input)) else {
    fatalError("Cannot read source image")
}
var minX = source.pixelsWide, minY = source.pixelsHigh
var maxX = -1, maxY = -1
for y in stride(from: 0, to: source.pixelsHigh, by: 2) {
    for x in stride(from: 0, to: source.pixelsWide, by: 2) {
        if (source.colorAt(x: x, y: y)?.alphaComponent ?? 0) >= 0.5 {
            minX = min(minX, x); minY = min(minY, y)
            maxX = max(maxX, x); maxY = max(maxY, y)
        }
    }
}
guard maxX >= minX, maxY >= minY else { fatalError("No opaque pixels") }
let sw = maxX - minX + 1, sh = maxY - minY + 1
let factor = min(250.0 / Double(sw), 130.0 / Double(sh))
let width = min(250, Int((Double(sw) * factor).rounded()))
let height = min(130, Int((Double(sh) * factor).rounded()))
let left = (260 - width) / 2, top = (141 - height) / 2
let target = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 260, pixelsHigh: 141,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB,
                              bytesPerRow: 0, bitsPerPixel: 0)!
let transparent = NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 0)
for y in 0..<141 {
    for x in 0..<260 { target.setColor(transparent, atX: x, y: y) }
}
for y in 0..<height {
    for x in 0..<width {
        let sx = min(maxX, minX + Int((Double(x) + 0.5) * Double(sw) / Double(width)))
        let sy = min(maxY, minY + Int((Double(y) + 0.5) * Double(sh) / Double(height)))
        if let c = source.colorAt(x: sx, y: sy)?.usingColorSpace(.deviceRGB),
           c.alphaComponent >= 0.5 {
            target.setColor(NSColor(deviceRed: c.redComponent, green: c.greenComponent,
                                    blue: c.blueComponent, alpha: 1),
                            atX: left + x, y: top + y)
        }
    }
}
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)
try target.representation(using: .png, properties: [:])!.write(to: output)
print("260x141, opaque bounds \(left),\(top)-\(left + width - 1),\(top + height - 1)")
