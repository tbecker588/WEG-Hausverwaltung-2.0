//
//  AbrechnungTheme.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftUI

/// Design-System für Hausverwaltung Abrechnung
enum AbrechnungTheme {
    // Primärfarben
    static let heizung = Color.blue          // Heizkostenabrechnung
    static let wasser = Color(red: 0.8, green: 0.2, blue: 0.2)  // Wasserkosten (rot)
    static let sonstige = Color.green        // Sonstige Kosten
    
    // Status-Farben
    static let positive = Color.green        // Guthaben
    static let negative = Color.red          // Nachzahlung
    static let neutral = Color.gray
    
    // Grautöne (von Lagerplatz übernommen)
    static let darkGray = Color.gray.opacity(0.8)
    static let mediumGray = Color.gray.opacity(0.6)
    static let lightGray = Color.gray.opacity(0.3)
    
    // Hintergrundfarben
    static let backgroundColor = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    
    // Text Farben
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
}

// MARK: - View Extensions

extension View {
    func abrechnungStyle() -> some View {
        accentColor(AbrechnungTheme.heizung)
            .background(AbrechnungTheme.backgroundColor)
    }
}
