import SwiftUI

/// Hauptnavigationsansicht der App
/// Stellt die primäre Navigation über TabView zur Verfügung
struct MainView: View {
    // MARK: - Properties

    @State
    private var selection = 0
    @Environment(\.horizontalSizeClass)
    var sizeClass

    // MARK: - Tab Definitionen

    private let tabs = [
        Tab(title: "Dashboard", image: "house", tag: 0),
        Tab(title: "Abrechnung", image: "list.bullet.rectangle", tag: 1),
        Tab(title: "Einstellungen", image: "gear", tag: 2),
    ]

    // MARK: - Body

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
                BillingView()
            }
            .tabItem {
                Label("Abrechnung", systemImage: "list.bullet.rectangle")
            }
            .tag(1)

            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Einstellungen", systemImage: "gear")
            }
            .tag(2)
        }
        .accentColor(DesignSystem.Colors.primary)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hauptnavigation")
    }
}

// MARK: - Hilfsstrukturen

private struct Tab: Identifiable {
    let id = UUID()
    let title: String
    let image: String
    let tag: Int
}

// MARK: - Preview

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView()
                .previewDisplayName("Light Mode")

            MainView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
