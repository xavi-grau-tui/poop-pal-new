// Technical nearest-neighbour export: approved v6.1 bells/beads, with fuller beads;
// Moon bell comes from its new ImageGen contrast painting.
import AppKit
import Foundation
let base="docs/mockups/hokora_homes",homes=["neon_cyber","moon","golden","ruined_night","tree_hollow","ramen_stall","capsule_apartment","arcade_cabinet","bathhouse","fire"]
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func canvas(_ w:Int,_ h:Int)->NSBitmapImageRep {let o=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!;memset(o.bitmapData!,0,o.bytesPerRow*h);return o}
func put(_ im:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:NSColor) {im.setColor(c,atX:x,y:y)}
func save(_ im:NSBitmapImageRep,_ p:String) {try! im.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:p))}
func largestShape(_ im:NSBitmapImageRep)->((Int,Int,Int,Int),[Bool]) {
    let w=im.pixelsWide,h=im.pixelsHigh
    var opaque=[Bool](repeating:false,count:w*h),seen=opaque,best=[Int]()
    for y in 0..<h {for x in 0..<w {opaque[y*w+x]=im.colorAt(x:x,y:y)!.alphaComponent >= 0.5}}
    for start in 0..<w*h where opaque[start] && !seen[start] {
        var q=[start],head=0;seen[start]=true
        while head<q.count {
            let v=q[head],x=v%w,y=v/w;head+=1
            for (nx,ny) in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)] where nx>=0 && nx<w && ny>=0 && ny<h {
                let u=ny*w+nx;if opaque[u] && !seen[u] {seen[u]=true;q.append(u)}
            }
        }
        if q.count>best.count {best=q}
    }
    var l=w,t=h,r=0,b=0,mask=[Bool](repeating:false,count:w*h)
    for v in best {let x=v%w,y=v/w;mask[v]=true;l=min(l,x);r=max(r,x);t=min(t,y);b=max(b,y)}
    return ((l,t,r,b),mask)
}
func bounds(_ im:NSBitmapImageRep)->(Int,Int,Int,Int) {largestShape(im).0}
func fitted(_ im:NSBitmapImageRep,_ w:Int,_ h:Int,_ drawW:Int,_ drawH:Int)->NSBitmapImageRep {
    let out=canvas(w,h),shape=largestShape(im),b=shape.0,sw=b.2-b.0+1,sh=b.3-b.1+1,ox=(w-drawW)/2,oy=(h-drawH)/2
    for y in 0..<drawH {for x in 0..<drawW {
        let sx=b.0+min(sw-1,Int(Double(x)*Double(sw)/Double(drawW))),sy=b.1+min(sh-1,Int(Double(y)*Double(sh)/Double(drawH)))
        if !shape.1[sy*im.pixelsWide+sx] {continue}
        let c=im.colorAt(x:sx,y:sy)!.usingColorSpace(.deviceRGB)!
        if c.alphaComponent >= 0.5 {put(out,ox+x,oy+y,NSColor(deviceRed:c.redComponent,green:c.greenComponent,blue:c.blueComponent,alpha:1))}
    }}
    return out
}
for home in homes {
    let d="\(base)/v6_2/\(home)"
    try! FileManager.default.createDirectory(atPath:d,withIntermediateDirectories:true)
    let old="\(base)/v6_1/\(home)"
    let bell: NSBitmapImageRep
    if home=="moon" {bell=fitted(load("\(d)/bell_source_imagegen.png"),76,86,74,84)}
    else {bell=load("\(old)/bell.png")}
    save(bell,"\(d)/bell.png")
    let one=fitted(load("\(old)/bead_1.png"),48,68,44,68),two=fitted(load("\(old)/bead_2.png"),48,68,44,68)
    save(one,"\(d)/bead_1.png");save(two,"\(d)/bead_2.png")
    let stack=canvas(96,86+5*68)
    for y in 0..<86 {for x in 0..<76 {let c=bell.colorAt(x:x,y:y)!;if c.alphaComponent>0 {put(stack,x+10,y,c)}}}
    for n in 0..<5 {let bead=n%2==0 ? one : two;for y in 0..<68 {for x in 0..<48 {let c=bead.colorAt(x:x,y:y)!;if c.alphaComponent>0 {put(stack,x+24,86+n*68+y,c)}}}}
    let p=canvas(384,1704)
    for y in 0..<1704 {for x in 0..<384 {put(p,x,y,stack.colorAt(x:x/4,y:y/4)!)}}
    save(p,"\(d)/bell_chain_4x.png")
    let b=bounds(one),c=bounds(two)
    print("\(home): bead bounds \(b), \(c); bell 76x86")
}
