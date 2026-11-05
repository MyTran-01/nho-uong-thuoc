import SwiftUI

/// Token review screen (gate G0): real SwiftUI components in app context,
/// palette, live contrast and type scale. Sample data is fictional.
struct TokenLabView: View {
    @Environment(ThemeSettings.self) private var settings
    @Environment(\.theme) private var theme
    @State private var showControls = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("Màn thử giao diện, chưa phải app thật. Bấm “Tuỳ chỉnh” để đổi màu và cỡ chữ.")
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)

                    CheckInSample()
                    section("Thẻ giờ uống kế tiếp") { NextDoseSample() }
                    section("Chọn bằng nút, không cần gõ") { OffsetSample() }
                    section("Trạng thái trong lịch sử") { StatusSample() }
                    section("Đơn thuốc") { PrescriptionSample() }
                    section("Bảng màu") { PaletteSample() }
                    section("Độ tương phản") { ContrastSample() }
                    section("Cỡ chữ") { TypeScaleSample() }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(theme.background.color.ignoresSafeArea())
            .navigationTitle("Bộ giao diện v0.1")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Tuỳ chỉnh") { showControls = true }
                }
            }
            .sheet(isPresented: $showControls) {
                ThemeControlsView(settings: settings)
                    .environment(\.theme, settings.theme)
                    .presentationDetents([.medium, .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .appFont(.label)
                .tracking(0.6)
                .foregroundStyle(theme.muted.color)
            content()
        }
    }
}

// MARK: Samples

private struct CheckInSample: View {
    @Environment(\.theme) private var theme
    @State private var taken: [String: Bool] = ["a": true, "b": true, "c": true]

    private var missing: Int { taken.values.filter { !$0 }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("7:15 · Sáng, sau khi ăn")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
                Text("Tới giờ uống thuốc rồi")
                    .appFont(.title)
                    .foregroundStyle(theme.foreground.color)
                Text("Bỏ dấu tích ở thuốc nào chưa uống.")
                    .appFont(.body)
                    .foregroundStyle(theme.muted.color)
            }

            HCard(padding: 16) {
                VStack(spacing: 0) {
                    ForEach(Array(LabSamples.morningMeds.enumerated()), id: \.element.id) { index, med in
                        if index > 0 { Divider().overlay(theme.separator.color) }
                        MedRow(med: med, isOn: binding(for: med.id))
                    }
                }
            }

            VStack(spacing: 8) {
                Button(missing == 0 ? "Đã uống" : "Đã uống (còn \(missing) thuốc chưa uống)") {}
                    .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                Button("Hôm nay bỏ cữ này") {}
                    .buttonStyle(HButtonStyle(variant: .tertiary, fullWidth: true))
            }
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(get: { taken[id] ?? true }, set: { taken[id] = $0 })
    }
}

private struct MedRow: View {
    let med: SampleMed
    @Binding var isOn: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                photo(.front)
                photo(.back)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(med.name)
                    .appFont(.headline)
                    .foregroundStyle(theme.foreground.color)
                Text("\(med.dose) · \(med.how)")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HCheckbox(isOn: $isOn, label: "Đã uống \(med.name)")
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
    }

    private func photo(_ side: BlisterPlaceholder.Side) -> some View {
        BlisterPlaceholder(side: side, pill: med.pill)
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(theme.border.color, lineWidth: 1))
    }
}

private struct NextDoseSample: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("19:15")
                        .appFont(.display)
                        .foregroundStyle(theme.foreground.color)
                    Text("Tối, sau khi ăn")
                        .appFont(.headline)
                        .foregroundStyle(theme.foreground.color)
                    Text("2 loại thuốc")
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                }
                Spacer()
                HChip(text: "Sắp tới", color: .accent, variant: .soft)
            }
            Button("Xem thuốc cần uống") {}
                .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true, minHeight: theme.buttonHeight))
        }
    }
}

private struct OffsetSample: View {
    @Environment(\.theme) private var theme
    @State private var minutes = 30

    var body: some View {
        HCard {
            Text("Trước khi ăn sáng bao lâu?")
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
            HOptionGroup(options: [15, 30, 45, 60].map { ($0, "\($0) phút") }, selection: $minutes)
            Text("Đơn không ghi thì để 30 phút.")
                .appFont(.secondary)
                .foregroundStyle(theme.muted.color)
        }
    }
}

private struct StatusSample: View {
    var body: some View {
        HCard {
            FlowLayout(spacing: 8, lineSpacing: 8) {
                HChip(text: "✓ Đã uống đủ", color: .success)
                HChip(text: "◐ Còn 1 thuốc chưa uống", color: .warning)
                HChip(text: "– Đã bỏ cữ", color: .neutral)
                HChip(text: "! Chưa đánh dấu", color: .danger)
            }
        }
    }
}

private struct PrescriptionSample: View {
    @Environment(\.theme) private var theme
    @State private var name = "Vitamin C"

    var body: some View {
        HCard {
            VStack(alignment: .leading, spacing: 2) {
                Text("Đơn Da liễu")
                    .appFont(.headline)
                    .foregroundStyle(theme.foreground.color)
                Text("4 loại thuốc · đã đủ 30 ngày")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
            }
            HTextField(label: "Tên thuốc", text: $name)
            HStack {
                Text("Kẽm")
                    .appFont(.body)
                    .foregroundStyle(theme.foreground.color)
                Spacer()
                Button("Đã hết") {}
                    .buttonStyle(HButtonStyle(variant: .outline))
            }
            Button("Đã uống hết đơn này") {}
                .buttonStyle(HButtonStyle(variant: .danger, fullWidth: true))
        }
    }
}

private struct PaletteSample: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    private var swatches: [(String, Tok)] {
        [("Chủ đạo", theme.accent), ("Nền trang", theme.background), ("Nền thẻ", theme.surface),
         ("Chữ chính", theme.foreground), ("Chữ phụ", theme.muted), ("Nền xám", theme.defaultFill),
         ("Đã uống đủ", theme.success), ("Còn thiếu", theme.warning), ("Lỗi / hết", theme.danger),
         ("Viền ô nhập", theme.fieldBorder), ("Viền", theme.border), ("Đường kẻ", theme.separator)]
    }

    var body: some View {
        HCard {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], alignment: .leading, spacing: 14) {
                ForEach(swatches, id: \.0) { name, tok in
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tok.color)
                            .frame(height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(theme.border.color, lineWidth: 1))
                        Text(name)
                            .appFont(.label)
                            .foregroundStyle(theme.foreground.color)
                        Text(String(format: "#%06x", tok.hex(scheme)))
                            .appFont(.label)
                            .monospaced()
                            .foregroundStyle(theme.muted.color)
                    }
                }
            }
        }
    }
}

private struct ContrastSample: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    private struct Pair: Identifiable {
        let name: String
        let fg: Tok
        let bg: Tok
        let isText: Bool
        var id: String { name }
    }

    private var pairs: [Pair] {
        [
            Pair(name: "Chữ chính / nền thẻ", fg: theme.foreground, bg: theme.surface, isText: true),
            Pair(name: "Chữ phụ / nền thẻ", fg: theme.muted, bg: theme.surface, isText: true),
            Pair(name: "Chữ phụ / nền trang", fg: theme.muted, bg: theme.background, isText: true),
            Pair(name: "Chữ trên nút chính", fg: theme.accentForeground, bg: theme.accent, isText: true),
            Pair(name: "Chữ trên nút xám", fg: theme.defaultForeground, bg: theme.defaultFill, isText: true),
            Pair(name: "Chip “Sắp tới”", fg: theme.accent, bg: theme.accentSoft, isText: true),
            Pair(name: "Chip “Đã uống đủ”", fg: theme.successForeground, bg: theme.success, isText: true),
            Pair(name: "Chip “Còn thiếu”", fg: theme.warningForeground, bg: theme.warning, isText: true),
            Pair(name: "Nút “Đã uống hết đơn”", fg: theme.dangerForeground, bg: theme.danger, isText: true),
            Pair(name: "Viền ô nhập / nền thẻ", fg: theme.fieldBorder, bg: theme.surface, isText: false),
            Pair(name: "Ô tích, nút chọn chưa chọn", fg: theme.fieldBorder, bg: theme.surface, isText: false),
            Pair(name: "Nút chính / nền trang", fg: theme.accent, bg: theme.background, isText: false),
        ]
    }

    var body: some View {
        HCard {
            VStack(spacing: 0) {
                ForEach(Array(pairs.enumerated()), id: \.element.id) { index, pair in
                    if index > 0 { Divider().overlay(theme.separator.color) }
                    row(pair)
                }
            }
            Text("Chữ cần ≥ 4.5 (AA), tốt nhất ≥ 7 (AAA). Viền, nút cần ≥ 3.")
                .appFont(.secondary)
                .foregroundStyle(theme.muted.color)
        }
    }

    private func row(_ pair: Pair) -> some View {
        let ratio = Contrast.ratio(pair.fg.hex(scheme), pair.bg.hex(scheme))
        let (label, color): (String, HChipColor) = {
            if pair.isText {
                if ratio >= 7 { return ("AAA", .success) }
                if ratio >= 4.5 { return ("AA", .success) }
                return ("Trượt", .danger)
            }
            return ratio >= 3 ? ("Đạt", .success) : ("Trượt", .danger)
        }()
        return HStack(spacing: 8) {
            Text(pair.name)
                .appFont(.secondary)
                .foregroundStyle(theme.foreground.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.1f", ratio))
                .appFont(.secondary)
                .monospacedDigit()
                .foregroundStyle(theme.foreground.color)
            HChip(text: label, color: color)
        }
        .padding(.vertical, 8)
    }
}

private struct TypeScaleSample: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HCard {
            ForEach(TextRole.allCases, id: \.self) { role in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sáng, sau khi ăn")
                        .appFont(role)
                        .foregroundStyle(theme.foreground.color)
                    Text("\(role.name) · \(Int((role.size * theme.baseSize / 19).rounded()))pt")
                        .appFont(.label)
                        .foregroundStyle(theme.muted.color)
                }
            }
        }
    }
}
