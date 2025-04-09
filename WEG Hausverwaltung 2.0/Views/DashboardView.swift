import CoreData
import SwiftUI

// Definition eines einfachen StatusBadge, falls nicht bereits separat vorhanden.
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - DashboardView

struct DashboardView: View {
    @Environment(\.managedObjectContext)
    private var viewContext

    var body: some View {
        NavigationView {
            List {
                // Dashboard-Inhalt hier
            }
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Vorschau

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environment(\.managedObjectContext, CoreDataStack.preview.context)
    }
}

// MARK: - Hilfs-View für eine einzelne Kachel

struct TileView: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white)
                .padding(8) // Reduzierte Polsterung

            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 8) // weniger seitliches Padding
        .padding(.vertical, 10) // weniger vertikales Padding
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}
