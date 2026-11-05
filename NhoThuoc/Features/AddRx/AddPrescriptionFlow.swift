import SwiftUI
import SwiftData
import OSLog

private let ocrLog = Logger(subsystem: "vn.nhothuoc.app", category: "ocr")

/// E4/T4: S6 photograph the prescription → S7 review the medications it found →
/// S8 photograph each blister. The prescription starts reminding as soon as S7 is saved.
struct AddPrescriptionFlow: View {
    enum Stage: Equatable {
        case capture
        case reading
        case unreadable
        case review
        case blisters([UUID])
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Query private var routines: [Routine]
    @State private var stage: Stage = .capture
    @State private var picker: PickerRequest?
    @State private var photo: UIImage?
    @State private var title = ""
    @State private var drafts: [DraftMed] = []

    var body: some View {
        NavigationStack {
            Group {
                switch stage {
                case .capture: capture
                case .reading: reading
                case .unreadable: unreadable
                case .review:
                    ReviewDraftsView(title: $title, drafts: $drafts,
                                     routine: routines.first?.times ?? RoutineTimes(),
                                     onSave: save)
                case .blisters(let ids):
                    BlisterCaptureView(medIDs: ids) { dismiss() }
                }
            }
            .background(theme.background.color.ignoresSafeArea())
            .toolbar {
                if stage != .reading, !isBlisters {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Đóng") { dismiss() }
                    }
                }
            }
        }
        .fullScreenCover(item: $picker) { request in
            ImagePicker(request: request) { image in read(image) }
                .ignoresSafeArea()
        }
    }

    private var isBlisters: Bool {
        if case .blisters = stage { return true }
        return false
    }

    // S6
    private var capture: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chụp đơn thuốc")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            HCard {
                tip("doc.text", "Đặt đơn trên mặt bàn, chỗ đủ sáng.")
                tip("viewfinder", "Chụp thẳng, thấy hết phần tên thuốc.")
                tip("lock.fill", "App đọc chữ ngay trên máy, ảnh không gửi đi đâu.")
            }
            Spacer()
            VStack(spacing: 8) {
                if Camera.isAvailable {
                    Button("Chụp ảnh đơn") { picker = PickerRequest(source: .camera, square: false) }
                        .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                    Button("Chọn ảnh có sẵn") { picker = PickerRequest(source: .photoLibrary, square: false) }
                        .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
                } else {
                    Button("Chọn ảnh đơn có sẵn") { picker = PickerRequest(source: .photoLibrary, square: false) }
                        .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                }
                Button("Tự thêm thuốc") { startManual() }
                    .buttonStyle(HButtonStyle(variant: .tertiary, fullWidth: true))
            }
        }
        .padding(16)
    }

    private var reading: some View {
        VStack(spacing: 20) {
            Spacer()
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
            }
            ProgressView()
                .controlSize(.large)
            Text("Đang đọc đơn…")
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }

    // AC04
    private var unreadable: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ảnh hơi mờ, chụp lại giúp nhé")
                .appFont(.title)
                .foregroundStyle(theme.foreground.color)
            Text("App chưa tìm thấy tên thuốc trong ảnh này. Đơn viết tay cũng khó đọc. Bạn có thể chụp lại hoặc tự thêm thuốc.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
            Spacer()
            Button("Chụp lại") { stage = .capture }
                .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
            Button("Tự thêm thuốc") { startManual() }
                .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
        }
        .padding(16)
    }

    private func tip(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(theme.accent.color)
                .frame(width: 26)
                .accessibilityHidden(true)
            Text(text)
                .appFont(.body)
                .foregroundStyle(theme.foreground.color)
        }
    }

    // MARK: Actions

    private func read(_ image: UIImage) {
        let upright = image.normalized(maxSide: 2400)
        photo = upright
        stage = .reading
        Task {
            var lines: [String] = []
            if let cg = upright.cgImage {
                do {
                    lines = try await TextRecognizer.lines(in: cg)
                } catch {
                    ocrLog.error("Text recognition failed: \(String(describing: error), privacy: .public)")
                }
            }
            let result = RxParser.parse(lines: lines)
            ocrLog.info("Read \(lines.count) lines, \(result.meds.count) medications")
            if result.meds.isEmpty {
                stage = .unreadable
            } else {
                title = result.title ?? "Đơn thuốc"
                drafts = result.meds
                stage = .review
            }
        }
    }

    private func startManual() {
        photo = nil
        title = "Đơn thuốc"
        drafts = [DraftMed(nameOnRx: "", displayName: "")]
        stage = .review
    }

    private func save() {
        let routine = routines.first?.times ?? RoutineTimes()
        let start = SlotEngine.drugDay(for: .now, routine: routine)
        let rx = Prescription(name: title.trimmingCharacters(in: .whitespaces).isEmpty ? "Đơn thuốc" : title,
                              photoFile: photo.flatMap { PhotoStore.save($0, maxSide: 2000) },
                              startDate: start)
        context.insert(rx)
        var ids: [UUID] = []
        for (i, draft) in drafts.enumerated() {
            var d = draft
            if d.displayName.trimmingCharacters(in: .whitespaces).isEmpty { d.displayName = d.nameOnRx.isEmpty ? "Thuốc \(i + 1)" : d.nameOnRx }
            let med = Medication(draft: d, startDate: start, sortIndex: i)
            med.prescription = rx
            context.insert(med)
            ids.append(med.id)
        }
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        stage = .blisters(ids)
    }
}

/// S7: medications found on the prescription, each editable in place.
struct ReviewDraftsView: View {
    @Binding var title: String
    @Binding var drafts: [DraftMed]
    let routine: RoutineTimes
    let onSave: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(drafts.count == 1 && drafts[0].nameOnRx.isEmpty ? "Thêm thuốc" : "Tìm thấy \(drafts.count) loại thuốc")
                        .appFont(.title)
                        .foregroundStyle(theme.foreground.color)
                    Text("Kiểm lại tên và giờ uống. Chỗ nào chưa đúng thì chạm để sửa.")
                        .appFont(.body)
                        .foregroundStyle(theme.muted.color)
                }
                HCard {
                    HTextField(label: "Tên đơn", text: $title)
                }
                ForEach($drafts) { $draft in
                    DraftMedCard(draft: $draft, routine: routine, startExpanded: draft.nameOnRx.isEmpty) {
                        drafts.removeAll { $0.id == draft.id }
                    }
                }
                Button("+ Thêm thuốc") {
                    drafts.append(DraftMed(nameOnRx: "", displayName: ""))
                }
                .buttonStyle(HButtonStyle(variant: .outline, fullWidth: true))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button("Lưu và chụp vỉ", action: onSave)
                .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                .disabled(drafts.isEmpty)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.background.color.opacity(0.96))
        }
    }
}
