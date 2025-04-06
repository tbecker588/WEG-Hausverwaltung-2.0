import SwiftUI

struct WEGDataInputView: View {
    @State private var buildingName: String = ""
    @State private var heatingType: String = ""
    @State private var roofType: String = ""
    @State private var totalLivingArea: String = ""
    @State private var commonAreas: String = ""
    @State private var basementInfo: String = ""
    @State private var garageInfo: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Gebäude")) {
                TextField("Name des Gebäudes", text: $buildingName)
                TextField("Heizungstyp", text: $heatingType)
                TextField("Dachtyp", text: $roofType)
            }
            
            Section(header: Text("Flächen")) {
                TextField("Gesamtwohnfläche (m²)", text: $totalLivingArea)
                TextField("Gemeinschaftsflächen", text: $commonAreas)
            }
            
            Section(header: Text("Zusätzliche Informationen")) {
                TextField("Keller", text: $basementInfo)
                TextField("Garagen", text: $garageInfo)
            }
        }
        .navigationTitle("Daten der WEG")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WEGDataInputView_Previews: PreviewProvider {
    static var previews: some View {
        WEGDataInputView()
    }
}