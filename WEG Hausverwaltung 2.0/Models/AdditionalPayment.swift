import CoreData
import Foundation

@objc(AdditionalPayment)
public class AdditionalPayment: NSManagedObject {
    @NSManaged
    public var amount: Double
    @NSManaged
    public var title: String?
    @NSManaged
    public var date: Date?

    // MARK: - Berechnete Eigenschaften

    var isValid: Bool {
        guard amount > 0,
              !(title?.isEmpty ?? true),
              date != nil
        else {
            return false
        }
        return true
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: amount)) ?? "€0,00"
    }

    var formattedDate: String {
        guard let date else { return "Kein Datum" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    // MARK: - Beispieldaten

    static var example: AdditionalPayment {
        let payment = AdditionalPayment(context: PersistenceController.preview.container.viewContext)
        payment.id = UUID()
        payment.title = "Instandhaltungsrücklage"
        payment.amount = 500.0
        payment.date = Date()
        payment.isPaid = false
        return payment
    }
}
