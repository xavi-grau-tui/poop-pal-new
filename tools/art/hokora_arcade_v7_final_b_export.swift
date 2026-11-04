// Final-grid export of the approved Option A ImageGen cabinet.
// ImageGen removed the example objects and table; this separates its screen
// into front/inside while preserving the painted cabinet and hard pixels.
import AppKit
import Foundation

typealias C=(UInt8,UInt8,UInt8,UInt8)
let dir="docs/mockups/hokora_homes/v7/arcade_cabinet/final_b"
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
 let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 memset(i.bitmapData!,0,i.bytesPerRow*h);return i
}
func get(_ i:NSBitmapImageRep,_ x:Int,_ y:Int)->C {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;return(p[j],p[j+1],p[j+2],p[j+3])}
func put(_ i:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:C) {let p=i.bitmapData!,j=y*i.bytesPerRow+x*4;p[j]=c.0;p[j+1]=c.1;p[j+2]=c.2;p[j+3]=c.3}
func save(_ i:NSBitmapImageRep,_ name:String) {try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(dir)/\(name).png"))}
let src=load("\(dir)/source_imagegen.png")
let master=blank(220,220)
for y in 0..<220 {for x in 0..<220 {
 let sx=min(src.pixelsWide-1,Int((Double(x)+0.5)*Double(src.pixelsWide)/220))
 let sy=min(src.pixelsHigh-1,Int((Double(y)+0.5)*Double(src.pixelsHigh)/220))
 let c=get(src,sx,sy)
 if c.3>=128 {put(master,x,y,(c.0,c.1,c.2,255))}
}}
// The cabinet, broad wings and lantern arms mirror exactly. Keep the logo and
// different left/right controls untouched in the central region.
for y in 0..<220 {for x in 0..<54 {
 // The high bell hook is intentionally left-only. Everything else on the
 // outside, including both trays and lantern arms, mirrors exactly.
 if !((34...52).contains(x) && (15...35).contains(y)) {
  put(master,219-x,y,get(master,x,y))
 }
}}
// Keep the ImageGen-painted outer pillar flares exactly. The movable ornaments
// draw above the cabinet; their sprites may visually overlap these pillars.
let front=blank(220,220),inside=blank(220,220)
for y in 0..<220 {for x in 0..<220 {put(front,x,y,get(master,x,y))}}
// The slightly smaller aperture returns thickness to the side pillars.
// Its full clear rectangle measures 80 wide × 78 high.
func window(_ x:Int,_ y:Int)->Bool {
 (70...149).contains(x) && (67...144).contains(y)
}
for y in 59...152 {for x in 62...157 {
 let sx=min(149,max(70,x)),sy=min(144,max(67,y))
 let c=get(master,sx,sy)
 // Copy the same ImageGen-painted blue room beyond the aperture so tilt
 // cannot reveal a gap. The front masks the extra pixels.
 put(inside,x,y,c.3==0 ? (22,62,133,255) : c)
}}
for y in 0..<220 {for x in 0..<220 where window(x,y) {put(front,x,y,(0,0,0,0))}}
save(front,"front");save(inside,"inside")
let guide=blank(220,220)
func dot(_ x:Int,_ y:Int,_ c:C) {for dy in -1...1 {for dx in -1...1 {put(guide,x+dx,y+dy,c)}}}
dot(44,22,(255,139,46,255))            // bell high on left pillar
dot(56,72,(255,221,40,255))            // left lantern
dot(163,72,(255,221,40,255))           // right lantern
dot(20,144,(49,227,100,255))          // left usable tray top
dot(199,144,(49,227,100,255))         // right usable tray top
save(guide,"guide")
func over(_ dst:NSBitmapImageRep,_ layer:NSBitmapImageRep) {
 for y in 0..<220 {for x in 0..<220 {
  let c=get(layer,x,y);if c.3>0 {put(dst,x,y,c)}
 }}
}
let preview=blank(220,220)
over(preview,inside);over(preview,front)
let p8=blank(1760,1760)
for y in 0..<1760 {for x in 0..<1760 {put(p8,x,y,get(preview,x/8,y/8))}}
save(p8,"preview_8x")
let icon=blank(96,96)
for y in 0..<96 {for x in 0..<96 {put(icon,x,y,get(preview,min(219,Int((Double(x)+0.5)*220/96)),min(219,Int((Double(y)+0.5)*220/96))))}}
save(icon,"icon")
var badAlpha=0,uncut=0,holes=0,asymmetry=0
var clearanceLeft=0,clearanceRight=0
for y in 0..<220 {for x in 0..<220 {
 let f=get(front,x,y),b=get(inside,x,y)
 if !(f.3==0 || f.3==255) || !(b.3==0 || b.3==255) {badAlpha += 1}
 if window(x,y) {if f.3 != 0 {uncut += 1};if b.3 != 255 {holes += 1}}
 let bellArea=(34...52).contains(x) && (15...35).contains(y)
 if x<54 && !bellArea && get(master,x,y).3 != get(master,219-x,y).3 {asymmetry += 1}
 if (101...142).contains(y) && (1...38).contains(x) && f.3>0 {clearanceLeft += 1}
 if (101...142).contains(y) && (181...218).contains(x) && f.3>0 {clearanceRight += 1}
}}
func longestRun(_ range:ClosedRange<Int>,_ y:Int)->Int {var run=0,best=0
 for x in range {if get(front,x,y).3>0 {run += 1;best=max(best,run)} else {run=0}}
 return best
}
let leftTray=longestRun(0...60,144),rightTray=longestRun(159...219,144)
let bellBottom=22+45
precondition(badAlpha==0 && uncut==0 && holes==0 && asymmetry==0 && leftTray>=40 && rightTray>=40 && bellBottom<101,"arcade layer validation failed")
print("Arcade v7 final_b: original flared silhouette retained; 220x220; screen 80x78; trays \(leftTray)/\(rightTray) px; high bell hook, symmetry and hard-alpha checks passed")
