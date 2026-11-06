import SwiftUI
import UIKit

// Design tokens ported from the approved-candidate token set (v0.1, HeroUI style).
// Source of truth during review: design-system/heroui-lab/src/tokens.css in the spec repo.

/// A colour token with a light and a dark value.
nonisolated struct Tok: Equatable, Sendable {
    let light: UInt32
    let dark: UInt32

    init(_ light: UInt32, _ dark: UInt32) {
        self.light = light
        self.dark = dark
    }

    var color: Color {
        Color(uiColor: Tok.dynamicColor(light: light, dark: dark))
    }

    func hex(_ scheme: ColorScheme) -> UInt32 {
        scheme == .dark ? dark : light
    }

    /// Alpha-blends `self` over `background` per scheme (used for "soft" fills).
    func blended(alpha: Double, over background: Tok) -> Tok {
        Tok(Contrast.blend(light, over: background.light, alpha: alpha),
            Contrast.blend(dark, over: background.dark, alpha: alpha))
    }

    private static func dynamicColor(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

nonisolated extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255,
                  green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255,
                  alpha: 1)
    }
}

/// Accent colour candidates offered at the token review.
nonisolated enum AccentOption: String, CaseIterable, Identifiable, Sendable {
    case teal, blue, mint, terracotta, rose

    var id: String { rawValue }

    var label: String {
        switch self {
        case .teal: "Ngọc lam"
        case .blue: "Xanh lam"
        case .mint: "Xanh bạc hà"
        case .terracotta: "Cam đất"
        case .rose: "Hồng đất"
        }
    }

    var accent: Tok {
        switch self {
        case .teal: Tok(0x0f766e, 0x2dd4bf)
        case .blue: Tok(0x1d4ed8, 0x60a5fa)
        case .mint: Tok(0x00c98e, 0x35d6a4)
        case .terracotta: Tok(0xc2410c, 0xfb923c)
        case .rose: Tok(0xbe123c, 0xfb7185)
        }
    }

    var accentForeground: Tok {
        switch self {
        case .teal: Tok(0xffffff, 0x042f2e)
        case .blue: Tok(0xffffff, 0x172554)
        case .mint: Tok(0x063b2d, 0x063b2d)
        case .terracotta: Tok(0xffffff, 0x431407)
        case .rose: Tok(0xffffff, 0x4c0519)
        }
    }
}

/// Resolved theme: colours, shape and type settings.
nonisolated struct Theme: Equatable, Sendable {
    // Locked for the MVP (token review 05/11/2026, recommended set).
    var accentOption: AccentOption = .mint
    var baseSize: CGFloat = 19
    var rounded = false
    var strongFieldBorder = true

    // Surfaces and text
    let background = Tok(0xf5f6f8, 0x10131b)
    let cardBackground = Tok(0xffffff, 0x1b2130)
    let foreground = Tok(0x111114, 0xf4f4f5)
    let surface = Tok(0xf5f6f8, 0x1b2130)
    let overlay = Tok(0xffffff, 0x2c2c2e)
    let muted = Tok(0x52525b, 0xd4d4d8)
    let defaultFill = Tok(0xe9eaed, 0x3a3a3c)
    let defaultForeground = Tok(0x111114, 0xf4f4f5)

    // Brand
    var accent: Tok { accentOption.accent }
    var accentHighlight: Tok { accentOption == .mint ? Tok(0x4ed7b0, 0x67e2bf) : accent }
    var accentForeground: Tok { accentOption.accentForeground }
    var accentSoft: Tok { accent.blended(alpha: 0.15, over: surface) }
    /// Text on accentSoft. Darker than accent so it reaches AA (teal on soft teal was 4.4:1).
    var accentSoftForeground: Tok {
        switch accentOption {
        case .blue: Tok(0x1e40af, 0x93c5fd)
        case .mint: Tok(0x006b4d, 0x75e8c3)
        case .teal: Tok(0x115e59, 0x5eead4)
        case .terracotta: Tok(0x9a3412, 0xfdba74)
        case .rose: Tok(0x9f1239, 0xfda4af)
        }
    }

    // Status
    let infoSoft = Tok(0xe3eeff, 0x172e4d)
    let infoSoftForeground = Tok(0x1e40af, 0x93c5fd)
    let success = Tok(0x15803d, 0x4ade80)
    let successForeground = Tok(0xffffff, 0x052e16)
    let warning = Tok(0xb45309, 0xfbbf24)
    let warningForeground = Tok(0xffffff, 0x451a03)
    let danger = Tok(0xb91c1c, 0xf87171)
    let dangerForeground = Tok(0xffffff, 0x450a0a)
    let successSoft = Tok(0xdff5e8, 0x173d2b)
    let successSoftForeground = Tok(0x14532d, 0x86efac)
    let warningSoft = Tok(0xfff1dc, 0x493015)
    let warningSoftForeground = Tok(0x92400e, 0xfcd34d)
    let dangerSoft = Tok(0xfee7e7, 0x4a1d22)
    let dangerSoftForeground = Tok(0x991b1b, 0xfca5a5)

    // Lines and fields
    var fieldBorder: Tok { strongFieldBorder ? Tok(0x71717a, 0x71717a) : Tok(0xa1a1aa, 0x71717a) }
    let fieldBackground = Tok(0xffffff, 0x2c2c2e)
    let border = Tok(0xe3e5e8, 0x3f3f46)
    let separator = Tok(0xdfe2e6, 0x30343d)

    // Shape (HeroUI: --radius 0.75rem, scaled by the base size)
    var radius: CGFloat { (baseSize * 0.75).rounded() }
    var fieldRadius: CGFloat { (radius * 1.25).rounded() }
    let cardRadius: CGFloat = 24
    let controlRadius: CGFloat = 8

    // Sizes (M14)
    let buttonHeight: CGFloat = 56
    let touchMin: CGFloat = 48
}

extension EnvironmentValues {
    @Entry var theme = Theme()
}

/// WCAG 2.x contrast helpers.
nonisolated enum Contrast {
    static func luminance(_ hex: UInt32) -> Double {
        func channel(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((hex >> 16) & 0xff)
            + 0.7152 * channel((hex >> 8) & 0xff)
            + 0.0722 * channel(hex & 0xff)
    }

    static func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    static func blend(_ fg: UInt32, over bg: UInt32, alpha: Double) -> UInt32 {
        func mix(_ shift: UInt32) -> UInt32 {
            let f = Double((fg >> shift) & 0xff), b = Double((bg >> shift) & 0xff)
            return UInt32((f * alpha + b * (1 - alpha)).rounded())
        }
        return (mix(16) << 16) | (mix(8) << 8) | mix(0)
    }
}
