// Two localized pixel fixes on the approved final_e arcade cabinet.
// The audit below rejects any changed pixel outside the marked boxes.
import AppKit
import Foundation

typealias Pixel=(UInt8,UInt8,UInt8,UInt8)
let src="docs/mockups/hokora_homes/v7/arcade_cabinet/final_e"
let dst="docs/mockups/hokora_homes/v7/arcade_cabinet/final_f"
try! FileManager.default.createDirectory(atPath:dst,withIntermediateDirectories:true)
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
 let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,
 samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,
 bytesPerRow:0,bitsPerPixel:0)!
 memset(i.bitmapData!,0,i.bytesPerRow*h);return i
}
func get(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->Pixel {
 let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;return(p[j],p[j+1],p[j+2],p[j+3])
}
func put(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:Pixel) {
 let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3
}
func copy(_ i:NSBitmapImageRep)->NSBitmapImageRep {
 let o=blank(i.pixelsWide,i.pixelsHigh)
 for y in 0..<i.pixelsHigh {for x in 0..<i.pixelsWide {put(o,x,y,get(i,x,y))}}
 return o
}
func save(_ i:NSBitmapImageRep,_ n:String) {
 try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(dst)/\(n).png"))
}
let oldFront=load("\(src)/front.png"),oldInside=load("\(src)/inside.png")
let oldTrays=load("\(src)/trays.png"),oldGuide=load("\(src)/guide.png")
let front=copy(oldFront),inside=copy(oldInside)
let plum:Pixel=(32,0,16,255)
// Box 1, drawn on the cabinet layer. The approved tray sprites stay intact
// behind it. Paired edits use exactly mirrored coordinates.
func pair(_ x:Int,_ y:Int,_ c:Pixel) {
 precondition((24...58).contains(x) && (136...176).contains(y))
 put(front,x,y,c);put(front,219-x,y,c)
}
let creamTop:Pixel=(247,233,212,255)
let creamFace:Pixel=(233,209,185,255)
for x in 37...41 {pair(x,153,creamTop)}
for x in 37...41 {pair(x,154,creamFace)}
pair(41,155,creamTop)
pair(36,154,plum)
for y in 161...164 {for x in (y==161 ? 48 : 47)...55 {
 let c=get(oldFront,59,y)
 pair(x,y,c.3>0 ? c:creamTop)
}}
// A clean dark L at each pillar foot separates the red support from the
// cream deck, then the cream surface continues behind the front corner.
for x in 40...47 {pair(x,151,plum)}
for y in 147...150 {pair(47,y,plum)}

// Box 2. The visible CRT is an 88 x 84 rounded rectangle. In its middle
// span it is 88 px wide; the otherwise straight sides swell one pixel there.
func screenSpan(_ y:Int)->ClosedRange<Int>? {
 if y<64 || y>147 {return nil}
 let end=min(y-64,147-y)
 switch end {
 case 0:return 73...146
 case 1:return 70...149
 case 2:return 69...150
 case 3:return 68...151
 case 4:return 67...152
 default:return (84...127).contains(y) ? 66...153 : 67...152
 }
}
func screen(_ x:Int,_ y:Int)->Bool {
 guard let span=screenSpan(y) else{return false}
 return span.contains(x)
}
func nearScreen(_ x:Int,_ y:Int)->Int {
 for radius in 1...5 {
  for dy in -radius...radius {for dx in -radius...radius {
   if abs(dx)+abs(dy)==radius && screen(x+dx,y+dy) {return radius}
  }}
 }
 return 6
}
let bezelInner:Pixel=(16,13,30,255)
let bezelMid:Pixel=(31,40,65,255)
let bezelOuter:Pixel=(23,33,55,255)
let screenEdgeLight:Pixel=(35,37,62,255)
let screenEdgeShade:Pixel=(25,25,44,255)
let recess:Pixel=(29,15,38,255)
for y in 58...150 {for x in 62...158 {
 let existing=get(oldFront,x,y)
 // Keep every existing opaque blue surround pixel. Only the old rectangular
 // opening is filled with a dark rim around the new rounded cutout.
 if existing.3==0 {
  if screen(x,y) {put(front,x,y,(0,0,0,0))}
  else {
   let distance=nearScreen(x,y)
   let colour=distance==1 ? bezelInner : distance<=3 ? bezelMid : bezelOuter
   put(front,x,y,colour)
  }
 }
 // The old room already fills most of this area. Extend it behind the new
 // rim and cutout, and remove any pale old side bevel visible in the hole.
 let old=get(oldInside,x,y)
 var colour=old
 if old.3==0 {colour=bezelOuter}
 if screen(x,y) {
  let edge=nearScreen(x,y) // zero for interior; explicit edge test follows
  _=edge
  var touching=false
  for dy in -1...1 {for dx in -1...1 where abs(dx)+abs(dy)==1 {
   if !screen(x+dx,y+dy) {touching=true}
  }}
  if touching {colour = x<109 || y<101 ? screenEdgeLight : screenEdgeShade}
  else if max(Int(colour.0),Int(colour.1),Int(colour.2))>120 {colour=recess}
 }
 put(inside,x,y,colour)
}}
save(front,"front");save(inside,"inside")
save(oldTrays,"trays");save(oldGuide,"guide")

// Pixel audit and a single three-panel diff. The panel order is front,
// trays, inside; magenta marks every changed pixel, including alpha edits.
func allowed(_ x:Int,_ y:Int)->Bool {
 let deck=((24...58).contains(x) || (162...196).contains(x)) && (136...176).contains(y)
 let screen=(62...158).contains(x) && (58...150).contains(y)
 return deck || screen
}
let originals=[oldFront,oldTrays,oldInside],outputs=[front,oldTrays,inside]
let diff=blank(660,220)
var counts=[0,0,0],outside=0
for l in 0..<3 {for y in 0..<220 {for x in 0..<220 {
 let a=get(originals[l],x,y),b=get(outputs[l],x,y)
 let changed=a.0 != b.0 || a.1 != b.1 || a.2 != b.2 || a.3 != b.3
 if changed {counts[l]+=1;if !allowed(x,y){outside+=1}
  put(diff,l*220+x,y,(255,35,221,255))
 } else if a.3>0 {
  put(diff,l*220+x,y,(UInt8(Int(a.0)/3),UInt8(Int(a.1)/3),UInt8(Int(a.2)/3),255))
 }
}}}
precondition(outside==0 && counts[1]==0,"changed pixels outside boxes or in trays")
var screenGaps=0
for y in 64...147 {for x in 66...153 where screen(x,y) {
 if get(front,x,y).3 != 0 || get(inside,x,y).3 != 255 {screenGaps += 1}
}}
precondition(screenGaps==0,"CRT screen is not fully filled by inside layer")
let diff4=blank(2640,880)
for y in 0..<880 {for x in 0..<2640 {put(diff4,x,y,get(diff,x/4,y/4))}}
save(diff4,"diff_vs_final_e_4x")
let preview=blank(220,220)
func over(_ layer:NSBitmapImageRep) {for y in 0..<220 {for x in 0..<220 {
 let c=get(layer,x,y);if c.3>0 {put(preview,x,y,c)}
}}}
over(inside);over(oldTrays);over(front)
let p8=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(p8,x,y,get(preview,x/8,y/8))}}
save(p8,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {
 put(icon,x,y,get(preview,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))
}}
save(icon,"icon")
print("final_f: changed pixels front=\(counts[0]), trays=\(counts[1]), inside=\(counts[2]); outside boxes=\(outside); screen bbox 88x84; screen gaps=\(screenGaps)")
