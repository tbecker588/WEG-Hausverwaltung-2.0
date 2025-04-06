//
//  WEG_HausverwaltungApp.swift
//  WEG Hausverwaltung
//
//  Created by Thomas Becker on 06.04.25.
//

import SwiftUI

@main
struct WEG_HausverwaltungApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate  // AppDelegate adaptieren
    let persistence = CoreDataStack.shared
    @StateObject var auth = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            DashboardView()   // Hier schaltest du zur gewünschten Start-View
                .environment(\.managedObjectContext, persistence.context)
                .environmentObject(auth)
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                    UICollectionView.appearance().backgroundColor = .clear
                }
        }
    }
}
