// Relocate only the orange bell-hook marker. All other guide marks stay intact.
import AppKit
import Foundation
let root="docs/mockups/hokora_homes/v6_1"
let hooks=["moon":(32,84),"capsule_apartment":(14,86),"arcade_cabinet":(28,70)]
for (home,(hx,hy)) in hooks {
    let path="\(root)/\(home)/guide.png"
    let im=NSBitmapImageRep(data:try! Data(contentsOf:URL(fileURLWithPath:path)))!
    let data=im.bitmapData!
    for y in 0..<im.pixelsHigh {for x in 0..<im.pixelsWide {
        let i=y*im.bytesPerRow+x*4
        if data[i]==255 && data[i+1]==112 && data[i+2]==20 && data[i+3]>0 {data[i]=0;data[i+1]=0;data[i+2]=0;data[i+3]=0}
    }}
    for dy in -2...2 {for dx in -2...2 where abs(dx)+abs(dy)<=2 {
        let i=(hy+dy)*im.bytesPerRow+(hx+dx)*4
        data[i]=255;data[i+1]=112;data[i+2]=20;data[i+3]=255
    }}
    try! im.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))
    print("\(home): bell hook (\(hx),\(hy))")
}
