/**
 * @file    ContentViewModel.swift
 * @brief   ViewModel für die ContentView
 * @author  Thomas Becker
 * @date    08.04.2024
 */

import CoreData
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published
    var selectedTab: Int = 0
    private let persistenceController = PersistenceController.shared

    var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
}
