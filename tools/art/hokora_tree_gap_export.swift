// Technical nearest-neighbour placement of ImageGen Tree Hollow interior edit.
import AppKit
import Foundation
func read(_ p:String)->NSBitmapImageRep { NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))! }
let base="docs/mockups/hokora_homes/v5/tree_hollow"
let out="docs/mockups/hokora_decor/round3/tree_hollow"
let old=read("\(base)/front.png")
// Export the separately generated interior repaint at the approved interior's placement.
let interiorSource=read("\(out)/source_inside_open_roots_precise_imagegen.png")
let oldInside=read("\(base)/inside.png")
func alphaBounds(_ a:NSBitmapImageRep)->(Int,Int,Int,Int) {
    var l=a.pixelsWide,t=a.pixelsHigh,r=0,b=0
    for y in 0..<a.pixelsHigh { for x in 0..<a.pixelsWide where a.colorAt(x:x,y:y)!.alphaComponent>0.5 {
        l=min(l,x);t=min(t,y);r=max(r,x);b=max(b,y)
    }}
    return (l,t,r,b)
}
let (sl,st,sr,sb)=alphaBounds(interiorSource)
let (dl,dt,dr,db)=alphaBounds(oldInside)
let interior=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:220,pixelsHigh:220,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
if let p=interior.bitmapData { memset(p,0,interior.bytesPerRow*220) }
for y in 0..<220 { for x in 0..<220 {
    let c=oldInside.colorAt(x:x,y:y)!
    if c.alphaComponent>=0.5 { interior.setColor(c,atX:x,y:y) }
} }
for y in dt...db { for x in dl...dr {
    let sx=sl+(x-dl)*(sr-sl+1)/(dr-dl+1)
    let sy=st+(y-dt)*(sb-st+1)/(db-dt+1)
    let c=interiorSource.colorAt(x:sx,y:sy)!.usingColorSpace(.deviceRGB)!
    if x>=75 && x<=145 && y>=89 && y<=144 && c.alphaComponent>=0.5 && oldInside.colorAt(x:x,y:y)!.alphaComponent>=0.5 {
        interior.setColor(NSColor(deviceRed:c.redComponent,green:c.greenComponent,blue:c.blueComponent,alpha:1),atX:x,y:y)
    }
}}
try! interior.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(out)/inside_open_roots.png"))
let front=old,table=read("\(base)/table.png")
let preview=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:220*8,pixelsHigh:220*8,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
if let p=preview.bitmapData { memset(p,0,preview.bytesPerRow*preview.pixelsHigh) }
for y in 0..<220 { for x in 0..<220 {
    if let v=[interior.colorAt(x:x,y:y)!,front.colorAt(x:x,y:y)!,table.colorAt(x:x,y:y)!].last(where:{$0.alphaComponent>=0.5}) {
        for yy in 0..<8 { for xx in 0..<8 { preview.setColor(v,atX:x*8+xx,y:y*8+yy) } }
    }
}}
try! preview.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(out)/tree_gap_preview_8x.png"))
