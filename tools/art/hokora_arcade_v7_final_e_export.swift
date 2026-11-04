// Surgical pixel edits on the approved final_c_wide layers. This script never
// changes a layer's alpha mask or moves an existing colour region.
import AppKit
import Foundation

typealias Pixel = (UInt8,UInt8,UInt8,UInt8)
let base = "docs/mockups/hokora_homes/v7/arcade_cabinet/final_c_wide"
let out = "docs/mockups/hokora_homes/v7/arcade_cabinet/final_e"
try! FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
 let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,
  samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,
  bytesPerRow:0,bitsPerPixel:0)!
 memset(i.bitmapData!,0,i.bytesPerRow*h);return i
}
func pixel(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->Pixel {
 let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;return (p[j],p[j+1],p[j+2],p[j+3])
}
func set(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:Pixel) {
 let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3
}
func save(_ i:NSBitmapImageRep,_ name:String) {
 try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(out)/\(name).png"))
}
func copy(_ i:NSBitmapImageRep)->NSBitmapImageRep {
 let o=blank(i.pixelsWide,i.pixelsHigh)
 for y in 0..<i.pixelsHigh {for x in 0..<i.pixelsWide {set(o,x,y,pixel(i,x,y))}}
 return o
}
let names=["front","trays","inside"]
let originals=names.map{load("\(base)/\($0).png")}
let edited=originals.map{copy($0)}
func kind(_ p:Pixel)->String {
 let r=Int(p.0),g=Int(p.1),b=Int(p.2)
 if p.3==0 {return "clear"}
 if max(r,g,b)<65 {return "outline"}
 if b>r*12/10 && b>g*11/10 {return "blue"}
 if r>g*15/10 && r>b*12/10 {return "red"}
 if r>135 && g>88 && b<g*8/10 {return "gold"}
 if r>155 && g>130 && b>105 {return "cream"}
 return "other"
}
func clamp(_ n:Int)->UInt8 {UInt8(max(0,min(255,n)))}
// Explicit little brush marks. Each is accepted only within a solid interior
// of its stated material; dark outlines, transparent pixels and other colour
// regions are never painted.
func stroke(_ layer:Int,_ xs:ClosedRange<Int>,_ ys:ClosedRange<Int>,_ material:String,
            _ dr:Int,_ dg:Int,_ db:Int) {
 let src=originals[layer],dst=edited[layer]
 for y in ys {for x in xs {
  if x<1 || x>218 || y<1 || y>218 {continue}
  let c=pixel(src,x,y)
  if kind(c) != material {continue}
  if kind(pixel(src,x-1,y)) != material || kind(pixel(src,x+1,y)) != material {continue}
  let next:Pixel=(clamp(Int(c.0)+dr),clamp(Int(c.1)+dg),clamp(Int(c.2)+db),c.3)
  if kind(next)==material {set(dst,x,y,next)}
 }}
}
// Sign: short top-left glints and a lower cream tone step.
stroke(0,61...66,23...23,"cream",8,8,6)
stroke(0,153...158,42...42,"cream",-8,-8,-7)
stroke(0,56...58,23...24,"gold",4,8,2)
// Paired pillar highlights, restrained to the red paint.
stroke(0,43...44,111...114,"red",7,3,2)
stroke(0,175...176,111...114,"red",7,3,2)
// Joystick and buttons get crisp, two-pixel light catches.
stroke(0,70...72,155...156,"red",9,4,3)
stroke(0,139...140,157...157,"red",9,4,3)
stroke(0,151...152,157...157,"blue",5,7,11)
stroke(0,164...165,157...157,"gold",3,8,4)
// Small lacquering and grille catches on the lower cabinet.
stroke(0,56...59,181...182,"red",7,3,2)
stroke(0,160...163,181...182,"red",7,3,2)
stroke(0,89...94,188...188,"blue",4,7,12)
stroke(0,124...129,198...198,"blue",-3,-5,-8)
// The approved tray shape, including its cream top, is untouched. Only a
// quiet top-left sheen and a lower red tone step are painted within it.
stroke(1,12...18,151...151,"cream",8,7,5)
stroke(1,201...207,151...151,"cream",8,7,5)
stroke(1,14...20,165...165,"red",-7,-3,-3)
stroke(1,199...205,165...165,"red",-7,-3,-3)
// The approved inside already has the needed depth; leave its paint intact.

// Exact alpha-mask and material-region audit, plus per-layer RGB diffs.
var counts=[Int](repeating:0,count:3)
let diff=blank(220*3,220)
for l in 0..<3 {for y in 0..<220 {for x in 0..<220 {
 let a=pixel(originals[l],x,y),b=pixel(edited[l],x,y)
 precondition(a.3==b.3,"alpha changed in \(names[l]) at \(x),\(y)")
 let changed=a.0 != b.0 || a.1 != b.1 || a.2 != b.2
 if changed {
  precondition(a.3>0 && kind(a)==kind(b),"colour region changed")
  counts[l] += 1
  set(diff,l*220+x,y,(255,52,220,255))
 } else if a.3>0 {
  set(diff,l*220+x,y,(UInt8(Int(a.0)/3),UInt8(Int(a.1)/3),UInt8(Int(a.2)/3),255))
 }
}}}
precondition(counts[0]>0 && counts[1]>0 && counts[2]==0)
for l in 0..<3 {save(edited[l],names[l])}
save(load("\(base)/guide.png"),"guide")
let diff4=blank(2640,880)
for y in 0..<880 {for x in 0..<2640 {set(diff4,x,y,pixel(diff,x/4,y/4))}}
save(diff4,"diff_all_layers_4x")
func over(_ dst:NSBitmapImageRep,_ src:NSBitmapImageRep) {
 for y in 0..<220 {for x in 0..<220 {let p=pixel(src,x,y);if p.3>0 {set(dst,x,y,p)}}}
}
let combined=blank(220,220)
over(combined,edited[2]);over(combined,edited[0]);over(combined,edited[1])
let preview=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {set(preview,x,y,pixel(combined,x/8,y/8))}}
save(preview,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {
 set(icon,x,y,pixel(combined,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))
}}
save(icon,"icon")
print("final_e: exact alpha masks; same material regions; changed pixels front=\(counts[0]), trays=\(counts[1]), inside=\(counts[2])")
