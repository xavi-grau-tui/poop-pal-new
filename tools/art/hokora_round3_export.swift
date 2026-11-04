// Technical placement/export of ImageGen ornament paintings. No ornament design is drawn here.
import AppKit
import Foundation

func load(_ path:String)->NSBitmapImageRep? {
    guard let d=try? Data(contentsOf:URL(fileURLWithPath:path)) else { return nil }
    return NSBitmapImageRep(data:d)
}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
    let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    if let data=rep.bitmapData { memset(data,0,rep.bytesPerRow*h) }
    return rep
}
func save(_ rep:NSBitmapImageRep,_ path:String) {
    try! rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))
}
func col(_ rep:NSBitmapImageRep,_ x:Int,_ y:Int)->NSColor { rep.colorAt(x:x,y:y)! }
func set(_ rep:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:NSColor) { rep.setColor(c,atX:x,y:y) }
func solid(_ c:NSColor)->Bool { c.alphaComponent >= 0.5 }
func clear(_ c:NSColor)->NSColor {
    NSColor(deviceRed:c.redComponent,green:c.greenComponent,blue:c.blueComponent,alpha:solid(c) ? 1 : 0)
}
func bounds(_ rep:NSBitmapImageRep,_ x0:Int,_ x1:Int,_ y0:Int,_ y1:Int)->(Int,Int,Int,Int)? {
    var l=rep.pixelsWide,t=rep.pixelsHigh,r=0,b=0
    for y in y0..<y1 { for x in x0..<x1 where solid(col(rep,x,y)) {
        l=min(l,x-x0);t=min(t,y-y0);r=max(r,x-x0);b=max(b,y-y0)
    }}
    return l<=r && t<=b ? (l,t,r,b) : nil
}
func enlarge(_ rep:NSBitmapImageRep,_ n:Int)->NSBitmapImageRep {
    let out=blank(rep.pixelsWide*n,rep.pixelsHigh*n)
    for y in 0..<out.pixelsHigh { for x in 0..<out.pixelsWide { set(out,x,y,col(rep,x/n,y/n)) } }
    return out
}
func overlay(_ dst:NSBitmapImageRep,_ src:NSBitmapImageRep,_ atX:Int,_ atY:Int,_ mirrored:Bool=false) {
    for y in 0..<src.pixelsHigh { for x in 0..<src.pixelsWide {
        let dx=atX+x,dy=atY+y
        if dx<0 || dy<0 || dx>=dst.pixelsWide || dy>=dst.pixelsHigh { continue }
        let c=col(src,mirrored ? src.pixelsWide-1-x : x,y)
        if solid(c) { set(dst,dx,dy,c) }
    }}
}

struct Entry { let home:String,kind:String,id:String,frames:Int,source:String,layout:String }
let root="docs/mockups/hokora_decor/round3"
let lines=try! String(contentsOfFile:"\(root)/manifest.tsv",encoding:.utf8).split(separator:"\n").dropFirst()
let entries=lines.compactMap { line -> Entry? in
    let v=line.split(separator:"\t").map(String.init)
    return v.count>=5 ? Entry(home:v[0],kind:v[1],id:v[2],frames:Int(v[3])!,source:v[4],layout:v.count>=6 ? v[5] : "h") : nil
}
let requested=CommandLine.arguments.dropFirst().first(where:{ !$0.hasPrefix("--") }) ?? "all"
let previewOnly=CommandLine.arguments.contains("--preview-only")
for e in entries where requested=="all" || requested==e.home {
    if previewOnly {continue}
    let dir="\(root)/\(e.home)"
    let src=load("\(dir)/\(e.source)")!
    let (w,h)=e.kind=="lantern" ? (26,42) : e.kind=="shelf" ? (30,36) : (90,37)
    let panelW=src.pixelsWide/(e.layout=="v" ? 1 : e.frames)
    let panelH=src.pixelsHigh/(e.layout=="v" ? e.frames : 1)
    let boxes=(0..<e.frames).map { f in bounds(src,e.layout=="v" ? 0 : f*panelW,e.layout=="v" ? panelW : (f+1)*panelW,e.layout=="v" ? f*panelH : 0,e.layout=="v" ? (f+1)*panelH : panelH)! }
    let l=boxes.map{$0.0}.min()!,t=boxes.map{$0.1}.min()!,r=boxes.map{$0.2}.max()!,b=boxes.map{$0.3}.max()!
    let bw=r-l+1,bh=b-t+1
    let scale=min(Double(w-2)/Double(bw),Double(h-1)/Double(bh))
    let dw=max(1,Int((Double(bw)*scale).rounded(.down))),dh=max(1,Int((Double(bh)*scale).rounded(.down)))
    let dx=(w-dw)/2,dy=e.kind=="shelf" ? h-dh : 0
    for f in 0..<e.frames {
        let out=blank(w,h)
        for yy in 0..<dh { for xx in 0..<dw {
            let sx=(e.layout=="v" ? 0 : f*panelW)+l+min(bw-1,Int(Double(xx)/scale))
            let sy=(e.layout=="v" ? f*panelH : 0)+t+min(bh-1,Int(Double(yy)/scale))
            let c=clear(col(src,sx,sy))
            if solid(c) { set(out,dx+xx,dy+yy,c) }
        }}
        save(out,"\(dir)/\(e.id)\(e.frames>1 ? "_\(f)" : "").png")
        if f==0 {
            let icon=blank(96,96)
            let factor=min(84.0/Double(w),84.0/Double(h))
            let iw=Int(Double(w)*factor),ih=Int(Double(h)*factor),ix=(96-iw)/2,iy=(96-ih)/2
            for y in 0..<ih { for x in 0..<iw {
                let sx=min(w-1,Int(Double(x)/factor)),sy=min(h-1,Int(Double(y)/factor))
                let c=col(out,sx,sy)
                if solid(c) { set(icon,ix+x,iy+y,c) }
            }}
            try! FileManager.default.createDirectory(atPath:"\(dir)/icons",withIntermediateDirectories:true)
            save(icon,"\(dir)/icons/\(e.id).png")
        }
    }
    print("\(e.home)/\(e.id): \(e.frames) frame(s), \(w)x\(h)")
}
for home in Set(entries.map{$0.home}) where requested=="all" || requested==home {
    let ee=entries.filter{$0.home==home && !$0.id.hasSuffix("_left")}
    guard ee.count==3, let inside=load("docs/mockups/hokora_homes/v5/\(home)/inside.png"),let front=load("docs/mockups/hokora_homes/v5/\(home)/front.png"),let table=load("docs/mockups/hokora_homes/v5/\(home)/table.png") else { continue }
    let canvas=blank(220,220)
    overlay(canvas,inside,0,0)
    overlay(canvas,front,0,0)
    overlay(canvas,table,0,0)
    let dir="\(root)/\(home)"
    if let hang=ee.first(where:{$0.kind=="hanging"}),let sprite=load("\(dir)/\(hang.id)\(hang.frames>1 ? "_0" : "").png") { overlay(canvas,sprite,65,72) }
    if let lantern=ee.first(where:{$0.kind=="lantern"}),let sprite=load("\(dir)/\(lantern.id)\(lantern.frames>1 ? "_0" : "").png") {
        overlay(canvas,sprite,50-13,60);overlay(canvas,sprite,170-13,60)
    }
    if let shelf=ee.first(where:{$0.kind=="shelf"}),let sprite=load("\(dir)/\(shelf.id)\(shelf.frames>1 ? "_0" : "").png") {
        overlay(canvas,sprite,38,162-sprite.pixelsHigh, true);overlay(canvas,sprite,152,162-sprite.pixelsHigh)
    }
    save(enlarge(canvas,8),"\(dir)/set_preview_8x.png")
}
// The approved round-1 shelf pair paintings are two separate objects on one source canvas.
// Crop them into individual game slots; no new ornament drawing occurs here.
if !previewOnly && (requested=="all" || requested=="round1") {
    let names=["bonsai","ema","kappa","kitsune","koma","komainu","origami","puzzle","sakaki","tsukimi"]
    let dir="\(root)/round1"
    for name in names {
        let src=load("docs/mockups/hokora_decor/imagegen_sources/shelf/shelf_\(name).png")!
        let half=src.pixelsWide/2
        for side in 0..<2 {
            guard let (l,t,r,b)=bounds(src,side*half,(side+1)*half,0,src.pixelsHigh) else { continue }
            let bw=r-l+1,bh=b-t+1
            let scale=min(28.0/Double(bw),35.0/Double(bh))
            let dw=max(1,Int(Double(bw)*scale)),dh=max(1,Int(Double(bh)*scale))
            let out=blank(30,36),dx=(30-dw)/2,dy=36-dh
            for y in 0..<dh { for x in 0..<dw {
                let sx=side*half+l+min(bw-1,Int(Double(x)/scale))
                let sy=t+min(bh-1,Int(Double(y)/scale))
                let c=clear(col(src,sx,sy))
                if solid(c) { set(out,dx+x,dy+y,c) }
            }}
            let suffix=side==0 ? "_left" : ""
            save(out,"\(dir)/shelf_\(name)\(suffix).png")
            if side==1 {
                let icon=blank(96,96)
                for y in 0..<84 { for x in 0..<70 {
                    let c=col(out,min(29,x*30/70),min(35,y*36/84))
                    if solid(c) { set(icon,13+x,6+y,c) }
                }}
                save(icon,"\(dir)/icons/shelf_\(name).png")
            }
        }
        print("round1/shelf_\(name): split pair to 30x36 singles")
    }
}
