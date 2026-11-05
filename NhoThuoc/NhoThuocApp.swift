import SwiftUI

@main
struct NhoThuocApp: App {
    @State private var settings = ThemeSettings()

    var body: some Scene {
        WindowGroup {
            TokenLabView()
                .environment(settings)
                .environment(\.theme, settings.theme)
                .tint(settings.theme.accent.color)
                .preferredColorScheme(settings.appearance.scheme)
        }
    }
}
