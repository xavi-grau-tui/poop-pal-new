// Technical separation of the approved ImageGen-painted v6.2 Capsule art.
// Keeps the central hatch pixel-identical, widens only the side bays, and
// moves existing window pixels into game layers without repainting the home.
import AppKit
import Foundation

typealias C = (UInt8,UInt8,UInt8,UInt8)
let base = "docs/mockups/hokora_homes"
let old = "\(base)/v6_2/capsule_apartment"
let dir = "\(base)/v6_4/capsule_apartment"
try! FileManager.default.createDirectory(atPath:dir,withIntermediateDirectories:true)
func load(_ p:String)->NSBitmapImageRep { NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))! }
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
 let o=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 memset(o.bitmapData!,0,o.bytesPerRow*h); return o
}
func get(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->C { let p=i.bitmapData!,j=y*i.bytesPerRow+x*4; return(p[j],p[j+1],p[j+2],p[j+3]) }
func put(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:C) { let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3 }
func save(_ i:NSBitmapImageRep,_ n:String) { try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(dir)/\(n).png")) }
func warp(_ src:NSBitmapImageRep)->NSBitmapImageRep {
 let o=blank(220,220)
 for y in 0..<220 {for x in 0..<220 {
  let sx:Int
  if x < 66 {sx=Int((8.0+Double(x-4)*58.0/62.0).rounded())}
  else if x <= 153 {sx=x}
  else {sx=Int((153.0+Double(x-153)*59.0/63.0).rounded())}
  if sx>=0 && sx<220 {put(o,x,y,get(src,sx,y))}
 }}
 return o
}
let original=load("\(old)/front.png")
let front=warp(original),back=blank(220,220),trays=blank(220,220),glass=warp(load("\(old)/glass.png"))
// Aperture follows the existing curved inner frame, leaving its light rim and
// dark border in front. The upper cut is narrower below the overhead shell.
func leftRange(_ y:Int)->ClosedRange<Int>? {
 switch y {
 case 67...72: return 42...56
 case 73...79: return 36...56
 case 80...85: return 33...56
 case 86...149: return 31...56
 case 150...156: return 34...56
 case 157...162: return 39...56
 default: return nil
 }
}
for y in 0..<220 {guard let span=leftRange(y) else {continue}
 for x in span {
  for xx in [x,219-x] {
   let c=get(front,xx,y)
   // Existing raised window floors are their own layer. The rest becomes the
   // little room behind the object. Fill old transparent slits with its dark wall.
   if y>=137 && y<=146 {if c.3>0 {put(trays,xx,y,c)}}
   else if c.3>0 {put(back,xx,y,c)}
   else if y>=77 && y<=151 {put(back,xx,y,(32,43,57,255))}
   put(front,xx,y,(0,0,0,0))
  }
 }
}
// Extend each tray's flat top to approximately thirty art pixels while
// preserving the accepted painted tray material and its end profile.
for y in 136...143 {
 for (from,to) in [(29,59),(160,190)] {
  for x in from...to where get(trays,x,y).3==0 {
   let sampleX=x<110 ? min(56,max(32,x)) : min(187,max(163,x))
   let c=get(trays,sampleX,y)
   if c.3>0 {put(trays,x,y,c);put(front,x,y,(0,0,0,0))}
  }
 }
}
// Keep a subtle see-through pane. The source already contains ImageGen-painted
// short highlight strokes; a pale tint makes objects visibly sit behind glass.
for y in 77...153 {guard let span=leftRange(y) else {continue}
 for x in span {for xx in [x,219-x] {
  let c=get(glass,xx,y)
  if c.3==0 {put(glass,xx,y,(175,225,235,55))}
  else {put(glass,xx,y,(c.0,c.1,c.2,min(c.3,125)))}
 }}
}
save(front,"front");save(back,"window_back");save(trays,"window_trays");save(glass,"glass")
// Existing centre room and solid table are retained for complete assembly.
for name in ["inside.png","table.png"] {
 let target="\(dir)/\(name)"
 try? FileManager.default.removeItem(atPath:target)
 try! FileManager.default.copyItem(atPath:"\(old)/\(name)",toPath:target)
}
let guide=warp(load("\(old)/guide.png"))
for (cx,cy) in [(44,136),(175,136)] {
 for d in -2...2 {put(guide,cx+d,cy,(52,225,105,255));put(guide,cx,cy+d,(52,225,105,255))}
}
save(guide,"guide")
func over(_ dst:NSBitmapImageRep,_ src:NSBitmapImageRep) {
 for y in 0..<220 {for x in 0..<220 {
  let s=get(src,x,y);if s.3==0 {continue};let d=get(dst,x,y),a=Double(s.3)/255
  let out:C=(UInt8((Double(s.0)*a+Double(d.0)*(1-a)).rounded()),UInt8((Double(s.1)*a+Double(d.1)*(1-a)).rounded()),UInt8((Double(s.2)*a+Double(d.2)*(1-a)).rounded()),UInt8(max(Int(s.3),Int(d.3))))
  put(dst,x,y,out)
 }}
}
let assembled=blank(220,220)
for layer in [load("\(dir)/inside.png"),back,trays,glass,front,load("\(dir)/table.png")] {over(assembled,layer)}
let preview=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(preview,x,y,get(assembled,x/8,y/8))}}
save(preview,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {put(icon,x,y,get(assembled,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))}}
save(icon,"icon")
precondition(get(front,44,110).3==0 && get(front,175,110).3==0,"side windows must be open in front")
precondition(get(back,44,110).3>0 && get(back,175,110).3>0,"rooms must back both windows")
precondition(get(trays,44,139).3>0 && get(trays,175,139).3>0,"both trays must support objects")
precondition(get(front,110,110).3==get(original,110,110).3,"central hatch must remain unchanged")
print("Capsule v6.4: 220x220 layers, preview 1760x1760, icon 96x96")
