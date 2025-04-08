import SwiftUI

extension Font {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title = Font.system(size: 22, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let caption = Font.system(size: 13, weight: .medium)
    
    // MARK: - Schriftgrößen für die App
    
    /// Große Überschrift (34pt, bold)
    /// Verwendung: Hauptüberschriften, Startseite
    static let appLargeTitle = Font.system(size: 34, weight: .bold)
    
    /// Standard-Überschrift (22pt, semibold)
    /// Verwendung: Sektionsüberschriften, Formulartitel
    static let appTitle = Font.system(size: 22, weight: .semibold)
    
    /// Standardtext (17pt, regular)
    /// Verwendung: Normaler Text, Listendarstellung
    static let appBody = Font.system(size: 17, weight: .regular)
    
    /// Kleine Beschriftung (13pt, medium)
    /// Verwendung: Zusatzinformationen, Labels
    static let appCaption = Font.system(size: 13, weight: .medium)
    
    // MARK: - Hilfsmethoden
    
    /// Erzeugt eine benutzerdefinierte Schriftgröße
    /// - Parameters:
    ///   - size: Schriftgröße in Punkten
    ///   - weight: Schriftstärke (.regular, .medium, etc.)
    static func custom(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}