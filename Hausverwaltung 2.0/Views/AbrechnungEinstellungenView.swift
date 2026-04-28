//
//  AbrechnungEinstellungenView.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PhotosUI
import UIKit

// MARK: - Einstellungen Hauptseite

struct AbrechnungEinstellungenView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let weg = viewModel.weg {

                        if viewModel.istJahrSchreibgeschuetzt {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.istHistorischesJahr ? "eye.fill" : "lock.fill")
                                Text(viewModel.schreibschutzHinweis)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        LazyVGrid(columns: columns, spacing: 12) {
                            EinstellungenKachelLink(
                                title: "WEG",
                                subtitle: "Verwalter, Zeitraum, Logo",
                                systemImage: "building.2.crop.circle",
                                tint: .mint,
                                destination: WEGVerwaltungView(weg: weg)
                            )

                            EinstellungenKachelLink(
                                title: "Vorschau & Layout",
                                subtitle: "PDF ansehen & gestalten",
                                systemImage: "doc.richtext.fill",
                                tint: .brown,
                                destination: RechnungsvorschauView(weg: weg, viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Abrechnungsheader",
                                subtitle: "Titel, Zusatzpunkte, Schlüssel",
                                systemImage: "text.document.fill",
                                tint: .indigo,
                                destination: AbrechnungsHeaderKonfigurationView(weg: weg, viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Eigentümer",
                                subtitle: "Stammdaten & Nutzung",
                                systemImage: "person.3.fill",
                                tint: .teal,
                                destination: EinstellungenEigentuemerView(viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Wohnungen",
                                subtitle: "Zähler & Zuordnung",
                                systemImage: "building.2.fill",
                                tint: .blue,
                                destination: EinstellungenWohnungenView(viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Jahresverwaltung",
                                subtitle: "Abschluss & neues Jahr",
                                systemImage: "calendar.badge.clock",
                                tint: .orange,
                                destination: EinstellungenJahresverwaltungView(viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Kontrolle",
                                subtitle: "Vergleiche & Summen",
                                systemImage: "checkmark.circle.fill",
                                tint: .cyan,
                                destination: AbrechnungKontrolleView(viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Admin",
                                subtitle: "PIN & Änderungslog",
                                systemImage: "lock.shield.fill",
                                tint: .green,
                                destination: EinstellungenAdminView(viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Aktionen",
                                subtitle: "Berechnen & Testdaten",
                                systemImage: "sparkles",
                                tint: .pink,
                                destination: EinstellungenAktionenView(viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Backup",
                                subtitle: "Sichern & Wiederherstellen",
                                systemImage: "arrow.up.doc.fill",
                                tint: .purple,
                                destination: BackupRestoreView(viewModel: viewModel)
                            )

                            EinstellungenKachelLink(
                                title: "Hilfe",
                                subtitle: "Bedienung Schritt für Schritt",
                                systemImage: "questionmark.circle.fill",
                                tint: .gray,
                                destination: AppHilfeView()
                            )
                        }
                        .disabled(viewModel.istJahrSchreibgeschuetzt)
                    } else {
                        ProgressView("Einstellungen werden geladen...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Einstellungen")
            .scrollDismissesKeyboard(.interactively)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.94, green: 0.96, blue: 0.99)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .appKeyboardToolbar()
    }
}

private struct EinstellungenHeaderCard: View {
    let weg: WEG

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(weg.name)
                .font(.headline)
                .fontWeight(.bold)
            Text(weg.adresse)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label("Jahr " + String(weg.abrechnungsjahr), systemImage: "calendar")
                    .font(.caption)
                Label("\(weg.wohnungen.count) Wohnungen", systemImage: "house")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

private struct EinstellungenKachelLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.12), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct AppHilfeView: View {
    var body: some View {
        List {
            Section("Überblick") {
                Text("Diese Hilfe erklärt die komplette Bedienung der App von der Ersteinrichtung bis zur fertigen Jahresabrechnung. Folge den Abschnitten in der Reihenfolge, dann arbeitest du sauber und nachvollziehbar.")
                    .font(.subheadline)
                Text("Grundprinzip: Du pflegst Stammdaten und Eingaben, prüfst die Kontrolle und erzeugst danach die Abrechnung/PDFs.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("1) Erste Einrichtung") {
                HilfeSchritt(
                    titel: "WEG-Daten eintragen",
                    text: "Öffne Einstellungen -> WEG. Pflege Name der Gemeinschaft, Objektadresse, Zeitraum und optional Logo. Diese Daten erscheinen in den Dokumenten."
                )
                HilfeSchritt(
                    titel: "Wohnungen anlegen und prüfen",
                    text: "Öffne Einstellungen -> Wohnungen. Pro Wohnung müssen mindestens Wohnungsnummer, Eigentümername, Fläche, Personen und Miteigentumsanteil korrekt sein."
                )
                HilfeSchritt(
                    titel: "Eigentümerprofile zuordnen",
                    text: "Öffne Einstellungen -> Eigentümer. Jedem Profil eine Wohnung zuordnen und Nutzungsart setzen: Selbstnutzer (Eigennutzung) oder Vermietet. Bei Vermietet zusätzlich den Mietername pflegen."
                )
            }

            Section("2) Laufender Jahresablauf") {
                HilfeSchritt(
                    titel: "Monatlich Zahlungen/Ausgaben pflegen",
                    text: "In Zahlungen und Eingaben die realen Rechnungen und Kosten laufend erfassen. So bleibt die Abrechnung am Jahresende vollständig und plausibel."
                )
                HilfeSchritt(
                    titel: "Zählerstände erfassen",
                    text: "In Wohnungen die Heiz- und Wasserwerte pflegen. Achte auf korrekte Anfangs-/Endwerte und passende Zählerzuordnung je Wohnung."
                )
                HilfeSchritt(
                    titel: "Plausibilität regelmäßig prüfen",
                    text: "Öffne Einstellungen -> Kontrolle. Dort erkennst du Summenabweichungen, fehlende Zuordnungen und unplausible Verteilungen frühzeitig."
                )
            }

            Section("3) Abrechnungsheader und Schlüssel") {
                HilfeSchritt(
                    titel: "Abrechnungszeilen definieren",
                    text: "In Einstellungen -> Abrechnungsheader legst du Zeilen, Bezeichnungen und Verteilungsschlüssel fest (z. B. Fläche, Personen, Miteigentumsanteile, Verbrauch)."
                )
                HilfeSchritt(
                    titel: "Manuelle Schlüssel bewusst verwenden",
                    text: "Manuelle Schlüssel nur einsetzen, wenn die Verteilung bewusst von den Zentraldaten abweichen soll. Die Konsistenzprüfung zeigt dir Abweichungen mit Hinweis an."
                )
                HilfeSchritt(
                    titel: "Konsistenzhinweise beachten",
                    text: "Orange Hinweise markieren Konflikte (z. B. Summen stimmen nicht). Diese zuerst auflösen, bevor PDFs erzeugt oder Jahre abgeschlossen werden."
                )
            }

            Section("4) Eigentümer richtig kennzeichnen") {
                HilfeSchritt(
                    titel: "Selbstnutzer vs. Vermietet",
                    text: "In der Eigentümerliste zeigt ein Status-Badge die Nutzungsart. Selbstnutzer bedeutet: Eigentümer nutzt die zugeordnete Wohnung selbst. Vermietet bedeutet: Eigentümer wohnt nicht dort."
                )
                HilfeSchritt(
                    titel: "Adresshinweise interpretieren",
                    text: "Wenn Eigennutzung gewählt ist, die Adresse aber außerhalb der Objektadresse liegt, zeigt die App einen Warnhinweis und bietet 'Als vermietet markieren' an."
                )
                HilfeSchritt(
                    titel: "Haushalt korrekt verstehen",
                    text: "Der Haushalt-Wert dient der Verteilung nach Personen/Haushalt. Er ist kein automatischer Wohnsitznachweis. Für die Wohnsituation ist die Nutzungsart maßgeblich."
                )
            }

            Section("5) Abrechnung und Ausgabe") {
                HilfeSchritt(
                    titel: "Vor Ausgabe berechnen",
                    text: "Nutze Einstellungen -> Aktionen, um Berechnungen neu auszuführen. Danach Ergebnisse in Kontrolle und Abrechnungsliste prüfen."
                )
                HilfeSchritt(
                    titel: "PDF Vorschau und Layout",
                    text: "Über Vorschau & Layout kontrollierst du Seitenbild, Positionen und Darstellungsdetails. Erst danach finale PDFs erstellen oder teilen."
                )
                HilfeSchritt(
                    titel: "Jahr abschließen",
                    text: "Wenn alle Werte final sind, in Jahresverwaltung abschließen. Ein abgeschlossenes Jahr ist schreibgeschützt und dient als dokumentierter Stand."
                )
            }

            Section("6) Backup, Wiederherstellung, Sicherheit") {
                HilfeSchritt(
                    titel: "Regelmäßig sichern",
                    text: "In Einstellungen -> Backup ein Backup erstellen und in Dateien/iCloud sichern. Empfohlen: vor größeren Änderungen, vor Jahresabschluss und nach Abschluss."
                )
                HilfeSchritt(
                    titel: "Wiederherstellen mit Bedacht",
                    text: "Beim Wiederherstellen werden die enthaltenen Jahre aus der Backup-Datei ersetzt. Vorher immer ein aktuelles Backup des Ist-Standes machen."
                )
                HilfeSchritt(
                    titel: "Admin und Änderungslog nutzen",
                    text: "Im Bereich Admin kannst du PIN-Schutz und Änderungsprotokoll verwenden, um Eingriffe nachvollziehbar und abgesichert zu halten."
                )
            }

            Section("7) Typische Fehler und Lösung") {
                HilfeSchritt(
                    titel: "Summen nicht 1000/1000",
                    text: "Prüfe Eigentumsanteile in den Eigentümerprofilen und Wohnungsdaten. Die Gesamtsumme muss konsistent sein."
                )
                HilfeSchritt(
                    titel: "Falsche Verteilung in einer Zeile",
                    text: "Im Abrechnungsheader die Zeile prüfen: Schlüsselart, manuelle Überschreibungen, sowie Gesamtschlüssel vs. Summe der Wohnungswerte."
                )
                HilfeSchritt(
                    titel: "Eigentümer wirkt falsch zugeordnet",
                    text: "Wohnungszuordnung, Nutzungsart und Adresse im Eigentümerprofil gemeinsam prüfen. Bei Widerspruch zuerst Zuordnung/Nutzungsart korrigieren."
                )
                HilfeSchritt(
                    titel: "Import/Restore zeigt unerwartete Daten",
                    text: "Dateiinhalt (Jahre), Wiederherstellungsziel und aktives Jahr prüfen. Nach Restore ggf. auf das gewünschte Jahr wechseln."
                )
            }

            Section("Empfohlene Reihenfolge vor der finalen Abrechnung") {
                Text("1. Wohnungen und Eigentümerdaten final prüfen")
                Text("2. Eingaben/Zahlungen vollständig eintragen")
                Text("3. Abrechnungsheader und Schlüssel prüfen")
                Text("4. Kontrolle auf Warnungen/Abweichungen prüfen")
                Text("5. Berechnung ausführen")
                Text("6. PDF Vorschau prüfen")
                Text("7. Backup erstellen")
                Text("8. Jahr abschließen")
            }
        }
        .navigationTitle("Hilfe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HilfeSchritt: View {
    let titel: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct WEGVerwaltungView: View {
    @Bindable var weg: WEG
    @State private var logoItem: PhotosPickerItem?

    private var amtszeitBisText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: weg.hausverwalterAmtsende) + " (5 Jahre)"
    }

    var body: some View {
        Form {
            Section("WEG") {
                TextField("Name der WEG", text: $weg.name)
                    .appInputTraits(.organizationName)
                TextField("Adresse", text: $weg.adresse)
                    .appInputTraits(.fullAddress)

                LabeledContent("Wohnungen aktuell") {
                    Text("\(weg.wohnungen.count)")
                        .fontWeight(.semibold)
                }
            }

            Section("Hausverwalter") {
                Picker(
                    "Art",
                    selection: Binding(
                        get: { weg.hausverwalterArtSicher },
                        set: { weg.setHausverwalterArt($0) }
                    )
                ) {
                    ForEach(HausverwalterArt.allCases, id: \.self) { art in
                        Text(art.anzeigeName).tag(art)
                    }
                }

                TextField("Name", text: $weg.hausverwalterName)
                    .appInputTraits(.personName)
                TextField("Straße und Hausnummer", text: $weg.hausverwalterStrasse)
                    .appInputTraits(.streetAddress)
                TextField("PLZ", text: $weg.hausverwalterPlz)
                    .appInputTraits(.postalCode)
                TextField("Ort", text: $weg.hausverwalterOrt)
                    .appInputTraits(.city)
                TextField("Telefon", text: $weg.hausverwalterTelefon)
                    .appInputTraits(.phone)
                TextField("E-Mail", text: $weg.hausverwalterEmail)
                    .appInputTraits(.email)

                DatePicker("Gewählt am", selection: $weg.hausverwalterGewaehltAm, displayedComponents: .date)

                LabeledContent("Amtszeit bis") {
                    Text(amtszeitBisText)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Abrechnungszeitraum") {
                DatePicker("Von", selection: $weg.abrechnungszeitraumVon, displayedComponents: .date)
                DatePicker("Bis", selection: $weg.abrechnungszeitraumBis, displayedComponents: .date)
                Text("Der Zeitraum wird automatisch im Untertitel der Abrechnung verwendet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Logo") {
                if let image = UIImage(data: weg.wegLogoBildData), !weg.wegLogoBildData.isEmpty {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 120)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } else {
                    Text("Noch kein Logo hinterlegt")
                        .foregroundStyle(.secondary)
                }

                PhotosPicker(selection: $logoItem, matching: .images) {
                    Label("Logo auswählen", systemImage: "photo")
                }

                if !weg.wegLogoBildData.isEmpty {
                    Button(role: .destructive) {
                        weg.wegLogoBildData = Data()
                    } label: {
                        Label("Logo entfernen", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("WEG-Verwaltung")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .appKeyboardToolbar()
        .task(id: logoItem) {
            guard let logoItem else { return }
            if let data = try? await logoItem.loadTransferable(type: Data.self) {
                weg.wegLogoBildData = data
            }
        }
    }
}

private struct AbrechnungsHeaderKonfigurationView: View {
    @Bindable var weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel

    @Query private var abrechnungsZeilen: [AbrechnungsZeileKonfiguration]
    @State private var istFreigeschaltet = false
    @State private var zeigePinSheet = false
    @State private var pinEingabe = ""
    @State private var pinFehler = ""
    @State private var fokussierteZeilenID: UUID?

    private struct HeaderPruefung: Identifiable {
        let id = UUID()
        let text: String
        let zeilenID: UUID?
    }

    private var globaleZeilen: [AbrechnungsZeileKonfiguration] {
        abrechnungsZeilen
            .filter { $0.abrechnungsjahr == weg.abrechnungsjahr && $0.istGlobal }
            .sorted {
                if $0.sortierung != $1.sortierung { return $0.sortierung < $1.sortierung }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var eigentuemerProfile: [EigentuemerProfil] {
        viewModel.eigentuemerProfileImAktuellenJahr()
    }

    private var schluesselBezeichnungsVorschlaege: [String] {
        let standard = [
            "Wohneinheiten",
            "Abrechnung",
            "Personen",
            "Miteigent. Anteil",
            "Wohnfläche",
            "Heizverbrauch",
            "Verbrauch",
            "Einheiten"
        ]
        let ausZeilen = globaleZeilen.map { $0.schluesselBezeichnungAnzeige.trimmingCharacters(in: .whitespacesAndNewlines) }
        return Array(Set((standard + ausZeilen).filter { !$0.isEmpty })).sorted()
    }

    private var headerPruefungen: [HeaderPruefung] {
        var hinweise: [HeaderPruefung] = []

        let gesamtPersonen = AbrechnungsZeilenEngine.resolveHaushaltPersonenGesamt(
            in: weg,
            eigentuemerProfile: eigentuemerProfile
        )
        if weg.muellGesamtPersonen != gesamtPersonen {
            hinweise.append(HeaderPruefung(
                text: "Gesamtpersonen Müll (\(weg.muellGesamtPersonen)) stimmen nicht mit den Wohnungsdaten (\(gesamtPersonen)) überein.",
                zeilenID: globaleZeilen.first(where: { $0.systemCode == "muell" })?.id
            ))
        }

        let gesamtMEA = AbrechnungsZeilenEngine.resolveMiteigentumsanteilGesamt(
            in: weg,
            eigentuemerProfile: eigentuemerProfile
        )
        if gesamtMEA != 1000 {
            hinweise.append(HeaderPruefung(
                text: "Die Summe der Miteigentumsanteile beträgt aktuell \(gesamtMEA)/1000.",
                zeilenID: globaleZeilen.first(where: { $0.systemCode == "versicherungen" })?.id
            ))
        }

        for zeile in globaleZeilen {
            let manuelleWohnungswerte = zeile.wohnungsSchluesselManuellMap
            if !manuelleWohnungswerte.isEmpty {
                let summe = manuelleWohnungswerte.values.reduce(0, +)
                let referenz = zeile.gesamtSchluesselManuell > 0 ? zeile.gesamtSchluesselManuell : 0
                if referenz > 0 && abs(summe - referenz) > 0.0001 {
                    hinweise.append(HeaderPruefung(
                        text: "\(zeile.name): Summe der manuellen Wohnungsschlüssel (\(formatSchluesselStr(summe))) weicht vom manuellen Gesamtschlüssel (\(formatSchluesselStr(referenz))) ab.",
                        zeilenID: zeile.id
                    ))
                }
            }

            if zeile.schluesselBezeichnungAnzeige.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                hinweise.append(HeaderPruefung(
                    text: "\(zeile.name): Schlüsselbezeichnung fehlt.",
                    zeilenID: zeile.id
                ))
            }
        }

        return hinweise
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                GroupBox("Abrechnungszeilen als Kacheln") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Jede Änderung wirkt sich direkt auf die Abrechnung aus.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Label(
                                istFreigeschaltet ? "Bearbeitung freigeschaltet" : "Bearbeitung gesperrt (PIN erforderlich)",
                                systemImage: istFreigeschaltet ? "lock.open.fill" : "lock.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(istFreigeschaltet ? .green : .orange)

                            Spacer()

                            if viewModel.adminAngelegegt {
                                Button(istFreigeschaltet ? "Sperren" : "Mit PIN entsperren") {
                                    if istFreigeschaltet {
                                        istFreigeschaltet = false
                                    } else {
                                        pinEingabe = ""
                                        pinFehler = ""
                                        zeigePinSheet = true
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        if !viewModel.adminAngelegegt {
                            Text("Bitte zuerst einen Admin-PIN einrichten. Ohne PIN bleiben diese Felder schreibgeschützt, damit keine unbeabsichtigten Änderungen in die Abrechnung gelangen.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Zeilen: \(globaleZeilen.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Button {
                                _ = viewModel.createAbrechnungsZeile(global: true, wohnung: nil)
                                normalisiereSortierung()
                                viewModel.saveWEG()
                            } label: {
                                Label("Neue Kachel", systemImage: "plus.circle.fill")
                            }
                            .disabled(!istFreigeschaltet)
                        }

                        if globaleZeilen.isEmpty {
                            Text("Keine globalen Zeilen vorhanden.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(globaleZeilen.enumerated()), id: \.element.id) { index, zeile in
                                HeaderZeileKachelView(
                                    zeile: zeile,
                                    istFreigeschaltet: istFreigeschaltet,
                                    weg: weg,
                                    eigentuemerProfile: eigentuemerProfile,
                                    schluesselBezeichnungsVorschlaege: schluesselBezeichnungsVorschlaege,
                                    istFokussiert: fokussierteZeilenID == zeile.id
                                )
                                .id(zeile.id)
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                GroupBox("Konsistenzprüfung") {
                    VStack(alignment: .leading, spacing: 8) {
                        if headerPruefungen.isEmpty {
                            Label("Alle Verknüpfungen sind konsistent. Die Schlüssel greifen auf die zentralen Wohnungsdaten zu.", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("Es gibt Punkte, die Berechnungen verfälschen können:", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)

                            ForEach(headerPruefungen) { hinweis in
                                Button {
                                    guard let zeilenID = hinweis.zeilenID else { return }
                                    fokussierteZeilenID = zeilenID
                                    withAnimation(.easeInOut) {
                                        proxy.scrollTo(zeilenID, anchor: .center)
                                    }
                                } label: {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: hinweis.zeilenID == nil ? "minus.circle.fill" : "arrow.down.right.circle.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                            .padding(.top, 2)
                                        Text(hinweis.text)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer(minLength: 0)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(hinweis.zeilenID == nil)
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                GroupBox("Vorschau") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(weg.abrechnungsTitelAnzeige)
                            .font(.headline)
                        Text(weg.abrechnungsUntertitelAnzeige)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(globaleZeilen.prefix(10), id: \.id) { zeile in
                            Text("• \(zeile.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
                }
                .padding()
            }
        }
        .navigationTitle("Abrechnungsheader")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $zeigePinSheet) {
            NavigationStack {
                Form {
                    Section("PIN-Freigabe") {
                        SecureField("Admin-PIN", text: $pinEingabe)
                            .keyboardType(.numberPad)
                        if !pinFehler.isEmpty {
                            Text(pinFehler)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        Text("Diese Freigabe ist erforderlich, weil Änderungen an den Schlüsseln die Abrechnung sofort beeinflussen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Entsperren")
                .navigationBarTitleDisplayMode(.inline)
                .appKeyboardToolbar()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { zeigePinSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Freigeben") {
                            guard !pinEingabe.isEmpty else {
                                pinFehler = "Bitte PIN eingeben."
                                return
                            }
                            guard viewModel.adminPinPruefen(pinEingabe) else {
                                pinFehler = "PIN ist nicht korrekt."
                                return
                            }
                            istFreigeschaltet = true
                            zeigePinSheet = false
                        }
                    }
                }
            }
        }
    }

    private func verschiebe(zeile: AbrechnungsZeileKonfiguration, delta: Int) {
        let sortiert = globaleZeilen
        guard let index = sortiert.firstIndex(where: { $0.id == zeile.id }) else { return }
        let ziel = index + delta
        guard ziel >= 0, ziel < sortiert.count else { return }

        let andere = sortiert[ziel]
        let temp = zeile.sortierung
        zeile.sortierung = andere.sortierung
        andere.sortierung = temp
        normalisiereSortierung()
        viewModel.saveWEG()
    }

    private func normalisiereSortierung() {
        let sortiert = globaleZeilen
        for (index, zeile) in sortiert.enumerated() where zeile.sortierung != index {
            zeile.sortierung = index
        }
    }
}

private struct HeaderZeileKachelView: View {
    @Bindable var zeile: AbrechnungsZeileKonfiguration
    let istFreigeschaltet: Bool
    let weg: WEG
    let eigentuemerProfile: [EigentuemerProfil]
    let schluesselBezeichnungsVorschlaege: [String]
    let istFokussiert: Bool

    private var aufgeloesterGesamtschluessel: Double {
        guard let erste = weg.wohnungenSortiert.first else { return 0 }
        return AbrechnungsZeilenEngine.resolveSchluessel(
            for: zeile, wohnung: erste, weg: weg, eigentuemerProfile: eigentuemerProfile
        ).total
    }

    private var gesamtschluesselBinding: Binding<String> {
        Binding(
            get: {
                let v = zeile.gesamtSchluesselManuell > 0 ? zeile.gesamtSchluesselManuell : aufgeloesterGesamtschluessel
                return v > 0 ? formatSchluesselStr(v) : ""
            },
            set: { str in
                zeile.gesamtSchluesselManuell = Double(str.replacingOccurrences(of: ",", with: ".")) ?? 0
            }
        )
    }

    private var schluesselBezeichnungBinding: Binding<String> {
        Binding(
            get: {
                let text = zeile.schluesselBezeichnungOverride.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? zeile.schluesselArt.anzeigeName : text
            },
            set: { zeile.schluesselBezeichnungOverride = $0 }
        )
    }

    private func aufgeloesteWohnungsSchluessel(fuer wohnung: Wohnung) -> Double {
        AbrechnungsZeilenEngine.resolveSchluessel(
            for: zeile, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile
        ).value
    }

    private func wohnungsSchluesselBinding(fuer wohnung: Wohnung) -> Binding<String> {
        Binding(
            get: {
                // Manuellen Wert aus Map bevorzugen, sonst auto-berechneten Wert anzeigen
                let manuell = zeile.wohnungsSchluessel(fuer: wohnung.wohnungsnummer)
                let wert = manuell ?? aufgeloesteWohnungsSchluessel(fuer: wohnung)
                return wert > 0 ? formatSchluesselStr(wert) : ""
            },
            set: { str in
                let wert = Double(str.replacingOccurrences(of: ",", with: ".")) ?? 0
                zeile.setWohnungsSchluessel(fuer: wohnung.wohnungsnummer, wert: wert)
            }
        )
    }

    private func hatManuellenWohnungsWert(_ wohnung: Wohnung) -> Bool {
        zeile.wohnungsSchluessel(fuer: wohnung.wohnungsnummer) != nil
    }

    private var verwendetEigeneBezeichnung: Bool {
        let text = zeile.schluesselBezeichnungOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        return !text.isEmpty && !schluesselBezeichnungsVorschlaege.contains(text)
    }

    private var rahmenFarbe: Color {
        if istFokussiert {
            return Color.orange.opacity(0.9)
        }
        if istFreigeschaltet {
            return Color.green.opacity(0.35)
        }
        return Color.black.opacity(0.08)
    }

    private var schattenFarbe: Color {
        istFokussiert ? Color.orange.opacity(0.18) : Color.black.opacity(0.05)
    }

    private var rahmenBreite: CGFloat {
        istFokussiert ? 2 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Kachelüberschrift
            HStack {
                Text(zeile.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if istFreigeschaltet {
                    Image(systemName: "lock.open.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Divider()

            // Gesamtschlüssel
            VStack(alignment: .leading, spacing: 4) {
                Text("Gesamtschlüssel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField(
                        "Auto: \(formatSchluesselStr(aufgeloesterGesamtschluessel))",
                        text: gesamtschluesselBinding
                    )
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!istFreigeschaltet)

                    if zeile.gesamtSchluesselManuell > 0 && istFreigeschaltet {
                        Button {
                            zeile.gesamtSchluesselManuell = 0
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.orange)
                    }
                }
            }

            // Schlüsselbezeichnung
            VStack(alignment: .leading, spacing: 4) {
                Text("Schlüsselbezeichnung")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(schluesselBezeichnungsVorschlaege, id: \.self) { bezeichnung in
                        Button {
                            zeile.schluesselBezeichnungOverride = bezeichnung
                        } label: {
                            if bezeichnung == zeile.schluesselBezeichnungAnzeige {
                                Label(bezeichnung, systemImage: "checkmark")
                            } else {
                                Text(bezeichnung)
                            }
                        }
                    }

                    Divider()

                    Button("Auf Standard zurücksetzen") {
                        zeile.schluesselBezeichnungOverride = ""
                    }
                } label: {
                    HStack {
                        Text(zeile.schluesselBezeichnungAnzeige)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!istFreigeschaltet)

                TextField("Eigene Bezeichnung", text: schluesselBezeichnungBinding)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!istFreigeschaltet)

                if verwendetEigeneBezeichnung {
                    Text("Eigene Bezeichnung aktiv")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Divider()

            // Per-Wohnung Umlageschlüssel
            VStack(alignment: .leading, spacing: 8) {
                Text("Umlageschlüssel je Wohnung")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                ForEach(weg.wohnungenSortiert) { wohnung in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("W\(wohnung.wohnungsnummer)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(wohnung.eigentuemer)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(minWidth: 70, alignment: .leading)

                        TextField(
                            "Auto: \(formatSchluesselStr(aufgeloesteWohnungsSchluessel(fuer: wohnung)))",
                            text: wohnungsSchluesselBinding(fuer: wohnung)
                        )
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!istFreigeschaltet)

                        if hatManuellenWohnungsWert(wohnung) && istFreigeschaltet {
                            Button {
                                zeile.setWohnungsSchluessel(fuer: wohnung.wohnungsnummer, wert: 0)
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(rahmenFarbe, lineWidth: rahmenBreite)
        )
        .shadow(color: schattenFarbe, radius: 6, y: 2)
    }
}

private func formatSchluesselStr(_ value: Double) -> String {
    if value == value.rounded() && value < 100000 {
        return String(format: "%.0f", value)
    }
    return String(format: "%.2f", value)
}

private struct EinstellungenEigentuemerView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: AbrechnungViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let weg = viewModel.weg {
                    let profile = viewModel.eigentuemerProfileImAktuellenJahr()

                    HStack {
                        Text("Eigentümerprofile")
                            .font(.headline)
                        Spacer()
                        let summe = profile.reduce(0) { $0 + $1.eigentumsanteilTausendstel }
                        Text("\(summe)/1000")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(summe == 1000 ? .green : .orange)
                    }

                    Button {
                        viewModel.createEigentuemerProfil()
                    } label: {
                        Label("Eigentümer hinzufügen", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)

                    ForEach(profile) { profil in
                        let wohnung = weg.wohnungenSortiert.first(where: { $0.wohnungsnummer == profil.wohnungsnummer })
                        NavigationLink {
                            EigentuemerProfilDetailView(
                                profil: profil,
                                wohnungen: weg.wohnungenSortiert,
                                profileImJahr: profile,
                                wegAdresse: weg.adresse
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 6) {
                                    Image(systemName: profil.nutzungsartSicher == .vermietet ? "building.2.fill" : "house.fill")
                                        .font(.caption2)
                                    Text(profil.nutzungsartSicher == .vermietet ? "Vermietet" : "Selbstnutzer")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundStyle(profil.nutzungsartSicher == .vermietet ? .orange : .green)
                                .background((profil.nutzungsartSicher == .vermietet ? Color.orange : Color.green).opacity(0.12))
                                .clipShape(Capsule())

                                Text(profil.vollerName.isEmpty ? "Unbenannter Eigentümer" : profil.vollerName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Text(profil.wohnungsnummer.map { "Wohnung \($0)" } ?? "Ohne Wohnungszuordnung")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let wohnung {
                                    Text("Zentral aus Wohnungen · Personen: \(wohnung.personenanzahl) · MEA: \(wohnung.eigentumsanteilTausendstel)/1000")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                  HStack(spacing: 4) {
                                      Text(profil.nutzungsartSicher == .vermietet
                                         ? "Vermietet · Mieter: \(profil.mieterName.isEmpty ? "-" : profil.mieterName) · Haushalt: \(profil.haushaltPersonen)"
                                         : "Eigennutzung · Haushalt: \(profil.haushaltPersonen)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                      if let wohnung, profil.haushaltPersonen != max(1, wohnung.personenanzahl) {
                                          Image(systemName: "exclamationmark.circle.fill")
                                              .font(.caption2)
                                              .foregroundStyle(.orange)
                                      }
                                  }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.teal.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if !profile.isEmpty {
                        Button(role: .destructive) {
                            if let letzter = profile.last {
                                modelContext.delete(letzter)
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Letztes Profil löschen", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Eigentümer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EinstellungenWohnungenView: View {
    @ObservedObject var viewModel: AbrechnungViewModel

    private var summeEigentumsanteile: Int {
        viewModel.weg?.wohnungenSortiert.reduce(0) { $0 + $1.eigentumsanteilTausendstel } ?? 0
    }

    var body: some View {
        List {
            if let weg = viewModel.weg {
                Section {
                    HStack {
                        Text("Eigentumsanteile gesamt")
                        Spacer()
                        Text("\(summeEigentumsanteile)/1000")
                            .fontWeight(.semibold)
                            .foregroundColor(summeEigentumsanteile == 1000 ? .green : .orange)
                    }

                    Text("Personenzahl und Eigentumsanteile werden hier zentral gepflegt und in die Abrechnung übernommen. Für Häuser ohne Abrechnung nach Eigentumsanteilen kann der Wert trotzdem hinterlegt bleiben.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(weg.wohnungenSortiert) { wohnung in
                    NavigationLink {
                        WohnungZaehlerVerwaltungView(wohnung: wohnung, viewModel: viewModel)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("W\(wohnung.wohnungsnummer)").fontWeight(.semibold)
                                Text(wohnung.eigentuemer).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Personen: \(wohnung.personenanzahl)").font(.caption2).foregroundColor(.secondary)
                                Text("MEA: \(wohnung.eigentumsanteilTausendstel)/1000").font(.caption2).foregroundColor(.secondary)
                                Text("HKV: \(wohnung.heizkostenverteiler.count)").font(.caption2).foregroundColor(.secondary)
                                Text("Wasser: \(wohnung.wasserzaehler.count)").font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Wohnungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EinstellungenJahresverwaltungView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @State private var showJahrAbschliessen = false
    @State private var showNeuesJahr = false

    var body: some View {
        List {
            if let weg = viewModel.weg {
                HStack {
                    Image(systemName: weg.abgeschlossen ? "lock.fill" : "lock.open")
                        .foregroundColor(weg.abgeschlossen ? .orange : .secondary)
                    Text(weg.abgeschlossen
                        ? "Jahr " + String(weg.abrechnungsjahr) + " ist abgeschlossen"
                        : "Jahr " + String(weg.abrechnungsjahr) + " ist offen")
                    Spacer()
                    if let am = weg.abgeschlossenAm {
                        Text(deKurzDatum(am)).font(.caption).foregroundColor(.secondary)
                    }
                }

                if !weg.abgeschlossen && viewModel.adminAngelegegt {
                    Button {
                        showJahrAbschliessen = true
                    } label: {
                        Label("Jahr " + String(weg.abrechnungsjahr) + " abschließen", systemImage: "lock.badge.clock")
                            .foregroundColor(.orange)
                    }
                }

                if viewModel.adminAngelegegt {
                    Button {
                        showNeuesJahr = true
                    } label: {
                        Label("Neues Jahr " + String(viewModel.selectedJahr + 1) + " anlegen", systemImage: "calendar.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Jahresverwaltung")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showJahrAbschliessen) {
            JahrAbschliessenView(viewModel: viewModel)
        }
        .sheet(isPresented: $showNeuesJahr) {
            NeuesJahrAnlegenView(viewModel: viewModel)
        }
    }
}

private struct EinstellungenAdminView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @State private var showAdminSetup = false
    @State private var showPinAendern = false

    var body: some View {
        List {
            if viewModel.adminAngelegegt {
                HStack {
                    Image(systemName: "lock.fill").foregroundColor(.green)
                    Text("Admin-PIN ist aktiv")
                }

                Button("PIN ändern") { showPinAendern = true }
            } else {
                Button {
                    showAdminSetup = true
                } label: {
                    Label("Admin-PIN einrichten", systemImage: "lock.badge.plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdminSetup) {
            AdminPinEinrichtenView(viewModel: viewModel)
        }
        .sheet(isPresented: $showPinAendern) {
            AdminPinAendernView(viewModel: viewModel)
        }
    }
}

private struct EinstellungenProtokollView: View {
    var body: some View {
        AenderungsLogView()
            .navigationTitle("Protokoll")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EinstellungenAktionenView: View {
    @ObservedObject var viewModel: AbrechnungViewModel

    var body: some View {
        List {
            Button(action: { viewModel.calculateAllAbrechnungen() }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Neu berechnen")
                }
                .foregroundColor(.blue)
            }

            Button(action: { viewModel.createTestWEG() }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Test-Daten laden")
                }
                .foregroundColor(.green)
            }
        }
        .navigationTitle("Aktionen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Backup & Restore

private struct BackupRestoreView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WEG.abrechnungsjahr, order: .reverse) private var wegs: [WEG]
    @Query(sort: \AenderungsLog.datum, order: .reverse) private var aenderungsLog: [AenderungsLog]
    @Query private var eigentuemerProfile: [EigentuemerProfil]
    @Query private var abrechnungsZeilen: [AbrechnungsZeileKonfiguration]

    @State private var backupManager = BackupManager()
    @State private var iCloudManager = ICloudBackupManager()
    @State private var pocketBaseService = PocketBaseBackupService()

    @AppStorage("pb_base_url") private var pbBaseURL = ""
    @AppStorage("pb_email") private var pbEmail = ""
    @AppStorage("pb_password") private var pbPassword = ""
    @AppStorage("pb_collection") private var pbCollection = "hausverwaltung"
    @AppStorage("pb_file_field") private var pbFileField = "backups"

    @State private var exportItem: ExportItem? = nil
    @State private var showImportSheet = false
    @State private var popupTitel = ""
    @State private var popupText = ""
    @State private var showPopup = false
    @State private var showWiederherstellungBestaetigung = false
    @State private var geladenerBackup: HausverwaltungBackup? = nil
    @State private var isSyncInProgress = false
    @State private var iCloudStatusText: String? = nil
    @State private var pocketBaseStatusText: String? = nil

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Backup erstellt eine portable .hausverwaltung-Datei. Du kannst sie in der Dateien-App speichern oder teilen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Enthalten: WEG-Stammdaten, Wohnungen, Zähler, Zahlungen, Ausgaben (Monatswerte inkl. Korrekturen), Eigentümer-Profile, Abrechnungszeilen, Änderungsprotokoll, PDF-Einstellungen.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("Hinweis: Benutzerdefinierte Ausgaben-Spalten werden über Kategorienliste und Ausgabenwerte wiederhergestellt.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Sichern") {
                Button {
                    erstelleBackup()
                } label: {
                    Label("Backup erstellen & teilen", systemImage: "arrow.up.doc")
                        .foregroundStyle(.purple)
                }
            }

            Section("iCloud Drive") {
                Button {
                    erstelleBackupInICloud()
                } label: {
                    Label("Backup direkt in iCloud speichern", systemImage: "icloud.and.arrow.up")
                }
                .disabled(isSyncInProgress)

                Button {
                    ladeNeuestesICloudBackup()
                } label: {
                    Label("Neuestes iCloud-Backup laden", systemImage: "icloud.and.arrow.down")
                }
                .disabled(isSyncInProgress)

                if let iCloudStatusText {
                    Text(iCloudStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("In der Dateien-App findest du die Backups unter iCloud Drive im Ordner der App Hausverwaltung 2.0.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Section("PocketBase") {
                TextField("Server-URL (z. B. https://api.meine-app.de)", text: $pbBaseURL)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                TextField("E-Mail", text: $pbEmail)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField("Passwort", text: $pbPassword)

                TextField("Collection", text: $pbCollection)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)

                TextField("Datei-Feld", text: $pbFileField)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)

                Button {
                    uploadZuPocketBase()
                } label: {
                    Label("Backup zu PocketBase hochladen", systemImage: "arrow.up.circle")
                }
                .disabled(isSyncInProgress)

                Button {
                    ladeNeuestesPocketBaseBackup()
                } label: {
                    Label("Neuestes PocketBase-Backup laden", systemImage: "arrow.down.circle")
                }
                .disabled(isSyncInProgress)

                if let pocketBaseStatusText {
                    Text(pocketBaseStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Hinweis: Für den Upload muss in PocketBase eine Collection mit einem Datei-Feld vorhanden sein (Standard: Collection 'hausverwaltung', Feld 'backups').")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Section("Wiederherstellen") {
                Button {
                    showImportSheet = true
                } label: {
                    Label("Backup-Datei laden...", systemImage: "arrow.down.doc")
                        .foregroundStyle(.blue)
                }

                if let backup = geladenerBackup {
                    let enthalteneWegs = (backup.wegs?.isEmpty == false) ? (backup.wegs ?? []) : (backup.weg.map { [$0] } ?? [])
                    let sortiertJahre = enthalteneWegs.map { $0.abrechnungsjahr }.sorted(by: >)
                    let jahreText = sortiertJahre.map(String.init).joined(separator: ", ")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Geladene Backup-Datei")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(enthalteneWegs.first?.name ?? "Unbekannt")
                            .fontWeight(.semibold)

                        Label(
                            enthalteneWegs.count == 1
                                ? "Enthält 1 Jahr: \(jahreText)"
                                : "Enthält \(enthalteneWegs.count) Jahre: \(jahreText)",
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundStyle(enthalteneWegs.count > 1 ? .green : .orange)

                        ForEach(sortiertJahre, id: \.self) { jahr in
                            if let w = enthalteneWegs.first(where: { $0.abrechnungsjahr == jahr }) {
                                HStack {
                                    Text("Jahr \(jahr)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(w.wohnungen.count) Wohnungen")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    if w.abgeschlossen {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }

                        Text("Erstellt: \(backup.erstelltAm.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    Button(role: .destructive) {
                        showWiederherstellungBestaetigung = true
                    } label: {
                        Label("Jahre aus Backup wiederherstellen", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportItem) { item in
            ExportDocumentPicker(url: item.url)
        }
        .sheet(isPresented: $showImportSheet) {
            ImportDocumentPicker { result in
                switch result {
                case .success(let url):
                    ladeBackupDatei(url: url)
                case .failure(let error):
                    zeigePopup(titel: "Fehler", text: error.localizedDescription)
                }
            }
        }
        .confirmationDialog(
            "Nur Jahre aus der Backup-Datei werden ersetzt. Fortfahren?",
            isPresented: $showWiederherstellungBestaetigung,
            titleVisibility: .visible
        ) {
            Button("Wiederherstellen", role: .destructive) {
                wiederherstellenBackup()
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .alert(popupTitel, isPresented: $showPopup) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(popupText)
        }
    }

    private func erstelleBackup() {
        do {
            let url = try backupManager.exportBackup(
                wegs: wegs,
                eigentuemerProfile: eigentuemerProfile,
                abrechnungsZeilen: abrechnungsZeilen,
                aenderungsLog: aenderungsLog,
                adminPinHash: viewModel.adminPinHash
            )
            exportItem = ExportItem(url: url)
            zeigePopup(titel: "Erfolg", text: "Backup-Datei wurde erstellt und kann jetzt geteilt werden.")
        } catch {
            zeigePopup(titel: "Fehler", text: error.localizedDescription)
        }
    }

    private func erzeugeBackupDatei() throws -> URL {
        try backupManager.exportBackup(
            wegs: wegs,
            eigentuemerProfile: eigentuemerProfile,
            abrechnungsZeilen: abrechnungsZeilen,
            aenderungsLog: aenderungsLog,
            adminPinHash: viewModel.adminPinHash
        )
    }

    private func pocketBaseConfig() -> PocketBaseBackupConfig {
        PocketBaseBackupConfig(
            baseURL: pbBaseURL,
            email: pbEmail,
            password: pbPassword,
            collection: pbCollection,
            fileFieldName: pbFileField
        )
    }

    private func erstelleBackupInICloud() {
        do {
            let localURL = try erzeugeBackupDatei()
            let cloudURL = try iCloudManager.speichereBackupNachICloud(von: localURL)
            iCloudStatusText = "Gespeichert in iCloud: \(ICloudBackupManager.normalisierteDateiname(cloudURL))"
            zeigePopup(titel: "Erfolg", text: "iCloud-Backup erfolgreich gespeichert.")
        } catch {
            zeigePopup(titel: "Fehler", text: error.localizedDescription)
        }
    }

    private func ladeNeuestesICloudBackup() {
        do {
            let kandidaten = try iCloudManager.listeBackupsInICloud()
            guard !kandidaten.isEmpty else {
                throw ICloudBackupManager.ICloudBackupError.keineDateienGefunden
            }

            var letzterFehler: Error?
            var erfolgreichGeladeneDatei: URL?

            for cloudURL in kandidaten {
                do {
                    let localURL = try iCloudManager.backupAusICloudLokalKopieren(cloudURL)
                    let backup = try backupManager.ladeBackup(von: localURL)
                    geladenerBackup = backup
                    erfolgreichGeladeneDatei = localURL
                    break
                } catch {
                    letzterFehler = error
                }
            }

            if let localURL = erfolgreichGeladeneDatei {
                iCloudStatusText = "iCloud-Backup geladen: \(ICloudBackupManager.normalisierteDateiname(localURL))"
                zeigePopup(titel: "Erfolg", text: "iCloud-Backup wurde geladen.")
            } else if let letzterFehler {
                throw letzterFehler
            } else {
                throw ICloudBackupManager.ICloudBackupError.keineDateienGefunden
            }
        } catch {
            zeigePopup(titel: "Fehler", text: error.localizedDescription)
        }
    }

    private func uploadZuPocketBase() {
        let config = pocketBaseConfig()
        guard config.istVollstaendig else {
            zeigePopup(titel: "Fehler", text: PocketBaseBackupService.PocketBaseError.ungueltigeKonfiguration.localizedDescription)
            return
        }

        isSyncInProgress = true
        Task {
            do {
                let dateiURL = try erzeugeBackupDatei()
                try await pocketBaseService.uploadBackup(config: config, dateiURL: dateiURL)
                await MainActor.run {
                    pocketBaseStatusText = "Upload erfolgreich: \(dateiURL.lastPathComponent)"
                    zeigePopup(titel: "Erfolg", text: "PocketBase-Backup erfolgreich hochgeladen.")
                    isSyncInProgress = false
                }
            } catch {
                await MainActor.run {
                    zeigePopup(titel: "Fehler", text: error.localizedDescription)
                    isSyncInProgress = false
                }
            }
        }
    }

    private func ladeNeuestesPocketBaseBackup() {
        let config = pocketBaseConfig()
        guard config.istVollstaendig else {
            zeigePopup(titel: "Fehler", text: PocketBaseBackupService.PocketBaseError.ungueltigeKonfiguration.localizedDescription)
            return
        }

        isSyncInProgress = true
        Task {
            do {
                let localURL = try await pocketBaseService.ladeNeuestesBackup(config: config)
                await MainActor.run {
                    ladeBackupDatei(url: localURL)
                    pocketBaseStatusText = "Download erfolgreich: \(localURL.lastPathComponent)"
                    zeigePopup(titel: "Erfolg", text: "PocketBase-Backup wurde geladen.")
                    isSyncInProgress = false
                }
            } catch {
                await MainActor.run {
                    zeigePopup(titel: "Fehler", text: error.localizedDescription)
                    isSyncInProgress = false
                }
            }
        }
    }

    private func ladeBackupDatei(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            geladenerBackup = try backupManager.ladeBackup(von: url)
            zeigePopup(titel: "Erfolg", text: "Backup-Datei wurde geladen.")
        } catch {
            zeigePopup(titel: "Fehler", text: error.localizedDescription)
        }
    }

    private func wiederherstellenBackup() {
        guard let backup = geladenerBackup else { return }
        do {
            try backupManager.wiederherstellenBackup(backup, modelContext: modelContext)

            // Zum neuesten Jahr aus dem Backup navigieren
            let wegBackups: [WEGBackup]
            if let alle = backup.wegs, !alle.isEmpty { wegBackups = alle }
            else if let einzel = backup.weg { wegBackups = [einzel] }
            else { wegBackups = [] }

            let jahreText = wegBackups.map { $0.abrechnungsjahr }.sorted(by: >).map(String.init).joined(separator: ", ")

            if let neuestesJahr = wegBackups.map({ $0.abrechnungsjahr }).max() {
                viewModel.jahresWechsel(zu: neuestesJahr)
            } else {
                viewModel.reload()
            }

            geladenerBackup = nil
            zeigePopup(titel: "Wiederherstellung erfolgreich", text: "Folgende Jahre wurden wiederhergestellt: \(jahreText.isEmpty ? "–" : jahreText)")
        } catch {
            zeigePopup(titel: "Fehler", text: error.localizedDescription)
        }
    }

    private func zeigePopup(titel: String, text: String) {
        popupTitel = titel
        popupText = text
        showPopup = true
    }
}

private struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// UIDocumentPicker für "Exportieren nach Dateien".
private struct ExportDocumentPicker: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: [url], asCopy: true)
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

/// UIDocumentPicker für "Backup-Datei laden".
private struct ImportDocumentPicker: UIViewControllerRepresentable {
    let onResult: (Result<URL, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let hausverwaltungType = UTType(filenameExtension: "hausverwaltung")
        let contentTypes: [UTType] = {
            if let hausverwaltungType {
                return [hausverwaltungType, .json, .data]
            }
            return [.json, .data]
        }()

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onResult: (Result<URL, Error>) -> Void

        init(onResult: @escaping (Result<URL, Error>) -> Void) {
            self.onResult = onResult
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onResult(.failure(NSError(domain: "BackupImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Keine Datei ausgewählt."])))
                return
            }
            onResult(.success(url))
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Kein Fehlerdialog bei Abbruch.
        }
    }
}

private struct AbrechnungsZeilenKonfigurationView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    let wohnung: Wohnung?

    private var zeilen: [AbrechnungsZeileKonfiguration] {
        viewModel.abrechnungsZeilen(fuer: wohnung)
    }

    var body: some View {
        List {
            Section {
                Button {
                    _ = viewModel.createAbrechnungsZeile(global: wohnung == nil, wohnung: wohnung)
                } label: {
                    Label("Neue Abrechnungszeile", systemImage: "plus.circle.fill")
                }
                .foregroundColor(.indigo)
            }

            if zeilen.isEmpty {
                Section {
                    Text("Noch keine Zeilen angelegt.")
                        .foregroundColor(.secondary)
                }
            } else {
                Section {
                    ForEach(zeilen) { zeile in
                        NavigationLink {
                            AbrechnungsZeileEditorView(viewModel: viewModel, zeile: zeile, wohnung: wohnung)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(zeile.name)
                                        .fontWeight(.semibold)
                                    if zeile.istStandard {
                                        Text("Standard")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    Spacer()
                                    Text(zeile.nutztAutomatischeQuellen ? "Automatisch" : String(format: "%.2f €", zeile.gesamtbetragEuro))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(zeile.schluesselBezeichnungAnzeige + (zeile.aktiv ? "" : " · Inaktiv"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(zeile.quellenBeschreibung)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let zeile = zeilen[index]
                            if !zeile.istStandard {
                                viewModel.deleteAbrechnungsZeile(zeile)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(wohnung == nil ? "Globale Zeilen" : "Zeilen W\(wohnung?.wohnungsnummer ?? 0)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AbrechnungsZeileEditorView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @Bindable var zeile: AbrechnungsZeileKonfiguration
    let wohnung: Wohnung?

    private let betragQuellenOptionen: [AbrechnungsWertQuelle] = [
        .verguetungHmtEuro,
        .heizkostenBrennstoffEuro,
        .gesamtwasserbetragLtRechnungEuro,
        .schornsteinfegerEuro,
        .wartungBaurEuro,
        .allgemeinStromEuro,
        .muellGebuehrenEuro,
        .versicherungGebaeudeMitFeuerEuro,
        .versicherungHausHaftpflichtEuro,
        .hausUndGrundEuro,
        .nebenkostenGeldverkehrEuro,
        .reparaturenAnschaffungenEuro,
        .ruecklagenEuro,
    ]

    private let schluesselQuellenOptionen: [AbrechnungsWertQuelle] = [
        .none,
        .wohnungsanzahl,
        .constantOne,
        .muellGesamtPersonen,
        .wohnungPersonen,
        .wohnflaecheGesamt,
        .wohnflaecheWohnung,
        .heizungVerbrauchGesamt,
        .heizungVerbrauchWohnung,
        .miteigentumsanteileGesamt,
        .miteigentumsanteileWohnung,
        .haushaltPersonenGesamt,
        .haushaltPersonenWohnung,
    ]

    private let wohnungsBetragOptionen: [AbrechnungsWertQuelle] = [
        .heizungVerbrauchAnteil,
        .verguetungHmtEuro,
        .allgemeinStromEuro,
        .muellGebuehrenEuro,
        .hausUndGrundEuro,
        .nebenkostenGeldverkehrEuro,
        .reparaturenAnschaffungenEuro,
        .ruecklagenEuro,
    ]

    private var standardInfoText: String {
        "Standardzeilen sind gegen Löschen und Quellen-Umbau geschützt, damit die 10 Basiszeilen konsistent bleiben."
    }

    private func quelleIstAktiv(_ quelle: AbrechnungsWertQuelle) -> Binding<Bool> {
        Binding(
            get: { zeile.betragQuellen.contains(quelle) },
            set: { aktiv in
                var quellen = zeile.betragQuellen
                if aktiv {
                    if !quellen.contains(quelle) {
                        quellen.append(quelle)
                    }
                } else {
                    quellen.removeAll { $0 == quelle }
                }
                zeile.setBetragQuellen(quellen)
            }
        )
    }

    var body: some View {
        Form {
            Section("Zeile") {
                TextField("Bezeichnung", text: $zeile.name)
                    .disabled(zeile.istStandard)
                if zeile.nutztAutomatischeQuellen {
                    LabeledContent("Gesamtbetrag") {
                        Text("Automatisch aus Quellen")
                            .foregroundColor(.secondary)
                    }
                } else {
                    TextField("Gesamtbetrag in €", value: $zeile.gesamtbetragEuro, format: .number)
                        .keyboardType(.decimalPad)
                }

                Toggle("Aktiv", isOn: $zeile.aktiv)
                HStack {
                    Text("Typ")
                    Spacer()
                    Text(zeile.istGlobal ? "Global" : "Wohnung")
                        .foregroundColor(.secondary)
                }
                if zeile.istStandard {
                    HStack {
                        Text("Standardzeile")
                        Spacer()
                        Text(zeile.systemCode)
                            .foregroundColor(.secondary)
                    }
                    Text(standardInfoText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Herkunft") {
                LabeledContent("Betragsquellen") {
                    Text(zeile.quellenBeschreibung)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                }
                if zeile.anteilsModellSicher == .direkterBetrag {
                    LabeledContent("Wohnungsbetrag") {
                        Text(zeile.wohnungsBetragQuelleSicher.anzeigeName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                }

                if zeile.istStandard {
                    ForEach(zeile.betragQuellen, id: \.self) { quelle in
                        LabeledContent(quelle.anzeigeName) {
                            Text("Aktiv")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Picker(
                        "Anteilsmodell",
                        selection: Binding(
                            get: { zeile.anteilsModellSicher },
                            set: { zeile.setAnteilsModell($0) }
                        )
                    ) {
                        ForEach(AbrechnungsAnteilModell.allCases, id: \.self) { modell in
                            Text(modell.anzeigeName).tag(modell)
                        }
                    }

                    ForEach(betragQuellenOptionen, id: \.self) { quelle in
                        Toggle(quelle.anzeigeName, isOn: quelleIstAktiv(quelle))
                    }

                    if zeile.anteilsModellSicher == .direkterBetrag {
                        Picker(
                            "Wohnungsbetrag aus",
                            selection: Binding(
                                get: { zeile.wohnungsBetragQuelleSicher },
                                set: { zeile.setWohnungsBetragQuelle($0) }
                            )
                        ) {
                            ForEach(wohnungsBetragOptionen, id: \.self) { quelle in
                                Text(quelle.anzeigeName).tag(quelle)
                            }
                        }
                    }
                }
            }

            Section("Verteilungsschlüssel") {
                Picker("Schlüssel", selection: $zeile.schluesselArt) {
                    ForEach(VerteilungsschluesselArt.allCases, id: \.self) { art in
                        Text(art.anzeigeName).tag(art)
                    }
                }
                .disabled(zeile.istStandard)

                TextField("Schlüsselbezeichnung", text: $zeile.schluesselBezeichnungOverride)

                if zeile.istStandard {
                    LabeledContent("Gesamtschlüssel aus") {
                        Text(zeile.schluesselGesamtQuelleSicher.anzeigeName)
                            .foregroundColor(.secondary)
                    }
                    LabeledContent("Umlageschlüssel aus") {
                        Text(zeile.schluesselWertQuelleSicher.anzeigeName)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Picker(
                        "Gesamtschlüssel aus",
                        selection: Binding(
                            get: { zeile.schluesselGesamtQuelleSicher },
                            set: { zeile.setSchluesselGesamtQuelle($0) }
                        )
                    ) {
                        ForEach(schluesselQuellenOptionen, id: \.self) { quelle in
                            Text(quelle.anzeigeName).tag(quelle)
                        }
                    }

                    Picker(
                        "Umlageschlüssel aus",
                        selection: Binding(
                            get: { zeile.schluesselWertQuelleSicher },
                            set: { zeile.setSchluesselWertQuelle($0) }
                        )
                    ) {
                        ForEach(schluesselQuellenOptionen, id: \.self) { quelle in
                            Text(quelle.anzeigeName).tag(quelle)
                        }
                    }
                }

                TextField("Gesamtschlüssel manuell (optional)", value: $zeile.gesamtSchluesselManuell, format: .number)
                    .keyboardType(.decimalPad)

                if wohnung != nil || !zeile.istGlobal {
                    TextField("Wohnungsschlüssel manuell (optional)", value: $zeile.wohnungsSchluesselManuell, format: .number)
                        .keyboardType(.decimalPad)
                }
            }

            Section {
                if zeile.istStandard {
                    Text("Standardzeilen können nicht gelöscht werden.")
                        .foregroundColor(.secondary)
                } else {
                    Button(role: .destructive) {
                        viewModel.deleteAbrechnungsZeile(zeile)
                    } label: {
                        Label("Zeile löschen", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Abrechnungszeile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Admin-PIN einrichten

struct AdminPinEinrichtenView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var pinWiederholung = ""
    @State private var fehler = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Neuen Admin-PIN festlegen")) {
                    SecureField("PIN eingeben", text: $pin)
                        .keyboardType(.numberPad)
                    SecureField("PIN wiederholen", text: $pinWiederholung)
                        .keyboardType(.numberPad)
                }
                if !fehler.isEmpty {
                    Section {
                        Text(fehler).foregroundColor(.red)
                    }
                }
                Section {
                    Text("Der PIN schützt alle Änderungen an Heizkostenverteilern und Wasserzählern. Jede Änderung wird im Protokoll erfasst.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Admin-PIN")
            .navigationBarTitleDisplayMode(.inline)
            .appKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                        .disabled(pin.isEmpty || pin != pinWiederholung)
                }
            }
        }
    }

    private func speichern() {
        guard pin.count >= 4 else { fehler = "PIN muss mindestens 4 Stellen haben."; return }
        guard pin == pinWiederholung else { fehler = "PINs stimmen nicht überein."; return }
        viewModel.adminPinSetzen(pin)
        dismiss()
    }
}

// MARK: - Admin-PIN ändern

struct AdminPinAendernView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var alterPin = ""
    @State private var neuerPin = ""
    @State private var neuerPinWiederholung = ""
    @State private var fehler = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Aktuellen PIN bestätigen")) {
                    SecureField("Alter PIN", text: $alterPin)
                        .keyboardType(.numberPad)
                }
                Section(header: Text("Neuer PIN")) {
                    SecureField("Neuer PIN", text: $neuerPin)
                        .keyboardType(.numberPad)
                    SecureField("Neuer PIN wiederholen", text: $neuerPinWiederholung)
                        .keyboardType(.numberPad)
                }
                if !fehler.isEmpty {
                    Section { Text(fehler).foregroundColor(.red) }
                }
            }
            .navigationTitle("PIN ändern")
            .navigationBarTitleDisplayMode(.inline)
            .appKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                        .disabled(alterPin.isEmpty || neuerPin.isEmpty || neuerPin != neuerPinWiederholung)
                }
            }
        }
    }

    private func speichern() {
        guard neuerPin.count >= 4 else { fehler = "PIN muss mindestens 4 Stellen haben."; return }
        guard viewModel.adminPinAendern(alter: alterPin, neuer: neuerPin) else {
            fehler = "Alter PIN ist nicht korrekt."
            return
        }
        dismiss()
    }
}

// MARK: - Änderungsprotokoll

struct AenderungsLogView: View {
    @Query(sort: \AenderungsLog.datum, order: .reverse) private var log: [AenderungsLog]

    var body: some View {
        List {
            if log.isEmpty {
                ContentUnavailableView("Keine Einträge", systemImage: "list.bullet.clipboard", description: Text("Noch wurden keine PIN-geschützten Änderungen vorgenommen."))
            } else {
                ForEach(log) { eintrag in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(eintrag.bereich)
                                .font(.caption)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(eintrag.bereich == "HKV" ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15))
                                .foregroundColor(eintrag.bereich == "HKV" ? .orange : .blue)
                                .cornerRadius(4)
                            Text("W\(eintrag.wohnungsnummer) · \(eintrag.eigentuemer)")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text(eintrag.datum, format: .dateTime.day().month().year().hour().minute())
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Text("Zähler \(eintrag.zaehlernummer) · \(eintrag.feldname)")
                            .font(.subheadline).fontWeight(.medium)
                        HStack {
                            Text("Alt: \(eintrag.altWert)").font(.caption).foregroundColor(.red)
                            Text("→")
                            Text("Neu: \(eintrag.neuWert)").font(.caption).foregroundColor(.green)
                        }
                        if !eintrag.grund.isEmpty {
                            Text("Grund: \(eintrag.grund)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Änderungsprotokoll")
    }
}

// MARK: - Zählerverwaltung je Wohnung

struct WohnungZaehlerVerwaltungView: View {
    @Bindable var wohnung: Wohnung
    @ObservedObject var viewModel: AbrechnungViewModel

    // PIN-Schutz State
    @State private var pinEingabe = ""
    @State private var pinFehler = false
    @State private var bearbeitenFreigegeben = false

    // HKV-Bearbeitung
    @State private var gewaehlterHKV: HeizkostenverteilerZaehler? = nil
    @State private var showHKVBearbeiten = false

    // Wasserzähler-Bearbeitung
    @State private var gewaehlterWasser: Wasserzaehler? = nil
    @State private var showWasserBearbeiten = false

    // PIN-Alert
    @State private var showPinAlert = false
    @State private var pendingAction: (() -> Void)? = nil

    private var istSchreibgeschuetzt: Bool { viewModel.istJahrSchreibgeschuetzt }

    var body: some View {
        List {
            Section("Wohnung") {
                HStack {
                    Text("Einheit"); Spacer()
                    Text("W\(wohnung.wohnungsnummer)").foregroundColor(.secondary)
                }
                HStack {
                    Text("Eigentümer"); Spacer()
                    Text(wohnung.eigentuemer).foregroundColor(.secondary)
                }

                Stepper(value: $wohnung.personenanzahl, in: 1...20) {
                    Text("Personen in Wohnung: \(wohnung.personenanzahl)")
                }
                .disabled(istSchreibgeschuetzt)

                Stepper(value: $wohnung.eigentumsanteilTausendstel, in: 0...1000) {
                    Text("Eigentumsanteile: \(wohnung.eigentumsanteilTausendstel) / 1000")
                }
                .disabled(istSchreibgeschuetzt)

                Text("Diese beiden Werte werden zentral an der Wohnung gepflegt und automatisch in die Abrechnung übernommen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                NavigationLink {
                    AbrechnungsZeilenKonfigurationView(viewModel: viewModel, wohnung: wohnung)
                } label: {
                    Label("Fixe Abrechnungsmaske", systemImage: "slider.horizontal.3")
                }
                .disabled(istSchreibgeschuetzt)
            }

            // MARK: HKV
            Section {
                ForEach(wohnung.heizkostenverteiler) { zaehler in
                    HKVZeile(zaehler: zaehler) {
                        // Bearbeiten angefordert
                        pinGeschutztAusfuehren {
                            gewaehlterHKV = zaehler
                            showHKVBearbeiten = true
                        }
                    }
                }
                .onDelete { offsets in
                    pinGeschutztAusfuehren {
                        for index in offsets {
                            viewModel.removeHKVZaehler(from: wohnung, zaehler: wohnung.heizkostenverteiler[index])
                        }
                    }
                }
                Button { viewModel.addHKVZaehler(to: wohnung) } label: {
                    Label("HKV hinzufügen", systemImage: "plus.circle")
                }
                .disabled(istSchreibgeschuetzt)
            } header: {
                Text("Heizkostenverteiler (HKV)")
            }

            // MARK: Wasserzähler
            Section {
                ForEach(wohnung.wasserzaehler) { zaehler in
                    WasserZeile(zaehler: zaehler) {
                        pinGeschutztAusfuehren {
                            gewaehlterWasser = zaehler
                            showWasserBearbeiten = true
                        }
                    }
                }
                .onDelete { offsets in
                    pinGeschutztAusfuehren {
                        for index in offsets {
                            viewModel.removeWasserzaehler(from: wohnung, zaehler: wohnung.wasserzaehler[index])
                        }
                    }
                }
                Button { viewModel.addWasserzaehler(to: wohnung, art: .warmwasser) } label: {
                    Label("Warmwasserzähler hinzufügen", systemImage: "plus.circle")
                }
                .disabled(istSchreibgeschuetzt)
                Button { viewModel.addWasserzaehler(to: wohnung, art: .kaltwasser) } label: {
                    Label("Kaltwasserzähler hinzufügen", systemImage: "plus.circle")
                }
                .disabled(istSchreibgeschuetzt)
                Button { viewModel.addWasserzaehler(to: wohnung, art: .waschkueche) } label: {
                    Label("Waschküchenzähler hinzufügen", systemImage: "plus.circle")
                }
                .disabled(istSchreibgeschuetzt)
            } header: {
                Text("Wasserzähler")
            }
        }
        .navigationTitle("Zählerverwaltung")
        .onChange(of: wohnung.personenanzahl) {
            viewModel.synchronisiereWohnungsStammdaten(wohnung)
        }
        .onChange(of: wohnung.eigentumsanteilTausendstel) {
            viewModel.synchronisiereWohnungsStammdaten(wohnung)
        }
        // PIN-Alert
        .alert("Admin-PIN eingeben", isPresented: $showPinAlert) {
            SecureField("PIN", text: $pinEingabe)
            Button("Bestätigen") {
                if viewModel.adminPinPruefen(pinEingabe) {
                    pinFehler = false
                    pendingAction?()
                    pendingAction = nil
                } else {
                    pinFehler = true
                }
                pinEingabe = ""
            }
            Button("Abbrechen", role: .cancel) {
                pendingAction = nil
                pinEingabe = ""
            }
        } message: {
            Text(pinFehler ? "Falscher PIN. Bitte erneut versuchen." : "Für diese Änderung ist der Admin-PIN erforderlich.")
        }
        // HKV bearbeiten
        .sheet(isPresented: $showHKVBearbeiten, onDismiss: { gewaehlterHKV = nil }) {
            if let zaehler = gewaehlterHKV {
                HKVBearbeitenSheet(zaehler: zaehler, wohnung: wohnung, viewModel: viewModel)
            }
        }
        // Wasser bearbeiten
        .sheet(isPresented: $showWasserBearbeiten, onDismiss: { gewaehlterWasser = nil }) {
            if let zaehler = gewaehlterWasser {
                WasserBearbeitenSheet(zaehler: zaehler, wohnung: wohnung, viewModel: viewModel)
            }
        }
    }

    private func pinGeschutztAusfuehren(_ action: @escaping () -> Void) {
        if !viewModel.adminAngelegegt {
            action()
        } else {
            pendingAction = action
            showPinAlert = true
        }
    }
}

// MARK: - HKV Zeile (Anzeige mit Bearbeiten-Button)

struct HKVZeile: View {
    var zaehler: HeizkostenverteilerZaehler
    let onBearbeiten: () -> Void

    @State private var historieSichtbar = false
    @Query private var historieAlle: [HKVHistorieEintrag]

    var historie: [HKVHistorieEintrag] {
        historieAlle.filter { $0.nummer == zaehler.nummer }.sorted { $0.datum > $1.datum }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(zaehler.nummer).fontWeight(.semibold)
                    Text(zaehler.bezeichnung).font(.caption).foregroundColor(.secondary)
                    if !zaehler.heizungstyp.isEmpty {
                        Text(zaehler.heizungstyp).font(.caption2).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Faktor: \(String(format: "%.4f", zaehler.faktor))")
                        .font(.caption2)
                    Text("Ablesew.: \(String(format: "%.1f", zaehler.ablesewertNeu))")
                        .font(.caption2)
                    Text("Punkte: \(String(format: "%.2f", zaehler.verbrauchPunkte))")
                        .font(.caption2)
                }
                Button(action: onBearbeiten) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
            if !historie.isEmpty {
                Button {
                    historieSichtbar.toggle()
                } label: {
                    Label(historieSichtbar ? "Historie ausblenden" : "Historie (\(historie.count))",
                          systemImage: "clock.arrow.circlepath")
                        .font(.caption).foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                if historieSichtbar {
                    ForEach(historie) { h in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(h.datum, format: .dateTime.day().month().year())
                                    .font(.caption2).foregroundColor(.secondary)
                                Text("Grund: \(h.grund)").font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("F: \(String(format: "%.4f", h.faktor))").font(.caption2)
                                Text("A: \(String(format: "%.1f", h.ablesewertNeu))").font(.caption2)
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Wasserzähler Zeile

struct WasserZeile: View {
    var zaehler: Wasserzaehler
    let onBearbeiten: () -> Void

    @State private var historieSichtbar = false
    @Query private var historieAlle: [WasserzaehlerHistorieEintrag]

    var historie: [WasserzaehlerHistorieEintrag] {
        historieAlle.filter { $0.nummer == zaehler.nummer }.sorted { $0.datum > $1.datum }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(zaehler.nummer).fontWeight(.semibold)
                    Text("\(zaehler.art.rawValue) · \(zaehler.bezeichnung)").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Alt: \(String(format: "%.3f", zaehler.ablesewertAlt))").font(.caption2)
                    Text("Neu: \(String(format: "%.3f", zaehler.ablesewertNeu))").font(.caption2)
                    Text("Verbr.: \(String(format: "%.3f", zaehler.verbrauch)) m³").font(.caption2).foregroundColor(.blue)
                }
                Button(action: onBearbeiten) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
            if !historie.isEmpty {
                Button {
                    historieSichtbar.toggle()
                } label: {
                    Label(historieSichtbar ? "Historie ausblenden" : "Historie (\(historie.count))",
                          systemImage: "clock.arrow.circlepath")
                        .font(.caption).foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                if historieSichtbar {
                    ForEach(historie) { h in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(h.datum, format: .dateTime.day().month().year())
                                    .font(.caption2).foregroundColor(.secondary)
                                Text("Grund: \(h.grund)").font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Alt: \(String(format: "%.3f", h.ablesewertAlt))").font(.caption2)
                                Text("Neu: \(String(format: "%.3f", h.ablesewertNeu))").font(.caption2)
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - HKV Bearbeiten Sheet

struct HKVBearbeitenSheet: View {
    var zaehler: HeizkostenverteilerZaehler
    var wohnung: Wohnung
    @ObservedObject var viewModel: AbrechnungViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var faktor: Double
    @State private var ablesewertNeu: Double
    @State private var verbrauchPunkte: Double
    @State private var bezeichnung: String
    @State private var heizungstyp: String
    @State private var hinweis: String
    @State private var grund: String = ""
    @State private var grundFehler = false

    init(zaehler: HeizkostenverteilerZaehler, wohnung: Wohnung, viewModel: AbrechnungViewModel) {
        self.zaehler = zaehler
        self.wohnung = wohnung
        self.viewModel = viewModel
        _faktor = State(initialValue: zaehler.faktor)
        _ablesewertNeu = State(initialValue: zaehler.ablesewertNeu)
        _verbrauchPunkte = State(initialValue: zaehler.verbrauchPunkte)
        _bezeichnung = State(initialValue: zaehler.bezeichnung)
        _heizungstyp = State(initialValue: zaehler.heizungstyp)
        _hinweis = State(initialValue: zaehler.hinweis)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Zähler \(zaehler.nummer)")) {
                    HStack {
                        Text("Bezeichnung")
                        Spacer()
                        TextField("Raum", text: $bezeichnung)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Heizungstyp")
                        Spacer()
                        TextField("Typ", text: $heizungstyp)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Hinweis")
                        Spacer()
                        TextField("z.B. erneuert", text: $hinweis)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Messwerte")) {
                    HStack {
                        Text("Faktor")
                        Spacer()
                        TextField("Faktor", value: $faktor, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Ablesewert neu")
                        Spacer()
                        TextField("Wert", value: $ablesewertNeu, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Verbrauchspunkte")
                        Spacer()
                        TextField("Punkte", value: $verbrauchPunkte, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Pflichtangabe")) {
                    HStack {
                        TextField("Grund der Änderung (Pflichtfeld)", text: $grund)
                        if grundFehler {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        }
                    }
                    Text("Jede Änderung wird mit Datum und Grund im Protokoll gespeichert.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("HKV bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                }
            }
        }
    }

    private func speichern() {
        guard !grund.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            grundFehler = true
            return
        }
        // Basisdaten ohne Historiepflicht (bezeichnung, heizungstyp, hinweis)
        if zaehler.bezeichnung != bezeichnung || zaehler.heizungstyp != heizungstyp || zaehler.hinweis != hinweis {
            zaehler.bezeichnung = bezeichnung
            zaehler.heizungstyp = heizungstyp
            zaehler.hinweis = hinweis
        }
        // Messwerte mit verpflichtender Historie
        viewModel.hkvTauschen(
            zaehler: zaehler,
            wohnung: wohnung,
            neuerFaktor: faktor,
            neuerAblesewert: ablesewertNeu,
            neueVerbrauchPunkte: verbrauchPunkte,
            grund: grund
        )
        dismiss()
    }
}

// MARK: - Wasserzähler Bearbeiten Sheet

struct WasserBearbeitenSheet: View {
    var zaehler: Wasserzaehler
    var wohnung: Wohnung
    @ObservedObject var viewModel: AbrechnungViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var ablesewertAlt: Double
    @State private var ablesewertNeu: Double
    @State private var faktor: Double
    @State private var bezeichnung: String
    @State private var typ: String
    @State private var art: WasserzaehlerArt
    @State private var grund: String = ""
    @State private var grundFehler = false

    init(zaehler: Wasserzaehler, wohnung: Wohnung, viewModel: AbrechnungViewModel) {
        self.zaehler = zaehler
        self.wohnung = wohnung
        self.viewModel = viewModel
        _ablesewertAlt = State(initialValue: zaehler.ablesewertAlt)
        _ablesewertNeu = State(initialValue: zaehler.ablesewertNeu)
        _faktor = State(initialValue: zaehler.faktor)
        _bezeichnung = State(initialValue: zaehler.bezeichnung)
        _typ = State(initialValue: zaehler.typ)
        _art = State(initialValue: zaehler.art)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Zähler \(zaehler.nummer)")) {
                    HStack {
                        Text("Bezeichnung")
                        Spacer()
                        TextField("Bezeichnung", text: $bezeichnung)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Typ/Hersteller")
                        Spacer()
                        TextField("Typ", text: $typ)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Art", selection: $art) {
                        Text("Warmwasser").tag(WasserzaehlerArt.warmwasser)
                        Text("Kaltwasser").tag(WasserzaehlerArt.kaltwasser)
                        Text("Waschküche").tag(WasserzaehlerArt.waschkueche)
                    }
                }

                Section(header: Text("Messwerte")) {
                    HStack {
                        Text("Ablesewert Alt")
                        Spacer()
                        TextField("Alt", value: $ablesewertAlt, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Ablesewert Neu")
                        Spacer()
                        TextField("Neu", value: $ablesewertNeu, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Faktor")
                        Spacer()
                        TextField("Faktor", value: $faktor, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    let verbrauch = max(0, (ablesewertNeu - ablesewertAlt) * faktor)
                    Text("Verbrauch: \(String(format: "%.3f", verbrauch)) m³")
                        .font(.caption).foregroundColor(.blue)
                }

                Section(header: Text("Pflichtangabe")) {
                    HStack {
                        TextField("Grund der Änderung (Pflichtfeld)", text: $grund)
                        if grundFehler {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        }
                    }
                    Text("Jede Änderung wird mit Datum und Grund im Protokoll gespeichert.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Wasserzähler bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                }
            }
        }
    }

    private func speichern() {
        guard !grund.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            grundFehler = true
            return
        }
        if zaehler.bezeichnung != bezeichnung { zaehler.bezeichnung = bezeichnung }
        if zaehler.typ != typ { zaehler.typ = typ }
        if zaehler.art != art { zaehler.art = art }
        viewModel.wasserzaehlerTauschen(
            zaehler: zaehler,
            wohnung: wohnung,
            neuerAblesewertAlt: ablesewertAlt,
            neuerAblesewertNeu: ablesewertNeu,
            neuerFaktor: faktor,
            grund: grund
        )
        dismiss()
    }
}

// MARK: - Jahr abschließen Sheet

struct JahrAbschliessenView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var fehler = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Jahr " + String(viewModel.selectedJahr) + " abschließen")) {
                    Text("Nach dem Abschluss ist das Jahr schreibgeschützt und kann nicht mehr bearbeitet werden. Dieser Schritt erfolgt nach der jährlichen Eigentümerversammlung.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("Admin-PIN eingeben", text: $pin)
                        .keyboardType(.numberPad)
                }
                if !fehler.isEmpty {
                    Section { Text(fehler).foregroundColor(.red) }
                }
            }
            .navigationTitle("Jahr abschließen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Abschließen") {
                        if viewModel.jahrAbschliessen(pin: pin) {
                            dismiss()
                        } else {
                            fehler = "Falscher PIN oder Jahr bereits abgeschlossen."
                        }
                    }
                    .disabled(pin.isEmpty)
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Neues Jahr anlegen Sheet

struct NeuesJahrAnlegenView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fehler = ""
    @State private var erfolgreich = false

    var basisJahr: Int { viewModel.selectedJahr }
    var neuesJahr: Int { basisJahr + 1 }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Neues Abrechnungsjahr \(neuesJahr)")) {
                    Text("Folgende Daten werden aus \(basisJahr) übernommen:")
                        .font(.caption).foregroundColor(.secondary)
                    ForEach([
                        "✓ Eigentümer (Name, Fläche, Personen)",
                        "✓ Zählernummern und -typen (HKV & Wasser)",
                        "✓ Wasserzähler Anfangswert = Vorjahres-Endwert",
                        "✓ Fixkosten (HMT, Heizung, Versicherungen, ...)",
                        "✗ Messwerte HKV → leer (neu ablesen)",
                        "✗ Hauptabrechnungswerte → leer (neue Rechnungen)",
                        "✗ Vorauszahlungen → leer (neues Jahr)",
                        "✗ Konto → leer",
                    ], id: \.self) { zeile in
                        Text(zeile).font(.caption2).foregroundColor(zeile.hasPrefix("✗") ? .secondary : .primary)
                    }
                }
                if !fehler.isEmpty {
                    Section { Text(fehler).foregroundColor(.red) }
                }
                if erfolgreich {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Jahr \(neuesJahr) wurde angelegt.")
                        }
                    }
                }
            }
            .navigationTitle("Neues Jahr anlegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(erfolgreich ? "Schließen" : "Abbrechen") { dismiss() }
                }
                if !erfolgreich {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Anlegen") {
                            if viewModel.neuesJahrAnlegen(basisJahr: basisJahr) {
                                erfolgreich = true
                            } else {
                                fehler = viewModel.errorMessage ?? "Unbekannter Fehler."
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Eigentümerprofil Detail

struct EigentuemerProfilDetailView: View {
    @Bindable var profil: EigentuemerProfil
    let wohnungen: [Wohnung]
    let profileImJahr: [EigentuemerProfil]
    let wegAdresse: String

    private var summeEigentumsanteile: Int {
        profileImJahr.reduce(0) { $0 + $1.eigentumsanteilTausendstel }
    }

    private var emailTrimmed: String {
        profil.email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emailIstGueltig: Bool {
        if emailTrimmed.isEmpty { return true }
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: emailTrimmed)
    }

    private var istAdresseAusserhalbObjekt: Bool {
        let profilAdresse = [profil.strasse, profil.plz, profil.ort]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let objektAdresse = wegAdresse
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !profilAdresse.isEmpty, !objektAdresse.isEmpty else { return false }
        return !objektAdresse.contains(profil.strasse.lowercased())
    }

    private var pflichtfeldFehler: [String] {
        var fehler: [String] = []
        if profil.vorname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fehler.append("Vorname fehlt")
        }
        if profil.nachname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fehler.append("Nachname fehlt")
        }
        if profil.wohnungsnummer == nil {
            fehler.append("Wohnung ist nicht zugeordnet")
        }
        if profil.eigentumsanteilTausendstel <= 0 {
            fehler.append("Eigentumsanteil muss größer als 0 sein")
        }
        if profil.nutzungsartSicher == .vermietet && profil.mieterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fehler.append("Mietername fehlt")
        }
        if profil.strasse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fehler.append("Straße/Hausnummer fehlt")
        }
        if profil.plz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fehler.append("PLZ fehlt")
        }
        if profil.ort.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fehler.append("Ort fehlt")
        }
        if profil.telefon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fehler.append("Telefon fehlt")
        }
        return fehler
    }

    var body: some View {
        Form {
            Section("Nutzung") {
                Picker(
                    "Nutzungsart",
                    selection: Binding(
                        get: { profil.nutzungsartSicher },
                        set: { profil.setNutzungsart($0) }
                    )
                ) {
                    ForEach(EigentuemerNutzungsart.allCases, id: \.self) { art in
                        Text(art.anzeigeName).tag(art)
                    }
                }

                if profil.nutzungsartSicher == .vermietet {
                    TextField("Mietername", text: $profil.mieterName)
                        .appInputTraits(.personName)
                }

                if profil.nutzungsartSicher == .eigennutzung && istAdresseAusserhalbObjekt {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Adresse wirkt extern")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Eigennutzung ist gewählt, aber die Adresse weicht von der Objektadresse ab.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Als vermietet markieren") {
                        profil.setNutzungsart(.vermietet)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }

            Section("Eigentümer") {
                TextField("Vorname", text: $profil.vorname)
                    .appInputTraits(.givenName)
                TextField("Nachname", text: $profil.nachname)
                    .appInputTraits(.familyName)

                Picker("Wohnung", selection: $profil.wohnungsnummer) {
                    Text("Keine Zuordnung").tag(Optional<Int>.none)
                    ForEach(wohnungen) { wohnung in
                        Text("W\(wohnung.wohnungsnummer) · \(wohnung.eigentuemer)")
                            .tag(Optional<Int>.some(wohnung.wohnungsnummer))
                    }
                }

                LabeledContent("Eigentumsanteil") {
                    Text("\(profil.eigentumsanteilTausendstel) / 1000")
                        .foregroundStyle(.secondary)
                }
                Text("Die Eigentumsanteile und die Personenzahl werden zentral unter Wohnungen gepflegt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let wohnungsnummer = profil.wohnungsnummer,
               let wohnung = wohnungen.first(where: { $0.wohnungsnummer == wohnungsnummer }) {
                konsistenzprüfungSection(profil: profil, wohnung: wohnung, profileImJahr: profileImJahr)
            }

            Section("Adresse") {
                TextField("Straße und Hausnummer", text: $profil.strasse)
                    .appInputTraits(.streetAddress)
                TextField("PLZ", text: $profil.plz)
                    .appInputTraits(.postalCode)
                TextField("Ort", text: $profil.ort)
                    .appInputTraits(.city)
            }

            Section("Kontaktdaten") {
                TextField("Telefon", text: $profil.telefon)
                    .appInputTraits(.phone)
                TextField("E-Mail", text: $profil.email)
                    .appInputTraits(.email)
                if !emailIstGueltig {
                    Text("E-Mail-Format ist ungültig.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section("Persönliche Daten") {
                Toggle(
                    "Geburtsdatum hinterlegen",
                    isOn: Binding(
                        get: { profil.geburtsdatum != nil },
                        set: { aktiv in
                            if aktiv {
                                profil.geburtsdatum = profil.geburtsdatum ?? Date()
                            } else {
                                profil.geburtsdatum = nil
                            }
                        }
                    )
                )

                if profil.geburtsdatum != nil {
                    DatePicker(
                        "Geburtsdatum",
                        selection: Binding(
                            get: { profil.geburtsdatum ?? Date() },
                            set: { profil.geburtsdatum = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
            }

            Section("Notfallkontakt") {
                TextField("Name Notfallkontakt", text: $profil.notfallkontakt)
                    .appInputTraits(.personName)
                TextField("Telefon Notfallkontakt", text: $profil.notfallkontaktTelefon)
                    .appInputTraits(.phone)
            }

            Section("Validierung") {
                if pflichtfeldFehler.isEmpty {
                    Text("Pflichtfelder sind vollständig.")
                        .foregroundColor(.green)
                } else {
                    ForEach(pflichtfeldFehler, id: \.self) { fehler in
                        Text("• \(fehler)")
                            .foregroundColor(.red)
                    }
                }

                HStack {
                    Text("Anteilssumme im Jahr")
                    Spacer()
                    Text("\(summeEigentumsanteile)/1000")
                        .foregroundColor(summeEigentumsanteile == 1000 ? .green : .orange)
                        .fontWeight(.semibold)
                }

                if summeEigentumsanteile != 1000 {
                    Text("Warnung: Beim Verlassen ist die Anteilssumme nicht 1000/1000.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("Eigentümer")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .appKeyboardToolbar()
    }

    @ViewBuilder
    private func konsistenzprüfungSection(profil: EigentuemerProfil, wohnung: Wohnung, profileImJahr: [EigentuemerProfil]) -> some View {
        let andereProfileMitWohnung = profileImJahr.filter { $0.wohnungsnummer == wohnung.wohnungsnummer && $0.id != profil.id }
        let adressMismatch = !andereProfileMitWohnung.isEmpty && 
            andereProfileMitWohnung.contains { anderesProfil in
                let myAddress = (profil.strasse + profil.plz + profil.ort).lowercased()
                let otherAddress = (anderesProfil.strasse + anderesProfil.plz + anderesProfil.ort).lowercased()
                return myAddress != otherAddress
            }
        
        let hatHaushaltAbweichung = profil.haushaltPersonen != max(1, wohnung.personenanzahl)
        let hatAdressAbweichung = adressMismatch
        
        if hatHaushaltAbweichung || hatAdressAbweichung {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if hatHaushaltAbweichung {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.body)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haushaltsgröße abweichend")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Profil: \(profil.haushaltPersonen) · Wohnung: \(wohnung.personenanzahl) Personen")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if hatAdressAbweichung {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.body)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Adresse stimmt nicht mit anderen Profilen dieser Wohnung überein")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("\(profil.strasse), \(profil.plz) \(profil.ort)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)

                if hatHaushaltAbweichung {
                    Button(action: {
                        profil.haushaltPersonen = max(1, wohnung.personenanzahl)
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Haushaltgröße auf \(max(1, wohnung.personenanzahl)) synchronisieren")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            } header: {
                Text("Konsistenzprüfung")
            }
        }
    }
}

// Frühere Row-Strukturen werden nicht mehr benötigt (ersetzt durch Sheets)
// HKVEditorRow und WasserEditorRow wurden durch HKVZeile/WasserZeile + Sheet-Pattern ersetzt.

// MARK: - PDFKit-Vorschau

import PDFKit

private struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.backgroundColor = .systemGroupedBackground
        return v
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if data.isEmpty {
            uiView.document = nil
            return
        }
        uiView.document = PDFDocument(data: data)
        uiView.autoScales = true
    }
}

private struct PDFPrintController: UIViewControllerRepresentable {
    let pdfData: Data
    let jobName: String
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            guard UIPrintInteractionController.isPrintingAvailable else {
                onFinish()
                return
            }
            let printController = UIPrintInteractionController.shared
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.outputType = .general
            printInfo.jobName = jobName
            printController.printInfo = printInfo
            printController.printingItem = pdfData
            printController.present(animated: true) { _, _, _ in
                onFinish()
            }
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Rechnungsvorschau & Layout

private struct RechnungsvorschauView: View {
    private enum VorschauArt: String, CaseIterable {
        case einzelabrechnung
        case heizwasserWohnung
        case zahlungen

        var titel: String {
            switch self {
            case .einzelabrechnung: return "Abrechnung"
            case .heizwasserWohnung: return "Heiz/Wasser"
            case .zahlungen: return "Zahlungen"
            }
        }
    }

    private struct LayoutPreset: Codable {
        var schriftGroesseRaw: String
        var randBreiteRaw: String
        var headerFarbeRaw: String
        var fusszeileEinblenden: Bool
        var logoPosition: String
        var logoHoehePt: Double
        var logoSkalierung: Double
        var logoOffsetY: Double
        var titelAbstandOben: Double
        var tabellenStartOffsetY: Double
        var kopfzeileText: String
        var kopfzeileOffsetY: Double
        var adresseOffsetX: Double
        var adresseOffsetY: Double
        var fusszeile1Text: String
        var fusszeile2Text: String
        var fusszeile1OffsetY: Double
        var fusszeile2OffsetY: Double

        init(layout: PDFLayoutKonfiguration) {
            self.schriftGroesseRaw = layout.schriftGroesse.rawValue
            self.randBreiteRaw = layout.randBreite.rawValue
            self.headerFarbeRaw = layout.headerFarbe.rawValue
            self.fusszeileEinblenden = layout.fusszeileEinblenden
            self.logoPosition = layout.logoPosition
            self.logoHoehePt = layout.logoHoehePt
            self.logoSkalierung = layout.logoSkalierung
            self.logoOffsetY = layout.logoOffsetY
            self.titelAbstandOben = layout.titelAbstandOben
            self.tabellenStartOffsetY = layout.tabellenStartOffsetY
            self.kopfzeileText = layout.kopfzeileText
            self.kopfzeileOffsetY = layout.kopfzeileOffsetY
            self.adresseOffsetX = layout.adresseOffsetX
            self.adresseOffsetY = layout.adresseOffsetY
            self.fusszeile1Text = layout.fusszeile1Text
            self.fusszeile2Text = layout.fusszeile2Text
            self.fusszeile1OffsetY = layout.fusszeile1OffsetY
            self.fusszeile2OffsetY = layout.fusszeile2OffsetY
        }

        var asLayout: PDFLayoutKonfiguration {
            PDFLayoutKonfiguration(
                schriftGroesse: PDFSchriftGroesse(rawValue: schriftGroesseRaw) ?? .mittel,
                randBreite: PDFRandBreite(rawValue: randBreiteRaw) ?? .normal,
                headerFarbe: PDFHeaderFarbe(rawValue: headerFarbeRaw) ?? .grau,
                fusszeileEinblenden: fusszeileEinblenden,
                logoPosition: logoPosition,
                logoHoehePt: logoHoehePt,
                logoSkalierung: logoSkalierung,
                logoOffsetY: logoOffsetY,
                titelAbstandOben: titelAbstandOben,
                tabellenStartOffsetY: tabellenStartOffsetY,
                kopfzeileText: kopfzeileText,
                kopfzeileOffsetY: kopfzeileOffsetY,
                adresseOffsetX: adresseOffsetX,
                adresseOffsetY: adresseOffsetY,
                fusszeile1Text: fusszeile1Text,
                fusszeile2Text: fusszeile2Text,
                fusszeile1OffsetY: fusszeile1OffsetY,
                fusszeile2OffsetY: fusszeile2OffsetY
            )
        }
    }

    @Bindable var weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel

    @State private var pdfData: Data = Data()
    @State private var showPrintSheet = false
    @State private var showFullscreen = false
    @State private var vorschauArt: VorschauArt = .einzelabrechnung
    @State private var previewRequestID: Int = 0
    @State private var zuletztAktiveArt: VorschauArt = .einzelabrechnung

    private var vorschauWohnung: Wohnung? { weg.wohnungenSortiert.first }

    private var currentLayout: PDFLayoutKonfiguration {
        PDFLayoutKonfiguration.from(weg: weg)
    }

    private func layoutStorageKey(for art: VorschauArt) -> String {
        "pdf-layout-preset-\(weg.id.uuidString)-\(weg.abrechnungsjahr)-\(art.rawValue)"
    }

    private func saveLayout(_ layout: PDFLayoutKonfiguration, for art: VorschauArt) {
        let preset = LayoutPreset(layout: layout)
        guard let data = try? JSONEncoder().encode(preset) else { return }
        UserDefaults.standard.set(data, forKey: layoutStorageKey(for: art))
    }

    private func loadLayout(for art: VorschauArt) -> PDFLayoutKonfiguration? {
        guard let data = UserDefaults.standard.data(forKey: layoutStorageKey(for: art)) else { return nil }
        guard let preset = try? JSONDecoder().decode(LayoutPreset.self, from: data) else { return nil }
        return preset.asLayout
    }

    private func applyLayoutToWEG(_ layout: PDFLayoutKonfiguration) {
        weg.pdfSchriftGroesseRaw = layout.schriftGroesse.rawValue
        weg.pdfRandBreiteRaw = layout.randBreite.rawValue
        weg.pdfHeaderFarbeRaw = layout.headerFarbe.rawValue
        weg.pdfFusszeileEinblenden = layout.fusszeileEinblenden
        weg.pdfLogoPositionRaw = layout.logoPosition
        weg.pdfLogoHoehePt = layout.logoHoehePt
        weg.pdfLogoSkalierung = layout.logoSkalierung
        weg.pdfLogoOffsetY = layout.logoOffsetY
        weg.pdfTitelAbstandOben = layout.titelAbstandOben
        weg.pdfTabellenStartOffsetY = layout.tabellenStartOffsetY
        weg.pdfKopfzeileText = layout.kopfzeileText
        weg.pdfKopfzeileOffsetY = layout.kopfzeileOffsetY
        weg.pdfAdresseOffsetX = layout.adresseOffsetX
        weg.pdfAdresseOffsetY = layout.adresseOffsetY
        weg.pdfFusszeile1Text = layout.fusszeile1Text
        weg.pdfFusszeile2Text = layout.fusszeile2Text
        weg.pdfFusszeile1OffsetY = layout.fusszeile1OffsetY
        weg.pdfFusszeile2OffsetY = layout.fusszeile2OffsetY
    }

    private func persistCurrentArtLayout() {
        saveLayout(PDFLayoutKonfiguration.from(weg: weg), for: vorschauArt)
    }

    private func initialisiereLayoutPresets() {
        let basis = PDFLayoutKonfiguration.from(weg: weg)
        for art in VorschauArt.allCases where loadLayout(for: art) == nil {
            saveLayout(basis, for: art)
        }
        let layout = loadLayout(for: vorschauArt) ?? basis
        applyLayoutToWEG(layout)
        zuletztAktiveArt = vorschauArt
    }

    private func wechsleAufLayoutFuerAktuelleArt() {
        saveLayout(PDFLayoutKonfiguration.from(weg: weg), for: zuletztAktiveArt)
        let layout = loadLayout(for: vorschauArt) ?? PDFLayoutKonfiguration.from(weg: weg)
        applyLayoutToWEG(layout)
        zuletztAktiveArt = vorschauArt
    }

    private var previewRefreshToken: String {
        [
            weg.pdfSchriftGroesseRaw,
            weg.pdfRandBreiteRaw,
            weg.pdfHeaderFarbeRaw,
            String(weg.pdfFusszeileEinblenden),
            weg.pdfLogoPositionRaw,
            String(weg.pdfLogoHoehePt),
            String(weg.pdfLogoSkalierung),
            String(weg.pdfLogoOffsetY),
            String(weg.pdfTitelAbstandOben),
            String(weg.pdfTabellenStartOffsetY),
            weg.pdfKopfzeileText,
            String(weg.pdfKopfzeileOffsetY),
            String(weg.pdfAdresseOffsetX),
            String(weg.pdfAdresseOffsetY),
            weg.pdfFusszeile1Text,
            weg.pdfFusszeile2Text,
            String(weg.pdfFusszeile1OffsetY),
            String(weg.pdfFusszeile2OffsetY),
            vorschauArt.rawValue
        ].joined(separator: "|")
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Layout-Optionen ───────────────────────────────────────
            Form {
                Section("Vorschautyp") {
                    Picker("Typ", selection: $vorschauArt) {
                        ForEach(VorschauArt.allCases, id: \.self) { art in
                            Text(art.titel).tag(art)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Schrift & Rand
                Section("Schrift & Rand") {
                    Picker("Schriftgröße",
                           selection: Binding(
                            get: { PDFSchriftGroesse(rawValue: weg.pdfSchriftGroesseRaw) ?? .mittel },
                            set: { weg.pdfSchriftGroesseRaw = $0.rawValue }
                           )
                    ) {
                        ForEach(PDFSchriftGroesse.allCases, id: \.self) { Text($0.anzeigeName).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Seitenrand",
                           selection: Binding(
                            get: { PDFRandBreite(rawValue: weg.pdfRandBreiteRaw) ?? .normal },
                            set: { weg.pdfRandBreiteRaw = $0.rawValue }
                           )
                    ) {
                        ForEach(PDFRandBreite.allCases, id: \.self) { Text($0.anzeigeName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                // Tabelle & Abstand
                Section("Tabellenfarbe & Titel") {
                    Picker("Header-Farbe",
                           selection: Binding(
                            get: { PDFHeaderFarbe(rawValue: weg.pdfHeaderFarbeRaw) ?? .grau },
                            set: { weg.pdfHeaderFarbeRaw = $0.rawValue }
                           )
                    ) {
                        ForEach(PDFHeaderFarbe.allCases, id: \.self) { Text($0.anzeigeName).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Stepper(
                        "Abstand nach Briefkopf: \(Int(weg.pdfTitelAbstandOben)) pt",
                        value: Binding(
                            get: { weg.pdfTitelAbstandOben },
                            set: { weg.pdfTitelAbstandOben = $0 }
                        ),
                        in: 0...60, step: 2
                    )

                    Stepper(
                        "Tabelle verschieben: \(Int(weg.pdfTabellenStartOffsetY)) pt",
                        value: Binding(
                            get: { weg.pdfTabellenStartOffsetY },
                            set: { weg.pdfTabellenStartOffsetY = $0 }
                        ),
                        in: -40...220, step: 2
                    )
                }

                // Logo
                Section("Logo") {
                    Picker("Position",
                           selection: Binding(
                            get: { weg.pdfLogoPositionRaw },
                            set: { weg.pdfLogoPositionRaw = $0 }
                           )
                    ) {
                        Text("Links").tag("links")
                        Text("Mitte").tag("mitte")
                        Text("Rechts").tag("rechts")
                    }
                    .pickerStyle(.segmented)

                    Stepper(
                        "Höhe: \(Int(weg.pdfLogoHoehePt)) pt",
                        value: Binding(
                            get: { weg.pdfLogoHoehePt },
                            set: { weg.pdfLogoHoehePt = $0 }
                        ),
                        in: 16...120, step: 4
                    )

                    Stepper(
                        "Skalierung: \(String(format: "%.2f", weg.pdfLogoSkalierung))x",
                        value: Binding(
                            get: { weg.pdfLogoSkalierung },
                            set: { weg.pdfLogoSkalierung = $0 }
                        ),
                        in: 0.5...2.5, step: 0.05
                    )

                    Stepper(
                        "Logo Y-Offset: \(Int(weg.pdfLogoOffsetY)) pt",
                        value: Binding(
                            get: { weg.pdfLogoOffsetY },
                            set: { weg.pdfLogoOffsetY = $0 }
                        ),
                        in: -120...260, step: 2
                    )
                }

                // Kopfzeile
                Section("Kopfzeile (Firmenname)") {
                    TextField("Firmenzeile", text: $weg.pdfKopfzeileText)
                        .font(.caption)

                    Stepper(
                        "Kopfzeile Y-Offset: \(Int(weg.pdfKopfzeileOffsetY)) pt",
                        value: Binding(
                            get: { weg.pdfKopfzeileOffsetY },
                            set: { weg.pdfKopfzeileOffsetY = $0 }
                        ),
                        in: -120...220, step: 2
                    )
                }

                Section("Empfängeradresse") {
                    Stepper(
                        "Adresse X-Offset: \(Int(weg.pdfAdresseOffsetX)) pt",
                        value: Binding(
                            get: { weg.pdfAdresseOffsetX },
                            set: { weg.pdfAdresseOffsetX = $0 }
                        ),
                        in: -160...200, step: 2
                    )

                    Stepper(
                        "Adresse Y-Offset: \(Int(weg.pdfAdresseOffsetY)) pt",
                        value: Binding(
                            get: { weg.pdfAdresseOffsetY },
                            set: { weg.pdfAdresseOffsetY = $0 }
                        ),
                        in: -180...260, step: 2
                    )
                }

                // Fußzeile
                Section("Fußzeile") {
                    Toggle("Fußzeile anzeigen", isOn: $weg.pdfFusszeileEinblenden)

                    if weg.pdfFusszeileEinblenden {
                        TextField("Zeile 1 (z. B. Bankdaten)", text: $weg.pdfFusszeile1Text)
                            .font(.caption)
                        Stepper(
                            "Zeile 1 Y-Offset: \(Int(weg.pdfFusszeile1OffsetY)) pt",
                            value: Binding(
                                get: { weg.pdfFusszeile1OffsetY },
                                set: { weg.pdfFusszeile1OffsetY = $0 }
                            ),
                            in: -140...140, step: 2
                        )

                        TextField("Zeile 2 (z. B. E-Mail)", text: $weg.pdfFusszeile2Text)
                            .font(.caption)
                        Stepper(
                            "Zeile 2 Y-Offset: \(Int(weg.pdfFusszeile2OffsetY)) pt",
                            value: Binding(
                                get: { weg.pdfFusszeile2OffsetY },
                                set: { weg.pdfFusszeile2OffsetY = $0 }
                            ),
                            in: -140...140, step: 2
                        )
                    }
                }

                Section {
                    Button(action: aktualisiereVorschau) {
                        Label("Vorschau aktualisieren", systemImage: "arrow.clockwise")
                    }
                }
            }
            .frame(maxHeight: 420)

            Divider()

            // ── PDF-Vorschau ──────────────────────────────────────────
            Group {
                if pdfData.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.richtext")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text((vorschauArt != .zahlungen && vorschauWohnung == nil)
                             ? "Keine Wohnung gefunden – bitte zuerst eine Wohnung anlegen."
                             : "Vorschau wird geladen…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    PDFKitView(data: pdfData)
                        .id("preview-\(vorschauArt.rawValue)-\(pdfData.count)")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Vorschau & Layout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showFullscreen = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .disabled(pdfData.isEmpty)

                Button {
                    showPrintSheet = true
                } label: {
                    Label("Drucken", systemImage: "printer")
                }
                .disabled(pdfData.isEmpty)
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            NavigationStack {
                PDFKitView(data: pdfData)
                    .id("fullscreen-\(vorschauArt.rawValue)-\(pdfData.count)")
                    .ignoresSafeArea()
                    .navigationTitle(vorschauArt.titel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Schließen") { showFullscreen = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showPrintSheet) {
            PDFPrintController(
                pdfData: pdfData,
                jobName: {
                    switch vorschauArt {
                    case .einzelabrechnung:
                        return "Abrechnung_\(weg.abrechnungsjahr)"
                    case .heizwasserWohnung:
                        return "Heiz_Wasser_Wohnung_\(weg.abrechnungsjahr)"
                    case .zahlungen:
                        return "Zahlungen_\(weg.abrechnungsjahr)"
                    }
                }(),
                onFinish: { showPrintSheet = false }
            )
        }
        .onAppear {
            initialisiereLayoutPresets()
            aktualisiereVorschau()
        }
        .onChange(of: vorschauArt) {
            wechsleAufLayoutFuerAktuelleArt()
            aktualisiereVorschau()
        }
        .onChange(of: previewRefreshToken) {
            persistCurrentArtLayout()
            aktualisiereVorschau()
        }
    }

    private func aktualisiereVorschau() {
        let requestedArt = vorschauArt
        let requestedLayout = currentLayout
        previewRequestID += 1
        let zeilen = viewModel.abrechnungsZeilen(fuer: nil)
        let profile = viewModel.eigentuemerProfileImAktuellenJahr()
        pdfData = Data()

        let data: Data
        switch requestedArt {
        case .einzelabrechnung:
            guard let wohnung = vorschauWohnung else { return }
            data = AbrechnungPDFRenderer.generatePDF(
                wohnung: wohnung,
                weg: weg,
                zeilenKonfiguration: zeilen,
                eigentuemerProfile: profile,
                layout: requestedLayout
            )
        case .heizwasserWohnung:
            guard let wohnung = vorschauWohnung else { return }
            data = HeizWasserWohnungPDFRenderer.generatePDF(
                wohnung: wohnung,
                weg: weg,
                layout: requestedLayout
            )
        case .zahlungen:
            data = ZahlungenPDFRenderer.generateSafePDF(
                weg: weg,
                layout: requestedLayout
            )
        }

        guard requestedArt == vorschauArt else { return }
        pdfData = data
    }
}
