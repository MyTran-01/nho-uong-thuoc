import Foundation
import Testing
@testable import NhoThuoc

// Fictional sample data mirroring PRD scenario A02 (2 prescriptions, 5 dose times a day).

private let cal = SlotEngine.calendar

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d))!
}

private func med(_ name: String, _ timings: [Timing], every: Int = 0, start: Date = day(2026, 11, 5), index: Int) -> MedInfo {
    MedInfo(id: UUID(), name: name, doseText: "1 viên", rxName: "Mẫu", timings: timings,
            everyNDays: every, startDay: start, sortIndex: index)
}

private let sampleMeds: [MedInfo] = [
    med("Thuốc A", [Timing(anchor: .breakfast, relation: .before)], index: 0),
    med("Thuốc B", [Timing(anchor: .breakfast, relation: .after), Timing(anchor: .dinner, relation: .after)], index: 1),
    med("Thuốc C", [Timing(anchor: .afternoon, relation: .at)], index: 2),
    med("Thuốc D", [Timing(anchor: .bed, relation: .before, offsetMinutes: 60, offsetSource: .rx)], index: 3),
    med("Vitamin C", [Timing(anchor: .breakfast, relation: .after)], index: 100),
    med("Kẽm", [Timing(anchor: .breakfast, relation: .after)], every: 1, index: 101),
    med("Omega-3", [Timing(anchor: .dinner, relation: .after)], index: 102),
]

@Suite("SlotEngine")
struct SlotEngineTests {
    // AC06
    @Test func sampleDayHasFiveDoseTimesAtTheRightClock() {
        let slots = SlotEngine.slots(day: day(2026, 11, 5), routine: RoutineTimes(), meds: sampleMeds)
        #expect(slots.map(\.timeText) == ["6:30", "7:15", "15:00", "19:15", "22:00"])
        #expect(slots.map(\.title) == ["Sáng, trước khi ăn", "Sáng, sau khi ăn", "Buổi chiều", "Tối, sau khi ăn", "Trước khi ngủ"])
        #expect(slots[1].items.map(\.name) == ["Thuốc B", "Vitamin C", "Kẽm"])
        #expect(slots[3].items.map(\.name) == ["Thuốc B", "Omega-3"])
    }

    // AC07
    @Test func everyOtherDayAppearsOnlyOnScheduledDaysOver14Days() {
        for offset in 0..<14 {
            let d = cal.date(byAdding: .day, value: offset, to: day(2026, 11, 5))!
            let slots = SlotEngine.slots(day: d, routine: RoutineTimes(), meds: sampleMeds)
            let hasZinc = slots.flatMap(\.items).contains { $0.name == "Kẽm" }
            #expect(hasZinc == offset.isMultiple(of: 2), "day +\(offset)")
            #expect(slots.count == 5, "day +\(offset)")
        }
    }

    @Test func notDueBeforeStartDay() {
        let m = med("Mới", [Timing(anchor: .lunch, relation: .after)], start: day(2026, 11, 10), index: 0)
        #expect(SlotEngine.slots(day: day(2026, 11, 9), routine: RoutineTimes(), meds: [m]).isEmpty)
        #expect(SlotEngine.slots(day: day(2026, 11, 10), routine: RoutineTimes(), meds: [m]).count == 1)
    }

    @Test func beforeAndAfterMealAreNeverMerged() {
        // 30 minutes before lunch 12:30 and right after breakfast... craft a same-minute clash:
        var r = RoutineTimes()
        r.breakfast = 7 * 60
        r.lunch = 7 * 60 + 30
        let a = med("Trước trưa", [Timing(anchor: .lunch, relation: .before, offsetMinutes: 15)], index: 0)   // 7:15
        let b = med("Sau sáng", [Timing(anchor: .breakfast, relation: .after, offsetMinutes: 15)], index: 1)   // 7:15
        let slots = SlotEngine.slots(day: day(2026, 11, 5), routine: r, meds: [a, b])
        #expect(slots.count == 2)
    }

    @Test func sameClockTimeDifferentAnchorsMerge() {
        let a = med("Chiều", [Timing(anchor: .afternoon, relation: .at)], index: 0)
        var r = RoutineTimes()
        r.lunch = 14 * 60 + 45
        let b = med("Sau trưa", [Timing(anchor: .lunch, relation: .after)], index: 1) // 15:00
        let slots = SlotEngine.slots(day: day(2026, 11, 5), routine: r, meds: [a, b])
        #expect(slots.count == 1)
        #expect(slots[0].items.count == 2)
    }

    // AC20: bed time after midnight stays on the same drug day.
    @Test func bedAfterMidnightBelongsToTheSameDrugDay() {
        var r = RoutineTimes()
        r.bed = 30 // 0:30
        let d = med("Trước ngủ", [Timing(anchor: .bed, relation: .before, offsetMinutes: 60)], index: 0)
        let slots = SlotEngine.slots(day: day(2026, 11, 5), routine: r, meds: [d])
        #expect(slots.count == 1)
        #expect(slots[0].timeText == "23:30")
        #expect(slots[0].dayKey == "2026-11-05")

        r.bed = 60 // 1:00 → 30 minutes before is 0:30 next calendar day
        let half = med("Trước ngủ", [Timing(anchor: .bed, relation: .before, offsetMinutes: 30)], index: 0)
        let s2 = SlotEngine.slots(day: day(2026, 11, 5), routine: r, meds: [half])
        #expect(s2.count == 1)
        #expect(s2[0].timeText == "0:30")
        #expect(s2[0].dayKey == "2026-11-05")
        #expect(cal.component(.day, from: s2[0].date) == 6)
    }

    @Test func drugDayBeforeBedAfterMidnightIsYesterday() {
        var r = RoutineTimes()
        r.bed = 60
        let at0040 = cal.date(bySettingHour: 0, minute: 40, second: 0, of: day(2026, 11, 6))!
        #expect(SlotEngine.dayKey(SlotEngine.drugDay(for: at0040, routine: r)) == "2026-11-05")
        let at0800 = cal.date(bySettingHour: 8, minute: 0, second: 0, of: day(2026, 11, 6))!
        #expect(SlotEngine.dayKey(SlotEngine.drugDay(for: at0800, routine: r)) == "2026-11-06")
    }

    @Test func dosesBeforeActivationAreHidden() {
        var m = med("Mới thêm", [Timing(anchor: .breakfast, relation: .after), Timing(anchor: .dinner, relation: .after)], index: 0)
        m.activeFrom = cal.date(bySettingHour: 18, minute: 0, second: 0, of: day(2026, 11, 5))!
        let today = SlotEngine.slots(day: day(2026, 11, 5), routine: RoutineTimes(), meds: [m])
        #expect(today.map(\.timeText) == ["19:15"])
        let tomorrow = SlotEngine.slots(day: day(2026, 11, 6), routine: RoutineTimes(), meds: [m])
        #expect(tomorrow.count == 2)
    }

    @Test func missedAtIsNextSlotOrThreeHours() {
        let slots = SlotEngine.slots(day: day(2026, 11, 5), routine: RoutineTimes(), meds: sampleMeds)
        #expect(SlotEngine.missedAt(slots[0], next: slots[1]) == slots[1].date)
        #expect(SlotEngine.missedAt(slots[4], next: nil) == slots[4].date.addingTimeInterval(3 * 3600))
    }
}

@Suite("Notifications")
struct NotificationPlanTests {
    @Test func neverMoreThan64Pending() {
        let routine = RoutineTimes()
        let slots = (0...2).flatMap { off in
            SlotEngine.slots(day: cal.date(byAdding: .day, value: off, to: day(2026, 11, 5))!, routine: routine, meds: sampleMeds)
        }
        let now = cal.date(bySettingHour: 5, minute: 0, second: 0, of: day(2026, 11, 5))!
        let plan = NotificationScheduler.plan(slots: slots, isMarked: { _ in false }, now: now)
        #expect(plan.count <= 64)
        #expect(plan.count == 60) // 15 dose times × 4
        #expect(plan.first?.id.hasSuffix("#0") == true)
    }

    @Test func markedDoseTimesAreNotReminded() {
        let slots = SlotEngine.slots(day: day(2026, 11, 5), routine: RoutineTimes(), meds: sampleMeds)
        let now = cal.date(bySettingHour: 5, minute: 0, second: 0, of: day(2026, 11, 5))!
        let marked = slots[0].key
        let plan = NotificationScheduler.plan(slots: slots, isMarked: { $0 == marked }, now: now)
        #expect(!plan.contains { $0.slot.key == marked })
        #expect(plan.count == 16)
    }

    @Test func repeatsEveryTenMinutesThreeTimes() {
        let slots = SlotEngine.slots(day: day(2026, 11, 5), routine: RoutineTimes(), meds: sampleMeds)
        let now = cal.date(bySettingHour: 5, minute: 0, second: 0, of: day(2026, 11, 5))!
        let plan = NotificationScheduler.plan(slots: [slots[0]], isMarked: { _ in false }, now: now)
        #expect(plan.map { $0.fire.timeIntervalSince(slots[0].date) } == [0, 600, 1200, 1800])
    }
}
