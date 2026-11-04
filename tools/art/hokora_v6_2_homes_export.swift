// Technical game-grid export of the v6.2 ImageGen fronts and the Ruined Night mask fix.
// No new shapes are painted by this script.
import AppKit
import Foundation

let root="docs/mockups/hokora_homes"
typealias C=(UInt8,UInt8,UInt8,UInt8)
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {let o=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!;memset(o.bitmapData!,0,o.bytesPerRow*h);return o}
func read(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->C {let c=i.colorAt(x:x,y:y)!.usingColorSpace(.deviceRGB)!;return(UInt8((c.redComponent*255).rounded()),UInt8((c.greenComponent*255).rounded()),UInt8((c.blueComponent*255).rounded()),UInt8((c.alphaComponent*255).rounded()))}
func write(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:C) {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3}
func save(_ i:NSBitmapImageRep,_ p:String) {try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:p))}
func bounds(_ i:NSBitmapImageRep)->(Int,Int,Int,Int) {var l=i.pixelsWide,t=i.pixelsHigh,r=0,b=0;for y in 0..<i.pixelsHigh {for x in 0..<i.pixelsWide where read(i,x,y).3>=128 {l=min(l,x);r=max(r,x);t=min(t,y);b=max(b,y)}};return(l,t,r,b)}
func normal(_ src:NSBitmapImageRep,_ left:Int,_ right:Int,_ anchors:[(Int,Double)])->NSBitmapImageRep {
    let out=blank(220,220),b=bounds(src)
    for y in 4...199 {for x in left...right {
        let sx=Double(b.0)+Double(x-left)/Double(right-left)*Double(b.2-b.0)
        var sy=anchors.last!.1
        for j in 0..<anchors.count-1 where y>=anchors[j].0 && y<=anchors[j+1].0 {
            let a=anchors[j],z=anchors[j+1],f=Double(y-a.0)/Double(z.0-a.0)
            sy=a.1+(z.1-a.1)*f;break
        }
        let ix=max(0,min(src.pixelsWide-1,Int(sx.rounded()))),iy=max(0,min(src.pixelsHigh-1,Int(sy.rounded())))
        let c=read(src,ix,iy);if c.3>=128 {write(out,x,y,(c.0,c.1,c.2,255))}
    }}
    return out
}
func copy(_ from:String,_ to:String) {try? FileManager.default.removeItem(atPath:to);try! FileManager.default.copyItem(atPath:from,toPath:to)}
func placeTable(_ source:String,_ path:String) {
    let s=load(source),o=blank(220,220)
    for y in 0..<22 {for x in 0..<58 {let c=read(s,x*2,y*2);if c.3>=128 {write(o,81+x,140+y,(c.0,c.1,c.2,255))}}}
    save(o,path)
}
func compose(_ files:[String])->NSBitmapImageRep {
    let o=blank(220,220)
    for file in files {let i=load(file);for y in 0..<220 {for x in 0..<220 {
        let c=read(i,x,y);if c.3==0 {continue};let a=Double(c.3)/255,d=read(o,x,y)
        write(o,x,y,(UInt8((Double(c.0)*a+Double(d.0)*(1-a)).rounded()),UInt8((Double(c.1)*a+Double(d.1)*(1-a)).rounded()),UInt8((Double(c.2)*a+Double(d.2)*(1-a)).rounded()),255))
    }}}
    return o
}
func finish(_ home:String,_ layers:[String]) {
    let dir="\(root)/v6_2/\(home)",o=compose(layers)
    let preview=blank(1760,1760)
    for y in 0..<1760 {for x in 0..<1760 {write(preview,x,y,read(o,x/8,y/8))}}
    save(preview,"\(dir)/preview_8x.png")
    let icon=blank(96,96)
    for y in 0..<96 {for x in 0..<96 {write(icon,x,y,read(o,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))}}
    save(icon,"\(dir)/icon.png")
    print("\(home): preview 1760x1760, icon 96x96")
}
// Ruined Night: restore the source's irregular transparent aperture. The old
// rectangular safety cut erased the broken edges. Extend the existing room
// colour underneath the full aperture so no hard bar can show through it.
do {
    let home="ruined_night",d="\(root)/v6_2/\(home)",src=load("\(root)/v6/\(home)/front_source_imagegen.png")
    try! FileManager.default.createDirectory(atPath:d,withIntermediateDirectories:true)
    let front=normal(src,8,212,[(4,30),(72,450),(162,1030),(199,1200)])
    save(front,"\(d)/front.png")
    let old=load("\(root)/v5/\(home)/inside.png"),inside=blank(220,220)
    for y in 62...168 {for x in 58...173 {write(inside,x,y,(31,38,51,255))}}
    for y in 0..<220 {for x in 0..<220 {let c=read(old,x,y);if c.3>0 {write(inside,x,y,c)}}}
    save(inside,"\(d)/inside.png")
    copy("\(root)/v6_1/\(home)/table.png","\(d)/table.png")
    copy("\(root)/v6_1/\(home)/guide.png","\(d)/guide.png")
    finish(home,["\(d)/inside.png","\(d)/front.png","\(d)/table.png"])
}
// Arcade: retain the ImageGen-painted joystick, buttons and actual gap. Never
// apply the v6.1 full-height rectangular control-panel erasure here.
do {
    let home="arcade_cabinet",d="\(root)/v6_2/\(home)",src=load("\(d)/front_source_imagegen.png")
    let front=normal(src,18,202,[(4,15),(72,280),(162,1000),(199,1220)])
    // Keep the already ImageGen-painted small bell bracket from v6.1. The new
    // cabinet eave joins it at x=38, and the existing orange guide dot stays
    // attached at (28,70), left of the lantern.
    let prior=load("\(root)/v6_1/\(home)/front.png")
    for y in 62...78 {for x in 24...39 {
        let c=read(prior,x,y)
        if c.3>0 && read(front,x,y).3==0 {write(front,x,y,c)}
    }}
    save(front,"\(d)/front.png")
    copy("\(root)/v5/\(home)/inside.png","\(d)/inside.png")
    copy("\(root)/v5/\(home)/glass.png","\(d)/glass.png")
    copy("\(root)/v6_1/\(home)/guide.png","\(d)/guide.png")
    placeTable("\(root)/v6/tables/arcade_cabinet_table_front_116.png","\(d)/table.png")
    finish(home,["\(d)/inside.png","\(d)/front.png","\(d)/glass.png","\(d)/table.png"])
}
// Capsule: the new square ImageGen painting includes a taller proper roof and
// a round hatch. The anchors preserve its round central ring on the 220 grid.
do {
    let home="capsule_apartment",d="\(root)/v6_2/\(home)",src=load("\(d)/front_source_imagegen.png")
    let front=normal(src,8,212,[(4,105),(72,495),(153,890),(199,1120)])
    save(front,"\(d)/front.png")
    copy("\(root)/v5/\(home)/inside.png","\(d)/inside.png")
    copy("\(root)/v5/\(home)/glass.png","\(d)/glass.png")
    copy("\(root)/v6_1/\(home)/guide.png","\(d)/guide.png")
    placeTable("\(root)/v6/tables/capsule_apartment_table_front_116.png","\(d)/table.png")
    finish(home,["\(d)/inside.png","\(d)/front.png","\(d)/glass.png","\(d)/table.png"])
}
