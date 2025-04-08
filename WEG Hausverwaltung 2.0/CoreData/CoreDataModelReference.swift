import Foundation
import CoreData

final class CoreDataModelReference {
    static let shared = CoreDataModelReference()
    
    private init() {}
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WEG_Hausverwaltung_2_0")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData Fehler: \(error.localizedDescription)")
            }
        }
        return container
    }()
}

/**
 # CoreData-Modell-Referenz für WEG Hausverwaltung 2.0
 
 Diese Datei dient als vollständige Referenz für alle CoreData-Entitäten und deren Attribute.
 Sie dokumentiert den aktuellen Stand des Datenmodells und fehlende Implementierungen.
 
 ## Legende:
 ✅ - Im Modell implementiert
 ❌ - Fehlt im Modell
 🔄 - Berechnete Eigenschaft (Computed Property)
 📱 - UI-relevante Eigenschaft
 🔍 - Suchrelevantes Attribut
 
 ## WEG (Wohnungseigentümergemeinschaft)
 ✅ id: UUID? (optional)                       // Eindeutige Identifikation der WEG
 ✅ name: String                              // Name der WEG (z.B. "WEG Musterstraße 1")
 ✅ street: String                            // Straßenname
 ❌ houseNumber: String? (optional)           // Hausnummer (z.B. "1a")
 ✅ city: String                              // Stadt
 ✅ postalCode: String                        // Postleitzahl (z.B. "12345")
 ✅ totalArea: Double                         // Gesamtfläche in Quadratmetern
 ❌ administrator: String? (optional)         // Name des WEG-Verwalters
 ❌ contact: String? (optional)               // Primärer Ansprechpartner
 ❌ email: String? (optional)                 // Kontakt-E-Mail
 ❌ phone: String? (optional)                 // Kontakt-Telefonnummer
 ❌ constructionYear: Int16                   // Baujahr des Gebäudes
 ❌ apartmentCount: Int16                     // Anzahl der Wohneinheiten
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 🔄 fullAddress: String                       // Formatierte Adresse einzeilig
 🔄 formattedAddress: String                  // Formatierte Adresse mehrzeilig
 📱 displayTitle: String                      // Anzeigename für UI (name + city)

 ### Beziehungen:
 ✅ owners: Set<Owner> (To-Many)              // Alle Eigentümer der WEG
 ✅ annualBillings: Set<AnnualBilling> (To-Many) // Alle Jahresabrechnungen
 ❌ documents: Set<Document>                  // Allgemeine WEG-Dokumente
 
 ## Owner (Eigentümer)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation
 ✅ firstName: String                         // Vorname
 ✅ lastName: String                          // Nachname
 ✅ email: String? (optional)                 // E-Mail-Adresse
 ✅ phoneNumber: String? (optional)           // Telefonnummer
 ✅ apartmentNumber: String? (optional)       // Wohnungsnummer (z.B. "App. 3")
 ✅ floorNumber: String? (optional)           // Etagennummer (z.B. "1. OG")
 ✅ ownershipShare: Double                    // Eigentumsanteil in Prozent
 ✅ occupantCount: Int16                      // Anzahl der Bewohner
 ❌ isRented: Bool                            // Vermietungsstatus
 ❌ iban: String? (optional)                  // Bankverbindung für Erstattungen
 ❌ emergencyContactName: String?             // Notfallkontakt Name
 ❌ emergencyContactPhone: String?            // Notfallkontakt Telefon
 ❌ garageNumber: String?                     // Garagenstellplatz-Nummer
 ❌ basementNumber: String?                   // Kellerraum-Nummer
 ❌ areaSqm: Double                           // Wohnfläche in m²
 ❌ lastModified: Date                        // Letzte Änderung der Daten
 ❌ moveInDate: Date?                         // Einzugsdatum
 ❌ communicationPreference: String?          // Bevorzugte Kontaktart
 ❌ notes: String?                            // Interne Notizen

 🔄 fullName: String                          // Vor- und Nachname
 🔄 displayName: String                       // Anzeigename (inkl. Wohnungsnummer)
 🔄 apartmentInfo: String                     // Wohnungsinformationen
 📱 statusBadge: String                       // UI-Status (aktiv/inaktiv)
 🔍 searchText: String                        // Suchtext für Filterung

 ### Beziehungen:
 ✅ apartmentBillings: Set<ApartmentBilling>  // Einzelabrechnungen
 ✅ heaters: Set<Heater>                      // Zugeordnete Heizkörper
 ✅ tenants: Set<Tenant>                      // Aktuelle Mieter
 ❌ documents: Set<Document>                  // Eigentümerdokumente
 ✅ weg: WEG? (To-One)                        // Zugehörige WEG

 ## Heater (Heizkörper)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation des Heizkörpers
 ✅ identifier: String? (optional)            // Neue einheitliche Zählernummer
 ✅ room: String                              // Raumbezeichnung (z.B. "Wohnzimmer")
 ✅ lastReading: String                        // Letzter abgelesener Zählerstand
 ✅ type: String? (optional)                  // Typ des Heizkörpers (z.B. "Rippe")
 ✅ installationDate: Date? (optional)        // Datum der Installation
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 🔄 factor: Double                            // Wird als UserDefaults-Wert gespeichert
 🔄 displayName: String                       // Anzeigename (Zählernummer + Raum)

 ### Beziehungen:
 ✅ owner: Owner? (To-One)                    // Zugehöriger Eigentümer
 ✅ meterReadings: Set<MeterReading> (To-Many) // Alle Ablesungen dieses Heizkörpers
 
 ## MeterReading (Zählerstand)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation der Ablesung
 ✅ date: Date                                // Datum der Ablesung
 ✅ currentValue: Double                      // Aktueller Zählerstand
 ✅ previousValue: Double                     // Vorheriger Zählerstand
 ✅ signature: Data? (optional)               // Unterschrift des Ablesers/Eigentümers
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 🔄 consumption: Double                       // Verbrauch (currentValue - previousValue)

 ### Beziehungen:
 ✅ heater: Heater? (To-One)                  // Zugehöriger Heizkörper
 
 ## AnnualBilling (Jahresabrechnung)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation der Jahresabrechnung
 ✅ year: Int16                               // Abrechnungsjahr
 ✅ creationDate: Date                        // Erstellungsdatum
 ✅ totalWaterConsumption: Double             // Gesamter Wasserverbrauch
 ✅ totalWaterCost: Double                    // Gesamte Wasserkosten
 ✅ waterCostPerCubicMeter: Double            // Wasserkosten pro Kubikmeter
 ✅ totalGasConsumption: Double               // Gesamter Gasverbrauch
 ✅ totalGasCost: Double                      // Gesamte Gaskosten
 ✅ gasCostPerKWh: Double                     // Gaskosten pro Kilowattstunde
 ✅ totalHeatingConsumption: Double           // Gesamter Heizungsverbrauch
 ✅ warmWaterConsumption: Double              // Warmwasserverbrauch
 ✅ isFinalized: Bool                         // Abrechnung ist abgeschlossen
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 🔄 yearString: String                        // Jahr als String formatiert
 🔄 formattedYear: String                     // Formatiertes Jahr (z.B. "Jahr 2023")

 ### Beziehungen:
 ✅ apartmentBillings: Set<ApartmentBilling>  // Einzelabrechnungen der Wohnungen
 
 ## ApartmentBilling (Wohnungsabrechnung)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation der Wohnungsabrechnung
 ❌ year: Int16                               // Abrechnungsjahr
 ✅ waterConsumption: Double                  // Wasserverbrauch der Wohnung
 ✅ waterCost: Double                         // Wasserkosten der Wohnung
 ❌ gasConsumption: Double                    // Gasverbrauch der Wohnung
 ❌ gasCost: Double                           // Gaskosten der Wohnung
 ✅ heatingConsumption: Double                // Heizungsverbrauch der Wohnung
 ❌ heatingCost: Double                       // Heizkosten der Wohnung
 ❌ warmWaterConsumption: Double              // Warmwasserverbrauch der Wohnung
 ❌ baseWaterCost: Double                     // Grundkosten Wasser
 ❌ baseGasCost: Double                       // Grundkosten Gas
 ❌ baseHeatingCost: Double                   // Grundkosten Heizung
 ❌ consumptionWaterCost: Double              // Verbrauchsabhängige Wasserkosten
 ✅ consumptionGasCost: Double                // Verbrauchsabhängige Gaskosten
 ✅ consumptionHeatingCost: Double            // Verbrauchsabhängige Heizkosten
 ✅ totalMonthlyFee: Double                   // Monatliche Gesamtvorauszahlung
 ✅ totalCosts: Double                        // Gesamtkosten der Wohnung
 ✅ totalPaidAmount: Double                   // Gesamt geleistete Vorauszahlungen
 ✅ finalBalance: Double                      // Endgültiger Saldo
 ✅ wasteCost: Double? (optional)             // Müllabfuhrkosten
 ✅ commonAreasCost: Double? (optional)       // Kosten für Gemeinschaftsflächen
 ✅ otherCosts: Double? (optional)            // Sonstige Kosten
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 🔄 balance: Double                           // Berechnet als totalPaidAmount - totalCosts
 🔄 balanceText: String                       // Formatierter Text zum Saldo
 🔄 balanceStatus: String                     // "Guthaben" oder "Nachzahlung"

 ### Beziehungen:
 ✅ owner: Owner? (To-One)                    // Zugehöriger Eigentümer
 ✅ annualBilling: AnnualBilling? (To-One)    // Zugehörige Jahresabrechnung
 
 ## DistributionSetting (Verteilungsschlüssel-Einstellung)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation der Einstellung
 ✅ categoryName: String                      // Name der Kostenkategorie
 ✅ typeName: String                          // Art der Verteilung
 ✅ value: Double                             // Wert für die Verteilung
 ✅ dataRepresentation: Data? (optional)     // JSON-Daten für erweiterte Einstellungen
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 🔄 type: DistributionSettingType             // Enum-Wert basierend auf typeName
 
 ## Tenant (Mieter)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation des Mieters
 ✅ firstName: String                         // Vorname
 ✅ lastName: String                          // Nachname
 ✅ email: String? (optional)                 // E-Mail-Adresse
 ✅ phoneNumber: String? (optional)           // Telefonnummer
 ✅ startDate: Date? (optional)               // Mietbeginn
 ✅ endDate: Date? (optional)                 // Mietende
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 🔄 fullName: String                          // Zusammengesetzt aus firstName und lastName
 🔄 isActive: Bool                            // Aktiver Mietvertrag basierend auf endDate

 ### Beziehungen:
 ✅ owner: Owner? (To-One)                    // Zugehöriger Eigentümer
 
 ## Billing (Abrechnung)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation der Abrechnung
 ✅ year: Int16                               // Abrechnungsjahr
 ✅ isVerified: Bool                          // Wurde die Abrechnung geprüft?
 ✅ verifiedBy: String? (optional)            // Name des Prüfers
 ✅ verifiedAt: Date? (optional)              // Zeitpunkt der Prüfung
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 ### Beziehungen:
 ✅ owner: Owner? (To-One)                    // Zugehöriger Eigentümer
 ✅ documents: Set<Document> (To-Many)        // Zugehörige Dokumente
 
 ## Document (Dokument)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation des Dokuments
 ✅ fileName: String                          // Name der Datei
 ✅ fileData: Data                            // Binärdaten des Dokuments
 ✅ mimeType: String                          // MIME-Typ des Dokuments
 ✅ uploadDate: Date                          // Datum des Uploads
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 ### Beziehungen:
 ✅ billing: Billing? (To-One)                // Zugehörige Abrechnung
 
 ## AuditLog (Änderungsprotokoll)
 ✅ id: UUID? (optional)                      // Eindeutige Identifikation des Protokolleintrags
 ✅ entityName: String                        // Name der geänderten Entität
 ✅ entityId: String                          // ID des geänderten Objekts
 ✅ changedBy: String                         // Benutzer, der die Änderung vorgenommen hat
 ✅ timestamp: Date                           // Zeitpunkt der Änderung
 ✅ oldValues: Data                           // JSON der alten Werte
 ✅ newValues: Data                           // JSON der neuen Werte
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Allgemeine Notizen/Bemerkungen

 ## Settings (Einstellungen)
 ✅ id: UUID? (optional)                      // Eindeutige ID der Einstellung
 ✅ key: String                               // Einstellungsschlüssel
 ✅ value: String                             // Einstellungswert
 ✅ group: String                             // Gruppierung der Einstellung
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Beschreibung/Notizen

 ## AdditionalCost (Zusatzkosten)
 ✅ id: UUID? (optional)                      // Eindeutige ID der Zusatzkosten
 ✅ title: String                             // Bezeichnung der Kosten
 ✅ amount: Double                            // Kostenbetrag
 ✅ date: Date                                // Datum der Entstehung
 ✅ category: String                          // Kostenkategorie
 ❌ isPaid: Bool                              // Bezahlstatus
 ❌ dueDate: Date?                            // Fälligkeitsdatum
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Beschreibung/Notizen

 ### Beziehungen:
 ✅ owner: Owner? (To-One)                    // Zugeordneter Eigentümer
 ✅ billing: Billing? (To-One)                // Zugeordnete Abrechnung

 ## PaymentPlan (Zahlungsplan)
 ✅ id: UUID? (optional)                      // Eindeutige ID des Zahlungsplans
 ✅ startDate: Date                           // Beginn der Ratenzahlung
 ✅ endDate: Date                             // Ende der Ratenzahlung
 ✅ totalAmount: Double                       // Gesamtbetrag
 ✅ monthlyRate: Double                       // Monatliche Rate
 ❌ isActive: Bool                            // Aktiv/Inaktiv Status
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Beschreibung/Notizen

 ### Beziehungen:
 ✅ owner: Owner? (To-One)                    // Zugeordneter Eigentümer
 ✅ billing: Billing? (To-One)                // Zugeordnete Abrechnung

 ## PaymentRecord (Zahlungsnachweis)
 ✅ id: UUID? (optional)                      // Eindeutige ID der Zahlung
 ✅ date: Date                                // Zahlungsdatum
 ✅ amount: Double                            // Zahlungsbetrag
 ✅ type: String                              // Art der Zahlung
 ❌ confirmationNumber: String?               // Überweisungsreferenz
 ❌ lastModified: Date                        // Datum der letzten Änderung
 ❌ notes: String? (optional)                 // Beschreibung/Notizen

 ### Beziehungen:
 ✅ paymentPlan: PaymentPlan? (To-One)        // Zugeordneter Zahlungsplan
 ✅ owner: Owner? (To-One)                    // Zahlender Eigentümer

/**
 # WICHTIGE HINWEISE:
 
 1. Standardattribute für alle Entitäten:
    - id: UUID? (optional)
    - lastModified: Date
    - notes: String? (optional)
 
 2. Beziehungstypen:
    - To-One: Einzelreferenz (optional mit ?)
    - To-Many: Set<Entity> für mehrere Referenzen
 
 3. Berechnete Eigenschaften (🔄):
    - Nicht im CoreData-Modell
    - In Extensions implementieren
 
 4. UI-Eigenschaften (📱):
    - Nur in ViewModels/Extensions
    - Nicht in CoreData speichern
 
 5. Suchattribute (🔍):
    - In der Entität indexieren
    - Für Spotlight vorbereiten
 */
