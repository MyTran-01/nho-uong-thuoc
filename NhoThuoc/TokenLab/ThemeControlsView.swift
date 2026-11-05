import SwiftUI

/// The four open token questions, answered by tapping.
struct ThemeControlsView: View {
    @Bindable var settings: ThemeSettings
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    group("1. Màu chủ đạo") {
                        FlowLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(AccentOption.allCases) { option in
                                Button {
                                    settings.accent = option
                                } label: {
                                    HStack(spacing: 8) {
                                        Circle().fill(option.accent.color).frame(width: 22, height: 22)
                                        Text(option.label)
                                    }
                                }
                                .buttonStyle(HButtonStyle(variant: settings.accent == option ? .secondary : .outline))
                                .overlay {
                                    if settings.accent == option {
                                        Capsule().strokeBorder(theme.foreground.color, lineWidth: 2.5)
                                    }
                                }
                                .accessibilityAddTraits(settings.accent == option ? .isSelected : [])
                            }
                        }
                    }

                    group("2. Cỡ chữ gốc") {
                        HOptionGroup(options: [(CGFloat(19), "19 · đề xuất"), (CGFloat(21), "21 · to hơn")],
                                     selection: $settings.baseSize)
                    }

                    group("3. Kiểu chữ") {
                        HOptionGroup(options: [(false, "Thường"), (true, "Bo tròn")], selection: $settings.rounded)
                    }

                    group("4. Viền ô nhập, ô tích, nút chọn (chế độ sáng)") {
                        HOptionGroup(options: [(false, "Nhạt · hiện tại"), (true, "Đậm hơn · đề xuất")],
                                     selection: $settings.strongFieldBorder)
                    }

                    group("Giao diện") {
                        HOptionGroup(options: AppearanceOption.allCases.map { ($0, $0.label) },
                                     selection: $settings.appearance)
                    }
                }
                .padding(16)
            }
            .background(theme.background.color)
            .navigationTitle("Tuỳ chỉnh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .appFont(.headline)
                .foregroundStyle(theme.foreground.color)
            content()
        }
    }
}
