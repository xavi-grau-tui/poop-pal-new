// Technical grid export and layer assembly of the v6.1 ImageGen front paintings.
// The accepted v5 opening/room/glass pixels anchor the geometry and are not redrawn.
import AppKit
import Foundation

struct Spec {let name:String,left:Int,right:Int,top:Double,opening:Double,floor:Double,bottom:Double}
let specs:[Spec]=[
    .init(name:"golden",left:8,right:212,top:0,opening:650,floor:1050,bottom:1180),
    .init(name:"capsule_apartment",left:8,right:212,top:140,opening:270,floor:760,bottom:900),
    .init(name:"arcade_cabinet",left:18,right:202,top:20,opening:280,floor:1000,bottom:1220),
    .init(name:"ramen_stall",left:8,right:212,top:95,opening:420,floor:805,bottom:1195)
]
let only=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : "all"
let root="docs/mockups/hokora_homes"
func load(_ path:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:path)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
    let im=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    memset(im.bitmapData!,0,im.bytesPerRow*h);return im
}
typealias P=(UInt8,UInt8,UInt8,UInt8)
func px(_ im:NSBitmapImageRep,_ x:Int,_ y:Int)->P {let d=im.bitmapData!,i=y*im.bytesPerRow+x*4;return (d[i],d[i+1],d[i+2],d[i+3])}
func put(_ im:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:P) {let d=im.bitmapData!,i=y*im.bytesPerRow+x*4;d[i]=c.0;d[i+1]=c.1;d[i+2]=c.2;d[i+3]=c.3}
func save(_ im:NSBitmapImageRep,_ path:String) {try! im.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))}
func bounds(_ im:NSBitmapImageRep)->(Int,Int,Int,Int) {
    var l=im.pixelsWide,t=im.pixelsHigh,r=0,b=0
    for y in 0..<im.pixelsHigh {for x in 0..<im.pixelsWide where px(im,x,y).3>=128 {l=min(l,x);r=max(r,x);t=min(t,y);b=max(b,y)}}
    return (l,t,r,b)
}
func normalized(_ src:NSBitmapImageRep,_ s:Spec)->NSBitmapImageRep {
    let out=blank(220,220),b=bounds(src)
    let top=max(Double(b.1),s.top),bottom=min(Double(b.3),s.bottom)
    for y in 4...199 {for x in s.left...s.right {
        let sx=Double(b.0)+Double(x-s.left)/Double(s.right-s.left)*Double(b.2-b.0)
        let sy:Double
        if y<=72 {sy=top+Double(y-4)/68*(s.opening-top)}
        else if y<=162 {sy=s.opening+Double(y-72)/90*(s.floor-s.opening)}
        else {sy=s.floor+Double(y-162)/37*(bottom-s.floor)}
        let ix=max(0,min(src.pixelsWide-1,Int(sx.rounded()))),iy=max(0,min(src.pixelsHigh-1,Int(sy.rounded())))
        let c=px(src,ix,iy)
        if c.3>=128 {put(out,x,y,(c.0,c.1,c.2,255))}
    }}
    return out
}
func enlarge(_ im:NSBitmapImageRep,_ n:Int)->NSBitmapImageRep {
    let out=blank(im.pixelsWide*n,im.pixelsHigh*n)
    for y in 0..<out.pixelsHigh {for x in 0..<out.pixelsWide {put(out,x,y,px(im,x/n,y/n))}}
    return out
}
func compose(_ layers:[NSBitmapImageRep])->NSBitmapImageRep {
    let out=blank(220,220)
    for layer in layers {for y in 0..<220 {for x in 0..<220 {
        let c=px(layer,x,y);if c.3==0 {continue}
        if c.3==255 {put(out,x,y,c);continue}
        let d=px(out,x,y),a=Double(c.3)/255,inv=1-a
        put(out,x,y,(UInt8((Double(c.0)*a+Double(d.0)*inv).rounded()),UInt8((Double(c.1)*a+Double(d.1)*inv).rounded()),UInt8((Double(c.2)*a+Double(d.2)*inv).rounded()),255))
    }}}
    return out
}
let standards=["neon_cyber","fire","bathhouse"].map{load("\(root)/v5/\($0)/preview_8x.png")}
for s in specs where only=="all" || only==s.name {
    let old="\(root)/v5/\(s.name)",dir="\(root)/v6_1/\(s.name)"
    let newSource=load("\(dir)/front_source_imagegen.png"),oldFront=load("\(old)/front.png")
    let front=normalized(newSource,s)
    let rawControls=s.name=="arcade_cabinet" ? normalized(newSource,s) : nil
    // Keep the v5 natural aperture and side holes clear, plus the full tall-spirit safety box.
    for y in 0..<220 {for x in 0..<220 {
        let central=x>=42 && x<=178 && y>=62 && y<=170
        let side=s.name=="capsule_apartment" && y>=75 && y<=165 && ((x>=18 && x<=68)||(x>=152 && x<=202))
        let clearTall=x>=66 && x<=157 && y>=72 && y<162
        if clearTall || ((central || side) && px(oldFront,x,y).3==0) {put(front,x,y,(0,0,0,0))}
    }}
    // Shift the two painted control wings outward, leaving the approved central
    // table recess and tall-spirit area open. No new artwork is drawn here.
    if let raw=rawControls {
        for y in 143...161 {for x in 24...196 {put(front,x,y,(0,0,0,0))}}
        for y in 143...161 {
            for x in 29...80 {let dx=x-15,c=px(raw,x,y);if dx<66 && c.3==255 {put(front,dx,y,c)}}
            for x in 140...191 {let dx=x+15,c=px(raw,x,y);if dx>157 && c.3==255 {put(front,dx,y,c)}}
        }
    }
    if s.name=="ramen_stall" {
        // The ImageGen source wheels are round; export them isotropically rather
        // than squeezing the cart's lower source band into 37 game pixels.
        for y in 169...199 {for x in 14...82 {put(front,x,y,(0,0,0,0));put(front,x+124,y,(0,0,0,0))}}
        for y in 181...199 {for x in 80...140 {put(front,x,y,(0,0,0,0))}}
        let wheels=[(90,855,450,1215,8),(800,855,1160,1215,158)]
        for (sx0,sy0,sx1,sy1,dx0) in wheels {
            for dy in 0..<56 {for dx in 0..<56 {
                let sx=sx0+Int(Double(dx)/55*Double(sx1-sx0)),sy=sy0+Int(Double(dy)/55*Double(sy1-sy0))
                let c=px(newSource,sx,sy)
                if c.3>=128 {put(front,dx0+dx,143+dy,(c.0,c.1,c.2,255))}
            }}
        }
    }
    save(front,"\(dir)/front.png")
    let inside=load("\(old)/inside.png")
    try? FileManager.default.removeItem(atPath:"\(dir)/inside.png")
    try! FileManager.default.copyItem(atPath:"\(old)/inside.png",toPath:"\(dir)/inside.png")
    let glassPath="\(old)/glass.png"
    var layers=[inside,front]
    if FileManager.default.fileExists(atPath:glassPath) {
        try? FileManager.default.removeItem(atPath:"\(dir)/glass.png")
        try! FileManager.default.copyItem(atPath:glassPath,toPath:"\(dir)/glass.png")
        layers.append(load(glassPath))
    }
    try? FileManager.default.removeItem(atPath:"\(dir)/guide.png")
    try! FileManager.default.copyItem(atPath:"\(old)/guide.png",toPath:"\(dir)/guide.png")
    let tablePath="\(dir)/table.png"
    let table=load(FileManager.default.fileExists(atPath:tablePath) ? tablePath : "\(old)/table.png")
    layers.append(table)
    let combined=compose(layers),preview=enlarge(combined,8)
    save(preview,"\(dir)/preview_8x.png")
    let icon=blank(96,96)
    for y in 0..<96 {for x in 0..<96 {put(icon,x,y,px(combined,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))}}
    save(icon,"\(dir)/icon.png")
    let compare=blank(1760*4,1760)
    for (i,panel) in (standards+[preview]).enumerated() {for y in 0..<1760 {for x in 0..<1760 {put(compare,i*1760+x,y,px(panel,x,y))}}}
    save(compare,"\(dir)/compare_8x.png")
    let check=blank(220,220)
    for y in 0..<220 {for x in 0..<220 {
        let c=px(front,x,y)
        put(check,x,y,c.3>0 ? c : (255,86,186,255))
    }}
    save(enlarge(check,8),"\(dir)/front_check_8x.png")
    let opening=(72..<162).flatMap{y in (66...157).map{x in px(front,x,y).3==0}}.filter{$0}.count
    print("\(s.name): front \(bounds(front)), tall opening clear \(opening)/8280")
}
if only=="all" || only=="moon" {
    let old="\(root)/v5/moon",dir="\(root)/v6_1/moon"
    let oldFront=load("\(old)/front.png"),oldInside=load("\(old)/inside.png")
    let b=bounds(oldFront),factor=204.0/Double(b.2-b.0)
    func widen(_ src:NSBitmapImageRep)->NSBitmapImageRep {
        let out=blank(220,220)
        for y in 0..<220 {for x in 0..<220 {
            let sx=Int((110.0+(Double(x)-110.0)/factor).rounded())
            if sx>=0 && sx<220 {put(out,x,y,px(src,sx,y))}
        }}
        return out
    }
    let front=widen(oldFront),inside=widen(oldInside)
    save(front,"\(dir)/front.png");save(inside,"\(dir)/inside.png")
    try? FileManager.default.removeItem(atPath:"\(dir)/guide.png")
    try! FileManager.default.copyItem(atPath:"\(old)/guide.png",toPath:"\(dir)/guide.png")
    let tablePath="\(dir)/table.png"
    let combined=compose([inside,front,load(FileManager.default.fileExists(atPath:tablePath) ? tablePath : "\(old)/table.png")]),preview=enlarge(combined,8)
    save(preview,"\(dir)/preview_8x.png")
    let icon=blank(96,96)
    for y in 0..<96 {for x in 0..<96 {put(icon,x,y,px(combined,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))}}
    save(icon,"\(dir)/icon.png")
    let compare=blank(1760*4,1760)
    for (i,panel) in (standards+[preview]).enumerated() {for y in 0..<1760 {for x in 0..<1760 {put(compare,i*1760+x,y,px(panel,x,y))}}}
    save(compare,"\(dir)/compare_8x.png")
    print("moon: v5 pixels widened by \(String(format:"%.3f",factor)) around center; opening \(bounds(front))")
}
