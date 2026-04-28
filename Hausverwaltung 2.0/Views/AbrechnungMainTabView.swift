//
//  AbrechnungMainTabView.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftUI
import SwiftData

struct AbrechnungMainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AbrechnungViewModel?
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                TabView(selection: $selectedTab) {
                    // Tab 1: Dashboard
                    AbrechnungDashboardView(viewModel: viewModel)
                        .tabItem {
                            Label("Dashboard", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    // Tab 2: Zahlungen (Monats-Tabelle)
                    AbrechnungZahlungenView(viewModel: viewModel)
                        .tabItem {
                            Label("Zahlungen", systemImage: "eurosign.circle")
                        }
                        .tag(1)

                    // Tab 3: Eingaben (Messwerte)
                    AbrechnungEingabenView(viewModel: viewModel)
                        .tabItem {
                            Label("Eingaben", systemImage: "pencil.and.list.clipboard")
                        }
                        .tag(2)
                    
                    // Tab 4: Abrechnungen (W107-W607)
                    AbrechnungListeView(viewModel: viewModel)
                        .tabItem {
                            Label("Abrechnungen", systemImage: "list.bullet")
                        }
                        .tag(3)
                    
                    // Tab 5: Einstellungen / More
                    AbrechnungEinstellungenView(viewModel: viewModel)
                        .tabItem {
                            Label("More", systemImage: "ellipsis.circle")
                        }
                        .tag(4)
                }
                .accentColor(AbrechnungTheme.heizung)
            } else {
                ProgressView("Wird geladen...")
                    .onAppear {
                        if viewModel == nil {
                            viewModel = AbrechnungViewModel(modelContext: modelContext)
                        }
                    }
            }
        }
    }
}
