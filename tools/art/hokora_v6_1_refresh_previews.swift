// Refresh approved Tree and Ruined Night previews with their new one-piece tables.
import AppKit
import Foundation
let root="docs/mockups/hokora_homes/v6_1"
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!;memset(i.bitmapData!,0,i.bytesPerRow*h);return i}
func pixel(_ im:NSBitmapImageRep,_ x:Int,_ y:Int)->(UInt8,UInt8,UInt8,UInt8) {let p=im.bitmapData!,j=y*im.bytesPerRow+x*4;return(p[j],p[j+1],p[j+2],p[j+3])}
func put(_ im:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:(UInt8,UInt8,UInt8,UInt8)) {let p=im.bitmapData!,j=y*im.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3}
func save(_ im:NSBitmapImageRep,_ p:String) {try! im.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:p))}
for home in ["tree_hollow","ruined_night"] {
    let d="\(root)/\(home)",out=blank(220,220)
    for file in ["inside.png","front.png","table.png"] {
        let layer=load("\(d)/\(file)")
        for y in 0..<220 {for x in 0..<220 {
            let c=pixel(layer,x,y)
            if c.3>127 {put(out,x,y,c)}
        }}
    }
    let preview=blank(1760,1760)
    for y in 0..<1760 {for x in 0..<1760 {put(preview,x,y,pixel(out,x/8,y/8))}}
    save(preview,"\(d)/preview_8x.png")
    print("\(home): refreshed")
}
