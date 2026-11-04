// Technical export of ImageGen home paintings on the 220-pixel hokora grid.
// All visible home/table art comes from ImageGen PNGs. This file only places,
// separates and previews the paintings; it draws no design details.
import AppKit

struct Spec {
    let name: String
    let oldName: String
    let roomSource: String
    let topY: Double
    let openingY: Double
    let floorY: Double
    let bottomY: Double
    let left: Int
    let right: Int
}
let specs: [Spec] = [
    .init(name:"neon_cyber",oldName:"neon_cyber",roomSource:"front_colour_with_inside_imagegen.png",topY:40,openingY:425,floorY:1065,bottomY:1220,left:10,right:210),
    .init(name:"moon",oldName:"moon",roomSource:"front_colour_with_inside_imagegen.png",topY:0,openingY:405,floorY:860,bottomY:1210,left:8,right:212),
    .init(name:"golden",oldName:"golden",roomSource:"front_colour_with_inside_imagegen.png",topY:0,openingY:650,floorY:1050,bottomY:1180,left:8,right:212),
    .init(name:"ruined_night",oldName:"ruined_night",roomSource:"front_colour_with_inside_imagegen.png",topY:80,openingY:450,floorY:1030,bottomY:1200,left:8,right:212),
    .init(name:"ramen_stall",oldName:"ramen_stall",roomSource:"front_colour_with_inside_imagegen.png",topY:95,openingY:420,floorY:805,bottomY:1195,left:8,right:212),
    .init(name:"capsule_apartment",oldName:"capsule_apartment",roomSource:"front_colour_with_inside_imagegen.png",topY:170,openingY:270,floorY:760,bottomY:900,left:8,right:212),
    .init(name:"arcade_cabinet",oldName:"arcade_cabinet",roomSource:"front_colour_imagegen.png",topY:20,openingY:280,floorY:1000,bottomY:1220,left:18,right:202),
    .init(name:"bathhouse",oldName:"bathhouse",roomSource:"front_colour_with_inside_imagegen.png",topY:85,openingY:430,floorY:970,bottomY:1180,left:8,right:212),
    .init(name:"fire",oldName:"fire",roomSource:"",topY:20,openingY:440,floorY:1000,bottomY:1220,left:8,right:212)
]

func load(_ path:String) throws -> NSBitmapImageRep {
    guard let rep=NSBitmapImageRep(data:try Data(contentsOf:URL(fileURLWithPath:path))) else { throw NSError(domain:"hokora",code:1) }
    return rep
}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
}
func save(_ rep:NSBitmapImageRep,_ path:String) throws {
    try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))
}
func color(_ rep:NSBitmapImageRep,_ x:Int,_ y:Int)->NSColor { rep.colorAt(x:x,y:y)! }
func solid(_ c:NSColor)->Bool { c.alphaComponent >= 0.5 }
func pixel(_ rep:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:NSColor) { rep.setColor(c,atX:x,y:y) }
func hard(_ c:NSColor)->NSColor {
    let v=c.usingColorSpace(.deviceRGB) ?? c
    return NSColor(deviceRed:v.redComponent,green:v.greenComponent,blue:v.blueComponent,alpha:solid(v) ? 1:0)
}
func bounds(_ rep:NSBitmapImageRep)->(Int,Int,Int,Int) {
    var x0=rep.pixelsWide,y0=rep.pixelsHigh,x1=0,y1=0
    for y in 0..<rep.pixelsHigh { for x in 0..<rep.pixelsWide {
        if solid(color(rep,x,y)) { x0=min(x0,x);y0=min(y0,y);x1=max(x1,x);y1=max(y1,y) }
    }}
    return (x0,y0,x1,y1)
}
func get(_ rep:NSBitmapImageRep,_ x:Double,_ y:Double)->NSColor {
    let xx=max(0,min(rep.pixelsWide-1,Int(x.rounded())))
    let yy=max(0,min(rep.pixelsHigh-1,Int(y.rounded())))
    return hard(color(rep,xx,yy))
}
func normalized(_ rep:NSBitmapImageRep,_ spec:Spec)->NSBitmapImageRep {
    let out=blank(220,220)
    let b=bounds(rep)
    let top=max(Double(b.1),spec.topY),bottom=min(Double(b.3),spec.bottomY)
    // The opening and floor are anchors, so each source keeps its own shape.
    for y in 4...199 { for x in spec.left...spec.right {
        let sx=Double(b.0)+Double(x-spec.left)/Double(spec.right-spec.left)*Double(b.2-b.0)
        let sy:Double
        if y<=72 { sy=top+Double(y-4)/68*(spec.openingY-top) }
        else if y<=162 { sy=spec.openingY+Double(y-72)/90*(spec.floorY-spec.openingY) }
        else { sy=spec.floorY+Double(y-162)/37*(bottom-spec.floorY) }
        let c=get(rep,sx,sy)
        if solid(c) { pixel(out,x,y,c) }
    }}
    return out
}
func grow(_ mask:[[Bool]],by radius:Int)->[[Bool]] {
    var out=mask
    for y in 0..<220 { for x in 0..<220 where mask[y][x] {
        for yy in max(0,y-radius)...min(219,y+radius) { for xx in max(0,x-radius)...min(219,x+radius) {
            out[yy][xx]=true
        }}
    }}
    return out
}
func openingMask(_ front:NSBitmapImageRep)->[[Bool]] {
    var out=Array(repeating:Array(repeating:false,count:220),count:220)
    var queue:[(Int,Int)]=[]
    // Prefer the component containing the spirit position; try nearby pixels
    // if a generated mark happens to cover the exact centre.
    for r in 0...20 {
        if !queue.isEmpty { break }
        for dy in -r...r { for dx in -r...r {
            let x=110+dx,y=112+dy
            if x>=46 && x<=174 && y>=66 && y<=170 && !solid(color(front,x,y)) { queue=[(x,y)];break }
        }}
    }
    var head=0
    while head<queue.count {
        let (x,y)=queue[head];head+=1
        if x<42 || x>178 || y<62 || y>170 || out[y][x] || solid(color(front,x,y)) { continue }
        out[y][x]=true
        queue.append((x-1,y));queue.append((x+1,y));queue.append((x,y-1));queue.append((x,y+1))
    }
    return out
}
func enlarge(_ rep:NSBitmapImageRep,_ n:Int)->NSBitmapImageRep {
    let out=blank(rep.pixelsWide*n,rep.pixelsHigh*n)
    for y in 0..<rep.pixelsHigh { for x in 0..<rep.pixelsWide {
        let c=color(rep,x,y)
        if solid(c) { for yy in 0..<n { for xx in 0..<n { pixel(out,x*n+xx,y*n+yy,c) } } }
    }}
    return out
}

let base="docs/mockups/hokora_homes"
let target=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : "neon_cyber"
guard let spec=specs.first(where:{$0.name==target}) else { fatalError("Unknown home \(target)") }
let dir="\(base)/v5/\(spec.name)"
let source=try load("\(dir)/front_source_imagegen.png")
let front=normalized(source,spec)
let mask=openingMask(front)
let holeCount=mask.flatMap{$0}.filter{$0}.count
if holeCount<500 { fatalError("No usable transparent spirit opening in \(spec.name): \(holeCount) pixels") }
let extra=grow(mask,by:16)
let old="\(base)/\(spec.oldName)/\(spec.roomSource)"
let roomSource=try load(FileManager.default.fileExists(atPath:"\(dir)/inside_source_imagegen.png") ? "\(dir)/inside_source_imagegen.png" : old)
let room=normalized(roomSource,spec)
let inside=blank(220,220)
let roomBack=solid(color(room,110,112)) ? color(room,110,112) : NSColor(deviceRed:0.12,green:0.10,blue:0.17,alpha:1)
var sideMask=Array(repeating:Array(repeating:false,count:220),count:220)
if spec.name == "capsule_apartment" {
    for y in 82...163 { for x in 21...64 where !solid(color(front,x,y)) { sideMask[y][x]=true } }
    for y in 82...163 { for x in 156...199 where !solid(color(front,x,y)) { sideMask[y][x]=true } }
}
let roomCoverage=spec.name == "capsule_apartment" ? grow(sideMask,by:5) : sideMask
for y in 0..<220 { for x in 0..<220 where extra[y][x] {
    let c=color(room,x,y)
    pixel(inside,x,y,solid(c) ? c : roomBack)
}}
if spec.name == "capsule_apartment" {
    for y in 0..<220 { for x in 0..<220 where roomCoverage[y][x] {
        let c=color(room,x,y)
        pixel(inside,x,y,solid(c) ? c : roomBack)
    }}
}
try save(front,"\(dir)/front.png")
try save(inside,"\(dir)/inside.png")
let frontCheck=blank(220,220)
let checkColour=NSColor(deviceRed:0.98,green:0.34,blue:0.72,alpha:1)
for y in 0..<220 { for x in 0..<220 {
    let c=color(front,x,y)
    pixel(frontCheck,x,y,solid(c) ? c : checkColour)
}}
try save(enlarge(frontCheck,8),"\(dir)/front_check_8x.png")

let tableSource=try load("\(dir)/table_source_imagegen.png")
let tb=bounds(tableSource)
let table=blank(220,220)
for y in 142...162 { for x in 84...139 {
    let sx=Double(tb.0)+Double(x-84)/55*Double(tb.2-tb.0)
    let sy=Double(tb.1)+Double(y-142)/20*Double(tb.3-tb.1)
    let c=get(tableSource,sx,sy)
    if solid(c) { pixel(table,x,y,c) }
}}
for x in 84...139 { let c=color(table,x,161);if solid(c) { pixel(table,x,162,c) } }
try save(table,"\(dir)/table.png")

let glass=blank(220,220)
if spec.name == "capsule_apartment" || spec.name == "arcade_cabinet" {
    let gSource=try load("\(dir)/glass_source_imagegen.png")
    let gb=bounds(gSource)
    let regions:[(Int,Int,Int,Int)]=spec.name == "capsule_apartment"
        ? [(21,82,64,163),(156,82,199,163)] : [(47,67,173,156)]
    for (x0,y0,x1,y1) in regions {
        for y in y0...y1 { for x in x0...x1 {
            let isAperture=spec.name == "arcade_cabinet" ? mask[y][x] : sideMask[y][x]
            if !isAperture { continue }
            let gx=Double(gb.0)+Double(x-x0)/Double(x1-x0)*Double(gb.2-gb.0)
            let gy=Double(gb.1)+Double(y-y0)/Double(y1-y0)*Double(gb.3-gb.1)
            let c=get(gSource,gx,gy).usingColorSpace(.deviceRGB)!
            pixel(glass,x,y,NSColor(deviceRed:c.redComponent,green:c.greenComponent,blue:c.blueComponent,alpha:0.38))
        }}
    }
    try save(glass,"\(dir)/glass.png")
}

let combined=blank(220,220)
for layer in [inside,front,glass,table] {
    for y in 0..<220 { for x in 0..<220 {
        let c=color(layer,x,y).usingColorSpace(.deviceRGB)!
        if c.alphaComponent <= 0 { continue }
        let d=color(combined,x,y).usingColorSpace(.deviceRGB)!
        let a=c.alphaComponent
        pixel(combined,x,y,NSColor(deviceRed:c.redComponent*a+d.redComponent*(1-a),green:c.greenComponent*a+d.greenComponent*(1-a),blue:c.blueComponent*a+d.blueComponent*(1-a),alpha:1))
    }}
}
let icon=blank(96,96)
for y in 0..<96 { for x in 0..<96 {
    let sx=min(219,Int((Double(x)+0.5)*220/96)),sy=min(219,Int((Double(y)+0.5)*220/96))
    let c=color(combined,sx,sy);if solid(c) { pixel(icon,x,y,c) }
}}
try save(icon,"\(dir)/icon.png")
let preview=enlarge(combined,8)
try save(preview,"\(dir)/preview_8x.png")
let forest=try load("textures/pet/shrine_new/front.png")
let forest220=blank(220,220)
for y in 0..<220 { for x in 0..<220 {
    let c=get(forest,(Double(x)+0.5)*Double(forest.pixelsWide)/220,(Double(y)+0.5)*Double(forest.pixelsHigh)/220)
    if solid(c) { pixel(forest220,x,y,c) }
}}
let f8=enlarge(forest220,8),compare=blank(3520,1760)
let paper=NSColor(deviceRed:0.95,green:0.94,blue:0.90,alpha:1)
for y in 0..<1760 { for x in 0..<3520 {
    let c=x<1760 ? color(f8,x,y) : color(preview,x-1760,y)
    pixel(compare,x,y,solid(c) ? c : paper)
}}
try save(compare,"\(dir)/compare_8x.png")
let guide=blank(220,220)
let orange=NSColor(deviceRed:1,green:0.44,blue:0.08,alpha:1)
let yellow=NSColor(deviceRed:1,green:0.76,blue:0.06,alpha:1)
let blue=NSColor(deviceRed:0.16,green:0.35,blue:0.9,alpha:1)
let green=NSColor(deviceRed:0.05,green:0.62,blue:0.24,alpha:1)
for (x,c) in [(22,orange),(50,yellow),(170,yellow)] {
    for yy in 58...62 { for xx in (x-2)...(x+2) where abs(xx-x)+abs(yy-60)<=2 { pixel(guide,xx,yy,c) } }
}
for x in 66...157 { pixel(guide,x,72,blue) }
for x in 22...54 { pixel(guide,x,162,green) }
for x in 166...198 { pixel(guide,x,162,green) }
try save(guide,"\(dir)/guide.png")
print("\(spec.name): opening \(holeCount), front \(bounds(front)), inside \(bounds(inside)), table \(bounds(table))")
