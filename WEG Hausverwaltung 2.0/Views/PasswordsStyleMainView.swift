import SwiftUI

enum PasswordsStyle {
    static let blue = Color("CustomBlue")
    static let gray = Color("CustomGray")
}

// Definiere die benötigten Design-Elemente lokal:
extension Color {
    static let passwordsBlue = Color.blue // Oder eine benutzerdefinierte Farbe
    static let passwordsGray = Color(red: 0.95, green: 0.95, blue: 0.97)
}

struct PasswordsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color.blue.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct PasswordsStyleMainView: View {
    @State
    private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }
            .tag(0)

            NavigationView {
                OwnerListView()
            }
            .tabItem {
                Label("Eigentümer", systemImage: "person.3")
            }
            .tag(1)

            NavigationView {
                Text("Abrechnungen")
                    .navigationTitle("Abrechnungen")
            }
            .tabItem {
                Label("Abrechnungen", systemImage: "doc.text")
            }
            .tag(2)

            NavigationView {
                Text("Einstellungen")
                    .navigationTitle("Einstellungen")
            }
            .tabItem {
                Label("Einstellungen", systemImage: "gear")
            }
            .tag(3)
        }
        .accentColor(Color.blue)
    }
}

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Willkommen zurück")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                // Statistikkarten
                VStack(spacing: 15) {
                    StatisticsCard(title: "Eigentümer", value: "8", icon: "person.3.fill", color: .blue)
                    StatisticsCard(title: "Wohnungen", value: "12", icon: "house.fill", color: .green)
                    StatisticsCard(title: "Abrechnungen", value: "3", icon: "doc.text", color: .orange)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
    }
}

struct StatisticsCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct OwnerListView: View {
    @Environment(\.managedObjectContext)
    private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Owner.lastName, ascending: true)],
        animation: .default
    )
    private var owners: FetchedResults<Owner>

    @State
    private var searchText = ""

    var body: some View {
        List {
            ForEach(owners, id: \.id) { owner in
                NavigationLink(destination: Text("Eigentümerdetails")) {
                    VStack(alignment: .leading) {
                        Text("\(owner.firstName) \(owner.lastName)")
                            .fontWeight(.medium)
                        if let apartment = owner.apartmentNumber {
                            Text("Wohnung \(apartment)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Eigentümer")
    }
}

struct PasswordsStyleMainView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordsStyleMainView()
    }
}
