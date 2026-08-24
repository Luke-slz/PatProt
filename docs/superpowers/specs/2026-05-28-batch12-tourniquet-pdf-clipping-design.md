# Design: Batch 12 — Tourniquet ZeitFeld, PDF Körperschema Clipping

**Datum:** 2026-05-28
**Scope:** Tourniquet Zeit clearbar machen; Körperschema im PDF mit explizitem Clipping sichern

---

## 1. Tourniquet Zeit → ZeitFeld

### Problem
`MassnahmenView.swift` zeigt die Tourniquet-Zeit als direktes `DatePicker` ohne ✕-Button. `tourniquetZeit: Date?` ist optional (default `nil`), aber sobald der Nutzer den DatePicker berührt, wird ein Wert gesetzt und kann nicht mehr gelöscht werden.

`ZeitFeld` (definiert in EinsatzOrtView.swift) bindet an `Date?`, zeigt "--:--" für nil, hat einen „Jetzt"-Button und einen ✕-Button zum Löschen. Es ist genau das richtige Steuerelement.

### Fix

**MassnahmenView.swift** — im Tourniquet-Block, ersetze:

```swift
// vorher:
DatePicker("Tourniquet Zeit", selection: Binding(
    get: { befund.tourniquetZeit ?? Date() },
    set: { befund.tourniquetZeit = $0 }
), displayedComponents: .hourAndMinute)

// nachher:
ZeitFeld(label: "Tourniquet Zeit", datum: $befund.tourniquetZeit)
```

`ZeitFeld` benötigt keinen Import — es liegt in derselben Views-Gruppe.

---

## 2. PDF Körperschema — Explizites Clipping

### Problem
`drawBodySilhouette` in PDFGenerator.swift wird ohne explizites Clipping aufgerufen. Die Funktion skaliert den Körper auf `h / 130.0`, erhält aber `silhH - 2` als Höhe, was zu einer leichten Verkleinerung (ca. 98%) führt. Ohne Clipping können Zeichnungspfade bei unerwarteten Werten über den zugewiesenen Bereich hinausragen und in benachbarte PDF-Inhalte eingreifen.

### Fix

**PDFGenerator.swift** — um den `drawBodySilhouette`-Aufruf (Zeilen ~999–1001) `saveGState` / `clip(to:)` / `restoreGState` wickeln:

```swift
// vorher:
drawBodySilhouette(p.diagnose.verletzungsMatrix,
                   rect: CGRect(x:lx+2, y:y+1, width:v2BodyW-4, height:silhH-2))

// nachher:
let silhRect = CGRect(x:lx+2, y:y+1, width:v2BodyW-4, height:silhH-2)
ctx.cgContext.saveGState()
ctx.cgContext.clip(to: silhRect)
drawBodySilhouette(p.diagnose.verletzungsMatrix, rect: silhRect)
ctx.cgContext.restoreGState()
```

Die Variable `ctx` ist der `UIGraphicsPDFRendererContext` der umgebenden Closure. Der Aufruf liegt innerhalb von `ctx.cgContext`-Operationen.

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Views/MassnahmenView.swift` | DatePicker → ZeitFeld für tourniquetZeit |
| `PatProt/Services/PDFGenerator.swift` | saveGState/clip/restoreGState um drawBodySilhouette |

Keine Model-Änderungen, keine neuen Tests erforderlich (View- und PDF-fixes).
