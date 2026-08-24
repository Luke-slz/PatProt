# Design: Batch 13 — Maßnahmen in ABCDE-Ansicht

**Datum:** 2026-05-28
**Scope:** Relevante dokumentierte Maßnahmen in den ABCDE-Detailansichten einblenden

---

## Problem

Die ABCDE-Detailansichten (AirwayView, BreathingView, CirculationView, DisabilityView, ExposureView) zeigen nur die jeweiligen Befund-Daten. Dokumentierte Maßnahmen (`MassnahmenBefund`) sind in einer separaten Section sichtbar. Ein ERS-Helfer, der gerade die Atemwege bewertet, sieht nicht, ob bereits O₂ gegeben oder ein supraglottischer Atemweg gelegt wurde — er muss die Ansicht wechseln.

---

## Fix

### Ansatz

Jede ABCDE-Detailansicht bekommt einen neuen Parameter `massnahmen: MassnahmenBefund` (read-only, kein Binding). Am Ende der View wird eine Section „Dokumentierte Maßnahmen" eingeblendet — aber **nur wenn mindestens eine relevante Maßnahme aktiv ist**.

ExposureView nimmt bereits das volle `protokoll: EinsatzProtokoll` entgegen — dort wird `protokoll.massnahmen` direkt genutzt, kein neuer Parameter nötig.

### Relevante Maßnahmen pro Abschnitt

**A – Airway:**
- atemwegFreimachen → "Atemweg freimachen"
- cervikalStuetze → "Cervikalstütze"
- absaugung → "Absaugung"
- guedelTubus → "Guedel-Tubus (OPA)"
- wendlTubus → "Wendl-Tubus (NPA)"
- supraglottisch → "Supraglottischer AW (+ Typ wenn gesetzt)"
- atemwegErschwert → "Erschwerter Atemweg"
- heimlich → "Heimlich-Manöver"

**B – Breathing:**
- sauerstoffgabe → "O₂ (+ l/min wenn gesetzt)"
- maskenbeatmung → "Maskenbeatmung"
- maschinelleBeatmung → "Maschinelle Beatmung"
- cpap → "CPAP (+ mbar wenn gesetzt)"

**C – Circulation:**
- peripherVenoes → "Peripher-venöser Zugang (+ Ort wenn gesetzt)"
- intraossaer → "Intraossärer Zugang (+ Ort wenn gesetzt)"
- defibrillation → "Defibrillation"
- kardioversion → "Kardioversion"
- tourniquet → "Tourniquet"

**D – Disability:**
- monBz → "BZ-Monitoring"
- monEkg → "EKG-Monitoring"
- krisenintervention → "Krisenintervention"

**E – Exposure** (via `protokoll.massnahmen`):
- kuehlung → "Kühlung"
- waermeerhalt → "Wärmeerhalt"
- verband → "Verband"
- beckenschlinge → "Beckenschlinge"
- extremitaetenschienung → "Extremitätenschienung"
- vakuummatratze → "Vakuummatratze"

### View-Änderungen

**ABCDEDetailViews.swift:**

1. `AirwayView`: neuer Parameter `var massnahmen: MassnahmenBefund`, neue Section am Ende
2. `BreathingView`: neuer Parameter `var massnahmen: MassnahmenBefund`, neue Section am Ende
3. `CirculationView`: neuer Parameter `var massnahmen: MassnahmenBefund`, neue Section am Ende
4. `DisabilityView`: neuer Parameter `var massnahmen: MassnahmenBefund`, neue Section am Ende
5. `ExposureView`: keine Parametrierung nötig (hat schon `protokoll`), neue Section am Ende

Jede Section:
```swift
let items = relevanteMassnahmen  // [String] computed var
if !items.isEmpty {
    Section {
        ForEach(items, id: \.self) { item in
            Label(item, systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.subheadline)
        }
    } header: {
        Label("Dokumentierte Maßnahmen", systemImage: "cross.fill")
    }
}
```

`relevanteMassnahmen` ist eine `private var` in jeder View (kein Computed-Overhead, da MassnahmenBefund ein kleines Struct ist).

### Call-Site-Änderungen

**`PatProt/ContentView 2.swift`** (iPhone) — Zeilen 108, 113, 118, 123: `massnahmen: protokoll.massnahmen` hinzufügen.

**`PatProt/Views/iPadMainView.swift`** — Zeilen 333, 337, 341, 345: `massnahmen: protokoll.massnahmen` hinzufügen.

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Views/ABCDEDetailViews.swift` | 4 neue Parameter + 5 Maßnahmen-Sections |
| `PatProt/ContentView 2.swift` | 4 Call-Sites aktualisiert |
| `PatProt/Views/iPadMainView.swift` | 4 Call-Sites aktualisiert |

Keine Model-Änderungen, keine neuen Tests erforderlich (UI-only).
