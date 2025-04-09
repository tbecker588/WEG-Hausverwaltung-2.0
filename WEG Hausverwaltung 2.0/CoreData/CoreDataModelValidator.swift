import Foundation
import CoreData

protocol CoreDataModelValidating {
    func validateModel()
}

class CoreDataModelValidator: CoreDataModelValidating {
    /// Überprüft das CoreData-Modell auf Vollständigkeit und Korrektheit.
    func validateModel() {
        // Teil 1 der Validierung
        validateBasicProperties()
        
        // Teil 2 der Validierung
        validateRelationships()
        
        print("✅ CoreData-Modellvalidierung abgeschlossen.")
    }
    
    private static func validateBasicProperties() {
        guard let modelURL = Bundle.main.url(forResource: "WEG_Hausverwaltung_2_0", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("⚠️ Warnung: CoreData-Modell konnte nicht geladen werden!")
            return
        }
        
        // Erwartete Entitäten und deren Attribute
        let expectedEntities: [String: Set<String>] = [
            "Owner": ["id", "firstName", "lastName", "email", "phoneNumber", "apartmentNumber",
                     "floorNumber", "ownershipShare", "occupantCount", "isRented", "iban",
                     "emergencyContactName", "emergencyContactPhone", "garageNumber",
                     "basementNumber", "areaSqm"],
            
            "Heater": ["id", "heaterIdentifier", "identifier", "room", "lastReading", "type",
                      "installationDate", "factorValue"],
            
            "MeterReading": ["id", "date", "currentValue", "previousValue", "signature"],
            
            "AnnualBilling": ["id", "year", "creationDate", "totalWaterConsumption", "totalWaterCost",
                             "waterCostPerCubicMeter", "totalGasConsumption", "totalGasCost", 
                             "gasCostPerKWh", "totalHeatingConsumption", "warmWaterConsumption", 
                             "isFinalized"],
            
            "ApartmentBilling": ["id", "waterConsumption", "waterCost", "heatingConsumption",
                                "consumptionGasCost", "consumptionHeatingCost", "totalMonthlyFee",
                                "totalCosts", "totalPaidAmount", "finalBalance", "wasteCost",
                                "commonAreasCost", "otherCosts"],
            
            "WEG": ["id", "name", "street", "city", "postalCode", "totalArea"],
            
            "DistributionSetting": ["id", "categoryName", "typeName", "value", "dataRepresentation"],
            
            "Tenant": ["id", "firstName", "lastName", "email", "phoneNumber", "startDate", 
                      "endDate"]
        ]
        
        validateEntitiesAndAttributes(model: model, expectedEntities: expectedEntities)
        validateAttributeTypes(model: model)
    }
    
    private static func validateRelationships() {
        guard let modelURL = Bundle.main.url(forResource: "WEG_Hausverwaltung_2_0", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("⚠️ Warnung: CoreData-Modell konnte nicht geladen werden!")
            return
        }
        
        // Erwartete Beziehungen
        let expectedRelationships: [String: [RelationshipConfig]] = [
            "Owner": [
                RelationshipConfig(name: "apartmentBillings", destination: "ApartmentBilling", isMultiple: true),
                RelationshipConfig(name: "heaters", destination: "Heater", isMultiple: true),
                RelationshipConfig(name: "tenants", destination: "Tenant", isMultiple: true)
            ],
            "Heater": [
                RelationshipConfig(name: "owner", destination: "Owner", isMultiple: false),
                RelationshipConfig(name: "meterReadings", destination: "MeterReading", isMultiple: true)
            ],
            "MeterReading": [
                RelationshipConfig(name: "heater", destination: "Heater", isMultiple: false)
            ],
            "AnnualBilling": [
                RelationshipConfig(name: "apartmentBillings", destination: "ApartmentBilling", isMultiple: true)
            ],
            "ApartmentBilling": [
                RelationshipConfig(name: "owner", destination: "Owner", isMultiple: false),
                RelationshipConfig(name: "annualBilling", destination: "AnnualBilling", isMultiple: false)
            ],
            "Tenant": [
                RelationshipConfig(name: "owner", destination: "Owner", isMultiple: false)
            ]
        ]
        
        validateRelationships(model: model, expectedRelationships: expectedRelationships)
        validateDetailedRelationships(model: model)
    }
    
    private static func validateEntitiesAndAttributes(
        model: NSManagedObjectModel, 
        expectedEntities: [String: Set<String>]
    ) {
        for (entityName, expectedAttributes) in expectedEntities {
            guard let entity = model.entitiesByName[entityName] else {
                print("⚠️ Warnung: Entität \(entityName) fehlt im Modell!")
                continue
            }
            
            let actualAttributes = Set(entity.attributesByName.keys)
            let missingAttributes = expectedAttributes.subtracting(actualAttributes)
            
            if !missingAttributes.isEmpty {
                print("⚠️ Warnung: Fehlende Attribute für \(entityName): \(missingAttributes)")
            }
            
            let unexpectedAttributes = actualAttributes.subtracting(expectedAttributes)
            if !unexpectedAttributes.isEmpty {
                print("ℹ️ Info: Zusätzliche Attribute für \(entityName): \(unexpectedAttributes)")
            }
        }
    }
    
    private static func validateRelationships(
        model: NSManagedObjectModel, 
        expectedRelationships: [String: [RelationshipConfig]]
    ) {
        for (entityName, relationships) in expectedRelationships {
            guard let entity = model.entitiesByName[entityName] else {
                continue
            }
            
            for relationship in relationships {
                let relationshipName = relationship.name
                let destinationName = relationship.destination
                let isToMany = relationship.isMultiple
                
                guard let rel = entity.relationshipsByName[relationshipName] else {
                    print("⚠️ Warnung: Beziehung \(relationshipName) fehlt bei \(entityName)!")
                    continue
                }
                
                if rel.destinationEntity?.name != destinationName {
                    print("⚠️ Warnung: Beziehung \(relationshipName) bei \(entityName) zeigt auf \(rel.destinationEntity?.name ?? "nil") statt auf \(destinationName)!")
                }
                
                if rel.isToMany != isToMany {
                    print("⚠️ Warnung: Beziehung \(relationshipName) bei \(entityName) ist \(rel.isToMany ? "To-Many" : "To-One") statt \(isToMany ? "To-Many" : "To-One")!")
                }
                
                // Prüfe inverse Beziehungen
                if rel.inverseRelationship == nil {
                    print("⚠️ Warnung: Keine inverse Beziehung für \(relationshipName) bei \(entityName)!")
                }
            }
        }
    }
    
    private static func validateAttributeTypes(model: NSManagedObjectModel) {
        let expectedTypes: [String: [String: NSAttributeType]] = [
            "Owner": [
                "id": .UUIDAttributeType,                       // Eindeutige ID des Eigentümers
                "firstName": .stringAttributeType,              // Vorname
                "lastName": .stringAttributeType,               // Nachname
                "email": .stringAttributeType,                  // E-Mail-Adresse
                "phoneNumber": .stringAttributeType,            // Telefonnummer
                "apartmentNumber": .stringAttributeType,        // Wohnungsnummer
                "floorNumber": .stringAttributeType,            // Etagennummer
                "ownershipShare": .doubleAttributeType,         // Eigentumsanteil in Prozent
                "occupantCount": .integer16AttributeType,       // Anzahl der Bewohner
                "isRented": .booleanAttributeType,             // Ist die Wohnung vermietet?
                "iban": .stringAttributeType,                   // Bankverbindung
                "emergencyContactName": .stringAttributeType,   // Name Notfallkontakt
                "emergencyContactPhone": .stringAttributeType,  // Telefon Notfallkontakt
                "garageNumber": .stringAttributeType,          // Garagennummer
                "basementNumber": .stringAttributeType,         // Kellernummer
                "areaSqm": .doubleAttributeType                // Wohnfläche in m²
            ],
            "Heater": [
                "id": .UUIDAttributeType,                      // Eindeutige ID des Heizkörpers
                "identifier": .stringAttributeType,             // Zählernummer
                "room": .stringAttributeType,                   // Raumbezeichnung
                "lastReading": .stringAttributeType,            // Letzter Zählerstand
                "type": .stringAttributeType,                   // Typ des Heizkörpers
                "installationDate": .dateAttributeType,         // Installationsdatum
                "factorValue": .doubleAttributeType            // Bewertungsfaktor
            ]
            // ... weitere Entitäten hier
        ]
        
        for (entityName, attributeTypes) in expectedTypes {
            guard let entity = model.entitiesByName[entityName] else {
                continue
            }
            
            for (attributeName, expectedType) in attributeTypes {
                guard let attribute = entity.attributesByName[attributeName] else {
                    continue
                }
                
                if attribute.attributeType != expectedType {
                    print("⚠️ Warnung: Attribut \(attributeName) in \(entityName) hat Typ \(attribute.attributeType) statt \(expectedType)!")
                }
            }
        }
    }
}

extension CoreDataModelValidator {
    private func validateDetailedRelationships(model: NSManagedObjectModel) {
        validateRelationshipTypes(model)
        validateRelationshipRules(model)
    }
}

private static func validateRelationshipDetail(
    entityName: String,
    relationship: NSRelationshipDescription,
    expected: RelationshipDetail
) {
    if relationship.destinationEntity?.name != expected.destinationEntity {
        print("⚠️ \(entityName).\(expected.name): Falsches Ziel - Ist: \(relationship.destinationEntity?.name ?? "nil"), Soll: \(expected.destinationEntity)")
    }
    
    if let inverse = relationship.inverseRelationship {
        if inverse.name != expected.inverse {
            print("⚠️ \(entityName).\(expected.name): Falsche Inverse - Ist: \(inverse.name), Soll: \(expected.inverse)")
        }
    } else {
        print("⚠️ \(entityName).\(expected.name): Keine inverse Beziehung definiert!")
    }
    
    if relationship.isOptional != expected.isOptional {
        print("⚠️ \(entityName).\(expected.name): Falsche Optionalität - Ist: \(relationship.isOptional), Soll: \(expected.isOptional)")
    }
    
    if relationship.isToMany != expected.isToMany {
        print("⚠️ \(entityName).\(expected.name): Falsche Kardinalität - Ist: \(relationship.isToMany ? "To-Many" : "To-One"), Soll: \(expected.isToMany ? "To-Many" : "To-One")")
    }
    
    if relationship.deleteRule != expected.deleteRule {
        print("⚠️ \(entityName).\(expected.name): Falsche Löschregel - Ist: \(relationship.deleteRule), Soll: \(expected.deleteRule)")
    }
}

private struct RelationshipDetail {
    let name: String
    let destinationEntity: String
    let inverse: String
    let isOptional: Bool
    let isToMany: Bool
    let deleteRule: NSDeleteRule
}

struct RelationshipConfig {
    let name: String
    let destination: String
    let isMultiple: Bool
}

struct ValidationResult {
    let isValid: Bool
    let errorMessage: String
    let details: [String]
}

private let validProperties = [
    "id",
    "name",
    "value"
]

func validateEntity(
    name: String,
    properties: [String],
    relationships: [String]
) -> ValidationResult {
    // ...existing code...
}
