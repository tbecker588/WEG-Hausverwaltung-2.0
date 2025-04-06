//
//  Item.swift
//  WEG Hausverwaltung 2.0
//
//  Created by Thomas Becker on 06.04.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
