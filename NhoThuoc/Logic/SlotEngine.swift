import Foundation

/// One medication inside a dose time.
nonisolated struct SlotItem: Codable, Hashable, Sendable {
    var medID: UUID
    var name: String
    var doseText: String
    var frontPhoto: String?
    var backPhoto: String?
    var rxName: String
}

/// A dose time ("giờ uống thuốc"). Computed, never stored.
nonisolated struct Slot: Identifiable, Hashable, Sendable {
    let key: String
    let dayKey: String
    let date: Date
    let minuteOfDrugDay: Int
    let anchor: Anchor
    let relation: Relation
    let items: [SlotItem]

    var id: String { key }
    var title: String { SlotEngine.title(anchor: anchor, relation: relation) }
    var timeText: String { Clock.text(minuteOfDrugDay) }
}

nonisolated enum SlotEngine {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "vi_VN")
        return c
    }()

    static func dayKey(_ day: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// The drug day ends at bed time, not at midnight.
    static func drugDay(for now: Date, routine: RoutineTimes) -> Date {
        let start = calendar.startOfDay(for: now)
        let minute = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        if routine.bed < routine.breakfast, minute < routine.bed {
            return calendar.date(byAdding: .day, value: -1, to: start)!
        }
        return start
    }

    static func minute(of timing: Timing, routine: RoutineTimes) -> Int {
        func meal(_ base: Int) -> Int {
            switch timing.relation {
            case .before: base - (timing.offsetMinutes ?? routine.beforeMeal)
            case .after: base + (timing.offsetMinutes ?? routine.afterMeal)
            case .during, .at: base
            }
        }
        switch timing.anchor {
        case .breakfast: return meal(routine.breakfast)
        case .lunch: return meal(routine.lunch)
        case .dinner: return meal(routine.dinner)
        case .afternoon: return routine.afternoon
        case .bed: return routine.bedOnDrugDay - (timing.offsetMinutes ?? routine.beforeBed)
        }
    }

    static func isDue(_ med: MedInfo, on day: Date) -> Bool {
        let start = calendar.startOfDay(for: med.startDay)
        let diff = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: day)).day ?? 0
        if diff < 0 { return false }
        return diff % (med.everyNDays + 1) == 0
    }

    /// Groups every due timing of every active medication into dose times.
    /// Merge rule: same anchor + same relation, or the same clock time,
    /// but never "before meal" with "after meal".
    static func slots(day: Date, routine: RoutineTimes, meds: [MedInfo]) -> [Slot] {
        struct Group { var anchor: Anchor; var relation: Relation; var minute: Int; var items: [(Int, SlotItem)] }
        var groups: [String: Group] = [:]
        let dayStart = calendar.startOfDay(for: day)
        for med in meds where isDue(med, on: day) {
            let item = SlotItem(medID: med.id, name: med.name, doseText: med.doseText,
                                frontPhoto: med.frontPhoto, backPhoto: med.backPhoto, rxName: med.rxName)
            for timing in Set(med.timings) {
                let m = minute(of: timing, routine: routine)
                if dayStart.addingTimeInterval(Double(m) * 60) < med.activeFrom { continue }
                let key = timing.groupKey
                if var g = groups[key] {
                    g.minute = min(g.minute, m)
                    if !g.items.contains(where: { $0.1.medID == med.id }) { g.items.append((med.sortIndex, item)) }
                    groups[key] = g
                } else {
                    groups[key] = Group(anchor: timing.anchor, relation: timing.relation, minute: m, items: [(med.sortIndex, item)])
                }
            }
        }

        // Merge groups that land on the same minute, unless before/after would mix.
        var merged: [Group] = []
        for g in groups.values.sorted(by: { ($0.minute, $0.anchor.rawValue) < ($1.minute, $1.anchor.rawValue) }) {
            if let i = merged.lastIndex(where: { $0.minute == g.minute && compatible($0.relation, g.relation) }) {
                for it in g.items where !merged[i].items.contains(where: { $0.1.medID == it.1.medID }) {
                    merged[i].items.append(it)
                }
            } else {
                merged.append(g)
            }
        }

        let dk = dayKey(day)
        let start = calendar.startOfDay(for: day)
        return merged
            .sorted { $0.minute < $1.minute }
            .map { g in
                Slot(key: "\(dk)#\(g.anchor.rawValue)-\(g.relation.rawValue)",
                     dayKey: dk,
                     date: calendar.date(byAdding: .minute, value: g.minute, to: start)!,
                     minuteOfDrugDay: g.minute,
                     anchor: g.anchor, relation: g.relation,
                     items: g.items.sorted { $0.0 < $1.0 }.map(\.1))
            }
    }

    private static func compatible(_ a: Relation, _ b: Relation) -> Bool {
        !((a == .before && b == .after) || (a == .after && b == .before))
    }

    static func title(anchor: Anchor, relation: Relation) -> String {
        let meal: String
        switch anchor {
        case .breakfast: meal = "Sáng"
        case .lunch: meal = "Trưa"
        case .dinner: meal = "Tối"
        case .afternoon: return "Buổi chiều"
        case .bed: return "Trước khi ngủ"
        }
        switch relation {
        case .before: return "\(meal), trước khi ăn"
        case .during: return "\(meal), trong bữa ăn"
        case .after, .at: return "\(meal), sau khi ăn"
        }
    }

    /// Q8: a dose time counts as not marked at the next dose time or after 3 hours.
    static func missedAt(_ slot: Slot, next: Slot?) -> Date {
        let limit = slot.date.addingTimeInterval(3 * 3600)
        guard let next else { return limit }
        return min(limit, next.date)
    }
}
