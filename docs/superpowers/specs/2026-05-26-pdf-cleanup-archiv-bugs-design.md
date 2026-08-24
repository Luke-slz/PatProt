# Design: PDF Cleanup, Archiv 24h, Bug-Fixes

**Datum:** 2026-05-26
**Scope:** Batch 1 — PDF-Überarbeitung (checked-only), Archiv-Ablauf nach 24h, NACA-Duplikat, Einsatzzeiten-Reihenfolge

---

## 1. PDF Cleanup (checked-only)

### Ziel
Das PDF zeigt nur noch Felder und Checkboxen, die tatsächlich ausgefüllt oder angekreuzt wurden. Nicht angekreuzte Einträge werden nicht gerendert. Das verhindert das bisherige Overflow-Problem (Seite 1 hatte ~854pt Inhalt bei 841pt Seitenhöhe) und macht das PDF deutlich lesbarer.

### 1.1 Section 2 — Reihenfolge und SAMPLER

**Neue Reihenfolge in Section 2:**
1. Notfallgeschehen-Felder (Erstbefund, Pat. vorgefunden, MANV etc.) — unverändert, dynamisch
2. ABCDE-Grid (5 Zeilen) — Zeilenhöhe von 15pt auf 11pt reduziert
3. SAMPLER — alle 7 Zeilen immer gerendert (S, A, M, P, L, E, R), auch wenn leer

**Begründung:** SAMPLER ist klinisch immer relevant (leere Zeile = bewusst nicht erhoben). ABCDE steht für Befunde, SAMPLER für Anamnese — Befunde zuerst ist sinnvoller für das Lesen des Protokolls.

### 1.2 Section 3 Befunde — Dual-Checkbox-Filter

**A+B Atmung, C Kreislauf+EKG, D Neurologie:**
- Nur Zeilen rendern, bei denen `ankunft == true || übergabe == true`
- Wenn in einer Sektion keine Zeile gesetzt: eine einzelne Zeile "o.B." (kursiv, grau) anzeigen
- Messwerte-Spalte (RR, HF, SpO₂, AF, BZ, Temp) bleibt unverändert

**Messwerte-Spalte** (RR, HF, SpO₂, AF, BZ, Temp): Immer alle 7 Zeilen gerendert — numerische Felder, kein Checkbox-Filter.

**Schmerz-Block:** Nur rendern wenn `schmerz > 0` (Ankunft) oder `ub.schmerz > 0` (Übergabe).

### 1.3 Section 4 Diagnose — Kompaktliste statt Checkbox-Gitter

**Jetzt:** Sechs 3-Spalten-Gitter mit zusammen ~55 Checkbox-Zeilen, alle immer gerendert.

**Neu:** Pro Diagnosegruppe (ZNS/Neurologie, Herz-Kreislauf, Infektionen/Sonstiges, Psychiatrie, Gyn/Geburtshilfe, Stoff/Abdomen, Spezielle Traumen):
- `subHeader` für die Gruppe wird nur gerendert, wenn mind. eine Diagnose dieser Gruppe angekreuzt ist
- Darunter: eine einzelne `field`-Zeile mit den angekreuzten Diagnosen als `" · "`-getrennten Text
- Wenn keine Diagnose in keiner Gruppe: Section 4 zeigt nur Leitsymptom/Verdachtsdiagnosen

**Leitsymptom und Verdachtsdiagnosen** bleiben unverändert (bereits dynamisch).

### 1.4 Section 6 Maßnahmen — Nur angekreuzte Einträge

**4 Spalten bleiben bestehen** (Airway/Stabilisation, Kreislauf/Zugänge, Weitere Maßnahmen, Lagerung/Transport).
- Pro Spalte: nur angekreuzte Items rendern
- Leere Spalte → Spalten-Header bleibt, Inhalt zeigt eine einzelne "—"-Zeile
- Monitoring-Zeile: Nur angekreuzte Monitoring-Items als Textzeile (`"SpO₂ · NIBP · EKG"`)

### 1.5 Section 7 Reanimation — Bedingt anzeigen

Wird nur gerendert wenn `reanimationAktiv == true` ODER mind. eines dieser Felder gesetzt:
`erstHelfer || vorabTelefonRea || aed || dnrOrder || khAufnahmeVorROSC`

Ansonsten wird Section 7 vollständig übersprungen.

### 1.6 Section 8 NACA — Einzelzeile statt Radio-Liste

**Jetzt:** 8 Zeilen, aktiver Wert highlighted.
**Neu:** Eine einzelne `field`-Zeile: `"NACA"` | `"III – Stationäre Behandlung..."`.
Wenn `nacaScoreWert == nil`: Zeile wird weggelassen.

---

## 2. Archiv 24h nach PDF-Export

### Datenmodell
`ProtokollDaten` bekommt ein neues Feld:
```swift
var pdfExportiertAm: Date? = nil
```
Da optional mit Default `nil`, ist das rückwärtskompatibel mit bestehenden archivierten JSON-Dateien.

### Ablauf beim PDF-Export (`AbschlussView`)
Beide Export-Buttons (Share + Mail) führen nach erfolgreichem Export aus:
1. Protokoll ins Archiv speichern (falls `!gespeichert`) — Fehler hier blockiert den Export **nicht** (`try?`)
2. `pdfExportiertAm = Date()` setzen und Archiveintrag aktualisieren

Neue Methode in `ProtokollArchiv`:
```swift
func markierePDFExport(id: UUID)
```
Setzt `pdfExportiertAm` im entsprechenden Eintrag und schreibt die JSON-Datei neu.

### Automatisches Löschen
`ProtokollArchiv.laden()` filtert beim App-Start:
- Einträge mit `pdfExportiertAm != nil && pdfExportiertAm! < Date() - 86400s` → Datei + Eintrag löschen
- Einträge ohne `pdfExportiertAm` bleiben erhalten (bis auto-save in Batch 2 kommt)

---

## 3. Bug-Fixes

### 3.1 NACA doppelt — totes Feld entfernen
`ErgebnisData.nacaScore: NacaScore` wird aus dem Model entfernt. Das Feld hat Standardwert `.naca3`, wird in keiner View angezeigt und ist nicht im PDF. Es existiert parallel zu `NotfallgeschehenBefund.nacaScoreWert`, das die echte Datenquelle ist.

Da `nacaScore` nie über eine View gesetzt wurde, gibt es keine Datenmigration — bestehende JSON-Dateien dekodieren ohne das Feld fehlerfrei (Codable ignoriert unbekannte Keys).

### 3.2 Einsatzzeiten-Reihenfolge
**`EinsatzzeitenView`** — neue Reihenfolge:
1. Alarmzeit
2. Ankunft Patient
3. **Übergabe an RD** (bisher 4.)
4. **Einsatz Ende** (bisher "Abfahrt Einsatzstelle", Label-Änderung)

**Validierungslogik** anpassen:
- Ankunft ≥ Alarm
- Übergabe ≥ Ankunft
- Einsatz Ende ≥ Übergabe

**PDF** (`drawPage1`): Label `"Ankunft Zielklinik"` → `"Übergabe an RD"`.

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `Services/PDFGenerator.swift` | Section 2 Reihenfolge, ABCDE-Höhe, Section 3 Filter, Section 4 Kompaktliste, Section 6 Filter, Section 7 bedingt, Section 8 Einzelzeile, Label "Übergabe an RD" |
| `Models/Models.swift` | `ErgebnisData.nacaScore` entfernen, `ProtokollDaten.pdfExportiertAm` hinzufügen |
| `Services/ProtokollArchiv.swift` | `markierePDFExport(id:)`, Purge-Logik in `laden()` |
| `Views/AbschlussView.swift` | Auto-Archivierung + `markierePDFExport` bei Export |
| `Views/EinsatzzeitenView.swift` | Reihenfolge + Labels + Validierung |
