import SwiftUI

/// Eine generische Zeile für die Anzeige von Informationen im Key-Value Format
struct InfoRow: View {
    // MARK: - Properties
    
    /// Der Titel/Schlüssel der Information
    let title: String
    
    /// Der Wert/Inhalt der Information
    let value: String
    
    /// Optionale Formatierung für den Titel
    var titleColor: Color = DesignSystem.Colors.textSecondary
    
    /// Optionale Formatierung für den Wert
    var valueColor: Color = DesignSystem.Colors.text
    
    // MARK: - Body
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(titleColor)
                .font(.body)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .font(.body)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Previews
struct InfoRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            InfoRow(
                title: "Bezeichnung",
                value: "Beispielwert"
            )
            
            InfoRow(
                title: "Status",
                value: "Aktiv",
                valueColor: .green
            )
            
            InfoRow(
                title: "Lange Information",
                value: "Dies ist ein sehr langer Informationstext, der über mehrere Zeilen gehen kann"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
