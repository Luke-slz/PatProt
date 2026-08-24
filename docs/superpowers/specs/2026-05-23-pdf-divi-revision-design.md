# PDF-Protokoll DIVI-Revision – Design

**Datum:** 2026-05-23  
**Scope:** `Services/PDFGenerator.swift` – `drawPage1` und `drawPage2`  
**Ziel:** Duplikate entfernen, DIVI-Konformität herstellen, Übersichtlichkeit verbessern

---

## Kontext

Das PatProt-PDF-Protokoll orientiert sich am DIVI-Notarzteinsatzprotokoll v5.0.
Es handelt sich um eine DLRG-First-Responder-Adaptation: Kassen-/Abrechnungsfelder
sind nicht relevant, alle klinischen Abschnitte (1–9) sollen DIVI-konform bleiben.

---

## Identifizierte Probleme

### Duplikate

| Feld | Häufigkeit | Fundstellen |
|------|-----------|-------------|
| Einsatznummer | 3× | Header, Section-1-Zeitblock, Titelblock |
| Datum | 2× | Header, Patientenblock |
| Einsatzart/Stichwort | 2× | Section 1 (`stichwort` + `einsatzArt`) |
| Temperatur | 2× | Messwerte-Spalte + Hautfarbe-Zeile |
| Zyanose | 2× | A+B Atmung + E/Haut (gleiche Datenquelle) |
| SAMPLER | 2× | Dekorativbuchstaben neben ABCDE + voller Block Ende S.1 |

### DIVI-Abweichungen

- **Fahrzeugtypen**: nur `NKW` (hardcoded, immer `false`) statt RTW/KTW/NEF/RTH
- **SAMPLER-Platzierung**: DIVI stellt SAMPLER in Section 2 (Anamnese), nicht am Seitenende
- **Kassenfelder**: Kostenträger-Kennz., Status, Arzt-Nr., Versichertenart-CBs immer leer

---

## Änderungen

### 1. Patientenblock (oben links, `drawPage1`)

**Entfernen:**
- `field("Krankenkasse / Kostenträger", ...)` — für FR nicht relevant
- Versichertenart-Zeile (`cb("Mitglied"...)`, `cb("Fam.-Vers."...)`, `cb("Rentner"...)`) 
- `field("Kostenträger-Kennz.", "")` — immer leer
- `field("Status", "")` — immer leer
- `field("Arzt-Nr.", "")` — immer leer
- `field("Datum", d(...))` — Duplikat (steht im Header)

**Behalten:** Name, geb. am, Geschlecht, Versicherungs-Nr., Gewicht

**Erwartetes Ergebnis:** ~40pt Platzgewinn im linken oberen Bereich

---

### 2. Titelblock (EINSATZPROTOKOLL-Box, `drawPage1`)

**Entfernen:**
- `valBox(p.einsatzOrt.einsatzNummer, ...)` — 3. Duplikat der Einsatznummer

**Behalten:** EINSATZPROTOKOLL-Titel, Verfasser-Checkboxen (Notfallsanitäter / Rettungssanitäter)

---

### 3. Section 1 – Rettungstechnische Daten

**Fahrzeugtypen:**
Ersetze `[("NKW", false)]` durch automatisch detektierte Checkboxen:

```swift
let fzUp = p.einsatzOrt.fahrzeugName.uppercased()
let vItems: [(String, Bool)] = [
    ("RTW", fzUp.contains("RTW")),
    ("KTW", fzUp.contains("KTW")),
    ("FR",  fzUp.contains("FR") || fzUp.contains("FIRST")),
    ("NEF", fzUp.contains("NEF")),
]
```

**Einsatz-Nr.:** Bleibt im Zeitblock (DIVI-konform), wird nur aus dem Titelblock entfernt.

**Einsatzart/Stichwort zusammenführen:**
- Entfernen: `labeledVal("Einsatzart", p.einsatzOrt.stichwort, ...)`
- Behalten: `field("Stichwort", p.einsatzOrt.stichwort, ...)` (ein Feld, eine Zeile)

**Übergabe-Zeit umbenennen:**
- `labeledVal("Übergabe an RD", ...)` → `labeledVal("Ankunft Zielklinik", ...)`
  (entspricht dem DIVI-Terminus)

---

### 4. Section 2 – Anamnese (SAMPLER-Einbindung)

**Verschieben:** Den SAMPLER-Block (`secHeader("SAMPLER-Anamnese")` + Felder) aus dem
Ende von Seite 1 direkt in Section 2, nach den Notfallgeschehen-Feldern und vor dem
ABCDE-Grid.

**Entfernen:** Die dekorativen SAMPLER-Buchstaben (S,M,P,L,R) rechts neben den ABCDE-Zeilen
(`txt(samplerLetters[i], ...)` in der ABCDE-Schleife). Da diese keine Funktion haben,
fallen sie weg. Die ABCDE-Content-Breite wächst entsprechend (+14pt).

**Reihenfolge in Section 2:**
1. Notfallgeschehen-Felder (Erstbefund, Pat. vorgef., MANV, Unfallhergang etc.)
2. SAMPLER-Block (S/A/M/P/L/E/R als Felder)
3. ABCDE-Grid (ohne Dekorativbuchstaben rechts)

---

### 5. Section 3 – Befunde

**A+B Atmung – Zyanose entfernen:**
```swift
// Vorher:
("Zyanose", p.breathing.zyanose),  // ← entfernen
// Nachher: nicht vorhanden
```
Zyanose bleibt in E/Haut (dort klinisch korrekter Platz).

**Hautfarbe-Zeile bereinigen:**
```swift
// Vorher: 3 Felder
field("Hautfarbe", ...)   // w = (rx-lx)/3
field("Temperatur", ...)  // w = (rx-lx)/3  ← entfernen (ist in Messwerte)
field("Verletzungen", ...) // w = (rx-lx)/3

// Nachher: 2 Felder
field("Hautfarbe", ...)   // w = (rx-lx)/2
field("Verletzungen", ...) // w = (rx-lx)/2
```

---

## Nicht verändert

- Section 4 Diagnose (alle Unterabschnitte)
- Page 2 vollständig (Sections 4.2–9)
- Foto-Anhang-Seiten
- Footer
- Alle Farben, Fonts, Primitive Helpers

---

## Akzeptanzkriterien

1. Einsatznummer erscheint genau 2× (Header + Section-1-Zeitblock)
2. Datum erscheint genau 1× (Header)
3. Fahrzeugtyp-Checkboxen zeigen RTW/KTW/FR/NEF, korrekt auto-gecheckt
4. SAMPLER-Block erscheint in Section 2 (nach Notfallgeschehen, vor ABCDE)
5. Keine SAMPLER-Buchstaben neben ABCDE-Zeilen
6. Kein separater SAMPLER-Block am Ende von Seite 1
7. Zyanose erscheint nur in E/Haut (nicht in A+B Atmung)
8. Temperatur erscheint nur in Messwerte-Spalte (nicht in Hautfarbe-Zeile)
9. Hautfarbe-Zeile hat 2 Felder (Hautfarbe + Verletzungen)
10. Titelblock zeigt nur Verfasser-Checkboxen (keine Einsatznummer)
