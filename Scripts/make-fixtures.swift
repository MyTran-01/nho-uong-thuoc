// Generates FICTIONAL prescription and blister images for simulator testing.
// Usage: swift Scripts/make-fixtures.swift Fixtures/Images
// No real prescriptions, people or clinics.
import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func save(_ size: NSSize, _ name: String, draw: (CGContext) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    // Flip so y grows downward.
    ctx.cgContext.translateBy(x: 0, y: size.height)
    ctx.cgContext.scaleBy(x: 1, y: -1)
    draw(ctx.cgContext)
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: outDir).appendingPathComponent(name))
    print("wrote", name)
}

func text(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, bold: Bool = false, color: NSColor = .black) {
    let font = bold ? NSFont(name: "Arial Bold", size: size)! : NSFont(name: "Arial", size: size)!
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let str = NSAttributedString(string: s, attributes: attrs)
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    // Undo the flip locally so glyphs are upright.
    ctx.translateBy(x: x, y: y + size)
    ctx.scaleBy(x: 1, y: -1)
    str.draw(at: .zero)
    ctx.restoreGState()
    NSGraphicsContext.restoreGraphicsState()
}

struct RxLine { let name: String; let qty: String; let how: String }

func prescription(_ file: String, clinic: String, items: [RxLine]) {
    let size = NSSize(width: 1240, height: 1754)
    save(size, file) { ctx in
        ctx.setFillColor(NSColor(white: 0.985, alpha: 1).cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        text(clinic, 90, 80, size: 40, bold: true)
        text("Địa chỉ: 123 Đường Mẫu, Quận Mẫu (dữ liệu hư cấu)", 90, 140, size: 26)
        text("ĐƠN THUỐC", 480, 240, size: 52, bold: true)
        text("Họ tên: Nguyễn Văn Mẫu", 90, 340, size: 30)
        text("Tuổi: 62", 820, 340, size: 30)
        text("Chẩn đoán: dữ liệu mẫu để thử ứng dụng", 90, 395, size: 30)
        var y: CGFloat = 500
        for (i, item) in items.enumerated() {
            text("\(i + 1). \(item.name)", 90, y, size: 32, bold: true)
            text(item.qty, 960, y, size: 32)
            text(item.how, 140, y + 52, size: 30)
            y += 150
        }
        text("Ngày 05 tháng 11 năm 2026", 700, y + 60, size: 28)
        text("Bác sĩ khám bệnh", 760, y + 110, size: 28, bold: true)
        text("BS. Trần Thị Mẫu", 760, y + 230, size: 28)
    }
}

prescription("don-da-lieu.png", clinic: "PHÒNG KHÁM DA LIỄU MẪU", items: [
    RxLine(name: "Thuốc Da Liễu A 10mg", qty: "30 viên", how: "Uống trước ăn sáng, mỗi lần 1 viên"),
    RxLine(name: "Thuốc Da Liễu B 250mg", qty: "60 viên", how: "Ngày 2 lần, sáng - tối sau ăn, mỗi lần 2 viên"),
    RxLine(name: "Thuốc Da Liễu C 5mg", qty: "30 viên", how: "Uống buổi chiều, mỗi lần 1 viên"),
    RxLine(name: "Thuốc Da Liễu D 2mg", qty: "15 viên", how: "Uống trước khi ngủ 1 tiếng, mỗi lần 1/2 viên"),
])

prescription("don-thuoc-bo.png", clinic: "NHÀ THUỐC MẪU", items: [
    RxLine(name: "Vitamin C 500mg", qty: "30 viên", how: "Uống sau ăn sáng, mỗi lần 1 viên"),
    RxLine(name: "Kẽm 15mg", qty: "15 viên", how: "Cách ngày, uống sau ăn sáng, mỗi lần 1 viên"),
    RxLine(name: "Omega-3 1000mg", qty: "30 viên", how: "Uống sau ăn tối, mỗi lần 1 viên"),
])

struct Blister { let file: String; let label: String; let pill: NSColor; let foil: NSColor; let round: Bool }

let blisters = [
    Blister(file: "vi-a", label: "DA LIỄU A", pill: .systemPink, foil: NSColor(white: 0.85, alpha: 1), round: true),
    Blister(file: "vi-b", label: "DA LIỄU B", pill: .systemYellow, foil: NSColor(calibratedRed: 0.75, green: 0.85, blue: 0.95, alpha: 1), round: false),
    Blister(file: "vi-c", label: "DA LIỄU C", pill: .white, foil: NSColor(calibratedRed: 0.95, green: 0.8, blue: 0.75, alpha: 1), round: true),
    Blister(file: "vi-d", label: "DA LIỄU D", pill: .systemPurple, foil: NSColor(white: 0.8, alpha: 1), round: true),
    Blister(file: "vi-vitc", label: "VITAMIN C", pill: .systemOrange, foil: NSColor(calibratedRed: 1, green: 0.9, blue: 0.7, alpha: 1), round: true),
    Blister(file: "vi-kem", label: "KẼM", pill: .systemTeal, foil: NSColor(white: 0.88, alpha: 1), round: false),
    Blister(file: "vi-omega", label: "OMEGA-3", pill: NSColor(calibratedRed: 0.95, green: 0.75, blue: 0.2, alpha: 1), foil: NSColor(calibratedRed: 0.8, green: 0.9, blue: 0.8, alpha: 1), round: false),
]

for b in blisters {
    let size = NSSize(width: 900, height: 900)
    save(size, "\(b.file)-truoc.png") { ctx in
        ctx.setFillColor(NSColor(white: 0.35, alpha: 1).cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        ctx.setFillColor(b.foil.cgColor)
        ctx.fill(CGRect(x: 120, y: 80, width: 660, height: 740))
        for row in 0..<4 {
            for col in 0..<2 {
                let r = CGRect(x: 200 + CGFloat(col) * 280, y: 130 + CGFloat(row) * 170, width: b.round ? 160 : 220, height: b.round ? 130 : 110)
                ctx.setFillColor(NSColor(white: 1, alpha: 0.5).cgColor)
                ctx.fillEllipse(in: r.insetBy(dx: -14, dy: -14))
                ctx.setFillColor(b.pill.cgColor)
                ctx.fillEllipse(in: r)
            }
        }
    }
    save(size, "\(b.file)-sau.png") { ctx in
        ctx.setFillColor(NSColor(white: 0.3, alpha: 1).cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        ctx.setFillColor(NSColor(white: 0.82, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 120, y: 80, width: 660, height: 740))
        for row in 0..<4 {
            text(b.label, 170, 140 + CGFloat(row) * 170, size: 54, bold: true, color: NSColor(calibratedRed: 0.1, green: 0.25, blue: 0.55, alpha: 1))
            text("Dữ liệu mẫu", 190, 205 + CGFloat(row) * 170, size: 30, color: .darkGray)
        }
    }
}
