import SwiftUI
import SwiftData

/// S9 (MVP): marked dose times grouped by day, newest first.
/// The month calendar from the PRD comes later.
struct HistoryView: View {
    @Query(sort: \DoseLog.scheduledAt, order: .reverse) private var logs: [DoseLog]
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if logs.isEmpty {
                        Text("Chưa có lần uống nào được đánh dấu.")
                            .appFont(.body)
                            .foregroundStyle(theme.muted.color)
                    }
                    ForEach(days, id: \.self) { day in
                        SectionTitle(VNDate.dayTitle(key: day))
                        HCard(padding: 0) {
                            VStack(spacing: 0) {
                                let dayLogs = logs.filter { $0.dayKey == day }.sorted { $0.scheduledAt < $1.scheduledAt }
                                ForEach(Array(dayLogs.enumerated()), id: \.element.slotKey) { i, log in
                                    if i > 0 { Divider().overlay(theme.separator.color).padding(.leading, 16) }
                                    row(log)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(theme.background.color.ignoresSafeArea())
            .navigationTitle("Lịch sử")
        }
    }

    private var days: [String] {
        var seen = Set<String>()
        return logs.map(\.dayKey).filter { seen.insert($0).inserted }
    }

    private func row(_ log: DoseLog) -> some View {
        let minute = SlotEngine.calendar.dateComponents([.hour, .minute], from: log.scheduledAt)
        let state: SlotState = switch log.status {
        case .taken: .taken
        case .partial: .partial(log.missingCount)
        case .skipped: .skipped
        }
        return HStack(alignment: .top, spacing: 12) {
            Text(String(format: "%d:%02d", minute.hour ?? 0, minute.minute ?? 0))
                .appFont(.headline)
                .monospacedDigit()
                .foregroundStyle(theme.foreground.color)
                .frame(minWidth: 58, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                Text(log.title)
                    .appFont(.body)
                    .foregroundStyle(theme.foreground.color)
                SlotStateChip(state: state)
                let notTaken = log.items.filter { !$0.taken }.map(\.name)
                if !notTaken.isEmpty, log.status == .partial {
                    Text("Chưa uống: \(notTaken.joined(separator: ", "))")
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
