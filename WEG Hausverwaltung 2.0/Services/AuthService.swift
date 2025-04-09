import Foundation
import LocalAuthentication
import SwiftUI

class AuthService: ObservableObject {
    static let shared = AuthService()
    private let context = LAContext()

    @Published
    var isAdmin = false
    @Published
    var authError: String?

    // Füge eine Eigenschaft für den aktuellen Benutzer hinzu:
    var currentUser: String? {
        // Beispielrückgabe – passe dies an deine Logik an
        "Admin"
    }

    // Beispiel-Methode, wenn du lieber eine Funktion nutzen möchtest:
    func userName() -> String {
        currentUser ?? "Unbekannter Benutzer"
    }

    private init() {}

    // Dummy-Implementierung; passe die Logik ggf. an
    func verifyOverride(password: String) -> Bool {
        password == "admin"
    }

    // Biometrie-Abfrage
    func verifyWithBiometrics(reason: String = "Admin-Zugriff erforderlich", completion: @escaping (Bool) -> Void) {
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context
                .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.isAdmin = true
                            completion(true)
                        } else {
                            self.authError = error?.localizedDescription ?? "Authentifizierung fehlgeschlagen"
                            completion(false)
                        }
                    }
                }
        } else {
            authError = "Biometrie nicht verfügbar"
            completion(false)
        }
    }

    // Passwort-Override (für Fallback)
    func verifyWithPassword(_ password: String) -> Bool {
        // Hier echte Logik implementieren
        let correctPassword = "WEG2024" // Beispiel
        isAdmin = (password == correctPassword)
        return isAdmin
    }
}
