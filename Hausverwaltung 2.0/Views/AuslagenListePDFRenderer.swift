import UIKit

struct AuslagenListePDFRenderer {
    static func generatePDF(weg: WEG, eintraege: [AuslagenEintrag]) -> Data {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 36
        let contentWidth = pageWidth - 2 * margin
        let rowHeight: CGFloat = 18

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        defer { UIGraphicsEndPDFContext() }

        func drawText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, font: UIFont, align: NSTextAlignment = .left) {
            let style = NSMutableParagraphStyle()
            style.alignment = align
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: style
            ]
            (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: rowHeight), withAttributes: attrs)
        }

        func newPage(_ y: inout CGFloat) {
            UIGraphicsBeginPDFPage()
            y = margin
        }

        let eintraegeSortiert = eintraege.sorted {
            if $0.monat == $1.monat { return $0.datum < $1.datum }
            return $0.monat < $1.monat
        }

        var y: CGFloat = 0
        newPage(&y)

        drawText("Auslagenliste \(weg.abrechnungsjahr)", x: margin, y: y, width: contentWidth, font: .boldSystemFont(ofSize: 16))
        y += 24

        let cols: [CGFloat] = [70, 70, 210, 140, 90]
        let colX: [CGFloat] = [
            margin,
            margin + cols[0],
            margin + cols[0] + cols[1],
            margin + cols[0] + cols[1] + cols[2],
            margin + cols[0] + cols[1] + cols[2] + cols[3]
        ]

        drawText("Monat", x: colX[0], y: y, width: cols[0], font: .boldSystemFont(ofSize: 11))
        drawText("Datum", x: colX[1], y: y, width: cols[1], font: .boldSystemFont(ofSize: 11))
        drawText("Zweck", x: colX[2], y: y, width: cols[2], font: .boldSystemFont(ofSize: 11))
        drawText("Kaufort", x: colX[3], y: y, width: cols[3], font: .boldSystemFont(ofSize: 11))
        drawText("Betrag", x: colX[4], y: y, width: cols[4], font: .boldSystemFont(ofSize: 11), align: .right)
        y += rowHeight

        let mn = ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]
        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "de_DE")
        dateFmt.dateFormat = "dd.MM.yyyy"

        for e in eintraegeSortiert {
            if y > pageHeight - margin - 40 {
                newPage(&y)
                drawText("Monat", x: colX[0], y: y, width: cols[0], font: .boldSystemFont(ofSize: 11))
                drawText("Datum", x: colX[1], y: y, width: cols[1], font: .boldSystemFont(ofSize: 11))
                drawText("Zweck", x: colX[2], y: y, width: cols[2], font: .boldSystemFont(ofSize: 11))
                drawText("Kaufort", x: colX[3], y: y, width: cols[3], font: .boldSystemFont(ofSize: 11))
                drawText("Betrag", x: colX[4], y: y, width: cols[4], font: .boldSystemFont(ofSize: 11), align: .right)
                y += rowHeight
            }

            let monatName = mn[max(1, min(12, e.monat)) - 1]
            drawText(monatName, x: colX[0], y: y, width: cols[0], font: .systemFont(ofSize: 10))
            drawText(dateFmt.string(from: e.datum), x: colX[1], y: y, width: cols[1], font: .systemFont(ofSize: 10))
            drawText(e.verwendungszweck, x: colX[2], y: y, width: cols[2], font: .systemFont(ofSize: 10))
            drawText(e.kaufort, x: colX[3], y: y, width: cols[3], font: .systemFont(ofSize: 10))
            drawText(String(format: "%.2f €", e.betrag), x: colX[4], y: y, width: cols[4], font: .systemFont(ofSize: 10), align: .right)
            y += rowHeight
        }

        y += 8
        let summe = eintraegeSortiert.reduce(0.0) { $0 + $1.betrag }
        drawText("Gesamtsumme", x: colX[2], y: y, width: cols[2] + cols[3], font: .boldSystemFont(ofSize: 11), align: .right)
        drawText(String(format: "%.2f €", summe), x: colX[4], y: y, width: cols[4], font: .boldSystemFont(ofSize: 11), align: .right)

        return pdfData as Data
    }
}
