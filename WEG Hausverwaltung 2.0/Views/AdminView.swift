import SwiftUI
import CoreData

struct AdminView: View {
    @State private var password = ""
    @Environment(\.managedObjectContext) var context
    var billing: Billing  // Annahme: Billing ist ein Core Data-Modell

    var body: some View {
        VStack(spacing: 20) {
            SecureField("Admin-Passwort", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Entsperren") {
                if AuthService.shared.verifyOverride(password: password) {
                    billing.isVerified = false
                    do {
                        try context.save()
                        print("Billing wurde entsperrt!")
                    } catch {
                        print("Fehler beim Speichern: \(error)")
                    }
                } else {
                    print("Falsches Passwort")
                }
            }
        }
        .padding()
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        // Da PersistenceController hier in SwiftData kein Standard ist, verwenden wir einen Dummy-Context für die Vorschau.
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let billing = Billing()  // Stelle sicher, dass Billing initialisierbar ist.
        billing.year = 2025
        billing.isVerified = true
        return AdminView(billing: billing)
            .environment(\.managedObjectContext, context)
    }
}