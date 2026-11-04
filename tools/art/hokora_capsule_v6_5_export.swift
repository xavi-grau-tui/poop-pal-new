// Game-grid export of the ImageGen-cleaned Capsule Pod and its simple windows.
// Four visual layers: trays, player ornament, glass, front.
import AppKit
import Foundation

typealias C=(UInt8,UInt8,UInt8,UInt8)
let root="docs/mockups/hokora_homes"
let old="\(root)/v6_4/capsule_apartment"
let dir="\(root)/v6_5/capsule_apartment"
let source="\(root)/v6_5/source_imagegen.png"
try! FileManager.default.createDirectory(atPath:dir,withIntermediateDirectories:true)
func load(_ p:String)->NSBitmapImageRep { NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))! }
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
 let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 memset(i.bitmapData!,0,i.bytesPerRow*h);return i
}
func get(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->C { let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;return(p[j],p[j+1],p[j+2],p[j+3]) }
func put(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:C) { let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3 }
func save(_ i:NSBitmapImageRep,_ n:String) { try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(dir)/\(n).png")) }
// One clean rounded rectangle, 30 columns wide. Its flat lower portion leaves
// enough space for a 30-column tray; both holes use the same exact shape.
func leftSpan(_ y:Int)->ClosedRange<Int>? {
 switch y {
 case 66: return 39...50
 case 67: return 36...54
 case 68: return 34...56
 case 69: return 33...57
 case 70: return 32...58
 case 71...155: return 30...59
 case 156: return 31...58
 case 157: return 32...57
 case 158: return 34...55
 case 159: return 37...52
 default: return nil
 }
}
func inWindow(_ x:Int,_ y:Int)->Bool {
 guard let s=leftSpan(y) else {return false}
 return s.contains(x) || s.contains(219-x)
}
let src=load(source)
let front=blank(220,220),trays=blank(220,220),glass=blank(220,220)
// Nearest-neighbour export from the ImageGen edit; hard alpha on the grid.
for y in 0..<220 {for x in 0..<220 {
 let sx=min(src.pixelsWide-1,Int((Double(x)+0.5)*Double(src.pixelsWide)/220))
 let sy=min(src.pixelsHigh-1,Int((Double(y)+0.5)*Double(src.pixelsHigh)/220))
 let c=get(src,sx,sy)
 if c.3>=128 {put(front,x,y,(c.0,c.1,c.2,255))}
}}
// Preserve the accepted v6.4 pod outside the two window bays: ImageGen is a
// guide for the cleaned cut, while those untouched pixels remain exact.
let accepted=load("\(old)/front.png")
for y in 0..<220 {for x in 0..<220 {
 if !(23...64).contains(x) && !(155...196).contains(x) || y<66 || y>159 {
  put(front,x,y,get(accepted,x,y))
 }
}}
// Remove any old ragged cut by filling only the narrow frame zone with its
// existing dark inner-rim tone. The clean rounded mask is carved afterwards.
for y in 66...159 {for x in 23...64 {
 for xx in [x,219-x] where !inWindow(xx,y) {
  if get(front,xx,y).3==0 && (27...61).contains(x) {
   // Preserve the black gap directly outside the pod; repair only pixels
   // between the inner side-wall and the opening.
   let nearLeft=(30...43).contains(x),nearRight=(53...61).contains(x)
   if nearLeft || nearRight {put(front,xx,y,(48,55,69,255))}
  }
 }
}}
for y in 0..<220 {for x in 0..<220 where inWindow(x,y) {
 put(front,x,y,(0,0,0,0))
 let edgeLeft=x<110 ? 30 : 160
 let local=x-edgeLeft
 var wall:C=(58,69,84,255)
 if local<4 {wall=(91,110,124,255)}
 if local>=26 {wall=(40,48,64,255)}
 if y<=70 {wall=(37,43,58,255)}
 if y>=151 {wall=(42,50,64,255)}
 put(trays,x,y,wall)
 put(glass,x,y,(176,220,231,72))
}}
// One simple shelf per window, with a level 30-column top.
for left in [30,160] {for y in 136...146 {for x in left..<(left+30) {
 let c:C
 switch y {
 case 136: c=(32,0,16,255)
 case 137...138: c=(246,244,232,255)
 case 139: c=(207,225,222,255)
 case 140: c=(40,143,145,255)
 case 141...144: c=(124,143,152,255)
 case 145: c=(78,91,104,255)
 default: c=(32,0,16,255)
 }
 put(trays,x,y,c)
}}}
// Glass has no extraneous highlights: two sparse, stepped diagonal marks.
for left in [30,160] {
 for j in 0...15 {
  let x=left+5+j/3,y=79+j
  if inWindow(x,y) {put(glass,x,y,(241,250,251,106))}
 }
 for j in 0...8 {
  let x=left+20+j/4,y=91+j
  if inWindow(x,y) {put(glass,x,y,(226,244,247,96))}
 }
}
save(front,"front");save(trays,"trays");save(glass,"glass")
let guide=load("\(old)/guide.png")
// Keep the existing hook marks. Replace the old shelf marks with two dots.
let cleanGuide=blank(220,220)
for y in 0..<220 {for x in 0..<220 {
 let c=get(guide,x,y)
 if c.3>0 && !(95...175).contains(y) {put(cleanGuide,x,y,c)}
}}
for cx in [45,175] {for dy in -1...1 {for dx in -1...1 {
 put(cleanGuide,cx+dx,135+dy,(48,223,101,255))
}}}
save(cleanGuide,"guide")
func over(_ dst:NSBitmapImageRep,_ src:NSBitmapImageRep) {
 for y in 0..<220 {for x in 0..<220 {
  let s=get(src,x,y);if s.3==0 {continue}
  let d=get(dst,x,y),a=Double(s.3)/255
  put(dst,x,y,(UInt8((Double(s.0)*a+Double(d.0)*(1-a)).rounded()),UInt8((Double(s.1)*a+Double(d.1)*(1-a)).rounded()),UInt8((Double(s.2)*a+Double(d.2)*(1-a)).rounded()),255))
 }}
}
let preview=blank(220,220),magenta=blank(220,220)
for y in 0..<220 {for x in 0..<220 {put(magenta,x,y,(255,0,255,255))}}
for layer in [load("\(old)/inside.png"),trays,glass,front,load("\(old)/table.png")] {over(preview,layer);over(magenta,layer)}
let p8=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(p8,x,y,get(preview,x/8,y/8))}}
save(p8,"preview_8x")
let magenta8=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(magenta8,x,y,get(magenta,x/8,y/8))}}
save(magenta8,"qa_magenta_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {put(icon,x,y,get(preview,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))}}
save(icon,"icon")
var holes=0,partial=0,frontInside=0,glassOutside=0
for y in 0..<220 {for x in 0..<220 {
 let f=get(front,x,y),t=get(trays,x,y),g=get(glass,x,y)
 if inWindow(x,y) {
  if f.3 != 0 {frontInside += 1}
  if t.3 != 255 {holes += 1}
  if get(magenta,x,y).0==255 && get(magenta,x,y).1==0 && get(magenta,x,y).2==255 {holes += 1}
 } else if g.3 != 0 {glassOutside += 1}
 if f.3 != 0 && f.3 != 255 {partial += 1}
 if t.3 != 0 && t.3 != 255 {partial += 1}
}}
precondition(holes==0 && partial==0 && frontInside==0 && glassOutside==0,"window-layer validation failed")
print("Capsule v6.5: 220x220 layers; magenta gaps 0; front/tray partial-alpha pixels 0; glass outside openings 0")
