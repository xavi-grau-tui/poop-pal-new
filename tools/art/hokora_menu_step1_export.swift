// Technical nearest-neighbour export of approved ImageGen UI paintings.
import AppKit
import Foundation
func load(_ p:String)->NSBitmapImageRep { NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))! }
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
    let a=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    if let p=a.bitmapData { memset(p,0,a.bytesPerRow*h) };return a
}
func bounds(_ a:NSBitmapImageRep)->(Int,Int,Int,Int) {
    var l=a.pixelsWide,t=a.pixelsHigh,r=0,b=0
    for y in 0..<a.pixelsHigh { for x in 0..<a.pixelsWide where a.colorAt(x:x,y:y)!.alphaComponent>=0.5 {
        l=min(l,x);t=min(t,y);r=max(r,x);b=max(b,y)
    }}
    return (l,t,r,b)
}
let root="docs/mockups/menu_frames/v1"
for material in ["paper","wood"] {
    let dir="\(root)/\(material)"
    for (name,w,h) in [("slide_frame",100,98),("logo_plate",74,46),("stats_plate",74,22)] {
        let src=load("\(dir)/source_\(name)_imagegen.png")
        let (l,t,r,b)=bounds(src)
        let out=blank(w,h)
        for y in 0..<h { for x in 0..<w {
            let sx=l+x*(r-l+1)/w,sy=t+y*(b-t+1)/h
            let c=src.colorAt(x:sx,y:sy)!.usingColorSpace(.deviceRGB)!
            if c.alphaComponent>=0.5 {
                out.setColor(NSColor(deviceRed:c.redComponent,green:c.greenComponent,blue:c.blueComponent,alpha:1),atX:x,y:y)
            }
        }}
        try! out.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(dir)/\(name).png"))
        let preview=blank(w*8,h*8)
        for y in 0..<h { for x in 0..<w {
            let c=out.colorAt(x:x,y:y)!
            if c.alphaComponent>=0.5 { for yy in 0..<8 { for xx in 0..<8 { preview.setColor(c,atX:x*8+xx,y:y*8+yy) } } }
        }}
        try! preview.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(dir)/\(name)_8x.png"))
        print("\(material)/\(name) \(w)x\(h)")
    }
}
