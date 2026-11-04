// final_i: a small deck-only correction on the approved final_h layers.
import AppKit
import Foundation

typealias Pixel=(UInt8,UInt8,UInt8,UInt8)
let src="docs/mockups/hokora_homes/v7/arcade_cabinet/final_h"
let dst="docs/mockups/hokora_homes/v7/arcade_cabinet/final_i"
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
let front=copy(oldFront)

// The middle of each horizontal deck band has the approved colour. Continue
// that exact colour through the two mismatched joins, without touching the
// joystick's top pixels at x66...79. Row 154 also clears the named white and
// black pixels above the yellow button.
for y in 152...154 {
 let c=get(oldFront,110,y)
 for x in 49...65 {if get(oldFront,x,y).3==255 {put(front,x,y,c)}}
 for x in 80...175 {if get(oldFront,x,y).3==255 {put(front,x,y,c)}}
}
// The grey pixels below the yellow button are background, not its rim.
for x in 163...165 {put(front,x,165,get(oldFront,110,165))}

// Refinish the controls in their existing footprints. Work directly on the
// 220-pixel grid: a round joystick socket, short shaft, and three equal keys.
for y in 161...166 {for x in 64...81 {put(front,x,y,get(oldFront,110,y))}}
for y in 161...166 {for x in 64...81 {
 let dx=(Double(x)-72.5)/8.5,dy=(Double(y)-163.5)/3.1
 let d=dx*dx+dy*dy
 if d<=1.0 {
  let c:Pixel = d>0.68 ? (16,18,26,255) :
   (y<=163 && x<=73 ? (117,136,168,255) : (52,65,87,255))
  put(front,x,y,c)
 }
}}
for y in 159...162 {for x in 71...73 {
 put(front,x,y,x==71 ? (66,82,109,255) : (17,24,35,255))
}}
// The red ball retains its approved silhouette and receives a two-pixel shine.
for y in 152...160 {for x in 66...77 {
 let p=get(oldFront,x,y)
 if p.0>120 && Int(p.0)>Int(p.1)*2 && Int(p.0)>Int(p.2)*2 {put(front,x,y,p)}
}}
for x in 69...70 {put(front,x,154,(255,241,204,255))}

let buttonCenters=[138,149,160]
let buttonFill:[Pixel]=[(246,53,62,255),(15,176,245,255),(252,179,11,255)]
let buttonShade:[Pixel]=[(190,24,34,255),(0,94,178,255),(191,120,0,255)]
for (k,cx) in buttonCenters.enumerated() {
 for y in 155...164 {for x in (cx-5)...(cx+5) {
  put(front,x,y,get(oldFront,110,y))
 }}
 // A one-pixel contact shadow, then a dark continuous rim and rounded cap.
 for x in (cx-3)...(cx+3) {put(front,x,164,(122,92,78,255))}
 for y in 156...163 {for x in (cx-5)...(cx+5) {
  let dx=(Double(x)-Double(cx))/5.1,dy=(Double(y)-159.5)/4.1
  let d=dx*dx+dy*dy
  if d<=1.0 {
   let ink:Pixel=(28,20,27,255)
   let c=d>0.64 ? ink : (y>=161 ? buttonShade[k] : buttonFill[k])
   put(front,x,y,c)
  }
 }}
 for x in (cx-2)...(cx-1) {put(front,x,157,(255,245,218,255))}
}

save(front,"front")
for name in ["trays","inside","glass","guide"] {
 let out="\(dst)/\(name).png"
 try? FileManager.default.removeItem(atPath:out)
 try! FileManager.default.copyItem(atPath:"\(src)/\(name).png",toPath:out)
}

// Diff audit: only the named deck bands and under-button streak may change.
let originalLayers=[oldFront,oldTrays,oldInside,oldGlass]
let outputLayers=[front,oldTrays,oldInside,oldGlass]
let diff=blank(880,220)
var changed=[0,0,0,0],outside=0,alphaChanged=0
func allowed(_ x:Int,_ y:Int)->Bool {
 if (152...154).contains(y) && ((49...65).contains(x) || (80...175).contains(x)) {return true}
 if y==165 && (163...165).contains(x) {return true}
 if (152...166).contains(y) && (64...81).contains(x) {return true}
 if (155...164).contains(y) && ((133...143).contains(x) || (144...154).contains(x) || (155...165).contains(x)) {return true}
 return false
}
for l in 0..<4 {for y in 0..<220 {for x in 0..<220 {
 let a=get(originalLayers[l],x,y),b=get(outputLayers[l],x,y)
 let different=a.0 != b.0 || a.1 != b.1 || a.2 != b.2 || a.3 != b.3
 if a.3 != b.3 {alphaChanged+=1}
 if different {
  changed[l]+=1
  if l != 0 || !allowed(x,y) {outside+=1}
  put(diff,l*220+x,y,(255,35,221,255))
 } else if a.3>0 {
  put(diff,l*220+x,y,(UInt8(Int(a.0)/3),UInt8(Int(a.1)/3),UInt8(Int(a.2)/3),255))
 }
}}}
precondition(outside==0 && alphaChanged==0 && changed[0]>0,
 "changed pixels outside deck pass or alpha mask")
let diff4=blank(3520,880)
for y in 0..<880 {for x in 0..<3520 {put(diff4,x,y,get(diff,x/4,y/4))}}
save(diff4,"diff_vs_final_h_4x")

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
over(oldInside);over(oldGlass);over(oldTrays);over(front)
let preview=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(preview,x,y,get(assembled,x/8,y/8))}}
save(preview,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {
 put(icon,x,y,get(assembled,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))
}}
save(icon,"icon")
print("final_i: front changed \(changed[0]) pixels; trays/inside/glass unchanged; outside=\(outside), alpha=\(alphaChanged)")
