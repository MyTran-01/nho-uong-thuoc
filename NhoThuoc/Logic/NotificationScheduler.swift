import Foundation
import SwiftData
import UserNotifications

/// Local notifications for dose times. iOS keeps at most 64 pending requests,
/// so only the next few days are scheduled and the list is rebuilt often.
@MainActor
enum NotificationScheduler {
    /// Phase 1 (06/11/2026): notifications are not part of this phase, so their UI is hidden
    /// (Today banner, Settings "Nhắc nhở"). Scheduling code stays; set to true to bring it back.
    static let showsUI = false

    static let category = "DOSE_TIME"
    static let takenAllAction = "TAKEN_ALL"
    static let repeats = 3
    static let repeatInterval: TimeInterval = 10 * 60
    static let maxPending = 64
    static let showNamesKey = "showNamesOnLockScreen"

    static func registerCategories() {
        let taken = UNNotificationAction(identifier: takenAllAction, title: "Đã dùng đủ", options: [])
        let cat = UNNotificationCategory(identifier: category, actions: [taken], intentIdentifiers: [],
                                         hiddenPreviewsBodyPlaceholder: "Tới giờ dùng thuốc rồi",
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
        c.title = "Tới giờ dùng thuốc rồi"
        // Q7: by default no medication names, the lock screen is visible to others.
        if UserDefaults.standard.bool(forKey: showNamesKey) {
            c.body = "\(slot.title): " + slot.items.map { "\($0.name) \($0.doseText.lowercased())" }.joined(separator: ", ")
        } else {
            c.body = "\(slot.title) · \(slot.items.count) thuốc"
        }
        c.sound = .default
        c.categoryIdentifier = category
        c.threadIdentifier = slot.key
        c.userInfo = ["slotKey": slot.key]
        c.interruptionLevel = .timeSensitive
        return c
    }

    nonisolated struct Planned: Equatable, Sendable {
        let id: String
        let fire: Date
        let slot: Slot
    }

    /// Pure planning step: which reminders to schedule, earliest first, capped at 64.
    /// The first reminder of a dose time fires at its time, then every 10 minutes, 3 more times.
    nonisolated static func plan(slots: [Slot], isMarked: (String) -> Bool, now: Date,
                                 repeats: Int = 3, interval: TimeInterval = 600, limit: Int = 64) -> [Planned] {
        var out: [Planned] = []
        for slot in slots where !isMarked(slot.key) {
            for n in 0...repeats {
                let fire = slot.date.addingTimeInterval(Double(n) * interval)
                if fire > now { out.append(Planned(id: "\(slot.key)#\(n)", fire: fire, slot: slot)) }
            }
        }
        return Array(out.sorted { $0.fire < $1.fire }.prefix(limit))
    }

    /// Rebuilds every pending reminder from current data.
    static func reschedule(now: Date = .now, in context: ModelContext = AppStore.context) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let slots = AppStore.slots(around: now, extraDays: 2, in: context)
        let marked = Set(((try? context.fetch(FetchDescriptor<DoseLog>())) ?? []).map(\.slotKey))
        for p in plan(slots: slots, isMarked: { marked.contains($0) }, now: now,
                      repeats: repeats, interval: repeatInterval, limit: maxPending) {
            let comps = SlotEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: p.fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: p.id, content: content(for: p.slot), trigger: trigger))
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
    static func sendTest(for slot: Slot, after seconds: TimeInterval = 8) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "\(slot.key)#test", content: content(for: slot), trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
