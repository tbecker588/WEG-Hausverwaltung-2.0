import SwiftUI

/// Zentrale Definition des Design Systems
enum DesignSystem {
    /// Farbdefinitionen der App
    enum Colors {
        // MARK: - Hauptfarben
        static let primary = Color.blue
        static let secondary = Color.mint
        static let background = Color(UIColor.systemGroupedBackground)
        static let card = Color.white
        
        // MARK: - Textfarben
        static let text = Color.primary
        static let textSecondary = Color.secondary
        
        // MARK: - Statusfarben
        static let error = Color.red
        static let success = Color.green
        static let warning = Color.yellow
        static let info = Color.blue
        
        // MARK: - Button-Farben
        enum Button {
            static let primary = Colors.primary
            static let secondary = Color.gray.opacity(0.1)
            static let destructive = Colors.error
            static let disabled = Color.gray.opacity(0.3)
        }
        
        // MARK: - Listen-Farben
        enum List {
            static let background = Colors.background
            static let rowBackground = Colors.card
            static let separator = Color.gray.opacity(0.2)
            static let selectedBackground = primary.opacity(0.1)
        }
    }
    
    // MARK: - Layout-Definitionen
    enum Layout {
        // Einheitliche Spacing-Definitionen
        enum Spacing {
            static let tiny: CGFloat = 4
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let extraLarge: CGFloat = 32
        }
        
        // Container-Größen
        enum Container {
            static let maxWidth: CGFloat = 414 // iPhone Max width
            static let defaultPadding: CGFloat = Layout.Spacing.medium
            static let listRowHeight: CGFloat = 44
            static let navigationBarHeight: CGFloat = 44
            static let tabBarHeight: CGFloat = 49
        }
        
        // Icon-Größen
        enum Icon {
            static let small: CGFloat = 16
            static let medium: CGFloat = 24
            static let large: CGFloat = 32
            static let extraLarge: CGFloat = 44
        }
        
        // Komponentenspezifische Abstände
        enum Component {
            static let listRowVertical: CGFloat = Spacing.small
            static let sectionVertical: CGFloat = Spacing.large
            static let cardPadding: CGFloat = Spacing.medium
            static let buttonHeight: CGFloat = 44
            static let inputFieldHeight: CGFloat = 44
        }
    }
    
    // MARK: - Corner Radius-Definitionen
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    // MARK: - Button-Styles
    enum ButtonStyles {
        /// Standard-Button mit Primärfarbe
        struct PrimaryButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .padding()
                    .background(Colors.Button.primary)
                    .foregroundColor(.white)
                    .cornerRadius(Layout.Spacing.small)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1)
            }
        }
        
        /// Sekundärer Button mit Outline
        struct SecondaryButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .padding()
                    .background(Colors.Button.secondary)
                    .foregroundColor(Colors.Button.primary)
                    .cornerRadius(Layout.Spacing.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.Spacing.small)
                            .stroke(Colors.Button.primary, lineWidth: 1)
                    )
                    .scaleEffect(configuration.isPressed ? 0.95 : 1)
            }
        }
        
        /// Lösch-/Warnungs-Button
        struct DestructiveButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .padding()
                    .background(Colors.Button.destructive)
                    .foregroundColor(.white)
                    .cornerRadius(Layout.Spacing.small)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1)
            }
        }
    }
    
    // MARK: - View Modifiers
    enum ViewModifiers {
        struct CardModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .padding(Layout.Spacing.medium)
                    .background(Colors.card)
                    .cornerRadius(Layout.Spacing.small)
                    .shadow(radius: 2, y: 1)
            }
        }
        
        struct ListRowModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .padding(Layout.Spacing.small)
                    .background(Colors.List.rowBackground)
                    .cornerRadius(Layout.Spacing.small)
            }
        }
        
        struct InputFieldModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .padding(Layout.Spacing.small)
                    .background(Colors.List.rowBackground)
                    .cornerRadius(Layout.Spacing.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.Spacing.small)
                            .stroke(Colors.List.separator, lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Wendet Primary Button Style an
    func primaryButtonStyle() -> some View {
        self.buttonStyle(DesignSystem.ButtonStyles.PrimaryButtonStyle())
    }
    
    /// Wendet Secondary Button Style an
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(DesignSystem.ButtonStyles.SecondaryButtonStyle())
    }
    
    /// Wendet Destructive Button Style an
    func destructiveButtonStyle() -> some View {
        self.buttonStyle(DesignSystem.ButtonStyles.DestructiveButtonStyle())
    }
    
    /// Wendet Card Style an
    func cardStyle() -> some View {
        self.modifier(DesignSystem.ViewModifiers.CardModifier())
    }
    
    /// Wendet List Row Style an
    func listRowStyle() -> some View {
        self.modifier(DesignSystem.ViewModifiers.ListRowModifier())
    }
    
    /// Wendet Input Field Style an
    func inputFieldStyle() -> some View {
        self.modifier(DesignSystem.ViewModifiers.InputFieldModifier())
    }
}
