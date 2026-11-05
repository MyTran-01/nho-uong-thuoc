import SwiftUI
import SwiftData

/// S8: photograph the front and back of each blister, one medication at a time.
/// Square crop (M08). Skippable; missing photos show up as a banner on Today.
struct BlisterCaptureView: View {
    let medIDs: [UUID]
    let onFinish: () -> Void
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @State private var index = 0
    @State private var picker: PickerRequest?
    @State private var target: Side = .front
    @State private var refresh = 0

    enum Side { case front, back }

    private var med: Medication? {
        guard index < medIDs.count else { return nil }
        let id = medIDs[index]
        _ = refresh
        return try? context.fetch(FetchDescriptor<Medication>(predicate: #Predicate { $0.id == id })).first
    }

    var body: some View {
        Group {
            if let med {
                page(med)
            } else {
                Color.clear.onAppear(perform: onFinish)
            }
        }
        .background(theme.background.color.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Để sau") { onFinish() }
            }
        }
        .fullScreenCover(item: $picker) { request in
            ImagePicker(request: request) { image in store(image) }
                .ignoresSafeArea()
        }
    }

    private func page(_ med: Medication) -> some View {
        GeometryReader { geo in
            let side = (geo.size.width - 32 - 12) / 2
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Thuốc \(index + 1)/\(medIDs.count) · Chụp vỉ thuốc")
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                    Text(med.displayName)
                        .appFont(.title)
                        .foregroundStyle(theme.foreground.color)
                    Text("Chụp cả mặt trước và mặt sau của vỉ, để lúc uống nhìn là nhận ra.")
                        .appFont(.body)
                        .foregroundStyle(theme.muted.color)

                    HStack(spacing: 12) {
                        slot(med.frontPhoto, label: "Mặt trước", size: side, current: med.frontPhoto == nil) { open(.front) }
                        slot(med.backPhoto, label: "Mặt sau", size: side,
                             current: med.frontPhoto != nil && med.backPhoto == nil) { open(.back) }
                    }
                    if Camera.isAvailable, !med.hasPhotos {
                        Button("Hoặc chọn ảnh có sẵn") {
                            target = med.frontPhoto == nil ? .front : .back
                            picker = PickerRequest(source: .photoLibrary, square: true)
                        }
                        .appFont(.body)
                        .foregroundStyle(theme.accentSoftForeground.color)
                        .underline()
                        .frame(maxWidth: .infinity, minHeight: theme.touchMin)
                    }
                }
                .padding(16)
            }
            .safeAreaInset(edge: .bottom) { actions(med) }
        }
    }

    private func slot(_ file: String?, label: String, size: CGFloat, current: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                BlisterPhoto(file: file, side: label.lowercased(), medName: med?.displayName ?? "", size: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                            .strokeBorder(current ? theme.accent.color : .clear, lineWidth: 3)
                    )
                HStack(spacing: 4) {
                    if file != nil {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.success.color)
                    }
                    Text(file == nil ? label : "\(label) · chụp lại")
                        .appFont(.secondary)
                        .foregroundStyle(theme.foreground.color)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func actions(_ med: Medication) -> some View {
        let isLast = index == medIDs.count - 1
        let verb = Camera.isAvailable ? "Chụp" : "Chọn ảnh"
        return VStack(spacing: 8) {
            if med.frontPhoto == nil {
                Button("\(verb) mặt trước") { open(.front) }
                    .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
            } else if med.backPhoto == nil {
                Button("\(verb) mặt sau") { open(.back) }
                    .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
            } else {
                Button(isLast ? "Xong" : "Sang thuốc tiếp theo") { next() }
                    .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
            }
            if !med.hasPhotos {
                Button(isLast ? "Bỏ qua, chụp sau" : "Bỏ qua thuốc này") { next() }
                    .buttonStyle(HButtonStyle(variant: .tertiary, fullWidth: true))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.background.color.opacity(0.96))
    }

    private func open(_ side: Side) {
        target = side
        picker = PickerRequest(source: Camera.isAvailable ? .camera : .photoLibrary, square: true)
    }

    private func store(_ image: UIImage) {
        guard let med, let file = PhotoStore.save(image, maxSide: 900) else { return }
        switch target {
        case .front: med.frontPhoto = file
        case .back: med.backPhoto = file
        }
        try? context.save()
        refresh += 1
    }

    private func next() {
        if index + 1 >= medIDs.count {
            onFinish()
        } else {
            index += 1
        }
    }
}
