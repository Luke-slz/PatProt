# RKN-Vollnachbau – Design

**Datum:** 2026-05-24  
**Ziel:** PDF so nah wie möglich an das RKN-Protokoll (Rhein-Kreis Neuss 2017) angleichen  
**Scope:** Models.swift · AbschlussView · PDFGenerator.swift (drawPage1 + drawPage2)

---

## A — Modell: Übergabe-Messwerte

Neuer Struct `UebergabeMesswerte` in `Models.swift`:

```swift
struct UebergabeMesswerte: Codable {
    var blutdruckSystolisch: Int? = nil
    var blutdruckDiastolisch: Int? = nil
    var puls: Int? = nil
    var spo2: Int? = nil
    var atemFrequenz: Int? = nil
    var blutzucker: Double? = nil
    var temperatur: Double? = nil
}
```

In `EinsatzProtokoll` hinzufügen:
```swift
var uebergabeMesswerte: UebergabeMesswerte = UebergabeMesswerte()
```

---

## B — PDF Seite 1

### B1 — Section 2 (SAMPLER): Immer alle 7 Zeilen

Aktuell: Zeilen nur wenn nicht leer.  
Neu: Alle 7 Zeilen (S / A / M / P / L / E / R) immer zeichnen, mit leerem Wertfeld wenn nichts erfasst.  
Jede Zeile: Höhe 10pt, Label-Breite 55pt.

### B2 — Section 3 (Befunde/Messwerte): Zwei Wertespalten

Messwerte-Block links hat statt einer Wertspalte **zwei**:

| Zeile     | Ankunft | Übergabe |
|-----------|---------|----------|
| RR sys.   |         |          |
| RR dia.   |         |          |
| HF /min   |         |          |
| SpO₂ %    |         |          |
| AF /min   |         |          |
| BZ        |         |          |
| Temp °C   |         |          |

Spaltenbreite des Messwerte-Blocks: ~105pt gesamt  
Davon: Label 40pt | Ankunft 30pt | Übergabe 35pt

Header-Zeile über Ankunft/Übergabe in f5-Schrift.

Werte:
- Ankunft = bestehende Felder (circulation.blutdruckSystolisch etc.)
- Übergabe = neue UebergabeMesswerte-Felder

### B3 — Section 5 (Verlauf): Von Seite 1 → Seite 2

In `drawPage1`: Verlauf-Block entfernen.  
In `drawPage2`: Verlauf nach Section 4.2 Verletzungen einfügen (vor Maßnahmen).

---

## C — PDF Seite 2: Neue Reihenfolge

```
4.2 Verletzungen (Körperkarte + Spezielle Traumen)
5.  Verlauf (Zeitraster)                          ← NEU hier
4.5 Medikamente                                   ← bleibt
6.  Maßnahmen (4 Spalten)                         ← umstrukturiert
7.  Reanimation / Tod
8.  Ergebnis / NACA
9.  Übergabe / Transportziel
```

---

## D — Section 6 (Maßnahmen): 4 Spalten nach RKN

### Spaltenaufteilung (Gesamtbreite rx-lx = 581pt):
- Spalte 1 (Airway): 145pt
- Spalte 2 (Kreislauf): 155pt
- Spalte 3 (Weitere): 145pt
- Spalte 4 (Lagerung): 136pt

### Spalte 1 – Airway / Stabilisation
```
Atemweg freimachen          (p.massnahmen.atemwegFreimachen)
Cervikalstütze / HWS        (p.massnahmen.cervikalstuetze)
Absaugung                   (p.massnahmen.absaugung)
Sauerstoffgabe              (p.massnahmen.sauerstoffGabe)
Maskenbeatmung              (p.massnahmen.maskenbeatmung)
Mask.beat. unmöglich        (p.massnahmen.maskenbeatmungUnmoeglich)
EGA supraglottisch          (p.massnahmen.egaSupraglottisch)
Atemweg erschwert           (p.massnahmen.atemwegErschwert)
CPAP  [___] mBar            (p.massnahmen.cpap + cpapMbar)
Heimlich (FK)               (p.massnahmen.heimlich)
```

### Spalte 2 – Kreislauf / Zugänge
```
Peripher-venös              (p.massnahmen.peripherVenoes)
Defibrillation  [___]J ×[_] (p.massnahmen.defibrillation + defiJoule + defiAnzahl)
Kardioversion   [___]J      (p.massnahmen.kardioversion + kardioversionJoule)
Intraossär-Zugang           (p.massnahmen.intraossaer)
Tourniquet                  (p.massnahmen.tourniquet)
Verband / Wundvers.         (p.massnahmen.verband)
Beckenschlinge              (p.massnahmen.beckenschlinge)
Krisenintervention          (p.massnahmen.krisenintervention)
Entbindung                  (p.massnahmen.entbindung)
```

### Spalte 3 – Weitere Maßnahmen
```
Wärmeerhalt                 (p.massnahmen.waermeerhalt)
Kühlung                     (p.massnahmen.kuehlung)
[Monitoring-Unterabschnitt]
SpO₂  NIBP  BZ  EKG  Temp  (checkboxes: monitoring*)
```

### Spalte 4 – Lagerung / Transport
```
OK-Hochlagerung             (p.massnahmen.okHochlagerung)
Flachlagerung               (p.massnahmen.flachlagerung)
Schocklagerung              (p.massnahmen.schocklagerung)
Herz-Tieflage               (p.massnahmen.herzTieflage)
Linksseitenlage             (p.massnahmen.linksseitenlage)
Sitzender Transport         (p.massnahmen.sitzenderTransport)
Vakuummatratze              (p.massnahmen.vakuummatratze)
Schaufeltrage               (p.massnahmen.schaufeltrage)
Extremit.schienung          (p.massnahmen.extremitaetenschienung)
```

---

## App-View: Übergabe-Messwerte

In `AbschlussView.swift`: Neue Section „Übergabe-Messwerte" mit NumpadSheet-Feldern für alle 7 Werte.  
Reihenfolge: RR sys | RR dia | HF | SpO₂ | AF | BZ | Temp

---

## Akzeptanzkriterien

1. Section 2 SAMPLER zeigt immer S/A/M/P/L/E/R (7 Zeilen)
2. Section 3 Messwerte hat Spalten „Ankunft" und „Übergabe" nebeneinander
3. PDF Seite 1 hat **keinen** Verlauf-Block mehr
4. PDF Seite 2: Reihenfolge ist 4.2 → 5 (Verlauf) → Medikamente → 6 → 7 → 8 → 9
5. Section 6 hat 4 Spalten wie oben beschrieben
6. Übergabe-Messwerte in AbschlussView eingebar
7. Build succeeds
