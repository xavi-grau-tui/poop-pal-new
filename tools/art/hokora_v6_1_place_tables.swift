// Technical placement of the four selected ImageGen table fronts on 220x220 home canvases.
import AppKit
import Foundation

let root="docs/mockups/hokora_homes/v6_1"
let names=[("golden","golden_table_front"),("ramen_stall","ramen_stall_table_front"),("ruined_night","ruined_night_table_front"),("tree_hollow","tree_hollow_table_front")]
func load(_ p:String)->NSBitmapImageRep {NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:p)))!}
func blank()->NSBitmapImageRep {
    let im=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:220,pixelsHigh:220,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    memset(im.bitmapData!,0,im.bytesPerRow*220);return im
}
for (home,name) in names {
    let src=load("\(root)/tables/\(name)_116.png"),out=blank()
    for y in 0..<22 {for x in 0..<58 {
        let c=src.colorAt(x:x*2,y:y*2)!.usingColorSpace(.deviceRGB)!
        if c.alphaComponent < 0.5 {continue}
        out.setColor(NSColor(deviceRed:c.redComponent,green:c.greenComponent,blue:c.blueComponent,alpha:1),atX:81+x,y:140+y)
    }}
    try! out.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(root)/\(home)/table.png"))
    print("\(home): table 220x220, feet at floor row 161")
}
