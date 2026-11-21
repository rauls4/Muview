// Draws the Muview app icon. Usage: swift Tools/make-icon.swift <out.png>
import AppKit

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// macOS icon grid: 824pt tile centred in the 1024 canvas.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: tile, xRadius: 186, yRadius: 186)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.32).cgColor)
NSColor.black.setFill()
shape.fill()
ctx.restoreGState()

ctx.saveGState()
shape.addClip()
let gradient = NSGradient(colors: [
    NSColor(srgbRed: 0.16, green: 0.20, blue: 0.42, alpha: 1),
    NSColor(srgbRed: 0.24, green: 0.36, blue: 0.86, alpha: 1),
    NSColor(srgbRed: 0.20, green: 0.74, blue: 0.84, alpha: 1),
])!
gradient.draw(in: tile, angle: 55)
// Soft highlight toward the top edge.
NSGradient(colors: [NSColor.white.withAlphaComponent(0.20), NSColor.white.withAlphaComponent(0)])!
    .draw(in: CGRect(x: tile.minX, y: tile.midY, width: tile.width, height: tile.height / 2), angle: -90)
ctx.restoreGState()

func rounded(_ pointSize: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: pointSize, weight: weight)
    if let d = base.fontDescriptor.withDesign(.rounded), let f = NSFont(descriptor: d, size: pointSize) { return f }
    return base
}
func draw(_ s: String, font: NSFont, color: NSColor, centerX: CGFloat, baseline: CGFloat) {
    let str = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color])
    let w = str.size().width
    str.draw(at: CGPoint(x: centerX - w / 2, y: baseline + font.descender))
}

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
shadow.shadowOffset = CGSize(width: 0, height: -8)
shadow.shadowBlurRadius = 18
shadow.set()

let bracket = rounded(400, .semibold)
let bracketColor = NSColor.white.withAlphaComponent(0.55)
draw("‹", font: bracket, color: bracketColor, centerX: 262, baseline: 398)
draw("›", font: bracket, color: bracketColor, centerX: 762, baseline: 398)
draw("μ", font: rounded(520, .bold), color: .white, centerX: 512, baseline: 400)

NSGraphicsContext.current!.flushGraphics()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
