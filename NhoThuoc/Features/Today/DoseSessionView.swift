import SwiftUI
import SwiftData

/// S2: one dose time. Every medication is pre-checked (M07); uncheck what was not taken.
struct DoseSessionView: View {
    let slot: Slot
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var taken: Set<UUID> = []
    @State private var hidden: Set<UUID> = []
    @State private var existing: DoseLog?
    @State private var zoom: SlotItem?
    @State private var confirmSkip = false
    @State private var toast: ToastMessage?
    @State private var loaded = false

    private var items: [SlotItem] { slot.items.filter { !hidden.contains($0.medID) } }
    private var missing: Int { items.filter { !taken.contains($0.medID) }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(slot.timeText) · \(slot.title)")
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                        Text(heading)
                            .appFont(.title)
                            .foregroundStyle(theme.foreground.color)
                        Text("Bỏ dấu tích ở thuốc nào chưa uống.")
                            .appFont(.body)
                            .foregroundStyle(theme.muted.color)
                    }
                    HCard(padding: 16) {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.medID) { index, item in
                                if index > 0 { Divider().overlay(theme.separator.color) }
                                row(item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(theme.background.color.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { actions }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .toast($toast)
        }
        .onAppear(perform: load)
        .sheet(item: $zoom) { BlisterZoomView(item: $0) }
        .alert("Hôm nay bỏ cữ này?", isPresented: $confirmSkip) {
            Button("Bỏ cữ", role: .destructive) { save(skipped: true) }
            Button("Không", role: .cancel) {}
        } message: {
            Text("App sẽ ghi là đã bỏ cữ và không nhắc lần này nữa.")
        }
    }

    private var heading: String {
        if existing != nil { return "Sửa lại lần uống này" }
        let now = Date.now
        if now < slot.date { return "Sắp tới giờ uống thuốc" }
        if now > slot.date.addingTimeInterval(3 * 3600) { return "Đánh dấu muộn" }
        return "Tới giờ uống thuốc rồi"
    }

    private func row(_ item: SlotItem) -> some View {
        let isOn = Binding(get: { taken.contains(item.medID) },
                           set: { on in if on { taken.insert(item.medID) } else { taken.remove(item.medID) } })
        return HStack(spacing: 12) {
            Button { zoom = item } label: {
                BlisterPair(front: item.frontPhoto, back: item.backPhoto, medName: item.name, size: 64)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Chạm để phóng to ảnh")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .appFont(.headline)
                    .foregroundStyle(theme.foreground.color)
                Text(item.doseText)
                    .appFont(.secondary)
                    .foregroundStyle(theme.foreground.color)
                Menu {
                    Button("Thuốc này đã hết", systemImage: "archivebox") { markFinished(item) }
                } label: {
                    Text("Tuỳ chọn")
                        .appFont(.secondary)
                        .foregroundStyle(theme.accentSoftForeground.color)
                        .underline()
                        .frame(minHeight: 32)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HCheckbox(isOn: isOn, label: "Đã uống \(item.name)")
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { isOn.wrappedValue.toggle() }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button(missing == 0 ? (existing == nil ? "Đã uống" : "Lưu thay đổi")
                   : "Đã uống (còn \(missing) thuốc chưa uống)") { save(skipped: false) }
                .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                .disabled(items.isEmpty)
            if existing?.status != .skipped {
                Button("Hôm nay bỏ cữ này") { confirmSkip = true }
                    .buttonStyle(HButtonStyle(variant: .tertiary, fullWidth: true))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(theme.background.color.opacity(0.96))
    }

    // MARK: Actions

    private func load() {
        guard !loaded else { return }
        loaded = true
        existing = AppStore.log(forKey: slot.key, in: context)
        if let existing, existing.status != .skipped {
            taken = Set(existing.items.filter(\.taken).map(\.medID))
        } else {
            taken = Set(slot.items.map(\.medID))
        }
    }

    private func save(skipped: Bool) {
        let visible = Slot(key: slot.key, dayKey: slot.dayKey, date: slot.date, minuteOfDrugDay: slot.minuteOfDrugDay,
                           anchor: slot.anchor, relation: slot.relation, items: items)
        let log = AppStore.record(slot: visible, taken: taken, skipped: skipped, in: context)
        let text: String
        switch log.status {
        case .taken: text = "Đã uống đủ · \(slot.title)"
        case .partial: text = "Đã ghi · còn \(log.missingCount) thuốc chưa uống"
        case .skipped: text = "Đã bỏ cữ · \(slot.title)"
        }
        Router.shared.toast = ToastMessage(text: text)
        dismiss()
    }

    private func markFinished(_ item: SlotItem) {
        let id = item.medID
        guard let med = try? context.fetch(FetchDescriptor<Medication>(predicate: #Predicate { $0.id == id })).first else { return }
        med.isFinished = true
        med.finishedAt = .now
        try? context.save()
        hidden.insert(id)
        NotificationScheduler.reschedule(in: context)
        toast = ToastMessage(text: "Đã ghi \(item.name) là đã hết") {
            med.isFinished = false
            med.finishedAt = nil
            try? context.save()
            hidden.remove(id)
            NotificationScheduler.reschedule(in: context)
        }
    }
}

extension SlotItem: Identifiable {
    var id: UUID { medID }
}
