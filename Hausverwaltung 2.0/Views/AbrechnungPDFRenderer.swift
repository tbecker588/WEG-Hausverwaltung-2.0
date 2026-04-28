//
//  AbrechnungPDFRenderer.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 18.04.26.
//

import UIKit
import PDFKit

// MARK: - PDFLayoutKonfiguration

struct PDFLayoutKonfiguration {
    var schriftGroesse: PDFSchriftGroesse = .mittel
    var randBreite: PDFRandBreite         = .normal
    var headerFarbe: PDFHeaderFarbe       = .grau
    var fusszeileEinblenden: Bool         = true

    // Logo
    var logoPosition: String = "links"   // links | mitte | rechts
    var logoHoehePt: Double  = 44
    var logoSkalierung: Double = 1.0
    var logoOffsetY: Double = 0

    // Abstände
    var titelAbstandOben: Double = 14     // Abstand nach dem Briefkopf
    var tabellenStartOffsetY: Double = 0

    // Kopf- und Fußzeile
    var kopfzeileText: String  = "Hausverwaltung Thomas Becker, Uhlandstr. 12, 72636 Frickenhausen"
    var kopfzeileOffsetY: Double = 0
    var adresseOffsetX: Double = 0
    var adresseOffsetY: Double = 0
    var fusszeile1Text: String = "Bankverbindung: KSK Esslingen IBAN DE70 6115 0020 0008 1610 37"
    var fusszeile2Text: String = "weg.uhlandstr.12@gmx.de"
    var fusszeile1OffsetY: Double = 0
    var fusszeile2OffsetY: Double = 0

    var schriftFaktor: CGFloat { schriftGroesse.faktor }
    var seitenRand: CGFloat    { randBreite.punkte }

    static func from(weg: WEG) -> PDFLayoutKonfiguration {
        PDFLayoutKonfiguration(
            schriftGroesse: PDFSchriftGroesse(rawValue: weg.pdfSchriftGroesseRaw) ?? .mittel,
            randBreite:     PDFRandBreite(rawValue: weg.pdfRandBreiteRaw)         ?? .normal,
            headerFarbe:    PDFHeaderFarbe(rawValue: weg.pdfHeaderFarbeRaw)        ?? .grau,
            fusszeileEinblenden: weg.pdfFusszeileEinblenden,
            logoPosition:  weg.pdfLogoPositionRaw,
            logoHoehePt:   weg.pdfLogoHoehePt,
            logoSkalierung: weg.pdfLogoSkalierung,
            logoOffsetY: weg.pdfLogoOffsetY,
            titelAbstandOben: weg.pdfTitelAbstandOben,
            tabellenStartOffsetY: weg.pdfTabellenStartOffsetY,
            kopfzeileText: weg.pdfKopfzeileText.isEmpty
                ? "Hausverwaltung Thomas Becker, Uhlandstr. 12, 72636 Frickenhausen"
                : weg.pdfKopfzeileText,
            kopfzeileOffsetY: weg.pdfKopfzeileOffsetY,
            adresseOffsetX: weg.pdfAdresseOffsetX,
            adresseOffsetY: weg.pdfAdresseOffsetY,
            fusszeile1Text: weg.pdfFusszeile1Text,
            fusszeile2Text: weg.pdfFusszeile2Text,
            fusszeile1OffsetY: weg.pdfFusszeile1OffsetY,
            fusszeile2OffsetY: weg.pdfFusszeile2OffsetY
        )
    }
}

// MARK: - UIColor-Extension für PDFHeaderFarbe

extension PDFHeaderFarbe {
    var uiColor: UIColor {
        switch self {
        case .grau:   return UIColor(white: 0.92, alpha: 1)
        case .blau:   return UIColor(red: 0.82, green: 0.88, blue: 0.96, alpha: 1)
        case .gruen:  return UIColor(red: 0.83, green: 0.93, blue: 0.84, alpha: 1)
        case .dunkel: return UIColor(red: 0.25, green: 0.30, blue: 0.38, alpha: 1)
        }
    }
    var textUIColor: UIColor { self == .dunkel ? .white : .black }
}

// MARK: - PDF-Generierung für Einzelabrechnung je Wohnung

struct AbrechnungPDFRenderer {

    // A4 in Punkt (72 pt/inch)
    static let pageWidth:  CGFloat = 595.2
    static let pageHeight: CGFloat = 841.9
    // Spaltenbreiten (total = contentWidth-Variante bei Normal-Rand ≈ 503)
    static let colWidths: [CGFloat] = [168, 62, 46, 92, 46, 89]

    // Aktives Layout für den aktuellen Render-Vorgang (Main-Thread only)
    private static var activeLayout: PDFLayoutKonfiguration = .init()
    static var marginLeft:   CGFloat { activeLayout.seitenRand }
    static var marginRight:  CGFloat { activeLayout.seitenRand }
    static var contentWidth: CGFloat { pageWidth - marginLeft - marginRight }

    // Schrift-Helfer mit aktiver Skalierung
    private static func f(_ base: CGFloat)   -> UIFont { .systemFont(ofSize: base * activeLayout.schriftFaktor) }
    private static func bf(_ base: CGFloat)  -> UIFont { .boldSystemFont(ofSize: base * activeLayout.schriftFaktor) }
    private static func itf(_ base: CGFloat) -> UIFont { .italicSystemFont(ofSize: base * activeLayout.schriftFaktor) }

    static func generatePDF(
        wohnung: Wohnung,
        weg: WEG,
        zeilenKonfiguration: [AbrechnungsZeileKonfiguration] = [],
        eigentuemerProfile: [EigentuemerProfil] = [],
        layout: PDFLayoutKonfiguration? = nil
    ) -> Data {
        activeLayout = layout ?? PDFLayoutKonfiguration.from(weg: weg)
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        UIGraphicsBeginPDFPage()
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return pdfData as Data
        }

        var y: CGFloat = 36

        // ── Briefkopf ────────────────────────────────────────────────
        y = drawHeader(ctx: ctx, weg: weg, wohnung: wohnung, y: y)
        y += CGFloat(activeLayout.titelAbstandOben)

        // ── Titel ─────────────────────────────────────────────────────
        y = drawCenteredText(weg.abrechnungsTitelAnzeige, font: bf(14), y: y)
        y += 10

        // ── Untertitel ────────────────────────────────────────────────
        let standardUntertitel = "Wohnung Nr.\(wohnung.wohnungsnummer) Uhlandstr.12, Frickenhausen   " +
                                weg.abrechnungsUntertitelAnzeige
        let subtitle = weg.abrechnungsHeaderUntertitel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? standardUntertitel
            : "Wohnung Nr.\(wohnung.wohnungsnummer) Uhlandstr.12, Frickenhausen   " + weg.abrechnungsUntertitelAnzeige
        y = drawText(subtitle, font: f(7.5), x: marginLeft, y: y, width: contentWidth, align: .left)
        y += 8

        if !weg.abrechnungsHeaderPunkte.isEmpty {
            for punkt in weg.abrechnungsHeaderPunkte {
                y = drawText("• \(punkt)", font: f(7), x: marginLeft, y: y, width: contentWidth, align: .left)
            }
            y += 6
        }

        y = drawText("Verteilungsschlüssel: \(weg.standardVerteilungsschluesselSicher.anzeigeName)",
                     font: f(7.5), x: marginLeft, y: y, width: contentWidth, align: .left)
        y += 6
        y += CGFloat(activeLayout.tabellenStartOffsetY)

        // ── Tabellen-Header ───────────────────────────────────────────
        let headers = ["Bezeichnung", "Gesamt in €", "Gesamt\nschlüssel", "Schlüssel-\nbezeichnung", "Umlage\nschlüssel", "Ihr Umlage-\nanteil in €"]
        y = drawTableHeader(ctx: ctx, headers: headers, y: y)

        // ── Zeilen ────────────────────────────────────────────────────
        let rows = buildRows(
            wohnung: wohnung,
            weg: weg,
            zeilenKonfiguration: zeilenKonfiguration,
            eigentuemerProfile: eigentuemerProfilesafe(eigentuemerProfile)
        )
        for row in rows {
            y = drawTableRow(ctx: ctx, row: row, y: y)
        }

        // ── Gesamtbetrag ──────────────────────────────────────────────
        let ausgabenGesamt = rows.reduce(0) { $0 + $1.amount }
        y += 4
        y = drawSummaryRow("Gesamt", value: ausgabenGesamt, bold: true, y: y)
        y += 2
        drawHLine(ctx: ctx, y: y)
        y += 6

        // ── Vorauszahlungen & Differenz ───────────────────────────────
        let vorauszahlungen = wohnung.zahlungen
            .filter { $0.monat >= 1 && $0.monat <= 12 }
            .reduce(0) { $0 + $1.betrag }
        y = drawSummaryRow("Vorausszahlungen \(weg.abrechnungsjahr)", value: vorauszahlungen, bold: false, y: y)
        y += 2
        drawHLine(ctx: ctx, y: y)
        y += 6

        let differenz = vorauszahlungen - ausgabenGesamt
        let diffLabel = differenz >= 0 ? "Ihr Guthaben beträgt:" : "Ihre Nachzahlung beträgt:"
        y = drawDiffRow(label: "Differenzbetrag", subtitle: diffLabel, value: differenz, y: y)
        y += 16

        // ── Fußzeile ──────────────────────────────────────────────────
        drawFooter(ctx: ctx)

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    // MARK: - Briefkopf

    @discardableResult
    private static func drawHeader(ctx: CGContext, weg: WEG, wohnung: Wohnung, y: CGFloat) -> CGFloat {
        var cy = y
        let layout = activeLayout

        // Logo
        if !weg.wegLogoBildData.isEmpty, let logo = UIImage(data: weg.wegLogoBildData) {
            let h = CGFloat(layout.logoHoehePt * layout.logoSkalierung)
            let aspect = logo.size.width / max(logo.size.height, 1)
            let w = h * aspect
            let logoX: CGFloat
            switch layout.logoPosition {
            case "mitte":  logoX = marginLeft + (contentWidth - w) / 2
            case "rechts": logoX = marginLeft + contentWidth - w
            default:       logoX = marginLeft          // links
            }
            logo.draw(in: CGRect(x: logoX, y: cy + CGFloat(layout.logoOffsetY), width: w, height: h))
        }

        // Firmenkopf / Kopfzeile
        let kopfY = cy + CGFloat(layout.kopfzeileOffsetY)
        let kopfBottom = drawText(layout.kopfzeileText, font: bf(7.5), x: marginLeft, y: kopfY, width: contentWidth, align: .center)
        cy = max(cy + 14, kopfBottom)

        // Links: Empfängeradresse
        let adressZeilen = ["Frau / Herrn", wohnung.eigentuemer, "Uhlandstr. 12", "72636 Frickenhausen"]
        let adrX = marginLeft + CGFloat(layout.adresseOffsetX)
        var adrY = cy + CGFloat(layout.adresseOffsetY)
        for zeile in adressZeilen {
            drawText(zeile, font: f(8), x: adrX, y: adrY, width: 200, align: .left)
            adrY += 11
        }
        cy = max(cy, adrY)

        // Rechts: Datum
        let dateStr = deKurzDatum(Date())
        drawText(dateStr, font: f(8),
                 x: marginLeft + contentWidth - 80, y: y + 14, width: 80, align: .right)

        return cy + 4
    }

    // MARK: - Tabellen-Header

    @discardableResult
    private static func drawTableHeader(ctx: CGContext, headers: [String], y: CGFloat) -> CGFloat {
        let rowH: CGFloat = 22
        let hFarbe = activeLayout.headerFarbe
        ctx.setFillColor(hFarbe.uiColor.cgColor)
        ctx.fill(CGRect(x: marginLeft, y: y, width: contentWidth, height: rowH))

        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: bf(6.5),
            .foregroundColor: hFarbe.textUIColor
        ]
        var x = marginLeft
        for (i, header) in headers.enumerated() {
            let w = colWidths[i]
            let style = NSMutableParagraphStyle()
            if i == 0 {
                style.alignment = .left
            } else if i == 2 || i == 3 || i == 4 {
                style.alignment = .center
            } else {
                style.alignment = .right
            }
            var attrs = textAttrs
            attrs[.paragraphStyle] = style
            (header as NSString).draw(in: CGRect(x: x + 3, y: y + 3, width: w - 6, height: rowH - 4),
                                      withAttributes: attrs)
            x += w
        }
        return y + rowH
    }

    // MARK: - Daten-Zeile

    struct RowData {
        let name: String
        let total: Double       // 0 = leer
        let keyTotal: Double    // 0 = leer
        let keyLabel: String
        let keyValue: Double    // 0 = leer
        let amount: Double
        let isSub: Bool         // Einrückung (Unterzeile wie Schornsteinfeger)
        let isBold: Bool
    }

    @discardableResult
    private static func drawTableRow(ctx: CGContext, row: RowData, y: CGFloat) -> CGFloat {
        let rowH: CGFloat = row.isSub ? 10 : 13
        var x = marginLeft

        let nameFont: UIFont = row.isSub ? itf(7) : (row.isBold ? bf(8) : f(8))
        let numFont: UIFont  = row.isSub ? f(7) : f(8)

        // Bezeichnung
        let nameX = row.isSub ? x + 10 : x
        drawText(row.name, font: nameFont, x: nameX + 2, y: y + 2, width: colWidths[0] - 4, align: .left)
        x += colWidths[0]

        // Gesamt in €
        if row.total > 0 {
            drawText(formatEuro(row.total), font: numFont, x: x + 2, y: y + 2, width: colWidths[1] - 4, align: .right)
        }
        x += colWidths[1]

        // Gesamtschlüssel
        if row.keyTotal > 0 {
            drawText(formatNum(row.keyTotal), font: numFont, x: x + 2, y: y + 2, width: colWidths[2] - 4, align: .center)
        }
        x += colWidths[2]

        // Schlüsselbezeichnung
        if !row.keyLabel.isEmpty {
            drawText(row.keyLabel, font: numFont, x: x + 2, y: y + 2, width: colWidths[3] - 4, align: .center)
        }
        x += colWidths[3]

        // Umlageschlüssel
        if row.keyValue > 0 {
            drawText(formatNum(row.keyValue), font: numFont, x: x + 2, y: y + 2, width: colWidths[4] - 4, align: .center)
        }
        x += colWidths[4]

        // Ihr Umlageanteil in €
        if row.amount > 0 || row.isBold {
            let amtFont: UIFont = row.isBold ? bf(8) : numFont
            drawText(formatEuro(row.amount), font: amtFont, x: x + 2, y: y + 2, width: colWidths[5] - 4, align: .right)
        }

        return y + rowH
    }

    // MARK: - Zusammenfassungs-Zeilen

    @discardableResult
    private static func drawSummaryRow(_ label: String, value: Double, bold: Bool, y: CGFloat) -> CGFloat {
        let font: UIFont = bold ? bf(8.5) : f(8)
        drawText(label, font: font, x: marginLeft + 2, y: y + 1, width: contentWidth - colWidths[5] - 4, align: .left)
        drawText(formatEuro(value), font: font,
                 x: marginLeft + contentWidth - colWidths[5] + 2, y: y + 1, width: colWidths[5] - 4, align: .right)
        return y + 14
    }

    @discardableResult
    private static func drawDiffRow(label: String, subtitle: String, value: Double, y: CGFloat) -> CGFloat {
        let farbe: UIColor = value >= 0 ? .systemGreen : .systemRed
        let summaryFont = bf(8.5)

        drawText(label, font: summaryFont,
                 x: marginLeft + 2, y: y + 1,
                 width: contentWidth - colWidths[5] - 4,
                 align: .left)

        let style = NSMutableParagraphStyle()
        style.alignment = .right
        let attrs: [NSAttributedString.Key: Any] = [
            .font: summaryFont,
            .foregroundColor: farbe,
            .paragraphStyle: style
        ]
        let str = NSAttributedString(string: formatEuro(value), attributes: attrs)
        let rect = CGRect(x: marginLeft + contentWidth - colWidths[5] + 2,
                          y: y + 1,
                          width: colWidths[5] - 4,
                          height: 14)
        str.draw(in: rect)

        let nextY = y + 14
        return drawText(subtitle, font: f(7.5), x: marginLeft + 2, y: nextY, width: contentWidth - 4, align: .left)
    }

    // MARK: - Fußzeile

    private static func drawFooter(ctx: CGContext) {
        guard activeLayout.fusszeileEinblenden else { return }
        let footerY = pageHeight - 36
        let z1 = activeLayout.fusszeile1Text
        let z2 = activeLayout.fusszeile2Text
        if !z1.isEmpty {
            drawText(z1, font: f(7), x: marginLeft, y: footerY + CGFloat(activeLayout.fusszeile1OffsetY), width: contentWidth, align: .left)
        }
        if !z2.isEmpty {
            drawText(z2, font: f(7), x: marginLeft, y: footerY + 10 + CGFloat(activeLayout.fusszeile2OffsetY), width: contentWidth, align: .left)
        }
    }

    // MARK: - Zeilen aufbauen

    private static func buildRows(
        wohnung: Wohnung,
        weg: WEG,
        zeilenKonfiguration: [AbrechnungsZeileKonfiguration],
        eigentuemerProfile: [EigentuemerProfil]
    ) -> [RowData] {
        AbrechnungsZeilenEngine.baueAusgabezeilen(
            wohnung: wohnung,
            weg: weg,
            zeilenKonfiguration: zeilenKonfiguration,
            eigentuemerProfile: eigentuemerProfile
        ).map {
            RowData(
                name: $0.name,
                total: $0.total,
                keyTotal: $0.keyTotal,
                keyLabel: $0.keyLabel,
                keyValue: $0.keyValue,
                amount: $0.amount,
                isSub: $0.isSub,
                isBold: $0.isBold
            )
        }
    }

    private static func eigentuemerProfilesafe(_ profiles: [EigentuemerProfil]) -> [EigentuemerProfil] {
        profiles
    }

    // MARK: - Hilfs-Funktionen

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
        let boundingRect = (text as NSString).boundingRect(with: CGSize(width: width, height: 300),
                                                           options: .usesLineFragmentOrigin,
                                                           attributes: attrs, context: nil)
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: boundingRect.height + 2), withAttributes: attrs)
        return y + boundingRect.height + 2
    }

    private static func drawHLine(ctx: CGContext, y: CGFloat) {
        ctx.setStrokeColor(UIColor.darkGray.cgColor)
        ctx.setLineWidth(0.4)
        ctx.move(to: CGPoint(x: marginLeft, y: y))
        ctx.addLine(to: CGPoint(x: marginLeft + contentWidth, y: y))
        ctx.strokePath()
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
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}

// MARK: - SwiftUI Share Sheet

import SwiftUI

struct PDFShareSheet: UIViewControllerRepresentable {
    let pdfData: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? pdfData.write(to: url)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
