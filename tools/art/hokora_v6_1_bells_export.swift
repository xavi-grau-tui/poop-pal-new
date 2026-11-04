// Separate the three ImageGen-painted objects in each sheet and put them on the game grid.
import AppKit
import Foundation

let root="docs/mockups/hokora_homes/v6_1"
let homes=["neon_cyber","moon","golden","ruined_night","tree_hollow","ramen_stall","capsule_apartment","arcade_cabinet","bathhouse","fire"]
let lanternNames=["neon_cyber":"holo_cube","moon":"crescent","golden":"phoenix","ruined_night":"ghost_stone","tree_hollow":"firefly_jar","ramen_stall":"akachochin","capsule_apartment":"pod_led","arcade_cabinet":"pixel_heart","bathhouse":"frosted_bath","fire":"iron_flame"]
typealias P=(UInt8,UInt8,UInt8,UInt8)
func load(_ path:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:path)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
    let im=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    memset(im.bitmapData!,0,im.bytesPerRow*h);return im
}
func px(_ im:NSBitmapImageRep,_ x:Int,_ y:Int)->P {let d=im.bitmapData!,i=y*im.bytesPerRow+x*4;return(d[i],d[i+1],d[i+2],d[i+3])}
func put(_ im:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:P) {let d=im.bitmapData!,i=y*im.bytesPerRow+x*4;d[i]=c.0;d[i+1]=c.1;d[i+2]=c.2;d[i+3]=c.3}
func save(_ im:NSBitmapImageRep,_ path:String) {try! im.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))}
func piece(_ sheet:NSBitmapImageRep,_ third:Int,_ width:Int,_ height:Int)->NSBitmapImageRep {
    let x0=third*sheet.pixelsWide/3,x1=(third+1)*sheet.pixelsWide/3
    var left=x1,top=sheet.pixelsHigh,right=x0,bottom=0
    for y in 0..<sheet.pixelsHigh {for x in x0..<x1 where px(sheet,x,y).3>=128 {left=min(left,x);right=max(right,x);top=min(top,y);bottom=max(bottom,y)}}
    precondition(left<=right)
    let bw=right-left+1,bh=bottom-top+1
    let scale=min(Double(width-2)/Double(bw),Double(height-2)/Double(bh))
    let dw=max(1,Int((Double(bw)*scale).rounded(.down))),dh=max(1,Int((Double(bh)*scale).rounded(.down)))
    let out=blank(width,height),dx=(width-dw)/2,dy=(height-dh)/2
    for y in 0..<dh {for x in 0..<dw {
        let sx=left+min(bw-1,Int(Double(x)/scale)),sy=top+min(bh-1,Int(Double(y)/scale))
        let c=px(sheet,sx,sy)
        if c.3>=128 {put(out,dx+x,dy+y,(c.0,c.1,c.2,255))}
    }}
    return out
}
for home in homes {
    let dir="\(root)/\(home)"
    try! FileManager.default.createDirectory(atPath:dir,withIntermediateDirectories:true)
    let sheet=load("\(root)/bells/\(home)/source_sheet.png")
    let bell=piece(sheet,0,76,86),bead1=piece(sheet,1,48,68),bead2=piece(sheet,2,48,68)
    save(bell,"\(dir)/bell.png");save(bead1,"\(dir)/bead_1.png");save(bead2,"\(dir)/bead_2.png")
    let stack=blank(220,86+5*68)
    for y in 0..<86 {for x in 0..<76 {put(stack,x+8,y,px(bell,x,y))}}
    for i in 0..<5 {let bead=i%2==0 ? bead1 : bead2;for y in 0..<68 {for x in 0..<48 {put(stack,x+22,86+i*68+y,px(bead,x,y))}}}
    let lanternPath="docs/mockups/hokora_decor/round3/\(home)/lantern_\(lanternNames[home]!)_0.png"
    let lantern=load(lanternPath)
    for y in 0..<min(176,lantern.pixelsHigh*4) {for x in 0..<min(108,lantern.pixelsWide*4) {
        // The accepted lantern PNGs are indexed RGB, unlike our RGBA export
        // canvases. Read them through AppKit's colour API before compositing.
        if let color=lantern.colorAt(x:x/4,y:y/4)?.usingColorSpace(.deviceRGB), color.alphaComponent>0 {
            let c:P=(UInt8((color.redComponent*255).rounded()),UInt8((color.greenComponent*255).rounded()),UInt8((color.blueComponent*255).rounded()),UInt8((color.alphaComponent*255).rounded()))
            put(stack,105+x,y,c)
        }
    }}
    let preview=blank(stack.pixelsWide*8,stack.pixelsHigh*8)
    for y in 0..<preview.pixelsHigh {for x in 0..<preview.pixelsWide {put(preview,x,y,px(stack,x/8,y/8))}}
    save(preview,"\(dir)/bell_preview_8x.png")
    print("\(home): bell 76x86, beads 48x68, source \(sheet.pixelsWide)x\(sheet.pixelsHigh)")
}
