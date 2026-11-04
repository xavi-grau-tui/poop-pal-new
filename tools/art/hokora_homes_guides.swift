// Technical fit overlays for the ImageGen home concepts.
import AppKit

struct Anchors { let home:String; let bell:(Int,Int); let left:(Int,Int); let right:(Int,Int) }
let anchors:[Anchors] = [
    .init(home:"neon_cyber",bell:(13,29),left:(25,30),right:(85,30)),
    .init(home:"moon",bell:(9,43),left:(29,33),right:(81,33)),
    .init(home:"golden",bell:(16,32),left:(22,35),right:(88,35)),
    .init(home:"ruined_night",bell:(11,30),left:(25,30),right:(85,30)),
    .init(home:"tree_hollow",bell:(11,21),left:(26,30),right:(86,32)),
    .init(home:"ramen_stall",bell:(11,30),left:(25,30),right:(85,30)),
    .init(home:"capsule_apartment",bell:(14,31),left:(25,30),right:(85,30)),
    .init(home:"arcade_cabinet",bell:(18,29),left:(23,29),right:(82,30)),
    .init(home:"bathhouse",bell:(11,30),left:(25,30),right:(85,30))
]
let root=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : "docs/mockups/hokora_homes"
func blank()->NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:110,pixelsHigh:110,bitsPerSample:8,
        samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,
        bytesPerRow:0,bitsPerPixel:0)!
}
func rect(_ r:NSBitmapImageRep,_ x1:Int,_ y1:Int,_ x2:Int,_ y2:Int,_ c:NSColor) {
    for x in x1...x2 { r.setColor(c,atX:x,y:y1);r.setColor(c,atX:x,y:y2) }
    for y in y1...y2 { r.setColor(c,atX:x1,y:y);r.setColor(c,atX:x2,y:y) }
}
func dot(_ r:NSBitmapImageRep,_ xy:(Int,Int),_ c:NSColor) {
    for y in (xy.1-1)...(xy.1+1) { for x in (xy.0-1)...(xy.0+1) {
        r.setColor(c,atX:x,y:y)
    }}
}
let red=NSColor(deviceRed:0.92,green:0.12,blue:0.13,alpha:1)
let green=NSColor(deviceRed:0.08,green:0.72,blue:0.15,alpha:1)
let blue=NSColor(deviceRed:0.10,green:0.35,blue:0.92,alpha:1)
let orange=NSColor(deviceRed:1,green:0.48,blue:0.02,alpha:1)
let yellow=NSColor(deviceRed:1,green:0.82,blue:0.02,alpha:1)
for a in anchors {
    let guide=blank()
    rect(guide,39,48,71,83,red)
    rect(guide,14,69,26,83,green)
    rect(guide,84,69,96,83,green)
    rect(guide,30,28,80,46,blue)
    for x in 5...105 { guide.setColor(red,atX:x,y:83) }
    dot(guide,a.bell,orange);dot(guide,a.left,yellow);dot(guide,a.right,yellow)
    let data=guide.representation(using:.png,properties:[:])!
    try data.write(to:URL(fileURLWithPath:"\(root)/\(a.home)/guide_points_110.png"))
    let art=NSBitmapImageRep(data:try Data(contentsOf:URL(fileURLWithPath:"\(root)/\(a.home)/front_colour.png")))!
    let check=blank()
    for y in 0..<110 { for x in 0..<110 {
        if let c=art.colorAt(x:x,y:y),c.alphaComponent>=0.5 { check.setColor(c,atX:x,y:y) }
        if let c=guide.colorAt(x:x,y:y),c.alphaComponent>=0.5 { check.setColor(c,atX:x,y:y) }
    }}
    try check.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(root)/\(a.home)/fit_check_110.png"))
}
