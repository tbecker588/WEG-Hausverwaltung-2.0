import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink(destination: WEGDataInputView()) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text("Daten der WEG")
                }
            }
            
            // Weitere Menüpunkte können hier hinzugefügt werden
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}