import SwiftUI

struct AppTheme {
    struct Colors {
        let primary: Color
        let secondary: Color
        let background: Color
        let surface: Color
        let surfaceSecondary: Color
        let textPrimary: Color
        let textSecondary: Color
        let accentGreen: Color
        let accentRed: Color
        let chartColors: [Color]
        let tabBarBackground: Color
        let divider: Color
        let glassBackground: Color
    }

    struct Typography {
        let displayLarge: Font
        let headlineMedium: Font
        let titleLarge: Font
        let titleMedium: Font
        let bodyLarge: Font
        let bodyMedium: Font
        let labelMedium: Font
        let labelSmall: Font
    }

    struct Shapes {
        let small: CGFloat
        let medium: CGFloat
        let large: CGFloat
        let extraLarge: CGFloat
        let pill: CGFloat
    }

    let colors: Colors
    let typography: Typography
    let shapes: Shapes

    static let light = AppTheme(
        colors: Colors(
            primary: Color(red: 0 / 255, green: 137 / 255, blue: 123 / 255),
            secondary: Color(red: 77 / 255, green: 182 / 255, blue: 172 / 255),
            background: Color(red: 242 / 255, green: 247 / 255, blue: 246 / 255),
            surface: Color.white,
            surfaceSecondary: Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255),
            textPrimary: Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255),
            textSecondary: Color(red: 99 / 255, green: 99 / 255, blue: 102 / 255),
            accentGreen: Color(red: 38 / 255, green: 166 / 255, blue: 154 / 255),
            accentRed: Color(red: 239 / 255, green: 83 / 255, blue: 80 / 255),
            chartColors: [
                Color(red: 0 / 255, green: 137 / 255, blue: 123 / 255),
                Color(red: 77 / 255, green: 182 / 255, blue: 172 / 255),
                Color(red: 128 / 255, green: 203 / 255, blue: 196 / 255),
                Color(red: 178 / 255, green: 223 / 255, blue: 219 / 255),
                Color(red: 0 / 255, green: 77 / 255, blue: 64 / 255),
            ],
            tabBarBackground: Color.white.opacity(0.85),
            divider: Color.black.opacity(0.08),
            glassBackground: Color.white.opacity(0.72)
        ),
        typography: Typography(
            displayLarge: .system(size: 34, weight: .bold, design: .default),
            headlineMedium: .system(size: 24, weight: .semibold, design: .default),
            titleLarge: .system(size: 20, weight: .semibold, design: .default),
            titleMedium: .system(size: 17, weight: .semibold, design: .default),
            bodyLarge: .system(size: 17, weight: .regular, design: .default),
            bodyMedium: .system(size: 15, weight: .regular, design: .default),
            labelMedium: .system(size: 13, weight: .medium, design: .default),
            labelSmall: .system(size: 12, weight: .medium, design: .default)
        ),
        shapes: Shapes(
            small: 8,
            medium: 12,
            large: 16,
            extraLarge: 24,
            pill: 50
        )
    )

    static let dark = AppTheme(
        colors: Colors(
            primary: Color(red: 72 / 255, green: 169 / 255, blue: 153 / 255),
            secondary: Color(red: 0 / 255, green: 121 / 255, blue: 107 / 255),
            background: Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255),
            surface: Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255),
            surfaceSecondary: Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255),
            textPrimary: Color(red: 229 / 255, green: 229 / 255, blue: 234 / 255),
            textSecondary: Color(red: 152 / 255, green: 152 / 255, blue: 157 / 255),
            accentGreen: Color(red: 56 / 255, green: 180 / 255, blue: 166 / 255),
            accentRed: Color(red: 255 / 255, green: 105 / 255, blue: 97 / 255),
            chartColors: [
                Color(red: 72 / 255, green: 169 / 255, blue: 153 / 255),
                Color(red: 0 / 255, green: 137 / 255, blue: 123 / 255),
                Color(red: 77 / 255, green: 182 / 255, blue: 172 / 255),
                Color(red: 128 / 255, green: 203 / 255, blue: 196 / 255),
                Color(red: 0 / 255, green: 77 / 255, blue: 64 / 255),
            ],
            tabBarBackground: Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255).opacity(0.85),
            divider: Color.white.opacity(0.08),
            glassBackground: Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255).opacity(0.72)
        ),
        typography: Typography(
            displayLarge: .system(size: 34, weight: .bold, design: .default),
            headlineMedium: .system(size: 24, weight: .semibold, design: .default),
            titleLarge: .system(size: 20, weight: .semibold, design: .default),
            titleMedium: .system(size: 17, weight: .semibold, design: .default),
            bodyLarge: .system(size: 17, weight: .regular, design: .default),
            bodyMedium: .system(size: 15, weight: .regular, design: .default),
            labelMedium: .system(size: 13, weight: .medium, design: .default),
            labelSmall: .system(size: 12, weight: .medium, design: .default)
        ),
        shapes: Shapes(
            small: 8,
            medium: 12,
            large: 16,
            extraLarge: 24,
            pill: 50
        )
    )
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .light
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

struct GlassBackground: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: theme.shapes.large)
                    .fill(theme.colors.glassBackground)
                    .shadow(
                        color: .black.opacity(0.04),
                        radius: 8, x: 0, y: 2
                    )
            )
    }
}

struct CardBackground: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: theme.shapes.medium)
                    .fill(theme.colors.surface)
                    .shadow(
                        color: .black.opacity(0.06),
                        radius: 4, x: 0, y: 1
                    )
            )
    }
}

extension View {
    func glassBackground() -> some View {
        modifier(GlassBackground())
    }

    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
