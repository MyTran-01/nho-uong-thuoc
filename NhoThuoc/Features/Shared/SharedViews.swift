import SwiftUI
import UIKit

// MARK: Slot state

enum SlotState: Equatable {
    case upcoming, due, missed, taken, partial(Int), skipped

    static func of(_ slot: Slot, next: Slot?, log: DoseLog?, now: Date) -> SlotState {
        if let log {
            switch log.status {
            case .taken: return .taken
            case .partial: return .partial(log.missingCount)
            case .skipped: return .skipped
            }
        }
        if now < slot.date { return .upcoming }
        return now < SlotEngine.missedAt(slot, next: next) ? .due : .missed
    }

    var isDone: Bool {
        switch self {
        case .taken, .partial, .skipped: true
        default: false
        }
    }
}

// One status palette for timeline dots, card headers and chips.
extension SlotState {
    var label: String {
        switch self {
        case .upcoming: "Sắp tới"
        case .due: "Tới giờ · Chưa dùng"
        case .missed: "Quá giờ · Chưa dùng"
        case .taken: "Đã dùng đủ"
        case .partial(let n): "Còn \(n) thuốc chưa dùng"
        case .skipped: "Đã bỏ cữ"
        }
    }

    var symbol: String {
        switch self {
        case .upcoming: "clock"
        case .due: "bell.fill"
        case .missed: "exclamationmark.triangle.fill"
        case .taken: "checkmark.circle.fill"
        case .partial: "circle.lefthalf.filled"
        case .skipped: "minus.circle"
        }
    }

    func palette(in theme: Theme) -> (background: Tok, foreground: Tok) {
        switch self {
        case .upcoming: (theme.infoSoft, theme.infoSoftForeground)
        case .due, .partial: (theme.warningSoft, theme.warningSoftForeground)
        case .missed: (theme.dangerSoft, theme.dangerSoftForeground)
        case .taken: (theme.successSoft, theme.successSoftForeground)
        case .skipped: (theme.defaultFill, theme.muted)
        }
    }
}

struct SlotStateChip: View {
    let state: SlotState
    @Environment(\.theme) private var theme

    var body: some View {
        let palette = state.palette(in: theme)
        Label(state.label, systemImage: state.symbol)
            .appFont(.chip)
            .foregroundStyle(palette.foreground.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(palette.background.color))
    }
}

// MARK: Photo zoom

/// D1: the blister photo, enlarged.
struct BlisterZoomView: View {
    let item: SlotItem
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 16) {
                Text(item.name)
                    .appFont(.title)
                    .foregroundStyle(theme.foreground.color)
                Text(item.doseText)
                    .appFont(.headline)
                    .foregroundStyle(theme.muted.color)
                MedThumb(file: item.frontPhoto, form: item.form, name: item.name,
                         size: min(geo.size.width - 32, geo.size.height * 0.55))
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
                Button("Đóng") { dismiss() }
                    .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true, minHeight: theme.buttonHeight))
            }
            .padding(16)
        }
        .background(theme.background.color.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}

// MARK: Toast with undo

struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let text: String
    var undo: (() -> Void)?

    static func == (a: ToastMessage, b: ToastMessage) -> Bool { a.id == b.id }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast {
                HStack(spacing: 12) {
                    Text(toast.text)
                        .appFont(.secondary)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let undo = toast.undo {
                        Button("Hoàn tác") {
                            undo()
                            self.toast = nil
                        }
                        .appFont(.button)
                        .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
                        .frame(minHeight: theme.touchMin)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(white: 0.13)))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: toast.id) {
                    try? await Task.sleep(for: .seconds(6))
                    withAnimation { self.toast = nil }
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

// MARK: Image picker (camera or library, optional square crop)

struct PickerRequest: Identifiable {
    let id = UUID()
    let source: UIImagePickerController.SourceType
    let square: Bool
}

enum Camera {
    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }
}

struct ImagePicker: UIViewControllerRepresentable {
    let request: PickerRequest
    let onPick: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = request.source
        picker.allowsEditing = request.square
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let edited = parent.request.square ? info[.editedImage] as? UIImage : nil
            if let image = edited ?? info[.originalImage] as? UIImage {
                parent.onPick(parent.request.square ? image.squared() : image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: Routine editor (O2, S12)

enum RoutineField: String, CaseIterable, Identifiable {
    case breakfast, lunch, afternoon, dinner, bed
    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: "Ăn sáng"
        case .lunch: "Ăn trưa"
        case .afternoon: "Buổi chiều"
        case .dinner: "Ăn tối"
        case .bed: "Đi ngủ"
        }
    }

    var keyPath: WritableKeyPath<RoutineTimes, Int> {
        switch self {
        case .breakfast: \.breakfast
        case .lunch: \.lunch
        case .afternoon: \.afternoon
        case .dinner: \.dinner
        case .bed: \.bed
        }
    }
}

struct RoutineEditor: View {
    @Binding var times: RoutineTimes
    var fields: [RoutineField] = [.breakfast, .lunch, .dinner, .bed]
    @State private var editing: RoutineField?
    @Environment(\.theme) private var theme

    var body: some View {
        HCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(fields.enumerated()), id: \.element) { index, field in
                    if index > 0 { Divider().overlay(theme.separator.color).padding(.leading, 16) }
                    row(field)
                }
            }
        }
    }

    private func row(_ field: RoutineField) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { editing = editing == field ? nil : field }
            } label: {
                HStack {
                    Text(field.label)
                        .appFont(.headline)
                        .foregroundStyle(theme.foreground.color)
                    Spacer()
                    Text(Clock.text(times[keyPath: field.keyPath]))
                        .appFont(.headline)
                        .monospacedDigit()
                        .foregroundStyle(editing == field ? theme.accentForeground.color : theme.accentSoftForeground.color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(editing == field ? theme.accent.color : theme.accentSoft.color))
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(field.label), \(Clock.text(times[keyPath: field.keyPath]))")
            .accessibilityHint("Chạm để đổi giờ")

            if editing == field {
                DatePicker("", selection: binding(field), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "vi_VN"))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }
        }
    }

    private func binding(_ field: RoutineField) -> Binding<Date> {
        Binding {
            let m = times[keyPath: field.keyPath]
            return SlotEngine.calendar.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: .now) ?? .now
        } set: { date in
            let c = SlotEngine.calendar.dateComponents([.hour, .minute], from: date)
            times[keyPath: field.keyPath] = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
    }
}

extension RoutineTimes {
    /// A short message when meal times are out of order, otherwise nil.
    var problem: String? {
        if lunch <= breakfast { return "Giờ ăn trưa cần sau giờ ăn sáng." }
        if dinner <= lunch { return "Giờ ăn tối cần sau giờ ăn trưa." }
        if bed > breakfast, bed <= dinner { return "Giờ đi ngủ cần sau giờ ăn tối." }
        return nil
    }
}

// MARK: Text helpers

enum VNDate {
    static func dayTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEEE, d 'tháng' M"
        let s = f.string(from: date)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    static func dayTitle(key: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: key) else { return key }
        return dayTitle(d)
    }
}

/// Section header used across screens.
struct SectionTitle: View {
    let text: String
    @Environment(\.theme) private var theme

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .appFont(.headline)
            .foregroundStyle(theme.foreground.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
