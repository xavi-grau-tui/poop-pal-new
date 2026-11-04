// final_h: localized pixel edits on final_g, without ImageGen or redrawing.
import AppKit
import Foundation

typealias Pixel=(UInt8,UInt8,UInt8,UInt8)
let src="docs/mockups/hokora_homes/v7/arcade_cabinet/final_g"
let dst="docs/mockups/hokora_homes/v7/arcade_cabinet/final_h"
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
let oldFront=load("\(src)/front.png"),oldTrays=load("\(src)/trays.png")
let oldInside=load("\(src)/inside.png"),oldGlass=load("\(src)/glass.png")
let oldGuide=load("\(src)/guide.png")
let front=copy(oldFront),trays=copy(oldTrays)
let clear:Pixel=(0,0,0,0)
let outline:Pixel=(20,14,27,255)
let band:Pixel=(45,34,55,255)
let bevel:Pixel=(101,85,116,255)

// The alpha cutout is the approved one. Flatten only existing opaque bezel
// paint: a dark outside edge, one flat plum band, one inner bevel line.
func isBezelPaint(_ p:Pixel)->Bool {
 p.3==255 && Int(p.0)<135 && Int(p.1)<145 && Int(p.2)<180 && Int(p.2)>=Int(p.0)*3/4
}
func touchesHole(_ x:Int,_ y:Int)->Bool {
 for (dx,dy) in [(0,-1),(0,1),(-1,0),(1,0)] {
  let xx=x+dx,yy=y+dy
  if xx>=0 && xx<220 && yy>=0 && yy<220 && get(oldFront,xx,yy).3==0 {return true}
 }
 return false
}
for y in 57...150 {for x in 56...163 {
 let p=get(oldFront,x,y)
 if !isBezelPaint(p) {continue}
 let outside=x==59 || x==160 || y==59 || y==149
 let c=touchesHole(x,y) ? bevel : outside ? outline : band
 put(front,x,y,c)
}}
// Give the short sides exactly the same paint, pixel for pixel. The bell is
// far above this area, so no asymmetric content is affected.
for y in 62...147 {for x in 59...65 {
 let a=get(oldFront,x,y),b=get(oldFront,219-x,y)
 if isBezelPaint(a) && isBezelPaint(b) {put(front,219-x,y,get(front,x,y))}
}}

// The tray faces remain behind the cabinet. Reuse the deck's own top-edge
// colour at each row; below it, one shaded red face and a continuous gold rule.
let redTop:Pixel=(248,69,69,255)
let redMain:Pixel=(229,51,60,255)
let redLow:Pixel=(161,28,43,255)
let gold:Pixel=(241,184,92,255)
for y in 150...175 {for u in 1...35 {
 put(trays,u,y,clear);put(trays,219-u,y,clear)
}}
for y in 150...175 {for u in 1...35 {
 if y==150 && u<3 {continue}
 if y==175 && u<5 {continue}
 var c:Pixel=outline
 if (151...154).contains(y) {c=get(oldFront,110,y)}
 if (155...159).contains(y) {c=redTop}
 if (160...168).contains(y) {c=redMain}
 if (169...173).contains(y) {c=redLow}
 if y==160 && (4...34).contains(u) {c=gold}
 if u==1 || y==150 || y==174 || y==175 {c=outline}
 put(trays,u,y,c);put(trays,219-u,y,c)
}}

// Paint a quiet cream deck from the centre deck's approved tone steps.
// This removes the white corner notches, two red specks and grey streaks.
func deck(_ x:Int,_ y:Int) {
 if get(oldFront,x,y).3>0 {put(front,x,y,get(oldFront,110,y))}
}
for y in 152...168 {
 for x in 56...82 {deck(x,y)}
 for x in 132...170 {deck(x,y)}
}
for y in 151...155 {for x in 35...40 {deck(x,y);deck(219-x,y)}}
for y in 151...154 {for x in 56...59 {deck(x,y);deck(219-x,y)}}
for y in 164...166 {for x in 48...55 {deck(x,y);deck(219-x,y)}}
for y in 164...166 {for x in 165...172 {deck(x,y)}}

// The approved joystick already has a round dark base, short shaft and a
// two-pixel red-ball catch. Keep its painting, only clean the deck around it.
for y in 152...168 {for x in 63...79 {put(front,x,y,get(oldFront,x,y))}}
// The three approved buttons have the richer shading and even 10-pixel caps
// seen in game. Move their group one pixel left: its centre is now x=149,
// exactly 39 pixels from the centre, matching the joystick at x=71.
for y in 154...166 {for x in 134...166 {put(front,x-1,y,get(oldFront,x,y))}}

save(front,"front");save(trays,"trays")
save(oldInside,"inside");save(oldGlass,"glass");save(oldGuide,"guide")

// Three-panel diff. Magenta is every changed pixel, including transparency.
func allowed(_ l:Int,_ x:Int,_ y:Int)->Bool {
 if l==1 {return ((1...35).contains(x) || (184...218).contains(x)) && (150...175).contains(y)}
 if l==2 {return false}
 let screen=(48...172).contains(x) && (54...152).contains(y)
 let controls=(((44...82).contains(x) || (132...176).contains(x)) && (150...169).contains(y))
 let corners=(((35...40).contains(x) || (179...184).contains(x)) && (151...155).contains(y))
 return screen || controls || corners
}
let originals=[oldFront,oldTrays,oldInside],outputs=[front,trays,oldInside]
let diff=blank(660,220)
var counts=[0,0,0],outside=0,frontAlphaChanged=0
for l in 0..<3 {for y in 0..<220 {for x in 0..<220 {
 let a=get(originals[l],x,y),b=get(outputs[l],x,y)
 let changed=a.0 != b.0 || a.1 != b.1 || a.2 != b.2 || a.3 != b.3
 if l==0 && a.3 != b.3 {frontAlphaChanged+=1}
 if changed {counts[l]+=1;if !allowed(l,x,y){outside+=1};put(diff,l*220+x,y,(255,35,221,255))}
 else if a.3>0 {put(diff,l*220+x,y,(UInt8(Int(a.0)/3),UInt8(Int(a.1)/3),UInt8(Int(a.2)/3),255))}
}}}
precondition(outside==0 && frontAlphaChanged==0 && counts[2]==0,"unmarked, opening or inside pixels changed")
let diff4=blank(2640,880)
for y in 0..<880 {for x in 0..<2640 {put(diff4,x,y,get(diff,x/4,y/4))}}
save(diff4,"diff_vs_final_g_4x")

let assembled=blank(220,220)
func over(_ layer:NSBitmapImageRep) {for y in 0..<220 {for x in 0..<220 {
 let p=get(layer,x,y),b=get(assembled,x,y)
 if p.3==0 {continue}
 if p.3==255 {put(assembled,x,y,p);continue}
 let sa=Double(p.3)/255,da=Double(b.3)/255,oa=sa+da*(1-sa)
 if oa<=0 {continue}
 func mix(_ s:UInt8,_ d:UInt8)->UInt8 {
  UInt8(max(0,min(255,Int((Double(s)*sa+Double(d)*da*(1-sa))/oa+0.5))))
 }
 put(assembled,x,y,(mix(p.0,b.0),mix(p.1,b.1),mix(p.2,b.2),UInt8(Int(oa*255+0.5))))
}}}
over(oldInside);over(oldGlass);over(trays);over(front)
let preview=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(preview,x,y,get(assembled,x/8,y/8))}}
save(preview,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {
 put(icon,x,y,get(assembled,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))
}}
save(icon,"icon")
print("final_h: changed front=\(counts[0]), trays=\(counts[1]), inside=\(counts[2]); outside marked areas=\(outside); front alpha changes=\(frontAlphaChanged)")
