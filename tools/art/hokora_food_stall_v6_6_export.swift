// Export the approved stall and wheels without repainting either. The new
// ImageGen mudguard face is placed twice, mirroring the right-hand piece.
import AppKit
import Foundation

typealias C=(UInt8,UInt8,UInt8,UInt8)
let base="docs/mockups/hokora_homes/v6_1/ramen_stall"
let out="docs/mockups/hokora_homes/v6_6/ramen_stall"
let source="docs/mockups/hokora_homes/v6_6/mudguard_imagegen_source.png"
try! FileManager.default.createDirectory(atPath:out,withIntermediateDirectories:true)
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
 let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 memset(i.bitmapData!,0,i.bytesPerRow*h);return i
}
func get(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->C {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;return(p[j],p[j+1],p[j+2],p[j+3])}
func put(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:C) {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3}
func save(_ i:NSBitmapImageRep,_ name:String) {try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(out)/\(name).png"))}
func copy(_ file:String) {let dst="\(out)/\(file)";try? FileManager.default.removeItem(atPath:dst);try! FileManager.default.copyItem(atPath:"\(base)/\(file)",toPath:dst)}
func over(_ dst:NSBitmapImageRep,_ src:NSBitmapImageRep) {
 for y in 0..<min(dst.pixelsHigh,src.pixelsHigh) {for x in 0..<min(dst.pixelsWide,src.pixelsWide) {
  let s=get(src,x,y);if s.3==0 {continue}
  let d=get(dst,x,y),a=Double(s.3)/255
  put(dst,x,y,(UInt8((Double(s.0)*a+Double(d.0)*(1-a)).rounded()),UInt8((Double(s.1)*a+Double(d.1)*(1-a)).rounded()),UInt8((Double(s.2)*a+Double(d.2)*(1-a)).rounded()),255))
 }}
}
let approved=load("\(base)/front.png"),front=blank(220,220),wheels=blank(220,220)
for y in 0..<220 {for x in 0..<220 {put(front,x,y,get(approved,x,y))}}
func wheelRegion(_ x:Int,_ y:Int)->Bool {
 if y<140 || y>199 {return false}
 return [36,184].contains {cx in
  let dx=Double(x-cx),dy=Double(y-169)
  return dx*dx+dy*dy <= 30.5*30.5
 }
}
for y in 0..<220 {for x in 0..<220 where wheelRegion(x,y) {
 let c=get(approved,x,y)
 if c.3>0 {put(wheels,x,y,c);put(front,x,y,(0,0,0,0))}
}}
// Continue the cart's lower wooden beam behind each removed wheel. It is
// hidden by the wheel rim, but makes the open spoke gaps read as a real cart.
for cx in [36,184] {for y in 141...156 {for x in (cx-30)...(cx+30) where x>=0 && x<220 {
 if get(front,x,y).3==0 && wheelRegion(x,y) {
  let c:C
  switch y {
  case 141: c=(32,0,16,255)
  case 142...144: c=(217,132,65,255)
  case 145...153: c=(150,76,39,255)
  case 154...155: c=(100,45,29,255)
  default: c=(32,0,16,255)
  }
  put(front,x,y,c)
 }
}}}
save(front,"front");save(wheels,"wheels")

// Technical nearest-neighbour export from the ImageGen mudguard painting.
let art=load(source)
var minX=art.pixelsWide,minY=art.pixelsHigh,maxX=0,maxY=0
for y in 0..<art.pixelsHigh {for x in 0..<art.pixelsWide where get(art,x,y).3>=128 {
 minX=min(minX,x);maxX=max(maxX,x);minY=min(minY,y);maxY=max(maxY,y)
}}
let left=blank(220,220),right=blank(220,220)
let leftX=19,topY=115,width=35,height=25
for yy in 0..<height {for xx in 0..<width {
 let sx=minX+Int((Double(xx)+0.5)*Double(maxX-minX+1)/Double(width))
 let sy=minY+Int((Double(yy)+0.5)*Double(maxY-minY+1)/Double(height))
 let c=get(art,min(maxX,sx),min(maxY,sy))
 if c.3>=128 {
  put(left,leftX+xx,topY+yy,(c.0,c.1,c.2,255))
  put(right,219-(leftX+xx),topY+yy,(c.0,c.1,c.2,255))
 }
}}
save(left,"mudguard_left");save(right,"mudguard_right")
copy("inside.png");copy("table.png")
let oldGuide=load("\(base)/guide.png"),guide=blank(220,220)
for y in 0..<220 {for x in 0..<220 {let c=get(oldGuide,x,y)
 // Keep the existing bell/lantern/beam guide, replacing old shelf lines.
 if c.3>0 && y<110 {put(guide,x,y,c)}
}}
for cx in [36,184] {for dy in -1...1 {for dx in -1...1 {put(guide,cx+dx,114+dy,(46,220,92,255))}}}
save(guide,"guide")
// Preview uses two previously approved small ornaments, only to demonstrate
// foot placement. They are not baked into the delivered game layers.
let preview=blank(220,220)
for layer in [load("\(out)/inside.png"),front,load("\(out)/table.png"),left,right] {over(preview,layer)}
for (file,cx) in [("docs/mockups/hokora_decor/round3/round1/shelf_koma_left.png",36),("docs/mockups/hokora_decor/round3/round1/shelf_origami_left.png",184)] {
 let ornament=load(file),small=blank(220,220),targetW=16,targetH=20
 for yy in 0..<targetH {for xx in 0..<targetW {
  let sx=min(ornament.pixelsWide-1,Int((Double(xx)+0.5)*Double(ornament.pixelsWide)/Double(targetW)))
  let sy=min(ornament.pixelsHigh-1,Int((Double(yy)+0.5)*Double(ornament.pixelsHigh)/Double(targetH)))
  let c=get(ornament,sx,sy)
  if c.3>=128 {put(small,cx-targetW/2+xx,115-targetH+yy,(c.0,c.1,c.2,255))}
 }}
 over(preview,small)
}
over(preview,wheels)
let p8=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(p8,x,y,get(preview,x/8,y/8))}}
save(p8,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {put(icon,x,y,get(preview,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))}}
save(icon,"icon")
var changedOutside=0,badAlpha=0
for y in 0..<220 {for x in 0..<220 {
 if !wheelRegion(x,y) {
  let a=get(front,x,y),b=get(approved,x,y)
  if a.0 != b.0 || a.1 != b.1 || a.2 != b.2 || a.3 != b.3 {changedOutside += 1}
 }
 for layer in [front,wheels,left,right] {let a=get(layer,x,y).3;if !(a==0 || a==255) {badAlpha += 1}}
}}
precondition(changedOutside==0 && badAlpha==0,"stall layer validation failed")
print("Food Stall v6.6: 220x220 layers; wheel separation and hard-alpha checks passed")
