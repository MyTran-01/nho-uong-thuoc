import Foundation

// Plain value types shared by the slot engine and the UI.
// Foundation-only so the logic can be exercised outside the app.

nonisolated enum Anchor: String, Codable, CaseIterable, Hashable, Sendable {
    case breakfast, lunch, afternoon, dinner, bed
    /// A clock time that does not follow the routine; the minute is in `Timing.offsetMinutes`.
    case fixed
}

nonisolated enum Relation: String, Codable, Hashable, Sendable {
    case before, during, after, at
}

nonisolated enum OffsetSource: String, Codable, Hashable, Sendable {
    case rx, standard, user
}

nonisolated struct Timing: Codable, Hashable, Sendable {
    var anchor: Anchor
    var relation: Relation
    /// nil = use the routine default for this relation. For `.fixed`: minute after midnight.
    var offsetMinutes: Int?
    var offsetSource: OffsetSource = .standard

    /// A medication taken at 9:00 and another at 9:00 share a dose time; 9:00 and 13:00 do not.
    var groupKey: String {
        anchor == .fixed ? "fixed-\(offsetMinutes ?? 0)" : "\(anchor.rawValue)-\(relation.rawValue)"
    }

    static func fixed(_ minute: Int) -> Timing {
        Timing(anchor: .fixed, relation: .at, offsetMinutes: minute, offsetSource: .user)
    }

    /// Default relation when a part of the day is picked.
    static func standard(_ anchor: Anchor) -> Timing {
        switch anchor {
        case .afternoon: Timing(anchor: .afternoon, relation: .at)
        case .bed: Timing(anchor: .bed, relation: .before)
        case .fixed: .fixed(9 * 60)
        default: Timing(anchor: anchor, relation: .after)
        }
    }
}

// MARK: Kind of medication

nonisolated enum MedForm: String, Codable, CaseIterable, Hashable, Sendable {
    case tablet, capsule, liquid, drops, injection, cream, inhaler, other

    /// Name on the picker grid.
    var label: String {
        switch self {
        case .tablet: "Viên nén"
        case .capsule: "Viên nang"
        case .liquid: "Dung dịch"
        case .drops: "Giọt"
        case .injection: "Tiêm"
        case .cream: "Kem bôi"
        case .inhaler: "Ống hít"
        case .other: "Khác"
        }
    }

    var symbol: String {
        switch self {
        case .tablet: "pill.fill"
        case .capsule: "pills.fill"
        case .liquid: "drop.fill"
        case .drops: "eyedropper"
        case .injection: "syringe.fill"
        case .cream: "bandage.fill"
        case .inhaler: "wind"
        case .other: "cross.case.fill"
        }
    }

    /// What one dose is counted in.
    var unit: String {
        switch self {
        case .tablet: "viên nén"
        case .capsule: "viên nang"
        case .liquid: "ml"
        case .drops: "giọt"
        case .injection: "mũi tiêm"
        case .cream: "lần bôi"
        case .inhaler: "nhát xịt"
        case .other: "liều"
        }
    }

    /// Step of the − / + buttons, in halves (1 = ½).
    var stepHalves: Int {
        switch self {
        case .tablet: 1          // ½ viên
        case .liquid: 5          // 2,5 ml
        default: 2               // 1
        }
    }

    /// Amount picked when switching to this kind.
    var defaultHalves: Int { self == .liquid ? 10 : 2 }
}

nonisolated enum StrengthUnit: String, Codable, CaseIterable, Hashable, Sendable {
    case mg, mcg, g, ml, iu, percent

    var label: String {
        switch self {
        case .mg: "mg"
        case .mcg: "mcg"
        case .g: "g"
        case .ml: "ml"
        case .iu: "IU"
        case .percent: "%"
        }
    }
}

nonisolated enum Dose {
    /// Amount is stored in halves (1 = ½) so "nửa viên" stays exact.
    static func text(halves: Int, form: MedForm) -> String {
        let whole = halves / 2
        let half = halves % 2 == 1
        if form == .liquid { return half ? "\(whole),5 ml" : "\(whole) ml" }
        if !half { return "\(max(1, whole)) \(form.unit)" }
        return whole == 0 ? "½ \(form.unit)" : "\(whole)½ \(form.unit)"
    }

    /// Snaps an amount to the kind's step, never below one step.
    static func snapped(_ halves: Int, form: MedForm) -> Int {
        let step = form.stepHalves
        return max(step, (halves / step) * step)
    }
}

// MARK: How often

nonisolated enum Frequency: String, Codable, CaseIterable, Hashable, Sendable {
    case once, twice, thrice, custom

    var timesPerDay: Int {
        switch self {
        case .once: 1
        case .twice: 2
        case .thrice: 3
        case .custom: 1
        }
    }
}

nonisolated enum CustomSchedule: String, Codable, CaseIterable, Hashable, Sendable {
    /// Only on some weekdays.
    case weekdays
    /// Every other day, every third day…
    case everyNDays
    /// Every few hours, from a start time until bed.
    case everyHours

    var label: String {
        switch self {
        case .weekdays: "Một số ngày"
        case .everyNDays: "Cách vài ngày"
        case .everyHours: "Vài giờ một lần"
        }
    }
}

nonisolated enum Weekday {
    /// Calendar weekday numbers (1 = Sunday) in Vietnamese order, Monday first.
    static let order = [2, 3, 4, 5, 6, 7, 1]

    static func short(_ day: Int) -> String { day == 1 ? "CN" : "T\(day)" }
}

/// The user's daily routine, in minutes after midnight.
nonisolated struct RoutineTimes: Codable, Equatable, Sendable {
    var breakfast = 7 * 60
    var lunch = 12 * 60
    var dinner = 19 * 60
    var bed = 23 * 60
    var afternoon = 15 * 60
    var beforeMeal = 30
    var afterMeal = 15
    var beforeBed = 60

    /// Bed time on the drug-day clock: after midnight means > 24h.
    var bedOnDrugDay: Int { bed < breakfast ? bed + 24 * 60 : bed }
}

nonisolated enum Clock {
    static func text(_ minutes: Int) -> String {
        let m = ((minutes % 1440) + 1440) % 1440
        return String(format: "%d:%02d", m / 60, m % 60)
    }
}

/// A medication as the slot engine needs it.
nonisolated struct MedInfo: Hashable, Sendable {
    var id: UUID
    var name: String
    var doseText: String
    var frontPhoto: String?
    var backPhoto: String?
    /// "Dùng để làm gì" (acne, blood pressure…). Empty when not given.
    var purpose: String
    var form: MedForm = .tablet
    var timings: [Timing]
    /// 0 = every day, 1 = every other day, 2 = every third day.
    var everyNDays: Int
    /// Calendar weekdays (1 = Sunday). Empty = every day.
    var weekdays: Set<Int> = []
    var startDay: Date
    var sortIndex: Int
    /// Dose times before this moment are not shown (e.g. the medication was added at 18:00,
    /// so the morning doses of that day are not "missed").
    var activeFrom: Date = .distantPast
}

/// A medication being added or edited, before it is saved.
nonisolated struct DraftMed: Identifiable, Hashable, Sendable {
    var id = UUID()
    var name = ""
    var purpose = ""
    var form: MedForm = .tablet
    var strength = ""
    var strengthUnit: StrengthUnit = .mg
    var doseHalves = 2
    var frequency: Frequency = .once
    var custom: CustomSchedule = .weekdays
    var weekdays: Set<Int> = [2, 4, 6]
    var everyNDays = 1
    var everyHours = 8
    /// How many times a day on the chosen days (custom weekdays / every N days).
    var customTimesPerDay = 1
    var timings: [Timing] = [Timing(anchor: .breakfast, relation: .after)]
    var photo: String?

    var doseText: String { Dose.text(halves: doseHalves, form: form) }

    var strengthText: String? {
        let s = strength.trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? nil : "\(s) \(strengthUnit.label)"
    }

    /// Times per day the chosen schedule asks for (every-few-hours is computed from the routine).
    var timesPerDay: Int {
        frequency == .custom ? customTimesPerDay : frequency.timesPerDay
    }

    /// Days the medication is taken, in words.
    var scheduleText: String {
        switch frequency {
        case .once: return "Mỗi ngày 1 lần"
        case .twice: return "Mỗi ngày 2 lần"
        case .thrice: return "Mỗi ngày 3 lần"
        case .custom:
            switch custom {
            case .weekdays:
                let days = Weekday.order.filter { weekdays.contains($0) }.map(Weekday.short).joined(separator: ", ")
                return "\(days) · \(customTimesPerDay) lần mỗi ngày"
            case .everyNDays:
                return "Cách \(everyNDays) ngày · \(customTimesPerDay) lần mỗi ngày"
            case .everyHours:
                return "Mỗi \(everyHours) tiếng"
            }
        }
    }

    /// Engine values for the schedule.
    var engineEveryNDays: Int { frequency == .custom && custom == .everyNDays ? everyNDays : 0 }
    var engineWeekdays: Set<Int> { frequency == .custom && custom == .weekdays ? weekdays : [] }
}

/// Suggested dose times, from the routine (PRD: times follow meals and bed).
nonisolated enum TimingSuggest {
    /// Meal-based defaults for N times a day, keeping what the user already set for the same meal.
    static func forCount(_ count: Int, keeping old: [Timing]) -> [Timing] {
        let anchors: [Anchor] = switch count {
        case 1: [.breakfast]
        case 2: [.breakfast, .dinner]
        default: [.breakfast, .lunch, .dinner]
        }
        return anchors.map { a in old.first { $0.anchor == a } ?? Timing.standard(a) }
    }

    /// Every `hours` hours from `start` (minute of day) until bed time, at least once.
    static func everyHours(_ hours: Int, start: Int, routine: RoutineTimes) -> [Timing] {
        let end = routine.bedOnDrugDay
        var out: [Timing] = []
        var m = start
        while out.isEmpty || m <= end {
            out.append(.fixed(m % 1440))
            m += max(1, hours) * 60
            if out.count >= 24 { break }
        }
        return out
    }
}
