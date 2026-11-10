// 生成「打工人的秒表」应用图标（1024x1024 PNG）
// 用法: swift draw_icon.swift <输出路径>
import AppKit

let size: CGFloat = 1024
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"

let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no ctx") }
ctx.setShouldAntialias(true)

let orange = NSColor(srgbRed: 1.0, green: 0.42, blue: 0.16, alpha: 1)
let orangeDeep = NSColor(srgbRed: 0.93, green: 0.30, blue: 0.08, alpha: 1)

// 1. 圆角方形底 + 渐变
let inset: CGFloat = 56
let bgRect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let bg = NSBezierPath(roundedRect: bgRect, xRadius: 228, yRadius: 228)
let grad = NSGradient(colors: [
    NSColor(srgbRed: 1.00, green: 0.78, blue: 0.31, alpha: 1),
    NSColor(srgbRed: 1.00, green: 0.52, blue: 0.16, alpha: 1),
    NSColor(srgbRed: 0.96, green: 0.36, blue: 0.10, alpha: 1),
], atLocations: [0.0, 0.55, 1.0], colorSpace: .sRGB)!
grad.draw(in: bg, angle: -72)

// 2. 顶部柔光（径向渐变，边缘自然消隐）
ctx.saveGState()
bg.addClip()
let gloss = NSBezierPath(ovalIn: NSRect(x: -size * 0.05, y: size * 0.30, width: size * 1.1, height: size * 1.05))
let glossGrad = NSGradient(colors: [
    NSColor(white: 1.0, alpha: 0.30),
    NSColor(white: 1.0, alpha: 0.10),
    NSColor(white: 1.0, alpha: 0.0),
], atLocations: [0.0, 0.55, 1.0], colorSpace: .sRGB)!
glossGrad.draw(in: gloss, relativeCenterPosition: NSPoint(x: 0, y: -0.15))
ctx.restoreGState()

// 3. 秒表
let cx: CGFloat = size / 2
let cy: CGFloat = size / 2 - 26
let faceR: CGFloat = 250

// 表冠（顶部按钮）
let crown = NSBezierPath(roundedRect: NSRect(x: cx - 52, y: cy + faceR + 6, width: 104, height: 58), xRadius: 20, yRadius: 20)
NSColor(white: 1.0, alpha: 0.98).setFill()
crown.fill()
// 表冠竖杆
let stem = NSBezierPath(roundedRect: NSRect(x: cx - 26, y: cy + faceR - 6, width: 52, height: 30), xRadius: 8, yRadius: 8)
NSColor(white: 1.0, alpha: 0.98).setFill()
stem.fill()

// 外圈
let ring = NSBezierPath(ovalIn: NSRect(x: cx - faceR, y: cy - faceR, width: faceR * 2, height: faceR * 2))
NSColor(white: 1.0, alpha: 1.0).setFill()
ring.fill()

// 内盘（微暖白）
let innerR = faceR - 40
let face = NSBezierPath(ovalIn: NSRect(x: cx - innerR, y: cy - innerR, width: innerR * 2, height: innerR * 2))
NSColor(srgbRed: 1.0, green: 0.975, blue: 0.955, alpha: 1).setFill()
face.fill()

// 刻度
for i in 0..<12 {
    let a = CGFloat(i) * .pi / 6
    let isMajor = i % 3 == 0
    let outer = innerR - 22
    let inner = outer - (isMajor ? 42 : 26)
    let w: CGFloat = isMajor ? 17 : 11
    let p = NSBezierPath()
    p.lineWidth = w
    p.lineCapStyle = .round
    p.move(to: NSPoint(x: cx + cos(a) * inner, y: cy + sin(a) * inner))
    p.line(to: NSPoint(x: cx + cos(a) * outer, y: cy + sin(a) * outer))
    orange.withAlphaComponent(isMajor ? 0.95 : 0.45).setStroke()
    p.stroke()
}

// 指针（指向右上，10 点方向偏上）
let handAngle: CGFloat = .pi / 3.4
let handLen = innerR - 62
let hand = NSBezierPath()
hand.lineWidth = 26
hand.lineCapStyle = .round
hand.move(to: NSPoint(x: cx, y: cy))
hand.line(to: NSPoint(x: cx + cos(handAngle) * handLen, y: cy + sin(handAngle) * handLen))
orangeDeep.setStroke()
hand.stroke()

// 中心轴
let hub = NSBezierPath(ovalIn: NSRect(x: cx - 26, y: cy - 26, width: 52, height: 52))
orangeDeep.setFill()
hub.fill()
let hubIn = NSBezierPath(ovalIn: NSRect(x: cx - 11, y: cy - 11, width: 22, height: 22))
NSColor(white: 1.0, alpha: 1.0).setFill()
hubIn.fill()

img.unlockFocus()

// 输出 PNG
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { fatalError("encode fail") }
try! png.write(to: URL(fileURLWithPath: outPath))
print("icon written: \(outPath) \(rep.pixelsWide)x\(rep.pixelsHigh)")
