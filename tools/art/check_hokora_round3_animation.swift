// Checks that all round-3 animation frames keep frame 0 unchanged outside their motion region.
import AppKit
import Foundation

let root="docs/mockups/hokora_decor/round3"
struct Box {let x0:Int,y0:Int,x1:Int,y1:Int
    func contains(_ x:Int,_ y:Int)->Bool {x>=x0 && x<x1 && y>=y0 && y<y1}
}
func load(_ path:String)->NSBitmapImageRep? {
    guard let data=try? Data(contentsOf:URL(fileURLWithPath:path)) else {return nil}
    return NSBitmapImageRep(data:data)
}
func pixel(_ im:NSBitmapImageRep,_ x:Int,_ y:Int)->(UInt8,UInt8,UInt8,UInt8) {
    let p=im.bitmapData!,i=y*im.bytesPerRow+x*4
    return (p[i],p[i+1],p[i+2],p[i+3])
}
let manifest=try! String(contentsOfFile:"\(root)/manifest.tsv",encoding:.utf8).split(separator:"\n").dropFirst()
var frameCounts=[String:Int]()
for row in manifest {let c=row.split(separator:"\t").map(String.init);frameCounts["\(c[0])/\(c[2])"]=Int(c[3])!}
let lines=try! String(contentsOfFile:"\(root)/animation_regions.tsv",encoding:.utf8).split(separator:"\n").dropFirst()
var problems=[String](),frames=0
for row in lines {
    let c=row.split(separator:"\t").map(String.init)
    let key="\(c[0])/\(c[1])",dir="\(root)/\(c[0])"
    guard let n=frameCounts[key],let base=load("\(dir)/\(c[1])_0.png") else {problems.append("missing base or manifest: \(key)");continue}
    let boxes=c[3].split(separator:";").map { s -> Box in
        let v=s.split(separator:",").map{Int($0)!}
        return Box(x0:v[0],y0:v[1],x1:v[2],y1:v[3])
    }
    for f in 1..<n {
        frames+=1
        guard let im=load("\(dir)/\(c[1])_\(f).png") else {problems.append("missing frame: \(key)_\(f)");continue}
        if im.pixelsWide != base.pixelsWide || im.pixelsHigh != base.pixelsHigh {problems.append("size: \(key)_\(f)");continue}
        var outside=0,partial=0,changed=0
        for y in 0..<im.pixelsHigh {for x in 0..<im.pixelsWide {
            let a=pixel(base,x,y),b=pixel(im,x,y)
            if b.3 != 0 && b.3 != 255 {partial+=1}
            if a != b {
                changed+=1
                if !boxes.contains(where:{$0.contains(x,y)}) {outside+=1}
            }
        }}
        if outside>0 && c[2] != "mirror_left" {problems.append("\(key)_\(f): \(outside) changed pixels outside motion region")}
        if partial>0 {problems.append("\(key)_\(f): \(partial) partial-alpha pixels")}
        if changed==0 && c[2] != "head_tilt" {problems.append("\(key)_\(f): no motion")}
        if c[2]=="mirror_left",let left=load("\(dir)/\(c[1])_left_\(f).png") {
            var nonmirror=0
            for y in 0..<im.pixelsHigh {for x in 0..<im.pixelsWide {
                if pixel(im,x,y) != pixel(left,im.pixelsWide-1-x,y) {nonmirror+=1}
            }}
            if nonmirror>0 {problems.append("\(key)_\(f): mirror mismatch")}
        }
    }
}
print("\(lines.count) animated pieces, \(frames) alternate frames, \(problems.count) problems")
for p in problems {print(p)}
if !problems.isEmpty {exit(1)}
