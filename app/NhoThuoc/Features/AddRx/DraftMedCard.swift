import SwiftUI

/// One medication on S7 / S5. Everything except the name is chosen by tapping (M12).
/// Order: name → times of day → details of each chosen time (shown only when chosen)
/// → amount per dose → schedule.
struct DraftMedCard: View {
    @Binding var draft: DraftMed
    let routine: RoutineTimes
    var startExpanded = false
    var onDelete: (() -> Void)?
    @State private var expanded = false
    @Environment(\.theme) private var theme

    private static let times: [(Anchor, String)] = [
        (.breakfast, "Sáng"), (.lunch, "Trưa"), (.afternoon, "Chiều"), (.dinner, "Tối"), (.bed, "Khi ngủ"),
    ]

    var body: some View {
        HCard {
            if !draft.nameOnRx.isEmpty {
                Text("Trong đơn: \(draft.nameOnRx)")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
            }
            HTextField(label: "Tên loại thuốc", text: $draft.displayName)

            Text(summary)
                .appFont(.body)
                .foregroundStyle(theme.foreground.color)
                .fixedSize(horizontal: false, vertical: true)

            if expanded {
                editor
            }

            HStack {
                Button(expanded ? "Xong" : "Đổi liều, giờ uống") {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                }
                .buttonStyle(HButtonStyle(variant: expanded ? .primary : .secondary))
                Spacer()
                if let onDelete {
                    Button("Bỏ thuốc này", action: onDelete)
                        .appFont(.secondary)
                        .foregroundStyle(theme.danger.color)
                        .frame(minHeight: theme.touchMin)
                }
            }
        }
        .onAppear { if startExpanded { expanded = true } }
    }

    private var summary: String {
        let times = sortedTimings
            .map { "\(Clock.text(SlotEngine.minute(of: $0, routine: routine))) \(SlotEngine.title(anchor: $0.anchor, relation: $0.relation).lowercased())" }
        let schedule = ["mỗi ngày", "cách 1 ngày", "cách 2 ngày"][min(draft.everyNDays, 2)]
        let when = times.isEmpty ? "chưa chọn giờ uống" : times.joined(separator: "; ")
        return "\(Dose.text(halves: draft.doseHalves, unit: draft.unit)) · \(when) · \(schedule)"
    }

    private var sortedTimings: [Timing] {
        draft.timings.sorted { SlotEngine.minute(of: $0, routine: routine) < SlotEngine.minute(of: $1, routine: routine) }
    }

    // MARK: Editor

    private var editor: some View {
        VStack(alignment: .leading, spacing: 20) {
            group("Thời gian uống") {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(Self.times, id: \.0) { anchor, label in
                        chip(label, on: timing(anchor) != nil) { toggleTime(anchor) }
                    }
                }
                if draft.timings.isEmpty {
                    Text("Chọn ít nhất một buổi.")
                        .appFont(.secondary)
                        .foregroundStyle(theme.danger.color)
                }
                // Details appear only for the chosen times, in the order of the day.
                ForEach(Self.times.filter { timing($0.0) != nil }, id: \.0) { anchor, label in
                    detail(anchor, label)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            group("Mỗi lần uống") {
                amountStepper
                rowLabel("Loại")
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(DoseUnit.allCases, id: \.self) { u in
                        chip(u.label, on: draft.unit == u) { setUnit(u) }
                    }
                }
            }

            group("Lịch uống") {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    chip("Mỗi ngày", on: draft.everyNDays == 0) { draft.everyNDays = 0 }
                    chip("Cách 1 ngày", on: draft.everyNDays == 1) { draft.everyNDays = 1 }
                    chip("Cách 2 ngày", on: draft.everyNDays == 2) { draft.everyNDays = 2 }
                }
            }
        }
        .padding(.top, 4)
        .animation(.easeInOut(duration: 0.2), value: draft.timings)
    }

    // MARK: Time detail

    @ViewBuilder
    private func detail(_ anchor: Anchor, _ label: String) -> some View {
        if let t = timing(anchor) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(anchor == .bed ? "Khi ngủ" : "Buổi \(label.lowercased())")
                        .appFont(.headline)
                        .foregroundStyle(theme.foreground.color)
                    Spacer()
                    Text("Uống lúc \(Clock.text(SlotEngine.minute(of: t, routine: routine)))")
                        .appFont(.secondary)
                        .monospacedDigit()
                        .foregroundStyle(theme.accentSoftForeground.color)
                }
                switch anchor {
                case .afternoon:
                    Text("Giờ buổi chiều đổi được trong Cài đặt.")
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                case .bed:
                    rowLabel("Trước khi ngủ bao lâu?")
                    offsetChips(anchor, t, options: [15, 30, 60, 120], fallback: routine.beforeBed)
                default:
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        chip("Trước ăn", on: t.relation == .before) { setRelation(anchor, .before) }
                        chip("Trong bữa", on: t.relation == .during) { setRelation(anchor, .during) }
                        chip("Sau ăn", on: t.relation == .after) { setRelation(anchor, .after) }
                    }
                    if t.relation == .before {
                        rowLabel("Trước ăn bao lâu?")
                        offsetChips(anchor, t, options: [15, 30, 45, 60], fallback: routine.beforeMeal)
                    } else if t.relation == .after {
                        rowLabel("Sau ăn bao lâu?")
                        offsetChips(anchor, t, options: [0, 15, 30, 60], fallback: routine.afterMeal)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.background.color))
        }
    }

    private func offsetChips(_ anchor: Anchor, _ t: Timing, options: [Int], fallback: Int) -> some View {
        let current = t.offsetMinutes ?? fallback
        return FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(options, id: \.self) { m in
                chip(offsetLabel(m), on: current == m) { setOffset(anchor, m) }
            }
        }
    }

    private func offsetLabel(_ m: Int) -> String {
        if m == 0 { return "Ngay sau" }
        if m >= 60, m % 60 == 0 { return "\(m / 60) tiếng" }
        return "\(m) phút"
    }

    // MARK: Amount

    private var amountStepper: some View {
        let step = draft.unit.stepHalves
        return HStack(spacing: 10) {
            Button("− Bớt") { draft.doseHalves = max(step, draft.doseHalves - step) }
                .buttonStyle(HButtonStyle(variant: .outline, compact: true))
                .disabled(draft.doseHalves <= step)
                .accessibilityLabel("Bớt")
            Text(Dose.text(halves: draft.doseHalves, unit: draft.unit))
                .appFont(.headline)
                .monospacedDigit()
                .foregroundStyle(theme.foreground.color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.updatesFrequently)
            Button("+ Thêm") { draft.doseHalves = min(step * 40, draft.doseHalves + step) }
                .buttonStyle(HButtonStyle(variant: .outline, compact: true))
                .accessibilityLabel("Thêm")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mỗi lần uống")
    }

    private func setUnit(_ u: DoseUnit) {
        guard u != draft.unit else { return }
        let wasCount = draft.unit == .vien || draft.unit == .goi
        let isCount = u == .vien || u == .goi
        draft.unit = u
        // Keep the amount between viên and gói, start fresh for other kinds.
        draft.doseHalves = wasCount && isCount ? Dose.snapped(draft.doseHalves, unit: u) : u.defaultHalves
    }

    // MARK: Timing helpers

    private func timing(_ anchor: Anchor) -> Timing? {
        draft.timings.first { $0.anchor == anchor }
    }

    private func toggleTime(_ anchor: Anchor) {
        if timing(anchor) != nil {
            draft.timings.removeAll { $0.anchor == anchor }
        } else {
            let relation: Relation = switch anchor {
            case .afternoon: .at
            case .bed: .before
            default: .after
            }
            draft.timings.append(Timing(anchor: anchor, relation: relation))
        }
    }

    private func setRelation(_ anchor: Anchor, _ relation: Relation) {
        guard let i = draft.timings.firstIndex(where: { $0.anchor == anchor }), draft.timings[i].relation != relation else { return }
        draft.timings[i] = Timing(anchor: anchor, relation: relation)
    }

    private func setOffset(_ anchor: Anchor, _ minutes: Int) {
        guard let i = draft.timings.firstIndex(where: { $0.anchor == anchor }) else { return }
        draft.timings[i].offsetMinutes = minutes
        draft.timings[i].offsetSource = .user
    }

    // MARK: Layout

    private func chip(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(HButtonStyle(variant: on ? .primary : .outline, compact: true))
            .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text)
            .appFont(.secondary)
            .foregroundStyle(theme.muted.color)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
            content()
        }
    }
}
