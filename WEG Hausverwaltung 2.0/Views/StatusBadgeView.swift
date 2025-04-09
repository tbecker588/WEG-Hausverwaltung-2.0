//
// StatusBadgeView.swift
// WEG Hausverwaltung 2.0
//
// Created by Thomas Becker on 09.04.2024.
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

// MARK: - StatusBadgeView

/// Ein View zur Anzeige des Abrechnungsstatus in der WEG-Hausverwaltung.
/// Verwendet das zentrale DesignSystem für konsistentes Styling.
struct StatusBadgeView: View {
    // MARK: - Properties

    let status: BillingStatusType

    // MARK: - Body

    var body: some View {
        Text(status.rawValue)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Private Properties

    private var statusColor: Color {
        switch status {
        case .paid: DesignSystem.Colors.success
        case .unpaid: DesignSystem.Colors.error
        case .partial: DesignSystem.Colors.warning
        }
    }

    private var accessibilityLabel: String {
        switch status {
        case .paid: "Vollständig bezahlt"
        case .unpaid: "Nicht bezahlt"
        case .partial: "Teilweise bezahlt"
        }
    }
}

#if DEBUG

    // MARK: - Previews

    struct StatusBadgeView_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 20) {
                StatusBadgeView(status: .paid)
                StatusBadgeView(status: .unpaid)
                StatusBadgeView(status: .partial)
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
#endif
