import SwiftUI
import SwiftData

/// Tab "Thuốc": every medication, grouped by what it is for. Paused and finished ones at the end.
struct MedListView: View {
    @Query(sort: \Medication.createdAt) private var meds: [Medication]
    @Query private var routines: [Routine]
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @State private var toast: ToastMessage?

    private var routine: RoutineTimes { routines.first?.times ?? RoutineTimes() }

    var body: some View {
        let active = meds.filter(\.isActive)
        let stopped = meds.filter { !$0.isActive }
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Thuốc")
                        .appFont(.display)
                        .foregroundStyle(theme.foreground.color)
                        .accessibilityAddTraits(.isHeader)
                    if !meds.isEmpty {
                        Text("\(active.count) thuốc đang dùng")
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                            .padding(.bottom, 6)
                    }
                    if meds.isEmpty {
                        HCard(padding: 22) {
                            Image(systemName: "pills.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(theme.accentSoftForeground.color)
                            Text("Chưa có thuốc nào")
                                .appFont(.headline)
                                .foregroundStyle(theme.foreground.color)
                            Text("Thêm thuốc bạn đang dùng, app sẽ xếp giờ theo bữa ăn của bạn.")
                                .appFont(.secondary)
                                .foregroundStyle(theme.muted.color)
                        }
                    }
                    ForEach(groups(active), id: \.title) { group in
                        SectionTitle(group.title)
                            .padding(.top, 6)
                        ForEach(group.meds) { med in row(med) }
                    }
                    if !stopped.isEmpty {
                        SectionTitle("Tạm dừng, đã hết")
                            .padding(.top, 6)
                        ForEach(stopped) { med in row(med) }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .background(theme.background.color.ignoresSafeArea())
            .bottomCTA {
                Button {
                    router.addMed = true
                } label: {
                    Label("Thêm thuốc", systemImage: "plus")
                }
                .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
            }
            .toolbar(.hidden, for: .navigationBar)
            .toast($toast)
        }
    }

    private struct Group { let title: String; let meds: [Medication] }

    /// Named groups in the order they were first used; medications without a purpose last.
    private func groups(_ list: [Medication]) -> [Group] {
        var order: [String] = []
        var byKey: [String: [Medication]] = [:]
        for m in list {
            let key = m.purpose.isEmpty ? "" : m.purpose.lowercased()
            if byKey[key] == nil { order.append(key) }
            byKey[key, default: []].append(m)
        }
        let named = order.filter { !$0.isEmpty }.map { Group(title: byKey[$0]![0].purpose, meds: byKey[$0]!) }
        let other = byKey[""].map { [Group(title: named.isEmpty ? "Đang dùng" : "Khác", meds: $0)] } ?? []
        return named + other
    }

    private func row(_ med: Medication) -> some View {
        let times = med.timings.map { SlotEngine.minute(of: $0, routine: routine) }.sorted().map(Clock.text)
        let detail = med.doseText
        return HCard(padding: 14) {
            HStack(spacing: 12) {
                Button { router.editMed = med } label: {
                    HStack(spacing: 12) {
                        MedThumb(file: med.photo, form: med.form, name: med.name, size: 60)
                            .opacity(med.isActive ? 1 : 0.5)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(med.name)
                                .appFont(.headline)
                                .foregroundStyle(med.isActive ? theme.foreground.color : theme.muted.color)
                            Text(detail)
                                .appFont(.secondary)
                                .foregroundStyle(theme.muted.color)
                            Text(statusText(med, times: times))
                                .appFont(.secondary)
                                .foregroundStyle(med.isActive ? theme.accentSoftForeground.color : theme.muted.color)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Chạm để xem và sửa")
                Menu {
                    Button("Sửa thuốc", systemImage: "pencil") { router.editMed = med }
                    if med.isFinished {
                        Button("Dùng lại", systemImage: "arrow.uturn.backward") { setFinished(med, false) }
                    } else {
                        Button(med.isPaused ? "Dùng tiếp" : "Tạm dừng",
                               systemImage: med.isPaused ? "play.circle" : "pause.circle") { setPaused(med, !med.isPaused) }
                        Button("Đã hết thuốc", systemImage: "checkmark.circle") { setFinished(med, true) }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(theme.foreground.color)
                        .frame(width: theme.touchMin, height: theme.touchMin)
                        .background(Circle().fill(theme.defaultFill.color))
                }
                .accessibilityLabel("Tuỳ chọn cho \(med.name)")
            }
        }
    }

    private func statusText(_ med: Medication, times: [String]) -> String {
        if med.isFinished { return "Đã hết" }
        if med.isPaused { return "Tạm dừng, không nhắc" }
        let d = med.draft
        let days: String = switch d.frequency {
        case .custom where d.custom != .everyHours: d.scheduleText.components(separatedBy: " · ").first ?? ""
        default: ""
        }
        return ([times.joined(separator: ", ")] + (days.isEmpty ? [] : [days])).joined(separator: " · ")
    }

    private func setFinished(_ med: Medication, _ finished: Bool) {
        med.isFinished = finished
        med.finishedAt = finished ? .now : nil
        if !finished { med.isPaused = false }
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        if finished {
            toast = ToastMessage(text: "\(med.name): đã hết") { setFinished(med, false) }
        }
    }

    private func setPaused(_ med: Medication, _ paused: Bool) {
        med.isPaused = paused
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        toast = paused
            ? ToastMessage(text: "Đã tạm dừng \(med.name)") { setPaused(med, false) }
            : ToastMessage(text: "Đã nhắc lại \(med.name)")
    }
}
