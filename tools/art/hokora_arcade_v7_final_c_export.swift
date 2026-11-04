// Export the approved arcade silhouette with its two wing faces on one layer.
// The ImageGen material pass supplies colour; the v7 final_b grid locks geometry.
import AppKit
import Foundation

typealias C = (UInt8, UInt8, UInt8, UInt8)
let root = "docs/mockups/hokora_homes/v7/arcade_cabinet"
let dir = "\(root)/final_c"
try! FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
func load(_ path: String) -> NSBitmapImageRep {
  NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: path)))!
}
func blank(_ w: Int, _ h: Int) -> NSBitmapImageRep {
  let i = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  memset(i.bitmapData!, 0, i.bytesPerRow * h)
  return i
}
func get(_ i: NSBitmapImageRep, _ x: Int, _ y: Int) -> C {
  let p = i.bitmapData!, j = y * i.bytesPerRow + x * 4
  return (p[j], p[j+1], p[j+2], p[j+3])
}
func put(_ i: NSBitmapImageRep, _ x: Int, _ y: Int, _ c: C) {
  let p = i.bitmapData!, j = y * i.bytesPerRow + x * 4
  p[j] = c.0; p[j+1] = c.1; p[j+2] = c.2; p[j+3] = c.3
}
func save(_ i: NSBitmapImageRep, _ name: String) {
  try! i.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
}
let approved = load("\(root)/final_b/front.png")
let finish = load("\(dir)/source_imagegen.png")
let oldInside = load("docs/mockups/hokora_homes/v6_2/arcade_cabinet/inside.png")
let front = blank(220,220), trays = blank(220,220), inside = blank(220,220)
let clear: C = (0,0,0,0)
func wing(_ x: Int, _ y: Int) -> Bool {
  let u = min(x, 219-x)
  if (140...165).contains(y) { return u <= 55 }
  if (166...171).contains(y) { return u <= 45 }
  return false
}
for y in 0..<220 { for x in 0..<220 {
  let a = get(approved,x,y)
  if a.3 == 0 { continue }
  let sx = min(finish.pixelsWide-1, Int((Double(x)+0.5)*Double(finish.pixelsWide)/220))
  let sy = min(finish.pixelsHigh-1, Int((Double(y)+0.5)*Double(finish.pixelsHigh)/220))
  let g = get(finish,sx,sy)
  // Keep the approved shape and hard alpha. Fall back to its colour if the
  // generated finish varies at a geometrically important edge.
  let c: C = g.3 >= 128 ? (g.0,g.1,g.2,255) : a
  if wing(x,y) { put(trays,x,y,c) } else { put(front,x,y,c) }
}}
// Continue the cabinet's red pillar behind each removed wing. The tray layer
// hides this backing in the complete view, while the isolated front remains sound.
for y in 140...171 { for x in 36...55 {
  if get(front,x,y).3 == 0 && get(trays,x,y).3 > 0 {
    let template = get(approved,min(65,max(57,x+17)),y)
    let red: C = template.3 > 0 && template.0 > template.2
      ? (template.0,template.1,template.2,255) : (196,35,50,255)
    put(front,x,y,red)
    put(front,219-x,y,red)
  }
}}
// Restore the approved 80 x 78 aperture. The older navy/plum screen room is
// scaled into a 92 x 90 panel (six pixels beyond each aperture edge for tilt).
for y in 61...150 { for x in 64...155 {
  let ox = min(176,46+(x-64)*131/92)
  let oy = min(157,65+(y-61)*93/90)
  let c = get(oldInside,ox,oy)
  put(inside,x,y,c.3 > 0 ? (c.0,c.1,c.2,255) : (30,17,48,255))
}}
for y in 67...144 { for x in 70...149 { put(front,x,y,clear) }}
save(front,"front"); save(trays,"trays"); save(inside,"inside")
let guide = blank(220,220)
func dot(_ x: Int, _ y: Int, _ c: C) {
  for dy in -1...1 { for dx in -1...1 { put(guide,x+dx,y+dy,c) }}
}
dot(44,22,(255,139,46,255))
dot(56,72,(255,221,40,255))
dot(163,72,(255,221,40,255))
dot(25,144,(49,227,100,255))
dot(194,144,(49,227,100,255))
save(guide,"guide")
func over(_ dst: NSBitmapImageRep, _ src: NSBitmapImageRep) {
  for y in 0..<220 { for x in 0..<220 {
    let c = get(src,x,y); if c.3 > 0 { put(dst,x,y,c) }
  }}
}
let combined = blank(220,220)
over(combined,inside); over(combined,front); over(combined,trays)
let preview = blank(1760,1760)
for y in 0..<1760 { for x in 0..<1760 { put(preview,x,y,get(combined,x/8,y/8)) }}
save(preview,"preview_8x")
let icon = blank(96,96)
for y in 0..<96 { for x in 0..<96 {
  put(icon,x,y,get(combined,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))
}}
save(icon,"icon")
var badAlpha = 0, screenHoles = 0, missingTrays = 0
for y in 0..<220 { for x in 0..<220 {
  for layer in [front,trays,inside] { let a=get(layer,x,y).3; if a != 0 && a != 255 {badAlpha += 1} }
  if (70...149).contains(x) && (67...144).contains(y) {
    if get(front,x,y).3 != 0 || get(inside,x,y).3 != 255 { screenHoles += 1 }
  }
  if wing(x,y) && get(approved,x,y).3 > 0 && get(trays,x,y).3 == 0 { missingTrays += 1 }
}}
precondition(badAlpha == 0 && screenHoles == 0 && missingTrays == 0)
print("Arcade final_c: 220-grid, hard alpha; 80x78 screen and 6px room margin; two tray faces aligned; validation passed")
