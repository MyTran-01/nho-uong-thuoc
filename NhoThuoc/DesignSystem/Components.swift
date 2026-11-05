import SwiftUI

// SwiftUI components rebuilt in HeroUI v3 style from the theme tokens.

// MARK: Button

enum HButtonVariant {
    case primary, secondary, tertiary, outline, danger
}

struct HButtonStyle: ButtonStyle {
    var variant: HButtonVariant = .primary
    var fullWidth = false
    var minHeight: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        HButtonBody(configuration: configuration, variant: variant, fullWidth: fullWidth, minHeight: minHeight)
    }
}

private struct HButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let variant: HButtonVariant
    let fullWidth: Bool
    let minHeight: CGFloat?
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .appFont(.button)
            .multilineTextAlignment(.center)
            .foregroundStyle(foreground)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: minHeight ?? theme.touchMin)
            .background(Capsule().fill(background))
            .overlay {
                if variant == .outline {
                    // HeroUI uses --border here; that is ~1.4:1 on white, too faint for
                    // a control people must find. Use the field border (≥ 3:1 target).
                    Capsule().strokeBorder(theme.fieldBorder.color, lineWidth: 1.5)
                }
            }
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var background: Color {
        switch variant {
        case .primary: theme.accent.color
        case .secondary, .tertiary: theme.defaultFill.color
        case .outline: .clear
        case .danger: theme.danger.color
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: theme.accentForeground.color
        // HeroUI tints secondary text with the accent; we use the main text colour
        // so the label stays AAA on the grey fill (M14).
        case .secondary, .tertiary, .outline: theme.defaultForeground.color
        case .danger: theme.dangerForeground.color
        }
    }
}

// MARK: Card

struct HCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: theme.cardRadius, style: .continuous)
                    .fill(theme.surface.color)
                    .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.06), radius: 3, y: 1)
            )
    }
}

// MARK: Chip

enum HChipColor { case accent, success, warning, danger, neutral }
enum HChipVariant { case solid, soft }

struct HChip: View {
    let text: String
    var color: HChipColor = .neutral
    var variant: HChipVariant = .solid
    @Environment(\.theme) private var theme

    var body: some View {
        Text(text)
            .appFont(.chip)
            .foregroundStyle(colors.fg.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(colors.bg.color))
    }

    private var colors: (bg: Tok, fg: Tok) {
        switch (color, variant) {
        case (.accent, .soft): (theme.accentSoft, theme.accent)
        case (.accent, .solid): (theme.accent, theme.accentForeground)
        case (.success, _): (theme.success, theme.successForeground)
        case (.warning, _): (theme.warning, theme.warningForeground)
        case (.danger, _): (theme.danger, theme.dangerForeground)
        case (.neutral, _): (theme.defaultFill, theme.defaultForeground)
        }
    }
}

// MARK: Checkbox

struct HCheckbox: View {
    @Binding var isOn: Bool
    let label: String
    @Environment(\.theme) private var theme

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: theme.controlRadius, style: .continuous)
                    .fill(isOn ? theme.accent.color : theme.fieldBackground.color)
                RoundedRectangle(cornerRadius: theme.controlRadius, style: .continuous)
                    .strokeBorder(isOn ? theme.accent.color : theme.fieldBorder.color, lineWidth: 2)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(theme.accentForeground.color)
                    .opacity(isOn ? 1 : 0)
            }
            .frame(width: 30, height: 30)
            .frame(minWidth: theme.touchMin, minHeight: theme.touchMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "Đã uống" : "Chưa uống")
        .sensoryFeedback(.selection, trigger: isOn)
    }
}

// MARK: Text field

struct HTextField: View {
    let label: String
    @Binding var text: String
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .appFont(.secondary)
                .foregroundStyle(theme.muted.color)
            TextField(label, text: $text)
                .appFont(.body)
                .foregroundStyle(theme.foreground.color)
                .padding(.horizontal, 14)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: theme.fieldRadius, style: .continuous)
                        .fill(theme.fieldBackground.color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.fieldRadius, style: .continuous)
                        .strokeBorder(theme.fieldBorder.color, lineWidth: 1.5)
                )
        }
    }
}

// MARK: Option group (choose instead of type, M12)

struct HOptionGroup<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value

    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(options, id: \.value) { option in
                Button(option.label) { selection = option.value }
                    .buttonStyle(HButtonStyle(variant: option.value == selection ? .primary : .outline))
                    .accessibilityAddTraits(option.value == selection ? .isSelected : [])
            }
        }
    }
}
