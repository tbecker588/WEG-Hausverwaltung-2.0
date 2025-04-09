/**
 * @file    DesignSystem.swift
 * @brief   Zentrale Design-Definitionen der App
 * @author  Thomas Becker
 * @date    09.04.2024
 */

import SwiftUI

/// Enthält alle Design-Konstanten der Anwendung
public enum DesignSystem {
    /// Definiert die Abstände im Layout
    public enum Spacing {
        /// Kleiner Abstand (8 Punkte)
        public static let small: CGFloat = 8
        /// Mittlerer Abstand (16 Punkte)
        public static let medium: CGFloat = 16
        /// Großer Abstand (24 Punkte)
        public static let large: CGFloat = 24
    }

    /// Definiert die Farbpalette
    public enum Colors {
        /// Primärfarbe der Anwendung
        public static let primary = Color("Primary")
        /// Sekundärfarbe für Akzente
        public static let secondary = Color("Secondary")
        /// Hintergrundfarbe
        public static let background = Color("Background")
    }

    /// Definiert die Typographie
    public enum Typography {
        /// Überschriften-Stil
        public static let title = Font.title
        /// Standard-Textstil
        public static let body = Font.body
        /// Kleiner Textstil
        public static let caption = Font.caption
    }
}
