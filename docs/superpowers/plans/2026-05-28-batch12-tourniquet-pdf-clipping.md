# Batch 12 — Tourniquet ZeitFeld, PDF Körperschema Clipping

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tourniquet-Zeit im Maßnahmen-Formular clearbar machen; Körperschema im PDF mit explizitem Clipping absichern.

**Architecture:** Zwei unabhängige View-/Service-Fixes ohne Model-Änderungen. Keine neuen Tests erforderlich.

**Tech Stack:** Swift 5.9, SwiftUI, `xcodebuild test`

---

## Dateien

| Datei | Änderung |
|---|---|
| `PatProt/Views/MassnahmenView.swift` | DatePicker → ZeitFeld für tourniquetZeit |
| `PatProt/Services/PDFGenerator.swift` | saveGState/clip/restoreGState um drawBodySilhouette |

---

## Task 1: Tourniquet ZeitFeld

**Files:**
- Modify: `PatProt/Views/MassnahmenView.swift` (Zeilen ~218–224)

**Context:**
- `MassnahmenBefund.tourniquetZeit: Date? = nil` (Models.swift Zeile 715).
- Aktuell: `DatePicker("Tourniquet Zeit", selection: Binding(get: { befund.tourniquetZeit ?? Date() }, set: { befund.tourniquetZeit = $0 }), displayedComponents: .hourAndMinute)` — kein Clear-Button.
- `ZeitFeld(label:datum:)` bindet direkt an `Date?` und hat ✕-Button eingebaut. Wird bereits in EinsatzzeitenView und SAMPLERView verwendet.

- [ ] **Step 1: DatePicker durch ZeitFeld ersetzen**

In `PatProt/Views/MassnahmenView.swift`, im Tourniquet-Block, ersetze:

```swift
                DatePicker("Tourniquet Zeit", selection: Binding(
                    get: { befund.tourniquetZeit ?? Date() },
                    set: { befund.tourniquetZeit = $0 }
                ), displayedComponents: .hourAndMinute)
```

durch:

```swift
                ZeitFeld(label: "Tourniquet Zeit", datum: $befund.tourniquetZeit)
```

- [ ] **Step 2: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 3: Commit**

```bash
git add PatProt/Views/MassnahmenView.swift
git commit -m "fix: replace DatePicker with ZeitFeld for tourniquetZeit to allow clearing"
```

---

## Task 2: PDF Körperschema Clipping

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` (Zeilen ~999–1001)

**Context:**
- `drawBodySilhouette` wird aktuell ohne explizites Clipping aufgerufen.
- Der Aufruf liegt in einer Closure, die `ctx: UIGraphicsPDFRendererContext` als Parameter hat.
- `ctx.cgContext` ist der aktive Core Graphics Context.
- Aktueller Aufruf-Block (ca. Zeilen 995–1005):
  ```swift
  let silhH = 9 + CGFloat(regions.count)*regH + 20
  drawBodySilhouette(p.diagnose.verletzungsMatrix,
                     rect: CGRect(x:lx+2, y:y+1, width:v2BodyW-4, height:silhH-2))
  y += silhH
  ```
- `ctx` muss sichtbar sein — lese die Datei um den exakten Variablennamen der umgebenden Closure zu bestätigen.

- [ ] **Step 1: saveGState/clip/restoreGState einfügen**

In `PatProt/Services/PDFGenerator.swift`, ersetze den `drawBodySilhouette`-Aufruf:

```swift
            let silhRect = CGRect(x:lx+2, y:y+1, width:v2BodyW-4, height:silhH-2)
            ctx.cgContext.saveGState()
            ctx.cgContext.clip(to: silhRect)
            drawBodySilhouette(p.diagnose.verletzungsMatrix, rect: silhRect)
            ctx.cgContext.restoreGState()
```

Behalte `y += silhH` danach unverändert.

Hinweis: Wenn der Context-Parameter in der Closure anders heißt (z.B. `context`), passe `ctx` entsprechend an.

- [ ] **Step 2: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 3: Commit**

```bash
git add PatProt/Services/PDFGenerator.swift
git commit -m "fix: add explicit clipping around body silhouette in PDF renderer"
```
