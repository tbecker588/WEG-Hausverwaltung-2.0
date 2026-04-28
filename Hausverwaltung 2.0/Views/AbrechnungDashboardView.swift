//
//  AbrechnungDashboardView.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftUI
import SwiftData

struct AbrechnungDashboardView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Demo-Modus Banner
                    if viewModel.istErsterStart {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Demo-Modus")
                                    .font(.headline)
                                    .foregroundStyle(.purple)
                                Text("Du siehst Musterdaten. Erkunde alle Funktionen der App.\nSetze einen Admin-PIN in den Einstellungen, um mit eigenen Daten zu starten.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                    }

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WEG-Abrechnung")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let weg = viewModel.weg {
                            Text(weg.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Jahres-Umschaltung als gut klickbare Buttons
                            HStack(spacing: 10) {
                                Button {
                                    let jahre = viewModel.alleJahre
                                    if let idx = jahre.firstIndex(of: viewModel.selectedJahr), idx + 1 < jahre.count {
                                        viewModel.jahresWechsel(zu: jahre[idx + 1])
                                    }
                                } label: {
                                    Label("Zurück", systemImage: "chevron.left")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled(viewModel.alleJahre.last == viewModel.selectedJahr)

                                Menu {
                                    ForEach(viewModel.alleJahre, id: \.self) { jahr in
                                        Button {
                                            viewModel.jahresWechsel(zu: jahr)
                                        } label: {
                                            if jahr == viewModel.selectedJahr {
                                                Label(viewModel.labelFuerJahrNummer(jahr), systemImage: "checkmark")
                                            } else {
                                                Text(viewModel.labelFuerJahrNummer(jahr))
                                            }
                                        }
                                    }
                                } label: {
                                    Label(viewModel.istMusterjahrAktiv ? "Demo" : String(viewModel.selectedJahr), systemImage: viewModel.istMusterjahrAktiv ? "sparkles" : "calendar")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    let jahre = viewModel.alleJahre
                                    if let idx = jahre.firstIndex(of: viewModel.selectedJahr), idx > 0 {
                                        viewModel.jahresWechsel(zu: jahre[idx - 1])
                                    }
                                } label: {
                                    Label("Weiter", systemImage: "chevron.right")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled(viewModel.alleJahre.first == viewModel.selectedJahr)
                            }

                            if viewModel.istMusterjahrAktiv && viewModel.adminAngelegegt {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles").font(.caption2)
                                    Text("Demo-Jahr – nur zur Ansicht")
                                        .font(.caption2)
                                }
                                .foregroundColor(.purple)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.purple.opacity(0.12))
                                .cornerRadius(6)
                            } else if viewModel.istJahrSchreibgeschuetzt {
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.istHistorischesJahr ? "eye.fill" : "lock.fill").font(.caption2)
                                    Text(
                                        viewModel.istHistorischesJahr
                                        ? "Historisches Jahr – nur Ansicht"
                                        : "Abgeschlossen" + (weg.abgeschlossenAm.map { " am " + deKurzDatum($0) } ?? "")
                                    )
                                        .font(.caption2)
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.orange.opacity(0.12))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AbrechnungTheme.secondaryBackground)
                    .cornerRadius(12)
                    
                    // Schnellübersicht
                    VStack(spacing: 12) {
                        DashboardStatCard(
                            title: "Wohnungen",
                            value: "\(viewModel.weg?.wohnungen.count ?? 0)",
                            icon: "building.2.fill",
                            color: .blue
                        )
                        
                        DashboardStatCard(
                            title: "Gesamtfläche",
                            value: String(format: "%.0f m²", viewModel.gesamtFlaeche),
                            icon: "square.fill",
                            color: .gray
                        )
                        
                        DashboardStatCard(
                            title: "Gesamtpersonen",
                            value: "\(viewModel.gesamtPersonen)",
                            icon: "person.2.fill",
                            color: .green
                        )
                    }
                    
                    // Heizung & Wasser
                    VStack(spacing: 12) {
                        Text("Verbrauch")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Heizung", systemImage: "flame.fill")
                                    .foregroundColor(AbrechnungTheme.heizung)
                                Text(String(format: "%.0f Punkte", viewModel.gesamtHeizPunkte))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
                            .padding()
                            .background(AbrechnungTheme.heizung.opacity(0.1))
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Wasser", systemImage: "drop.fill")
                                    .foregroundColor(AbrechnungTheme.wasser)
                                Text(String(format: "%.0f m³", viewModel.gesamtWasserUnterzaehler))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
                            .padding()
                            .background(AbrechnungTheme.wasser.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(AbrechnungTheme.secondaryBackground)
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wasserabgleich")
                            .font(.headline)
                        Text("Hauptzähler: \(String(format: "%.3f", viewModel.hauptwasserVerbrauch)) m³")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Differenz Haupt - Unterzähler: \(String(format: "%.3f", viewModel.wasserDifferenzHauptZuUnterzaehler)) m³")
                            .font(.caption)
                            .foregroundColor(viewModel.wasserDifferenzHauptZuUnterzaehler == 0 ? .secondary : .orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AbrechnungTheme.secondaryBackground)
                    .cornerRadius(12)
                    
                    // Aktionen
                    VStack(spacing: 12) {
                        Text("Aktionen")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            viewModel.calculateAllAbrechnungen()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Abrechnungen berechnen")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AbrechnungTheme.heizung)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(AbrechnungTheme.secondaryBackground)
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Komponenten

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding()
        .background(AbrechnungTheme.secondaryBackground)
        .cornerRadius(8)
    }
}

