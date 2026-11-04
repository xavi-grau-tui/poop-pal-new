// Technical export of ImageGen paintings to the v5 hokora grid.
// This only samples, positions, separates, and previews existing artwork.
import AppKit

let root = "docs/mockups/hokora_homes/v5"
let treeDir = "\(root)/tree_hollow"
let fireDir = "\(root)/fire"
let fm = FileManager.default
try fm.createDirectory(atPath: treeDir, withIntermediateDirectories: true)
try fm.createDirectory(atPath: fireDir, withIntermediateDirectories: true)

func bitmap(_ path: String) throws -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: path))) else {
        throw NSError(domain: "hokora-v5", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot read \(path)"])
    }
    return rep
}
func blank(_ w: Int, _ h: Int) -> NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                     isPlanar: false, colorSpaceName: .deviceRGB,
                     bytesPerRow: 0, bitsPerPixel: 0)!
}
func save(_ rep: NSBitmapImageRep, _ path: String) throws {
    try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
func rgba(_ c: NSColor) -> NSColor {
    let v = c.usingColorSpace(.deviceRGB) ?? c
    return NSColor(deviceRed: v.redComponent, green: v.greenComponent,
                   blue: v.blueComponent, alpha: v.alphaComponent >= 0.5 ? 1 : 0)
}
func opaqueBounds(_ rep: NSBitmapImageRep) -> (Int, Int, Int, Int) {
    var x0 = rep.pixelsWide, y0 = rep.pixelsHigh, x1 = 0, y1 = 0
    for y in 0..<rep.pixelsHigh { for x in 0..<rep.pixelsWide {
        if rep.colorAt(x: x, y: y)!.alphaComponent >= 0.5 {
            x0 = min(x0, x); y0 = min(y0, y)
            x1 = max(x1, x); y1 = max(y1, y)
        }
    }}
    return (x0, y0, x1, y1)
}
func sample(_ rep: NSBitmapImageRep, _ x: Double, _ y: Double) -> NSColor {
    let sx = max(0, min(rep.pixelsWide - 1, Int(x.rounded())))
    let sy = max(0, min(rep.pixelsHigh - 1, Int(y.rounded())))
    return rgba(rep.colorAt(x: sx, y: sy)!)
}
func pixel(_ rep: NSBitmapImageRep, _ x: Int, _ y: Int, _ c: NSColor) {
    rep.setColor(c, atX: x, y: y)
}
func enlarge(_ rep: NSBitmapImageRep, factor: Int) -> NSBitmapImageRep {
    let out = blank(rep.pixelsWide * factor, rep.pixelsHigh * factor)
    for y in 0..<rep.pixelsHigh { for x in 0..<rep.pixelsWide {
        let c = rep.colorAt(x: x, y: y)!
        if c.alphaComponent >= 0.5 {
            for yy in 0..<factor { for xx in 0..<factor {
                pixel(out, x * factor + xx, y * factor + yy, c)
            }}
        }
    }}
    return out
}

// Tree: the three vertical landmarks are the trunk top, the branch across the
// hollow, and the ledges. Piecewise nearest sampling puts them on the guide.
let source = try bitmap("\(treeDir)/tree_source_imagegen.png")
let bounds = opaqueBounds(source)
let whole = blank(220, 220)
let srcTop = Double(bounds.1), srcBranch = 530.0, srcLedge = 865.0
let srcBottom = Double(bounds.3)
for y in 4...199 { for x in 10...211 {
    let sx = Double(bounds.0) + Double(x - 10) / 201.0 * Double(bounds.2 - bounds.0)
    let sy: Double
    if y <= 76 { sy = srcTop + Double(y - 4) / 72.0 * (srcBranch - srcTop) }
    else if y <= 162 { sy = srcBranch + Double(y - 76) / 86.0 * (srcLedge - srcBranch) }
    else { sy = srcLedge + Double(y - 162) / 37.0 * (srcBottom - srcLedge) }
    let c = sample(source, sx, sy)
    if c.alphaComponent > 0 { pixel(whole, x, y, c) }
}}

let front = blank(220, 220)
let inside = blank(220, 220)
for y in 0..<220 { for x in 0..<220 {
    let c = whole.colorAt(x: x, y: y)!
    if c.alphaComponent == 0 { continue }
    if (66...157).contains(x) && (84...161).contains(y) {
        pixel(inside, x, y, c)
    } else {
        pixel(front, x, y, c)
    }
}}
try save(front, "\(treeDir)/front.png")
try save(inside, "\(treeDir)/inside.png")

let stumpSource = try bitmap("\(treeDir)/table_source_imagegen.png")
let tb = opaqueBounds(stumpSource)
let table = blank(220, 220)
for y in 142...162 { for x in 84...139 {
    let sx = Double(tb.0) + Double(x - 84) / 55.0 * Double(tb.2 - tb.0)
    let sy = Double(tb.1) + Double(y - 142) / 20.0 * Double(tb.3 - tb.1)
    let c = sample(stumpSource, sx, sy)
    if c.alphaComponent > 0 { pixel(table, x, y, c) }
}}
for x in 84...139 {
    let c = table.colorAt(x: x, y: 143)!
    if c.alphaComponent > 0 { pixel(table, x, 142, c) }
}
// The generated stump's last source row is only an antialiased fringe. Repeat
// its last solid row once so the separate table actually meets floor row 162.
for x in 84...139 {
    let c = table.colorAt(x: x, y: 161)!
    if c.alphaComponent > 0 { pixel(table, x, 162, c) }
}
try save(table, "\(treeDir)/table.png")

let combined = blank(220, 220)
for layer in [inside, front, table] {
    for y in 0..<220 { for x in 0..<220 {
        let c = layer.colorAt(x: x, y: y)!
        if c.alphaComponent > 0 { pixel(combined, x, y, c) }
    }}
}

let icon = blank(96, 96)
for y in 0..<96 { for x in 0..<96 {
    let sx = Int((Double(x) + 0.5) * 220 / 96)
    let sy = Int((Double(y) + 0.5) * 220 / 96)
    let c = combined.colorAt(x: min(219, sx), y: min(219, sy))!
    if c.alphaComponent > 0 { pixel(icon, x, y, c) }
}}
try save(icon, "\(treeDir)/icon.png")
let preview = enlarge(combined, factor: 8)
try save(preview, "\(treeDir)/preview_8x.png")

// Forest reference on the same 220-art-pixel grid and at the same 8x zoom.
let forest = try bitmap("textures/pet/shrine_new/front.png")
let forest220 = blank(220, 220)
for y in 0..<220 { for x in 0..<220 {
    let c = sample(forest, (Double(x) + 0.5) * Double(forest.pixelsWide) / 220,
                           (Double(y) + 0.5) * Double(forest.pixelsHigh) / 220)
    if c.alphaComponent > 0 { pixel(forest220, x, y, c) }
}}
let forest8 = enlarge(forest220, factor: 8)
let compare = blank(3520, 1760)
for y in 0..<1760 { for x in 0..<3520 {
    let c: NSColor
    if x < 1760 { c = forest8.colorAt(x: x, y: y)! }
    else { c = preview.colorAt(x: x - 1760, y: y)! }
    pixel(compare, x, y, c.alphaComponent > 0 ? c : NSColor(deviceRed: 0.95, green: 0.94, blue: 0.90, alpha: 1))
}}
try save(compare, "\(treeDir)/compare_8x.png")

// Review guide. Dots/lines are placement metadata, kept separate from art.
let guide = blank(220, 220)
let orange = NSColor(deviceRed: 1, green: 0.44, blue: 0.08, alpha: 1)
let yellow = NSColor(deviceRed: 1, green: 0.76, blue: 0.06, alpha: 1)
let blue = NSColor(deviceRed: 0.16, green: 0.35, blue: 0.9, alpha: 1)
let green = NSColor(deviceRed: 0.05, green: 0.62, blue: 0.24, alpha: 1)
for (x, c) in [(22, orange), (50, yellow), (170, yellow)] {
    for yy in 58...62 { for xx in (x-2)...(x+2) {
        if abs(xx-x)+abs(yy-60) <= 2 { pixel(guide, xx, yy, c) }
    }}
}
for x in 66...157 { pixel(guide, x, 72, blue) }
for x in 22...54 { pixel(guide, x, 162, green) }
for x in 166...198 { pixel(guide, x, 162, green) }
try save(guide, "\(treeDir)/guide.png")

// Fire concept: only its silhouette in this review round.
let fireSource = try bitmap("\(fireDir)/silhouette_source_imagegen.png")
let fb = opaqueBounds(fireSource)
let fire = blank(220, 220)
let plum = NSColor(deviceRed: 32.0/255, green: 0, blue: 16.0/255, alpha: 1)
for y in 4...199 { for x in 10...211 {
    // The v5 red-box guide is a hard placement mask for the spirit. It trims
    // only the generated silhouette's inner rock, leaving the drawn exterior.
    if (66...157).contains(x) && (84...163).contains(y) { continue }
    let sx = Double(fb.0) + Double(x-10)/201 * Double(fb.2-fb.0)
    let sy = Double(fb.1) + Double(y-4)/195 * Double(fb.3-fb.1)
    if sample(fireSource, sx, sy).alphaComponent > 0 { pixel(fire, x, y, plum) }
}}
try save(fire, "\(fireDir)/silhouette.png")
let fire8 = enlarge(fire, factor: 8)
try save(fire8, "\(fireDir)/silhouette_8x.png")
let firePreview = blank(1760, 1760)
for y in 0..<1760 { for x in 0..<1760 {
    let c = fire8.colorAt(x: x, y: y)!
    pixel(firePreview, x, y, c.alphaComponent > 0 ? c : NSColor(deviceRed: 0.95, green: 0.94, blue: 0.90, alpha: 1))
}}
try save(firePreview, "\(fireDir)/silhouette_preview_8x.png")

for (label, rep) in [("tree front", front), ("tree inside", inside), ("tree table", table), ("fire silhouette", fire)] {
    print("\(label): \(rep.pixelsWide)x\(rep.pixelsHigh), bounds \(opaqueBounds(rep))")
}
let openingFrontPixels = (84...161).reduce(0) { sum, y in
    sum + (66...157).filter { front.colorAt(x: $0, y: y)!.alphaComponent > 0 }.count
}
print("tree front pixels inside clear spirit opening: \(openingFrontPixels)")
let fireOpeningPixels = (84...163).reduce(0) { sum, y in
    sum + (66...157).filter { fire.colorAt(x: $0, y: y)!.alphaComponent > 0 }.count
}
print("fire silhouette pixels inside clear spirit opening: \(fireOpeningPixels)")
for (label, x) in [("bell", 22), ("lantern L", 50), ("lantern R", 170)] {
    var closest: (Int, Int, Int)? = nil
    for y in 50...70 { for xx in max(0, x-10)...min(219, x+10) {
        if front.colorAt(x: xx, y: y)!.alphaComponent > 0 {
            let d = abs(xx-x) + abs(y-60)
            if closest == nil || d < closest!.2 { closest = (xx, y, d) }
        }
    }}
    print("tree \(label) guide (\(x),60), closest art \(String(describing: closest))")
}

print("v5 Tree Hollow and Fire silhouette exported")
