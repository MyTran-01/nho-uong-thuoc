import SwiftUI

/// One medication on S7 / S5. Everything except the name is chosen by tapping (M12).
struct DraftMedCard: View {
    @Binding var draft: DraftMed
    let routine: RoutineTimes
    var startExpanded = false
    var onDelete: (() -> Void)?
    @State private var expanded = false
    @Environment(\.theme) private var theme

    var body: some View {
        HCard {
            if !draft.nameOnRx.isEmpty {
                Text("Trong đơn: \(draft.nameOnRx)")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
            }
            HTextField(label: "Tên để dễ nhớ", text: $draft.displayName)

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
        let times = draft.timings
            .map { (SlotEngine.minute(of: $0, routine: routine), $0) }
            .sorted { $0.0 < $1.0 }
            .map { "\(Clock.text($0.0)) \(SlotEngine.title(anchor: $0.1.anchor, relation: $0.1.relation).lowercased())" }
        let schedule = ["mỗi ngày", "cách 1 ngày", "cách 2 ngày"][min(draft.everyNDays, 2)]
        let when = times.isEmpty ? "chưa chọn giờ uống" : times.joined(separator: "; ")
        return "\(Dose.text(halves: draft.doseHalves, unit: draft.unit)) · \(when) · \(schedule)"
    }

    // MARK: Editor

    private var editor: some View {
        VStack(alignment: .leading, spacing: 18) {
            group("Mỗi lần uống") {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach([1, 2, 4, 6], id: \.self) { h in
                        chip(h == 1 ? "Nửa" : "\(h / 2)", on: draft.doseHalves == h) { draft.doseHalves = h }
                    }
                }
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(DoseUnit.allCases, id: \.self) { u in
                        chip(u.label, on: draft.unit == u) { draft.unit = u }
                    }
                }
            }

            group("Uống lúc nào") {
                mealRow("Bữa sáng", .breakfast)
                mealRow("Bữa trưa", .lunch)
                mealRow("Bữa tối", .dinner)
                rowLabel("Khác")
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    chip("Buổi chiều", on: has(.afternoon)) { toggle(.afternoon, .at) }
                    chip("Trước khi ngủ", on: has(.bed)) { toggle(.bed, .before) }
                }
            }

            if draft.timings.contains(where: { $0.relation == .before && $0.anchor != .bed }) {
                offsetGroup("Trước ăn bao lâu?", relation: .before, isBed: false,
                            options: [15, 30, 45, 60], fallback: routine.beforeMeal)
            }
            if draft.timings.contains(where: { $0.relation == .after }) {
                offsetGroup("Sau ăn bao lâu?", relation: .after, isBed: false,
                            options: [0, 15, 30, 60], fallback: routine.afterMeal)
            }
            if has(.bed) {
                offsetGroup("Trước khi ngủ bao lâu?", relation: .before, isBed: true,
                            options: [15, 30, 60, 120], fallback: routine.beforeBed)
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
    }

    private func mealRow(_ label: String, _ anchor: Anchor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel(label)
            FlowLayout(spacing: 8, lineSpacing: 8) {
                chip("Trước ăn", on: has(anchor, .before)) { toggle(anchor, .before) }
                chip("Trong bữa", on: has(anchor, .during)) { toggle(anchor, .during) }
                chip("Sau ăn", on: has(anchor, .after)) { toggle(anchor, .after) }
            }
        }
    }

    private func offsetGroup(_ title: String, relation: Relation, isBed: Bool, options: [Int], fallback: Int) -> some View {
        let current = draft.timings.first { ($0.anchor == .bed) == isBed && $0.relation == relation }?.offsetMinutes ?? fallback
        return group(title) {
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(options, id: \.self) { m in
                    chip(offsetLabel(m), on: current == m) { setOffset(m, relation: relation, isBed: isBed) }
                }
            }
        }
    }

    private func offsetLabel(_ m: Int) -> String {
        if m == 0 { return "Ngay sau" }
        if m >= 60, m % 60 == 0 { return "\(m / 60) tiếng" }
        return "\(m) phút"
    }

    // MARK: Timing helpers

    private func has(_ anchor: Anchor, _ relation: Relation? = nil) -> Bool {
        draft.timings.contains { $0.anchor == anchor && (relation == nil || $0.relation == relation) }
    }

    /// One relation per meal: choosing "Sau ăn" replaces "Trước ăn" for that meal.
    private func toggle(_ anchor: Anchor, _ relation: Relation) {
        if has(anchor, relation) {
            draft.timings.removeAll { $0.anchor == anchor }
        } else {
            let sibling = draft.timings.first { $0.relation == relation && $0.anchor != .bed && anchor != .bed }
            draft.timings.removeAll { $0.anchor == anchor }
            draft.timings.append(Timing(anchor: anchor, relation: relation,
                                        offsetMinutes: sibling?.offsetMinutes,
                                        offsetSource: sibling?.offsetSource ?? .standard))
        }
    }

    private func setOffset(_ minutes: Int, relation: Relation, isBed: Bool) {
        for i in draft.timings.indices where (draft.timings[i].anchor == .bed) == isBed && draft.timings[i].relation == relation {
            draft.timings[i].offsetMinutes = minutes
            draft.timings[i].offsetSource = .user
        }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
            content()
        }
    }
}
