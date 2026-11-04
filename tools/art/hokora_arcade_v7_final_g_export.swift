// Surgical grid edits on the exact arcade art currently used in game.
// Nothing is generated. The audit rejects any change outside the marked spots.
import AppKit
import Foundation

typealias Pixel=(UInt8,UInt8,UInt8,UInt8)
let src="docs/mockups/hokora_homes/v7/arcade_cabinet/current"
let dst="docs/mockups/hokora_homes/v7/arcade_cabinet/final_g"
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
let front=copy(oldFront),trays=copy(oldTrays),inside=copy(oldInside)
let clear:Pixel=(0,0,0,0)
let plum:Pixel=(25,12,29,255)
let bezel:Pixel=(29,21,38,255)
let bevel:Pixel=(67,56,78,255)
let inner:Pixel=(11,10,20,255)

// Bezel: sample the existing rounded screen hole, then paint both side bands
// from the same column logic. The outer vertical edge is x=59 / x=160.
func holeStart(_ y:Int)->Int {
 if y<=63{return 73}
 var x=65
 while x<=82 {if get(oldFront,x,y).3==0{return x};x+=1}
 return 73
}
for y in 62...147 {
 let start=holeStart(y)
 for x in 59..<start {
  let c:Pixel = x==59 ? plum : x==start-1 ? inner : x==start-2 ? bevel : bezel
  put(front,x,y,c);put(front,219-x,y,c)
 }
}
// Remove the pale leftover at the two lower bezel/deck junctions. The deck
// itself starts below this at row 150 and is left intact.
for y in 148...149 {for x in 59...65 {
 put(front,x,y,plum);put(front,219-x,y,plum)
}}

// Pillar feet: one straight dark end line and a cream deck corner under it.
let deckCream:Pixel=(241,222,197,255)
func pairedFront(_ x:Int,_ y:Int,_ c:Pixel) {
 put(front,x,y,c);put(front,219-x,y,c)
}
for x in 36...48 {pairedFront(x,151,plum)}
for y in 152...155 {pairedFront(36,y,plum)}
for y in 152...155 {for x in 37...41 {pairedFront(x,y,deckCream)}}

// Trays stay separate, behind the cabinet. Only the two marked front faces
// are repainted: a level cream edge at the deck's row 150, then a substantial
// red face with a shaded base. The game stacks them backward for depth.
let creamHi:Pixel=(255,250,235,255)
let creamMid:Pixel=(244,224,202,255)
let creamShade:Pixel=(203,169,148,255)
let redHi:Pixel=(253,73,70,255)
let redMid:Pixel=(235,48,56,255)
let redShade:Pixel=(166,25,41,255)
let gold:Pixel=(255,204,105,255)
for y in 150...175 {for u in 1...55 {
 put(trays,u,y,clear);put(trays,219-u,y,clear)
}}
for y in 150...175 {for u in 1...55 {
 if y==150 && (u<4 || u>53) {continue}
 if y==175 && u<7 {continue}
 var c:Pixel=plum
 switch y {
 case 151:c=creamHi
 case 152:c=creamMid
 case 153:c=creamShade
 case 154:c=plum
 case 155...158:c=redHi
 case 159...169:c=redMid
 case 170...173:c=redShade
 default:c=plum
 }
 if (160...166).contains(y) && ((17...18).contains(u) || (30...31).contains(u)) {c=gold}
 if u==1 || u==55 || y==150 || y==174 || y==175 {c=plum}
 put(trays,u,y,c);put(trays,219-u,y,c)
}}

save(front,"front");save(trays,"trays");save(inside,"inside")
save(oldGlass,"glass")
let guide=blank(220,220)
func dot(_ x:Int,_ y:Int,_ c:Pixel) {
 for dy in -1...1 {for dx in -1...1 {put(guide,x+dx,y+dy,c)}}
}
dot(44,22,(255,139,46,255))
dot(56,72,(255,221,40,255));dot(163,72,(255,221,40,255))
dot(27,150,(49,227,100,255));dot(192,150,(49,227,100,255))
save(guide,"guide")

// Full pixel diff: magenta means changed, dim original means untouched.
func allowed(_ l:Int,_ x:Int,_ y:Int)->Bool {
 if l==1 {return ((1...55).contains(x) || (164...218).contains(x)) && (150...175).contains(y)}
 if l==2 {return false}
 let bezelSpot=((59...73).contains(x) || (146...160).contains(x)) && (62...149).contains(y)
 let foot=((36...48).contains(x) || (171...183).contains(x)) && (151...155).contains(y)
 return bezelSpot || foot
}
let originals=[oldFront,oldTrays,oldInside],outputs=[front,trays,inside]
let diff=blank(660,220)
var counts=[0,0,0],outside=0
for l in 0..<3 {for y in 0..<220 {for x in 0..<220 {
 let a=get(originals[l],x,y),b=get(outputs[l],x,y)
 let changed=a.0 != b.0 || a.1 != b.1 || a.2 != b.2 || a.3 != b.3
 if changed {counts[l]+=1;if !allowed(l,x,y){outside+=1};put(diff,l*220+x,y,(255,35,221,255))}
 else if a.3>0 {put(diff,l*220+x,y,(UInt8(Int(a.0)/3),UInt8(Int(a.1)/3),UInt8(Int(a.2)/3),255))}
}}}
var bezelMismatch=0,trayMismatch=0,trayTopMissing=0
for y in 62...147 {for x in 59..<holeStart(y) {
 let a=get(front,x,y),b=get(front,219-x,y)
 if a.0 != b.0 || a.1 != b.1 || a.2 != b.2 || a.3 != b.3 {bezelMismatch+=1}
}}
for y in 150...175 {for x in 1...55 {
 let a=get(trays,x,y),b=get(trays,219-x,y)
 if a.0 != b.0 || a.1 != b.1 || a.2 != b.2 || a.3 != b.3 {trayMismatch+=1}
}}
for x in 4...53 {if get(trays,x,150).3==0 {trayTopMissing+=1}}
precondition(outside==0 && counts[2]==0 && bezelMismatch==0 && trayMismatch==0 && trayTopMissing==0,
 "unmarked, inside, symmetry, or tray-top check failed")
let diff4=blank(2640,880)
for y in 0..<880 {for x in 0..<2640 {put(diff4,x,y,get(diff,x/4,y/4))}}
save(diff4,"diff_vs_current_4x")
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
over(inside);over(oldGlass);over(trays);over(front)
let preview=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(preview,x,y,get(assembled,x/8,y/8))}}
save(preview,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {
 put(icon,x,y,get(assembled,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))
}}
save(icon,"icon")
print("final_g: changed front=\(counts[0]), trays=\(counts[1]), inside=\(counts[2]); outside marked spots=\(outside); mirrored bezel/trays; tray top row 150")
