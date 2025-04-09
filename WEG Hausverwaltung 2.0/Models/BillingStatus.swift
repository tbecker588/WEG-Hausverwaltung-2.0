/**
 * @file    BillingStatus.swift
 * @brief   Definition des Abrechnungsstatus
 * @author  Thomas Becker
 * @date    08.04.2024
 */

import Foundation

/// Status einer Abrechnung
enum BillingStatus: String, Codable, CaseIterable {
    /// Vollständig bezahlt
    case paid = "Bezahlt"
    /// Noch nicht bezahlt
    case unpaid = "Offen"
    /// Teilweise bezahlt
    case partial = "Teilweise bezahlt"

    /// Farbe für den Status
    var color: Color {
        switch self {
        case .paid:
            DesignSystem.Colors.primary
        case .unpaid:
            .red
        case .partial:
            .orange
        }
    }

    /// Icon für den Status
    var icon: String {
        switch self {
        case .paid:
            "checkmark.circle.fill"
        case .unpaid:
            "exclamationmark.circle.fill"
        case .partial:
            "timer"
        }
    }
}
