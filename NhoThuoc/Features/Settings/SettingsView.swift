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
                        Text("Muốn xem lời nhắc trông thế nào? Bấm nút dưới, 5 giây sau điện thoại sẽ báo giờ uống kế tiếp.")
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

    private func saveRoutine() {
        let r = AppStore.routine(in: context)
        r.times = times
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        Router.shared.toast = ToastMessage(text: "Đã dời giờ uống theo giờ mới")
    }

    private func sendTest() {
        guard let slot = testSlot else { return }
        NotificationScheduler.sendTest(for: slot)
        Router.shared.toast = ToastMessage(text: "5 giây nữa sẽ có lời nhắc")
    }
}
