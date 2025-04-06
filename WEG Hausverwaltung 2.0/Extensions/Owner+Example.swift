import Foundation

extension Owner {
    static var example: Owner {
        let owner = Owner()
        owner.name = "Test Owner"         // Passe an dein Modell an
        owner.apartment = "Wohnzimmer"      // Beispielwert
        owner.areaSqm = 81.74               // Beispielwert
        return owner
    }
}