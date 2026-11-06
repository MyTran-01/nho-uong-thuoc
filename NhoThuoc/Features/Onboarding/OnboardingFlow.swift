import SwiftUI
import SwiftData

/// A01: O1 welcome → O2 routine (meal and bed times drive the suggested dose times) → O3 first medication.
/// Notification permission is not asked here yet (06/11/2026: basic flow first).
struct OnboardingFlow: View {
    enum Step { case welcome, routine, firstMed }

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
            case .firstMed: firstMed.transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    // O1
    private var welcome: some View {
        page(primary: ("Bắt đầu", { step = .routine })) {
            welcomeIllustration
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            Text("Nhớ Thuốc")
                .appFont(.display)
                .foregroundStyle(theme.foreground.color)
                .frame(maxWidth: .infinity)
            Text("Biết đúng thuốc cần dùng, đúng giờ. Dùng xong chỉ cần chạm một lần.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    // O2
    private var routine: some View {
        page(primary: ("Tiếp tục", saveRoutine), primaryDisabled: times.problem != nil) {
            hero("clock")
            Text("Bạn thường ăn và ngủ lúc mấy giờ?")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            Text("App dựa vào giờ sinh hoạt của riêng bạn để nhắc dùng thuốc đúng lúc. Đổi được sau trong Cài đặt.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
                .fixedSize(horizontal: false, vertical: true)
            RoutineEditor(times: $times)
            if let problem = times.problem {
                Text(problem)
                    .appFont(.secondary)
                    .foregroundStyle(theme.danger.color)
            }
        }
    }

    // O3
    private var firstMed: some View {
        page(primary: ("Thêm thuốc", { finish(addMed: true) }),
             secondary: ("Để sau", { finish(addMed: false) })) {
            hero("pills.fill")
            Text("Bạn đang dùng thuốc gì?")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            Text("Nhập tên, loại thuốc và mỗi ngày dùng mấy lần. App tự gợi ý giờ dùng theo bữa ăn của bạn.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
        }
    }

    // MARK: Actions

    private func saveRoutine() {
        let r = AppStore.routine(in: context)
        r.times = times
        try? context.save()
        step = .firstMed
    }

    private func finish(addMed: Bool) {
        Router.shared.tab = .today
        // RootView opens the add flow once it is on screen.
        Router.shared.addMedAfterOnboarding = addMed
        onboarded = true
    }

    // MARK: Layout

    private var welcomeIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [theme.accentSoft.color, theme.surface.color],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .fill(theme.accent.color.opacity(0.14))
                .frame(width: 180, height: 180)
                .offset(x: 105, y: -85)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("NHẮC UỐNG THUỐC", systemImage: "bell.fill")
                        .appFont(.label)
                        .foregroundStyle(theme.accentSoftForeground.color)
                    Spacer()
                    Image(systemName: "pills.fill")
                        .foregroundStyle(theme.accentSoftForeground.color)
                }
                Spacer()
                Text("07:30")
                    .appFont(.display)
                    .monospacedDigit()
                    .foregroundStyle(theme.foreground.color)
                Text("Sáng, sau khi ăn")
                    .appFont(.headline)
                    .foregroundStyle(theme.foreground.color)
                HStack(spacing: 10) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.accentSoftForeground.color)
                        .frame(width: 50, height: 50)
                        .background(RoundedRectangle(cornerRadius: 14).fill(theme.accentSoft.color))
                    Text("Đúng thuốc, đúng lúc")
                        .appFont(.secondary)
                        .foregroundStyle(theme.foreground.color)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(theme.accentSoftForeground.color)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 18).fill(theme.cardBackground.color))
            }
            .padding(22)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: theme.accent.color.opacity(0.12), radius: 20, y: 10)
        .accessibilityHidden(true)
    }

    private var stepNumber: Int {
        switch step {
        case .welcome: 1
        case .routine: 2
        case .firstMed: 3
        }
    }

    private func hero(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 44, weight: .medium))
            .foregroundStyle(theme.accentSoftForeground.color)
            .frame(width: 92, height: 92)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [theme.accentSoft.color, theme.surface.color],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: theme.accent.color.opacity(0.10), radius: 10, y: 5))
            .padding(.bottom, 12)
            .accessibilityHidden(true)
    }

    private func page<Content: View>(primary: (String, () -> Void),
                                     primaryDisabled: Bool = false,
                                     secondary: (String, () -> Void)? = nil,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(stepNumber)/3")
                    .appFont(.label)
                    .foregroundStyle(theme.accentSoftForeground.color)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.defaultFill.color)
                        Capsule().fill(theme.accent.color)
                            .frame(width: geometry.size.width * CGFloat(stepNumber) / 3)
                    }
                }
                .frame(height: 5)
                .accessibilityLabel("Bước \(stepNumber) trên 3")
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) { content() }
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
                    .padding(.bottom, 24)
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
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(theme.background.color)
        }
    }
}
