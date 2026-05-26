# Übergabe-Befunde – Design

**Datum:** 2026-05-26  
**Ziel:** Vollständige RKN-konforme Übergabe-Befunde-View mit Ankunft/Übergabe-Doppelcheckboxen + PDF Section 3 Neugestaltung  
**Referenz:** https://rettungsdienst.rhein-kreis-neuss.de/wp-content/uploads/2017/05/RD-Protokoll-RKN-2017.jpg  
**Scope:** Models.swift · ABCDEDetailViews.swift · BreathingView · CirculationView · DisabilityView · ExposureView · UebergabeBefundeView (neu) · iPhoneMenuView · iPadMainView · PDFGenerator.swift (drawPage1 Section 3)

---

## A — Modell

### A1 — Ergänzungen an bestehenden Structs

#### `BreathingBefund` — neue Felder (nach `beatmungsform`)
```swift
var spastik:          Bool = false
var rasselgeraeusche: Bool = false   // war vorher nur String atemgeraeusche
var stridor:          Bool = false
var schnappatmung:    Bool = false
var apnoe:            Bool = false
var hyperventilation: Bool = false
var abNichtBeurteilbar: Bool = false
```

#### `CirculationBefund` — neue Felder (nach `freitext`)
```swift
var rekapillierung:          Bool = false   // Rekap. > 2 Sek.
var sinusrhythmus:           Bool = false
var absoluteArrhythmie:      Bool = false
var avBlock:                 Bool = false   // AV-Block II°/III°
var qrsTachykardieBreit:     Bool = false
var qrsTachykardieSchmal:    Bool = false
var kammerflattern:          Bool = false
var pea:                     Bool = false   // pulslose elektr. Aktivität
var asystolie:               Bool = false
var schrittmacher:           Bool = false
var infarktEkg:              Bool = false   // STEMI/LSB
var sves:                    Bool = false
var ves:                     Bool = false
var extrasystolenMonomorph:  Bool = false
var extrasystolenPolymorph:  Bool = false
var cNichtBeurteilbar:       Bool = false
```

#### `DisabilityBefund` — neue Felder (nach `befastSymptombeginn`)

Bewusstseinslage:
```swift
var bewWach:            Bool = false
var bewAnsprache:       Bool = false
var bewSchmerzreiz:     Bool = false
var bewusstlos:         Bool = false
var dNichtBeurteilbar:  Bool = false
```

Pupillen strukturiert (ersetzt/ergänzt die bisherigen String-Felder):
```swift
// Rechts
var pupilleReEng:             Bool = false
var pupilleReMittel:          Bool = true
var pupilleReWeit:            Bool = false
var pupilleReEntrundet:       Bool = false
var pupilleReNichtBeurteilbar:Bool = false
var pupilleReKeineLichtreaktion: Bool = false
// Links
var pupilleLiEng:             Bool = false
var pupilleLiMittel:          Bool = true
var pupilleLiWeit:            Bool = false
var pupilleLiEntrundet:       Bool = false
var pupilleLiNichtBeurteilbar:Bool = false
var pupilleLiKeineLichtreaktion: Bool = false
```

Neurologische Auffälligkeiten:
```swift
var neuroVorbestehendesDefizit: Bool = false
var neuroFacialisparese:        Bool = false
var neuroArmparese:             Bool = false
var neuroSprachstoerung:        Bool = false
var neuroSehstoerung:           Bool = false
var neuroBabinski:              Bool = false
var neuroQuerschnitt:           Bool = false
var neuroMeningismus:           Bool = false
var neuroDemenz:                Bool = false
var neuroNichtBeurteilbar:      Bool = false
```

#### `ExposureBefund` — neue Haut-Felder (nach `freitext`)
```swift
var hautNichtUntersucht:   Bool = false
var stehendeHautfalten:    Bool = false
var kaltschweissig:        Bool = false
var dekubitus:             Bool = false
var exanthem:              Bool = false
var hautNichtBeurteilbar:  Bool = false
```

### A2 — Neuer Struct `PsycheBefund`

```swift
// MARK: - Psyche
struct PsycheBefund: Codable {
    var unauffaellig:      Bool = false
    var aengstlich:        Bool = false
    var wahnhaft:          Bool = false
    var suizidal:          Bool = false
    var erregt:            Bool = false
    var verlangsamt:       Bool = false
    var depressiv:         Bool = false
    var euphorisch:        Bool = false
    var verwirrt:          Bool = false
    var motorischUnruhig:  Bool = false
    var nichtBeurteilbar:  Bool = false
    var aggressiv:         Bool = false
}
```

In `EinsatzProtokoll` nach `exposure`:
```swift
@Published var psyche = PsycheBefund()
```

### A3 — Neuer Struct `UebergabeBefunde`

```swift
// MARK: - Übergabe-Befunde
struct UebergabeBefunde: Codable {
    // A+B Atmung
    var abUnauffaellig:     Bool = false
    var dyspnoe:            Bool = false
    var zyanose:            Bool = false
    var spastik:            Bool = false
    var rasselgeraeusche:   Bool = false
    var stridor:            Bool = false
    var atemwegsverlegung:  Bool = false
    var schnappatmung:      Bool = false
    var apnoe:              Bool = false
    var beatmung:           Bool = false
    var hyperventilation:   Bool = false
    var abNichtBeurteilbar: Bool = false

    // C Kreislauf + EKG
    var cUnauffaellig:          Bool = false
    var rekapillierung:         Bool = false
    var sinusrhythmus:          Bool = false
    var absoluteArrhythmie:     Bool = false
    var avBlock:                Bool = false
    var qrsTachykardieBreit:    Bool = false
    var qrsTachykardieSchmal:   Bool = false
    var kammerflattern:         Bool = false
    var pea:                    Bool = false
    var asystolie:              Bool = false
    var schrittmacher:          Bool = false
    var infarktEkg:             Bool = false
    var sves:                   Bool = false
    var ves:                    Bool = false
    var extrasystolenMonomorph: Bool = false
    var extrasystolenPolymorph: Bool = false
    var cNichtBeurteilbar:      Bool = false

    // D Neurologie
    var dUnauffaellig:      Bool = false
    var bewWach:            Bool = false
    var bewAnsprache:       Bool = false
    var bewSchmerzreiz:     Bool = false
    var bewusstlos:         Bool = false
    var dNichtBeurteilbar:  Bool = false
    // Pupillen Übergabe
    var pupilleReEng:             Bool = false
    var pupilleReMittel:          Bool = true
    var pupilleReWeit:            Bool = false
    var pupilleReEntrundet:       Bool = false
    var pupilleReNichtBeurteilbar:Bool = false
    var pupilleReKeineLichtreaktion: Bool = false
    var pupilleLiEng:             Bool = false
    var pupilleLiMittel:          Bool = true
    var pupilleLiWeit:            Bool = false
    var pupilleLiEntrundet:       Bool = false
    var pupilleLiNichtBeurteilbar:Bool = false
    var pupilleLiKeineLichtreaktion: Bool = false
    // Neuro Auffälligkeiten Übergabe
    var neuroVorbestehendesDefizit: Bool = false
    var neuroFacialisparese:        Bool = false
    var neuroArmparese:             Bool = false
    var neuroSprachstoerung:        Bool = false
    var neuroSehstoerung:           Bool = false
    var neuroBabinski:              Bool = false
    var neuroQuerschnitt:           Bool = false
    var neuroMeningismus:           Bool = false
    var neuroDemenz:                Bool = false
    var neuroNichtBeurteilbar:      Bool = false
    // GCS Übergabe
    var gcsAugen:  Int = 4
    var gcsVerbal: Int = 5
    var gcsMotor:  Int = 6
    // Schmerz Übergabe
    var schmerz: Int = 0
}
```

In `EinsatzProtokoll` nach `uebergabeMesswerte`:
```swift
@Published var uebergabeBefunde = UebergabeBefunde()
```

### A4 — Serialisierung

In `ProtokollDaten`, `toDaten()`, `apply(from:)` und `reset()` alle vier neuen/erweiterten Felder eintragen:
- `psyche: PsycheBefund`
- `uebergabeBefunde: UebergabeBefunde`
- Die erweiterten Struct-Felder werden automatisch durch Codable-Synthese serialisiert (kein explizites Eintragen in toDaten nötig, da die Structs selbst Codable sind)

---

## B — Bestehende ABCDE-Views erweitern

### B1 — BreathingView (in `ABCDEDetailViews.swift`)

Neue Section „Atemgeräusche / Atemstörungen" nach der Beatmungs-Section:
```
CheckboxRow("Spastik",           isOn: $befund.spastik)
CheckboxRow("Rasselgeräusche",   isOn: $befund.rasselgeraeusche)
CheckboxRow("Stridor",           isOn: $befund.stridor)
CheckboxRow("Schnappatmung",     isOn: $befund.schnappatmung)
CheckboxRow("Apnoe",             isOn: $befund.apnoe)
CheckboxRow("Hyperventilation",  isOn: $befund.hyperventilation)
CheckboxRow("Nicht beurteilbar", isOn: $befund.abNichtBeurteilbar)
```

### B2 — CirculationView (in `ABCDEDetailViews.swift`)

Neue Section „EKG-Rhythmus":
```
CheckboxRow("Sinusrhythmus",           isOn: $befund.sinusrhythmus)
CheckboxRow("Absolute Arrhythmie",     isOn: $befund.absoluteArrhythmie)
CheckboxRow("AV-Block II°/III°",       isOn: $befund.avBlock)
CheckboxRow("QRS-Tachykardie breit",   isOn: $befund.qrsTachykardieBreit)
CheckboxRow("QRS-Tachykardie schmal",  isOn: $befund.qrsTachykardieSchmal)
CheckboxRow("Kammerflattern/-flimmern",isOn: $befund.kammerflattern)
CheckboxRow("Pulslose elektr. Akt.",   isOn: $befund.pea)
CheckboxRow("Asystolie",               isOn: $befund.asystolie)
CheckboxRow("Schrittmacherrhythmus",   isOn: $befund.schrittmacher)
CheckboxRow("Infarkt-EKG (STEMI/LSB)",isOn: $befund.infarktEkg)
CheckboxRow("Rekap. > 2 Sek.",         isOn: $befund.rekapillierung)
CheckboxRow("Nicht beurteilbar",       isOn: $befund.cNichtBeurteilbar)
```

Neue Section „Extrasystolen":
```
CheckboxRow("SVES",           isOn: $befund.sves)
CheckboxRow("VES",            isOn: $befund.ves)
CheckboxRow("Monomorph",      isOn: $befund.extrasystolenMonomorph)
CheckboxRow("Polymorph",      isOn: $befund.extrasystolenPolymorph)
```

### B3 — DisabilityView (in `ABCDEDetailViews.swift`)

Neue Section „Bewusstseinslage":
```
CheckboxRow("Wach",                    isOn: $befund.bewWach)
CheckboxRow("Reagiert auf Ansprache",  isOn: $befund.bewAnsprache)
CheckboxRow("Reagiert auf Schmerzreiz",isOn: $befund.bewSchmerzreiz)
CheckboxRow("Bewusstlos",              isOn: $befund.bewusstlos)
CheckboxRow("Nicht beurteilbar",       isOn: $befund.dNichtBeurteilbar)
```

Neue Section „Pupillen Rechts / Links" (je Seite):
```
// Rechts
CheckboxRow("Eng",                   isOn: $befund.pupilleReEng)
CheckboxRow("Mittel",                isOn: $befund.pupilleReMittel)
CheckboxRow("Weit",                  isOn: $befund.pupilleReWeit)
CheckboxRow("Entrundet",             isOn: $befund.pupilleReEntrundet)
CheckboxRow("Nicht beurteilbar",     isOn: $befund.pupilleReNichtBeurteilbar)
CheckboxRow("Keine Lichtreaktion",   isOn: $befund.pupilleReKeineLichtreaktion)
// Links — gleiche 6 Felder für Li
```

Neue Section „Neurologische Auffälligkeiten":
```
CheckboxRow("Vorbestehendes neurol. Defizit", isOn: $befund.neuroVorbestehendesDefizit)
CheckboxRow("Facialisparese",                 isOn: $befund.neuroFacialisparese)
CheckboxRow("Armparese",                      isOn: $befund.neuroArmparese)
CheckboxRow("Sprachstörung",                  isOn: $befund.neuroSprachstoerung)
CheckboxRow("Sehstörung",                     isOn: $befund.neuroSehstoerung)
CheckboxRow("Babinski-Zeichen",               isOn: $befund.neuroBabinski)
CheckboxRow("Querschnittsymptomatik",         isOn: $befund.neuroQuerschnitt)
CheckboxRow("Meningismus",                    isOn: $befund.neuroMeningismus)
CheckboxRow("Demenz",                         isOn: $befund.neuroDemenz)
CheckboxRow("Nicht beurteilbar",              isOn: $befund.neuroNichtBeurteilbar)
```

### B4 — ExposureView (in `ABCDEDetailViews.swift`)

Bestehende Haut-Felder erweitern:
```
CheckboxRow("Nicht untersucht",      isOn: $befund.hautNichtUntersucht)
CheckboxRow("Stehende Hautfalten",   isOn: $befund.stehendeHautfalten)
CheckboxRow("Kaltschweißig",         isOn: $befund.kaltschweissig)
CheckboxRow("Dekubitus",             isOn: $befund.dekubitus)
CheckboxRow("Exanthem",              isOn: $befund.exanthem)
CheckboxRow("Nicht beurteilbar",     isOn: $befund.hautNichtBeurteilbar)
```

Neue Section „Psyche" (zeigt PsycheBefund):
```
CheckboxRow("Unauffällig",         isOn: $protokoll.psyche.unauffaellig)
CheckboxRow("Ängstlich",           isOn: $protokoll.psyche.aengstlich)
CheckboxRow("Wahnhaft",            isOn: $protokoll.psyche.wahnhaft)
CheckboxRow("Suizidal",            isOn: $protokoll.psyche.suizidal)
CheckboxRow("Erregt",              isOn: $protokoll.psyche.erregt)
CheckboxRow("Verlangsamt",         isOn: $protokoll.psyche.verlangsamt)
CheckboxRow("Depressiv",           isOn: $protokoll.psyche.depressiv)
CheckboxRow("Euphorisch",          isOn: $protokoll.psyche.euphorisch)
CheckboxRow("Verwirrt",            isOn: $protokoll.psyche.verwirrt)
CheckboxRow("Motorisch unruhig",   isOn: $protokoll.psyche.motorischUnruhig)
CheckboxRow("Aggressiv",           isOn: $protokoll.psyche.aggressiv)
CheckboxRow("Nicht beurteilbar",   isOn: $protokoll.psyche.nichtBeurteilbar)
```

`ExposureView` benötigt dafür Zugriff auf `@ObservedObject var protokoll: EinsatzProtokoll` statt nur `@Binding var befund: ExposureBefund`. Signatur anpassen.

---

## C — Neue `UebergabeBefundeView.swift`

Eigenständige Datei. SwiftUI `Form` mit `@ObservedObject var protokoll: EinsatzProtokoll` und `var onBack: () -> Void`.

### C1 — Helper `DualCheckRow`

```swift
struct DualCheckRow: View {
    let label: String
    let ankunft: Bool          // read-only
    @Binding var uebergabe: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Ankunft-Checkbox (read-only, grau wenn nicht gesetzt)
            Image(systemName: ankunft ? "checkmark.square.fill" : "square")
                .foregroundColor(ankunft ? Color("RDOrange").opacity(0.5) : .secondary)
                .font(.title3)
                .frame(width: 32)
            // Label
            Text(label)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
            // Übergabe-Checkbox (tippbar)
            Button { uebergabe.toggle() } label: {
                Image(systemName: uebergabe ? "checkmark.square.fill" : "square")
                    .foregroundColor(uebergabe ? Color("RDOrange") : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .frame(width: 32)
        }
    }
}
```

### C2 — View-Struktur

```
Form {
    // Spaltenheader
    Section {
        HStack {
            Text("Ankunft").font(.caption).foregroundColor(.secondary).frame(width:32)
            Spacer()
            Text("Übergabe").font(.caption).foregroundColor(.secondary).frame(width:32)
        }
    }

    Section("A+B Atmung") {
        DualCheckRow("unauffällig",
            ankunft: p.breathing.status == .nicht_kritisch,
            uebergabe: $p.uebergabeBefunde.abUnauffaellig)
        DualCheckRow("Dyspnoe",
            ankunft: p.breathing.dyspnoe,
            uebergabe: $p.uebergabeBefunde.dyspnoe)
        DualCheckRow("Zyanose",       ankunft: p.breathing.zyanose,        uebergabe: $p.uebergabeBefunde.zyanose)
        DualCheckRow("Spastik",       ankunft: p.breathing.spastik,        uebergabe: $p.uebergabeBefunde.spastik)
        DualCheckRow("Rasselger.",    ankunft: p.breathing.rasselgeraeusche,uebergabe: $p.uebergabeBefunde.rasselgeraeusche)
        DualCheckRow("Stridor",       ankunft: p.breathing.stridor,        uebergabe: $p.uebergabeBefunde.stridor)
        DualCheckRow("Atemwegsverl.", ankunft: p.airway.verlegung,         uebergabe: $p.uebergabeBefunde.atemwegsverlegung)
        DualCheckRow("Schnappatmung", ankunft: p.breathing.schnappatmung,  uebergabe: $p.uebergabeBefunde.schnappatmung)
        DualCheckRow("Apnoe",         ankunft: p.breathing.apnoe,          uebergabe: $p.uebergabeBefunde.apnoe)
        DualCheckRow("Beatmung",      ankunft: p.breathing.beatmung,       uebergabe: $p.uebergabeBefunde.beatmung)
        DualCheckRow("Hyperventilat.",ankunft: p.breathing.hyperventilation,uebergabe: $p.uebergabeBefunde.hyperventilation)
        DualCheckRow("n. beurteilbar",ankunft: p.breathing.abNichtBeurteilbar,uebergabe: $p.uebergabeBefunde.abNichtBeurteilbar)
    }

    Section("C Kreislauf + EKG") {
        DualCheckRow("unauffällig",       ankunft: p.circulation.status == .nicht_kritisch, uebergabe: $p.uebergabeBefunde.cUnauffaellig)
        DualCheckRow("Rekap. > 2 Sek.",   ankunft: p.circulation.rekapillierung,   uebergabe: $p.uebergabeBefunde.rekapillierung)
        DualCheckRow("Sinusrhythmus",     ankunft: p.circulation.sinusrhythmus,     uebergabe: $p.uebergabeBefunde.sinusrhythmus)
        DualCheckRow("Abs. Arrhythmie",   ankunft: p.circulation.absoluteArrhythmie,uebergabe: $p.uebergabeBefunde.absoluteArrhythmie)
        DualCheckRow("AV-Block II°/III°", ankunft: p.circulation.avBlock,           uebergabe: $p.uebergabeBefunde.avBlock)
        DualCheckRow("QRS-Tachy breit",   ankunft: p.circulation.qrsTachykardieBreit,uebergabe: $p.uebergabeBefunde.qrsTachykardieBreit)
        DualCheckRow("QRS-Tachy schmal",  ankunft: p.circulation.qrsTachykardieSchmal,uebergabe: $p.uebergabeBefunde.qrsTachykardieSchmal)
        DualCheckRow("Kammerflattern",    ankunft: p.circulation.kammerflattern,    uebergabe: $p.uebergabeBefunde.kammerflattern)
        DualCheckRow("PEA",               ankunft: p.circulation.pea,               uebergabe: $p.uebergabeBefunde.pea)
        DualCheckRow("Asystolie",         ankunft: p.circulation.asystolie,         uebergabe: $p.uebergabeBefunde.asystolie)
        DualCheckRow("Schrittmacher",     ankunft: p.circulation.schrittmacher,     uebergabe: $p.uebergabeBefunde.schrittmacher)
        DualCheckRow("Infarkt-EKG",       ankunft: p.circulation.infarktEkg,        uebergabe: $p.uebergabeBefunde.infarktEkg)
        // Extrasystolen
        DualCheckRow("SVES",              ankunft: p.circulation.sves,              uebergabe: $p.uebergabeBefunde.sves)
        DualCheckRow("VES",               ankunft: p.circulation.ves,               uebergabe: $p.uebergabeBefunde.ves)
        DualCheckRow("Monomorph",         ankunft: p.circulation.extrasystolenMonomorph, uebergabe: $p.uebergabeBefunde.extrasystolenMonomorph)
        DualCheckRow("Polymorph",         ankunft: p.circulation.extrasystolenPolymorph, uebergabe: $p.uebergabeBefunde.extrasystolenPolymorph)
        DualCheckRow("n. beurteilbar",    ankunft: p.circulation.cNichtBeurteilbar, uebergabe: $p.uebergabeBefunde.cNichtBeurteilbar)
    }

    Section("D Neurologie") {
        DualCheckRow("unauffällig",           ankunft: p.disability.status == .nicht_kritisch,  uebergabe: $p.uebergabeBefunde.dUnauffaellig)
        // Bewusstseinslage
        DualCheckRow("Wach",                  ankunft: p.disability.bewWach,         uebergabe: $p.uebergabeBefunde.bewWach)
        DualCheckRow("Reagiert Ansprache",    ankunft: p.disability.bewAnsprache,    uebergabe: $p.uebergabeBefunde.bewAnsprache)
        DualCheckRow("Reagiert Schmerz",      ankunft: p.disability.bewSchmerzreiz,  uebergabe: $p.uebergabeBefunde.bewSchmerzreiz)
        DualCheckRow("Bewusstlos",            ankunft: p.disability.bewusstlos,      uebergabe: $p.uebergabeBefunde.bewusstlos)
        DualCheckRow("n. beurteilbar",        ankunft: p.disability.dNichtBeurteilbar, uebergabe: $p.uebergabeBefunde.dNichtBeurteilbar)
        // Pupillen re
        Text("Pupillen rechts").font(.caption).foregroundColor(.secondary)
        DualCheckRow("eng",              ankunft: p.disability.pupilleReEng,              uebergabe: $p.uebergabeBefunde.pupilleReEng)
        DualCheckRow("mittel",           ankunft: p.disability.pupilleReMittel,           uebergabe: $p.uebergabeBefunde.pupilleReMittel)
        DualCheckRow("weit",             ankunft: p.disability.pupilleReWeit,             uebergabe: $p.uebergabeBefunde.pupilleReWeit)
        DualCheckRow("entrundet",        ankunft: p.disability.pupilleReEntrundet,        uebergabe: $p.uebergabeBefunde.pupilleReEntrundet)
        DualCheckRow("n. beurteilbar",   ankunft: p.disability.pupilleReNichtBeurteilbar, uebergabe: $p.uebergabeBefunde.pupilleReNichtBeurteilbar)
        DualCheckRow("keine Lichtreakt.",ankunft: p.disability.pupilleReKeineLichtreaktion,uebergabe: $p.uebergabeBefunde.pupilleReKeineLichtreaktion)
        // Pupillen li (gleiche 6)
        Text("Pupillen links").font(.caption).foregroundColor(.secondary)
        DualCheckRow("eng",              ankunft: p.disability.pupilleLiEng,              uebergabe: $p.uebergabeBefunde.pupilleLiEng)
        DualCheckRow("mittel",           ankunft: p.disability.pupilleLiMittel,           uebergabe: $p.uebergabeBefunde.pupilleLiMittel)
        DualCheckRow("weit",             ankunft: p.disability.pupilleLiWeit,             uebergabe: $p.uebergabeBefunde.pupilleLiWeit)
        DualCheckRow("entrundet",        ankunft: p.disability.pupilleLiEntrundet,        uebergabe: $p.uebergabeBefunde.pupilleLiEntrundet)
        DualCheckRow("n. beurteilbar",   ankunft: p.disability.pupilleLiNichtBeurteilbar, uebergabe: $p.uebergabeBefunde.pupilleLiNichtBeurteilbar)
        DualCheckRow("keine Lichtreakt.",ankunft: p.disability.pupilleLiKeineLichtreaktion,uebergabe: $p.uebergabeBefunde.pupilleLiKeineLichtreaktion)
        // GCS
        HStack {
            Text("GCS \(p.disability.gcsGesamt)/15")
                .foregroundColor(.secondary).font(.callout)
            Spacer()
            Text("GCS Übergabe")
            Stepper("\(p.uebergabeBefunde.gcsAugen + p.uebergabeBefunde.gcsVerbal + p.uebergabeBefunde.gcsMotor)/15",
                    value: .constant(0))  // Stepper per Subkomponente
        }
        // Neuro Auffälligkeiten
        DualCheckRow("Vorb. neurol. Defizit", ankunft: p.disability.neuroVorbestehendesDefizit, uebergabe: $p.uebergabeBefunde.neuroVorbestehendesDefizit)
        DualCheckRow("Facialisparese",         ankunft: p.disability.neuroFacialisparese,        uebergabe: $p.uebergabeBefunde.neuroFacialisparese)
        DualCheckRow("Armparese",              ankunft: p.disability.neuroArmparese,             uebergabe: $p.uebergabeBefunde.neuroArmparese)
        DualCheckRow("Sprachstörung",          ankunft: p.disability.neuroSprachstoerung,        uebergabe: $p.uebergabeBefunde.neuroSprachstoerung)
        DualCheckRow("Sehstörung",             ankunft: p.disability.neuroSehstoerung,           uebergabe: $p.uebergabeBefunde.neuroSehstoerung)
        DualCheckRow("Babinski-Zeichen",       ankunft: p.disability.neuroBabinski,              uebergabe: $p.uebergabeBefunde.neuroBabinski)
        DualCheckRow("Querschnittsympt.",      ankunft: p.disability.neuroQuerschnitt,           uebergabe: $p.uebergabeBefunde.neuroQuerschnitt)
        DualCheckRow("Meningismus",            ankunft: p.disability.neuroMeningismus,           uebergabe: $p.uebergabeBefunde.neuroMeningismus)
        DualCheckRow("Demenz",                 ankunft: p.disability.neuroDemenz,                uebergabe: $p.uebergabeBefunde.neuroDemenz)
        DualCheckRow("n. beurteilbar",         ankunft: p.disability.neuroNichtBeurteilbar,      uebergabe: $p.uebergabeBefunde.neuroNichtBeurteilbar)
    }

    Section("Schmerz (0–10)") {
        HStack {
            Text("Ankunft: \(p.disability.schmerz)/10").foregroundColor(.secondary)
            Spacer()
            Stepper("Übergabe: \(p.uebergabeBefunde.schmerz)/10",
                    value: $p.uebergabeBefunde.schmerz, in: 0...10)
        }
    }
}
.navigationTitle("Übergabe-Befunde")
.navigationBarBackButtonHidden(true)
.safeAreaInset(edge: .bottom) {
    Button(action: onBack) {
        Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
    }
    .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
}
```

GCS Übergabe wird per drei separater Stepper (Augen 1–4, Verbal 1–5, Motor 1–6) eingegeben.

---

## D — Navigation

### D1 — `iPhoneMenuView.swift`

Neuen Navigationsbutton zwischen Maßnahmen und Abschluss hinzufügen:
```swift
NavigationsButton(
    icon: "cross.case",
    titel: "Übergabe-Befunde",
    untertitel: uebergabeSubtitel(),
    action: { aktuelleSeite = .uebergabeBefunde }
)
```

Neue `AppSeite` (oder analog zur bestehenden Enum-Erweiterung): `.uebergabeBefunde`

Routing zur neuen `UebergabeBefundeView`.

### D2 — `iPadMainView.swift`

Analog: neuer Sidebar-Eintrag + Routing.

---

## E — PDF Section 3 Neugestaltung

### E1 — Spaltenaufteilung (Gesamtbreite lx=7 bis rx=588 = 581pt)

| Spalte | Breite | Inhalt |
|--------|--------|--------|
| Messwerte | 110pt | bereits dual Ankunft/Übergabe ✓ |
| A+B Atmung | 120pt | dual Checkboxen: cb(12) + label(96) + cb(12) |
| Schmerz/OPQRST | 40pt | vertikal zwischen A+B und C |
| C Kreislauf/EKG | 130pt | dual Checkboxen |
| D Neurologie + GCS | 181pt | dual Checkboxen + GCS-Blöcke |

Summe: 110+120+40+130+181 = 581 ✓

### E2 — Zeilenhöhe

Alle Befund-Zeilen: `h = 8.5pt` (kompakter als aktuell 11pt, um alle Zeilen auf Seite 1 unterzubringen).

### E3 — Dual-Checkbox Zeile (Hilfsfunktion)

Neue private Hilfsfunktion in `DINPDFGenerator`:
```swift
func dualCb(_ label: String, ankunft: Bool, uebergabe: Bool,
            x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
    let cbW: CGFloat = 10
    let lblW = w - 2*cbW - 4
    fillRect(CGRect(x:x, y:y, width:w, height:h), .white)
    strokeRect(CGRect(x:x, y:y, width:w, height:h))
    cb("", ankunft,  x:x+1,        y:y+1, bs:cbW-2, lw:0)
    txt(label, CGRect(x:x+cbW+2, y:y+1, width:lblW, height:h-2), font:f6)
    cb("", uebergabe, x:x+w-cbW-1, y:y+1, bs:cbW-2, lw:0)
}
```

### E4 — Abschnitte im PDF (drawPage1)

Section 3 wird komplett neu gezeichnet nach der ABCDE-Raster-Zeile. Reihenfolge:

1. `secHeader("3. Befunde", ...)` → `y += 11`
2. Subheader-Zeile: „Messwerte" | „A+B Atmung" | „Schmerz" | „C Kreislauf+EKG" | „D Neurologie"
3. Spaltenheader-Linie: in A+B/C/D je links „Ank." und rechts „Üb." in Miniaturschrift
4. Zeilenblock: Alle Zeilen in allen Spalten parallel gezeichnet (Messwerte 7 Zeilen, A+B 12 Zeilen, C 17 Zeilen, D je Gruppe)
5. `y` = Unterkante des höchsten Blocks + 2

---

## Akzeptanzkriterien

1. Build succeeds nach Modell-Änderungen
2. Alle neuen Felder in BreathingBefund, CirculationBefund, DisabilityBefund, ExposureBefund sind in den bestehenden Detail-Views sichtbar und tippbar
3. PsycheBefund-Felder sind in ExposureView sichtbar
4. `UebergabeBefundeView` zeigt für jede Zeile Ankunft-Checkbox (read-only) links und Übergabe-Checkbox (tippbar) rechts
5. Navigation: neuer Wizard-Schritt erscheint auf iPhone und iPad zwischen Maßnahmen und Abschluss
6. Serialisierung: UebergabeBefunde + PsycheBefund werden im Archiv korrekt gespeichert/geladen
7. PDF Section 3: dual Checkboxen für A+B und C, dual für D, Schmerz mit Ankunft/Übergabe-Wert
8. Build succeeds (alle Tests grün)
