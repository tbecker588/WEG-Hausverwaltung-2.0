import SwiftUI

// Farben laut Passwörter-App
extension Color {
    static let passwordsBlue = Color(red: 0/255, green: 122/255, blue: 255/255)
    static let passwordsGray = Color(.systemGroupedBackground)
    static let passwordsCell = Color(.secondarySystemGroupedBackground)
}

// Button-Style, angelehnt an die Passwörter-App
struct PasswordsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.passwordsBlue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}