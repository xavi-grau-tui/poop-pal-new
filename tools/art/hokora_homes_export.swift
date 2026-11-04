// Technical export only: nearest-neighbour placement of ImageGen art on the
// game's 110-pixel grid. This script does not create or repaint any artwork.
import AppKit

struct Home {
    let name: String
    let floorSourceY: Double
    let left: Double
    let right: Double
    let top: Double
    let bottom: Double
}

let root = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/mockups/hokora_homes"
let homes = [
    Home(name:"neon_cyber",floorSourceY:1030,left:10,right:100,top:8,bottom:103),
    Home(name:"moon",floorSourceY:860,left:4,right:106,top:8,bottom:105),
    Home(name:"golden",floorSourceY:1055,left:6,right:104,top:3,bottom:103),
    Home(name:"ruined_night",floorSourceY:835,left:3,right:107,top:8,bottom:105),
    Home(name:"tree_hollow",floorSourceY:995,left:5,right:105,top:4,bottom:105),
    Home(name:"ramen_stall",floorSourceY:650,left:4,right:106,top:16,bottom:105),
    Home(name:"capsule_apartment",floorSourceY:720,left:4,right:106,top:19,bottom:105),
    Home(name:"arcade_cabinet",floorSourceY:875,left:10,right:100,top:5,bottom:105),
    Home(name:"bathhouse",floorSourceY:730,left:4,right:106,top:18,bottom:104)
]

func save(_ rep:NSBitmapImageRep, _ path:String) throws {
    try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))
}
func blank(_ width:Int,_ height:Int)->NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,
        bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,
        colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
}
for home in homes {
    let dir="\(root)/\(home.name)"
    let fittedPath="\(dir)/front_colour_fitted_imagegen.png"
    let hookedPath="\(dir)/front_colour_hooked_imagegen.png"
    let sourcePath = FileManager.default.fileExists(atPath:hookedPath) ? hookedPath
        : FileManager.default.fileExists(atPath:fittedPath) ? fittedPath
        : (home.name == "capsule_apartment" ? "\(dir)/front_colour_with_inside_imagegen.png"
        : "\(dir)/front_colour_imagegen.png")
    let source=NSBitmapImageRep(data:try Data(contentsOf:URL(fileURLWithPath:sourcePath)))!
    let editedPath="\(dir)/front_colour_with_inside_imagegen.png"
    let edited=FileManager.default.fileExists(atPath:editedPath)
        ? NSBitmapImageRep(data:try Data(contentsOf:URL(fileURLWithPath:editedPath)))!
        : source
    var minX=source.pixelsWide, minY=source.pixelsHigh, maxX=0, maxY=0
    for y in 0..<source.pixelsHigh { for x in 0..<source.pixelsWide {
        if source.colorAt(x:x,y:y)!.alphaComponent > 0.5 {
            minX=min(minX,x); minY=min(minY,y); maxX=max(maxX,x); maxY=max(maxY,y)
        }
    }}
    let out=blank(110,110)
    let inside=blank(110,110)
    let targetFloor=83.0
    for y in 0..<110 { for x in 0..<110 {
        let dx=Double(x), dy=Double(y)
        guard dx >= home.left && dx <= home.right && dy >= home.top && dy <= home.bottom else { continue }
        let sx=Double(minX)+(dx-home.left)/(home.right-home.left)*Double(maxX-minX)
        let sy:Double
        if dy <= targetFloor {
            sy=Double(minY)+(dy-home.top)/(targetFloor-home.top)*(home.floorSourceY-Double(minY))
        } else {
            sy=home.floorSourceY+(dy-targetFloor)/(home.bottom-targetFloor)*(Double(maxY)-home.floorSourceY)
        }
        let ix=max(0,min(source.pixelsWide-1,Int(sx.rounded())))
        let iy=max(0,min(source.pixelsHigh-1,Int(sy.rounded())))
        let color=source.colorAt(x:ix,y:iy)!
        let editColor=edited.colorAt(x:max(0,min(edited.pixelsWide-1,ix)),y:max(0,min(edited.pixelsHigh-1,iy)))!
        if color.alphaComponent >= 0.5 {
            let c=color.usingColorSpace(.deviceRGB) ?? color
            out.setColor(NSColor(deviceRed:c.redComponent,green:c.greenComponent,
                blue:c.blueComponent,alpha:1),atX:x,y:y)
        } else if editColor.alphaComponent >= 0.5 && x>=25 && x<=84 && y>=29 && y<83 {
            let c=editColor.usingColorSpace(.deviceRGB) ?? editColor
            inside.setColor(NSColor(deviceRed:c.redComponent,green:c.greenComponent,
                blue:c.blueComponent,alpha:1),atX:x,y:y)
        }
    }}
    // Capsule and arcade were generated with their recessed rooms already in
    // the original picture. Separate only their dark central backing pixels.
    if ["capsule_apartment","arcade_cabinet","golden","ruined_night","tree_hollow","moon"].contains(home.name) {
        for y in 31..<83 { for x in 29..<81 {
            guard let c=out.colorAt(x:x,y:y), c.alphaComponent >= 0.5 else { continue }
            let rgb=c.usingColorSpace(.deviceRGB) ?? c
            if (rgb.redComponent+rgb.greenComponent+rgb.blueComponent)/3 < 0.36 {
                inside.setColor(c,atX:x,y:y)
                out.setColor(NSColor(deviceRed:0,green:0,blue:0,alpha:0),atX:x,y:y)
            }
        }}
    }
    // The spirit and movable shelf objects render over these reserved zones.
    // Move any remaining source pixels into the back layer; retain their exact
    // image pixels, without repainting or changing the assembled picture.
    for y in 48..<83 { for x in 39...71 {
        if let c=out.colorAt(x:x,y:y),c.alphaComponent>=0.5 {
            inside.setColor(c,atX:x,y:y)
            out.setColor(NSColor(deviceRed:0,green:0,blue:0,alpha:0),atX:x,y:y)
        }
    }}
    for y in 69..<83 { for x in Array(14...26)+Array(84...96) {
        if let c=out.colorAt(x:x,y:y),c.alphaComponent>=0.5 {
            inside.setColor(c,atX:x,y:y)
            out.setColor(NSColor(deviceRed:0,green:0,blue:0,alpha:0),atX:x,y:y)
        }
    }}
    let layerNames=["front","side","side_back","floor","floor_side","near","land"]
    var layers:[String:NSBitmapImageRep]=[:]
    for name in layerNames { layers[name]=blank(110,110) }
    for y in 0..<110 { for x in 0..<110 {
        guard let c=out.colorAt(x:x,y:y), c.alphaComponent >= 0.5 else { continue }
        let name:String
        if y>=100 { name="land" }
        else if y>=96 { name=(x<29 || x>80) ? "near" : "floor_side" }
        else if y>=90 { name=(x<29 || x>80) ? "near" : "floor_side" }
        else if y>=83 { name=(x<29 || x>80) ? "near" : "floor" }
        else if y>=48 && x<39 { name="side" }
        else if y>=48 && x>71 { name="side_back" }
        else { name="front" }
        layers[name]!.setColor(c,atX:x,y:y)
    }}
    for name in layerNames { try save(layers[name]!,"\(dir)/\(name)_110.png") }
    try save(inside,"\(dir)/inside_110.png")
    let combined=blank(110,110)
    for y in 0..<110 { for x in 0..<110 {
        if let a=out.colorAt(x:x,y:y),a.alphaComponent>=0.5 { combined.setColor(a,atX:x,y:y) }
        else if let b=inside.colorAt(x:x,y:y),b.alphaComponent>=0.5 { combined.setColor(b,atX:x,y:y) }
    }}
    let icon=blank(96,96)
    for y in 0..<96 { for x in 0..<96 {
        let sx=min(109,Int((Double(x)+0.5)*110/96)), sy=min(109,Int((Double(y)+0.5)*110/96))
        if let c=combined.colorAt(x:sx,y:sy),c.alphaComponent>=0.5 { icon.setColor(c,atX:x,y:y) }
    }}
    try save(icon,"\(dir)/icon_96.png")
    try save(out,"\(dir)/front_colour_110.png")
    try save(combined,"\(dir)/front_colour_complete_110.png")
    let preview=blank(880,880)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:preview)
    NSGraphicsContext.current?.imageInterpolation = .none
    NSColor(deviceRed:0.96,green:0.94,blue:0.90,alpha:1).setFill()
    NSRect(x:0,y:0,width:880,height:880).fill()
    let image=NSImage(data:combined.representation(using:.png,properties:[:])!)!
    image.draw(in:NSRect(x:0,y:0,width:880,height:880),from:.zero,
        operation:.sourceOver,fraction:1,respectFlipped:true,
        hints:[.interpolation:NSImageInterpolation.none])
    NSGraphicsContext.restoreGraphicsState()
    try save(preview,"\(dir)/front_colour_preview_8x.png")
    print(home.name)
}
