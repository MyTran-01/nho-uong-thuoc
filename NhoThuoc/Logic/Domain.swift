import Foundation

// Plain value types shared by the slot engine, the prescription parser and the UI.
// Foundation-only so the logic can be exercised outside the app.

nonisolated enum Anchor: String, Codable, CaseIterable, Hashable, Sendable {
    case breakfast, lunch, afternoon, dinner, bed
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
    /// nil = use the routine default for this relation.
    var offsetMinutes: Int?
    var offsetSource: OffsetSource = .standard

    var groupKey: String { "\(anchor.rawValue)-\(relation.rawValue)" }
}

nonisolated enum DoseUnit: String, Codable, CaseIterable, Hashable, Sendable {
    case vien, goi, ml, giot, lanBoi

    var label: String {
        switch self {
        case .vien: "viên"
        case .goi: "gói"
        case .ml: "ml"
        case .giot: "giọt"
        case .lanBoi: "lần bôi"
        }
    }
}

nonisolated enum Dose {
    /// Amount is stored in halves (1 = ½) so "nửa viên" stays exact.
    static func text(halves: Int, unit: DoseUnit) -> String {
        if halves == 1 { return "Nửa \(unit.label)" }
        if halves % 2 == 0 { return "\(halves / 2) \(unit.label)" }
        return "\(halves / 2) \(unit.label) rưỡi"
    }
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
    var rxName: String
    var timings: [Timing]
    /// 0 = every day, 1 = every other day, 2 = every third day.
    var everyNDays: Int
    var startDay: Date
    var sortIndex: Int
    /// Dose times before this moment are not shown (e.g. the prescription was added at 18:00,
    /// so the morning doses of that day are not "missed").
    var activeFrom: Date = .distantPast
}

/// A medication proposed from a prescription photo, still editable.
nonisolated struct DraftMed: Identifiable, Hashable, Sendable {
    var id = UUID()
    var nameOnRx: String
    var displayName: String
    var doseHalves = 2
    var unit: DoseUnit = .vien
    var timings: [Timing] = [Timing(anchor: .breakfast, relation: .after)]
    var everyNDays = 0
}
