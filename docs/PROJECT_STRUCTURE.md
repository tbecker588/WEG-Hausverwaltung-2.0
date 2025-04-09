# 📱 WEG Hausverwaltung 2.0 - Detaillierte Projektstruktur

## 1. 🔷 App-Grundlagen
### Core App Files
- **ContentView.swift**
  - Hauptansicht der App
  - Navigation & Routing
  - State Management
- **WEG_Hausverwaltung_2_0App.swift**
  - App-Lebenszyklus
  - Dependency Injection
  - Globale Konfiguration
- **SceneDelegate.swift**
  - Fenster-Verwaltung
  - UI-Lebenszyklus
  - State Restoration
- **Persistence.swift**
  - CoreData Setup
  - Datenbankinitialisierung
  - Migrations-Logik

## 2. 🔷 Components
### UI-Bausteine (4 Dateien)
- **ConsumptionOverviewCard.swift**
  - Verbrauchsübersicht
  - Diagramme & Charts
  - Interaktive Elemente
- **InfoRow.swift**
  - Listeneintrag-Template
  - Konfigurierbare Labels
  - Einheitliches Design
- **SignaturePadView.swift**
  - Unterschriften-Erfassung
  - Apple Pencil Support
  - PDF-Export
- **UniversalNumpad.swift**
  - Numerische Eingabe
  - Validierung
  - Formatierung

## 3. 🔷 CoreData
### Datenverwaltung (4 Dateien)
- **CoreDataModelReference.swift**
  - Entity-Definitionen
  - Beziehungen
  - Attribute
- **CoreDataModelValidator.swift**
  - Datenvalidierung
  - Constraints
  - Fehlerbehandlung
- **CoreDataModels.swift**
  - Model-Klassen
  - Computed Properties
  - Convenience Methods
- **CoreDataStack.swift**
  - Persistenz-Container
  - CRUD-Operationen
  - Context-Management

## 4. 🔷 Design
### UI/UX System (1 Datei)
- **DesignSystem.swift**
  - Farb-Palette
  - Typography
  - Spacing & Layout
  - Komponenten-Stile
  - Assets & Icons
  - Animationen

## 5. 🔷 Services
### Geschäftslogik (7 Dateien)
- **AuthService.swift**
  - Authentifizierung
  - Autorisierung
  - Session-Management
- **BillingCalculationService.swift**
  - Verbrauchsberechnung
  - Kostenverteilung
  - Abrechnung
- **BillingService.swift**
  - Rechnungserstellung
  - PDF-Generierung
  - Archivierung
- **CalculationService.swift**
  - Mathematische Berechnungen
  - Statistiken
  - Prognosen
- **ExcelImportService.swift**
  - Datenimport
  - Validierung
  - Mapping
- **OwnerTransferService.swift**
  - Eigentümerwechsel
  - Datenmigration
  - Historie
- **PDFService.swift**
  - Dokumentenerstellung
  - Templates
  - Digitale Signatur

## 6. 🔷 Models
### Datenmodelle (14 Dateien)
- **AdditionalPayment.swift**
- **AnnualBilling+Extensions.swift**
- **ApartmentBilling+Extensions.swift**
- **AppModels.swift**
- **AuditLog.swift**
- **Billing.swift**
- **BillingModels.swift**
- **BillingStatus.swift**
- **DistributionKey.swift**
- **Enums.swift**
- **Heater.swift**
- **Owner.swift**
- **Tenant.swift**
- **TypeAliases.swift**

## 7. 🔷 Extensions
### Erweiterungen (3 Dateien)
- **Color+Custom.swift**
  - Farbdefinitionen
  - Themes
- **Font+Custom.swift**
  - Schriftarten
  - Text-Stile
- **Owner+Extensions.swift**
  - Berechnungsmethoden
  - Hilfs-Funktionen

## 8. 🔷 Views
### Hauptansichten (21 Dateien)
#### Admin-Bereich
- **AdminView.swift**
- **SettingsView.swift**
- **UserManagementView.swift**

#### Abrechnungen
- **BillingView.swift**
- **BillingDetailView.swift**
- **BillingPreviewView.swift**

#### Zählerstände
- **MeterReadingView.swift**
- **MeterReadingDetailView.swift**
- **MeterReadingInputView.swift**

#### Eigentümer
- **OwnerListView.swift**
- **OwnerDetailView.swift**
- **TenantDetailView.swift**

## 9. 🔷 Tests
### Teststrategie (5 Dateien)
#### Unit Tests
- **HeaterTests.swift**
  - Verbrauchsberechnung
  - Validierung
- **TypeAliasesTests.swift**
  - Typ-Konvertierung
- **WEG_Hausverwaltung_2_0Tests.swift**
  - Integration

#### UI Tests
- **WEG_Hausverwaltung_2_0UITests.swift**
  - Navigation
  - Interaktion
- **WEG_Hausverwaltung_2_0UITestsLaunchTests.swift**
  - App-Start
  - Performance

## 📊 Metriken
- **Codebasis**: 74 Swift-Dateien
- **Testabdeckung**: 6.8%
- **Hauptmodule**: 11
- **Durchschnittliche Dateigröße**: ~200 Zeilen
- **Komplexität**: Mittel bis Hoch

## 📋 Verbesserungsvorschläge
1. **Tests**
   - Unit-Tests für Services
   - UI-Tests für kritische Pfade
   - Performance-Tests

2. **Dokumentation**
   - API-Dokumentation
   - Architektur-Diagramme
   - Workflow-Beschreibungen

3. **Code-Qualität**
   - Service-Layer überarbeiten
   - View-Hierarchie optimieren
   - Dependency Injection einführen

4. **Performance**
   - CoreData-Optimierung
   - Memory-Management
   - Lazy Loading

5. **Sicherheit**
   - Input-Validierung
   - Datenverschlüsselung
   - Zugriffskontrollen