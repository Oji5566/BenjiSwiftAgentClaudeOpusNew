import SwiftUI

/// Shared visual constants. The app deliberately leans on system colours
/// and SF Symbols rather than hard-coded hex values from the original web
/// app, so it picks up Light/Dark modes and Dynamic Type for free.
enum Theme {
    /// Brand accent — only used where the system's `accentColor` isn't
    /// already in play (e.g. progress bars). Mirrors the web `--color-brand`.
    static let brand = Color(red: 0x0F / 255, green: 0x6C / 255, blue: 0xBD / 255)

    /// Subtle background tint used behind grouped settings/cards in light
    /// mode. Resolves to `systemGroupedBackground` so dark mode is correct.
    static let groupedBackground = Color(.systemGroupedBackground)
}

extension Color {
    static let buyTint  = Color.green
    static let skipTint = Color.red
    static let watchTint = Color.orange
}

/// Glass-style background container — used by the calculator hero and the
/// tab bar for an iOS-26-style Liquid Glass surface, falling back to
/// `.thinMaterial` on older OS versions.
struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassBackground()) }
}
