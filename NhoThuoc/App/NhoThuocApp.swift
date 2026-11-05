import SwiftUI
import SwiftData
import UserNotifications

enum AppTab: Hashable {
    case today, prescriptions, history, settings
}

/// App-wide navigation state, also driven by notification taps.
@Observable
final class Router {
    static let shared = Router()

    var tab: AppTab = .today
    var openSlotKey: String?
    var addPrescription = false
    var toast: ToastMessage?
}

@main
struct NhoThuocApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("onboarded") private var onboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded {
                    RootView()
                } else {
                    OnboardingFlow()
                }
            }
            .environment(Router.shared)
            .environment(\.theme, Theme())
            .tint(Theme().accent.color)
            .preferredColorScheme(.light)
        }
        .modelContainer(AppStore.container)
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationScheduler.registerCategories()
        return true
    }

    // Show reminders even while the app is open.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let key = response.notification.request.content.userInfo["slotKey"] as? String
        let action = response.actionIdentifier
        guard let key else { return }
        await MainActor.run {
            if action == NotificationScheduler.takenAllAction {
                // E2: mark everything taken without opening the app.
                if let slot = AppStore.slot(forKey: key) {
                    AppStore.record(slot: slot, taken: Set(slot.items.map(\.medID)))
                }
            } else if action == UNNotificationDefaultActionIdentifier {
                // E1: open the dose screen for this exact dose time.
                Router.shared.tab = .today
                Router.shared.openSlotKey = key
            }
        }
    }
}

struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            Tab("Hôm nay", systemImage: "sun.max.fill", value: AppTab.today) { TodayView() }
            Tab("Đơn thuốc", systemImage: "doc.text.fill", value: AppTab.prescriptions) { PrescriptionListView() }
            Tab("Lịch sử", systemImage: "calendar", value: AppTab.history) { HistoryView() }
            Tab("Cài đặt", systemImage: "gearshape.fill", value: AppTab.settings) { SettingsView() }
        }
        .sheet(item: openSlot) { slot in
            DoseSessionView(slot: slot)
        }
        .fullScreenCover(isPresented: $router.addPrescription) {
            AddPrescriptionFlow()
        }
        .toast($router.toast)
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { NotificationScheduler.reschedule(in: context) }
        }
    }

    private var openSlot: Binding<Slot?> {
        Binding {
            router.openSlotKey.flatMap { AppStore.slot(forKey: $0, in: context) }
        } set: { newValue in
            router.openSlotKey = newValue?.key
        }
    }
}
