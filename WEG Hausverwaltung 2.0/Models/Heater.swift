/**
 * @class   Heater
 * @brief   Modelliert einen Heizkörper im System
 *
 * @details Repräsentiert einen einzelnen Heizkörper mit allen relevanten
 *          Eigenschaften für die Verbrauchsabrechnung.
 *
 * @author  [IhrName]
 * @date    2024-04-08
 * @version 1.0
 */

import CoreData
import Foundation

@objc(Heater)
public class Heater: NSManagedObject, Identifiable {
    // MARK: - Properties

    @NSManaged
    private var primitiveId: UUID?
    @NSManaged
    private var primitiveIdentifier: String? // z.B. "HK-001"
    @NSManaged
    private var primitiveManufacturer: String?
    @NSManaged
    private var primitiveModel: String?
    @NSManaged
    private var primitiveInstallDate: Date?

    // MARK: - Public Interface

    public var heaterIdentifier: String {
        get { primitiveIdentifier ?? "Nicht zugewiesen" }
        set { primitiveIdentifier = newValue }
    }

    public var manufacturer: String {
        get { primitiveManufacturer ?? "" }
        set { primitiveManufacturer = newValue }
    }

    // MARK: - Lifecycle

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveId = UUID()
    }
}
