import UIKit

struct HeizWasserAbrechnungPDFRenderer {
    private static let pageWidth: CGFloat = 595.2
    private static let pageHeight: CGFloat = 841.9
    private static let margin: CGFloat = 22
    private static let contentWidth: CGFloat = pageWidth - (margin * 2)
    private static let colWidths: [CGFloat] = [138, 74, 72, 74, 86, 107]

    private struct Cell {
        let text: String
        let align: NSTextAlignment
        let bold: Bool

        init(_ text: String = "", align: NSTextAlignment = .left, bold: Bool = false) {
            self.text = text
            self.align = align
            self.bold = bold
        }
    }

    static func generatePDF(weg: WEG) -> Data {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        UIGraphicsBeginPDFPage()

        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return pdfData as Data
        }

        let gesamtFlaeche = weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm }
        let gesamtHeizPunkte = max(0.0001, weg.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch })
        let warmwasserM3 = max(0.0001, weg.warmwasserMengeM3)
        let kaltwasserM3 = max(0.0001, weg.kaltwasserMengeM3)

        // Vorlage-Logik (1:1):
        // - Brennstoff gesamt = Brennstoffverbrauch * Faktor
        // - Heiz-Brennstoff und WW-Brennstoff werden aus den kWh-Teilverbräuchen berechnet
        // - Kaltwasserkosten lt. Rechnung sind ohne Niederschlagswasser
        // - Im Kaltwasserblock wird erst der WW-Anteil abgezogen
        let brennstoffGesamt = weg.brennstoffverbrauchKwh * weg.faktorProKwhEuro
        let heizBrennstoff = weg.verbrauchHeizungKwh * weg.faktorProKwhEuro
        let warmwasserBrennstoff = weg.verbrauchWarmwasserKwh * weg.faktorProKwhEuro
        let kaltwasserLtRechnung = weg.wasserbetragOhneNiederschlagEuro
        let kaltwasserNachAbzugWW = max(0, kaltwasserLtRechnung - weg.kaltwasserAnteilFuerWarmwasserEuro)
        let niederschlagsTopf = weg.abrechnungsjahr >= 2026 ? max(0, weg.niederschlagswasserEuro) : 0
        let niederschlagsProWohnung = weg.abrechnungsjahr >= 2026 ? (niederschlagsTopf / 6.0) : 0
        let kaltwasserGesamtMitNiederschlag = kaltwasserNachAbzugWW + niederschlagsTopf
        let gesamtKosten = brennstoffGesamt + weg.gesamtwasserbetragLtRechnungEuro

        let heiz30 = weg.heizkostenBrennstoffEuro * 0.3
        let heiz70 = weg.heizkostenBrennstoffEuro * 0.7
        let ww30 = weg.warmwasserkostenGesamtEuro * 0.3
        let ww70 = weg.warmwasserkostenGesamtEuro * 0.7
        let kw100 = kaltwasserGesamtMitNiederschlag

        var y: CGFloat = 20

        y = drawCentered(
            "Heiz-, Warm- und Kaltwasserkosten Abrechnung \(weg.abrechnungsjahr)",
            font: .boldSystemFont(ofSize: 16),
            y: y
        )
        y += 8

        y = drawRow(ctx: ctx, y: y, rowHeight: 22, cells: [
            Cell("Kostenaufstellung des gesamten Objekts", bold: true),
            Cell(), Cell(), Cell(), Cell(), Cell()
        ])

        let startDate = Calendar.current.date(from: DateComponents(year: weg.abrechnungsjahr, month: 1, day: 1)) ?? Date()

        y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
            Cell("Heizungsanlage", bold: true),
            Cell("Wert", bold: true),
            Cell("Einheiten", bold: true),
            Cell("Datum Ablesung", bold: true),
            Cell("", bold: true),
            Cell(deKurzDatum(startDate), align: .right, bold: true)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Brennstoffverbrauch"),
            Cell(formatNum(weg.brennstoffverbrauchKwh), align: .right),
            Cell("kWh"),
            Cell("31.12.\(String(weg.abrechnungsjahr).suffix(2))"),
            Cell(""),
            Cell(formatEuro(brennstoffGesamt), align: .right)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Faktor fur kWh"),
            Cell(String(format: "%.5f", weg.faktorProKwhEuro), align: .right),
            Cell("Euro"),
            Cell(""),
            Cell("Summe:", align: .right, bold: true),
            Cell(formatEuro(brennstoffGesamt), align: .right, bold: true)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Verbrauch Heizung"),
            Cell(formatNum(weg.verbrauchHeizungKwh), align: .right),
            Cell("kWh"),
            Cell(""), Cell(), Cell()
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Verbrauch Wasser"),
            Cell(formatNum(weg.verbrauchWarmwasserKwh), align: .right),
            Cell("kWh"),
            Cell("31.12.\(String(weg.abrechnungsjahr).suffix(2))"),
            Cell(), Cell()
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Gesamtwasserbetrag"),
            Cell(formatEuro(weg.gesamtwasserbetragLtRechnungEuro), align: .right),
            Cell("lt. Rechnung"),
            Cell(), Cell(), Cell()
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Warmwassermenge"),
            Cell(formatNum(weg.warmwasserMengeM3), align: .right),
            Cell("Kubikmeter"),
            Cell(), Cell(), Cell()
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Kaltwassermenge"),
            Cell(formatNum(weg.kaltwasserMengeM3), align: .right),
            Cell("Kubikmeter"),
            Cell(), Cell(), Cell()
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Gesamtwassermenge"),
            Cell(formatNum(weg.gesamtwasserMengeM3), align: .right),
            Cell("Kubikmeter"),
            Cell(), Cell(), Cell()
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Kaltwasserkosten"),
            Cell("lt."),
            Cell("Rechnung"),
            Cell(),
            Cell(),
            Cell(formatEuro(kaltwasserLtRechnung), align: .right, bold: true)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Niederschlagswasser"),
            Cell("lt."),
            Cell("Rechnung"),
            Cell(),
            Cell(),
            Cell(formatEuro(weg.niederschlagswasserEuro), align: .right)
        ])

        y += 8
        y = drawThickLine(ctx: ctx, y: y)

        y = drawRow(ctx: ctx, y: y, rowHeight: 22, cells: [
            Cell("Gesamt", bold: true),
            Cell(""),
            Cell(""),
            Cell(deKurzDatum(startDate), align: .right),
            Cell(""),
            Cell(formatEuro(gesamtKosten), align: .right, bold: true)
        ])

        y += 8
        y = drawThickLine(ctx: ctx, y: y)

        y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
            Cell("Trennung der Gesamtkosten Heizungsanlage", bold: true),
            Cell(), Cell(), Cell(), Cell(), Cell()
        ])

        y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
            Cell("Heizkosten", bold: true),
            Cell("Betrag", bold: true),
            Cell("Anteil", bold: true),
            Cell(""),
            Cell(""),
            Cell("Summe", align: .right, bold: true)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Brennstoff"),
            Cell(String(format: "%.5f €", weg.faktorProKwhEuro), align: .right),
            Cell(formatNum(weg.verbrauchHeizungKwh), align: .right),
            Cell("kWh"),
            Cell(""),
            Cell(formatEuro(heizBrennstoff), align: .right)
        ])

        y = drawThickLine(ctx: ctx, y: y)
        y = drawRow(ctx: ctx, y: y, cells: [Cell("Summe", bold: true), Cell(), Cell(), Cell(), Cell(), Cell(formatEuro(heizBrennstoff), align: .right, bold: true)])

        y += 8
        y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
            Cell("Warmwasserkosten", bold: true),
            Cell("Betrag", bold: true),
            Cell("Anteil", bold: true),
            Cell(""),
            Cell(""),
            Cell("", align: .right)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Brennstoff"),
            Cell(String(format: "%.5f €", weg.faktorProKwhEuro), align: .right),
            Cell(formatNum(weg.verbrauchWarmwasserKwh), align: .right),
            Cell("kWh"),
            Cell(""),
            Cell(formatEuro(warmwasserBrennstoff), align: .right)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Kaltwasser fur Warmwasser"),
            Cell(formatEuro(weg.kaltwasserAnteilFuerWarmwasserEuro), align: .right),
            Cell("100,00%", align: .right),
            Cell(""),
            Cell(""),
            Cell(formatEuro(weg.kaltwasserAnteilFuerWarmwasserEuro), align: .right)
        ])

        y = drawThickLine(ctx: ctx, y: y)
        y = drawRow(ctx: ctx, y: y, cells: [Cell("Summe", bold: true), Cell(), Cell(), Cell(), Cell(), Cell(formatEuro(weg.warmwasserkostenGesamtEuro), align: .right, bold: true)])
        y = drawRow(ctx: ctx, y: y, cells: [Cell("Gesamtsumme Heizungskosten", bold: true), Cell(), Cell(), Cell(), Cell(), Cell(formatEuro(weg.heizkostenGesamtEuro), align: .right, bold: true)])

        y += 8
        y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
            Cell("Kaltwasserkosten", bold: true),
            Cell("Betrag", bold: true),
            Cell("Anteil WW", bold: true),
            Cell(""),
            Cell(""),
            Cell("", align: .right)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("Kaltwasser"),
            Cell(formatEuro(kaltwasserLtRechnung), align: .right),
            Cell(formatEuro(weg.kaltwasserAnteilFuerWarmwasserEuro), align: .right),
            Cell(""), Cell(""),
            Cell(formatEuro(kaltwasserNachAbzugWW), align: .right)
        ])

        if weg.abrechnungsjahr >= 2026 {
            y = drawRow(ctx: ctx, y: y, cells: [
                Cell("Niederschlagswasser (6 WE)"),
                Cell(formatEuro(niederschlagsTopf), align: .right),
                Cell(formatNum(6), align: .right),
                Cell("WE"),
                Cell(formatEuro(niederschlagsProWohnung), align: .right),
                Cell(formatEuro(niederschlagsTopf), align: .right)
            ])
        } else {
            y = drawRow(ctx: ctx, y: y, cells: [
                Cell("Niederschlagswasser"),
                Cell(formatEuro(weg.niederschlagswasserEuro), align: .right),
                Cell(""), Cell(""), Cell(""),
                Cell(formatEuro(weg.niederschlagswasserEuro), align: .right)
            ])
        }

        y = drawThickLine(ctx: ctx, y: y)
        y = drawRow(ctx: ctx, y: y, cells: [Cell("Gesamt", bold: true), Cell(), Cell(), Cell(), Cell(), Cell(formatEuro(kw100), align: .right, bold: true)])

        y += 10
        y = drawThickLine(ctx: ctx, y: y)

        y = drawRow(ctx: ctx, y: y, rowHeight: 22, cells: [
            Cell("Verteilung der Kosten", bold: true),
            Cell("", bold: true),
            Cell("Euro", bold: true),
            Cell("Werte", bold: true),
            Cell("", bold: true),
            Cell("", bold: true)
        ])

        y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
            Cell("Heizkosten", bold: true),
            Cell(""),
            Cell(formatEuro(heizBrennstoff), align: .right, bold: true),
            Cell(""),
            Cell(""),
            Cell("Preis je Einheit", align: .right, bold: true)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("30% Grundkosten"),
            Cell(""),
            Cell(formatEuro(heiz30), align: .right),
            Cell(formatNum(gesamtFlaeche), align: .right),
            Cell("qm"),
            Cell(formatEuro(heiz30 / max(0.0001, gesamtFlaeche)), align: .right)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("70% Verbrauchskosten"),
            Cell(""),
            Cell(formatEuro(heiz70), align: .right),
            Cell(formatNum(gesamtHeizPunkte), align: .right),
            Cell("Punkte"),
            Cell(formatEuro(heiz70 / gesamtHeizPunkte), align: .right)
        ])

        y += 6
        y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
            Cell("Warmwasserkosten", bold: true),
            Cell(""),
            Cell(formatEuro(weg.warmwasserkostenGesamtEuro), align: .right, bold: true),
            Cell(""),
            Cell(""),
            Cell("", align: .right)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("30% Grundkosten"),
            Cell(""),
            Cell(formatEuro(ww30), align: .right),
            Cell(formatNum(gesamtFlaeche), align: .right),
            Cell("qm"),
            Cell(formatEuro(ww30 / max(0.0001, gesamtFlaeche)), align: .right)
        ])

        y = drawRow(ctx: ctx, y: y, cells: [
            Cell("70% Verbrauchskosten"),
            Cell(""),
            Cell(formatEuro(ww70), align: .right),
            Cell(formatNum(warmwasserM3), align: .right),
            Cell("Kubikmeter"),
            Cell(formatEuro(ww70 / warmwasserM3), align: .right)
        ])

        y += 6
        y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
            Cell("Kaltwasserkosten", bold: true),
            Cell(""),
            Cell(formatEuro(kaltwasserNachAbzugWW), align: .right, bold: true),
            Cell(formatNum(kaltwasserM3), align: .right),
            Cell("Kubikmeter"),
            Cell(formatEuro(kaltwasserNachAbzugWW / kaltwasserM3), align: .right)
        ])

        if weg.abrechnungsjahr >= 2026 {
            y = drawRow(ctx: ctx, y: y, rowHeight: 20, cells: [
                Cell("Niederschlagswasser", bold: true),
                Cell(""),
                Cell(formatEuro(niederschlagsTopf), align: .right, bold: true),
                Cell(formatNum(6), align: .right),
                Cell("WE"),
                Cell(formatEuro(niederschlagsProWohnung), align: .right)
            ])
        }

        y += 8
        let kontrollEinheiten = weg.gesamtwasserMengeM3
        y = drawThickLine(ctx: ctx, y: y)
        _ = drawRow(ctx: ctx, y: y, rowHeight: 22, cells: [
            Cell("Kontrollsumme", bold: true),
            Cell(""),
            Cell(formatEuro(gesamtKosten), align: .right, bold: true),
            Cell(formatNum(kontrollEinheiten), align: .right, bold: true),
            Cell("Kubikmeter", bold: true),
            Cell(formatEuro(gesamtKosten), align: .right, bold: true)
        ])

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    @discardableResult
    private static func drawCentered(_ text: String, font: UIFont, y: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attrs)
        let x = (pageWidth - size.width) / 2
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        return y + size.height + 2
    }

    @discardableResult
    private static func drawRow(ctx: CGContext, y: CGFloat, rowHeight: CGFloat = 18, cells: [Cell]) -> CGFloat {
        var x = margin
        let fixedCells = cells.count < 6 ? cells + Array(repeating: Cell(), count: 6 - cells.count) : Array(cells.prefix(6))

        for i in 0..<6 {
            let w = colWidths[i]
            let rect = CGRect(x: x, y: y, width: w, height: rowHeight)

            ctx.setStrokeColor(UIColor(white: 0.65, alpha: 1).cgColor)
            ctx.setLineWidth(0.5)
            ctx.stroke(rect)

            let style = NSMutableParagraphStyle()
            style.alignment = fixedCells[i].align
            let attrs: [NSAttributedString.Key: Any] = [
                .font: fixedCells[i].bold ? UIFont.boldSystemFont(ofSize: 12) : UIFont.systemFont(ofSize: 11),
                .paragraphStyle: style
            ]

            (fixedCells[i].text as NSString).draw(
                in: CGRect(x: x + 3, y: y + 2, width: w - 6, height: rowHeight - 4),
                withAttributes: attrs
            )
            x += w
        }

        return y + rowHeight
    }

    @discardableResult
    private static func drawThickLine(ctx: CGContext, y: CGFloat) -> CGFloat {
        ctx.setStrokeColor(UIColor.darkGray.cgColor)
        ctx.setLineWidth(1.0)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        ctx.strokePath()
        return y + 1
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

    private static func formatNum(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.00001 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
    }
}
