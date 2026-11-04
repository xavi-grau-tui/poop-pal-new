// Technical placement of the two ImageGen-painted shelves. Existing cabinet
// pixels are copied byte-for-byte; the script paints no new artwork.
import AppKit
import Foundation

let base="docs/mockups/hokora_homes"
let prior="\(base)/v6_2/arcade_cabinet"
let out="\(base)/v6_3/arcade_cabinet"
func load(_ path:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:path)))!}
func save(_ im:NSBitmapImageRep,_ path:String) {try! im.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))}
func pixel(_ im:NSBitmapImageRep,_ x:Int,_ y:Int)->(UInt8,UInt8,UInt8,UInt8) {
    let p=im.bitmapData!,j=y*im.bytesPerRow+x*4
    return(p[j],p[j+1],p[j+2],p[j+3])
}
func put(_ im:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:(UInt8,UInt8,UInt8,UInt8)) {
    let p=im.bitmapData!,j=y*im.bytesPerRow+x*4
    p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3
}
let source=load("\(base)/v6_3/sources/arcade_shelves_imagegen.png")
let front=load("\(prior)/front.png"),guide=load("\(prior)/guide.png"),preview=load("\(prior)/preview_8x.png")
precondition(front.samplesPerPixel==4 && front.bitsPerPixel==32 && guide.samplesPerPixel==4 && preview.samplesPerPixel==4)
precondition(front.pixelsWide==220 && front.pixelsHigh==220 && preview.pixelsWide==1760 && preview.pixelsHigh==1760)

func sourceBounds(_ leftHalf:Bool)->(Int,Int,Int,Int) {
    let x0=leftHalf ? 0 : source.pixelsWide/2
    let x1=leftHalf ? source.pixelsWide/2 : source.pixelsWide
    var l=x1,t=source.pixelsHigh,r=x0,b=0
    for y in 0..<source.pixelsHigh {for x in x0..<x1 {
        if source.colorAt(x:x,y:y)!.alphaComponent>=0.5 {l=min(l,x);r=max(r,x);t=min(t,y);b=max(b,y)}
    }}
    precondition(l<=r)
    return(l,t,r,b)
}
// Source shelves have a 2:1 width/height, so their 33x17 reduction keeps that
// proportion. The outer two canvas pixels stay empty; the inner ends attach
// to the original control-panel sides.
let placement=[(true,2),(false,185)]
var newPixels=0
for (leftHalf,x0) in placement {
    let b=sourceBounds(leftHalf),sw=b.2-b.0+1,sh=b.3-b.1+1
    for dy in 0..<17 {for dx in 0..<33 {
        let sx=b.0+min(sw-1,Int(Double(dx)*Double(sw)/33.0))
        let sy=b.1+min(sh-1,Int(Double(dy)*Double(sh)/17.0))
        let color=source.colorAt(x:sx,y:sy)!.usingColorSpace(.deviceRGB)!
        if color.alphaComponent<0.5 {continue}
        let c=(UInt8((color.redComponent*255).rounded()),UInt8((color.greenComponent*255).rounded()),UInt8((color.blueComponent*255).rounded()),UInt8(255))
        let x=x0+dx,y=143+dy
        put(front,x,y,c)
        for py in (y*8)..<(y*8+8) {for px in (x*8)..<(x*8+8) {put(preview,px,py,c)}}
        newPixels+=1
    }}
    print("\(leftHalf ? "left" : "right") shelf source \(sw)x\(sh), game position x=\(x0)..\(x0+32), y=143..159")
}
// Replace the old shelf-top guide strokes at y=162 with one green 3x3 dot on
// the middle of each new flat top, leaving bell hooks and the beam unchanged.
for y in 0..<220 {for x in 0..<220 {let c=pixel(guide,x,y);if c.0==0 && c.1==170 && c.2==77 && c.3>0 {put(guide,x,y,(0,0,0,0))}}}
for center in [18,201] {for y in 142...144 {for x in (center-1)...(center+1) {put(guide,x,y,(0,170,77,255))}}}
save(front,"\(out)/front.png")
save(guide,"\(out)/guide.png")
save(preview,"\(out)/preview_8x.png")
print("placed \(newPixels) shelf pixels")
