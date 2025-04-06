import SwiftUI
// Falls dein DesignSystem bereits existiert, importiere es ggf. hier:
// import DesignSystem


// MARK: - Platzhalter-Views für Navigation:
struct AddOwnerView: View {
    var body: some View {
        Text("Neuer Eigentümer")
            .font(.headline)
            .padding()
            .navigationTitle("Eigentümer hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct BillingDetailView: View {
    var body: some View {
        Text("Details der Abrechnung")
            .font(.headline)
            .padding()
            .navigationTitle("Abrechnung")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// Dummy-Implementierung für BillingListView – wird hier lokal verwendet.
struct BillingListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Text("Rechnung 1")
                    Text("Rechnung 2")
                    Text("Rechnung 3")
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Abrechnungen")
                
                NavigationLink {
                    BillingDetailView()
                } label: {
                    Text("Neue Abrechnung hinzufügen")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PasswordsButtonStyle()) // Definiert in deinem DesignSystem
                .padding()
            }
            .background(Color.passwordsGray) // Ebenfalls in deinem DesignSystem definiert
        }
    }
}

// MARK: - Haupt-TabView
struct PasswordsStyleMainView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            // Tab 0: Dashboard
            NavigationStack {
                DashboardView()
                    .background(Color.passwordsGray)
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(0)
            
            // Tab 1: Eigentümer – verweist auf die externe OwnerListView
            NavigationStack {
                OwnerListView() // Diese View ist in OwnerListView.swift definiert.
                    .background(Color.passwordsGray)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            NavigationLink {
                                AddOwnerView()
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundColor(Color.passwordsBlue)
                                    .font(.body.weight(.bold))
                            }
                        }
                    }
            }
            .tabItem {
                Label("Eigentümer", systemImage: "person.3.fill")
            }
            .tag(1)
            
            // Tab 3: Abrechnungen
            NavigationStack {
                BillingListView()
            }
            .tabItem {
                Label("Abrechnungen", systemImage: "doc.text.fill")
            }
            .tag(3)
        }
        .tint(Color.passwordsBlue)
        .background(Color.passwordsGray)
    }
}

struct PasswordsStyleMainView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordsStyleMainView()
            .environment(\.managedObjectContext, CoreDataStack.preview.context)
    }
}

#Preview {
    PasswordsStyleMainView()
        .environment(\.managedObjectContext, CoreDataStack.preview.context)
}