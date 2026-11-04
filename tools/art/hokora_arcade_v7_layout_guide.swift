// Layout guide only: coloured reservation boxes for ImageGen concept edits.
import AppKit
import Foundation
let out="docs/mockups/hokora_homes/v7/arcade_cabinet/layout_guide.png"
let i=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:220,pixelsHigh:220,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
func rect(_ x:Int,_ y:Int,_ w:Int,_ h:Int,_ r:UInt8,_ g:UInt8,_ b:UInt8,_ a:UInt8) {
 let p=i.bitmapData!
 for yy in y..<(y+h) {for xx in x..<(x+w) {let j=yy*i.bytesPerRow+xx*4;p[j]=r;p[j+1]=g;p[j+2]=b;p[j+3]=a}}
}
rect(0,0,220,220,24,24,30,255)
rect(42,5,136,40,232,206,111,255)      // marquee
rect(62,51,96,88,75,133,223,255)       // clear screen >=80x80
rect(82,140,56,23,178,106,199,255)     // separate offering table
rect(4,101,44,42,76,165,102,255)       // left ornament clearance
rect(172,101,44,42,76,165,102,255)     // right ornament clearance
rect(4,143,44,7,109,220,123,255)       // left tray >=40
rect(172,143,44,7,109,220,123,255)     // right tray >=40
rect(70,164,80,15,241,150,74,255)     // controls
rect(78,180,64,31,217,94,85,255)      // coin and grille lower body
try! i.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:out))
print(out)
