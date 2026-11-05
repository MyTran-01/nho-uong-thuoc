import SwiftUI

// Fictional sample data for the token lab. Not real prescriptions.

struct SampleMed: Identifiable {
    let id: String
    let name: String
    let dose: String
    let how: String
    let pill: Color
}

enum LabSamples {
    static let morningMeds: [SampleMed] = [
        SampleMed(id: "a", name: "Thuốc da liễu B", dose: "2 viên", how: "Uống với nhiều nước", pill: Color(red: 0.96, green: 0.62, blue: 0.04)),
        SampleMed(id: "b", name: "Vitamin C", dose: "1 viên", how: "Nhai hoặc nuốt", pill: Color(red: 0.98, green: 0.45, blue: 0.09)),
        SampleMed(id: "c", name: "Kẽm", dose: "Nửa viên", how: "Uống sau khi ăn no", pill: Color(red: 0.38, green: 0.65, blue: 0.98)),
    ]
}

/// Placeholder for a blister photo (front: pills, back: printed foil).
struct BlisterPlaceholder: View {
    enum Side { case front, back }
    let side: Side
    let pill: Color

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(side == .front ? Color(white: 0.9) : Color(white: 0.82)))
            switch side {
            case .front:
                for row in 0..<3 {
                    for col in 0..<2 {
                        let rect = CGRect(x: w * (0.18 + Double(col) * 0.38), y: h * (0.12 + Double(row) * 0.28),
                                          width: w * 0.26, height: h * 0.19)
                        context.fill(Path(ellipseIn: rect), with: .color(pill))
                        context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.15)), lineWidth: 1)
                    }
                }
            case .back:
                for i in 0..<4 {
                    let rect = CGRect(x: w * 0.14, y: h * (0.2 + Double(i) * 0.17),
                                      width: w * (i.isMultiple(of: 2) ? 0.72 : 0.5), height: h * 0.06)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(Color(white: 0.6)))
                }
            }
        }
        .accessibilityLabel(side == .front ? "Ảnh mặt trước vỉ" : "Ảnh mặt sau vỉ")
    }
}
