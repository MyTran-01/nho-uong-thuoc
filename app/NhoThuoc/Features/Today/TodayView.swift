import SwiftUI
import SwiftData

/// S1: dose times due now first, then the next one, the rest, and the finished ones.
/// Each dose time lists its medications; they are ticked right here (PRD §5.1).
struct TodayView: View {
    @Query private var meds: [Medication]
    @Query private var logs: [DoseLog]
    @Query private var routines: [Routine]
    @Environment(Router.self) private var router
    @Environment(\.theme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context
    @State private var notificationsOn = true
    @State private var expanded: Set<String> = []
    @State private var zoom: SlotItem?
    @State private var skipSlot: Slot?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                content(now: context.date)
            }
            .background(theme.background.color.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .task(id: scenePhase) { notificationsOn = await NotificationScheduler.isAuthorized() }
        .sheet(item: $zoom) { BlisterZoomView(item: $0) }
        .alert("Bỏ cữ \(skipSlot?.timeText ?? "")?", isPresented: Binding(get: { skipSlot != nil }, set: { if !$0 { skipSlot = nil } })) {
            Button("Bỏ cữ", role: .destructive) { if let s = skipSlot { skip(s) } }
            Button("Không", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let routine = routines.first?.times ?? RoutineTimes()
        let active = meds.filter(\.isActive)
        let day = SlotEngine.drugDay(for: now, routine: routine)
        let slots = SlotEngine.slots(day: day, routine: routine, meds: active.map(\.info))
        let logByKey = Dictionary(logs.map { ($0.slotKey, $0) }, uniquingKeysWith: { a, _ in a })
        let entries: [Entry] = slots.enumerated().map { i, s in
            let next = i + 1 < slots.count ? slots[i + 1] : nil
            let log = logByKey[s.key]
            return Entry(slot: s,
                         state: SlotState.of(s, next: next, log: log, now: now),
                         taken: Entry.takenIDs(log),
                         stillOpen: now < SlotEngine.missedAt(s, next: next),
                         canTick: now >= s.date.addingTimeInterval(-Entry.earlyWindow))
        }
        // Half-ticked dose times stay on top until they would count as missed.
        let open = entries.filter { $0.isOpen }
        let upcoming = entries.filter { $0.state == .upcoming }
        let done = entries.filter { $0.state.isDone && !$0.isOpen }

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TodayHeader(dayTitle: VNDate.dayTitle(day), entries: entries)
                    .padding(.top, 14)

                banner

                if active.isEmpty {
                    emptyState
                } else if slots.isEmpty {
                    nextDoseCard(after: day, routine: routine, meds: active.map(\.info))
                } else {
                    ForEach(open) { entry in
                        group(entry, showFooter: true)
                    }
                    if let next = upcoming.first {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle("Kế tiếp")
                            group(next.alwaysTickable, showFooter: false)
                        }
                    }
                    if upcoming.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle("Còn lại")
                            compactList(Array(upcoming.dropFirst()))
                        }
                    }
                    if !done.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle("Đã xong")
                            compactList(done)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .bottomCTA {
            Button {
                router.addMed = true
            } label: {
                Label("Thêm thuốc", systemImage: "plus")
            }
            .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
        }
    }

    private func group(_ entry: Entry, showFooter: Bool) -> some View {
        DoseGroupCard(entry: entry, showFooter: showFooter,
                      onTick: { toggle($0, in: entry.slot) },
                      onAll: { takeAll(entry.slot) },
                      onZoom: { zoom = $0 },
                      onSkip: { skipSlot = entry.slot },
                      onFinished: { router.openSlotKey = entry.slot.key })
    }

    private func compactList(_ list: [Entry]) -> some View {
        HCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.element.id) { i, entry in
                    if i > 0 { Divider().overlay(theme.separator.color).padding(.leading, 16) }
                    let isOpen = expanded.contains(entry.id)
                    CompactSlotRow(entry: entry, isExpanded: isOpen) {
                        withAnimation(.snappy) {
                            if isOpen { expanded.remove(entry.id) } else { expanded.insert(entry.id) }
                        }
                    }
                    if isOpen {
                        ForEach(entry.slot.items, id: \.medID) { item in
                            Divider().overlay(theme.separator.color).padding(.leading, 16)
                            MedTickRow(item: item, isTaken: entry.taken.contains(item.medID), canTick: entry.canTick,
                                       onTick: { toggle(item, in: entry.slot) }, onZoom: { zoom = item })
                        }
                    }
                }
            }
        }
    }

    // At most one banner (PRD §5).
    @ViewBuilder
    private var banner: some View {
        if NotificationScheduler.showsUI, !notificationsOn {
            HCard {
                Label("Thông báo đang tắt", systemImage: "bell.slash.fill")
                    .appFont(.body)
                    .foregroundStyle(theme.foreground.color)
                Button("Bật thông báo") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
            }
        }
    }

    /// Nothing left today (e.g. the medication was added this evening): say when the next dose is.
    private func nextDoseCard(after day: Date, routine: RoutineTimes, meds: [MedInfo]) -> some View {
        let next: (Int, Slot)? = (1...14).lazy.compactMap { offset -> (Int, Slot)? in
            let d = SlotEngine.calendar.date(byAdding: .day, value: offset, to: day)!
            return SlotEngine.slots(day: d, routine: routine, meds: meds).first.map { (offset, $0) }
        }.first
        return HCard(padding: 20) {
            Text("Hôm nay không còn lần dùng nào")
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
            if let next {
                let slot = next.1
                let when = next.0 == 1 ? "Ngày mai" : VNDate.dayTitle(slot.date)
                Text("Lần kế tiếp: \(when), \(slot.timeText)")
                    .appFont(.body)
                    .foregroundStyle(theme.accentSoftForeground.color)
                Text(slot.items.map(\.name).joined(separator: ", "))
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
            }
        }
    }

    private var emptyState: some View {
        HCard(padding: 20) {
            Image(systemName: "pills.fill")
                .font(.system(size: 44))
                .foregroundStyle(theme.accentSoftForeground.color)
                .accessibilityHidden(true)
            Text("Chưa có thuốc nào")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            Text("Thêm thuốc bạn đang dùng, app sẽ nhắc đúng giờ theo bữa ăn của bạn.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
        }
    }

    // MARK: Actions (each one can be undone from the toast)

    private enum Snapshot {
        case none
        case logged(taken: Set<UUID>, skipped: Bool)
    }

    private func snapshot(_ slot: Slot) -> Snapshot {
        guard let log = AppStore.log(forKey: slot.key, in: context) else { return .none }
        return .logged(taken: Entry.takenIDs(log), skipped: log.status == .skipped)
    }

    private func restore(_ snap: Snapshot, _ slot: Slot) {
        switch snap {
        case .none: apply([], to: slot)
        case let .logged(taken, skipped):
            if !skipped && taken.isEmpty { apply([], to: slot) }
            else { AppStore.record(slot: slot, taken: taken, skipped: skipped, in: context) }
        }
    }

    /// Writes the ticks for one dose time. No tick left = no record, so the dose time is open again.
    private func apply(_ taken: Set<UUID>, to slot: Slot) {
        if taken.isEmpty {
            if let log = AppStore.log(forKey: slot.key, in: context) {
                context.delete(log)
                try? context.save()
                NotificationScheduler.reschedule(in: context)
            }
        } else {
            AppStore.record(slot: slot, taken: taken, in: context)
        }
    }

    private func toggle(_ item: SlotItem, in slot: Slot) {
        let before = snapshot(slot)
        var taken: Set<UUID> = []
        if case let .logged(t, skipped) = before, !skipped { taken = t }
        let nowTaken = !taken.contains(item.medID)
        if nowTaken { taken.insert(item.medID) } else { taken.remove(item.medID) }
        apply(taken, to: slot)
        router.toast = ToastMessage(text: nowTaken ? "Đã dùng \(item.name)" : "Đã bỏ dấu") {
            restore(before, slot)
        }
    }

    private func takeAll(_ slot: Slot) {
        let before = snapshot(slot)
        AppStore.record(slot: slot, taken: Set(slot.items.map(\.medID)), in: context)
        router.toast = ToastMessage(text: "Đã dùng đủ") { restore(before, slot) }
    }

    private func skip(_ slot: Slot) {
        let before = snapshot(slot)
        AppStore.record(slot: slot, taken: [], skipped: true, in: context)
        router.toast = ToastMessage(text: "Đã bỏ cữ") { restore(before, slot) }
    }
}

// MARK: Model for one dose time on screen

private struct Entry: Identifiable {
    /// Ticking is allowed from 60 minutes before the dose time (Q22).
    static let earlyWindow: TimeInterval = 3600

    let slot: Slot
    let state: SlotState
    let taken: Set<UUID>
    let stillOpen: Bool
    var canTick: Bool

    var id: String { slot.key }

    /// The next dose time can be ticked at any time, however early (product decision 06/11/2026).
    var alwaysTickable: Entry {
        var copy = self
        copy.canTick = true
        return copy
    }

    var isOpen: Bool {
        switch state {
        case .due, .missed: true
        case .partial: stillOpen
        default: false
        }
    }

    static func takenIDs(_ log: DoseLog?) -> Set<UUID> {
        guard let log, log.status != .skipped else { return [] }
        return Set(log.items.filter(\.taken).map(\.medID))
    }
}

// MARK: Pieces

/// Title, date and today's dose times as status dots, in one block.
private struct TodayHeader: View {
    let dayTitle: String
    let entries: [Entry]
    @Environment(\.theme) private var theme

    private var completed: Int { entries.filter { $0.state == .taken }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hôm nay")
                        .appFont(.display)
                        .foregroundStyle(theme.foreground.color)
                        .accessibilityAddTraits(.isHeader)
                    Text(dayTitle)
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                }
                Spacer()
                if !entries.isEmpty {
                    Text("\(completed)/\(entries.count)")
                        .appFont(.title)
                        .monospacedDigit()
                        .foregroundStyle(completed == entries.count ? theme.success.color : theme.foreground.color)
                        .accessibilityLabel("Đã dùng đủ \(completed) trên \(entries.count) lần")
                }
            }
            if !entries.isEmpty { dots }
        }
    }

    private var dots: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(entries) { entry in
                        VStack(spacing: 7) {
                            Image(systemName: entry.state.symbol)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(entry.state.palette(in: theme).foreground.color)
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(entry.state.palette(in: theme).background.color))
                            Text(entry.slot.timeText)
                                .appFont(.label)
                                .monospacedDigit()
                                .foregroundStyle(theme.muted.color)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(entry.slot.timeText), \(entry.state.label)")
                    }
                }
                .padding(.vertical, 2)
            }
    }

}

/// Coloured round icon for the part of the day.
private struct DayPartIcon: View {
    let anchor: Anchor
    let state: SlotState
    var size: CGFloat = 44
    @Environment(\.theme) private var theme

    var body: some View {
        let symbol: String = switch anchor {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .afternoon: "cloud.sun.fill"
        case .dinner: "moon.fill"
        case .bed: "bed.double.fill"
        case .fixed: "clock.fill"
        }
        Image(systemName: symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(state.palette(in: theme).foreground.color)
            .frame(width: size, height: size)
            .background(Circle().fill(state.palette(in: theme).background.color))
            .accessibilityHidden(true)
    }
}

/// One medication: blister photo, name, amount, and the round tick button.
private struct MedTickRow: View {
    let item: SlotItem
    let isTaken: Bool
    let canTick: Bool
    let onTick: () -> Void
    let onZoom: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onZoom) {
                MedThumb(file: item.frontPhoto, form: item.form, name: item.name, size: 64)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Chạm để phóng to ảnh")

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .appFont(.headline)
                    .foregroundStyle(theme.foreground.color)
                Text(item.purpose.isEmpty ? item.doseText : "\(item.doseText) · \(item.purpose)")
                    .appFont(.secondary)
                    .fontWeight(isTaken ? .semibold : .regular)
                    .foregroundStyle(isTaken ? theme.success.color : theme.muted.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if canTick {
                Button(action: onTick) {
                    Image(systemName: isTaken ? "checkmark" : "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isTaken ? theme.successForeground.color : theme.foreground.color)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(isTaken ? theme.success.color : theme.defaultFill.color))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: isTaken) { _, new in new }
                .accessibilityLabel("Đã dùng \(item.name)")
                .accessibilityAddTraits(isTaken ? .isSelected : [])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// A full dose time: header with "Dùng đủ", one row per medication, and the small actions.
private struct DoseGroupCard: View {
    let entry: Entry
    let showFooter: Bool
    let onTick: (SlotItem) -> Void
    let onAll: () -> Void
    let onZoom: (SlotItem) -> Void
    let onSkip: () -> Void
    let onFinished: () -> Void
    @Environment(\.theme) private var theme

    private var slot: Slot { entry.slot }

    var body: some View {
        HCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                header
                ForEach(slot.items, id: \.medID) { item in
                    Divider().overlay(theme.separator.color)
                    MedTickRow(item: item, isTaken: entry.taken.contains(item.medID), canTick: entry.canTick,
                               onTick: { onTick(item) }, onZoom: { onZoom(item) })
                }
                if showAllButton {
                    Button("Đã dùng đủ", action: onAll)
                        .buttonStyle(HButtonStyle(variant: entry.state == .upcoming ? .secondary : .primary,
                                                  fullWidth: true, minHeight: theme.buttonHeight))
                        .accessibilityLabel("Dùng đủ cả \(slot.title)")
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .padding(.top, 4)
                }
                if showFooter {
                    Divider().overlay(theme.separator.color)
                    HStack(spacing: 4) {
                        footerLink("Bỏ cữ", action: onSkip)
                        footerLink("Hết thuốc", action: onFinished)
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .shadow(color: entry.state == .due ? theme.warning.color.opacity(0.10) : .clear,
                radius: 16, y: 5)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(slot.title)
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
            if slot.anchor != .fixed {
                Text(slot.timeText)
                    .appFont(.secondary)
                    .monospacedDigit()
                    .foregroundStyle(theme.muted.color)
            }
            SlotStateChip(state: entry.state)
        }
        .accessibilityElement(children: .combine)
    }

    /// One tap for the whole dose time. Pointless with a single medication (its ＋ does the same).
    private var showAllButton: Bool {
        entry.canTick && slot.items.count > 1 && entry.taken.count < slot.items.count
    }

    private var header: some View {
        HStack(spacing: 12) {
            DayPartIcon(anchor: slot.anchor, state: entry.state)
            titleBlock
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(entry.state.palette(in: theme).background.color.opacity(0.55))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: theme.cardRadius, topTrailingRadius: theme.cardRadius))
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .appFont(.secondary)
                .underline()
                .foregroundStyle(theme.accentSoftForeground.color)
                .frame(maxWidth: .infinity, minHeight: theme.touchMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// One line for later and finished dose times. Tapping opens the medications below it.
private struct CompactSlotRow: View {
    let entry: Entry
    let isExpanded: Bool
    let toggle: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                DayPartIcon(anchor: entry.slot.anchor, state: entry.state, size: 36)
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.slot.anchor == .fixed ? entry.slot.timeText : "\(entry.slot.timeText) · \(entry.slot.title)")
                        .appFont(.headline)
                        .monospacedDigit()
                        .foregroundStyle(theme.foreground.color)
                    SlotStateChip(state: entry.state)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(theme.muted.color)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(isExpanded ? "Chạm để thu gọn" : "Chạm để xem từng thuốc")
    }
}
