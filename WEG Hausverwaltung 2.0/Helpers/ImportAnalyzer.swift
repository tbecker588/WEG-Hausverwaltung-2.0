import Foundation

/// Analysiert und validiert Import-Statements in Swift-Dateien
///
/// Der ImportAnalyzer durchsucht rekursiv alle Swift-Dateien im Projekt und:
/// - Erkennt fehlende notwendige Imports
/// - Identifiziert doppelte Import-Statements
/// - Validiert spezielle Anforderungen für bestimmte Dateitypen
/// - Erstellt einen detaillierten Markdown-Bericht
class ImportAnalyzer {
    // MARK: - Öffentliche API

    /// Führt eine vollständige Import-Analyse durch
    /// - Durchsucht alle Swift-Dateien im Projekt
    /// - Erstellt einen Bericht über Probleme
    /// - Speichert die Ergebnisse in einer Markdown-Datei
    static func analyzeImports() {
        print("\n🔍 Starte Import-Analyse...")

        let fileManager = FileManager.default
        let projectURL =
            URL(
                fileURLWithPath: "/Users/thomasbecker/Desktop/XCode Projects/WEG Hausverwaltung 2.0/WEG Hausverwaltung 2.0"
            )

        var report = ImportReport()

        if let enumerator = fileManager.enumerator(
            at: projectURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                guard fileURL.pathExtension == "swift" else { continue }

                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    analyzeFile(at: fileURL, content: content, report: &report)
                } catch {
                    print("⚠️ Fehler beim Lesen von \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }

        report.printResults()
        report.saveToFile()
    }

    /// Führt eine finale Validierung aller Imports durch
    /// - Prüft Standard-Imports
    /// - Validiert spezielle Dateien
    /// - Misst die Ausführungszeit
    static func validateFinalImports() {
        print("\n🔄 Starte finale Import-Validierung...")

        let startTime = Date()
        analyzeImports() // Führt die normale Analyse durch

        // Führt zusätzliche Validierungen durch
        validateSpecialCases()

        let endTime = Date()
        print("\n⏱ Validierungszeit: \(String(format: "%.2f", endTime.timeIntervalSince(startTime))) Sekunden")
    }

    // MARK: - Private Hilfsmethoden

    /// Analysiert eine einzelne Swift-Datei
    /// - Parameters:
    ///   - url: URL der zu analysierenden Datei
    ///   - content: Inhalt der Datei
    ///   - report: Report-Objekt für die Ergebnisse
    private static func analyzeFile(at url: URL, content: String, report: inout ImportReport) {
        let fileName = url.lastPathComponent
        let lines = content.components(separatedBy: .newlines)

        var imports = Set<String>()
        var coreDataNeeded = false
        var swiftUINeeded = false

        // Analyse des Dateiinhalts
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "import") {
                if !imports.insert(trimmed).inserted {
                    report.addDuplicate(file: fileName, import: trimmed)
                }
            }

            if !coreDataNeeded {
                coreDataNeeded = trimmed.contains("NSManagedObject") ||
                    trimmed.contains("NSFetchRequest") ||
                    trimmed.contains("CoreDataStack")
            }

            if !swiftUINeeded {
                swiftUINeeded = trimmed.contains("View") ||
                    trimmed.contains("@State") ||
                    trimmed.contains("@Binding")
            }
        }

        // Prüfung auf fehlende Imports
        if coreDataNeeded, !imports.contains("import CoreData") {
            report.addMissing(file: fileName, import: "CoreData")
        }

        if swiftUINeeded, !imports.contains("import SwiftUI") {
            report.addMissing(file: fileName, import: "SwiftUI")
        }

        if !imports.contains("import Foundation") {
            report.addMissing(file: fileName, import: "Foundation")
        }
    }

    /// Validiert spezielle Dateien mit besonderen Anforderungen
    /// - Parameters:
    ///   - fileName: Name der zu prüfenden Datei
    ///   - requiredImports: Liste der erforderlichen Imports
    private static func validateSpecialFile(_ fileName: String, requiredImports: [String]) {
        let projectURL =
            URL(
                fileURLWithPath: "/Users/thomasbecker/Desktop/XCode Projects/WEG Hausverwaltung 2.0/WEG Hausverwaltung 2.0"
            )
        let fileURL = projectURL.appendingPathComponent(fileName)

        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let missingImports = requiredImports.filter { !content.contains("import \($0)") }

            if !missingImports.isEmpty {
                print("⚠️ \(fileName): Fehlende wichtige Imports: \(missingImports.joined(separator: ", "))")
            } else {
                print("✅ \(fileName): Alle erforderlichen Imports vorhanden")
            }
        } catch {
            print("⚠️ Konnte \(fileName) nicht überprüfen: \(error.localizedDescription)")
        }
    }
}

/// Speichert und formatiert die Ergebnisse der Import-Analyse
struct ImportReport {
    // MARK: - Properties

    /// Speichert fehlende Imports pro Datei
    private var missingImports: [String: Set<String>] = [:]

    /// Speichert doppelte Imports pro Datei
    private var duplicateImports: [String: Set<String>] = [:]

    // MARK: - Öffentliche Methoden

    /// Fügt einen fehlenden Import hinzu
    /// - Parameters:
    ///   - file: Dateiname
    ///   - import: Name des fehlenden Imports
    mutating func addMissing(file: String, import: String) {
        missingImports[file, default: []].insert(`import`)
    }

    /// Fügt einen doppelten Import hinzu
    /// - Parameters:
    ///   - file: Dateiname
    ///   - import: Name des doppelten Imports
    mutating func addDuplicate(file: String, import: String) {
        duplicateImports[file, default: []].insert(`import`)
    }

    /// Druckt die Analyseergebnisse in der Konsole aus
    /// Format:
    /// ```
    /// 📊 Import-Analyse Ergebnis
    /// ========================
    /// ⚠️ Fehlende Imports:
    /// 📄 DateiName.swift:
    ///   ➕ import Foundation
    /// ```
    func printResults() {
        print("\n📊 Import-Analyse Ergebnis")
        print("========================")

        if missingImports.isEmpty, duplicateImports.isEmpty {
            print("✅ Keine Probleme gefunden!")
            return
        }

        if !missingImports.isEmpty {
            print("\n⚠️ Fehlende Imports:")
            for (file, imports) in missingImports.sorted(by: { $0.key < $1.key }) {
                print("\n📄 \(file):")
                imports.sorted().forEach { print("  ➕ import \($0)") }
            }
        }

        if !duplicateImports.isEmpty {
            print("\n🔄 Doppelte Imports:")
            for (file, imports) in duplicateImports.sorted(by: { $0.key < $1.key }) {
                print("\n📄 \(file):")
                imports.sorted().forEach { print("  ❌ \($0)") }
            }
        }
    }

    /// Speichert den Bericht als Markdown-Datei
    /// - Throws: Fehler beim Schreiben der Datei
    func saveToFile() {
        let report = generateMarkdownReport()
        let fileURL =
            URL(fileURLWithPath: "/Users/thomasbecker/Desktop/XCode Projects/WEG Hausverwaltung 2.0/import_report.md")

        do {
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            print("\n📝 Bericht gespeichert unter: import_report.md")
        } catch {
            print("⚠️ Fehler beim Speichern des Berichts: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Hilfsmethoden

    /// Erstellt einen Markdown-Bericht basierend auf den Analyseergebnissen
    /// - Returns: String des Markdown-Berichts
    private func generateMarkdownReport() -> String {
        var report = """
        # Import-Analyse Bericht

        Erstellt am: \(Date())

        """

        if !missingImports.isEmpty {
            report += "\n## Fehlende Imports\n"
            for (file, imports) in missingImports.sorted(by: { $0.key < $1.key }) {
                report += "\n### \(file)\n"
                imports.sorted().forEach { report += "- import \($0)\n" }
            }
        }

        if !duplicateImports.isEmpty {
            report += "\n## Doppelte Imports\n"
            for (file, imports) in duplicateImports.sorted(by: { $0.key < $1.key }) {
                report += "\n### \(file)\n"
                imports.sorted().forEach { report += "- \($0)\n" }
            }
        }

        return report
    }
}
