import UIKit
import PDFKit

struct ZahlungenPDFRenderer {
    static let pageWidth: CGFloat = 595.2
    static let pageHeight: CGFloat = 841.9

    private static var activeLayout: PDFLayoutKonfiguration = .init()
    private static var marginLeft: CGFloat { activeLayout.seitenRand }
    private static var marginRight: CGFloat { activeLayout.seitenRand }
    private static var contentWidth: CGFloat { pageWidth - marginLeft - marginRight }

    private static func f(_ base: CGFloat) -> UIFont { .systemFont(ofSize: base * activeLayout.schriftFaktor) }
    private static func bf(_ base: CGFloat) -> UIFont { .boldSystemFont(ofSize: base * activeLayout.schriftFaktor) }

    private static let monate = ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]
    private static let standardAusgabenKategorien = [
        "Strom VaFa",
        "fairenergie Gas",
        "Schornstein",
        "Konto",
        "Müll",
        "Wasser",
        "Haus und Grund",
        "Baur",
        "Auslagen HM",
        "HMT",
        "WEG Rücklagen"
    ]

    static func generatePDF(weg: WEG, layout: PDFLayoutKonfiguration? = nil) -> Data {
        activeLayout = layout ?? PDFLayoutKonfiguration.from(weg: weg)
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        defer { UIGraphicsEndPDFContext() }

        UIGraphicsBeginPDFPage()
        guard let ctx = UIGraphicsGetCurrentContext() else { return pdfData as Data }

        var y: CGFloat = 36
        y = drawHeader(ctx: ctx, weg: weg, y: y)
        y += CGFloat(activeLayout.titelAbstandOben)
        y = drawCenteredText("Zahlungen \(weg.abrechnungsjahr)", font: bf(14), y: y)
        y += 8
        y = drawText("Ein- und Ausgabenübersicht für \(weg.name)", font: f(8), x: marginLeft, y: y, width: contentWidth, align: .left)
        y += 6
        y = drawMetaLine(weg: weg, y: y)
        y += 8 + CGFloat(activeLayout.tabellenStartOffsetY)

        y = ensurePageSpace(ctx: ctx, y: y, needed: 96)
        y = drawSummaryCards(weg: weg, y: y)

        y = ensurePageSpace(ctx: ctx, y: y, needed: 190)
        y = drawSectionTitle("Einnahmen je Monat", y: y)
        y = drawSimpleTable(
            ctx: ctx,
            y: y,
            headers: showHmtUndRl(weg) ? ["Monat", "Hausgeld", "HMT", "WEG RL", "Gesamt"] : ["Monat", "Hausgeld", "Gesamt"],
            rows: einnahmenRows(weg),
            emphasizeLastRow: true
        )

        y += 10
        y = ensurePageSpace(ctx: ctx, y: y, needed: 160)
        y = drawSectionTitle("Jahressummen je Eigentümer", y: y)
        y = drawSimpleTable(
            ctx: ctx,
            y: y,
            headers: ["Wohnung", "Eigentümer", "Jahressumme"],
            rows: wohnungsSummenRows(weg)
        )

        y += 10
        y = ensurePageSpace(ctx: ctx, y: y, needed: 260)
        y = drawSectionTitle("Ausgaben je Monat", y: y)
        y = drawSimpleTable(
            ctx: ctx,
            y: y,
            headers: ["Monat", "Ausgaben", "Korrektur", "Gesamt"],
            rows: ausgabenMonatsRows(weg),
            emphasizeLastRow: true
        )

        y += 10
        y = ensurePageSpace(ctx: ctx, y: y, needed: max(180, CGFloat(ausgabenKategorieRows(weg).count) * 18 + 40))
        y = drawSectionTitle("Ausgaben nach Kategorie", y: y)
        y = drawSimpleTable(
            ctx: ctx,
            y: y,
            headers: ["Kategorie", "Summe"],
            rows: ausgabenKategorieRows(weg)
        )

        let auslagen = weg.auslagenEintraege.sorted {
            if $0.monat == $1.monat { return $0.datum < $1.datum }
            return $0.monat < $1.monat
        }
        if !auslagen.isEmpty {
            y += 10
            y = ensurePageSpace(ctx: ctx, y: y, needed: max(180, CGFloat(auslagen.count) * 18 + 60))
            y = drawSectionTitle("Auslagenliste", y: y)
            y = drawSimpleTable(
                ctx: ctx,
                y: y,
                headers: ["Monat", "Datum", "Zweck", "Kaufort", "Betrag"],
                rows: auslagenRows(weg)
            )
        }

        y += 10
        y = ensurePageSpace(ctx: ctx, y: y, needed: 120)
        y = drawSectionTitle("Jahresbilanz", y: y)
        y = drawSimpleTable(
            ctx: ctx,
            y: y,
            headers: ["Position", "Betrag"],
            rows: jahresbilanzRows(weg),
            emphasizeLastRow: true
        )

        drawFooter(ctx: ctx)
        return pdfData as Data
    }

    static func generateSafePDF(weg: WEG, layout: PDFLayoutKonfiguration? = nil) -> Data {
        activeLayout = layout ?? PDFLayoutKonfiguration.from(weg: weg)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        return renderer.pdfData { ctx in
            let wohnungen = weg.wohnungenSortiert
            let showHmtUndRl = weg.abrechnungsjahr < 2026
            let ausgabenKats = ausgabenKategorien(weg).filter { $0 != "HMT" && $0 != "WEG Rücklagen" }
            let pageBottomY: CGFloat = pageHeight - (activeLayout.fusszeileEinblenden ? 62 : 28)

            func einnahmenMonat(_ monat: Int, wohnung: Wohnung) -> Double {
                wohnung.zahlungen.filter { $0.monat == monat }.reduce(0) { $0 + $1.betrag }
            }

            func einnahmenSummeMonat(_ monat: Int) -> Double {
                wohnungen.reduce(0) { $0 + einnahmenMonat(monat, wohnung: $1) }
            }

            func einnahmenJahrWohnung(_ wohnung: Wohnung) -> Double {
                wohnung.zahlungen.filter { $0.monat >= 1 && $0.monat <= 12 }.reduce(0) { $0 + $1.betrag }
            }

            func hmt(_ monat: Int) -> Double {
                if let wert = weg.ausgaben.first(where: { $0.kategorie == "HMT" && $0.monat == monat })?.betrag { return wert }
                return weg.verguetungHmtEuro / 12
            }

            func rl(_ monat: Int) -> Double {
                if let wert = weg.ausgaben.first(where: { $0.kategorie == "WEG Rücklagen" && $0.monat == monat })?.betrag { return wert }
                return weg.ruecklagenEuro / 12
            }

            let einnahmenGesamt = wohnungen.reduce(0.0) { $0 + einnahmenJahrWohnung($1) }
            let ausgabenGesamt = wohnungen.reduce(0.0) { $0 + ($1.abrechnungsErgebnis?.gesamtgebuehr ?? 0) }
            let differenz = einnahmenGesamt - ausgabenGesamt
            let hmtJahr = (1...12).reduce(0.0) { $0 + hmt($1) }
            let rlJahr = (1...12).reduce(0.0) { $0 + rl($1) }
            let hmtMonat = hmtJahr / 12
            let rlMonat = rlJahr / 12

            // MARK: Seite 1 - Einnahmen
            var einnahmenHeaders = ["Monat"]
            einnahmenHeaders.append(contentsOf: wohnungen.map { shortLabel($0.eigentuemer, max: 9) })
            einnahmenHeaders.append("Gesamt")

            var einnahmenRowsUI: [[String]] = []
            for m in 1...12 {
                var row: [String] = [monate[m - 1]]
                row.append(contentsOf: wohnungen.map { String(format: "%.0f", einnahmenMonat(m, wohnung: $0)) })
                row.append(String(format: "%.0f", einnahmenSummeMonat(m)))
                einnahmenRowsUI.append(row)
            }
            var totalRow: [String] = ["Gesamt"]
            totalRow.append(contentsOf: wohnungen.map { String(format: "%.0f", einnahmenJahrWohnung($0)) })
            totalRow.append(String(format: "%.0f", einnahmenGesamt))
            einnahmenRowsUI.append(totalRow)

            let rowsPage1 = max(1, einnahmenRowsUI.count + (showHmtUndRl ? 2 : 0))
            let availablePage1 = max(320, pageBottomY - 285)
            let fixedPage1: CGFloat = 24 + 16 + (showHmtUndRl ? 24 + 10 : 0)
            let rowH1 = max(12.0, min(18.0, floor((availablePage1 - fixedPage1) / CGFloat(rowsPage1))))
            let headerH1 = max(14.0, min(19.0, rowH1 + 2))
            let bodyFont1 = max(7.4, rowH1 - 3.1)
            let headerFont1 = max(7.8, bodyFont1)

            // Seite 1
            ctx.beginPage()
            var y: CGFloat = 36
            if let cg = UIGraphicsGetCurrentContext() {
                y = drawHeader(ctx: cg, weg: weg, y: y)
                y += CGFloat(activeLayout.titelAbstandOben)
                y = drawCenteredText("Zahlungen \(weg.abrechnungsjahr)", font: bf(14), y: y)
                y += 8
                y = drawText("Seite 1/3: Einnahmen", font: f(8), x: marginLeft, y: y, width: contentWidth, align: .left)
                y += 6
                y = drawMetaLine(weg: weg, y: y)
                y += 10

                y = drawSummaryCards(weg: weg, y: y)
                y = drawSectionTitle("Einnahmen", y: y + 8)
                y = drawSimpleTable(
                    ctx: cg,
                    y: y,
                    headers: einnahmenHeaders,
                    rows: einnahmenRowsUI,
                    headerHeight: headerH1,
                    rowHeight: rowH1,
                    headerFontSize: headerFont1,
                    bodyFontSize: bodyFont1,
                    emphasizeLastRow: true
                )

                if showHmtUndRl {
                    y = drawSectionTitle("HMT / WEG RL", y: y + 8)
                    _ = drawSimpleTable(
                        ctx: cg,
                        y: y,
                        headers: ["Position", "Monat", "Jahr"],
                        rows: [
                            ["HMT", String(format: "12 x %.2f €", hmtMonat), String(format: "%.2f €", hmtJahr)],
                            ["WEG RL", String(format: "12 x %.2f €", rlMonat), String(format: "%.2f €", rlJahr)]
                        ],
                        headerHeight: headerH1,
                        rowHeight: rowH1,
                        headerFontSize: headerFont1,
                        bodyFontSize: bodyFont1,
                        emphasizeLastRow: false
                    )
                }

                drawFooter(ctx: cg)
            }

            // MARK: Seite 2 - Ausgaben in zwei Tabellen
            let splitIndex = max(1, Int(ceil(Double(ausgabenKats.count) / 2.0)))
            let katTeil1 = Array(ausgabenKats.prefix(splitIndex))
            let katTeil2 = Array(ausgabenKats.dropFirst(splitIndex))

            func headerName(_ key: String) -> String {
                switch key {
                case "Strom VaFa": return "Strom"
                case "fairenergie Gas": return "Gas"
                case "Schornstein": return "Schorn."
                case "Haus und Grund": return "H&G"
                case "Auslagen HM": return "Auslagen"
                default: return shortLabel(key, max: 10)
                }
            }

            func ausgabenRowsFuer(_ teile: [String]) -> ([[String]], [String]) {
                var headers = ["Monat"]
                headers.append(contentsOf: teile.map(headerName))
                headers.append("Summe")

                var rows: [[String]] = []
                for m in 1...12 {
                    var row: [String] = [monate[m - 1]]
                    let values = teile.map { ausgabenWert(weg, monat: m, key: $0) }
                    row.append(contentsOf: values.map { String(format: "%.2f", $0) })
                    row.append(String(format: "%.2f", values.reduce(0, +)))
                    rows.append(row)
                }
                let korrVals = teile.map { ausgabenWert(weg, monat: 13, key: $0) }
                rows.append(["Korr."] + korrVals.map { String(format: "%.2f", $0) } + [String(format: "%.2f", korrVals.reduce(0, +))])

                let sumVals = teile.map { key in
                    (1...12).reduce(0.0) { $0 + ausgabenWert(weg, monat: $1, key: key) } + ausgabenWert(weg, monat: 13, key: key)
                }
                rows.append(["Summe"] + sumVals.map { String(format: "%.2f", $0) } + [String(format: "%.2f", sumVals.reduce(0, +))])
                return (rows, headers)
            }

            let (ausgRows1, ausgHeaders1) = ausgabenRowsFuer(katTeil1)
            let (ausgRows2, ausgHeaders2) = ausgabenRowsFuer(katTeil2.isEmpty ? katTeil1 : katTeil2)

            let rowsPage2 = max(1, ausgRows1.count + ausgRows2.count)
            let availablePage2 = max(320, pageBottomY - 255)
            let fixedPage2: CGFloat = 24 + 14 + 24 + 16
            let rowH2 = max(10.5, min(15.0, floor((availablePage2 - fixedPage2) / CGFloat(rowsPage2))))
            let headerH2 = max(13.0, min(17.0, rowH2 + 2))
            let bodyFont2 = max(6.5, rowH2 - 2.5)
            let headerFont2 = max(6.8, bodyFont2)

            ctx.beginPage()
            y = 36
            if let cg = UIGraphicsGetCurrentContext() {
                y = drawHeader(ctx: cg, weg: weg, y: y)
                y += CGFloat(activeLayout.titelAbstandOben)
                y = drawCenteredText("Zahlungen \(weg.abrechnungsjahr) - Seite 2", font: bf(12.8), y: y)
                y += 8
                y = drawText("Seite 2/3: Ausgaben in zwei Tabellen", font: f(8), x: marginLeft, y: y, width: contentWidth, align: .left)
                y += 6
                y = drawMetaLine(weg: weg, y: y)
                y += 10

                y = drawSectionTitle("Ausgaben - Teil 1", y: y)
                y = drawSimpleTable(
                    ctx: cg,
                    y: y,
                    headers: ausgHeaders1,
                    rows: ausgRows1,
                    headerHeight: headerH2,
                    rowHeight: rowH2,
                    headerFontSize: headerFont2,
                    bodyFontSize: bodyFont2,
                    emphasizeLastRow: true
                )

                y = drawSectionTitle("Ausgaben - Teil 2", y: y + 10)
                _ = drawSimpleTable(
                    ctx: cg,
                    y: y,
                    headers: ausgHeaders2,
                    rows: ausgRows2,
                    headerHeight: headerH2,
                    rowHeight: rowH2,
                    headerFontSize: headerFont2,
                    bodyFontSize: bodyFont2,
                    emphasizeLastRow: true
                )

                drawFooter(ctx: cg)
            }

            // MARK: Seite 3 - Übersicht, Versicherungen, Bilanz
            var wohnRows: [[String]] = wohnungen.map { w in
                let ein = einnahmenJahrWohnung(w)
                let aus = w.abrechnungsErgebnis?.gesamtgebuehr ?? 0
                return ["\(shortLabel(w.eigentuemer, max: 20)) (W\(w.wohnungsnummer))", String(format: "%.2f", ein), String(format: "%.2f", aus), String(format: "%.2f", ein - aus)]
            }
            wohnRows.append(["Gesamt", String(format: "%.2f", einnahmenGesamt), String(format: "%.2f", ausgabenGesamt), String(format: "%.2f", differenz)])

            let rowsPage3 = max(1, wohnRows.count + 3 + 5)
            let availablePage3 = max(280, pageBottomY - 250)
            let fixedPage3: CGFloat = 24 + 10 + 24 + 10 + 24 + 24
            let rowH3 = max(11.0, min(17.0, floor((availablePage3 - fixedPage3) / CGFloat(rowsPage3))))
            let headerH3 = max(13.0, min(18.0, rowH3 + 2))
            let bodyFont3 = max(7.0, rowH3 - 2.5)
            let headerFont3 = max(7.2, bodyFont3)

            // Seite 3
            ctx.beginPage()
            y = 36
            if let cg = UIGraphicsGetCurrentContext() {
                y = drawHeader(ctx: cg, weg: weg, y: y)
                y += CGFloat(activeLayout.titelAbstandOben)
                y = drawCenteredText("Zahlungen \(weg.abrechnungsjahr) - Seite 3", font: bf(12.5), y: y)
                y += 8
                y = drawText("Seite 3/3: Übersicht je Eigentümer, Versicherungen, Jahresbilanz", font: f(8), x: marginLeft, y: y, width: contentWidth, align: .left)
                y += 6
                y = drawMetaLine(weg: weg, y: y)
                y += 10

                y = drawSectionTitle("Übersicht je Eigentümer", y: y)
                y = drawSimpleTable(
                    ctx: cg,
                    y: y,
                    headers: ["Eigentümer", "Einnahmen", "Ausgaben", "Differenz"],
                    rows: wohnRows,
                    headerHeight: headerH3,
                    rowHeight: rowH3,
                    headerFontSize: headerFont3,
                    bodyFontSize: bodyFont3,
                    emphasizeLastRow: true
                )

                y = drawSectionTitle("Versicherungen", y: y + 10)
                y = drawSimpleTable(
                    ctx: cg,
                    y: y,
                    headers: ["Position", "Betrag"],
                    rows: [
                        ["Haftpflicht", String(format: "%.2f", weg.versicherungHausHaftpflichtEuro)],
                        ["Gebäude m. Feuer", String(format: "%.2f", weg.versicherungGebaeudeMitFeuerEuro)],
                        ["Summe", String(format: "%.2f", weg.versicherungenGesamtEuro)]
                    ],
                    headerHeight: headerH3,
                    rowHeight: rowH3,
                    headerFontSize: headerFont3,
                    bodyFontSize: bodyFont3,
                    emphasizeLastRow: true
                )

                y = drawSectionTitle("Jahresbilanz", y: y + 10)
                _ = drawSimpleTable(
                    ctx: cg,
                    y: y,
                    headers: ["Position", "Betrag"],
                    rows: [
                        ["Einnahmen", String(format: "%.2f", einnahmenGesamt)],
                        ["Ausgaben", String(format: "%.2f", ausgabenGesamt)],
                        ["Differenz", String(format: "%.2f", differenz)],
                        ["Rückzahlungen", String(format: "%.2f", differenz)],
                        ["Rücklagen", String(format: "%.2f", weg.kontoAktuellEuro)]
                    ],
                    headerHeight: headerH3,
                    rowHeight: rowH3,
                    headerFontSize: headerFont3,
                    bodyFontSize: bodyFont3,
                    emphasizeLastRow: true
                )

                drawFooter(ctx: cg)
            }
        }
    }

    static func generateFallbackPDF(weg: WEG) -> Data {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        defer { UIGraphicsEndPDFContext() }
        UIGraphicsBeginPDFPage()

        let margin: CGFloat = 40
        let width = pageWidth - 2 * margin
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
        let textAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]

        ("Zahlungen \(weg.abrechnungsjahr)" as NSString).draw(in: CGRect(x: margin, y: 60, width: width, height: 24), withAttributes: titleAttrs)
        let einnahmen = weg.wohnungenSortiert.reduce(0.0) { $0 + $1.zahlungen.filter { $0.monat >= 1 && $0.monat <= 12 }.reduce(0) { $0 + $1.betrag } }
        let ausgaben = weg.wohnungenSortiert.reduce(0.0) { $0 + ($1.abrechnungsErgebnis?.gesamtgebuehr ?? 0) }
        let lines = [
            "WEG: \(weg.name)",
            String(format: "Einnahmen gesamt: %.2f €", einnahmen),
            String(format: "Ausgaben gesamt: %.2f €", ausgaben),
            String(format: "Differenz: %.2f €", einnahmen - ausgaben),
            String(format: "Rücklagen: %.2f €", weg.kontoAktuellEuro)
        ]
        for (idx, line) in lines.enumerated() {
            (line as NSString).draw(in: CGRect(x: margin, y: 100 + CGFloat(idx) * 22, width: width, height: 22), withAttributes: textAttrs)
        }

        return pdfData as Data
    }

    private static func showHmtUndRl(_ weg: WEG) -> Bool {
        weg.abrechnungsjahr < 2026
    }

    private static func jahresSummeWohnung(_ wohnung: Wohnung) -> Double {
        wohnung.zahlungen.filter { $0.monat >= 1 && $0.monat <= 12 }.reduce(0) { $0 + $1.betrag }
    }

    private static func hmt(_ weg: WEG, monat: Int) -> Double {
        if let wert = weg.ausgaben.first(where: { $0.kategorie == "HMT" && $0.monat == monat })?.betrag { return wert }
        return weg.verguetungHmtEuro / 12
    }

    private static func rl(_ weg: WEG, monat: Int) -> Double {
        if let wert = weg.ausgaben.first(where: { $0.kategorie == "WEG Rücklagen" && $0.monat == monat })?.betrag { return wert }
        return weg.ruecklagenEuro / 12
    }

    private static func fallbackMonatswert(_ weg: WEG, key: String) -> Double {
        switch key {
        case "Strom VaFa": return weg.allgemeinStromEuro / 12
        case "Gas", "fairenergie Gas": return weg.brennstoffverbrauchKwh > 0 ? (weg.brennstoffverbrauchKwh * weg.faktorProKwhEuro) / 12 : 0
        case "Schornstein": return weg.schornsteinfegerEuro / 12
        case "Müll": return weg.muellGebuehrenEuro / 12
        case "Wasser": return weg.gesamtwasserbetragLtRechnungEuro / 12
        case "H&G", "Haus und Grund": return weg.hausUndGrundEuro / 12
        case "Baur": return weg.wartungBaurEuro / 12
        case "Auslagen HM": return weg.nebenkostenGeldverkehrEuro / 12
        case "HMT": return weg.verguetungHmtEuro / 12
        case "WEG Rücklagen": return weg.ruecklagenEuro / 12
        default: return 0
        }
    }

    private static func ausgabenKategorien(_ weg: WEG) -> [String] {
        var result: [String] = []
        for key in standardAusgabenKategorien where !result.contains(key) { result.append(key) }
        let raw = weg.ausgabenKategorienRaw
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for key in raw where !result.contains(key) { result.append(key) }
        for item in weg.ausgaben {
            let key = item.kategorie.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty && !result.contains(key) { result.append(key) }
        }
        return result
    }

    private static func ausgabenWert(_ weg: WEG, monat: Int, key: String) -> Double {
        if key == "Auslagen HM" && monat >= 1 && monat <= 12 {
            let details = weg.auslagenEintraege.filter { $0.monat == monat }.reduce(0.0) { $0 + $1.betrag }
            let legacy = weg.ausgaben.filter { $0.kategorie == key && $0.monat == monat }.reduce(0.0) { $0 + $1.betrag }
            return details + legacy
        }
        if let wert = weg.ausgaben.first(where: { $0.kategorie == key && $0.monat == monat })?.betrag { return wert }
        if monat == 13 { return 0 }
        return fallbackMonatswert(weg, key: key)
    }

    private static func monatlicheEinnahmen(_ weg: WEG, monat: Int) -> Double {
        weg.wohnungenSortiert.reduce(0) { $0 + $1.zahlungen.filter { $0.monat == monat }.reduce(0) { $0 + $1.betrag } }
    }

    private static func einnahmenRows(_ weg: WEG) -> [[String]] {
        (1...12).map { m in
            let hausgeld = monatlicheEinnahmen(weg, monat: m)
            if showHmtUndRl(weg) {
                let h = hmt(weg, monat: m)
                let r = rl(weg, monat: m)
                return [monate[m - 1], euro(hausgeld), euro(h), euro(r), euro(hausgeld + h + r)]
            }
            return [monate[m - 1], euro(hausgeld), euro(hausgeld)]
        } + [showHmtUndRl(weg)
            ? ["Gesamt", euro((1...12).reduce(0.0) { $0 + monatlicheEinnahmen(weg, monat: $1) }), euro((1...12).reduce(0.0) { $0 + hmt(weg, monat: $1) }), euro((1...12).reduce(0.0) { $0 + rl(weg, monat: $1) }), euro((1...12).reduce(0.0) { $0 + monatlicheEinnahmen(weg, monat: $1) + hmt(weg, monat: $1) + rl(weg, monat: $1) })]
            : ["Gesamt", euro((1...12).reduce(0.0) { $0 + monatlicheEinnahmen(weg, monat: $1) }), euro((1...12).reduce(0.0) { $0 + monatlicheEinnahmen(weg, monat: $1) })]
        ]
    }

    private static func wohnungsSummenRows(_ weg: WEG) -> [[String]] {
        weg.wohnungenSortiert.map { ["W\($0.wohnungsnummer)", $0.eigentuemer, euro(jahresSummeWohnung($0))] }
    }

    private static func ausgabenMonatsRows(_ weg: WEG) -> [[String]] {
        let monateRows = (1...12).map { m in
            let basis = ausgabenKategorien(weg).reduce(0.0) { $0 + ausgabenWert(weg, monat: m, key: $1) }
            let korr = ausgabenKategorien(weg).reduce(0.0) { $0 + ausgabenWert(weg, monat: 13, key: $1) }
            return [monate[m - 1], euro(basis), m == 12 ? euro(korr) : "-", euro(basis + (m == 12 ? korr : 0))]
        }
        let basisGesamt = (1...12).reduce(0.0) { sum, m in
            sum + ausgabenKategorien(weg).reduce(0.0) { $0 + ausgabenWert(weg, monat: m, key: $1) }
        }
        let korrGesamt = ausgabenKategorien(weg).reduce(0.0) { $0 + ausgabenWert(weg, monat: 13, key: $1) }
        return monateRows + [["Gesamt", euro(basisGesamt), euro(korrGesamt), euro(basisGesamt + korrGesamt)]]
    }

    private static func ausgabenKategorieRows(_ weg: WEG) -> [[String]] {
        ausgabenKategorien(weg).map { key in
            let summe = (1...12).reduce(0.0) { $0 + ausgabenWert(weg, monat: $1, key: key) } + ausgabenWert(weg, monat: 13, key: key)
            return [key, euro(summe)]
        }
    }

    private static func auslagenRows(_ weg: WEG) -> [[String]] {
        weg.auslagenEintraege.sorted {
            if $0.monat == $1.monat { return $0.datum < $1.datum }
            return $0.monat < $1.monat
        }.map {
            [monate[max(1, min(12, $0.monat)) - 1], deKurzDatum($0.datum), $0.verwendungszweck, $0.kaufort, euro($0.betrag)]
        }
    }

    private static func jahresbilanzRows(_ weg: WEG) -> [[String]] {
        let einnahmen = weg.wohnungenSortiert.reduce(0.0) { $0 + jahresSummeWohnung($1) }
        let ausgaben = weg.wohnungenSortiert.reduce(0.0) { $0 + ($1.abrechnungsErgebnis?.gesamtgebuehr ?? 0) }
        let differenz = einnahmen - ausgaben
        return [
            ["Einnahmen", euro(einnahmen)],
            ["Ausgaben", euro(ausgaben)],
            ["Differenz", euro(differenz)],
            ["Rückzahlungen", euro(differenz)],
            ["Rücklagen", euro(weg.kontoAktuellEuro)]
        ]
    }

    private static func euro(_ value: Double) -> String {
        String(format: "%.2f €", value)
    }

    private static func einnahmenGesamt(_ weg: WEG) -> Double {
        weg.wohnungenSortiert.reduce(0.0) { $0 + jahresSummeWohnung($1) }
    }

    private static func ausgabenGesamtBilanz(_ weg: WEG) -> Double {
        weg.wohnungenSortiert.reduce(0.0) { $0 + ($1.abrechnungsErgebnis?.gesamtgebuehr ?? 0) }
    }

    @discardableResult
    private static func drawHeader(ctx: CGContext, weg: WEG, y: CGFloat) -> CGFloat {
        var cy = y
        let layout = activeLayout

        if !weg.wegLogoBildData.isEmpty, let logo = UIImage(data: weg.wegLogoBildData) {
            let h = CGFloat(layout.logoHoehePt * layout.logoSkalierung)
            let aspect = logo.size.width / max(logo.size.height, 1)
            let w = h * aspect
            let logoX: CGFloat
            switch layout.logoPosition {
            case "mitte": logoX = marginLeft + (contentWidth - w) / 2
            case "rechts": logoX = marginLeft + contentWidth - w
            default: logoX = marginLeft
            }
            logo.draw(in: CGRect(x: logoX, y: cy + CGFloat(layout.logoOffsetY), width: w, height: h))
        }

        let kopfBottom = drawText(layout.kopfzeileText, font: bf(7.5), x: marginLeft, y: cy + CGFloat(layout.kopfzeileOffsetY), width: contentWidth, align: .center)
        cy = max(cy + 14, kopfBottom)
        let adresseText = "\(weg.name)\n\(weg.adresse)"
        cy = max(cy, drawText(adresseText, font: f(8.5), x: marginLeft + CGFloat(layout.adresseOffsetX), y: cy + 18 + CGFloat(layout.adresseOffsetY), width: contentWidth * 0.52, align: .left))
        return cy + 10
    }

    @discardableResult
    private static func drawFooter(ctx: CGContext) -> CGFloat {
        guard activeLayout.fusszeileEinblenden else { return 0 }
        let baseY = pageHeight - 48
        _ = drawText(activeLayout.fusszeile1Text, font: f(7), x: marginLeft, y: baseY + CGFloat(activeLayout.fusszeile1OffsetY), width: contentWidth, align: .center)
        return drawText(activeLayout.fusszeile2Text, font: f(7), x: marginLeft, y: baseY + 11 + CGFloat(activeLayout.fusszeile2OffsetY), width: contentWidth, align: .center)
    }

    @discardableResult
    private static func drawMetaLine(weg: WEG, y: CGFloat) -> CGFloat {
        let status: String
        if weg.abgeschlossen {
            status = "Status: abgeschlossen"
        } else {
            status = "Status: offen"
        }
        let text = "Abrechnungsjahr: \(weg.abrechnungsjahr)   |   \(status)"
        return drawText(text, font: f(7.2), x: marginLeft, y: y, width: contentWidth, align: .left)
    }

    @discardableResult
    private static func drawSummaryCards(weg: WEG, y: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else { return y }
        let spacing: CGFloat = 10
        let cardWidth = (contentWidth - spacing) / 2
        let cardHeight: CGFloat = 34
        let totalEinnahmen = einnahmenGesamt(weg)
        let totalAusgaben = ausgabenGesamtBilanz(weg)
        let differenz = totalEinnahmen - totalAusgaben
        let cards: [(String, String, UIColor)] = [
            ("Einnahmen", euro(totalEinnahmen), UIColor.systemGreen.withAlphaComponent(0.12)),
            ("Ausgaben", euro(totalAusgaben), UIColor.systemOrange.withAlphaComponent(0.12)),
            ("Differenz", euro(differenz), (differenz >= 0 ? UIColor.systemGreen : UIColor.systemRed).withAlphaComponent(0.12)),
            ("Rücklagen", euro(weg.kontoAktuellEuro), UIColor.systemBlue.withAlphaComponent(0.12))
        ]

        for index in cards.indices {
            let row = index / 2
            let col = index % 2
            let x = marginLeft + CGFloat(col) * (cardWidth + spacing)
            let cardY = y + CGFloat(row) * (cardHeight + 8)
            let rect = CGRect(x: x, y: cardY, width: cardWidth, height: cardHeight)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
            ctx.setFillColor(cards[index].2.cgColor)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            _ = drawText(cards[index].0, font: bf(7.2), x: x + 8, y: cardY + 6, width: cardWidth - 16, align: .left)
            _ = drawText(cards[index].1, font: bf(9), x: x + 8, y: cardY + 17, width: cardWidth - 16, align: .right)
        }
        return y + (cardHeight * 2) + 16
    }

    @discardableResult
    private static func drawCenteredText(_ text: String, font: UIFont, y: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attrs)
        let x = (pageWidth - size.width) / 2
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        return y + size.height + 2
    }

    @discardableResult
    private static func drawText(_ text: String, font: UIFont, x: CGFloat, y: CGFloat, width: CGFloat, align: NSTextAlignment) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: style]
        let rect = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: ceil(rect.height) + 2), withAttributes: attrs)
        return y + ceil(rect.height) + 2
    }

    private static func ensurePageSpace(ctx: CGContext, y: CGFloat, needed: CGFloat) -> CGFloat {
        if y + needed < pageHeight - 70 { return y }
        UIGraphicsBeginPDFPage()
        return 36
    }

    @discardableResult
    private static func drawSectionTitle(_ title: String, y: CGFloat) -> CGFloat {
        guard let ctx = UIGraphicsGetCurrentContext() else { return y }
        let rect = CGRect(x: marginLeft, y: y, width: contentWidth, height: 18)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        ctx.setFillColor(activeLayout.headerFarbe.uiColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        _ = drawText(title, font: bf(8.5), x: marginLeft + 8, y: y + 4, width: contentWidth - 16, align: .left)
        return y + 24
    }

    @discardableResult
    private static func drawSimpleTable(
        ctx: CGContext,
        y: CGFloat,
        headers: [String],
        rows: [[String]],
        headerHeight: CGFloat = 18,
        rowHeight: CGFloat = 18,
        headerFontSize: CGFloat = 7.5,
        bodyFontSize: CGFloat = 7.3,
        emphasizeLastRow: Bool = false
    ) -> CGFloat {
        let colWidth = contentWidth / CGFloat(max(headers.count, 1))
        let startY = y
        ctx.setFillColor(activeLayout.headerFarbe.uiColor.cgColor)
        ctx.fill(CGRect(x: marginLeft, y: startY, width: contentWidth, height: headerHeight))

        for (idx, header) in headers.enumerated() {
            let x = marginLeft + CGFloat(idx) * colWidth + 4
            drawSingleLineText(header, font: bf(headerFontSize), x: x, y: startY + 2, width: colWidth - 8, align: idx == 0 ? .left : .right)
        }

        var currentY = startY + headerHeight + 2
        for (rowIndex, row) in rows.enumerated() {
            let isLastRow = emphasizeLastRow && rowIndex == rows.count - 1
            if isLastRow {
                ctx.setFillColor(UIColor.systemGray5.cgColor)
                ctx.fill(CGRect(x: marginLeft, y: currentY - 1, width: contentWidth, height: rowHeight - 1))
            } else if rowIndex % 2 == 0 {
                ctx.setFillColor(UIColor(white: 0.97, alpha: 1).cgColor)
                ctx.fill(CGRect(x: marginLeft, y: currentY - 1, width: contentWidth, height: rowHeight - 1))
            }
            for (idx, cell) in row.enumerated() {
                let x = marginLeft + CGFloat(idx) * colWidth + 4
                drawSingleLineText(cell, font: isLastRow ? bf(bodyFontSize + 0.1) : f(bodyFontSize), x: x, y: currentY + 1, width: colWidth - 8, align: idx == 0 ? .left : .right)
            }
            currentY += rowHeight
        }
        return currentY
    }

    private static func drawSingleLineText(_ text: String, font: UIFont, x: CGFloat, y: CGFloat, width: CGFloat, align: NSTextAlignment) {
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineBreakMode = .byTruncatingTail
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: style]
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: max(12, font.lineHeight + 2)), withAttributes: attrs)
    }

    private static func shortLabel(_ value: String, max: Int) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > max else { return trimmed }
        return String(trimmed.prefix(max)) + "…"
    }
}