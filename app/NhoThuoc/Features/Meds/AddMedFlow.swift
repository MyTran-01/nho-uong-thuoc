import SwiftUI
import SwiftData

/// Add or edit one medication, typed by hand (06/11/2026: no prescription photo any more).
/// 1 name + what it is for → 2 kind, amount → 3 how often + times (suggested from meals)
/// → 4 photo (optional) → 5 review.
/// Editing opens on the review step; each row jumps to its step and comes back.
struct AddMedFlow: View {
    enum Step: Int, CaseIterable { case name = 1, form, schedule, photo, review }

    var editing: Medication?
    var onClose: () -> Void = {}

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Query private var routines: [Routine]
    @Query private var allMeds: [Medication]
    @State private var draft = DraftMed()
    @State private var step: Step = .name
    @State private var forward = true
    @State private var returnToReview = false
    @State private var loaded = false
    @State private var editingTiming: TimingEdit?
    @State private var picker: PickerRequest?
    @State private var confirmDelete = false
    @FocusState private var focus: Field?

    enum Field { case name, purpose }

    private var routine: RoutineTimes { routines.first?.times ?? RoutineTimes() }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    stepContent
                        .id(step)
                        .transition(.asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                                                removal: .opacity))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
            footer
        }
        .background(theme.surface.color.ignoresSafeArea())
        .onAppear(perform: load)
        .sheet(item: $editingTiming) { edit in
            TimingSheet(timing: edit.timing, routine: routine, fixedOnly: edit.fixedOnly) { t in
                apply(t, to: edit)
            }
            .presentationDetents([.fraction(0.85), .large])
        }
        .fullScreenCover(item: $picker) { request in
            ImagePicker(request: request) { image in
                draft.photo = PhotoStore.save(image.squared(), maxSide: 1200)
            }
            .ignoresSafeArea()
        }
        .alert("Xoá thuốc này?", isPresented: $confirmDelete) {
            Button("Xoá", role: .destructive, action: delete)
            Button("Không", role: .cancel) {}
        } message: {
            Text("App sẽ thôi nhắc \(draft.name). Các lần đã dùng vẫn còn trong lịch sử.")
        }
    }

    // MARK: Header and footer

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: back) {
                Image(systemName: step == .name || (editing != nil && step == .review) ? "xmark" : "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.foreground.color)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(theme.cardBackground.color))
            }
            .accessibilityLabel(step == .name ? "Đóng" : "Quay lại")
            HStack(spacing: 5) {
                ForEach(Step.allCases, id: \.self) { s in
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? theme.accent.color : theme.defaultFill.color)
                        .frame(height: 5)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Bước \(step.rawValue) trên \(Step.allCases.count)")
            Text("\(step.rawValue)/\(Step.allCases.count)")
                .appFont(.secondary)
                .monospacedDigit()
                .foregroundStyle(theme.muted.color)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Button(action: next) {
                HStack(spacing: 10) {
                    Text(primaryTitle)
                    if step != .review && !returnToReview { Image(systemName: "arrow.right") }
                }
            }
            .buttonStyle(HButtonStyle(variant: .primary, fullWidth: true, minHeight: theme.buttonHeight))
            .disabled(!canContinue)
            if step == .review, editing != nil {
                Button { confirmDelete = true } label: {
                    Text("Xoá thuốc").foregroundStyle(theme.danger.color)
                }
                .buttonStyle(HButtonStyle(variant: .tertiary, fullWidth: true))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(theme.surface.color)
    }

    private var primaryTitle: String {
        if step == .review { return editing == nil ? "Lưu thuốc" : "Lưu thay đổi" }
        if returnToReview { return "Xong" }
        if step == .photo && draft.photo == nil { return "Bỏ qua, để sau" }
        return "Tiếp theo"
    }

    private var canContinue: Bool {
        switch step {
        case .name: !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
        case .schedule: !(draft.frequency == .custom && draft.custom == .weekdays && draft.weekdays.isEmpty)
        default: true
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .name: nameStep
        case .form: formStep
        case .schedule: scheduleStep
        case .photo: photoStep
        case .review: reviewStep
        }
    }

    // 1
    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Bạn dùng thuốc gì?")
            BigField(placeholder: "Tên thuốc, ví dụ: Amlodipin", text: $draft.name)
                .focused($focus, equals: .name)
                .submitLabel(.next)
                .onSubmit { focus = .purpose }
            sectionHeader("Dùng để làm gì?", optional: true)
                .padding(.top, 12)
            BigField(placeholder: "ví dụ: Huyết áp, trị mụn", text: $draft.purpose)
                .focused($focus, equals: .purpose)
                .submitLabel(.done)
            FlowLayout(spacing: 8, lineSpacing: 4) {
                ForEach(purposeSuggestions, id: \.self) { p in
                    OutlineChip(label: p, isOn: draft.purpose.caseInsensitiveCompare(p) == .orderedSame) {
                        draft.purpose = draft.purpose.caseInsensitiveCompare(p) == .orderedSame ? "" : p
                    }
                }
            }
        }
    }

    /// The user's own groups first, then a few common ones.
    private var purposeSuggestions: [String] {
        var seen = Set<String>()
        let mine = allMeds.map(\.purpose).filter { !$0.isEmpty }
        return (mine + ["Huyết áp", "Tiểu đường", "Trị mụn", "Dạ dày", "Vitamin"])
            .filter { seen.insert($0.lowercased()).inserted }
            .prefix(8).map { $0 }
    }

    // 2
    private var formStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Thuốc loại nào?")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(MedForm.allCases, id: \.self) { f in
                    FormTile(form: f, isOn: draft.form == f) { setForm(f) }
                }
            }
            sectionHeader("Mỗi liều bao nhiêu?", optional: false)
                .padding(.top, 12)
            DoseStepper(halves: $draft.doseHalves, form: draft.form)
        }
    }

    private func setForm(_ f: MedForm) {
        guard f != draft.form else { return }
        let wasCount = draft.form == .tablet || draft.form == .capsule
        let isCount = f == .tablet || f == .capsule
        draft.doseHalves = wasCount && isCount ? Dose.snapped(draft.doseHalves, form: f) : f.defaultHalves
        draft.form = f
    }

    // 3
    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Bao lâu dùng một lần?")
            FrequencyRow(title: "Một lần mỗi ngày", isOn: draft.frequency == .once) { setFrequency(.once) }
            FrequencyRow(title: "Hai lần mỗi ngày", isOn: draft.frequency == .twice) { setFrequency(.twice) }
            FrequencyRow(title: "3 lần mỗi ngày", isOn: draft.frequency == .thrice) { setFrequency(.thrice) }
            FrequencyRow(title: "Lịch khác", subtitle: "Vài giờ một lần hoặc vào một số ngày",
                         isOn: draft.frequency == .custom) { setFrequency(.custom) }
            if draft.frequency == .custom {
                customCard
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            timesBlock
                .padding(.top, 12)
        }
        .animation(.easeInOut(duration: 0.2), value: draft.frequency)
        .animation(.easeInOut(duration: 0.2), value: draft.custom)
    }

    private var customCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            FlowLayout(spacing: 8, lineSpacing: 4) {
                ForEach(CustomSchedule.allCases, id: \.self) { c in
                    OutlineChip(label: c.label, isOn: draft.custom == c, filled: true) { setCustom(c) }
                }
            }
            switch draft.custom {
            case .weekdays:
                WeekdayPicker(selection: $draft.weekdays)
                if draft.weekdays.isEmpty {
                    Text("Chọn ít nhất một ngày.")
                        .appFont(.secondary)
                        .foregroundStyle(theme.danger.color)
                }
                timesPerDayPicker
            case .everyNDays:
                miniLabel("Cách mấy ngày?")
                FlowLayout(spacing: 8, lineSpacing: 4) {
                    ForEach(1...3, id: \.self) { n in
                        OutlineChip(label: "Cách \(n) ngày", isOn: draft.everyNDays == n) { draft.everyNDays = n }
                    }
                }
                Text(draft.everyNDays == 1 ? "Dùng hôm nay, nghỉ 1 ngày, rồi dùng tiếp." : "Dùng hôm nay, nghỉ \(draft.everyNDays) ngày, rồi dùng tiếp.")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
                timesPerDayPicker
            case .everyHours:
                miniLabel("Mấy tiếng một lần?")
                FlowLayout(spacing: 8, lineSpacing: 4) {
                    ForEach([4, 6, 8, 12], id: \.self) { h in
                        OutlineChip(label: "\(h) tiếng", isOn: draft.everyHours == h) {
                            draft.everyHours = h
                            regenerateHours()
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.cardBackground.color))
    }

    private var timesPerDayPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            miniLabel("Mỗi ngày dùng mấy lần?")
            FlowLayout(spacing: 8, lineSpacing: 4) {
                ForEach(1...3, id: \.self) { n in
                    OutlineChip(label: "\(n) lần", isOn: draft.customTimesPerDay == n) {
                        draft.customTimesPerDay = n
                        draft.timings = TimingSuggest.forCount(n, keeping: draft.timings)
                    }
                }
            }
        }
    }

    private var timesBlock: some View {
        let hourly = draft.frequency == .custom && draft.custom == .everyHours
        let sorted = draft.timings.enumerated()
            .map { (index: $0.offset, timing: $0.element, minute: SlotEngine.minute(of: $0.element, routine: routine)) }
            .sorted { $0.minute < $1.minute }
        return VStack(alignment: .leading, spacing: 10) {
            Text(hourly ? "Giờ dùng (chạm giờ đầu tiên để đổi)" : "Giờ (chạm để đổi)")
                .appFont(.secondary)
                .foregroundStyle(theme.muted.color)
            FlowLayout(spacing: 10, lineSpacing: 10) {
                ForEach(Array(sorted.enumerated()), id: \.offset) { pos, row in
                    TimeChip(timing: row.timing, minute: row.minute, interactive: !hourly || pos == 0,
                             caption: hourly ? (pos == 0 ? "Bắt đầu" : nil) : TimingText.short(row.timing)) {
                        editingTiming = TimingEdit(index: row.index, timing: row.timing, fixedOnly: hourly)
                    }
                }
            }
            if !hourly {
                Text("Giờ gợi ý theo giờ ăn, giờ ngủ của bạn.")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
            }
        }
    }

    private func setFrequency(_ f: Frequency) {
        draft.frequency = f
        if f == .custom {
            setCustom(draft.custom, force: true)
        } else {
            draft.timings = TimingSuggest.forCount(f.timesPerDay, keeping: draft.timings.filter { $0.anchor != .fixed })
        }
    }

    private func setCustom(_ c: CustomSchedule, force: Bool = false) {
        guard force || c != draft.custom else { return }
        draft.custom = c
        if c == .everyHours {
            regenerateHours()
        } else {
            draft.timings = TimingSuggest.forCount(draft.customTimesPerDay,
                                                   keeping: draft.timings.filter { $0.anchor != .fixed })
        }
    }

    private func regenerateHours(start: Int? = nil) {
        let first = start
            ?? draft.timings.map { SlotEngine.minute(of: $0, routine: routine) }.min().map { $0 % 1440 }
            ?? routine.breakfast + routine.afterMeal
        draft.timings = TimingSuggest.everyHours(draft.everyHours, start: first, routine: routine)
    }

    private func apply(_ t: Timing, to edit: TimingEdit) {
        if edit.fixedOnly {
            regenerateHours(start: SlotEngine.minute(of: t, routine: routine) % 1440)
        } else if draft.timings.indices.contains(edit.index) {
            draft.timings[edit.index] = t
        }
    }

    // 4
    private var photoStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Thêm ảnh thuốc")
            Text("Lúc tới giờ, app hiện ảnh này để bạn lấy đúng viên. Không bắt buộc.")
                .appFont(.body)
                .foregroundStyle(theme.muted.color)
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.cardBackground.color)
                if let image = PhotoStore.image(draft.photo) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: draft.form.symbol)
                            .font(.system(size: 54))
                        Text("Chụp vỉ, hộp hoặc viên thuốc")
                            .appFont(.secondary)
                    }
                    .foregroundStyle(theme.muted.color)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 320)
            .frame(maxWidth: .infinity)
            .accessibilityElement()
            .accessibilityLabel(draft.photo == nil ? "Chưa có ảnh" : "Ảnh thuốc \(draft.name)")
            HStack(spacing: 10) {
                if Camera.isAvailable {
                    Button {
                        picker = PickerRequest(source: .camera, square: true)
                    } label: {
                        Label("Chụp ảnh", systemImage: "camera.fill")
                    }
                    .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
                }
                Button {
                    picker = PickerRequest(source: .photoLibrary, square: true)
                } label: {
                    Label("Chọn ảnh", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(HButtonStyle(variant: .secondary, fullWidth: true))
            }
            if draft.photo != nil {
                Button("Bỏ ảnh") { draft.photo = nil }
                    .buttonStyle(HButtonStyle(variant: .tertiary, fullWidth: true))
            }
        }
    }

    // 5
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            title(editing == nil ? "Kiểm tra lại" : "Thông tin thuốc")
            HStack(spacing: 14) {
                MedThumb(file: draft.photo, form: draft.form, name: draft.name, size: 76)
                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.name)
                        .appFont(.title)
                        .foregroundStyle(theme.foreground.color)
                    if !draft.purpose.isEmpty {
                        Text(draft.purpose)
                            .appFont(.secondary)
                            .foregroundStyle(theme.muted.color)
                    }
                }
            }
            VStack(spacing: 0) {
                reviewRow("Tên, dùng để làm gì", value: draft.purpose.isEmpty ? draft.name : "\(draft.name) · \(draft.purpose)", step: .name)
                divider
                reviewRow("Loại thuốc", value: draft.form.label, step: .form)
                divider
                reviewRow("Mỗi liều", value: draft.doseText, step: .form)
                divider
                reviewRow("Lịch dùng", value: draft.scheduleText, step: .schedule)
                divider
                reviewRow("Giờ dùng", value: timesText, step: .schedule)
                divider
                reviewRow("Ảnh", value: draft.photo == nil ? "Chưa có" : "Đã có", step: .photo)
            }
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.cardBackground.color))
        }
    }

    private var timesText: String {
        draft.timings
            .map { (SlotEngine.minute(of: $0, routine: routine), $0) }
            .sorted { $0.0 < $1.0 }
            .map { "\(Clock.text($0.0)) (\(TimingText.short($0.1)))" }
            .joined(separator: ", ")
    }

    private var divider: some View {
        Divider().overlay(theme.separator.color).padding(.leading, 18)
    }

    private func reviewRow(_ label: String, value: String, step target: Step) -> some View {
        Button {
            returnToReview = true
            go(target)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .appFont(.secondary)
                        .foregroundStyle(theme.muted.color)
                    Text(value)
                        .appFont(.body)
                        .foregroundStyle(theme.foreground.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Sửa")
                    .appFont(.secondary)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.accentSoftForeground.color)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Chạm để sửa")
    }

    // MARK: Layout helpers

    private func title(_ text: String) -> some View {
        Text(text)
            .appFont(.display)
            .foregroundStyle(theme.foreground.color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 8)
            .accessibilityAddTraits(.isHeader)
    }

    private func sectionHeader(_ text: String, optional: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text)
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
            Spacer()
            if optional {
                Text("Tùy chọn")
                    .appFont(.secondary)
                    .foregroundStyle(theme.muted.color)
            }
        }
    }

    private func miniLabel(_ text: String) -> some View {
        Text(text)
            .appFont(.secondary)
            .foregroundStyle(theme.muted.color)
    }

    // MARK: Navigation

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let editing {
            draft = editing.draft
            step = .review
        } else {
            draft.timings = TimingSuggest.forCount(1, keeping: [])
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))
                focus = .name
            }
        }
    }

    private func go(_ target: Step) {
        focus = nil
        forward = target.rawValue > step.rawValue
        withAnimation(.easeInOut(duration: 0.25)) { step = target }
    }

    private func next() {
        if step == .review { save(); return }
        if returnToReview { returnToReview = false; go(.review); return }
        if let n = Step(rawValue: step.rawValue + 1) { go(n) }
    }

    private func back() {
        if returnToReview { returnToReview = false; go(.review); return }
        if step == .name || (editing != nil && step == .review) { close(); return }
        if let p = Step(rawValue: step.rawValue - 1) { go(p) }
    }

    private func close() {
        onClose()
        dismiss()
    }

    private func save() {
        if let editing {
            editing.apply(draft)
        } else {
            context.insert(Medication(draft: draft))
        }
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        Router.shared.toast = ToastMessage(text: editing == nil ? "Đã thêm \(draft.name)" : "Đã lưu \(draft.name)")
        close()
    }

    private func delete() {
        guard let editing else { return }
        context.delete(editing)
        try? context.save()
        NotificationScheduler.reschedule(in: context)
        Router.shared.toast = ToastMessage(text: "Đã xoá \(draft.name)")
        close()
    }
}

/// Which time chip is being edited.
struct TimingEdit: Identifiable {
    let id = UUID()
    let index: Int
    let timing: Timing
    /// Every-few-hours: only the start clock time can change.
    let fixedOnly: Bool
}

// MARK: Pieces

/// Large rounded text field, as on the reference screens.
struct BigField: View {
    let placeholder: String
    @Binding var text: String
    @Environment(\.theme) private var theme

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(theme.muted.color.opacity(0.7)))
            .appFont(.headline)
            .foregroundStyle(theme.foreground.color)
            .padding(.horizontal, 20)
            .frame(minHeight: 60)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(theme.cardBackground.color))
    }
}

/// One kind of medication on the 4-column grid.
private struct FormTile: View {
    let form: MedForm
    let isOn: Bool
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: form.symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .frame(height: 30)
                    .foregroundStyle(isOn ? theme.accentSoftForeground.color : theme.muted.color)
                Text(form.label)
                    .appFont(.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(isOn ? theme.accentSoftForeground.color : theme.foreground.color)
            }
            .frame(maxWidth: .infinity, minHeight: 92)
            .padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(theme.cardBackground.color))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(isOn ? theme.accent.color : .clear, lineWidth: 2.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(form.label)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// "1 viên nang  − +" in a card.
private struct DoseStepper: View {
    @Binding var halves: Int
    let form: MedForm
    @Environment(\.theme) private var theme

    var body: some View {
        let step = form.stepHalves
        HStack(spacing: 12) {
            Text(Dose.text(halves: halves, form: form))
                .appFont(.title)
                .monospacedDigit()
                .foregroundStyle(theme.foreground.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.updatesFrequently)
            stepButton("minus", label: "Bớt", enabled: halves > step) { halves = max(step, halves - step) }
            stepButton("plus", label: "Thêm", enabled: halves < step * 40) { halves = min(step * 40, halves + step) }
        }
        .padding(.leading, 20)
        .padding(.trailing, 14)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.cardBackground.color))
    }

    private func stepButton(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(theme.foreground.color)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.defaultFill.color))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

/// One frequency option with a round check on the right.
private struct FrequencyRow: View {
    let title: String
    var subtitle: String?
    let isOn: Bool
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .appFont(.headline)
                        .foregroundStyle(theme.foreground.color)
                    if let subtitle {
                        Text(subtitle)
                            .appFont(.secondary)
                            .foregroundStyle(isOn ? theme.accentSoftForeground.color : theme.muted.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle()
                        .strokeBorder(isOn ? theme.accent.color : theme.muted.color.opacity(0.6), lineWidth: 2)
                    if isOn {
                        Circle().fill(theme.accent.color)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(theme.accentForeground.color)
                    }
                }
                .frame(width: 30, height: 30)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 66)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(theme.cardBackground.color))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isOn ? theme.accent.color : .clear, lineWidth: 2.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Capsule option: outlined when off, filled with the accent when on.
struct OutlineChip: View {
    let label: String
    let isOn: Bool
    var filled = false
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(label)
                .appFont(.secondary)
                .foregroundStyle(isOn ? theme.background.color : theme.foreground.color)
                .padding(.horizontal, 14)
                .frame(minHeight: 38)
                // Selected tags are filled with the dark text colour (06/11/2026), not the brand colour.
                .background(Capsule().fill(isOn ? theme.foreground.color : .clear))
                // Unselected: no fill, only a light outline (06/11/2026).
                .overlay(Capsule().strokeBorder(isOn ? .clear : theme.muted.color.opacity(0.22), lineWidth: 1))
                // Visual 38pt, tap area 44pt.
                .padding(.vertical, 3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// T2 … CN as round toggles.
private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.order, id: \.self) { d in
                let on = selection.contains(d)
                Button {
                    if on { selection.remove(d) } else { selection.insert(d) }
                } label: {
                    Text(Weekday.short(d))
                        .appFont(.chip)
                        .foregroundStyle(on ? theme.background.color : theme.foreground.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Circle().fill(on ? theme.foreground.color : theme.surface.color))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(d == 1 ? "Chủ nhật" : "Thứ \(d)")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// "☀ 9:00" — tap to change.
private struct TimeChip: View {
    let timing: Timing
    let minute: Int
    let interactive: Bool
    var caption: String?
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Image(systemName: TimingText.symbol(minute: minute, anchor: timing.anchor))
                        .font(.system(size: 18, weight: .medium))
                    Text(Clock.text(minute))
                        .appFont(.headline)
                        .monospacedDigit()
                }
                .foregroundStyle(theme.foreground.color)
                if let caption {
                    Text(caption)
                        .appFont(.label)
                        .foregroundStyle(theme.muted.color)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(minHeight: 60)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(theme.cardBackground.color))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(interactive)
        .accessibilityLabel("\(Clock.text(minute)), \(TimingText.short(timing))")
        .accessibilityHint(interactive ? "Chạm để đổi giờ" : "")
    }
}

/// Words for a timing, used on chips and in the review.
enum TimingText {
    static func short(_ t: Timing) -> String {
        switch t.anchor {
        case .fixed: return "Giờ cố định"
        case .afternoon: return "Buổi chiều"
        case .bed: return "Trước khi ngủ"
        default:
            let meal = t.anchor == .breakfast ? "sáng" : t.anchor == .lunch ? "trưa" : "tối"
            switch t.relation {
            case .before: return "Trước ăn \(meal)"
            case .during: return "Trong bữa \(meal)"
            case .after, .at: return "Sau ăn \(meal)"
            }
        }
    }

    static func symbol(minute: Int, anchor: Anchor) -> String {
        if anchor == .bed { return "bed.double" }
        let m = minute % 1440
        if m >= 4 * 60 && m < 11 * 60 { return "sun.horizon" }
        if m >= 11 * 60 && m < 17 * 60 { return "sun.max" }
        return "moon"
    }
}

/// Photo, or the kind's symbol when there is none.
struct MedThumb: View {
    let file: String?
    let form: MedForm
    let name: String
    var size: CGFloat = 64
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let image = PhotoStore.image(file) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: form.symbol)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(theme.accentSoftForeground.color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.accentSoft.color)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(file == nil ? name : "Ảnh \(name)")
    }
}

// MARK: Change one time

/// Pick the part of the day and how it relates to the meal; the clock time follows the routine.
/// "Giờ khác" sets a fixed clock time instead.
struct TimingSheet: View {
    @State var timing: Timing
    let routine: RoutineTimes
    var fixedOnly = false
    let onDone: (Timing) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    private static let parts: [(Anchor, String)] = [
        (.breakfast, "Sáng"), (.lunch, "Trưa"), (.afternoon, "Chiều"), (.dinner, "Tối"), (.bed, "Trước ngủ"), (.fixed, "Giờ khác"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Clock.text(minute))
                            .appFont(.display)
                            .monospacedDigit()
                            .foregroundStyle(theme.foreground.color)
                            .contentTransition(.numericText())
                        Text(TimingText.short(timing))
                            .appFont(.body)
                            .foregroundStyle(theme.muted.color)
                    }
                    if !fixedOnly {
                        FlowLayout(spacing: 8, lineSpacing: 4) {
                            ForEach(Self.parts, id: \.0) { anchor, label in
                                OutlineChip(label: label, isOn: timing.anchor == anchor) { setAnchor(anchor) }
                            }
                        }
                    }
                    details
                }
                .padding(20)
                .animation(.snappy, value: timing)
            }
            .background(theme.surface.color.ignoresSafeArea())
            .navigationTitle(fixedOnly ? "Giờ bắt đầu" : "Đổi giờ dùng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        onDone(timing)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear { if fixedOnly { timing = .fixed(minute % 1440) } }
    }

    private var minute: Int { SlotEngine.minute(of: timing, routine: routine) }

    @ViewBuilder
    private var details: some View {
        switch timing.anchor {
        case .fixed:
            DatePicker("Giờ", selection: fixedBinding, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .environment(\.locale, Locale(identifier: "vi_VN"))
        case .afternoon:
            note("Theo giờ buổi chiều trong Cài đặt (\(Clock.text(routine.afternoon))).")
        case .bed:
            label("Trước khi ngủ bao lâu?")
            offsetChips([15, 30, 60, 120], fallback: routine.beforeBed)
        default:
            label("So với bữa ăn")
            FlowLayout(spacing: 8, lineSpacing: 4) {
                OutlineChip(label: "Trước ăn", isOn: timing.relation == .before) { setRelation(.before) }
                OutlineChip(label: "Trong bữa", isOn: timing.relation == .during) { setRelation(.during) }
                OutlineChip(label: "Sau ăn", isOn: timing.relation == .after) { setRelation(.after) }
            }
            if timing.relation == .before {
                label("Trước ăn bao lâu?")
                offsetChips([15, 30, 45, 60], fallback: routine.beforeMeal)
            } else if timing.relation == .after {
                label("Sau ăn bao lâu?")
                offsetChips([0, 15, 30, 60], fallback: routine.afterMeal)
            }
        }
    }

    private var fixedBinding: Binding<Date> {
        Binding(
            get: {
                let m = (timing.offsetMinutes ?? 9 * 60) % 1440
                return SlotEngine.calendar.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: .now) ?? .now
            },
            set: { d in
                let c = SlotEngine.calendar.dateComponents([.hour, .minute], from: d)
                timing = .fixed((c.hour ?? 0) * 60 + (c.minute ?? 0))
            })
    }

    private func setAnchor(_ a: Anchor) {
        guard a != timing.anchor else { return }
        if a == .fixed {
            timing = .fixed(minute % 1440)
        } else if [.breakfast, .lunch, .dinner].contains(a), [.breakfast, .lunch, .dinner].contains(timing.anchor) {
            // Keep "trước ăn 30 phút" when moving from one meal to another.
            timing.anchor = a
        } else {
            timing = .standard(a)
        }
    }

    private func setRelation(_ r: Relation) {
        guard r != timing.relation else { return }
        timing = Timing(anchor: timing.anchor, relation: r)
    }

    private func offsetChips(_ options: [Int], fallback: Int) -> some View {
        let current = timing.offsetMinutes ?? fallback
        return FlowLayout(spacing: 8, lineSpacing: 4) {
            ForEach(options, id: \.self) { m in
                OutlineChip(label: offsetLabel(m), isOn: current == m) {
                    timing.offsetMinutes = m
                    timing.offsetSource = .user
                }
            }
        }
    }

    private func offsetLabel(_ m: Int) -> String {
        if m == 0 { return "Ngay sau" }
        if m >= 60, m % 60 == 0 { return "\(m / 60) tiếng" }
        return "\(m) phút"
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .appFont(.secondary)
            .foregroundStyle(theme.muted.color)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .appFont(.body)
            .foregroundStyle(theme.muted.color)
    }
}
