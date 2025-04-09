import CoreData
import Foundation
import PDFKit
import UIKit

/// Zentrale Klasse für PDF-Export Funktionalitäten
final class PDFExportUtility {
    // MARK: - Fehlertypen

    enum PDFError: LocalizedError {
        case generationFailed
        case invalidData
        case previewFailed

        var errorDescription: String? {
            switch self {
            case .generationFailed: "PDF konnte nicht erstellt werden"
            case .invalidData: "Ungültige Daten für PDF"
            case .previewFailed: "Vorschau konnte nicht generiert werden"
            }
        }
    }

    // MARK: - PDF Generation

    /// Exportiert Eigentümerdaten als PDF
    /// - Parameter owner: Der zu exportierende Eigentümer
    /// - Returns: PDF als Data oder Error
    func exportOwnerToPDF(owner: NSManagedObject) async throws -> Data {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))

        return try await withCheckedThrowingContinuation { continuation in
            let data = pdfRenderer.pdfData { context in
                context.beginPage()
                drawOwnerPDF(owner: owner, in: context)
            }

            guard !data.isEmpty else {
                continuation.resume(throwing: PDFError.generationFailed)
                return
            }

            continuation.resume(returning: data)
        }
    }

    /// Generiert eine Vorschau aus PDF-Daten
    /// - Parameter data: PDF-Daten
    /// - Returns: Vorschaubild oder Error
    func generatePDFPreview(from data: Data) async throws -> UIImage {
        guard let provider = CGDataProvider(data: data as CFData),
              let document = CGPDFDocument(provider),
              let page = document.page(at: 1)
        else {
            throw PDFError.previewFailed
        }

        return await withCheckedContinuation { continuation in
            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)

            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)

                ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                ctx.cgContext.drawPDFPage(page)
            }

            continuation.resume(returning: image)
        }
    }

    /// Generiert eine Abrechnungs-PDF
    /// - Parameter owner: Eigentümer für die Abrechnung
    /// - Returns: PDF als Data oder Error
    func generateBillingPDF(for _: AppOwner) async throws -> Data {
        // TODO: Implementierung hinzufügen
        throw PDFError.generationFailed
    }

    // MARK: - Private Hilfsmethoden

    private func drawOwnerPDF(owner: NSManagedObject, in _: UIGraphicsPDFRendererContext) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
        ]

        // Überschrift
        let title = "Eigentümer-Informationen"
        title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)

        // Eigentümer-Daten
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
        ]

        // Name
        let firstName = owner.value(forKey: "firstName") as? String ?? "k.A."
        let lastName = owner.value(forKey: "lastName") as? String ?? "k.A."
        let nameString = "Name: \(firstName) \(lastName)"
        nameString.draw(at: CGPoint(x: 50, y: 100), withAttributes: textAttributes)

        // Wohnungsinfo
        let apartmentNumber = owner.value(forKey: "apartmentNumber") as? String ?? "k.A."
        let floorNumber = owner.value(forKey: "floorNumber") as? String ?? "k.A."
        let apartmentString = "Wohnung: \(apartmentNumber), Etage: \(floorNumber)"
        apartmentString.draw(at: CGPoint(x: 50, y: 120), withAttributes: textAttributes)

        // Kontaktdaten
        let email = owner.value(forKey: "email") as? String ?? "k.A."
        let phone = owner.value(forKey: "phoneNumber") as? String ?? "k.A."
        let contactString = "Kontakt: \(email), Tel: \(phone)"
        contactString.draw(at: CGPoint(x: 50, y: 140), withAttributes: textAttributes)

        // Eigentumsanteil
        if let share = owner.value(forKey: "ownershipShare") as? Double {
            let shareString = "Eigentumsanteil: \(String(format: "%.2f", share))%"
            shareString.draw(at: CGPoint(x: 50, y: 160), withAttributes: textAttributes)
        }
    }
}
