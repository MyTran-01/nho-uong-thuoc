import SwiftUI
import UIKit

/// Type roles. Sizes are at the default base (19pt) and default Dynamic Type size,
/// then scaled by the chosen base size and by the user's Dynamic Type setting.
enum TextRole: CaseIterable {
    case display, title, headline, body, secondary, button, chip, label

    var size: CGFloat {
        switch self {
        case .display: 34
        case .title: 28
        case .headline: 21
        case .body: 19
        case .secondary: 17
        case .button: 20
        case .chip: 16
        case .label: 15
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .title: .bold
        case .headline, .button, .chip: .semibold
        case .label: .semibold
        case .body, .secondary: .regular
        }
    }

    var textStyle: UIFont.TextStyle {
        switch self {
        case .display: .largeTitle
        case .title: .title1
        case .label: .footnote
        default: .body
        }
    }

    var name: String {
        switch self {
        case .display: "Giờ lớn"
        case .title: "Tiêu đề"
        case .headline: "Tên thuốc, chữ chính"
        case .body: "Chữ thường"
        case .secondary: "Chữ phụ"
        case .button: "Chữ trên nút"
        case .chip: "Nhãn trạng thái"
        case .label: "Nhãn nhỏ"
        }
    }
}

private struct AppFont: ViewModifier {
    let role: TextRole
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.font(.system(size: pointSize, weight: role.weight, design: theme.rounded ? .rounded : .default))
    }

    private var pointSize: CGFloat {
        let base = role.size * theme.baseSize / 19
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        return UIFontMetrics(forTextStyle: role.textStyle).scaledValue(for: base, compatibleWith: traits)
    }
}

extension View {
    func appFont(_ role: TextRole) -> some View {
        modifier(AppFont(role: role))
    }
}
