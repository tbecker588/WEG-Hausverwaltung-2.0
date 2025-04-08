import SwiftUI
import CoreData

struct AdminView: View {
    @State private var password = ""
    @Environment(\.managedObjectContext) var context
    var billing: AnnualBilling  // Korrektur: Richtige Entity verwenden

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
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let billing = AnnualBilling(context: context)  // Korrektur: Richtige Entity verwenden
        billing.year = 2025
        billing.isVerified = true
        return AdminView(billing: billing)
            .environment(\.managedObjectContext, context)
    }
}