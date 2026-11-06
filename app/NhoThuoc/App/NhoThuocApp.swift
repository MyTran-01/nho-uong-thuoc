import SwiftUI
import SwiftData
import UserNotifications
import OSLog

nonisolated private let notifyLog = Logger(subsystem: "vn.nhothuoc.app", category: "notify")

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

    private static let pendingKey = "pendingSlotKey"
    private static let pendingAt = "pendingSlotAt"

    static func rememberPending(_ key: String) {
        UserDefaults.standard.set(key, forKey: pendingKey)
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: pendingAt)
    }

    /// A reminder tapped in the last 10 minutes that has not been shown yet.
    static func takePending() -> String? {
        let d = UserDefaults.standard
        defer { d.removeObject(forKey: pendingKey); d.removeObject(forKey: pendingAt) }
        guard let key = d.string(forKey: pendingKey),
              Date.now.timeIntervalSince1970 - d.double(forKey: pendingAt) < 600 else { return nil }
        return key
    }
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
        notifyLog.info("Notification response \(action, privacy: .public) for \(key ?? "nil", privacy: .public)")
        guard let key else { return }
        await MainActor.run {
            if action == NotificationScheduler.takenAllAction {
                // E2: mark everything taken without opening the app.
                if let slot = AppStore.slot(forKey: key) {
                    AppStore.record(slot: slot, taken: Set(slot.items.map(\.medID)))
                }
            } else if action == UNNotificationDefaultActionIdentifier {
                // E1: open the dose screen for this exact dose time.
                // Also remembered on disk, in case iOS ends the process before the window shows.
                Router.rememberPending(key)
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
        .sheet(item: $presented, onDismiss: { router.openSlotKey = nil }) { slot in
            DoseSessionView(slot: slot)
        }
        .onChange(of: router.openSlotKey) { presentPending() }
        .fullScreenCover(isPresented: $router.addPrescription) {
            AddPrescriptionFlow()
        }
        .toast($router.toast)
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                NotificationScheduler.reschedule(in: context)
                // A reminder tapped while the app was in the background sets the key
                // before the window is active; present it now.
                presentPending()
            }
        }
    }

    @State private var presented: Slot?

    private func presentPending() {
        if let saved = Router.takePending(), router.openSlotKey == nil {
            router.openSlotKey = saved
            return // onChange(of: openSlotKey) calls back in
        }
        notifyLog.info("presentPending key=\(router.openSlotKey ?? "nil", privacy: .public)")
        guard let key = router.openSlotKey, presented?.key != key else { return }
        guard let slot = AppStore.slot(forKey: key, in: context) else {
            router.openSlotKey = nil // the dose time no longer exists (e.g. medication finished)
            return
        }
        if presented == nil {
            presented = slot
        } else {
            // Another dose sheet is open: close it first, then show the new one.
            presented = nil
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))
                presented = slot
            }
        }
    }
}
