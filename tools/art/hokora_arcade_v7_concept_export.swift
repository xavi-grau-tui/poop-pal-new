// Technical nearest-neighbour export of three ImageGen arcade layout concepts.
// No geometry is redrawn here; selected concept needs its own final grid pass.
import AppKit
import Foundation

typealias C=(UInt8,UInt8,UInt8,UInt8)
let root="docs/mockups/hokora_homes/v7/arcade_cabinet"
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
 let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 memset(i.bitmapData!,0,i.bytesPerRow*h);return i
}
func get(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->C {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;return(p[j],p[j+1],p[j+2],p[j+3])}
func put(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:C) {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3}
func save(_ i:NSBitmapImageRep,_ p:String) {try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:p))}
for option in ["option_a","option_b","option_c"] {
 let path="\(root)/\(option)",src=load("\(path)/source_imagegen.png"),grid=blank(220,220)
 for y in 0..<220 {for x in 0..<220 {
  let sx=min(src.pixelsWide-1,Int((Double(x)+0.5)*Double(src.pixelsWide)/220))
  let sy=min(src.pixelsHigh-1,Int((Double(y)+0.5)*Double(src.pixelsHigh)/220))
  let c=get(src,sx,sy)
  if c.3>=128 {put(grid,x,y,(c.0,c.1,c.2,255))}
 }}
 save(grid,"\(path)/concept_220.png")
 let preview=blank(1760,1760)
 for y in 0..<1760 {for x in 0..<1760 {put(preview,x,y,get(grid,x/8,y/8))}}
 save(preview,"\(path)/preview_8x.png")
 print("\(option): concept 220x220, preview 1760x1760")
}
let sheet=blank(660,220)
for (index,option) in ["option_a","option_b","option_c"].enumerated() {
 let src=load("\(root)/\(option)/concept_220.png")
 for y in 0..<220 {for x in 0..<220 {put(sheet,index*220+x,y,get(src,x,y))}}
}
let sheet4=blank(2640,880)
for y in 0..<880 {for x in 0..<2640 {put(sheet4,x,y,get(sheet,x/4,y/4))}}
save(sheet4,"\(root)/options_contact_4x.png")
