/**
 * @file    ContentView.swift
 * @brief   Hauptansicht der App
 * @author  Thomas Becker
 * @date    08.04.2024
 */

import CoreData
import SwiftUI

// MARK: - ViewModel

final class ContentViewModel: ObservableObject {
    @Published
    var selectedTab = 0
    let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject
    private var viewModel = ContentViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            NavigationStack {
                OwnerListView()
            }
            .tabItem {
                Label("Eigentümer", systemImage: "person.2")
            }
            .tag(0)

            NavigationStack {
                BillingView()
            }
            .tabItem {
                Label("Abrechnungen", systemImage: "doc.text")
            }
            .tag(1)

            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar")
            }
            .tag(2)
        }
        .environment(\.managedObjectContext, viewModel.context)
    }
}

#if DEBUG
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
#endif
