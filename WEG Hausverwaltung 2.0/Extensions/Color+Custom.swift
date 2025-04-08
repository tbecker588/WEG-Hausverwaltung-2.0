import SwiftUI

extension Color {
    // MARK: - Design System Colors
    static var cardWhite: Color { DesignSystem.Colors.card }
    static var backgroundGray: Color { DesignSystem.Colors.background }
    static var primaryBlue: Color { DesignSystem.Colors.primary }
    static var secondaryMint: Color { DesignSystem.Colors.secondary }
    
    // MARK: - Legacy Support (Deprecated)
    @available(*, deprecated, message: "Bitte DesignSystem.Colors verwenden")
    static var passwordsBlue: Color { DesignSystem.Colors.primary }
    
    @available(*, deprecated, message: "Bitte DesignSystem.Colors verwenden")
    static var passwordsGray: Color { DesignSystem.Colors.Button.secondary }
    
    // MARK: - Utility Methods
    func withOpacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }
    
    static func dynamicColor(
        light: @escaping @autoclosure () -> Color,
        dark: @escaping @autoclosure () -> Color
    ) -> Color {
        #if os(iOS)
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark())
            default:
                return UIColor(light())
            }
        })
        #else
        return light()
        #endif
    }
    
    static let customBackground = Color("Background")
    static let customText = Color("Text")
    
    static let primaryBackground = Color("PrimaryBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    static let primaryText = Color("PrimaryText")
    
    // Weitere Farben hier hinzufügen
}