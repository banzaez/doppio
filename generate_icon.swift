import Cocoa
import CoreGraphics

func createDoppioIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = size / 1024.0

    // Canvas 1024x1024 coords
    // Squircle macOS standard: bounds ~ (100, 100, 824, 824), corner radius ~ 185
    let bodyRect = CGRect(x: 100 * scale, y: 100 * scale, width: 824 * scale, height: 824 * scale)
    let cornerRadius: CGFloat = 185 * scale

    // 1. Drop shadow
    ctx.saveGState()
    let shadowColor = NSColor.black.withAlphaComponent(0.35).cgColor
    ctx.setShadow(offset: CGSize(width: 0, height: -18 * scale), blur: 30 * scale, color: shadowColor)

    let squirclePath = CGPath(roundedRect: bodyRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor(red: 0.15, green: 0.08, blue: 0.04, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // 2. Base Squircle Gradient (Rich Espresso & Amber)
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor(red: 0.98, green: 0.55, blue: 0.18, alpha: 1.0).cgColor, // Warm amber top
        NSColor(red: 0.78, green: 0.32, blue: 0.08, alpha: 1.0).cgColor, // Espresso orange middle
        NSColor(red: 0.28, green: 0.12, blue: 0.05, alpha: 1.0).cgColor, // Deep coffee
        NSColor(red: 0.12, green: 0.05, blue: 0.02, alpha: 1.0).cgColor  // Obsidian bottom
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.45, 0.85, 1.0]

    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 512 * scale, y: 924 * scale),
            end: CGPoint(x: 512 * scale, y: 100 * scale),
            options: []
        )
    }

    // 3. Inner radial glow (Sun/warmth from upper-center)
    let radialColors = [
        NSColor.white.withAlphaComponent(0.25).cgColor,
        NSColor.clear.cgColor
    ] as CFArray
    if let radialGradient = CGGradient(colorsSpace: colorSpace, colors: radialColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            radialGradient,
            startCenter: CGPoint(x: 512 * scale, y: 700 * scale),
            startRadius: 0,
            endCenter: CGPoint(x: 512 * scale, y: 700 * scale),
            endRadius: 400 * scale,
            options: []
        )
    }

    // 4. Subtle inner border / rim light
    ctx.addPath(squirclePath)
    ctx.setLineWidth(2.5 * scale)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.22).cgColor)
    ctx.strokePath()

    // 5. Draw Steaming Coffee Cup Icon & Energy Aura
    // Saucer
    let saucerRect = CGRect(x: 270 * scale, y: 260 * scale, width: 484 * scale, height: 75 * scale)
    let saucerPath = CGPath(ellipseIn: saucerRect, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 15 * scale, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    ctx.addPath(saucerPath)
    ctx.setFillColor(NSColor(white: 0.96, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Saucer rim
    ctx.addPath(saucerPath)
    ctx.setLineWidth(3 * scale)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.6).cgColor)
    ctx.strokePath()

    // Cup Body
    let cupPath = CGMutablePath()
    let cupTop = 520.0 * scale
    let cupBottom = 300.0 * scale
    let cupLeft = 320.0 * scale
    let cupRight = 660.0 * scale

    cupPath.move(to: CGPoint(x: cupLeft, y: cupTop))
    cupPath.addCurve(
        to: CGPoint(x: 360 * scale, y: cupBottom),
        control1: CGPoint(x: cupLeft, y: 390 * scale),
        control2: CGPoint(x: 340 * scale, y: cupBottom)
    )
    cupPath.addLine(to: CGPoint(x: 620 * scale, y: cupBottom))
    cupPath.addCurve(
        to: CGPoint(x: cupRight, y: cupTop),
        control1: CGPoint(x: 640 * scale, y: cupBottom),
        control2: CGPoint(x: cupRight, y: 390 * scale)
    )
    cupPath.closeSubpath()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * scale), blur: 20 * scale, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(cupPath)
    ctx.setFillColor(NSColor(white: 0.95, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Cup Handle
    let handlePath = CGMutablePath()
    handlePath.addArc(
        center: CGPoint(x: 660 * scale, y: 420 * scale),
        radius: 65 * scale,
        startAngle: -.pi / 2,
        endAngle: .pi / 2,
        clockwise: false
    )
    ctx.saveGState()
    ctx.addPath(handlePath)
    ctx.setLineWidth(24 * scale)
    ctx.setLineCap(.round)
    ctx.setStrokeColor(NSColor(white: 0.93, alpha: 1.0).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    // Coffee surface (Crema)
    let coffeeSurfaceRect = CGRect(x: 326 * scale, y: 485 * scale, width: 328 * scale, height: 60 * scale)
    let coffeePath = CGPath(ellipseIn: coffeeSurfaceRect, transform: nil)
    ctx.saveGState()
    ctx.addPath(coffeePath)
    ctx.clip()

    let cremaColors = [
        NSColor(red: 0.85, green: 0.52, blue: 0.22, alpha: 1.0).cgColor,
        NSColor(red: 0.42, green: 0.18, blue: 0.08, alpha: 1.0).cgColor
    ] as CFArray
    if let cremaGrad = CGGradient(colorsSpace: colorSpace, colors: cremaColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(cremaGrad, start: CGPoint(x: 490 * scale, y: 545 * scale), end: CGPoint(x: 490 * scale, y: 485 * scale), options: [])
    }
    ctx.restoreGState()

    // Rising Steam Waves (Curls)
    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setLineWidth(14 * scale)

    let steam1 = CGMutablePath()
    steam1.move(to: CGPoint(x: 420 * scale, y: 570 * scale))
    steam1.addCurve(
        to: CGPoint(x: 400 * scale, y: 720 * scale),
        control1: CGPoint(x: 390 * scale, y: 620 * scale),
        control2: CGPoint(x: 440 * scale, y: 670 * scale)
    )

    let steam2 = CGMutablePath()
    steam2.move(to: CGPoint(x: 490 * scale, y: 580 * scale))
    steam2.addCurve(
        to: CGPoint(x: 500 * scale, y: 750 * scale),
        control1: CGPoint(x: 530 * scale, y: 640 * scale),
        control2: CGPoint(x: 460 * scale, y: 690 * scale)
    )

    let steam3 = CGMutablePath()
    steam3.move(to: CGPoint(x: 560 * scale, y: 570 * scale))
    steam3.addCurve(
        to: CGPoint(x: 580 * scale, y: 720 * scale),
        control1: CGPoint(x: 600 * scale, y: 620 * scale),
        control2: CGPoint(x: 540 * scale, y: 670 * scale)
    )

    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.75).cgColor)
    ctx.addPath(steam1)
    ctx.strokePath()

    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
    ctx.addPath(steam2)
    ctx.strokePath()

    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.70).cgColor)
    ctx.addPath(steam3)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // pop squircle clip

    image.unlockFocus()
    return image
}

let fileManager = FileManager.default
let iconsetDir = "AppIcon.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(name: String, px: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for item in sizes {
    let img = createDoppioIcon(size: item.px)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let filePath = "\(iconsetDir)/\(item.name)"
        try? png.write(to: URL(fileURLWithPath: filePath))
        print("Generated: \(filePath)")
    }
}
print("Done generating iconset.")
