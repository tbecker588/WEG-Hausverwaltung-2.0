import SwiftUI

struct OwnerListView: View {
    var body: some View {
        Text("Eigentümerliste")
            .navigationTitle("Eigentümer")
    }
}

struct OwnerListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OwnerListView()
                .environment(\.managedObjectContext, CoreDataStack.preview.context)
        }
    }
}