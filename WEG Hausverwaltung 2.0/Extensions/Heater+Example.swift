import Foundation
import SwiftUI

extension Heater {
    // Falls dein Heater-Modell die Properties 'room' und 'lastReading' nicht besitzt,
    // definieren wir sie hier als computed properties für die Preview.
    var room: String {
        "Wohnzimmer"
    }
    var lastReading: String {
        "1.234"  // Beispielwert – passe diesen Wert bei Bedarf an
    }
    
    static var example: Heater {
        let heater = Heater()
        heater.identifier = "Heater001"   // Stelle sicher, dass diese Eigenschaft im Modell existiert
        heater.factor = 1.0               // Dummy-Faktor
        return heater
    }
}