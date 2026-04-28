import UIKit

struct HeizWasserWohnungPDFRenderer {
    private static let pageWidth: CGFloat = 595.2
    private static let pageHeight: CGFloat = 841.9
    private static var activeLayout: PDFLayoutKonfiguration = .init()
    private static var fitScale: CGFloat = 1.0

    private static var marginLeft: CGFloat { activeLayout.seitenRand }
    private static var contentWidth: CGFloat { pageWidth - (activeLayout.seitenRand * 2) }

    private static func s(_ value: CGFloat) -> CGFloat { value * fitScale }
    private static func f(_ base: CGFloat) -> UIFont { .systemFont(ofSize: base * activeLayout.schriftFaktor * fitScale) }
    private static func bf(_ base: CGFloat) -> UIFont { .boldSystemFont(ofSize: base * activeLayout.schriftFaktor * fitScale) }

    static func generatePDF(wohnung: Wohnung, weg: WEG, layout: PDFLayoutKonfiguration? = nil) -> Data {
        activeLayout = layout ?? PDFLayoutKonfiguration.from(weg: weg)
        fitScale = 1.0

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        UIGraphicsBeginPDFPage()

        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return pdfData as Data
        }

        var y: CGFloat = 34
        y = drawHeader(ctx: ctx, weg: weg, wohnung: wohnung, y: y)
        y += CGFloat(activeLayout.titelAbstandOben)

        // Alles auf eine Seite komprimieren.
        let estimated = estimateBodyHeight(wohnung: wohnung)
        let available = max(120, pageHeight - 56 - y)
        fitScale = min(1.0, max(0.52, available / estimated))

        y = drawCenteredText("Heizkosten & Wasserkosten Abrechnung \(weg.abrechnungsjahr)", font: bf(14), y: y)
        y = drawCenteredText("Wohnung \(wohnung.wohnungsnummer) - \(wohnung.eigentuemer)", font: bf(10), y: y + s(2))
        y += s(8)

        y = drawVerteilungBlock(wohnung: wohnung, weg: weg, y: y)
        y += s(10)

        y = drawZaehlerListeBlock(
            title: "Heizkostenverteiler",
            headers: ["Nummer", "Bezeichnung", "Heizungstyp", "Faktor", "Ablesewert neu", "Verbrauch"],
            rows: wohnung.heizkostenverteiler.map {
                [
                    $0.nummer,
                    $0.bezeichnung,
                    $0.heizungstyp + ($0.hinweis.isEmpty ? "" : "  \($0.hinweis)"),
                    formatNum($0.faktor, digits: 3),
                    formatNum($0.ablesewertNeu, digits: 0),
                    formatNum($0.verbrauchPunkte, digits: 0)
                ]
            },
            sumText: formatNum(wohnung.heizungVerbrauch, digits: 0),
            y: y
        )
        y += s(8)

        let wwRows = wohnung.wasserzaehler
            .filter { $0.art == .warmwasser }
            .map {
                [
                    $0.nummer,
                    $0.bezeichnung,
                    $0.typ,
                    formatNum($0.faktor, digits: 2),
                    formatNum($0.ablesewertAlt, digits: 3),
                    formatNum($0.ablesewertNeu, digits: 3),
                    formatNum($0.verbrauch, digits: 3)
                ]
            }

        y = drawZaehlerListeBlock(
            title: "Warmwasserzahler",
            headers: ["Nummer", "Bezeichnung", "Typ", "Faktor", "Ablesewert alt", "Ablesewert neu", "Verbrauch"],
            rows: wwRows,
            sumText: formatNum(wohnung.warmwasserVerbrauch, digits: 2),
            y: y
        )
        y += s(6)

        let kwRows = wohnung.wasserzaehler
            .filter { $0.art == .kaltwasser || $0.art == .waschkueche }
            .map {
                [
                    $0.nummer,
                    $0.bezeichnung,
                    $0.typ,
                    formatNum($0.faktor, digits: 2),
                    formatNum($0.ablesewertAlt, digits: 3),
                    formatNum($0.ablesewertNeu, digits: 3),
                    formatNum($0.verbrauch, digits: 3)
                ]
            }

        _ = drawZaehlerListeBlock(
            title: "Kaltwasserzahler",
            headers: ["Nummer", "Bezeichnung", "Typ", "Faktor", "Ablesewert alt", "Ablesewert neu", "Verbrauch"],
            rows: kwRows,
            sumText: formatNum(wohnung.kaltwasserVerbrauch, digits: 2),
            y: y
        )

        drawFooter(ctx: ctx)
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    @discardableResult
    private static func drawVerteilungBlock(wohnung: Wohnung, weg: WEG, y: CGFloat) -> CGFloat {
        let gesamtFlaeche = max(0.0001, weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm })
        let gesamtHeizPunkte = max(0.0001, weg.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch })
        let gesamtWW = max(0.0001, weg.warmwasserMengeM3)
        let gesamtKW = max(0.0001, weg.kaltwasserMengeM3)

        let heiz30Topf = weg.heizkostenBrennstoffEuro * 0.3
        let heiz70Topf = weg.heizkostenBrennstoffEuro * 0.7
        let ww30Topf = weg.warmwasserkostenGesamtEuro * 0.3
        let ww70Topf = weg.warmwasserkostenGesamtEuro * 0.7
        let kwTopfVerbrauch = weg.kaltwasserkostenVerbrauchsanteilEuro
        let niederschlagsTopf = weg.abrechnungsjahr >= 2026 ? max(0, weg.niederschlagswasserEuro) : 0
        let niederschlagsProWohnung = weg.abrechnungsjahr >= 2026 ? (niederschlagsTopf / 6.0) : 0

        let heiz30Wohnung = (wohnung.flaeche_qm / gesamtFlaeche) * heiz30Topf
        let heiz70Wohnung = (wohnung.heizungVerbrauch / gesamtHeizPunkte) * heiz70Topf
        let ww30Wohnung = (wohnung.flaeche_qm / gesamtFlaeche) * ww30Topf
        let ww70Wohnung = (wohnung.warmwasserVerbrauch / gesamtWW) * ww70Topf
        let kwWohnungVerbrauch = (wohnung.kaltwasserVerbrauch / gesamtKW) * kwTopfVerbrauch
        let kwWohnung = kwWohnungVerbrauch + niederschlagsProWohnung

        let gesamtWohnung = heiz30Wohnung + heiz70Wohnung + ww30Wohnung + ww70Wohnung + kwWohnung
        let vorjahr = wohnung.zahlungen.filter { $0.monat >= 1 && $0.monat <= 12 }.reduce(0) { $0 + $1.betrag }
        let differenz = gesamtWohnung - vorjahr

        let baseWidths: [CGFloat] = [170, 68, 80, 90, 120, 70]
        let scale = contentWidth / baseWidths.reduce(0, +)
        let widths = baseWidths.map { $0 * scale }

        let c0 = marginLeft
        let c1 = c0 + widths[0]
        let c2 = c1 + widths[1]
        let c3 = c2 + widths[2]
        let c4 = c3 + widths[3]
        let c5 = c4 + widths[4]
        let cols: [CGFloat] = [c0, c1, c2, c3, c4, c5]

        var cy = y

        cy = drawText("Verteilung der Kosten", font: bf(9), x: cols[0], y: cy, width: widths[0], align: .left)
        cy -= s(1)
        _ = drawText("Betrag", font: bf(9), x: cols[1], y: cy, width: widths[1], align: .right)
        _ = drawText("Einheiten", font: bf(9), x: cols[2], y: cy, width: widths[2], align: .right)
        _ = drawText("Preis je Einheit", font: bf(9), x: cols[3], y: cy, width: widths[3], align: .right)
        _ = drawText("Verteilerschlussel", font: bf(9), x: cols[4], y: cy, width: widths[4], align: .right)
        _ = drawText("Summe", font: bf(9), x: cols[5], y: cy, width: widths[5], align: .right)
        cy += s(15)

        cy = drawText("Heizkosten", font: bf(10), x: cols[0], y: cy, width: widths[0], align: .left)
        _ = drawText(formatEuro(weg.heizkostenBrennstoffEuro), font: bf(10), x: cols[1], y: cy, width: widths[1], align: .right)
        cy += s(13)
        cy = drawVerteilRow(label: "30% Grundkosten", topf: heiz30Topf, einheiten: gesamtFlaeche, preis: heiz30Topf / gesamtFlaeche, verteil: wohnung.flaeche_qm, einheit: "qm", summe: heiz30Wohnung, y: cy, cols: cols)
        cy = drawVerteilRow(label: "70% Verbrauchskosten", topf: heiz70Topf, einheiten: gesamtHeizPunkte, preis: heiz70Topf / gesamtHeizPunkte, verteil: wohnung.heizungVerbrauch, einheit: "Punkte", summe: heiz70Wohnung, y: cy, cols: cols)
        cy += s(5)

        cy = drawText("Warmwasserkosten", font: bf(10), x: cols[0], y: cy, width: widths[0], align: .left)
        _ = drawText(formatEuro(weg.warmwasserkostenGesamtEuro), font: bf(10), x: cols[1], y: cy, width: widths[1], align: .right)
        cy += s(13)
        cy = drawVerteilRow(label: "30% Grundkosten", topf: ww30Topf, einheiten: gesamtFlaeche, preis: ww30Topf / gesamtFlaeche, verteil: wohnung.flaeche_qm, einheit: "qm", summe: ww30Wohnung, y: cy, cols: cols)
        cy = drawVerteilRow(label: "70% Verbrauchskosten", topf: ww70Topf, einheiten: gesamtWW, preis: ww70Topf / gesamtWW, verteil: wohnung.warmwasserVerbrauch, einheit: "Kubikmeter", summe: ww70Wohnung, y: cy, cols: cols)
        cy += s(5)

        cy = drawText("Kaltwasserkosten", font: bf(10), x: cols[0], y: cy, width: widths[0], align: .left)
        _ = drawText(formatEuro(weg.kaltwasserkostenGesamtEuro), font: bf(10), x: cols[1], y: cy, width: widths[1], align: .right)
        cy += s(13)
        cy = drawVerteilRow(label: "100% Verbrauch", topf: kwTopfVerbrauch, einheiten: gesamtKW, preis: kwTopfVerbrauch / gesamtKW, verteil: wohnung.kaltwasserVerbrauch, einheit: "Kubikmeter", summe: kwWohnungVerbrauch, y: cy, cols: cols)
        if weg.abrechnungsjahr >= 2026 {
            cy = drawVerteilRow(label: "Niederschlagswasser", topf: niederschlagsTopf, einheiten: 6, preis: niederschlagsProWohnung, verteil: 1, einheit: "WE", summe: niederschlagsProWohnung, y: cy, cols: cols)
        }
        cy += s(7)

        cy = drawText("Gesamt", font: bf(10), x: cols[0], y: cy, width: widths[0], align: .left)
        _ = drawText(formatEuro(weg.gesamtkostenHeizungWasserEuro), font: bf(10), x: cols[1], y: cy, width: widths[1], align: .right)
        _ = drawText(formatEuro(gesamtWohnung), font: bf(10), x: cols[5], y: cy, width: widths[5], align: .right)
        cy += s(13)

        cy = drawText("Vorjahr", font: bf(10), x: cols[0], y: cy, width: widths[0], align: .left)
        _ = drawText(formatEuro(vorjahr), font: bf(10), x: cols[5], y: cy, width: widths[5], align: .right)
        cy += s(13)

        cy = drawText("Differenz", font: bf(10), x: cols[0], y: cy, width: widths[0], align: .left)
        let diffColor: UIColor = differenz >= 0 ? .systemGreen : .systemRed
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        let attrs: [NSAttributedString.Key: Any] = [.font: bf(10), .foregroundColor: diffColor, .paragraphStyle: style]
        NSAttributedString(string: formatEuro(differenz), attributes: attrs)
            .draw(in: CGRect(x: cols[5], y: cy, width: widths[5], height: s(14)))
        cy += s(16)

        return cy
    }

    @discardableResult
    private static func drawVerteilRow(label: String, topf: Double, einheiten: Double, preis: Double, verteil: Double, einheit: String, summe: Double, y: CGFloat, cols: [CGFloat]) -> CGFloat {
        let widths = [
            cols[1] - cols[0],
            cols[2] - cols[1],
            cols[3] - cols[2],
            cols[4] - cols[3],
            cols[5] - cols[4],
            marginLeft + contentWidth - cols[5]
        ]

        _ = drawText(label, font: f(8.8), x: cols[0], y: y, width: widths[0], align: .left)
        _ = drawText(formatEuro(topf), font: f(8.8), x: cols[1], y: y, width: widths[1], align: .right)
        _ = drawText(formatNum(einheiten, digits: 2), font: f(8.8), x: cols[2], y: y, width: widths[2], align: .right)
        _ = drawText(formatEuro(preis), font: f(8.8), x: cols[3], y: y, width: widths[3], align: .right)
        _ = drawText(formatNum(verteil, digits: 2) + " " + einheit, font: f(8.8), x: cols[4], y: y, width: widths[4], align: .right)
        _ = drawText(formatEuro(summe), font: f(8.8), x: cols[5], y: y, width: widths[5], align: .right)
        return y + s(12)
    }

    @discardableResult
    private static func drawZaehlerListeBlock(title: String, headers: [String], rows: [[String]], sumText: String, y: CGFloat) -> CGFloat {
        var cy = y
        cy = drawText(title, font: bf(9.5), x: marginLeft, y: cy, width: contentWidth, align: .left)

        let count = max(1, headers.count)
        let colWidth = contentWidth / CGFloat(count)

        for (idx, head) in headers.enumerated() {
            _ = drawText(head, font: bf(8.0), x: marginLeft + CGFloat(idx) * colWidth, y: cy, width: colWidth, align: idx == 0 ? .left : .right)
        }
        cy += s(11)

        for row in rows {
            for (idx, value) in row.enumerated() where idx < headers.count {
                _ = drawText(value, font: f(8.0), x: marginLeft + CGFloat(idx) * colWidth, y: cy, width: colWidth, align: idx == 0 ? .left : .right)
            }
            cy += s(10)
        }

        _ = drawText("Summe:", font: bf(8.5), x: marginLeft + contentWidth - s(120), y: cy, width: s(60), align: .right)
        _ = drawText(sumText, font: bf(8.5), x: marginLeft + contentWidth - s(60), y: cy, width: s(60), align: .right)
        return cy + s(14)
    }

    @discardableResult
    private static func drawHeader(ctx: CGContext, weg: WEG, wohnung: Wohnung, y: CGFloat) -> CGFloat {
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

        let kopfY = cy + CGFloat(layout.kopfzeileOffsetY)
        let kopfBottom = drawText(layout.kopfzeileText, font: bf(7.5), x: marginLeft, y: kopfY, width: contentWidth, align: .center)
        cy = max(cy + s(14), kopfBottom)

        let adress = ["Frau / Herrn", wohnung.eigentuemer, "Uhlandstr. 12", "72636 Frickenhausen"]
        let adrX = marginLeft + CGFloat(layout.adresseOffsetX)
        var adrY = cy + CGFloat(layout.adresseOffsetY)
        for line in adress {
            _ = drawText(line, font: f(8), x: adrX, y: adrY, width: 200, align: .left)
            adrY += s(11)
        }

        let dateStr = deKurzDatum(Date())
        _ = drawText(dateStr, font: f(8), x: marginLeft + contentWidth - 80, y: y + s(14), width: 80, align: .right)
        return max(adrY, cy) + s(4)
    }

    private static func drawFooter(ctx: CGContext) {
        guard activeLayout.fusszeileEinblenden else { return }
        let footerY = pageHeight - 36
        if !activeLayout.fusszeile1Text.isEmpty {
            _ = drawText(activeLayout.fusszeile1Text, font: f(7), x: marginLeft, y: footerY + CGFloat(activeLayout.fusszeile1OffsetY), width: contentWidth, align: .left)
        }
        if !activeLayout.fusszeile2Text.isEmpty {
            _ = drawText(activeLayout.fusszeile2Text, font: f(7), x: marginLeft, y: footerY + s(10) + CGFloat(activeLayout.fusszeile2OffsetY), width: contentWidth, align: .left)
        }
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
        style.lineBreakMode = .byTruncatingTail

        let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: style]
        let lineHeight = ceil(font.lineHeight)
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: lineHeight + 2), withAttributes: attrs)
        return y + lineHeight + 2
    }

    private static func estimateBodyHeight(wohnung: Wohnung) -> CGFloat {
        let verteilung: CGFloat = 220
        let hkv = 14 + 11 + (CGFloat(wohnung.heizkostenverteiler.count) * 10) + 14
        let wwCount = wohnung.wasserzaehler.filter { $0.art == .warmwasser }.count
        let ww = 14 + 11 + (CGFloat(wwCount) * 10) + 14
        let kwCount = wohnung.wasserzaehler.filter { $0.art == .kaltwasser || $0.art == .waschkueche }.count
        let kw = 14 + 11 + (CGFloat(kwCount) * 10) + 14
        return verteilung + hkv + 8 + ww + 6 + kw + 16
    }

    private static func formatEuro(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = "."
        return (formatter.string(from: NSNumber(value: value)) ?? "0,00") + " €"
    }

    private static func formatNum(_ value: Double, digits: Int) -> String {
        if digits == 0 {
            return String(Int(value.rounded()))
        }
        return String(format: "%0.*f", digits, value).replacingOccurrences(of: ".", with: ",")
    }
}
