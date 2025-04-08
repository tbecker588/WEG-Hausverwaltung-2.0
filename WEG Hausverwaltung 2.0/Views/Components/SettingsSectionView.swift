import SwiftUI

/// Eine wiederverwendbare Komponente für Einstellungseinträge
/// 
/// Verwendung:
/// ```swift
/// SettingsSectionView(
///     title: "Meine Einstellung",
///     icon: "gear",
///     destination: AnyView(SettingsDetailView())
/// )
/// ```
struct SettingsSectionView: View {
    // MARK: - Properties
    
    /// Der angezeigte Titel
    let title: String
    
    /// SF Symbol Name für das Icon
    let icon: String
    
    /// Farbe des Icons (Standard: primary)
    let color: Color
    
    /// Zielview für die Navigation
    let destination: AnyView
    
    // MARK: - Initialization
    
    init(
        title: String,
        icon: String,
        color: Color = DesignSystem.Colors.primary,
        destination: AnyView
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.destination = destination
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                
                Text(title)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint("Tippen um Details anzuzeigen")
    }
}

// MARK: - Previews
struct SettingsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Heller Modus
            NavigationStack {
                List {
                    SettingsSectionView(
                        title: "Allgemeine Einstellungen",
                        icon: "gear",
                        destination: AnyView(Text("Einstellungen"))
                    )
                    
                    SettingsSectionView(
                        title: "Benachrichtigungen",
                        icon: "bell.badge",
                        color: .red,
                        destination: AnyView(Text("Benachrichtigungen"))
                    )
                    
                    SettingsSectionView(
                        title: "Sicherheit",
                        icon: "lock.shield",
                        color: .green,
                        destination: AnyView(Text("Sicherheit"))
                    )
                }
            }
            .previewDisplayName("Light Mode")
            
            // Dunkler Modus
            NavigationStack {
                List {
                    SettingsSectionView(
                        title: "Beispiel-Einstellung",
                        icon: "gear",
                        destination: AnyView(Text("Einstellungen"))
                    )
                }
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}