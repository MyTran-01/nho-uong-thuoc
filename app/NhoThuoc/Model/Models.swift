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

@Model
final class Medication {
    var id = UUID()
    var name = ""
    /// "Dùng để làm gì": groups medications on the Thuốc tab. Empty = not given.
    var purpose = ""
    var formRaw = MedForm.tablet.rawValue
    var strength = ""
    var strengthUnitRaw = StrengthUnit.mg.rawValue
    var doseHalves = 2
    var frequencyRaw = Frequency.once.rawValue
    var customRaw = CustomSchedule.weekdays.rawValue
    var weekdaysData = Data()
    var everyNDays = 0
    var everyHours = 8
    var customTimesPerDay = 1
    var timingsData = Data()
    var photo: String?
    var isPaused = false
    var isFinished = false
    var finishedAt: Date?
    var createdAt = Date()
    var startDate = Date()

    init(draft: DraftMed) {
        id = draft.id
        apply(draft)
    }

    func apply(_ d: DraftMed) {
        name = d.name.trimmingCharacters(in: .whitespaces)
        purpose = d.purpose.trimmingCharacters(in: .whitespaces)
        formRaw = d.form.rawValue
        strength = d.strength.trimmingCharacters(in: .whitespaces)
        strengthUnitRaw = d.strengthUnit.rawValue
        doseHalves = d.doseHalves
        frequencyRaw = d.frequency.rawValue
        customRaw = d.custom.rawValue
        weekdays = d.weekdays
        everyNDays = d.everyNDays
        everyHours = d.everyHours
        customTimesPerDay = d.customTimesPerDay
        timings = d.timings
        photo = d.photo
    }

    var draft: DraftMed {
        DraftMed(id: id, name: name, purpose: purpose, form: form, strength: strength,
                 strengthUnit: StrengthUnit(rawValue: strengthUnitRaw) ?? .mg, doseHalves: doseHalves,
                 frequency: Frequency(rawValue: frequencyRaw) ?? .once,
                 custom: CustomSchedule(rawValue: customRaw) ?? .weekdays,
                 weekdays: weekdays, everyNDays: max(1, everyNDays), everyHours: everyHours,
                 customTimesPerDay: customTimesPerDay, timings: timings, photo: photo)
    }

    var form: MedForm { MedForm(rawValue: formRaw) ?? .tablet }
    var doseText: String { Dose.text(halves: doseHalves, form: form) }
    var isActive: Bool { !isPaused && !isFinished }

    var weekdays: Set<Int> {
        get { (try? JSONDecoder().decode(Set<Int>.self, from: weekdaysData)) ?? [] }
        set { weekdaysData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var timings: [Timing] {
        get { (try? JSONDecoder().decode([Timing].self, from: timingsData)) ?? [] }
        set { timingsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var info: MedInfo {
        let d = draft
        return MedInfo(id: id, name: name, doseText: doseText, frontPhoto: photo, backPhoto: nil,
                       purpose: purpose, form: form, timings: timings, everyNDays: d.engineEveryNDays,
                       weekdays: d.engineWeekdays, startDay: startDate,
                       sortIndex: Int(createdAt.timeIntervalSince1970), activeFrom: createdAt)
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
