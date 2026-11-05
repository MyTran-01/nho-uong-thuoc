import Foundation
import SwiftData

@Model
final class Routine {
    var breakfast = 7 * 60
    var lunch = 12 * 60
    var dinner = 19 * 60
    var bed = 23 * 60
    var afternoon = 15 * 60
    var beforeMeal = 30
    var afterMeal = 15
    var beforeBed = 60

    init() {}

    var times: RoutineTimes {
        get {
            RoutineTimes(breakfast: breakfast, lunch: lunch, dinner: dinner, bed: bed, afternoon: afternoon,
                         beforeMeal: beforeMeal, afterMeal: afterMeal, beforeBed: beforeBed)
        }
        set {
            breakfast = newValue.breakfast; lunch = newValue.lunch; dinner = newValue.dinner; bed = newValue.bed
            afternoon = newValue.afternoon; beforeMeal = newValue.beforeMeal; afterMeal = newValue.afterMeal
            beforeBed = newValue.beforeBed
        }
    }
}

enum PrescriptionStatus: String {
    case active, paused, ended
}

@Model
final class Prescription {
    var id = UUID()
    var name: String
    var photoFile: String?
    var createdAt = Date()
    var startDate = Date()
    var statusRaw = PrescriptionStatus.active.rawValue
    @Relationship(deleteRule: .cascade, inverse: \Medication.prescription)
    var medications: [Medication] = []

    init(name: String, photoFile: String?, startDate: Date) {
        self.name = name
        self.photoFile = photoFile
        self.startDate = startDate
    }

    var status: PrescriptionStatus {
        get { PrescriptionStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var sortedMedications: [Medication] { medications.sorted { $0.sortIndex < $1.sortIndex } }
}

@Model
final class Medication {
    var id = UUID()
    var nameOnRx: String
    var displayName: String
    var isFinished = false
    var finishedAt: Date?
    var frontPhoto: String?
    var backPhoto: String?
    var doseHalves = 2
    var unitRaw = DoseUnit.vien.rawValue
    var timingsData = Data()
    var everyNDays = 0
    var startDate = Date()
    var sortIndex = 0
    var prescription: Prescription?

    init(draft: DraftMed, startDate: Date, sortIndex: Int) {
        self.id = draft.id
        self.nameOnRx = draft.nameOnRx
        self.displayName = draft.displayName
        self.startDate = startDate
        self.sortIndex = sortIndex
        apply(draft)
    }

    func apply(_ draft: DraftMed) {
        displayName = draft.displayName.trimmingCharacters(in: .whitespaces).isEmpty ? draft.nameOnRx : draft.displayName
        doseHalves = draft.doseHalves
        unitRaw = draft.unit.rawValue
        timings = draft.timings
        everyNDays = draft.everyNDays
    }

    var draft: DraftMed {
        DraftMed(id: id, nameOnRx: nameOnRx, displayName: displayName, doseHalves: doseHalves,
                 unit: unit, timings: timings, everyNDays: everyNDays)
    }

    var unit: DoseUnit { DoseUnit(rawValue: unitRaw) ?? .vien }
    var doseText: String { Dose.text(halves: doseHalves, unit: unit) }

    var timings: [Timing] {
        get { (try? JSONDecoder().decode([Timing].self, from: timingsData)) ?? [] }
        set { timingsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var hasPhotos: Bool { frontPhoto != nil && backPhoto != nil }

    var info: MedInfo {
        MedInfo(id: id, name: displayName, doseText: doseText, frontPhoto: frontPhoto, backPhoto: backPhoto,
                rxName: prescription?.name ?? "", timings: timings, everyNDays: everyNDays,
                startDay: startDate, sortIndex: (prescription.map { Int($0.createdAt.timeIntervalSince1970) } ?? 0) * 100 + sortIndex,
                activeFrom: prescription?.createdAt ?? .distantPast)
    }
}

enum DoseStatus: String, Codable {
    case taken, partial, skipped
}

/// Snapshot of one medication at the moment the dose was marked (M11).
struct DoseLogItem: Codable, Hashable {
    var medID: UUID
    var name: String
    var doseText: String
    var frontPhoto: String?
    var backPhoto: String?
    var taken: Bool
}

@Model
final class DoseLog {
    @Attribute(.unique) var slotKey: String
    var dayKey: String
    var title: String
    var scheduledAt: Date
    var recordedAt: Date
    var statusRaw: String
    var itemsData: Data

    init(slot: Slot, status: DoseStatus, items: [DoseLogItem], recordedAt: Date = .now) {
        slotKey = slot.key
        dayKey = slot.dayKey
        title = slot.title
        scheduledAt = slot.date
        self.recordedAt = recordedAt
        statusRaw = status.rawValue
        itemsData = (try? JSONEncoder().encode(items)) ?? Data()
    }

    var status: DoseStatus {
        get { DoseStatus(rawValue: statusRaw) ?? .taken }
        set { statusRaw = newValue.rawValue }
    }

    var items: [DoseLogItem] {
        get { (try? JSONDecoder().decode([DoseLogItem].self, from: itemsData)) ?? [] }
        set { itemsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var missingCount: Int { items.filter { !$0.taken }.count }
}
