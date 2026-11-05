import SwiftUI
import SwiftData

/// A01: O1 welcome → O2 routine → O3 notifications → O4 first prescription.
struct OnboardingFlow: View {
    enum Step { case welcome, routine, notifications, firstPrescription }

    @AppStorage("onboarded") private var onboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @State private var step: Step = .welcome
    @State private var times = RoutineTimes()

    var body: some View {
        ZStack {
            theme.background.color.ignoresSafeArea()
            switch step {
            case .welcome: welcome.transition(.opacity)
            case .routine: routine.transition(.move(edge: .trailing))
            case .notifications: notifications.transition(.move(edge: .trailing))
            case .firstPrescription: firstPrescription.transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    // O1
    private var welcome: some View {
        page(primary: ("Bắt đầu", { step = .routine })) {
            Spacer(minLength: 24)
            Image(systemName: "pills.fill")
                .font(.system(size: 64))
                .foregroundStyle(theme.accent.color)
                .accessibilityHidden(true)
            Text("Nhớ Thuốc")
                .appFont(.display)
                .foregroundStyle(theme.foreground.color)
            Text("Tới giờ, app nhắc bạn uống viên nào, kèm ảnh vỉ thuốc để nhìn là nhận ra.")
                .appFont(.headline)
                .fontWeight(.regular)
                .foregroundStyle(theme.foreground.color)
            VStack(alignment: .leading, spacing: 14) {
                point("camera.fill", "Chụp đơn một lần, app tự xếp giờ uống")
                point("bell.fill", "Tới giờ thì nhắc, gom thuốc của mọi đơn")
                point("checkmark.circle.fill", "Uống xong bấm một nút là xong")
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    // O2
    private var routine: some View {
        page(primary: ("Tiếp tục", saveRoutine), primaryDisabled: times.problem != nil) {
            Text("Bạn thường ăn và ngủ lúc mấy giờ?")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            Text("App dựa vào đây để tính giờ uống thuốc. Giờ nào chưa đúng thì chạm vào để sửa.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
            RoutineEditor(times: $times)
            if let problem = times.problem {
                Text(problem)
                    .appFont(.secondary)
                    .foregroundStyle(theme.danger.color)
            }
            Text("Buổi chiều mặc định là 15:00, đổi được trong Cài đặt.")
                .appFont(.secondary)
                .foregroundStyle(theme.muted.color)
        }
    }

    // O3
    private var notifications: some View {
        page(primary: ("Bật nhắc nhở", askPermission), secondary: ("Để sau", { step = .firstPrescription })) {
            Spacer(minLength: 24)
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(theme.accent.color)
                .accessibilityHidden(true)
            Text("Cho phép app nhắc bạn")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            Text("Tới giờ uống thuốc, điện thoại sẽ báo. Màn hình khoá chỉ hiện giờ uống và số loại thuốc, không hiện tên thuốc.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
            Text("Bấm “Bật nhắc nhở”, rồi chọn “Cho phép” ở hộp hiện ra.")
                .appFont(.body)
                .foregroundStyle(theme.foreground.color)
            Spacer()
        }
    }

    // O4
    private var firstPrescription: some View {
        page(primary: ("Chụp đơn thuốc", { finish(addPrescription: true) }),
             secondary: ("Để sau", { finish(addPrescription: false) })) {
            Spacer(minLength: 24)
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(theme.accent.color)
                .accessibilityHidden(true)
            Text("Thêm đơn thuốc đầu tiên")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            Text("Chụp ảnh đơn bác sĩ kê. App đọc tên thuốc và cách uống, bạn chỉ cần kiểm lại.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
            Text("Sau đó chụp vỉ thuốc mặt trước và mặt sau, để lúc uống nhìn là nhận ra.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
            Spacer()
        }
    }

    // MARK: Actions

    private func saveRoutine() {
        let r = AppStore.routine(in: context)
        r.times = times
        try? context.save()
        step = .notifications
    }

    private func askPermission() {
        Task {
            _ = await NotificationScheduler.requestPermission()
            step = .firstPrescription
        }
    }

    private func finish(addPrescription: Bool) {
        onboarded = true
        Router.shared.tab = .today
        if addPrescription {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                Router.shared.addPrescription = true
            }
        }
    }

    // MARK: Layout

    private func point(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(theme.accent.color)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(text)
                .appFont(.body)
                .foregroundStyle(theme.foreground.color)
        }
    }

    private func page<Content: View>(primary: (String, () -> Void),
                                     primaryDisabled: Bool = false,
                                     secondary: (String, () -> Void)? = nil,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) { content() }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 8) {
                Button(primary.0, action: primary.1)
                    .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                    .disabled(primaryDisabled)
                if let secondary {
                    Button(secondary.0, action: secondary.1)
                        .buttonStyle(HButtonStyle(variant: .tertiary, fullWidth: true))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}
