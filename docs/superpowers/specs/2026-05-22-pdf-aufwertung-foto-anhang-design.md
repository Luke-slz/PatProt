# Design: PDF-Aufwertung, Foto-Anhang & PDF-Positionshinweise

**Datum:** 2026-05-22  
**Status:** Genehmigt  

---

## Überblick

Drei zusammenhängende Verbesserungen am PatProt-System:

1. **PDF aufräumen** — ABCDE zeigt "o.B." für leere Felder; SAMPLER überspringt leere Felder
2. **Foto-Anhang** — Medikamentenplan-Fotos + allgemeine Patientenfotos werden als eigene PDF-Seiten (S. 3ff.) angehängt
3. **PDF-Positionshinweise in der App** — Jedes Freitext-Eingabefeld zeigt einen grauen Hinweis, wo der Eintrag im PDF erscheint

---

## A. PDF-Änderungen (`Services/PDFGenerator.swift`)

### A.1 ABCDE-Grid

**Aktuell:** Leere `freitext`-Felder (A–E) zeigen eine leere Box.  
**Neu:** Leere Felder zeigen `"o.B."` in grauer, kursiver Schrift (`UIColor.lightGray`, kursive Font-Variante).  
Alle 5 Zeilen bleiben immer sichtbar — Format-Treue zum Originalprotokoll bleibt erhalten.

```
Änderung in drawPage1():
let abcdeVals = [
    p.airway.freitext.isEmpty    ? "o.B." : p.airway.freitext,
    p.breathing.freitext.isEmpty ? "o.B." : p.breathing.freitext,
    ...
]
// Farbe beim txt()-Aufruf: leere → UIColor.lightGray, befüllt → .black
```

### A.2 SAMPLER-Block

**Aktuell:** Alle 7 Felder (S/A/M/P/L/E/R) immer gerendert, auch wenn leer.  
**Neu:**
- Felder mit leerem Wert werden übersprungen (`guard !value.isEmpty`)
- M – Medikamente: Wenn `medikamentFotos` nicht leer → zeigt `"Medikamentenplan: Foto-Anhang (S. 3ff.)"` (auch wenn `.medikamente` leer ist)
- Wenn alle Felder leer und keine Fotos: Eine Zeile `"– nicht erhoben –"` in grau

### A.3 Foto-Anhang-Seiten (neue Funktion `drawFotoPages`)

Neue private Methode `drawFotoPages(ctx:mediFotos:patFotos:erstelltAm:)` die nach `drawPage2` aufgerufen wird. Der `UIGraphicsPDFRendererContext` wird durchgereicht, damit `ctx.beginPage()` pro Foto aufgerufen werden kann.

**Reihenfolge:** Erst Medikamentenplan-Fotos, dann allgemeine Patientenfotos.

**Seitenaufbau je Foto:**
```
[Blauer Header-Balken (h=22): "Medikamentenplan – Foto 1 / 2" oder "Patientenfoto – Foto 1 / 3"]
[Foto: aspect-fit in CGRect(x:7, y:22, width:581, height:pageHeight-22-14), zentriert]
[Standard-Footer (h=14, wie Seiten 1+2)]
```

**generate()-Anpassung:**
```swift
try renderer.writePDF(to: url) { ctx in
    ctx.beginPage(); drawPage1(p: protokoll)
    ctx.beginPage(); drawPage2(p: protokoll)
    drawFotoPages(ctx: ctx, mediFotos: protokoll.medikamentFotos,
                  patFotos: protokoll.fotos, erstelltAm: protokoll.erstelltAm)
}
```

Wenn keine Fotos vorhanden → keine zusätzlichen Seiten.

---

## B. Datenmodell (`Models/Models.swift`)

### B.1 Neues Feld in `EinsatzProtokoll`

```swift
@Published var medikamentFotos: [FotoEintrag] = []
```

Platzierung: nach `fotos`, vor `medikamente`.

### B.2 `reset()` anpassen

```swift
medikamentFotos.forEach { $0.loeschen() }
medikamentFotos = []
```

### B.3 `SAMPLERBefund.medikamente`

Das String-Feld bleibt im Modell (Codable-Kompatibilität mit archivierten Protokollen). Es wird in der UI nicht mehr angezeigt.

---

## C. Views

### C.1 `SAMPLERView.swift` — M-Sektion ersetzen

**Signatur-Änderung:** `SAMPLERView` bekommt ein zweites Binding:
```swift
struct SAMPLERView: View {
    @Binding var befund: SAMPLERBefund
    @Binding var medikamentFotos: [FotoEintrag]  // NEU
    var onZurueck: () -> Void
```
Alle Aufrufer von `SAMPLERView` (ContentView 2.swift, iPadMainView.swift) müssen `medikamentFotos: $protokoll.medikamentFotos` übergeben.

**Entfernen:** Die bestehende `Section` für `"M — Medikamente"` (TextEditor mit `$befund.medikamente`).

**Ersetzen durch:** Neue Sektion `"M — Medikamente (Foto)"`:

```
Section header: "M — Medikamente (Foto)"
├── Text("Aktuelle Medikation als Foto dokumentieren")  ← .caption, grau
├── Wenn medikamentFotos nicht leer:
│   └── ScrollView(.horizontal): LazyHStack mit Thumbnails (80×80pt)
│       └── Je Thumbnail: Foto + Löschen-Button (X oben rechts)
├── HStack:
│   ├── Button("Kamera", systemImage: "camera") → zeigt CameraImagePicker
│   └── Button("Bibliothek", systemImage: "photo.on.rectangle") → zeigt PHPicker
└── Text("→ PDF S. 3ff. · Foto-Anhang")  ← .caption, grau
```

### C.2 `ABCDEDetailViews.swift` — PDF-Positionshinweise

In jedem der 5 Views (A–E), in der `Section { TextEditor } header: { Text("Freitext / Notizen") }`:

Footer unter dem TextEditor (als `.listRowBackground`-freier `Text`):
```swift
Text("→ PDF S. 1 · ABCDE · A")
    .font(.caption2)
    .foregroundColor(.secondary)
```

| View | Hinweis-Text |
|------|-------------|
| AirwayView | `→ PDF S. 1 · ABCDE · A` |
| BreathingView | `→ PDF S. 1 · ABCDE · B` |
| CirculationView | `→ PDF S. 1 · ABCDE · C` |
| DisabilityView | `→ PDF S. 1 · ABCDE · D` |
| ExposureView | `→ PDF S. 1 · ABCDE · E` |

### C.3 `SAMPLERView.swift` — PDF-Positionshinweise (restliche Felder)

Unter dem TextEditor/TextField jeder verbleibenden SAMPLER-Sektion:

| Feld | Hinweis-Text |
|------|-------------|
| S – Symptome | `→ PDF S. 1 · SAMPLER · S` |
| A – Allergien | `→ PDF S. 1 · SAMPLER · A` |
| P – Vorgeschichte | `→ PDF S. 1 · SAMPLER · P` |
| L – Letzte Mahlzeit | `→ PDF S. 1 · SAMPLER · L` |
| E – Ereignis | `→ PDF S. 1 · SAMPLER · E` |
| R – Risikofaktoren | `→ PDF S. 1 · SAMPLER · R` |

---

## D. Neue Komponente: `MedikamentFotoView`

Neuer Wrapper für Foto-Aufnahme (neue Datei `Views/MedikamentFotoView.swift` oder Hilfscode inline in SAMPLERView):

### D.1 `CameraImagePicker` (UIViewControllerRepresentable)
- Wraps `UIImagePickerController` mit `sourceType = .camera`
- Callback: `onImage: (UIImage) -> Void`
- Speichert Bild als JPEG in `FileManager.default.temporaryDirectory`
- Erstellt `FotoEintrag` und hängt ihn an `medikamentFotos`

### D.2 `PHPickerWrapper` (UIViewControllerRepresentable)
- Wraps `PHPickerViewController` mit `filter = .images`
- Gleicher Callback wie CameraImagePicker

**Bildspeicherung** (konsistent mit vorhandenen `FotoEintrag`):
```swift
let filename = "medifoto_\(UUID().uuidString).jpg"
let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
try data.write(to: url)
medikamentFotos.append(FotoEintrag(bildDateiname: filename))
```

---

## Nicht im Scope

- Änderungen an `ProtokollArchiv` / `ProtokollDaten` — Fotos werden nicht archiviert (wie bestehende Fotos)
- OCR / automatisches Auslesen des Medikamentenplans
- Änderungen an anderen PDF-Sektionen (Sektion 3 Befunde, Sektion 4 Diagnose etc.)
- Änderungen an der allgemeinen Foto-Aufnahme-UI (bestehende FotoView bleibt unverändert)

---

## Betroffene Dateien

| Datei | Art der Änderung |
|-------|-----------------|
| `Services/PDFGenerator.swift` | ABCDE "o.B.", SAMPLER bedingt, drawFotoPages() |
| `Models/Models.swift` | medikamentFotos Feld + reset() |
| `Views/SAMPLERView.swift` | M-Sektion ersetzen + Hinweise |
| `Views/ABCDEDetailViews.swift` | PDF-Hinweise in allen 5 Views |
| `Views/MedikamentFotoView.swift` | Neue Datei (Kamera/Bibliothek-Wrapper) |
