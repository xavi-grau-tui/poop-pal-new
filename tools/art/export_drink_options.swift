import AppKit
import Foundation

// Converts generated concepts into native 32x32 sprites and contact sheets.
// Usage: swift -module-cache-path /private/tmp/drink-swift-cache \
//   tools/art/export_drink_options.swift manifest.json output_directory

struct Drink: Decodable {
    let name: String
    let file: String
    let a: String
    let b: String
}

let manifestURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let drinks = try JSONDecoder().decode([Drink].self, from: Data(contentsOf: manifestURL))
let manager = FileManager.default
let outline = NSColor(deviceRed: 50 / 255, green: 14 / 255, blue: 18 / 255, alpha: 1)

func blank(_ width: Int, _ height: Int) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB,
                                  bytesPerRow: 0, bitsPerPixel: 0)!
    let transparent = NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 0)
    for y in 0..<height {
        for x in 0..<width {
            bitmap.setColor(transparent, atX: x, y: y)
        }
    }
    return bitmap
}

func exportSprite(_ sourceURL: URL, _ targetURL: URL) throws {
    guard let source = NSBitmapImageRep(data: try Data(contentsOf: sourceURL)) else {
        throw NSError(domain: "DrinkExport", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot read \(sourceURL.path)"])
    }
    var minX = source.pixelsWide
    var minY = source.pixelsHigh
    var maxX = -1
    var maxY = -1
    // A two-pixel scan step is accurate enough for the large generated source.
    for y in stride(from: 0, to: source.pixelsHigh, by: 2) {
        for x in stride(from: 0, to: source.pixelsWide, by: 2) {
            if (source.colorAt(x: x, y: y)?.alphaComponent ?? 0) >= 0.5 {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }
        }
    }
    guard maxX >= minX, maxY >= minY else {
        throw NSError(domain: "DrinkExport", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "No opaque pixels in \(sourceURL.path)"])
    }

    let sourceWidth = maxX - minX + 1
    let sourceHeight = maxY - minY + 1
    let scale = min(30.0 / Double(sourceWidth), 30.0 / Double(sourceHeight))
    let width = max(1, min(30, Int((Double(sourceWidth) * scale).rounded())))
    let height = max(1, min(30, Int((Double(sourceHeight) * scale).rounded())))
    let left = (32 - width) / 2
    let top = (32 - height) / 2
    var pixels = Array<NSColor?>(repeating: nil, count: 32 * 32)
    func index(_ x: Int, _ y: Int) -> Int { y * 32 + x }

    for y in 0..<height {
        for x in 0..<width {
            // Nearest-neighbour source sampling; alpha is forced to 0 or 255.
            let sourceX = Int((Double(x) + 0.5) * Double(sourceWidth) / Double(width))
            let sourceY = Int((Double(y) + 0.5) * Double(sourceHeight) / Double(height))
            let sx = min(maxX, minX + sourceX)
            let sy = min(maxY, minY + sourceY)
            if let c = source.colorAt(x: sx, y: sy)?.usingColorSpace(.deviceRGB),
               c.alphaComponent >= 0.5 {
                pixels[index(left + x, top + y)] =
                    NSColor(deviceRed: c.redComponent, green: c.greenComponent,
                            blue: c.blueComponent, alpha: 1)
            }
        }
    }

    // Only exterior transparent space controls the silhouette outline.
    var exterior = Array(repeating: false, count: 32 * 32)
    var queue = [Int]()
    for x in 0..<32 {
        for y in [0, 31] where pixels[index(x, y)] == nil {
            let i = index(x, y)
            if !exterior[i] { exterior[i] = true; queue.append(i) }
        }
    }
    for y in 0..<32 {
        for x in [0, 31] where pixels[index(x, y)] == nil {
            let i = index(x, y)
            if !exterior[i] { exterior[i] = true; queue.append(i) }
        }
    }
    var head = 0
    while head < queue.count {
        let i = queue[head]; head += 1
        let x = i % 32, y = i / 32
        for dy in -1...1 {
            for dx in -1...1 where dx != 0 || dy != 0 {
                let nx = x + dx, ny = y + dy
                if (0..<32).contains(nx), (0..<32).contains(ny) {
                    let ni = index(nx, ny)
                    if pixels[ni] == nil && !exterior[ni] {
                        exterior[ni] = true; queue.append(ni)
                    }
                }
            }
        }
    }
    let sprite = blank(32, 32)
    for y in 0..<32 {
        for x in 0..<32 {
            let i = index(x, y)
            guard let color = pixels[i] else { continue }
            var border = false
            for dy in -1...1 {
                for dx in -1...1 where dx != 0 || dy != 0 {
                    let nx = x + dx, ny = y + dy
                    if !(0..<32).contains(nx) || !(0..<32).contains(ny) ||
                        exterior[index(nx, ny)] { border = true }
                }
            }
            sprite.setColor(border ? outline : color, atX: x, y: y)
        }
    }
    guard let png = sprite.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "DrinkExport", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot encode \(targetURL.path)"])
    }
    try png.write(to: targetURL)
}

func validateSprite(_ url: URL) throws {
    guard let bitmap = NSBitmapImageRep(data: try Data(contentsOf: url)),
          bitmap.pixelsWide == 32, bitmap.pixelsHigh == 32 else {
        throw NSError(domain: "DrinkExport", code: 4,
                      userInfo: [NSLocalizedDescriptionKey: "Wrong size: \(url.path)"])
    }
    var minX = 32, minY = 32, maxX = -1, maxY = -1
    for y in 0..<32 {
        for x in 0..<32 {
            let alpha = bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0
            if alpha > 0.001 && alpha < 0.999 {
                throw NSError(domain: "DrinkExport", code: 5,
                              userInfo: [NSLocalizedDescriptionKey: "Partial alpha: \(url.path)"])
            }
            if alpha >= 0.999 {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }
        }
    }
    if minX < 1 || minY < 1 || maxX > 30 || maxY > 30 ||
        max(maxX - minX + 1, maxY - minY + 1) != 30 {
        throw NSError(domain: "DrinkExport", code: 6,
                      userInfo: [NSLocalizedDescriptionKey: "Footprint: \(url.path) \(minX),\(minY)-\(maxX),\(maxY)"])
    }
}

func contactSheet(_ option: String) throws {
    let cols = 5, rows = 3, tileWidth = 190, tileHeight = 160
    let width = cols * tileWidth, height = rows * tileHeight
    let board = blank(width, height)
    guard let graphics = NSGraphicsContext(bitmapImageRep: board) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    graphics.imageInterpolation = .none
    NSColor(deviceRed: 0.96, green: 0.94, blue: 0.88, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
    for (i, drink) in drinks.enumerated() {
        let col = i % cols, row = i / cols
        let x = col * tileWidth, y = (rows - row - 1) * tileHeight
        NSColor(deviceRed: 0.75, green: 0.68, blue: 0.55, alpha: 1).setStroke()
        NSBezierPath(rect: NSRect(x: x + 2, y: y + 2,
                                  width: tileWidth - 4, height: tileHeight - 4)).stroke()
        let label = "\(option.uppercased())  \(drink.name)" as NSString
        label.draw(at: NSPoint(x: x + 11, y: y + 135),
                   withAttributes: [.font: NSFont.boldSystemFont(ofSize: 13),
                                    .foregroundColor: NSColor(deviceRed: 0.19, green: 0.10,
                                                              blue: 0.10, alpha: 1)])
        let iconURL = option == "current"
            ? URL(fileURLWithPath: "textures/drinks/new_shrine/\(drink.file)")
            : outputURL.appendingPathComponent("option_\(option)/\(drink.file)")
        if let icon = NSImage(contentsOf: iconURL) {
            icon.draw(in: NSRect(x: x + 18, y: y + 21, width: 96, height: 96),
                      from: NSRect(x: 0, y: 0, width: 32, height: 32),
                      operation: .sourceOver, fraction: 1)
            icon.draw(in: NSRect(x: x + 136, y: y + 53, width: 32, height: 32),
                      from: NSRect(x: 0, y: 0, width: 32, height: 32),
                      operation: .sourceOver, fraction: 1)
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    if let png = board.representation(using: .png, properties: [:]) {
        try png.write(to: outputURL.appendingPathComponent("option_\(option)_sheet.png"))
    }
}

for option in ["a", "b"] {
    try manager.createDirectory(at: outputURL.appendingPathComponent("option_\(option)"),
                                withIntermediateDirectories: true)
    for drink in drinks {
        let source = URL(fileURLWithPath: option == "a" ? drink.a : drink.b)
        let destination = outputURL.appendingPathComponent("option_\(option)/\(drink.file)")
        try exportSprite(source, destination)
        try validateSprite(destination)
        print("\(option) \(drink.file)")
    }
    try contactSheet(option)
}
try contactSheet("current")
