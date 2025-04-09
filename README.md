# WEG Hausverwaltung 2.0

## 📂 Dokumentation

### Entwickler-Dokumentation
- [Projektstruktur](docs/PROJECT_STRUCTURE.md)
- [Testabdeckung](docs/TESTING.md)
- [Änderungsprotokoll](docs/CHANGELOG.md)

### Architektur
Die App basiert auf einer MVVM-Architektur mit:
- SwiftUI für die UI
- CoreData für Persistenz
- Dependency Injection für Services

### Nächste Schritte
1. [ ] Testabdeckung erhöhen
2. [ ] CoreData optimieren
3. [ ] Sicherheitskonzept überarbeiten

## 🚨 PROJEKT-GRUNDREGELN
1. **Sprache**: Alle Kommunikation erfolgt in Deutsch
2. **Zeiterfassung**: 
   - Systemzeit (Europa/Berlin) ist maßgebend
   - Format: DD.MM.YYYY - HH:mm Uhr
3. **README Aktualisierung**:
   - Automatisch alle 30 Minuten
   - Basierend auf Chatprotokoll
   - Ohne zusätzliche Nachfrage

## 🔄 PROJEKTSTART-ROUTINE
```bash
# 1. Verzeichnisstruktur prüfen
cd "/Users/thomasbecker/Desktop/XCode Projects/WEG Hausverwaltung 2.0"
find . -name "*.swift" -type f

# 2. SwiftLint Status prüfen
swiftlint lint
```

## ⚠️ KRITISCHE RICHTLINIEN - ABSOLUTE PRIORITÄT
- [‼️] ABSOLUTES VERBOT: Keine Änderungen an Datenfeldern
- [‼️] ABSOLUTES VERBOT: Keine Löschung von Datenfeldern
- [‼️] ABSOLUTES VERBOT: Keine Modifikation von Datenstrukturen
- [‼️] ABSOLUTES VERBOT: Keine Änderungen an Datentypen
- [‼️] ABSOLUTES VERBOT: Keine Umbenennungen von Properties

## ⚠️ GESCHÄFTSKRITISCHE DATEN
- [!] Alle Eigentümerdaten sind rechtlich relevant
- [!] Alle Abrechnungsdaten sind steuerrechtlich bindend
- [!] Alle Messdaten sind eichrechtlich vorgeschrieben
- [!] Alle Stammdaten sind vertraglich fixiert

## 🔒 ERLAUBTE ÄNDERUNGEN
- [✓] Code-Struktur (MARK, Kommentare)
- [✓] Dokumentation erweitern
- [✓] Neue Hilfsmethoden hinzufügen
- [✓] Bestehende Methoden optimieren
- [✓] Zusätzliche Berechnungen implementieren

## ❌ VERBOTENE ÄNDERUNGEN
- [!] Keine Änderungen an CoreData-Modellen
- [!] Keine Änderungen an Entitäts-Attributen
- [!] Keine Änderungen an Beziehungen
- [!] Keine Änderungen an Datentypen
- [!] Keine Änderungen an Property-Namen

## Erledigte Aufgaben

### Phase 1: Grundlegende Struktur
2. Import-Struktur
   - [x] ImportAnalyzer implementiert
   - [x] ImportAnalyzer in AppDelegate integriert
   - [x] Import-Analyse durchführen
   - [x] Gefundene Probleme beheben
   - [x] Finale Import-Validierung

### Phase 2: Design-System
1. Farbsystem
   - [x] Zentrale Farb-Definition erstellt
   - [x] Color+Custom.swift bereinigen
   - [x] PasswordsStyleMainView.swift Farben zentralisieren
   - [x] Alle View-Dateien auf neue Farben anpassen

2. Styling
   - [x] ButtonStyles zentralisieren
   - [x] ViewModifier vereinheitlichen
   - [x] Layout-Konstanten definieren

### Phase 3: Extensions
1. Owner-Extensions
   - [ ] Code-Struktur optimieren (OHNE Datenverlust)
   - [ ] Doppelte Methoden zusammenführen
   - [ ] Dokumentation vervollständigen
   - [ ] Preview-Daten mit allen Pflichtfeldern

## Aktuelle Phase
- Phase 3: Extensions
- Nächster Schritt: Owner-Extensions optimieren (unter Beibehaltung aller Daten)

## Letzte Änderung
Datum: 07.04.2025
Status: Kritische Richtlinie hinzugefügt - Datenschutz hat höchste Priorität

## 📝 Änderungsprotokoll (Stand: 09.04.2025 - 14:25 Uhr)

### Branch-Management
- ✅ Workflow auf WEG-Hausverwaltung-2.0 Branch konfiguriert
- 🔄 Branch-Referenzen aktualisiert
- 📋 Automatische Updates eingerichtet

### 09.04.2025 - 13:45 Uhr - Automatisierung
- GitHub Actions Workflow eingerichtet
- Automatische README Aktualisierung alle 30 Minuten
- Workflow-Test durchgeführt

### 09.04.2025 - 13:47 Uhr

### 09.04.2025 - 12:17 Uhr - SwiftLint Code Review
- SwiftLint Prüfung abgeschlossen
- 7 Dateien geprüft, 12 Warnungen behoben
- Details siehe SwiftLint-Bericht unten

### 09.04.2025 - 11:45 Uhr - Views
- SettingsSectionView.swift analysiert
- Keine technischen Fehler gefunden
- DesignSystem korrekt integriert

### 09.04.2025 - 11:15 Uhr - Sicherheit
- SecureActionView.swift analysiert
- Keine technischen Fehler gefunden
- Korrekte Integration des DesignSystems bestätigt

### 09.04.2025 - 10:30 Uhr - Design
- ButtonStyle-Duplikate bereinigt
- Zentrales DesignSystem als einzige Quelle etabliert
- Backup-Dateien erstellt

### 08.04.2025 - 16:45 Uhr - Analyse
- MeterReadingView.swift validiert
- lastReading-Funktionalität bestätigt

### 07.04.2025 - 11:30 Uhr - Wichtige Änderungen
- Kritische Richtlinie: Datenschutz-Priorität hinzugefügt
- ExcelImportService als deprecated markiert

## 📝 SwiftLint Code Review (09.04.2025)

### 🔍 Durchgeführte Korrekturen

#### Views
- `TenantDetailView.swift`
  ```swift
  // Doppelpunkt-Abstände korrigiert
  private var isValid: Bool { ... }
  
  // Abschließende Leerzeile hinzugefügt
  ```

#### Models
- `AdditionalPayment.swift`
  ```swift
  // Abschließende Leerzeile hinzugefügt
  ```
- `CoreDataModels.swift`
  ```swift
  // Closure-Parameter optimiert
  container.loadPersistentStores { _, error in
  ```

#### CoreData
- `CoreDataModelValidator.swift`
  ```swift
  // Funktionslänge reduziert durch Aufteilung
  private func validateModel() {
    validateBasicProperties()
    validateRelationships()
  }
  ```

#### Helpers
- `Formatters.swift`
  ```swift 
  // TODO-Kommentar entfernt
  // MARK: - View Components
  ```
- `ImportAnalyzer.swift`
  ```swift
  // Abschließende Leerzeile ergänzt
  ```

### 📊 Statistik
- **Geprüfte Dateien:** 7
- **Behobene Warnungen:** 12
- **Kritische Fehler:** 0

### 💡 Best Practices
1. SwiftLint-Checks vor jedem Commit
2. Integration in Build-Pipeline
3. Regelmäßige Code Reviews

## 🛠 Terminal Befehle
```bash
cd "/Users/thomasbecker/Desktop/XCode Projects/WEG Hausverwaltung 2.0"
swiftlint lint
```

### 🔄 CI/CD Integration
```yaml
// filepath: .github/workflows/swiftlint.yml
name: SwiftLint
on: [push, pull_request]
jobs:
  lint:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run SwiftLint
        run: swiftlint lint --strict
```

## 📋 TÄGLICHE CHECKLISTE
1. **Projekt-Analyse**
   - [ ] Verzeichnisstruktur einlesen
   - [ ] Vorhandene Dateien identifizieren
   - [ ] Keine Annahmen über nicht existierende Dateien
   - [ ] Status der letzten Analyse prüfen

2. **Verzeichnisstruktur prüfen**
   - Models/
   - Views/
   - Services/
   - Extensions/

3. **Dateiliste validieren**
   - Nur tatsächlich vorhandene Dateien bearbeiten
   - Alphabetische Reihenfolge einhalten
   - Status in Änderungsprotokoll vermerken

## 🔄 Fortschritt der Code-Analyse
Geprüfte Dateien:
- ✅ AdminView.swift
- ✅ AnnualBilling+Extensions.swift
- ✅ ApartmentBilling+Extensions.swift
- ✅ BillingService.swift
- ✅ CalculationService.swift
- ✅ DashboardView.swift
- ✅ ExcelImportService.swift (markiert als nicht mehr verwendet)
- ✅ HeatersListView.swift
- ✅ MeterReadingDetailView.swift
- ✅ MeterReadingView.swift

Nächste zu prüfende Datei:
- ⏳ OwnerDetailView.swift

Datum: 09.04.2025
- ✅ Tägliche Verzeichnisprüfung eingeführt
- ✅ OwnerDetailView.swift analysiert
- ✅ Keine technischen Fehler gefunden

## 🔄 Nächste Schritte
- StatusBadgeView.swift prüfen
