//
//  ContentView.swift
//  WEG Hausverwaltung 2.0
//
//  Created by Thomas Becker on 06.04.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            OwnerListView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
