import SwiftUI
import SwiftData

/// S3: prescriptions, active first.
struct PrescriptionListView: View {
    @Query(sort: \Prescription.createdAt, order: .reverse) private var prescriptions: [Prescription]
    @Environment(Router.self) private var router
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button("Thêm đơn thuốc") { router.addPrescription = true }
                        .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                    if prescriptions.isEmpty {
                        Text("Chưa có đơn thuốc nào.")
                            .appFont(.body)
                            .foregroundStyle(theme.muted.color)
                    }
                    ForEach(sorted) { rx in
                        NavigationLink(value: rx.id) { card(rx) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(theme.background.color.ignoresSafeArea())
            .navigationTitle("Đơn thuốc")
            .navigationDestination(for: UUID.self) { id in
                if let rx = prescriptions.first(where: { $0.id == id }) {
                    PrescriptionDetailView(rx: rx)
                }
            }
        }
    }

    private var sorted: [Prescription] {
        prescriptions.sorted { ($0.status == .active ? 0 : 1) < ($1.status == .active ? 0 : 1) }
    }

    private func card(_ rx: Prescription) -> some View {
        let active = rx.sortedMedications.filter { !$0.isFinished }
        return HCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rx.name)
                        .appFont(.headline)
                        .foregroundStyle(theme.foreground.color)
                    Text(rx.status == .active ? "\(active.count) loại thuốc đang dùng"
                         : rx.status == .paused ? "Đang tạm dừng" : "Đã uống hết đơn này")
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.muted.color)
                    .accessibilityHidden(true)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(active) { med in
                        BlisterPhoto(file: med.frontPhoto, side: "mặt trước", medName: med.displayName, size: 48)
                    }
                }
            }
        }
        .opacity(rx.status == .active ? 1 : 0.6)
    }
}

/// S4: one prescription. "Đã uống hết đơn này" sits at the top (M13, AC23).
struct PrescriptionDetailView: View {
    @Bindable var rx: Prescription
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @State private var confirmEnd = false
    @State private var confirmPause = false
    @State private var renaming = false
    @State private var newName = ""
    @State private var editing: Medication?
    @State private var photoFor: [UUID]?
    @State private var toast: ToastMessage?

    var body: some View {
        let meds = rx.sortedMedications
        let active = meds.filter { !$0.isFinished }
        let finished = meds.filter(\.isFinished)
        let routine = AppStore.routine(in: context).times

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch rx.status {
                case .active:
                    Button("Đã uống hết đơn này") { confirmEnd = true }
                        .buttonStyle(HButtonStyle(variant: .danger, fullWidth: true))
                case .paused:
                    Text("Đơn này đang tạm dừng, app không nhắc.")
                        .appFont(.body)
                        .foregroundStyle(theme.muted.color)
                    Button("Uống tiếp đơn này") { setStatus(.active) }
                        .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                case .ended:
                    Text("Đơn này đã uống hết, app không nhắc nữa.")
                        .appFont(.body)
                        .foregroundStyle(theme.muted.color)
                    Button("Dùng lại đơn này") { setStatus(.active) }
                        .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                }

                if !active.isEmpty {
                    SectionTitle("Đang dùng")
                    ForEach(active) { med in medRow(med, routine: routine) }
                }
                if !finished.isEmpty {
                    SectionTitle("Đã hết")
                    ForEach(finished) { med in
                        HCard {
                            HStack {
                                Text(med.displayName)
                                    .appFont(.body)
                                    .foregroundStyle(theme.muted.color)
                                Spacer()
                                Button("Dùng lại") { setFinished(med, false) }
                                    .buttonStyle(HButtonStyle(variant: .outline))
                            }
                        }
                    }
                }

                if let image = PhotoStore.image(rx.photoFile) {
                    SectionTitle("Ảnh đơn gốc")
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Ảnh đơn thuốc gốc")
                }

                if rx.status == .active {
                    HCard {
                        Text("Bác sĩ dặn ngưng ít hôm? Tạm dừng để app thôi nhắc, khi nào uống lại thì bật lại.")
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                        Button("Tạm dừng đơn này") { confirmPause = true }
                            .buttonStyle(HButtonStyle(variant: .outline, fullWidth: true))
                    }
                }

                Button("Đổi tên đơn") {
                    newName = rx.name
                    renaming = true
                }
                .buttonStyle(HButtonStyle(variant: .tertiary, fullWidth: true))
            }
            .padding(16)
        }
        .background(theme.background.color.ignoresSafeArea())
        .navigationTitle(rx.name)
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .alert("Đã uống hết đơn này?", isPresented: $confirmEnd) {
            Button("Đã hết", role: .destructive) { setStatus(.ended) }
            Button("Chưa", role: .cancel) {}
        } message: {
            Text("App sẽ thôi nhắc mọi thuốc trong đơn. Lịch sử vẫn giữ nguyên.")
        }
        .alert("Đổi tên đơn", isPresented: $renaming) {
            TextField("Tên đơn", text: $newName)
            Button("Lưu") {
                let n = newName.trimmingCharacters(in: .whitespaces)
                if !n.isEmpty {
                    rx.name = n
                    try? context.save()
                    NotificationScheduler.reschedule(in: context)
                }
            }
            Button("Huỷ", role: .cancel) {}
        }
        .alert("Tạm dừng đơn này?", isPresented: $confirmPause) {
            Button("Tạm dừng") { setStatus(.paused) }
            Button("Không", role: .cancel) {}
        } message: {
            Text("App sẽ thôi nhắc thuốc của đơn này cho tới khi bạn bật lại.")
        }
        .sheet(item: $editing) { med in
            MedEditSheet(med: med, routine: routine)
        }
        .fullScreenCover(item: Binding(get: { photoFor.map(MedIDs.init) }, set: { photoFor = $0?.ids })) { list in
            NavigationStack {
                BlisterCaptureView(medIDs: list.ids) { photoFor = nil }
            }
        }
    }

    private struct MedIDs: Identifiable { let ids: [UUID]; var id: String { ids.map(\.uuidString).joined() } }

    private func medRow(_ med: Medication, routine: RoutineTimes) -> some View {
        let times = med.timings.map { SlotEngine.minute(of: $0, routine: routine) }.sorted().map(Clock.text)
        return HCard {
            HStack(alignment: .top, spacing: 12) {
                BlisterPair(front: med.frontPhoto, back: med.backPhoto, medName: med.displayName, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(med.displayName)
                        .appFont(.headline)
                        .foregroundStyle(theme.foreground.color)
                    Text("\(med.doseText) · \(times.joined(separator: ", "))")
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                    if med.everyNDays > 0 {
                        Text("Cách \(med.everyNDays) ngày")
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                Button("Sửa") { editing = med }
                    .buttonStyle(HButtonStyle(variant: .secondary))
                if !med.hasPhotos {
                    Button("Chụp vỉ") { photoFor = [med.id] }
                        .buttonStyle(HButtonStyle(variant: .secondary))
                }
                Spacer()
                Button("Đã hết") { setFinished(med, true) }
                    .buttonStyle(HButtonStyle(variant: .outline))
            }
        }
    }

    private func setFinished(_ med: Medication, _ finished: Bool) {
        med.isFinished = finished
        med.finishedAt = finished ? .now : nil
        if finished, rx.medications.allSatisfy(\.isFinished) { rx.status = .ended }
        if !finished, rx.status == .ended { rx.status = .active }
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        if finished {
            toast = ToastMessage(text: "Đã ghi \(med.displayName) là đã hết") { setFinished(med, false) }
        }
    }

    private func setStatus(_ status: PrescriptionStatus) {
        let old = rx.status
        rx.status = status
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        switch status {
        case .ended: toast = ToastMessage(text: "Đã thôi nhắc đơn này") { setStatus(old) }
        case .paused: toast = ToastMessage(text: "Đã tạm dừng đơn này") { setStatus(old) }
        case .active: toast = ToastMessage(text: "App sẽ nhắc lại thuốc của đơn này")
        }
    }
}

/// S5 (MVP): edit name, dose, times; retake blister photos.
struct MedEditSheet: View {
    let med: Medication
    let routine: RoutineTimes
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var draft: DraftMed

    init(med: Medication, routine: RoutineTimes) {
        self.med = med
        self.routine = routine
        _draft = State(initialValue: med.draft)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                DraftMedCard(draft: $draft, routine: routine, startExpanded: true)
                    .padding(16)
            }
            .background(theme.background.color.ignoresSafeArea())
            .navigationTitle("Sửa thuốc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Lưu") {
                    med.apply(draft)
                    try? context.save()
                    NotificationScheduler.reschedule(in: context)
                    dismiss()
                }
                .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
                .padding(16)
                .background(theme.background.color.opacity(0.96))
            }
        }
    }
}
