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
                VStack(alignment: .leading, spacing: 18) {
                    Text("Cài đặt")
                        .appFont(.display)
                        .foregroundStyle(theme.foreground.color)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, 8)
                    SectionTitle("Giờ sinh hoạt")
                    Text("App dựa vào giờ ăn, giờ ngủ của riêng bạn để nhắc dùng thuốc đúng lúc. Ví dụ thuốc dùng sau ăn sáng sẽ được nhắc ngay sau giờ ăn sáng của bạn.")
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                        .fixedSize(horizontal: false, vertical: true)
                    RoutineEditor(times: $times, fields: [.breakfast, .lunch, .afternoon, .dinner, .bed])
                    if let problem = times.problem {
                        Text(problem).appFont(.secondary).foregroundStyle(theme.danger.color)
                    }
                    if times != saved {
                        if times.problem == nil, !moves.isEmpty {
                            HCard {
                                Text("Giờ dùng mới")
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
                            }
                        }
                    }

                    if NotificationScheduler.showsUI {
                    SectionTitle("Nhắc nhở")
                    HCard {
                        Label(notificationsOn ? "Thông báo đang bật" : "Thông báo đang tắt",
                              systemImage: notificationsOn ? "bell.fill" : "bell.slash.fill")
                            .appFont(.body)
                            .foregroundStyle(notificationsOn ? theme.foreground.color : theme.danger.color)
                        if !notificationsOn {
                            Button("Bật thông báo") {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
                        }
                        Toggle(isOn: $showNames) {
                            Text("Hiện tên thuốc trên màn hình khoá")
                                .appFont(.body)
                                .foregroundStyle(theme.foreground.color)
                        }
                        .tint(theme.accent.color)
                        .frame(minHeight: theme.touchMin)
                        .onChange(of: showNames) { NotificationScheduler.reschedule(in: context) }
                        Divider().overlay(theme.separator.color)
                        Button("Gửi thử lời nhắc") { sendTest() }
                            .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
                            .disabled(testSlot == nil)
                        if testSlot == nil {
                            Text("Chưa có thuốc nào")
                                .appFont(.secondary)
                                .foregroundStyle(theme.muted.color)
                        }
                    }
                    }

                    Button("Xoá hết dữ liệu") { confirmReset = true }
                        .appFont(.secondary)
                        .foregroundStyle(theme.danger.color)
                        .frame(maxWidth: .infinity, minHeight: theme.touchMin)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .background(theme.background.color.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .bottomCTA(when: times != saved) {
                Button("Lưu giờ sinh hoạt") { saveRoutine() }
                    .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                    .disabled(times.problem != nil)
            }
        }
        .onAppear {
            if !loaded { times = saved; loaded = true }
        }
        .task(id: scenePhase) { notificationsOn = await NotificationScheduler.isAuthorized() }
        .alert("Xoá hết dữ liệu?", isPresented: $confirmReset) {
            Button("Xoá hết", role: .destructive) {
                AppStore.resetAll(in: context)
                onboarded = false
            }
            Button("Không", role: .cancel) {}
        } message: {
            Text("Thuốc, ảnh và lịch sử sẽ mất hẳn.")
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
        Router.shared.toast = ToastMessage(text: n > 0 ? "Đã dời \(n) giờ dùng" : "Đã lưu giờ mới")
    }

    private func sendTest() {
        guard let slot = testSlot else { return }
        NotificationScheduler.sendTest(for: slot)
        Router.shared.toast = ToastMessage(text: "Lời nhắc tới sau vài giây")
    }
}
