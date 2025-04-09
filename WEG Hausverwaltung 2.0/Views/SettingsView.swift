import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            // WEG-Daten
            Section(header: Text("Haupteinstellungen")) {
                NavigationLink(destination: WEGDataInputView()) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text("Daten der WEG")
                    }
                }

                // Link zu Eigentümern
                NavigationLink(destination: OwnerListView()) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        Text("Eigentümer verwalten")
                    }
                }

                // Verteilungsschlüssel
                NavigationLink(destination: DistributionSettingsView()) {
                    HStack {
                        Image(systemName: "percent")
                            .foregroundColor(.purple)
                        Text("Verteilungsschlüssel")
                    }
                }
            }

            // Abrechnungen
            Section(header: Text("Abrechnungen")) {
                // Abrechnungen anzeigen
                NavigationLink(destination: BillingPreviewView()) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.green)
                        Text("Abrechnungen anzeigen")
                    }
                }

                // Jahresabrechnung erstellen
                NavigationLink(destination: AnnualBillingInputView()) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                            .foregroundColor(.blue)
                        Text("Jahresabrechnung erstellen")
                    }
                }

                // Vollständige Abrechnung
                NavigationLink(destination: ComprehensiveBillingView()) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.blue)
                        Text("Vollständige Abrechnung")
                    }
                }
            }

            // Zählerstände
            Section(header: Text("Zähler & Messgeräte")) {
                // Zählerstände erfassen
                NavigationLink(destination: MeterReadingInputView()) {
                    HStack {
                        Image(systemName: "gauge")
                            .foregroundColor(.orange)
                        Text("Zählerstände erfassen")
                    }
                }

                // Heizkostenverteiler
                NavigationLink(destination: HeatersListView()) {
                    HStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(.red)
                        Text("Heizkostenverteiler ablesen")
                    }
                }
            }
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .background(DesignSystem.Colors.background)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
