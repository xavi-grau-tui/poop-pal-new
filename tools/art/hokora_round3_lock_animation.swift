// Locks every animation to frame 0. Only pixels in the named moving regions may change.
// The old alternate drawings provide the motion reference; no new whole-object art is made.
import AppKit
import Foundation

let root="docs/mockups/hokora_decor/round3"
let only=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : "all"
struct Box { let x0:Int,y0:Int,x1:Int,y1:Int
    func contains(_ x:Int,_ y:Int)->Bool {x>=x0 && x<x1 && y>=y0 && y<y1}
}
struct Spec {let folder:String,id:String,mode:String,boxes:[Box]}
func load(_ path:String)->NSBitmapImageRep {
    NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:path)))!
}
func save(_ im:NSBitmapImageRep,_ path:String) {
    try! im.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))
}
struct Pixel {let r:UInt8,g:UInt8,b:UInt8,a:UInt8}
func at(_ im:NSBitmapImageRep,_ x:Int,_ y:Int)->Pixel {
    let p=im.bitmapData!,i=y*im.bytesPerRow+x*4
    return Pixel(r:p[i],g:p[i+1],b:p[i+2],a:p[i+3])
}
func put(_ im:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:Pixel) {
    let p=im.bitmapData!,i=y*im.bytesPerRow+x*4
    p[i]=c.r;p[i+1]=c.g;p[i+2]=c.b;p[i+3]=c.a
}
func delta(_ a:Pixel,_ b:Pixel)->Int {
    abs(Int(a.r)-Int(b.r))+abs(Int(a.g)-Int(b.g))+abs(Int(a.b)-Int(b.b))+abs(Int(a.a)-Int(b.a))
}
func light(_ c:Pixel)->Double {Double(c.r)*0.299+Double(c.g)*0.587+Double(c.b)*0.114}
func warm(_ c:Pixel)->Bool {c.a>127 && Double(c.r)>140 && Double(c.r)>Double(c.b)*1.35 && Double(c.r)>=Double(c.g)*0.88}
func mirror(_ im:NSBitmapImageRep)->NSBitmapImageRep {
    let out=loadFromData(im.representation(using:.png,properties:[:])!)
    for y in 0..<im.pixelsHigh {for x in 0..<im.pixelsWide {
        put(out,x,y,at(im,im.pixelsWide-1-x,y))
    }}
    return out
}
func loadFromData(_ data:Data)->NSBitmapImageRep {NSBitmapImageRep(data:data)!}
func inside(_ x:Int,_ y:Int,_ boxes:[Box])->Bool {boxes.contains{$0.contains(x,y)}}
let lines=try! String(contentsOfFile:"\(root)/animation_regions.tsv",encoding:.utf8).split(separator:"\n").dropFirst()
let specs=lines.map { line -> Spec in
    let c=line.split(separator:"\t").map(String.init)
    let boxes=c[3].split(separator:";").map { s -> Box in
        let v=s.split(separator:",").map{Int($0)!}
        return Box(x0:v[0],y0:v[1],x1:v[2],y1:v[3])
    }
    return Spec(folder:c[0],id:c[1],mode:c[2],boxes:boxes)
}
for s in specs where only=="all" || only==s.folder {
    let dir="\(root)/\(s.folder)"
    let basePath="\(dir)/\(s.id)_0.png"
    if s.mode=="mirror_left" {
        for f in 0..<3 {
            let left=load("\(dir)/\(s.id)_left_\(f).png")
            save(mirror(left),"\(dir)/\(s.id)_\(f).png")
        }
        // The menu icon must show the new, cleaner base drawing as well.
        let icon=load("\(dir)/icons/\(s.id)_left.png")
        save(mirror(icon),"\(dir)/icons/\(s.id).png")
        print("\(s.folder)/\(s.id): clean mirror of left drawing")
        continue
    }
    let base=load(basePath)
    var count=0
    for f in 1..<4 {
        let path="\(dir)/\(s.id)_\(f).png"
        guard FileManager.default.fileExists(atPath:path) else {break}
        let old=load(path)
        let out=load(basePath)
        if s.mode=="head_tilt" {
            // A one-pixel head nod; the doll's torso and stand are copied unchanged.
            if f==1 {
                let box=s.boxes[0]
                let clear=Pixel(r:0,g:0,b:0,a:0)
                for y in box.y0..<box.y1 {for x in box.x0..<box.x1 {put(out,x,y,clear)}}
                for y in box.y0..<box.y1 {for x in box.x0..<box.x1 {
                    let c=at(base,x,y)
                    if c.a>127 && x>0 {put(out,x-1,y,c)}
                }}
            }
        } else if s.mode=="pulse" {
            var candidates=[(Double,Int,Int)]()
            for y in 0..<base.pixelsHigh {for x in 0..<base.pixelsWide where inside(x,y,s.boxes) {
                let a=at(base,x,y),b=at(old,x,y)
                if a.a>127 && b.a>127 && max(light(a),light(b))>117 {
                    let d=delta(a,b)
                    if d>23 {candidates.append((Double(d),x,y))}
                }
            }}
            candidates.sort{$0.0>$1.0}
            for (_,x,y) in candidates.prefix(18) {put(out,x,y,at(old,x,y))}
            if candidates.isEmpty {
                // A tiny, palette-constrained light pulse when the old frame has no usable core pixels.
                var bright=[(Double,Int,Int)]()
                for y in 0..<base.pixelsHigh {for x in 0..<base.pixelsWide where inside(x,y,s.boxes) {
                    let c=at(base,x,y)
                    if c.a>127 && light(c)>140 {bright.append((light(c),x,y))}
                }}
                bright.sort{$0.0>$1.0}
                if let highlight=bright.first {
                    let c=at(base,highlight.1,highlight.2)
                    for (_,x,y) in bright.dropFirst(2).prefix(5) {put(out,x,y,c)}
                }
            }
        } else {
            for y in 0..<base.pixelsHigh {for x in 0..<base.pixelsWide where inside(x,y,s.boxes) {
                let a=at(base,x,y),b=at(old,x,y)
                if s.mode=="warm_patch" && !(warm(a) || warm(b)) {continue}
                if delta(a,b)>0 {put(out,x,y,b)}
            }}
        }
        for y in 0..<base.pixelsHigh {for x in 0..<base.pixelsWide {
            if delta(at(base,x,y),at(out,x,y))>0 {count+=1}
        }}
        save(out,path)
    }
    print("\(s.folder)/\(s.id): \(count) moving pixels across alternate frames")
}
