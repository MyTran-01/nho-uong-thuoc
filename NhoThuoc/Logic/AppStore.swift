import Foundation
import SwiftData
import UserNotifications

/// Shared data access used by the UI and by notification actions (which may run
/// while the app is in the background).
@MainActor
enum AppStore {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Routine.self, Prescription.self, Medication.self, DoseLog.self)
        } catch {
            fatalError("Could not open the data store: \(error)")
        }
    }()

    static var context: ModelContext { container.mainContext }

    static func routine(in context: ModelContext = context) -> Routine {
        if let r = try? context.fetch(FetchDescriptor<Routine>()).first { return r }
        let r = Routine()
        context.insert(r)
        return r
    }

    static func activeMeds(in context: ModelContext = context) -> [MedInfo] {
        let meds = (try? context.fetch(FetchDescriptor<Medication>())) ?? []
        return activeInfos(meds)
    }

    static func activeInfos(_ meds: [Medication]) -> [MedInfo] {
        meds.filter { !$0.isFinished && $0.prescription?.status == .active }.map(\.info)
    }

    /// Dose times for the drug day containing `now`, plus `extraDays` following days.
    static func slots(around now: Date, extraDays: Int = 0, in context: ModelContext = context) -> [Slot] {
        let routine = routine(in: context).times
        let meds = activeMeds(in: context)
        let today = SlotEngine.drugDay(for: now, routine: routine)
        return (0...extraDays).flatMap { offset in
            let day = SlotEngine.calendar.date(byAdding: .day, value: offset, to: today)!
            return SlotEngine.slots(day: day, routine: routine, meds: meds)
        }
    }

    static func slot(forKey key: String, in context: ModelContext = context) -> Slot? {
        let all = slots(around: .now.addingTimeInterval(-36 * 3600), extraDays: 3, in: context)
        return all.first { $0.key == key }
    }

    static func log(forKey key: String, in context: ModelContext = context) -> DoseLog? {
        var d = FetchDescriptor<DoseLog>(predicate: #Predicate { $0.slotKey == key })
        d.fetchLimit = 1
        return try? context.fetch(d).first
    }

    /// Creates or updates the single record for a dose time (unique slotKey, AC13).
    @discardableResult
    static func record(slot: Slot, taken: Set<UUID>, skipped: Bool = false, in context: ModelContext = context) -> DoseLog {
        let items = slot.items.map {
            DoseLogItem(medID: $0.medID, name: $0.name, doseText: $0.doseText,
                        frontPhoto: $0.frontPhoto, backPhoto: $0.backPhoto, taken: !skipped && taken.contains($0.medID))
        }
        let status: DoseStatus = skipped ? .skipped : (items.allSatisfy(\.taken) ? .taken : .partial)
        let entry: DoseLog
        if let existing = log(forKey: slot.key, in: context) {
            existing.items = items
            existing.status = status
            existing.recordedAt = .now
            entry = existing
        } else {
            entry = DoseLog(slot: slot, status: status, items: items)
            context.insert(entry)
        }
        try? context.save()
        NotificationScheduler.cancel(slotKey: slot.key)
        return entry
    }

    /// Removes everything (used by "Bắt đầu lại" in Settings).
    static func resetAll(in context: ModelContext = context) {
        try? context.delete(model: DoseLog.self)
        try? context.delete(model: Medication.self)
        try? context.delete(model: Prescription.self)
        try? context.delete(model: Routine.self)
        try? context.save()
        PhotoStore.removeAll()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
