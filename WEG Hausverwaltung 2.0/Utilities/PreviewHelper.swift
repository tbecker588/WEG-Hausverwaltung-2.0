/**
 * @file    PreviewHelper.swift
 * @brief   Hilfsfunktionen für SwiftUI Previews
 * @author  Thomas Becker
 * @date    08.04.2024
 */

import CoreData

/// Extension für PersistenceController zur Preview-Unterstützung
extension PersistenceController {
    /// Preview-Container mit Beispieldaten
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Beispiel-Eigentümer erstellen
        let owner = Owner(context: viewContext)
        owner.id = UUID()
        owner.firstName = "Max"
        owner.lastName = "Mustermann"
        owner.apartmentNumber = "1"
        owner.floorNumber = 1
        owner.ownershipShare = 0.25

        // Beispiel-Heizkörper erstellen
        let heater = Heater(context: viewContext)
        heater.id = UUID()
        heater.room = "Wohnzimmer"
        heater.lastReading = "123.45"
        heater.factorValue = 1.0
        heater.owner = owner

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Core Data Fehler: \(nsError.localizedDescription)")
        }

        return controller
    }()
}
