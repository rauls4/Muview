// Draws the Muview icons.
// Usage: swift Tools/make-icon.swift app|document <out.png>
import AppKit

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func rounded(_ pointSize: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: pointSize, weight: weight)
    if let d = base.fontDescriptor.withDesign(.rounded), let f = NSFont(descriptor: d, size: pointSize) { return f }
    return base
}

func draw(_ s: String, font: NSFont, color: NSColor, centerX: CGFloat, baseline: CGFloat) {
    let str = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color])
    str.draw(at: CGPoint(x: centerX - str.size().width / 2, y: baseline + font.descender))
}

/// The blue ‹μ› tile, drawn in a 1024 canvas (macOS icon grid: 824pt tile, centred).
func drawTile() {
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 186, yRadius: 186)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28,
                  color: NSColor.black.withAlphaComponent(0.32).cgColor)
    NSColor.black.setFill()
    shape.fill()
    ctx.restoreGState()

    ctx.saveGState()
    shape.addClip()
    NSGradient(colors: [
        NSColor(srgbRed: 0.16, green: 0.20, blue: 0.42, alpha: 1),
        NSColor(srgbRed: 0.24, green: 0.36, blue: 0.86, alpha: 1),
        NSColor(srgbRed: 0.20, green: 0.74, blue: 0.84, alpha: 1),
    ])!.draw(in: tile, angle: 55)
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.20), NSColor.white.withAlphaComponent(0)])!
        .draw(in: CGRect(x: tile.minX, y: tile.midY, width: tile.width, height: tile.height / 2), angle: -90)
    ctx.restoreGState()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowOffset = CGSize(width: 0, height: -8)
    shadow.shadowBlurRadius = 18
    ctx.saveGState()
    shadow.set()
    let bracket = rounded(400, .semibold)
    let bracketColor = NSColor.white.withAlphaComponent(0.55)
    draw("‹", font: bracket, color: bracketColor, centerX: 262, baseline: 398)
    draw("›", font: bracket, color: bracketColor, centerX: 762, baseline: 398)
    draw("μ", font: rounded(520, .bold), color: .white, centerX: 512, baseline: 400)
    ctx.restoreGState()
}

/// A sheet of paper with a folded corner, a few text lines, and the tile as a badge.
func drawDocument() {
    let page = CGRect(x: 192, y: 72, width: 640, height: 880)
    let fold: CGFloat = 190
    let radius: CGFloat = 44

    let outline = NSBezierPath()
    outline.move(to: CGPoint(x: page.minX + radius, y: page.minY))
    outline.appendArc(withCenter: CGPoint(x: page.maxX - radius, y: page.minY + radius), radius: radius,
                      startAngle: 270, endAngle: 0)
    outline.line(to: CGPoint(x: page.maxX, y: page.maxY - fold))
    outline.line(to: CGPoint(x: page.maxX - fold, y: page.maxY))
    outline.appendArc(withCenter: CGPoint(x: page.minX + radius, y: page.maxY - radius), radius: radius,
                      startAngle: 90, endAngle: 180)
    outline.appendArc(withCenter: CGPoint(x: page.minX + radius, y: page.minY + radius), radius: radius,
                      startAngle: 180, endAngle: 270)
    outline.close()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 26,
                  color: NSColor.black.withAlphaComponent(0.30).cgColor)
    NSColor.white.setFill()
    outline.fill()
    ctx.restoreGState()

    ctx.saveGState()
    outline.addClip()
    NSGradient(colors: [NSColor(white: 0.93, alpha: 1), NSColor.white])!.draw(in: page, angle: 90)
    ctx.restoreGState()

    NSColor(white: 0, alpha: 0.10).setStroke()
    outline.lineWidth = 3
    outline.stroke()

    // Folded corner.
    let corner = NSBezierPath()
    corner.move(to: CGPoint(x: page.maxX - fold, y: page.maxY))
    corner.line(to: CGPoint(x: page.maxX - fold, y: page.maxY - fold + 30))
    corner.appendArc(withCenter: CGPoint(x: page.maxX - fold + 30, y: page.maxY - fold + 30), radius: 30,
                     startAngle: 180, endAngle: 270)
    corner.line(to: CGPoint(x: page.maxX, y: page.maxY - fold))
    corner.close()
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: -6, height: -8), blur: 16,
                  color: NSColor.black.withAlphaComponent(0.22).cgColor)
    NSColor(white: 0.86, alpha: 1).setFill()
    corner.fill()
    ctx.restoreGState()

    // Text lines hinting at a heading and a paragraph.
    func line(_ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: NSColor) {
        color.setFill()
        NSBezierPath(roundedRect: CGRect(x: page.minX + 84, y: y, width: width, height: height),
                     xRadius: height / 2, yRadius: height / 2).fill()
    }
    line(770, 250, 40, NSColor(srgbRed: 0.24, green: 0.36, blue: 0.86, alpha: 0.85))
    line(690, 330, 26, NSColor(white: 0, alpha: 0.16))
    line(634, 440, 26, NSColor(white: 0, alpha: 0.16))

    // The app tile as a badge on the lower part of the page.
    let badge: CGFloat = 520
    ctx.saveGState()
    ctx.translateBy(x: (size - badge) / 2, y: 78)
    ctx.scaleBy(x: badge / size, y: badge / size)
    drawTile()
    ctx.restoreGState()
}

let args = CommandLine.arguments
guard args.count == 3, ["app", "document"].contains(args[1]) else {
    FileHandle.standardError.write("usage: make-icon.swift app|document <out.png>\n".data(using: .utf8)!)
    exit(2)
}
if args[1] == "app" { drawTile() } else { drawDocument() }

NSGraphicsContext.current!.flushGraphics()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
