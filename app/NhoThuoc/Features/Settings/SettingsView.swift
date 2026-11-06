import SwiftUI
import SwiftData

/// S11/S12 (MVP): routine times, reminder test, start over.
struct SettingsView: View {
    @Query private var routines: [Routine]
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onboarded") private var onboarded = false
    @State private var times = RoutineTimes()
    @State private var loaded = false
    @State private var notificationsOn = true
    @State private var confirmReset = false
    @AppStorage(NotificationScheduler.showNamesKey) private var showNames = false

    private var saved: RoutineTimes { routines.first?.times ?? RoutineTimes() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle("Giờ sinh hoạt")
                    RoutineEditor(times: $times, fields: [.breakfast, .lunch, .afternoon, .dinner, .bed])
                    if let problem = times.problem {
                        Text(problem).appFont(.secondary).foregroundStyle(theme.danger.color)
                    }
                    if times != saved {
                        if times.problem == nil, !moves.isEmpty {
                            HCard {
                                Text("Các giờ uống sẽ dời thành:")
                                    .appFont(.headline)
                                    .foregroundStyle(theme.foreground.color)
                                ForEach(moves, id: \.title) { m in
                                    HStack {
                                        Text(m.title)
                                            .appFont(.body)
                                            .foregroundStyle(theme.foreground.color)
                                        Spacer()
                                        Text("\(m.from) → \(m.to)")
                                            .appFont(.body)
                                            .monospacedDigit()
                                            .foregroundStyle(theme.foreground.color)
                                    }
                                }
                                Text("Những lần đã đánh dấu vẫn giữ nguyên.")
                                    .appFont(.secondary)
                                    .foregroundStyle(theme.muted.color)
                            }
                        }
                        Button("Lưu giờ mới") { saveRoutine() }
                            .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                            .disabled(times.problem != nil)
                    }

                    SectionTitle("Nhắc nhở")
                    HCard {
                        Text(notificationsOn ? "Đã bật thông báo." : "Chưa bật thông báo nên app chưa nhắc được.")
                            .appFont(.body)
                            .foregroundStyle(theme.foreground.color)
                        if !notificationsOn {
                            Button("Mở Cài đặt để bật") {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
                        }
                        Toggle(isOn: $showNames) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hiện tên thuốc trong lời nhắc")
                                    .appFont(.body)
                                    .foregroundStyle(theme.foreground.color)
                                Text("Tắt thì người khác nhìn màn hình khoá không biết bạn uống thuốc gì.")
                                    .appFont(.secondary)
                                    .foregroundStyle(theme.muted.color)
                            }
                        }
                        .tint(theme.accent.color)
                        .frame(minHeight: theme.touchMin)
                        .onChange(of: showNames) { NotificationScheduler.reschedule(in: context) }
                        Divider().overlay(theme.separator.color)
                        Text("Muốn xem lời nhắc trông thế nào? Bấm nút dưới, vài giây sau điện thoại sẽ báo giờ uống kế tiếp.")
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                        Button("Gửi thử lời nhắc") { sendTest() }
                            .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
                            .disabled(testSlot == nil)
                        if testSlot == nil {
                            Text("Thêm đơn thuốc trước đã.")
                                .appFont(.secondary)
                                .foregroundStyle(theme.muted.color)
                        }
                    }

                    SectionTitle("Khác")
                    HCard {
                        Text("Xoá hết đơn thuốc, ảnh và lịch sử, rồi làm lại từ đầu.")
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                        Button("Bắt đầu lại từ đầu") { confirmReset = true }
                            .buttonStyle(HButtonStyle(variant: .outline, fullWidth: true))
                    }
                }
                .padding(16)
            }
            .background(theme.background.color.ignoresSafeArea())
            .navigationTitle("Cài đặt")
        }
        .onAppear {
            if !loaded { times = saved; loaded = true }
        }
        .task(id: scenePhase) { notificationsOn = await NotificationScheduler.isAuthorized() }
        .alert("Xoá hết và làm lại?", isPresented: $confirmReset) {
            Button("Xoá hết", role: .destructive) {
                AppStore.resetAll(in: context)
                onboarded = false
            }
            Button("Không", role: .cancel) {}
        } message: {
            Text("Mọi đơn thuốc, ảnh vỉ và lịch sử sẽ mất, không lấy lại được.")
        }
    }

    /// The next dose time that is not marked yet, else the first one today.
    private var testSlot: Slot? {
        let slots = AppStore.slots(around: .now, extraDays: 1, in: context)
        return slots.first { $0.date > .now && AppStore.log(forKey: $0.key, in: context) == nil } ?? slots.first
    }

    /// Dose times whose clock changes with the edited routine (AC08 preview).
    private var moves: [(title: String, from: String, to: String)] {
        let meds = AppStore.activeMeds(in: context).map { m -> MedInfo in
            var copy = m
            copy.activeFrom = .distantPast
            return copy
        }
        let day = SlotEngine.calendar.startOfDay(for: .now)
        // Use a typical day so every-other-day medications show up too.
        let old = SlotEngine.slots(day: day, routine: saved, meds: meds.map { var c = $0; c.everyNDays = 0; return c })
        let new = SlotEngine.slots(day: day, routine: times, meds: meds.map { var c = $0; c.everyNDays = 0; return c })
        return old.compactMap { o in
            guard let n = new.first(where: { $0.anchor == o.anchor && $0.relation == o.relation }),
                  n.minuteOfDrugDay != o.minuteOfDrugDay else { return nil }
            return (o.title, o.timeText, n.timeText)
        }
    }

    private func saveRoutine() {
        let n = moves.count
        let r = AppStore.routine(in: context)
        r.times = times
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        Router.shared.toast = ToastMessage(text: n > 0 ? "Đã dời \(n) giờ uống" : "Đã lưu giờ mới")
    }

    private func sendTest() {
        guard let slot = testSlot else { return }
        NotificationScheduler.sendTest(for: slot)
        Router.shared.toast = ToastMessage(text: "Vài giây nữa sẽ có lời nhắc")
    }
}
