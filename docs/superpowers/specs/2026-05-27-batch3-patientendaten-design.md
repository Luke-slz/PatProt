# Design: Batch 3 — Patientendaten

**Datum:** 2026-05-27
**Scope:** Krankenkasse im PDF, Qualifikation je Besatzungsmitglied, KV-Karten-Foto, Einsatzort PLZ + Ort

---

## 1. Datenmodell

### EinsatzOrt — PLZ + Ort

**`Models/Models.swift`** — `struct EinsatzOrt`:

```swift
var plz: String = ""
var ort: String = ""
```

Einfügen nach `var zusatz = ""`. Rückwärtskompatibel (Codable-Default).

### Qualifikation + PersonalEintrag

**`Models/Models.swift`** — neue Typen:

```swift
enum Qualifikation: String, CaseIterable, Codable {
    case ersthelfer       = "EH"
    case ersthelferE      = "EH-E"
    case rettungssanitaeter = "RS"
    case rettungsassistent  = "RA"
    case notfallsanitaeter  = "NotSan"
    case arzt             = "Arzt"
}

struct PersonalEintrag: Codable, Hashable {
    var name: String
    var qualifikation: Qualifikation = .rettungssanitaeter
}
```

### KV-Karten-Foto

**`Models/Models.swift`** — `class EinsatzProtokoll`:

```swift
@Published var kvFotos: [FotoEintrag] = []
```

In `reset()`:
```swift
kvFotos.forEach { $0.loeschen() }
kvFotos = []
```

In `apply(from:)` und `ProtokollDaten`: analog zu `medikamentFotos` — Dateinamen als `[String]` in `ProtokollDaten` speichern, `FotoEintrag`-Objekte in `apply(from:)` rekonstruieren.

---

## 2. SettingsView — Qualifikation je Besatzungsmitglied

**`Views/SettingsView.swift`**

`gespeichertesPersonal` speichert bisher `[String]` (JSON). Upgrade auf `[PersonalEintrag]`.

**Migration:** Beim Dekodieren zuerst als `[PersonalEintrag]` versuchen. Schlägt fehl → als `[String]` dekodieren und konvertieren:
```swift
PersonalEintrag(name: nameString, qualifikation: .rettungssanitaeter)
```

**UI-Änderungen:**
- Jede Person in der Liste zeigt `"Name · Qual"` (z.B. `"Max Muster · NotSan"`)
- Dialog „Person hinzufügen" bekommt einen `Picker` für `Qualifikation`
- Swipe-to-delete bleibt unverändert

---

## 3. EinsatzOrtView

### PLZ + Ort

In der Einsatzort-Section, nach `adresse`/`zusatz`:

```swift
HStack(spacing: 8) {
    TextField("PLZ", text: $protokoll.einsatzOrt.plz)
        .keyboardType(.numberPad)
        .frame(maxWidth: 80)
    TextField("Ort / Stadt", text: $protokoll.einsatzOrt.ort)
}
```

`LocationManager`-Integration: In der GPS-Callback-Funktion zusätzlich befüllen:
```swift
protokoll.einsatzOrt.plz = placemark.postalCode ?? ""
protokoll.einsatzOrt.ort = placemark.locality ?? ""
```

### PersonalPickerSheet — Qualifikation anzeigen

`PersonalPickerSheet` dekodiert `[PersonalEintrag]` statt `[String]`. Jede Zeile zeigt:
```
Max Muster                    NotSan
```
Beim Tippen wird `"Max Muster (NotSan)"` in das `sanitaeter`-Feld eingetragen.

### KV-Karten-Foto

In der Patienten-Section, nach dem `kostentraeger`-Textfeld:

```swift
// Foto-Button
Button {
    zeigeKVPicker = true
} label: {
    Label(protokoll.kvFotos.isEmpty ? "KV-Karte fotografieren" : "KV-Karte ersetzen",
          systemImage: "creditcard.viewfinder")
}

// Thumbnail wenn vorhanden
if let foto = protokoll.kvFotos.first,
   let img = UIImage(contentsOfFile: foto.bildURL.path) {
    HStack {
        Image(uiImage: img)
            .resizable().scaledToFit()
            .frame(height: 60).cornerRadius(6)
        Spacer()
        Button(role: .destructive) {
            foto.loeschen()
            protokoll.kvFotos = []
        } label: {
            Image(systemName: "trash")
        }
    }
}
```

`ImagePicker` (`.photoLibrary` + `.camera`) — analog zu `BilderView`. Maximal 1 KV-Foto (Überschreiben statt Anhängen).

---

## 4. PDFGenerator

### Krankenkasse

In `drawPage1`, nach dem `versicherungsNummer`-Block:

```swift
if !p.patientDaten.kostentraeger.isEmpty {
    field("Krankenkasse", p.patientDaten.kostentraeger, x:lx, y:y, w:rx-lx, h:11, lw:55)
    y += 11
}
```

### PLZ + Ort im Einsatzort-Feld

Bestehenden `adresseText` erweitern:

```swift
let plzOrt = [p.einsatzOrt.plz, p.einsatzOrt.ort]
    .filter { !$0.isEmpty }.joined(separator: " ")
let adresseText = [p.einsatzOrt.adresse, p.einsatzOrt.zusatz, plzOrt]
    .filter { !$0.isEmpty }.joined(separator: ", ")
```

### KV-Karten-Foto

In `drawFotoPages`, neue Gruppe:

```swift
let groups: [(String, [FotoEintrag])] = [
    ("Medikamentenplan", mediFotos),
    ("Patientenfoto",    patFotos),
    ("KV-Karte",         kvFotos),
].filter { !$1.isEmpty }
```

`drawFotoPages` bekommt `kvFotos: [FotoEintrag]` als zusätzlichen Parameter. Aufruf in `generate()` entsprechend anpassen.

### Besatzung mit Qualifikation

Keine Änderung nötig: Da `PersonalPickerSheet` jetzt `"Name (Qual)"` in `sanitaeter1..4` einträgt, erscheint die Qualifikation automatisch in der bestehenden PDF-Zeile.

---

## 5. Tests

- `einsatzOrtHatPlzUndOrt()` — `EinsatzOrt()` hat `plz == ""` und `ort == ""`
- `personalEintragMigration()` — `[String]` JSON wird korrekt zu `[PersonalEintrag]` migriert
- `kvFotosResetLeert()` — `reset()` löscht `kvFotos`

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | `plz`/`ort` in `EinsatzOrt`; `Qualifikation`-Enum; `PersonalEintrag`-Struct; `kvFotos` in `EinsatzProtokoll` + `reset()` + `apply()` |
| `PatProt/Views/SettingsView.swift` | `[String]` → `[PersonalEintrag]` + Migration + Qualifikation-Picker |
| `PatProt/Views/EinsatzOrtView.swift` | PLZ/Ort-Felder; `PersonalPickerSheet` Qualifikation; KV-Foto-Button + Thumbnail |
| `PatProt/Services/PDFGenerator.swift` | Krankenkasse-Feld; PLZ/Ort in Adresse; `kvFotos`-Gruppe in `drawFotoPages` |
| `PatProtTests/PatProtTests.swift` | 3 neue Tests |
