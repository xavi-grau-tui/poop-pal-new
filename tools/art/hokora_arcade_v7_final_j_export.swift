// Final_j: deliberate colour repaint within final_i's locked pixel masks.
import AppKit
import Foundation

typealias Pixel = (UInt8, UInt8, UInt8, UInt8)
let source = "docs/mockups/hokora_homes/v7/arcade_cabinet/final_i"
let target = "docs/mockups/hokora_homes/v7/arcade_cabinet/final_j"
try! FileManager.default.createDirectory(atPath: target, withIntermediateDirectories: true)
func load(_ path: String) -> NSBitmapImageRep {
 NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: path)))!
}
func bitmap(_ w: Int, _ h: Int) -> NSBitmapImageRep {
 let b=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,
 samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,
 bytesPerRow:0,bitsPerPixel:0)!
 memset(b.bitmapData!,0,b.bytesPerRow*h)
 return b
}
func pixel(_ b:NSBitmapImageRep,_ x:Int,_ y:Int)->Pixel {
 let p=b.bitmapData!,i=y*b.bytesPerRow+x*4
 return (p[i],p[i+1],p[i+2],p[i+3])
}
func set(_ b:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:Pixel) {
 let p=b.bitmapData!,i=y*b.bytesPerRow+x*4
 p[i]=c.0;p[i+1]=c.1;p[i+2]=c.2;p[i+3]=c.3
}
func clone(_ b:NSBitmapImageRep)->NSBitmapImageRep {
 let o=bitmap(b.pixelsWide,b.pixelsHigh)
 for y in 0..<b.pixelsHigh {for x in 0..<b.pixelsWide {set(o,x,y,pixel(b,x,y))}}
 return o
}
func save(_ b:NSBitmapImageRep,_ name:String) {
 try! b.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(target)/\(name).png"))
}
let oldFront=load("\(source)/front.png"),oldTrays=load("\(source)/trays.png")
let front=clone(oldFront),trays=clone(oldTrays)
let ink:Pixel=(36,18,31,255)
let redDeep:Pixel=(123,25,39,255),redShadow:Pixel=(166,30,45,255)
let redBase:Pixel=(219,43,56,255),redLight:Pixel=(248,65,70,255)
let redShine:Pixel=(255,119,105,255)
let creamDeep:Pixel=(123,83,67,255),creamShade:Pixel=(186,144,111,255)
let creamBase:Pixel=(238,209,174,255),creamLight:Pixel=(255,240,210,255)
let creamShine:Pixel=(255,250,232,255)
let goldDeep:Pixel=(131,74,35,255),goldBase:Pixel=(217,146,63,255)
let goldLight:Pixel=(255,206,106,255),goldShine:Pixel=(255,239,174,255)
let plumDeep:Pixel=(39,26,49,255),plumBase:Pixel=(61,47,73,255)
let plumLight:Pixel=(94,79,107,255)

func red(_ c:Pixel)->Bool {Int(c.0)>110 && Int(c.0)>Int(c.1)*2 && Int(c.0)>Int(c.2)*15/10}
func cream(_ c:Pixel)->Bool {Int(c.0)>150 && Int(c.1)>115 && Int(c.2)>95 && abs(Int(c.0)-Int(c.1))<85}
func dark(_ c:Pixel)->Bool {Int(c.0)<120 && Int(c.1)<110 && Int(c.2)<150}
func paint(_ b:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:Pixel,_ accepts:(Pixel)->Bool) {
 guard x>=0 && x<b.pixelsWide && y>=0 && y<b.pixelsHigh else {return}
 let p=pixel(b,x,y)
 if p.3==255 && accepts(p) {set(b,x,y,c)}
}
func hline(_ b:NSBitmapImageRep,_ y:Int,_ x0:Int,_ x1:Int,_ c:Pixel,_ accepts:(Pixel)->Bool) {
 for x in x0...x1 {paint(b,x,y,c,accepts)}
}
func vline(_ b:NSBitmapImageRep,_ x:Int,_ y0:Int,_ y1:Int,_ c:Pixel,_ accepts:(Pixel)->Bool) {
 for y in y0...y1 {paint(b,x,y,c,accepts)}
}
func fastener(_ b:NSBitmapImageRep,_ x:Int,_ y:Int,_ metal:Bool=true) {
 let rim=metal ? goldDeep : creamDeep
 let face=metal ? goldLight : creamLight
 for dy in -1...1 {for dx in -1...1 {
  paint(b,x+dx,y+dy,rim,{ $0.3==255 && $0.0>70 })
 }}
 paint(b,x,y,face,{ $0.3==255 && $0.0>70 })
 paint(b,x-1,y-1,goldShine,{ $0.3==255 && $0.0>70 })
}

// Give existing red-painted surfaces a coherent lacquer ramp. Constrain this
// to the large cabinet panels; the lettering and controls retain their art.
for y in 0..<220 {for x in 0..<220 {
 let p=pixel(oldFront,x,y)
 if p.3 != 255 || !red(p) {continue}
 let topBar=(y>=10 && y<=58 && x>=27 && x<=193)
 let pillars=(y>=55 && y<=151 && (x<55 || x>165))
 let lower=(y>=174 && y<=210 && x>=32 && x<=188)
 if !(topBar || pillars || lower) {continue}
 let value=Int(p.0)+Int(p.1)/2
 let lightBias=(x<110 ? 7:0)+(y<100 ? 5:0)
 let v=value+lightBias
 let c:Pixel = v<159 ? redDeep : v<199 ? redShadow :
  v<252 ? redBase : v<307 ? redLight : redShine
 set(front,x,y,c)
}}

// Remove scattered yellow flecks on the lower panel and buttresses. Keep
// material highlights elsewhere: sign, gold hooks, feet, and grille screws.
for y in 174...207 {for x in 35...184 {
 let p=pixel(oldFront,x,y)
 let goldish=Int(p.0)>130 && Int(p.1)>85 && Int(p.2)<145 && Int(p.0)>Int(p.1)*12/10
 if goldish && !(x>=76 && x<=143 && y>=181) && !(y>=202) {
  paint(front,x,y,redBase,{ $0.3==255 })
 }
}}

// The old top-bar flashes were scattered with no connection to a seam.
// Clear those, then light the bar as a single lacquered part below.
for y in 10...58 {for x in 42...178 {
 let p=pixel(oldFront,x,y)
 let topRun=y<=16 || (y>=50 && y<=55)
 let flash=Int(p.0)>155 && Int(p.1)>95 && Int(p.2)<165 && !red(p)
 if topRun && flash {paint(front,x,y,redBase,{ $0.3==255 && $0.0>70 })}
}}
// Clean isolated bright marks on the sloping red panels, while retaining the
// long cream and gold material edges running alongside the bezel.
for y in 80...147 {for x in 20...199 {
 if !(x<39 || x>181) {continue}
 let p=pixel(oldFront,x,y)
 let bright=Int(p.0)>180 && Int(p.1)>110 && Int(p.2)<170 && !red(p)
 if !bright {continue}
 var neighbours=0
 for yy in max(0,y-2)...min(219,y+2) {for xx in max(0,x-2)...min(219,x+2) {
  let q=pixel(oldFront,xx,yy)
  if Int(q.0)>180 && Int(q.1)>110 && Int(q.2)<170 && !red(q) {neighbours+=1}
 }}
 if neighbours<8 {paint(front,x,y,redBase,{ $0.3==255 })}
}}

// A one-pixel light and shadow turn follows the actual sloping supports and
// lower case, so those panels have volume without changing their contours.
let panelColours=clone(front)
for y in 60...210 {for x in 20...199 {
 let side=y<=149 && (x<58 || x>162)
 let base=y>=174 && x>=32 && x<=188
 if !(side || base) {continue}
 let p=pixel(panelColours,x,y)
 if !red(p) {continue}
 let top = !red(pixel(panelColours,x,y-1))
 let left = !red(pixel(panelColours,x-1,y))
 let bottom = !red(pixel(panelColours,x,y+1))
 let right = !red(pixel(panelColours,x+1,y))
 if top || (left && x<110) {set(front,x,y,redLight)}
 else if bottom || (right && x>=110) {set(front,x,y,redShadow)}
}}

// Top bar: brushed top edge, dark underside and two quiet join seams.
hline(front,12,43,176,redShine,red)
hline(front,13,45,174,redLight,red)
hline(front,18,43,176,redShadow,red)
hline(front,54,42,178,redDeep,red)
hline(front,50,44,176,redShine,red)
hline(front,51,45,175,redLight,red)
for x in [51,168] {vline(front,x,12,17,redDeep,red)}
// Shadow in the join between the sign and its lacquer support.
hline(front,47,44,175,redDeep,red)
hline(front,48,44,175,redShadow,red)

// Frame the sign with a warm gold top-left glint and a brown lower edge.
hline(front,19,47,171,goldShine,cream)
hline(front,45,47,171,goldDeep,cream)
vline(front,45,21,43,goldLight,cream)
vline(front,174,21,43,goldDeep,cream)

// Pillars and slanted supports: directional light and depth at the deck join.
for y in 61...148 {
 paint(front,38,y,redShine,red)
 paint(front,181,y,redShadow,red)
}
hline(front,147,29,56,redDeep,red)
hline(front,147,164,191,redDeep,red)

// CRT bezel: one quiet band, lighter above/left and deeper below/right.
hline(front,59,54,166,plumLight,dark)
hline(front,62,57,163,plumBase,dark)
hline(front,149,56,164,plumDeep,dark)
vline(front,53,64,145,plumLight,dark)
vline(front,167,64,145,plumDeep,dark)
for (x,y) in [(53,61),(166,61),(53,146),(166,146)] {
 for dy in -1...1 {for dx in -1...1 {
  paint(front,x+dx,y+dy,plumDeep,dark)
 }}
 paint(front,x,y,plumLight,dark)
}

// Control deck: plate seams, clear near edge, two corner bolts. Avoid the
// centre with the table and the exact joystick/button footprints.
hline(front,151,47,172,creamShine,cream)
hline(front,166,46,173,creamShade,cream)
hline(front,171,44,176,creamDeep,cream)
vline(front,45,153,166,creamShade,cream)
vline(front,175,153,166,creamDeep,cream)
for (x,y) in [(48,157),(171,157),(48,165),(171,165)] {fastener(front,x,y)}

// Lower cabinet's purposeful join seams and trim replace loose spark marks.
hline(front,176,44,176,redShine,red)
hline(front,180,46,174,redShadow,red)
hline(front,182,46,174,redDeep,red)
hline(front,207,47,172,redDeep,red)
hline(front,208,49,170,redLight,red)
vline(front,49,183,201,redShadow,red)
vline(front,170,183,201,redDeep,red)
for (x,y) in [(53,187),(166,187),(53,199),(166,199)] {fastener(front,x,y)}

// Trays are separate game layers. Give each the same cream bevel and lacquer
// ramp as the deck, while leaving its exact alpha silhouette intact.
for y in 0..<220 {for x in 0..<220 {
 let p=pixel(oldTrays,x,y)
 if p.3 != 255 {continue}
 if red(p) {
  let v=Int(p.0)+Int(p.1)/2+(x<110 ? 5:0)
  set(trays,x,y,v<170 ? redDeep : v<220 ? redShadow : v<275 ? redBase : redLight)
 }
}}
for (a,b) in [(5,40),(180,215)] {
 hline(trays,151,a,b,creamShine,cream)
 hline(trays,156,a,b,creamShade,cream)
 hline(trays,166,a,b,redDeep,red)
 hline(trays,168,a,b,redShadow,red)
}
for (x,y) in [(9,154),(37,154),(183,154),(211,154)] {fastener(trays,x,y)}

save(front,"front");save(trays,"trays")
for name in ["inside","glass","guide"] {
 let out="\(target)/\(name).png"
 try? FileManager.default.removeItem(atPath:out)
 try! FileManager.default.copyItem(atPath:"\(source)/\(name).png",toPath:out)
}

// Compose the game layers. The game inserts spirit and table separately.
let inside=load("\(source)/inside.png"),glass=load("\(source)/glass.png")
let composed=bitmap(220,220)
func over(_ b:NSBitmapImageRep) {
 for y in 0..<220 {for x in 0..<220 {
  let p=pixel(b,x,y),d=pixel(composed,x,y)
  if p.3==0 {continue}
  if p.3==255 {set(composed,x,y,p);continue}
  let sa=Double(p.3)/255,da=Double(d.3)/255,oa=sa+da*(1-sa)
  if oa==0 {continue}
  func mix(_ a:UInt8,_ b:UInt8)->UInt8 {
   UInt8(max(0,min(255,Int((Double(a)*sa+Double(b)*da*(1-sa))/oa+0.5))))
  }
  set(composed,x,y,(mix(p.0,d.0),mix(p.1,d.1),mix(p.2,d.2),UInt8(oa*255+0.5)))
 }}
}
over(inside);over(glass);over(trays);over(front)
let preview=bitmap(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {set(preview,x,y,pixel(composed,x/8,y/8))}}
save(preview,"preview_8x")
let icon=bitmap(96,96)
for y in 0..<96 {for x in 0..<96 {
 set(icon,x,y,pixel(composed,min(219,(x*220+110)/96),min(219,(y*220+110)/96)))
}}
save(icon,"icon")

var frontChanged=0,traysChanged=0,maskChanged=0
let diff=bitmap(440,220)
for y in 0..<220 {for x in 0..<220 {
 let af=pixel(oldFront,x,y),bf=pixel(front,x,y)
 let at=pixel(oldTrays,x,y),bt=pixel(trays,x,y)
 if af.3 != bf.3 || at.3 != bt.3 {maskChanged+=1}
 let frontDiff=af.0 != bf.0 || af.1 != bf.1 || af.2 != bf.2 || af.3 != bf.3
 let traysDiff=at.0 != bt.0 || at.1 != bt.1 || at.2 != bt.2 || at.3 != bt.3
 if frontDiff {frontChanged+=1}
 if traysDiff {traysChanged+=1}
 if frontDiff {set(diff,x,y,(255,29,224,255))}
 else if af.3>0 {set(diff,x,y,(af.0/3,af.1/3,af.2/3,255))}
 if traysDiff {set(diff,x+220,y,(255,29,224,255))}
 else if at.3>0 {set(diff,x+220,y,(at.0/3,at.1/3,at.2/3,255))}
}}
precondition(maskChanged==0)
let diff4=bitmap(1760,880)
for y in 0..<880 {for x in 0..<1760 {set(diff4,x,y,pixel(diff,x/4,y/4))}}
save(diff4,"diff_vs_final_i_4x")
print("final_j audit: front changed \(frontChanged) pixels; trays changed \(traysChanged); alpha mask changes \(maskChanged); inside/glass copied unchanged")

// Same-scale quality row: replace only the Arcade panel in the supplied row.
let comparison=load("\(source)/quality_vs_other_homes.png")
let row=clone(comparison)
let bg=pixel(comparison,0,0)
for y in 0..<440 {for x in 0..<440 {
 let p=pixel(composed,x/2,y/2)
 if p.3==0 {set(row,x,y,bg)}
 else if p.3==255 {set(row,x,y,p)}
 else {
  let a=Double(p.3)/255
  func m(_ s:UInt8,_ b:UInt8)->UInt8 {UInt8(Double(s)*a+Double(b)*(1-a)+0.5)}
  set(row,x,y,(m(p.0,bg.0),m(p.1,bg.1),m(p.2,bg.2),255))
 }
}}
save(row,"quality_vs_other_homes")
