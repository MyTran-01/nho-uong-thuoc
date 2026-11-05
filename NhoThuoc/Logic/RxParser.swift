import Foundation

/// Turns recognised text lines from a printed prescription into draft medications.
/// Rule-based, runs on device. Anything it cannot read is filled with defaults
/// the user changes by tapping chips.
nonisolated enum RxParser {
    struct Result: Sendable {
        var title: String?
        var meds: [DraftMed]
    }

    /// A recognised text fragment with its position (normalised, origin top-left).
    struct Fragment: Sendable {
        var text: String
        var midY: Double
        var minX: Double
        var height: Double
    }

    /// Joins fragments that sit on the same printed line, top to bottom, left to right.
    static func lines(from fragments: [Fragment]) -> [String] {
        let sorted = fragments.sorted { $0.midY < $1.midY }
        var rows: [[Fragment]] = []
        for f in sorted {
            if let last = rows.last?.last, abs(last.midY - f.midY) < max(last.height, f.height) * 0.5 {
                rows[rows.count - 1].append(f)
            } else {
                rows.append([f])
            }
        }
        return rows.map { $0.sorted { $0.minX < $1.minX }.map(\.text).joined(separator: "  ") }
    }

    static func parse(lines raw: [String]) -> Result {
        let lines = raw.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var title: String?
        var items: [(name: String, instructions: [String])] = []

        for line in lines {
            let lower = line.lowercased()
            if title == nil, ["phòng khám", "bệnh viện", "nhà thuốc", "phòng mạch"].contains(where: lower.contains) {
                title = sentenceCase(line)
                continue
            }
            if isStopLine(lower) {
                if !items.isEmpty { break }
                continue
            }
            if let name = itemName(line) {
                items.append((name, []))
            } else if !items.isEmpty {
                items[items.count - 1].instructions.append(line)
            }
        }

        let meds = items.map { item -> DraftMed in
            var draft = DraftMed(nameOnRx: item.name, displayName: cleanName(item.name))
            apply(instructions: item.instructions.joined(separator: " "), to: &draft)
            return draft
        }
        return Result(title: title, meds: meds)
    }

    // MARK: Lines

    private static func isStopLine(_ lower: String) -> Bool {
        lower.range(of: #"ngày\s+\d+\s+tháng"#, options: .regularExpression) != nil
            || lower.hasPrefix("bác sĩ") || lower.hasPrefix("lời dặn") || lower.hasPrefix("tái khám")
    }

    /// "2. Thuốc Da Liễu B 250mg   60 viên" -> "Thuốc Da Liễu B 250mg"
    private static func itemName(_ line: String) -> String? {
        guard let m = line.range(of: #"^\s*\d{1,2}\s*[\.\)]\s*(?=\p{L})"#, options: .regularExpression) else { return nil }
        var name = String(line[m.upperBound...])
        if let q = name.range(of: #"\s+(sl[:\s]*)?\d+\s*(viên|gói|ống|lọ|chai|tuýp|hộp|vỉ|ml)\s*$"#,
                              options: [.regularExpression, .caseInsensitive]) {
            name.removeSubrange(q)
        }
        name = name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    /// Display name suggestion: keep the name, drop the strength ("250mg").
    private static func cleanName(_ name: String) -> String {
        let stripped = name.replacingOccurrences(of: #"\s+\d+([.,]\d+)?\s*(mg|mcg|g|ml|iu|ui)\b.*$"#,
                                                 with: "", options: [.regularExpression, .caseInsensitive])
        return stripped.isEmpty ? name : stripped
    }

    private static func sentenceCase(_ s: String) -> String {
        let lower = s.lowercased()
        return lower.prefix(1).uppercased() + lower.dropFirst()
    }

    // MARK: Instructions

    static func apply(instructions text: String, to draft: inout DraftMed) {
        let t = " " + text.lowercased().replacingOccurrences(of: "–", with: "-") + " "

        // Dose: "mỗi lần 2 viên", "mỗi lần 1/2 viên", "nửa viên"
        if let m = firstMatch(#"(\d+\s*/\s*\d+|\d+|nửa|½)\s*(viên|gói|ml|giọt)"#, in: t) {
            let amount = m[1].replacingOccurrences(of: " ", with: "")
            switch amount {
            case "1/2", "nửa", "½": draft.doseHalves = 1
            default: draft.doseHalves = max(1, (Int(amount) ?? 1) * 2)
            }
            draft.unit = ["gói": .goi, "ml": .ml, "giọt": .giot][m[2]] ?? .vien
        }
        if t.contains("bôi") { draft.unit = .lanBoi }

        // Schedule: "cách ngày", "cách 2 ngày"
        if let m = firstMatch(#"cách\s*(\d+)\s*ngày"#, in: t) {
            draft.everyNDays = min(max(Int(m[1]) ?? 1, 1), 2)
        } else if t.contains("cách ngày") {
            draft.everyNDays = 1
        }

        // Explicit offset: "30 phút", "1 tiếng"
        var offset: Int?
        if let m = firstMatch(#"(\d+)\s*(phút|tiếng|giờ)"#, in: t) {
            let n = Int(m[1]) ?? 0
            offset = m[2] == "phút" ? n : n * 60
        }

        var timings: [Timing] = []

        // Before bed
        if t.contains("trước khi ngủ") || t.contains("trước ngủ") || t.contains("trước giờ ngủ") || t.contains("lúc đi ngủ") {
            timings.append(Timing(anchor: .bed, relation: .before, offsetMinutes: offset, offsetSource: offset == nil ? .standard : .rx))
        }

        // Afternoon (but not "chiều tối")
        if t.contains("buổi chiều") || (t.range(of: #"\bchiều\b"#, options: .regularExpression) != nil && !t.contains("chiều tối")) {
            timings.append(Timing(anchor: .afternoon, relation: .at))
        }

        // Meals
        var relation: Relation?
        if t.contains("trước ăn") || t.contains("trước bữa") || t.contains("lúc đói") || t.contains("trước khi ăn") {
            relation = .before
        } else if t.contains("trong bữa") || t.contains("trong khi ăn") || t.contains("cùng bữa") {
            relation = .during
        } else if t.contains("sau ăn") || t.contains("sau khi ăn") || t.contains("ăn no") || t.contains("sau bữa") {
            relation = .after
        }

        var meals: [Anchor] = []
        if t.contains("sáng") { meals.append(.breakfast) }
        if t.contains("trưa") { meals.append(.lunch) }
        if t.range(of: #"\btối\b"#, options: .regularExpression) != nil { meals.append(.dinner) }

        if meals.isEmpty, relation != nil || timings.isEmpty {
            // "Ngày 2 lần" without meal names
            let perDay = firstMatch(#"ngày\s*(\d)\s*lần"#, in: t).flatMap { Int($0[1]) } ?? 1
            meals = perDay >= 3 ? [.breakfast, .lunch, .dinner] : perDay == 2 ? [.breakfast, .dinner] : [.breakfast]
        }
        let mealRelation = relation ?? .after
        let mealUsesOffset = mealRelation != .during && !timings.contains(where: { $0.anchor == .bed })
        for meal in meals {
            timings.append(Timing(anchor: meal, relation: mealRelation,
                                  offsetMinutes: mealUsesOffset ? offset : nil,
                                  offsetSource: mealUsesOffset && offset != nil ? .rx : .standard))
        }

        if !timings.isEmpty { draft.timings = timings }
    }

    private static func firstMatch(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        guard let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        return (0..<m.numberOfRanges).map { i in
            let r = m.range(at: i)
            return r.location == NSNotFound ? "" : ns.substring(with: r)
        }
    }
}
