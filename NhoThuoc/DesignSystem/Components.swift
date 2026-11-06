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
    /// Tighter side padding for option chips.
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        HButtonBody(configuration: configuration, variant: variant, fullWidth: fullWidth, minHeight: minHeight, compact: compact)
    }
}

private struct HButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let variant: HButtonVariant
    let fullWidth: Bool
    let minHeight: CGFloat?
    let compact: Bool
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    private var isProminent: Bool {
        (variant == .primary || variant == .danger) && fullWidth && (minHeight ?? 0) >= theme.buttonHeight
    }

    var body: some View {
        configuration.label
            .appFont(compact ? .chip : isProminent ? .button : .secondary)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
            .foregroundStyle(foreground)
            .padding(.horizontal, isProminent ? 20 : compact ? 12 : 14)
            .padding(.vertical, isProminent ? 10 : compact ? 3 : 5)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: minHeight ?? (compact ? 38 : theme.touchMin))
            .background(Capsule().fill(background))
            .overlay(Capsule().strokeBorder(isUnselectedChip ? theme.muted.color.opacity(0.22) : .clear, lineWidth: 1))
            .shadow(color: isProminent ? theme.accent.color.opacity(0.20) : .clear,
                    radius: isProminent ? 6 : 0, y: isProminent ? 3 : 0)
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    /// A selected option chip: dark fill instead of the brand colour.
    private var isSelectedChip: Bool { compact && variant == .primary }
    /// An unselected option chip: no fill, light outline only.
    private var isUnselectedChip: Bool { compact && variant == .secondary }

    private var background: LinearGradient {
        if isSelectedChip {
            return LinearGradient(colors: [theme.foreground.color], startPoint: .top, endPoint: .bottom)
        }
        if isUnselectedChip {
            return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
        let color: Color
        switch variant {
        case .primary: color = isProminent ? theme.accent.color : theme.accentSoft.color
        case .secondary, .outline: color = theme.defaultFill.color
        case .tertiary: color = .clear
        case .danger: color = theme.danger.color
        }
        return LinearGradient(colors: isProminent && variant == .primary
                              ? [theme.accentHighlight.color, color]
                              : [color, color], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var foreground: Color {
        if isSelectedChip { return theme.background.color }
        return switch variant {
        case .primary: isProminent ? theme.accentForeground.color : theme.accentSoftForeground.color
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
                    .fill(theme.cardBackground.color)
                    .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.07), radius: 14, y: 5)
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
        case (.accent, .soft): (theme.accentSoft, theme.accentSoftForeground)
        case (.accent, .solid): (theme.accent, theme.accentForeground)
        case (.success, _): (theme.successSoft, theme.successSoftForeground)
        case (.warning, _): (theme.warningSoft, theme.warningSoftForeground)
        case (.danger, _): (theme.dangerSoft, theme.dangerSoftForeground)
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
                    .fill(isOn ? theme.accent.color : theme.defaultFill.color)
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
                        .shadow(color: .black.opacity(0.035), radius: 5, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.fieldRadius, style: .continuous)
                        .strokeBorder(theme.fieldBorder.color, lineWidth: 1)
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
                    .buttonStyle(HButtonStyle(variant: option.value == selection ? .primary : .secondary, compact: true))
                    .accessibilityAddTraits(option.value == selection ? .isSelected : [])
            }
        }
    }
}

// MARK: Bottom CTA

/// A recessed track that blends into the page instead of floating above it.
struct InsetTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            tab(.today, title: "Hôm nay", icon: "sun.max.fill")
            tab(.meds, title: "Thuốc", icon: "pills.fill")
            tab(.settings, title: "Cài đặt", icon: "gearshape.fill")
        }
        .padding(6)
        .background {
            Capsule()
                .fill(theme.surface.color
                    .shadow(.inner(color: .black.opacity(scheme == .dark ? 0.24 : 0.08), radius: 3, x: 1, y: 2))
                    .shadow(.inner(color: .white.opacity(scheme == .dark ? 0.04 : 0.8), radius: 2, x: -1, y: -2)))
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(theme.background.color.ignoresSafeArea(edges: .bottom))
    }

    private func tab(_ value: AppTab, title: String, icon: String) -> some View {
        let selected = selection == value
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                selection = value
            }
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                    Text(title)
                }
                VStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(title)
                }
            }
            .font(.system(.subheadline, weight: selected ? .semibold : .medium))
            .foregroundStyle(selected ? theme.foreground.color : theme.muted.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: theme.touchMin)
            .background {
                if selected {
                    Capsule().fill(theme.cardBackground.color)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("tab.\(value)")
    }
}

/// Pins a screen's main action to the bottom, inside the thumb zone and above the
/// tab bar. Rule: when a screen has a single primary CTA, it lives here, not at the top.
struct BottomCTA<Actions: View>: ViewModifier {
    var isShown: Bool
    @ViewBuilder var actions: Actions
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            if isShown {
                VStack(spacing: 8) { actions }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(theme.background.color)
                    .background(alignment: .top) {
                        LinearGradient(colors: [theme.background.color.opacity(0), theme.background.color],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 24)
                            .offset(y: -24)
                            .allowsHitTesting(false)
                    }
            }
        }
    }
}

extension View {
    func bottomCTA<Actions: View>(when isShown: Bool = true, @ViewBuilder _ actions: () -> Actions) -> some View {
        modifier(BottomCTA(isShown: isShown, actions: actions))
    }
}
