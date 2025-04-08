import SwiftUI
import LocalAuthentication

struct SecureActionView: View {
    @State private var authenticated = false
    @State private var message = "Nicht authentifiziert"
    var onAuthenticated: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(.headline)
                .foregroundColor(authenticated ? DesignSystem.Colors.success : DesignSystem.Colors.text)
            
            if !authenticated {
                Button("Authentifizieren") {
                    authenticateUser()
                }
                .buttonStyle(DesignSystem.ButtonStyles.PasswordsButtonStyle())
            } else {
                Text("Zugriff gewährt!")
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
        .padding()
        .background(DesignSystem.Colors.background)
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        let reason = "Bitte authentifizieren Sie sich, um diese Aktion zu bestätigen."
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        authenticated = true
                        message = "Authentifizierung erfolgreich!"
                        onAuthenticated()
                    } else {
                        authenticated = false
                        message = "Authentifizierung fehlgeschlagen: \(authError?.localizedDescription ?? "Unbekannter Fehler")"
                    }
                }
            }
        } else {
            message = "Geräte-Authentifizierung nicht verfügbar."
        }
    }
}

// Preview mit Mock-Handler
struct SecureActionView_Previews: PreviewProvider {
    static var previews: some View {
        SecureActionView {
            print("Authentifizierung erfolgreich")
        }
    }
}