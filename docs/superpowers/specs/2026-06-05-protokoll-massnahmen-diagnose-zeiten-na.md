# Protokoll-Überarbeitung: Maßnahmen · Diagnosen · Zeiten · NA Design

**Datum:** 2026-06-05
**Status:** Genehmigt

## Ziel

Vier unabhängige Verbesserungen am RKN-Protokoll (PDF + App):
1. NA-Spalte aus Section 6 Maßnahmen entfernen
2. Diagnosen aus DiagnoseView automatisch in Section 4 Checkboxen übernehmen
3. Zeitraster auf eine Wertspalte vereinfachen
4. Neues "NA nachgefordert"-Toggle in KonfigurationView

---

## Change 1: NA-Spalte aus Maßnahmen (RKNPDFGenerator)

**Datei:** `Services/RKNPDFGenerator.swift` — `drawSection6`

### Aktuell
```swift
let rdX = x + 2
let naX = rdX + 9
let lblX = naX + 9   // Label beginnt bei x+20

func mRow(_ label: String, rd: Bool, na: Bool = false, atY: CGFloat) {
    cb(rd, x: rdX, y: atY+2, size: 5)
    cb(na, x: naX, y: atY+2, size: 5)   // ← immer false, nie gesetzt
    txt(label, ...)
}
// Spaltenköpfe (3×):
txt("RD", ...) ; txt("NA", ...)
```

### Neu
```swift
let rdX = x + 2
let lblX = rdX + 9   // naX fällt weg, Label rückt 9pt nach links

func mRow(_ label: String, rd: Bool, atY: CGFloat) {
    cb(rd, x: rdX, y: atY+2, size: 5)
    // kein NA-Checkbox mehr
    txt(label, ...)
}
// Nur noch:
txt("RD", ...)   // naX-Header fällt weg
```

**Auswirkung:** Alle `mRow`-Aufrufe verlieren den `na:`-Parameter (war ohnehin immer `false`). Labels gewinnen ~9pt Breite.

---

## Change 2: Diagnosen-Mapping (RKNPDFGenerator)

**Datei:** `Services/RKNPDFGenerator.swift` — `drawSection4`

### Ansatz

Lokale Hilfsfunktion in `drawSection4` prüft boolean-Flag ODER passenden Namen in `verdachtsdiagnosen`:

```swift
let vdNames = Set(protokoll.diagnose.verdachtsdiagnosen.map(\.name))
func check(_ flag: Bool, _ names: String...) -> Bool {
    flag || names.contains(where: { vdNames.contains($0) })
}
```

Jede `row()`-Zeile erhält explizit gemappte App-Diagnosen als Fallback. Nicht gematchte `verdachtsdiagnosen` erscheinen im Freitext-Feld unten.

### Vollständiges Mapping

| PDF-Checkbox | Modell-Flag | Gemappte App-Diagnosen |
|---|---|---|
| Schlaganfall | `znsSchlaganfall` | "Schlaganfall / Apoplex" |
| ICB | `znsIcb` | — |
| SAB | `znsSab` | "Subarachnoidalblutung (SAB)" |
| Krampfanfall | `znsKrampfanfall` | "Epilepsie / Krampfanfall" |
| Status Epilepticus | `znsEpilepsie` | "Epilepsie / Krampfanfall" |
| Fieberkrampf | `znsFieberkrampf` | "Fieberkrampf" |
| akutes zentral-neurol. Defizit | `znsAkutNeuro` | "Bewusstlosigkeit unklarer Genese", "TIA (transitorische ischämische Attacke)" |
| ACS | `herzAcs` | "ACS / Herzinfarkt (STEMI)", "ACS / Herzinfarkt (NSTEMI)", "Angina pectoris" |
| STEMI | `herzStemi` | "ACS / Herzinfarkt (STEMI)" |
| kardiogener Schock | `herzKardiogenerSchock` | "Hypotonie / Schock" |
| Rhythmusstörung | `herzRhythmus` | "Herzrhythmusstörung" |
| Lungenembolie | `herzLungenembolie` | "Lungenembolie" |
| dekomp. Herzinsuffizienz | `herzDekomp` | "Herzinsuffizienz / Dekompensation" |
| hypertensiver Notfall | `herzHypertonerNotfall` | "Hypertensive Krise" |
| Aortenaneurysma | `herzAortenaneurysma` | "Aortenaneurysma / Dissektion" |
| Hypotonie | `herzHypotonie` | "Hypotonie / Schock" |
| Synkope | `herzSynkope` | "Synkope", "Synkope (kardial)" |
| Herz-Kreislauf-Stillstand | `herzStillstand` | — |
| Schock unklarer Genese | `herzSchockUnklarGenese` | — |
| Asthma | `atmungAsthma` | "Asthma-Anfall" |
| Status asthm. | `atmungStatusAsthmaticus` | "Asthma-Anfall" |
| exacerbierte COPD | `atmungExazerbiert` | "COPD-Exazerbation" |
| Aspiration | `atmungAspiration` | "Fremdkörperaspiration" |
| Pneumonie / Bronchitis | `atmungPneumonie` | "Pneumonie", "Pneumonie (infektiös)" |
| Hyperventilationstetanie | `atmungHyperventilation` | "Hyperventilation" |
| LTB | `atmungLtb` | "Krupp-Syndrom" |
| Epiglottitis | `atmungEpiglottitis` | "Epiglottitis" |
| Lungenödem | `atmungLungenodem` | "Lungenödem (kardial)" |
| Pseudokrupp | `atmungPseudokrupp` | "Krupp-Syndrom" |
| Exsikkose | `stoffExsikkose` | "Exsikkose / Dehydration" |
| Hypoglycämie | `stoffHypoglykämie` | "Hypoglykämie" |
| Hyperglycämie | `stoffHyperglykämie` | "Hyperglykämie", "Diabetisches Koma" |
| Urämie/ANV | `stoffUremie` | "Urämie" |
| akutes Abdomen | `abdoAkutes` | "Akutes Abdomen", "Appendizitisverdacht", "Ileus", "Ulkus-Perforation" |
| Kolik allgemein | `abdoKoliken` | "Gallenkolik", "Nierenkolik" |
| GIB obere | `abdoGibOben` | "GI-Blutung (obere)" |
| GIB untere | `abdoGibUnten` | "GI-Blutung (untere)" |
| Gallenkolik | `abdoGallenkolik` | "Gallenkolik" |
| Nierenkolik | `abdoNierenkolik` | "Nierenkolik" |
| psych. Ausnahmezustand | `psychAkut` | "Akute Psychose / Erregungszustand" |
| psychosoz. Krise | `psychKrise` | "Psychiatrische Krise", "Panikattacke" |
| Manie | `psychManie` | "Manie" |
| Intoxikation (Psych) | `psychIntoxikation` | "Alkoholintoxikation", "Medikamenten-Intoxikation", "Drogenintoxikation" |
| Entzug/Delir | `psychEntzug` | "Alkoholentzugsdelir" |
| Suizidalität | `psychSuizidal` | "Suizidversuch" |
| Geburt | `gynGeburt` | "Drohende / stattfindende Geburt" |
| Extrauterine Gravidität | `gynExtrauterine` | "Extrauteringravidität" |
| Eklampsie | `gynEklampsie` | "Eklampsie / Präeklampsie" |
| vaginale Blutung | `gynVaginalblutung` | "Vaginale Blutung", "Fehlgeburt / Abort" |
| Schwangerschaft > 35. SSW | `gynSchwangerschaft35` | "Schwangerschaftskomplikation" |
| unkl. Fieber | `infektUnklarFieber` | "Fieber unklarer Genese" |
| Meningitis/Enzephalitis | `infektMeningitis` | "Meningitis / Enzephalitis", "Meningitis (bakteriell)" |
| hochkontag. Erreger (SARS) | `infektHighToxSars` | "COVID-19 / SARS" |
| Gastroenteritis | `infektGastro` | "Gastroenteritis" |
| Anaphylaxie Grad 1/2 | `infektAnaphylaxie12` | "Allergische Reaktion (leicht)" |
| Anaphylaxie Grad 3/4 | `infektAnaphylaxie34` | "Anaphylaxie (schwer)" |
| sept. Schock | `infektSeptSchock` | "Sepsis / septischer Schock" |
| Hitzeerschöpf./Hitzschl. | `infektHitze` | "Hitzeerschöpfung", "Hitzschlag" |
| Unterkül./Erfrierung | `infektUnterku` | "Unterkühlung" |
| Ertrinken | `infektErtrinken` | "Ertrinken / Beinaheertrinken" |
| SIDS | `infektSids` | "SIDS-Verdacht" |
| Intoxikation (Sonstiges) | `infektIntoxikation` | "Alkoholintoxikation", "Medikamenten-Intoxikation", "Drogenintoxikation" |
| palliative Situation | `infektPalliativ` | "Palliativversorgung" |
| urologische Erkrankung | `infektUrologisch` | "Harnwegsinfekt / Urosepsis" |

**Nicht gematchte App-Diagnosen** (kein Checkbox-Pendant): TIA, Migräne / Kopfschmerz, Bewusstlosigkeit unklarer Genese (wenn kein `znsAkutNeuro`), Perikarditis, Angina pectoris (wenn kein ACS), Depressionen, HELLP-Syndrom, Elektrolytentgleisung → landen in "Diagnose/Leitsymptom"-Freitextfeld.

### Freitext-Feld

```swift
// Gematchte Namen sammeln
var matchedNames: Set<String> = []
// ... (jedes check()-Aufruf trägt gematchte Namen ein)

// Ungematchte → Freitext
let unmatched = protokoll.diagnose.verdachtsdiagnosen
    .filter { !matchedNames.contains($0.name) }
    .map(\.name)

var diagText: [String] = []
if !d.leitsymptom.isEmpty { diagText.append(d.leitsymptom) }
if !unmatched.isEmpty { diagText.append(contentsOf: unmatched) }
if !d.diagnoseFreitext.isEmpty { diagText.append(d.diagnoseFreitext) }

// Adaptive Höhe
let joined = diagText.joined(separator: " · ")
let h = max(14, min(35, CGFloat(diagText.count) * 7 + 4))
labeledField("Diagnose/Leitsymptom", joined, x: lx, y: diagBottom, w: W-8, h: h)
```

---

## Change 3: Zeitraster vereinfacht (RKNPDFGenerator)

**Datei:** `Services/RKNPDFGenerator.swift` — `drawSection1` (Zeitraster-Zeilen)

### Aktuell (3-Tupel mit Links/Rechts-Split)
```swift
let tItems: [(String, String, String)] = [
    ("Alarm",          t(e.alarmzeit),    ""),
    ("Ausfahrt",       t(e.ausfahrtzeit), ""),
    ("Ankunft",        "",                t(e.ankunftzeit)),
    ("Alarmierung NA", "",                ""),          // ← immer leer, fällt weg
    ("Abfahrt",        "",                t(e.abfahrtzeit)),
    ("Übergabe",       "",                t(e.uebergabeZeit ?? e.krankenHausAnkunft)),
    ("Einsatzbereit",  "",                t(e.einsatzbereitZeit)),
    ("Ende",           "",                t(e.endeZeit)),
]
```

### Neu (2-Tupel, eine Wertspalte, 7 Zeilen)
```swift
let tItems: [(String, String)] = [
    ("Alarm",         t(e.alarmzeit)),
    ("Ausfahrt",      t(e.ausfahrtzeit)),
    ("Ankunft",       t(e.ankunftzeit)),
    ("Abfahrt",       t(e.abfahrtzeit)),
    ("Übergabe",      t(e.uebergabeZeit ?? e.krankenHausAnkunft)),
    ("Einsatzbereit", t(e.einsatzbereitZeit)),
    ("Ende",          t(e.endeZeit)),
]
```

Rendering: Label linksbündig, Wert rechtsbündig in derselben Zelle.

---

## Change 4: "NA nachgefordert" in KonfigurationView

### Modell (`Models.swift` — `EinsatzOrt`)
```swift
var naAngefordert: Bool = false   // NEU
var notarzt: Bool = false         // bleibt (bisherige Bedeutung: Notarzt vor Ort / in Konfiguration)
```

### KonfigurationView (`Views/KonfigurationView.swift`)
Unter dem bestehenden "Notarzt"-Toggle:
```swift
Toggle("Notarzt",          isOn: $protokoll.einsatzOrt.notarzt)
Toggle("NA nachgefordert", isOn: $protokoll.einsatzOrt.naAngefordert)  // NEU
```

### RKNPDFGenerator — Section 1
Die bestehende "Notarzt nachgefordert"-Checkbox (Zeile 341: `labeledField("NA", ...)`) auf `naAngefordert` umkoppeln:
```swift
// Vorher: p.einsatzOrt.notarzt
// Nachher: p.einsatzOrt.naAngefordert
```

### PDFGenerator (Hauptprotokoll)
Zeile 412: `cb("Notarzt nachgefordert", p.einsatzOrt.naAngefordert, ...)`

---

## Dateien

| Datei | Änderung |
|---|---|
| `Models/Models.swift` | `naAngefordert: Bool` zu `EinsatzOrt` hinzufügen |
| `Views/KonfigurationView.swift` | Toggle "NA nachgefordert" hinzufügen |
| `Services/RKNPDFGenerator.swift` | NA-Spalte entfernen, Mapping einbauen, Zeitraster vereinfachen, `naAngefordert` einbinden |
| `Services/PDFGenerator.swift` | `naAngefordert` statt `notarzt` für "Notarzt nachgefordert" |
