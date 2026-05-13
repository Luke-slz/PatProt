# RettungsProtokoll iOS App

## Projektstruktur

```
RettungsProtokoll/
├── RettungsProtokollApp.swift          ← App Entry Point
├── ContentView.swift                   ← Navigation / Router
├── Models/
│   └── Models.swift                    ← Alle Datenmodelle
├── Views/
│   ├── EinsatzOrtView.swift            ← Screen 1: Einsatz & Patient
│   ├── ABCDEUebersichtView.swift       ← Screen 2: ABCDE Übersicht
│   ├── ABCDEDetailViews.swift          ← A / B / C / D / E Detailscreens
│   ├── SAMPLERReanimationViews.swift   ← SAMPLER + Reanimationsprotokoll
│   └── AbschlussView.swift             ← Abschluss + PDF Export
└── Services/
    └── PDFGenerator.swift              ← PDF-Erzeugung mit PDFKit
```

## Setup in Xcode

### 1. Neues Xcode-Projekt anlegen
- Xcode öffnen → "Create a new Xcode project"
- iOS → App
- Interface: **SwiftUI**
- Language: **Swift**
- Produktname: `RettungsProtokoll`

### 2. Dateien einfügen
Alle `.swift`-Dateien aus diesem Projekt in das Xcode-Projekt kopieren
(per Drag & Drop in den Project Navigator, "Copy items if needed" anhaken).

### 3. Farbe "RDOrange" anlegen
In `Assets.xcassets`:
- Neues Color Set erstellen → Name: `RDOrange`
- Light Mode: `#D85A30`
- Dark Mode: `#FF7A4A`

### 4. Minimum iOS-Version
- Deployment Target: **iOS 16.0** oder neuer

### 5. Berechtigungen (Info.plist)
Für den PDF-Export / Share-Sheet wird keine zusätzliche Permission benötigt.

---

## Funktionsumfang

### Screen 1 – Einsatz & Patient
- Einsatzort, Adresse, Stichwort, Priorität, Fahrzeugtyp
- Alarmzeit, Ankunft, Abfahrt
- Patientendaten (Name, Geburtsdatum, Geschlecht, Gewicht)
- Besatzung (NFS, Fahrer, Arzt, Praktikant)

### Screen 2 – ABCDE-Übersicht
- Fortschrittsbalken
- Statusanzeige je Buchstabe (Normal / Auffällig / Kritisch)
- Automatische Erkennung ob Reanimationsprotokoll benötigt wird
- Direktzugang zu SAMPLER

### ABCDE-Detailscreens
- **A – Airway**: Atemwegsstatus, Sicherungsmaßnahmen, Intubation
- **B – Breathing**: AF, SpO², Beatmung, O₂-Gabe
- **C – Circulation**: Puls, RR, EKG, Blutung, i.v.-Zugang
- **D – Disability**: GCS mit Stepper, Pupillen, BZ, NRS-Schmerzskala
- **E – Exposure**: Temperatur, Haut, Verletzungen

### SAMPLER
- Vollständige S–A–M–P–L–E–R Anamnese

### Reanimationsprotokoll (automatisch aktiviert bei kritischen Befunden)
- Kollapszeit, Ersthelfer, AED
- Initialrhythmus (VF / VT pulslos / Asystolie / PEA)
- CPR-Zyklen mit Defibrillationsenergie und Zeitstempel
- Medikamentenliste mit Zeitstempel (Standard: Adrenalin, Amiodaron, Atropin...)
- Outcome (ROSC / Verstorben / Transportiert ohne ROSC)

### Abschluss & PDF
- Übergabedaten (Klinik, Arzt, Zustand)
- PDF-Export via PDFKit (kein externes Framework nötig)
- Share-Sheet für AirDrop, E-Mail, Drucker etc.

---

## Erweiterungsideen
- Core Data für lokale Protokollspeicherung und Verlaufsanzeige
- CloudKit-Sync für Team-Zugriff
- Vitalkurve (Zeitverlauf SpO², Puls, RR)
- Medikamentendatenbank mit Dosierungsrechner nach Gewicht
- Unterschrift per Apple Pencil / Finger (PKCanvasView)
- Export als DIVI-Notaufnahmeprotokoll
