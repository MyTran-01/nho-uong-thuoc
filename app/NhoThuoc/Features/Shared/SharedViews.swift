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

struct SlotStateChip: View {
    let state: SlotState

    var body: some View {
        switch state {
        case .upcoming: HChip(text: "Sắp tới", color: .accent, variant: .soft)
        case .due: HChip(text: "Tới giờ", color: .accent)
        case .missed: HChip(text: "! Chưa đánh dấu", color: .danger)
        case .taken: HChip(text: "✓ Đã uống đủ", color: .success)
        case .partial(let n): HChip(text: "◐ Còn \(n) thuốc chưa uống", color: .warning)
        case .skipped: HChip(text: "– Đã bỏ cữ", color: .neutral)
        }
    }
}

// MARK: Blister photos (M08: two squares side by side)

struct BlisterPhoto: View {
    let file: String?
    let side: String
    let medName: String
    var size: CGFloat = 64
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let image = PhotoStore.image(file) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    theme.defaultFill.color
                    VStack(spacing: 2) {
                        Image(systemName: "camera")
                            .font(.system(size: size * 0.24))
                        if size >= 90 {
                            Text("Chưa có ảnh").appFont(.label)
                        }
                    }
                    .foregroundStyle(theme.muted.color)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.16, style: .continuous).strokeBorder(theme.border.color, lineWidth: 1))
        .accessibilityElement()
        .accessibilityLabel(file == nil ? "\(medName), chưa có ảnh \(side)" : "Ảnh \(side) vỉ \(medName)")
    }
}

struct BlisterPair: View {
    let front: String?
    let back: String?
    let medName: String
    var size: CGFloat = 64

    var body: some View {
        HStack(spacing: 6) {
            BlisterPhoto(file: front, side: "mặt trước", medName: medName, size: size)
            BlisterPhoto(file: back, side: "mặt sau", medName: medName, size: size)
        }
    }
}

/// D1: enlarged photos, still side by side.
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
                let side = (geo.size.width - 32 - 8) / 2
                HStack(spacing: 8) {
                    labeled(BlisterPhoto(file: item.frontPhoto, side: "mặt trước", medName: item.name, size: side), "Mặt trước")
                    labeled(BlisterPhoto(file: item.backPhoto, side: "mặt sau", medName: item.name, size: side), "Mặt sau")
                }
                Spacer(minLength: 0)
                Button("Đóng") { dismiss() }
                    .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true, minHeight: theme.buttonHeight))
            }
            .padding(16)
        }
        .background(theme.background.color.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private func labeled(_ photo: BlisterPhoto, _ label: String) -> some View {
        VStack(spacing: 6) {
            photo
            Text(label).appFont(.secondary).foregroundStyle(theme.muted.color)
        }
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
                        .foregroundStyle(editing == field ? theme.accentForeground.color : theme.accent.color)
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
