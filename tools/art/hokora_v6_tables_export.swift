// Technical nearest-neighbour export of ImageGen table-front paintings. No art is drawn here.
import AppKit
import Foundation

let dir=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : "docs/mockups/hokora_homes/v6/tables"
func load(_ path:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:path)))!}
func blank(_ w:Int,_ h:Int)->NSBitmapImageRep {
    let out=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    memset(out.bitmapData!,0,out.bytesPerRow*h)
    return out
}
func px(_ im:NSBitmapImageRep,_ x:Int,_ y:Int)->(UInt8,UInt8,UInt8,UInt8) {
    let p=im.bitmapData!,i=y*im.bytesPerRow+x*4
    return (p[i],p[i+1],p[i+2],p[i+3])
}
func put(_ im:NSBitmapImageRep,_ x:Int,_ y:Int,_ c:(UInt8,UInt8,UInt8,UInt8)) {
    let p=im.bitmapData!,i=y*im.bytesPerRow+x*4
    p[i]=c.0;p[i+1]=c.1;p[i+2]=c.2;p[i+3]=c.3
}
func save(_ im:NSBitmapImageRep,_ path:String) {try! im.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))}
let rows=try! String(contentsOfFile:"\(dir)/manifest.tsv",encoding:.utf8).split(separator:"\n").dropFirst()
for row in rows {
    let c=row.split(separator:"\t").map(String.init),name=c[0],maxWidth=Int(c[1])!
    let src=load("\(dir)/\(name).png")
    var left=src.pixelsWide,top=src.pixelsHigh,right=0,bottom=0
    for y in 0..<src.pixelsHigh {for x in 0..<src.pixelsWide where px(src,x,y).3>=128 {
        left=min(left,x);right=max(right,x);top=min(top,y);bottom=max(bottom,y)
    }}
    guard left<=right else {fatalError("empty source: \(name)")}
    let bw=right-left+1,bh=bottom-top+1
    let scale=min(Double(maxWidth)/Double(bw),44.0/Double(bh))
    let dw=max(1,Int((Double(bw)*scale).rounded(.down))),dh=max(1,Int((Double(bh)*scale).rounded(.down)))
    let out=blank(116,44),dx=(116-dw)/2,dy=44-dh
    for y in 0..<dh {for x in 0..<dw {
        let sx=left+min(bw-1,Int(Double(x)/scale)),sy=top+min(bh-1,Int(Double(y)/scale))
        let color=px(src,sx,sy)
        if color.3>=128 {put(out,dx+x,dy+y,(color.0,color.1,color.2,255))}
    }}
    save(out,"\(dir)/\(name)_116.png")
    let preview=blank(928,352)
    for y in 0..<352 {for x in 0..<928 {put(preview,x,y,px(out,x/8,y/8))}}
    save(preview,"\(dir)/\(name)_preview_8x.png")
    print("\(name): source \(src.pixelsWide)x\(src.pixelsHigh), reduced \(dw)x\(dh) on 116x44")
}
let sheet=blank(4*116*4,max(1,(rows.count+3)/4)*44*4)
for (index,row) in rows.enumerated() {
    let name=String(row.split(separator:"\t")[0]),im=load("\(dir)/\(name)_116.png")
    let ox=(index%4)*116*4,oy=(index/4)*44*4
    for y in 0..<44*4 {for x in 0..<116*4 {put(sheet,ox+x,oy+y,px(im,x/4,y/4))}}
}
save(sheet,"\(dir)/all_tables_4x.png")
