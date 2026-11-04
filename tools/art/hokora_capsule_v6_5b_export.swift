// Precision export of the ImageGen-reviewed Capsule Pod v6.5b window fix.
// The approved v6.2 pixels are widened exactly as in v6.4, then only the
// two side-window apertures are cut. Everything outside them is byte-identical.
import AppKit
import Foundation

typealias C=(UInt8,UInt8,UInt8,UInt8)
let root="docs/mockups/hokora_homes"
let base="\(root)/v6_5/capsule_apartment"
let old="\(root)/v6_2/capsule_apartment"
let dir="\(root)/v6_5b/capsule_apartment"
try! FileManager.default.createDirectory(atPath:dir,withIntermediateDirectories:true)
func load(_ p:String)->NSBitmapImageRep { NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))! }
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
 let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 memset(i.bitmapData!,0,i.bytesPerRow*h);return i
}
func get(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->C {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;return(p[j],p[j+1],p[j+2],p[j+3])}
func put(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:C) {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3}
func save(_ i:NSBitmapImageRep,_ n:String) {try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(dir)/\(n).png"))}
func same(_ a:C,_ b:C)->Bool {a.0==b.0 && a.1==b.1 && a.2==b.2 && a.3==b.3}
func widened(_ src:NSBitmapImageRep)->NSBitmapImageRep {
 let o=blank(220,220)
 for y in 0..<220 {for x in 0..<220 {
  let sx:Int
  if x<66 {sx=Int((8.0+Double(x-4)*58.0/62.0).rounded())}
  else if x<=153 {sx=x}
  else {sx=Int((153.0+Double(x-153)*59.0/63.0).rounded())}
  if sx>=0 && sx<220 {put(o,x,y,get(src,sx,y))}
 }}
 return o
}
let original=load("\(old)/front.png")
let pristine=widened(original)
let front=blank(220,220)
for y in 0..<220 {for x in 0..<220 {put(front,x,y,get(pristine,x,y))}}
// The white arch approaches x=54 at its widest point. This curve is the
// window's inner boundary: every row stops before its dark outer outline.
func rightEnd(_ y:Int)->Int {
 switch y {
 case 78...81: return 55
 case 82...87: return 54
 case 88...95: return 52
 case 96...127: return 51
 case 128...134: return 52
 case 135...148: return 53
 case 149...152: return 54
 default: return 55
 }
}
func leftStart(_ y:Int)->Int {
 switch y {
 case 78: return 38
 case 79: return 36
 case 80: return 35
 case 81: return 34
 case 82...85: return 33
 case 86...149: return 31
 case 150...152: return 33
 case 153...154: return 35
 default: return 38
 }
}
func isWindow(_ x:Int,_ y:Int)->Bool {
 guard (78...156).contains(y) else {return false}
 let a=leftStart(y),b=rightEnd(y)
 return (a...b).contains(x) || ((219-b)...(219-a)).contains(x)
}
for y in 0..<220 {for x in 0..<220 where isWindow(x,y) {put(front,x,y,(0,0,0,0))}}
save(front,"front")
// Retain the accepted flat wall and shelf, covering the revised opening.
let oldTrays=load("\(base)/trays.png"),trays=blank(220,220)
for y in 0..<220 {for x in 0..<220 {
 let behindWindow=(68...156).contains(y) && ((30...59).contains(x) || (160...189).contains(x))
 if behindWindow || ((136...146).contains(y) && ((30...59).contains(x) || (160...189).contains(x))) {
  let c=get(oldTrays,x,y)
  if c.3==255 {put(trays,x,y,c)}
  else {put(trays,x,y,(58,69,84,255))}
 }
}}
save(trays,"trays")
let oldGlass=load("\(base)/glass.png"),glass=blank(220,220)
for y in 0..<220 {for x in 0..<220 where isWindow(x,y) {put(glass,x,y,get(oldGlass,x,y))}}
save(glass,"glass")
let guide=load("\(base)/guide.png");save(guide,"guide")
func over(_ dst:NSBitmapImageRep,_ src:NSBitmapImageRep) {
 for y in 0..<220 {for x in 0..<220 {
  let s=get(src,x,y);if s.3==0 {continue}
  let d=get(dst,x,y),a=Double(s.3)/255
  put(dst,x,y,(UInt8((Double(s.0)*a+Double(d.0)*(1-a)).rounded()),UInt8((Double(s.1)*a+Double(d.1)*(1-a)).rounded()),UInt8((Double(s.2)*a+Double(d.2)*(1-a)).rounded()),255))
 }}
}
let preview=blank(220,220),magenta=blank(220,220)
for y in 0..<220 {for x in 0..<220 {put(magenta,x,y,(255,0,255,255))}}
for layer in [load("\(root)/v6_4/capsule_apartment/inside.png"),trays,glass,front,load("\(root)/v6_4/capsule_apartment/table.png")] {
 over(preview,layer);over(magenta,layer)
}
let preview8=blank(1760,1760),magenta8=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {
 put(preview8,x,y,get(preview,x/8,y/8));put(magenta8,x,y,get(magenta,x/8,y/8))
}}
save(preview8,"preview_8x");save(magenta8,"qa_magenta_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {put(icon,x,y,get(preview,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))}}
save(icon,"icon")
var changedOutside=0,gaps=0,badAlpha=0
for y in 0..<220 {for x in 0..<220 {
 let f=get(front,x,y),p=get(pristine,x,y),t=get(trays,x,y),g=get(glass,x,y)
 if !isWindow(x,y) && !same(f,p) {changedOutside += 1}
 if isWindow(x,y) {
  if f.3 != 0 || t.3 != 255 {gaps += 1}
  if same(get(magenta,x,y),(255,0,255,255)) {gaps += 1}
 } else if g.3 != 0 {gaps += 1}
 if (68...156).contains(y) && ((30...59).contains(x) || (160...189).contains(x)) && same(get(magenta,x,y),(255,0,255,255)) {gaps += 1}
 if !(f.3==0 || f.3==255) || !(t.3==0 || t.3==255) {badAlpha += 1}
}}
precondition(changedOutside==0 && gaps==0 && badAlpha==0,"Capsule v6.5b validation failed")
print("Capsule v6.5b: 220x220; changed pixels outside windows 0; magenta window gaps 0; hard-alpha violations 0")
