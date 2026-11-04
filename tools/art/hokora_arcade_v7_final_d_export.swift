// Registered export for arcade v7 final_d. ImageGen supplies the material
// finish; final_c_wide supplies the exact game geometry and inside mask.
import AppKit
import Foundation

typealias Pixel = (UInt8,UInt8,UInt8,UInt8)
let root = "docs/mockups/hokora_homes/v7/arcade_cabinet"
let source = "\(root)/final_c_wide"
let target = "\(root)/final_d"
try! FileManager.default.createDirectory(atPath: target, withIntermediateDirectories: true)
func load(_ path:String)->NSBitmapImageRep {
  NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:path)))!
}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
  let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,
    samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,
    bytesPerRow:0,bitsPerPixel:0)!
  memset(i.bitmapData!,0,i.bytesPerRow*h);return i
}
func get(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->Pixel {
  let p=i.bitmapData!,j=y*i.bytesPerRow+x*4
  return (p[j],p[j+1],p[j+2],p[j+3])
}
func put(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:Pixel) {
  let p=i.bitmapData!,j=y*i.bytesPerRow+x*4
  p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3
}
func save(_ i:NSBitmapImageRep,_ name:String) {
  try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(target)/\(name).png"))
}
let oldFront=load("\(source)/front.png")
let oldInside=load("\(source)/inside.png")
let oldGuide=load("\(source)/guide.png")
let art=load("\(target)/source_imagegen.png")
func family(_ c:Pixel)->Int {
  let r=Int(c.0),g=Int(c.1),b=Int(c.2)
  if max(r,g,b)<78 {return 0} // plum or outline
  if b>r*12/10 && b>g*11/10 {return 1} // blue
  if r>g*14/10 && r>b*12/10 {return 2} // red
  if r>145 && g>100 && b<g*9/10 {return 3} // gold
  if r>145 && g>120 && b>100 {return 4} // cream
  return 5
}
func generated(_ x:Int,_ y:Int)->Pixel {
  // Align ImageGen's transparent silhouette to the locked combined bounds.
  let sx=max(0,min(art.pixelsWide-1,21+(x-1)*1211/217))
  let sy=max(0,min(art.pixelsHigh-1,28+(y-1)*1183/216))
  return get(art,sx,sy)
}
let front=blank(220,220)
let inside=blank(220,220)
for y in 0..<220 {for x in 0..<220 {put(inside,x,y,get(oldInside,x,y))}}
for y in 0..<220 {for x in 0..<110 {
  let a=get(inside,x,y),b=get(inside,219-x,y)
  if a.3==255 && b.3==255 {put(inside,219-x,y,a)}
}}
for y in 0..<220 {for x in 0..<220 {
  let base=get(oldFront,x,y)
  if base.3==0 {continue}
  let paint=generated(x,y)
  let use=paint.3>=128 && family(base)==family(paint)
  put(front,x,y,use ? (paint.0,paint.1,paint.2,255) : base)
}}
// Outside pillars and arms are paired architectural parts. Keep their finish
// paired too; the left-only bell hook and the asymmetric controls are exempt.
for y in 0..<220 {for x in 0..<(y<145 ? 65 : 37) {
  if (15...36).contains(y) && (34...52).contains(x) {continue}
  let a=get(front,x,y),b=get(front,219-x,y)
  if a.3==255 && b.3==255 {put(front,219-x,y,a)}
}}
// The interior's exact c_wide alpha and six-pixel tilt allowance stay
// registered; only its material colour is paired across the centre.
save(front,"front")
save(inside,"inside")
save(oldGuide,"guide")
let trays=blank(220,220)
let plum:Pixel=(32,0,16,255)
let creamLight:Pixel=(255,248,225,255)
let creamMid:Pixel=(239,216,188,255)
let creamShade:Pixel=(196,155,137,255)
let redLight:Pixel=(255,73,68,255)
let redMid:Pixel=(237,45,54,255)
let redShade:Pixel=(169,23,39,255)
let gold:Pixel=(255,201,95,255)
for y in 158...171 {for u in 1...55 {
  // A straight-on face: cream edge, seam, red front and dark lower edge.
  // No slanted cream top or diagonal red side wall from c_wide survives.
  if y==158 && (u<4 || u>53) {continue}
  if y==170 && u<4 {continue}
  if y==171 && u<6 {continue}
  var c:Pixel=plum
  if y==159 {c=creamLight}
  if y==160 {c=creamMid}
  if y==161 {c=creamShade}
  if y==162 {c=plum}
  if y==163 || y==169 {c=redShade}
  if (164...168).contains(y) {c = y<=166 ? redLight : redMid}
  if (164...167).contains(y) && ((18...19).contains(u) || (37...38).contains(u)) {c=gold}
  if u==1 || u==55 || y==158 || y==171 {c=plum}
  put(trays,u,y,c);put(trays,219-u,y,c)
}}
save(trays,"trays")
let preview=blank(220,220)
func over(_ i:NSBitmapImageRep) {for y in 0..<220 {for x in 0..<220 {
  let c=get(i,x,y);if c.3>0 {put(preview,x,y,c)}
}}}
over(inside);over(front);over(trays)
let p8=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(p8,x,y,get(preview,x/8,y/8))}}
save(p8,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {
  put(icon,x,y,get(preview,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))
}}
save(icon,"icon")
var geometry=0,alpha=0,traySymmetry=0,oldTopPixels=0
for y in 0..<220 {for x in 0..<220 {
  if get(front,x,y).3 != get(oldFront,x,y).3 {geometry += 1}
  if get(inside,x,y).3 != get(oldInside,x,y).3 {geometry += 1}
  for layer in [front,trays,inside] {let a=get(layer,x,y).3;if a != 0 && a != 255 {alpha += 1}}
  if get(trays,x,y).3 != get(trays,219-x,y).3 {traySymmetry += 1}
  if y<158 && get(trays,x,y).3>0 {oldTopPixels += 1}
}}
precondition(geometry==0 && alpha==0 && traySymmetry==0 && oldTopPixels==0)
print("Arcade v7 final_d: c_wide front and inside alpha exact; flat symmetric tray faces; hard alpha; all checks passed")
