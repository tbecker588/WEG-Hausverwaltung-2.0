//
//  ICloudBackupManager.swift
//  Hausverwaltung 2.0
//

import Foundation

struct ICloudBackupManager {
    enum ICloudBackupError: LocalizedError {
        case nichtVerfuegbar
        case keineDateienGefunden
        case speichernFehlgeschlagen(Error)
        case ladenFehlgeschlagen(Error)

        var errorDescription: String? {
            switch self {
            case .nichtVerfuegbar:
                return "iCloud Drive ist für diese App nicht verfügbar. Bitte iCloud in den iOS-Einstellungen aktivieren."
            case .keineDateienGefunden:
                return "Kein iCloud-Backup gefunden."
            case .speichernFehlgeschlagen(let error):
                return "Backup konnte nicht in iCloud gespeichert werden: \(error.localizedDescription)"
            case .ladenFehlgeschlagen(let error):
                return "Backup konnte nicht aus iCloud geladen werden: \(error.localizedDescription)"
            }
        }
    }

    func iCloudDocumentsURL() throws -> URL {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw ICloudBackupError.nichtVerfuegbar
        }
        let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        }
        return documentsURL
    }

    @discardableResult
    func speichereBackupNachICloud(von localFileURL: URL) throws -> URL {
        do {
            let zielOrdner = try iCloudDocumentsURL()
            let zielURL = zielOrdner.appendingPathComponent(localFileURL.lastPathComponent)

            if FileManager.default.fileExists(atPath: zielURL.path) {
                try FileManager.default.removeItem(at: zielURL)
            }
            try FileManager.default.copyItem(at: localFileURL, to: zielURL)
            return zielURL
        } catch let error as ICloudBackupError {
            throw error
        } catch {
            throw ICloudBackupError.speichernFehlgeschlagen(error)
        }
    }

    func listeBackupsInICloud() throws -> [URL] {
        do {
            let documentsURL = try iCloudDocumentsURL()
            let dateien = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            return dateien
                .filter {
                    let ext = $0.pathExtension.lowercased()
                    return ext == "json" || ext == "hausverwaltung"
                }
                .sorted { lhs, rhs in
                    let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                    let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                    return lhsDate > rhsDate
                }
        } catch let error as ICloudBackupError {
            throw error
        } catch {
            throw ICloudBackupError.ladenFehlgeschlagen(error)
        }
    }

    func neuestesBackupAusICloudLokalKopieren() throws -> URL {
        do {
            guard let cloudURL = try listeBackupsInICloud().first else {
                throw ICloudBackupError.keineDateienGefunden
            }
            return try backupAusICloudLokalKopieren(cloudURL)
        } catch let error as ICloudBackupError {
            throw error
        } catch {
            throw ICloudBackupError.ladenFehlgeschlagen(error)
        }
    }

    func backupAusICloudLokalKopieren(_ cloudURL: URL) throws -> URL {
        let zielURL = FileManager.default.temporaryDirectory.appendingPathComponent(cloudURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: zielURL.path) {
            try FileManager.default.removeItem(at: zielURL)
        }
        try FileManager.default.copyItem(at: cloudURL, to: zielURL)
        return zielURL
    }

    /// Wandelt lange Altnamen wie `Hausverwaltung_WEG_Name_2025_2026_20260425_0710.hausverwaltung`
    /// in das Kurzformat `HV2026-4.hausverwaltung` um. Neue Namen (beginnen mit „HV") bleiben unverändert.
    static func normalisierteDateiname(_ url: URL) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        // Bereits im Kurzformat
        if name.hasPrefix("HV") { return url.lastPathComponent }

        // Muster: Teile durch "_" trennen, erstes vierstelliges Jahr + YYYYMMDD-Token suchen
        let teile = name.components(separatedBy: "_")
        if let jahrStr = teile.first(where: { $0.count == 4 && Int($0) != nil }),
           let jahr = Int(jahrStr) {
            var monat = Calendar.current.component(.month, from: Date())
            for teil in teile {
                if teil.count == 8, let _ = Int(teil) {
                    // YYYYMMDD → Monat extrahieren
                    let mStr = String(teil.dropFirst(4).prefix(2))
                    if let m = Int(mStr) { monat = m }
                    break
                }
            }
            return "HV\(jahr)-\(monat).\(url.pathExtension)"
        }
        // Fallback: ursprünglicher Name
        return url.lastPathComponent
    }
}
