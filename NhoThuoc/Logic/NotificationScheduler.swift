import Foundation
import SwiftData
import UserNotifications

/// Local notifications for dose times. iOS keeps at most 64 pending requests,
/// so only the next few days are scheduled and the list is rebuilt often.
@MainActor
enum NotificationScheduler {
    static let category = "DOSE_TIME"
    static let takenAllAction = "TAKEN_ALL"
    static let repeats = 3
    static let repeatInterval: TimeInterval = 10 * 60
    static let maxPending = 64

    static func registerCategories() {
        let taken = UNNotificationAction(identifier: takenAllAction, title: "Đã uống đủ", options: [])
        let cat = UNNotificationCategory(identifier: category, actions: [taken], intentIdentifiers: [],
                                         hiddenPreviewsBodyPlaceholder: "Tới giờ uống thuốc rồi",
                                         options: [])
        UNUserNotificationCenter.current().setNotificationCategories([cat])
    }

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func isAuthorized() async -> Bool {
        let s = await UNUserNotificationCenter.current().notificationSettings()
        return s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
    }

    static func content(for slot: Slot) -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        c.title = "Tới giờ uống thuốc rồi"
        // No medication names: the lock screen is visible to others (Q7).
        c.body = "\(slot.title) (\(slot.items.count) loại thuốc)"
        c.sound = .default
        c.categoryIdentifier = category
        c.threadIdentifier = slot.key
        c.userInfo = ["slotKey": slot.key]
        c.interruptionLevel = .timeSensitive
        return c
    }

    /// Rebuilds every pending reminder from current data.
    static func reschedule(now: Date = .now, in context: ModelContext = AppStore.context) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let slots = AppStore.slots(around: now, extraDays: 2, in: context)
        var requests: [(Date, UNNotificationRequest)] = []
        for slot in slots where AppStore.log(forKey: slot.key, in: context) == nil {
            let c = content(for: slot)
            for n in 0...repeats {
                let fire = slot.date.addingTimeInterval(Double(n) * repeatInterval)
                guard fire > now else { continue }
                let comps = SlotEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                requests.append((fire, UNNotificationRequest(identifier: "\(slot.key)#\(n)", content: c, trigger: trigger)))
            }
        }
        for (_, r) in requests.sorted(by: { $0.0 < $1.0 }).prefix(maxPending) {
            center.add(r)
        }
    }

    static func cancel(slotKey: String) {
        let ids = (0...repeats).map { "\(slotKey)#\($0)" } + ["\(slotKey)#test"]
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.getDeliveredNotifications { delivered in
            let match = delivered.filter { ($0.request.content.userInfo["slotKey"] as? String) == slotKey }
                .map(\.request.identifier)
            center.removeDeliveredNotifications(withIdentifiers: match)
        }
    }

    /// Sends a real reminder for `slot` in a few seconds (to try the flow).
    static func sendTest(for slot: Slot, after seconds: TimeInterval = 5) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "\(slot.key)#test", content: content(for: slot), trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
