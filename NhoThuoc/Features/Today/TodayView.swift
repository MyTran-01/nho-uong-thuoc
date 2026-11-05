import SwiftUI
import SwiftData

/// S1: dose times due now first, then the next one, the rest, and the finished ones.
struct TodayView: View {
    @Query private var meds: [Medication]
    @Query private var logs: [DoseLog]
    @Query private var routines: [Routine]
    @Environment(Router.self) private var router
    @Environment(\.theme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationsOn = true
    @State private var photoFlowMeds: [UUID]?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                content(now: context.date)
            }
            .background(theme.background.color.ignoresSafeArea())
            .navigationTitle("Hôm nay")
        }
        .task(id: scenePhase) { notificationsOn = await NotificationScheduler.isAuthorized() }
        .fullScreenCover(item: Binding(get: { photoFlowMeds.map(IDList.init) }, set: { photoFlowMeds = $0?.ids })) { list in
            NavigationStack {
                BlisterCaptureView(medIDs: list.ids) { photoFlowMeds = nil }
            }
        }
    }

    private struct IDList: Identifiable { let ids: [UUID]; var id: String { ids.map(\.uuidString).joined() } }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let routine = routines.first?.times ?? RoutineTimes()
        let active = meds.filter { !$0.isFinished && $0.prescription?.status == .active }
        let day = SlotEngine.drugDay(for: now, routine: routine)
        let slots = SlotEngine.slots(day: day, routine: routine, meds: active.map(\.info))
        let logByKey = Dictionary(logs.map { ($0.slotKey, $0) }, uniquingKeysWith: { a, _ in a })
        let states: [(Slot, SlotState)] = slots.enumerated().map { i, s in
            (s, SlotState.of(s, next: i + 1 < slots.count ? slots[i + 1] : nil, log: logByKey[s.key], now: now))
        }
        let open = states.filter { $0.1 == .due || $0.1 == .missed }
        let upcoming = states.filter { $0.1 == .upcoming }
        let done = states.filter { $0.1.isDone }
        let missingPhotos = active.filter { !$0.hasPhotos }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(VNDate.dayTitle(day))
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
                    .padding(.top, -8)

                banner(missingPhotos: missingPhotos)

                if active.isEmpty {
                    emptyState
                } else if slots.isEmpty {
                    Text("Hôm nay không có thuốc cần uống.")
                        .appFont(.body)
                        .foregroundStyle(theme.muted.color)
                } else {
                    ForEach(open, id: \.0.key) { slot, state in
                        DueCard(slot: slot, state: state) { router.openSlotKey = slot.key }
                    }
                    if let next = upcoming.first {
                        NextCard(slot: next.0, isFirst: open.isEmpty) { router.openSlotKey = next.0.key }
                    }
                    if upcoming.count > 1 {
                        SectionTitle("Còn lại hôm nay")
                        HCard(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(Array(upcoming.dropFirst().enumerated()), id: \.element.0.key) { i, entry in
                                    if i > 0 { Divider().overlay(theme.separator.color).padding(.leading, 16) }
                                    SlotRow(slot: entry.0, state: entry.1) { router.openSlotKey = entry.0.key }
                                }
                            }
                        }
                    }
                    if !done.isEmpty {
                        SectionTitle("Đã xong")
                        HCard(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(Array(done.enumerated()), id: \.element.0.key) { i, entry in
                                    if i > 0 { Divider().overlay(theme.separator.color).padding(.leading, 16) }
                                    SlotRow(slot: entry.0, state: entry.1) { router.openSlotKey = entry.0.key }
                                }
                            }
                        }
                    }
                    if open.isEmpty && upcoming.isEmpty {
                        Text("Hôm nay đã uống xong hết rồi.")
                            .appFont(.headline)
                            .foregroundStyle(theme.success.color)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // At most one banner (PRD §5).
    @ViewBuilder
    private func banner(missingPhotos: [Medication]) -> some View {
        if !notificationsOn {
            HCard {
                Text("Chưa bật thông báo nên app chưa nhắc được.")
                    .appFont(.body)
                    .foregroundStyle(theme.foreground.color)
                Button("Mở Cài đặt để bật") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
            }
        } else if !missingPhotos.isEmpty {
            HCard {
                Text("\(missingPhotos.count) thuốc chưa có ảnh vỉ")
                    .appFont(.headline)
                    .foregroundStyle(theme.foreground.color)
                Text("Có ảnh thì lúc uống nhìn là nhận ra ngay.")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
                Button("Chụp ảnh vỉ") { photoFlowMeds = missingPhotos.sorted { $0.info.sortIndex < $1.info.sortIndex }.map(\.id) }
                    .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
            }
        }
    }

    private var emptyState: some View {
        HCard(padding: 20) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(theme.accent.color)
                .accessibilityHidden(true)
            Text("Chưa có đơn thuốc nào")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            Text("Chụp ảnh đơn thuốc, app sẽ tự xếp giờ uống cho bạn.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
            Button("Chụp đơn thuốc") { router.addPrescription = true }
                .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
        }
    }
}

// MARK: Cards

private struct PhotoStrip: View {
    let items: [SlotItem]
    var size: CGFloat = 52
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.medID) { item in
                    BlisterPhoto(file: item.frontPhoto, side: "mặt trước", medName: item.name, size: size)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(items.map(\.name).joined(separator: ", "))
    }
}

private struct DueCard: View {
    let slot: Slot
    let state: SlotState
    let open: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        HCard {
            HStack(alignment: .firstTextBaseline) {
                Text(state == .missed ? "Chưa đánh dấu" : "Tới giờ uống thuốc rồi")
                    .appFont(.title)
                    .foregroundStyle(theme.foreground.color)
                Spacer()
            }
            Text("\(slot.timeText) · \(slot.title) · \(slot.items.count) loại thuốc")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
            PhotoStrip(items: slot.items)
            Button("Đánh dấu đã uống", action: open)
                .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
        }
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardRadius, style: .continuous)
                .strokeBorder(state == .missed ? theme.danger.color : theme.accent.color, lineWidth: 2)
        )
    }
}

private struct NextCard: View {
    let slot: Slot
    let isFirst: Bool
    let open: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Giờ uống kế tiếp")
            HCard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.timeText)
                            .appFont(.display)
                            .monospacedDigit()
                            .foregroundStyle(theme.foreground.color)
                        Text(slot.title)
                            .appFont(.headline)
                            .foregroundStyle(theme.foreground.color)
                        Text("\(slot.items.count) loại thuốc")
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                    }
                    Spacer()
                    SlotStateChip(state: .upcoming)
                }
                PhotoStrip(items: slot.items)
                Button("Xem thuốc cần uống", action: open)
                    .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true, minHeight: theme.buttonHeight))
            }
        }
    }
}

private struct SlotRow: View {
    let slot: Slot
    let state: SlotState
    let open: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                Text(slot.timeText)
                    .appFont(.headline)
                    .monospacedDigit()
                    .foregroundStyle(theme.foreground.color)
                    .frame(minWidth: 58, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(slot.title)
                        .appFont(.body)
                        .foregroundStyle(theme.foreground.color)
                    if state.isDone {
                        SlotStateChip(state: state)
                    } else {
                        Text("\(slot.items.count) loại thuốc")
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.muted.color)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
