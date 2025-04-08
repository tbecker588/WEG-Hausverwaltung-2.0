import Foundation
import CoreData

// MARK: - Formatierungs-Konstanten
private extension WEG {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
}

extension WEG {
    // MARK: - Berechnete Eigenschaften
    
    /// Vollständige Adresse der WEG (einzeilig)
    var fullAddress: String {
        guard !street.isEmpty else { return "Keine Adresse" }
        return "\(street) \(houseNumber ?? ""), \(postalCode) \(city)"
    }
    
    /// Kontaktinformationen der WEG
    var contactInfo: String {
        guard let contact = contact, !contact.isEmpty else { 
            return "Kein Ansprechpartner"
        }
        return "Ansprechpartner: \(contact)"
    }
    
    /// Formatierte E-Mail-Adresse
    var formattedEmail: String {
        guard let email = email, !email.isEmpty else {
            return "Keine E-Mail"
        }
        return email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Formatierte Telefonnummer
    var formattedPhone: String {
        phone ?? "Keine Telefonnummer"
    }
    
    /// Baujahr als String
    var constructionYearString: String {
        constructionYear > 0 ? String(constructionYear) : "Unbekannt"
    }
    
    /// Formatierte Gesamtfläche
    var formattedTotalArea: String {
        formatArea(totalArea)
    }
    
    /// Anzahl der Wohnungen als String
    var apartmentCountString: String {
        apartmentCount > 0 ? String(apartmentCount) : "Unbekannt"
    }
    
    // MARK: - Validierung
    
    var isValid: Bool {
        guard !street.isEmpty,
              !city.isEmpty,
              !postalCode.isEmpty,
              totalArea > 0 else {
            return false
        }
        return true
    }
    
    // MARK: - Beispieldaten für Vorschau
    static var example: WEG {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let weg = WEG(context: context)
        weg.id = UUID()
        weg.name = "WEG Musterstraße 123"
        weg.street = "Musterstraße"
        weg.houseNumber = "123"
        weg.postalCode = "12345"
        weg.city = "Musterstadt"
        weg.administrator = "Hausverwaltung GmbH"
        weg.contact = "Max Mustermann"
        weg.email = "info@hausverwaltung.de"
        weg.phone = "+49 123 456789"
        weg.constructionYear = 1985
        weg.apartmentCount = 6
        weg.totalArea = 450.0
        return weg
    }
    
    // MARK: - Formatierungshelfer
    
    /// Formatiert einen Geldbetrag
    func formatCurrency(_ amount: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "€0,00"
    }
    
    /// Formatiert ein Datum
    func formatDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
    
    /// Formatiert eine Fläche
    func formatArea(_ area: Double) -> String {
        guard area >= 0 else { return "0,0 m²" }
        return String(format: "%.1f m²", area)
    }
}

// MARK: - Sortierung
extension WEG {
    static func sort(_ wegs: [WEG], by sortOrder: WEGSortOrder = .name) -> [WEG] {
        switch sortOrder {
        case .name:
            return wegs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .city:
            return wegs.sorted { $0.city.localizedCaseInsensitiveCompare($1.city) == .orderedAscending }
        case .size:
            return wegs.sorted { $0.totalArea > $1.totalArea }
        }
    }
}

enum WEGSortOrder {
    case name, city, size
}
