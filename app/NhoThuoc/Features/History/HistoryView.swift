import SwiftUI
import SwiftData

/// Result of one drug day, shown by shape as well as colour (AC17).
enum DayResult {
    case allTaken, somethingMissing, skippedOrNotMarked, none, upcoming

    var symbol: String {
        switch self {
        case .allTaken: "✓"
        case .somethingMissing: "◐"
        case .skippedOrNotMarked: "✕"
        case .none, .upcoming: ""
        }
    }

    var label: String {
        switch self {
        case .allTaken: "Uống đủ"
        case .somethingMissing: "Có thuốc chưa uống"
        case .skippedOrNotMarked: "Có lần bỏ cữ hoặc chưa đánh dấu"
        case .none: "Không có thuốc"
        case .upcoming: "Chưa tới"
        }
    }
}

/// One row on the day screen: a dose time with its record, if any.
struct DayEntry: Identifiable {
    let key: String
    let date: Date
    let title: String
    let log: DoseLog?
    let state: SlotState
    let openable: Bool
    var id: String { key }
}

enum HistoryModel {
    /// Dose times of a past or current day: computed slots merged with saved records.
    @MainActor
    static func entries(for day: Date, logs: [DoseLog], context: ModelContext, now: Date = .now) -> [DayEntry] {
        let dk = SlotEngine.dayKey(day)
        let slots = AppStore.slots(on: day, in: context)
        let dayLogs = logs.filter { $0.dayKey == dk }
        var out: [DayEntry] = []
        for (i, s) in slots.enumerated() {
            let log = dayLogs.first { $0.slotKey == s.key }
            let next = i + 1 < slots.count ? slots[i + 1] : nil
            out.append(DayEntry(key: s.key, date: s.date, title: s.title, log: log,
                                state: SlotState.of(s, next: next, log: log, now: now), openable: true))
        }
        // Records whose medications were removed later still show (snapshot, M11).
        for log in dayLogs where !out.contains(where: { $0.key == log.slotKey }) {
            let state: SlotState = switch log.status {
            case .taken: .taken
            case .partial: .partial(log.missingCount)
            case .skipped: .skipped
            }
            out.append(DayEntry(key: log.slotKey, date: log.scheduledAt, title: log.title, log: log, state: state, openable: false))
        }
        return out.sorted { $0.date < $1.date }
    }

    @MainActor
    static func result(for day: Date, logs: [DoseLog], context: ModelContext, now: Date = .now) -> DayResult {
        let entries = entries(for: day, logs: logs, context: context, now: now)
        if entries.isEmpty { return .none }
        if entries.contains(where: { $0.state == .skipped || $0.state == .missed }) { return .skippedOrNotMarked }
        if entries.contains(where: { if case .partial = $0.state { true } else { false } }) { return .somethingMissing }
        if entries.allSatisfy({ $0.state == .taken }) { return .allTaken }
        return .upcoming
    }
}

/// S9: month calendar, one mark per day.
struct HistoryView: View {
    @Query private var logs: [DoseLog]
    @Query private var meds: [Medication]
    @Query private var routines: [Routine]
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @State private var month = SlotEngine.calendar.date(from: SlotEngine.calendar.dateComponents([.year, .month], from: .now))!

    private var cal: Calendar {
        var c = SlotEngine.calendar
        c.firstWeekday = 2 // Thứ Hai
        return c
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    monthHeader
                    HCard(padding: 12) { grid }
                    legend
                }
                .padding(16)
            }
            .background(theme.background.color.ignoresSafeArea())
            .navigationTitle("Lịch sử")
            .navigationDestination(for: Date.self) { day in
                DayDetailView(day: day)
            }
        }
    }

    private var monthTitle: String {
        let c = cal.dateComponents([.month, .year], from: month)
        return "Tháng \(c.month!), \(c.year!)"
    }

    private var monthHeader: some View {
        HStack {
            Button("‹ Trước") { shift(-1) }
                .buttonStyle(HButtonStyle(variant: .secondary, compact: true))
                .accessibilityLabel("Tháng trước")
            Spacer()
            Text(monthTitle)
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Button("Sau ›") { shift(1) }
                .buttonStyle(HButtonStyle(variant: .secondary, compact: true))
                .accessibilityLabel("Tháng sau")
                .disabled(isCurrentMonth)
        }
    }

    private var isCurrentMonth: Bool {
        cal.isDate(month, equalTo: .now, toGranularity: .month)
    }

    private func shift(_ by: Int) {
        month = cal.date(byAdding: .month, value: by, to: month) ?? month
    }

    private var days: [Date?] {
        let range = cal.range(of: .day, in: .month, for: month)!
        let weekday = cal.component(.weekday, from: month)
        let lead = (weekday - cal.firstWeekday + 7) % 7
        let dates = range.map { cal.date(byAdding: .day, value: $0 - 1, to: month)! }
        return Array(repeating: nil, count: lead) + dates.map { Optional($0) }
    }

    private var grid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let today = SlotEngine.drugDay(for: .now, routine: routines.first?.times ?? RoutineTimes())
        _ = meds.count // refresh when medications change
        return LazyVGrid(columns: cols, spacing: 6) {
            ForEach(["T2", "T3", "T4", "T5", "T6", "T7", "CN"], id: \.self) { d in
                Text(d)
                    .appFont(.label)
                    .foregroundStyle(theme.muted.color)
                    .frame(maxWidth: .infinity)
            }
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date {
                    let future = date > today
                    let result: DayResult = future ? .upcoming : HistoryModel.result(for: date, logs: logs, context: context)
                    let isToday = cal.isDate(date, inSameDayAs: today)
                    if future {
                        cell(date, result, isToday: false).opacity(0.45)
                    } else {
                        NavigationLink(value: date) { cell(date, result, isToday: isToday) }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Ngày \(cal.component(.day, from: date)), \(result.label)")
                    }
                } else {
                    Color.clear.frame(height: 56)
                }
            }
        }
    }

    private func cell(_ date: Date, _ result: DayResult, isToday: Bool) -> some View {
        VStack(spacing: 2) {
            Text("\(cal.component(.day, from: date))")
                .appFont(.secondary)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(theme.foreground.color)
            ZStack {
                if !result.symbol.isEmpty {
                    Circle().fill(color(result)).frame(width: 24, height: 24)
                    Text(result.symbol)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(height: 24)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isToday ? theme.accent.color : .clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }

    private func color(_ r: DayResult) -> Color {
        switch r {
        case .allTaken: theme.success.color
        case .somethingMissing: theme.warning.color
        case .skippedOrNotMarked: theme.danger.color
        case .none, .upcoming: .clear
        }
    }

    private var legend: some View {
        HCard {
            ForEach([DayResult.allTaken, .somethingMissing, .skippedOrNotMarked], id: \.symbol) { r in
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(color(r)).frame(width: 24, height: 24)
                        Text(r.symbol).font(.system(size: 14, weight: .heavy)).foregroundStyle(Color.white)
                    }
                    Text(r.label)
                        .appFont(.secondary)
                        .foregroundStyle(theme.foreground.color)
                }
            }
            Text("Chạm vào một ngày để xem từng giờ uống.")
                .appFont(.secondary)
                .foregroundStyle(theme.muted.color)
        }
    }
}

/// S10: every dose time of one day. Tap to edit or mark late (AC16).
struct DayDetailView: View {
    let day: Date
    @Query private var logs: [DoseLog]
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @State private var open: Slot?

    var body: some View {
        let entries = HistoryModel.entries(for: day, logs: logs, context: context)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if entries.isEmpty {
                    Text("Ngày này không có thuốc cần uống.")
                        .appFont(.body)
                        .foregroundStyle(theme.muted.color)
                }
                ForEach(entries) { entry in row(entry) }
            }
            .padding(16)
        }
        .background(theme.background.color.ignoresSafeArea())
        .navigationTitle(VNDate.dayTitle(day))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $open) { DoseSessionView(slot: $0) }
    }

    private func row(_ e: DayEntry) -> some View {
        let minute = SlotEngine.calendar.dateComponents([.hour, .minute], from: e.date)
        return Button {
            open = AppStore.slot(forKey: e.key, in: context)
        } label: {
            HCard {
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%d:%02d", minute.hour ?? 0, minute.minute ?? 0))
                        .appFont(.headline)
                        .monospacedDigit()
                        .foregroundStyle(theme.foreground.color)
                        .frame(minWidth: 58, alignment: .leading)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(e.title)
                            .appFont(.body)
                            .foregroundStyle(theme.foreground.color)
                        SlotStateChip(state: e.state)
                        if let log = e.log {
                            let missing = log.items.filter { !$0.taken }.map(\.name)
                            if log.status == .partial, !missing.isEmpty {
                                Text("Chưa uống: \(missing.joined(separator: ", "))")
                                    .appFont(.secondary)
                                    .foregroundStyle(theme.muted.color)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    if e.openable {
                        Text(e.log == nil ? "Đánh dấu" : "Sửa")
                            .appFont(.secondary)
                            .foregroundStyle(theme.accentSoftForeground.color)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!e.openable || e.state == .upcoming)
    }
}
