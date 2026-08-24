# Befunderhebung Redesign

**Datum:** 2026-05-22  
**Projekt:** PatProt (DLRG EMS Protokoll App)  
**Scope:** Komplettes Redesign der Befunderhebung-Sektion

---

## Ziel

Die Befunderhebung soll klarer strukturiert sein mit mehr tippbaren Elementen statt langer Formulare. Jeder Menüpunkt führt zu einem fokussierten Screen. Maximale Auswahlfelder (Multi-/Single-Select), minimaler Freitext — aber immer Freitext als Fallback. Standard iOS-Zurück-Navigation überall (kein `navigationBarBackButtonHidden`, Wisch-zurück-Geste funktioniert).

---

## Navigation

### Neue `iPhoneAppStep` Cases

```swift
case konfiguration    // Einsatzort + Einsatzart
case einsatzzeiten    // nur Zeitfelder
case patient          // Patient + klinische Angaben
```

`.einsatzOrt` bleibt als Legacy-Case bestehen (für bestehende Referenzen).

### iPhoneMenuView Änderungen

| Menüpunkt | Bisher | Neu |
|---|---|---|
| Konfiguration | `.settings` | `.konfiguration` |
| Einsatzzeiten | `.einsatzOrt` | `.einsatzzeiten` |
| Rettungstechnische Daten | `.einsatzOrt` | `.patient` |
| Notfallgeschehen | `.notfallGeschehen` | `.notfallGeschehen` (neu gestaltet) |
| Diagnosen | `.diagnose` | `.diagnose` (neu gestaltet) |
| Befunde | `.abcde` | `.abcde` (vereinfacht) |

---

## Neue Views

### KonfigurationView
**Step:** `.konfiguration`  
**Inhalt:**
- Section „Einsatzort": Adresse (TextField), Zusatz (TextField), Einsatz-Nr. (Numpad), GPS-Button
- Section „Einsatzart": Stichwort-Picker (bestehender StichwortPickerSheet), Fahrzeug-Picker

Datenbindung: `protokoll.einsatzOrt` (bestehend)

---

### EinsatzzeitenView
**Step:** `.einsatzzeiten`  
**Inhalt:**
- DatePicker: Alarmzeit, Abfahrtzeit, Ankunftzeit, KH-Ankunft
- Validierungsfehler als roter Footer (bestehende `zeitFehler`-Logik)

Datenbindung: `protokoll.einsatzOrt` (bestehend)

---

### PatientView
**Step:** `.patient`  
**Inhalt:**
- Section „Patient": Vorname, Nachname, Geburtsdatum (Numpad), Geschlecht (Picker), Gewicht (Numpad)
- Section „Klinische Angaben": Versicherungsträger, Versicherungsnummer, behandelnder Arzt (Freitext)

Datenbindung: `protokoll.patientDaten` (bestehend)

---

## Notfallgeschehen — Redesign

### Übersicht-Screen
Navigationsliste mit 7 tippbaren Zeilen (chevron.right, Badge zeigt ob ausgefüllt):

1. Unfallhergang
2. Unfallmechanismus
3. Pre Emergency Status
4. NACA-Score
5. Erstbefund bei Ankunft
6. Verlaufsbemerkungen
7. Dynamische Erweiterung

### Neue Modell-Felder (`NotfallgeschehenBefund`)

```swift
var unfallhergangAuswahl: [String] = []       // Multi-Select
var unfallhergangFreitext: String = ""
var unfallmechanismus: String = ""             // Single-Select
var unfallmechanismusFreitext: String = ""
var preEmergencyStatus: String = ""            // Single-Select
var nacaScore: Int? = nil                      // 0–7
var erstbefundAuswahl: [String] = []           // Multi-Select
var verlaufsbemerkungen: String = ""
var dynamischeErweiterung: String = ""
```

Bestehende Felder `erstbefundVorOrt`, `patientGefunden`, `ersthelferMassnahmen`, `anzahlBeteiligte`, `manv` etc. bleiben erhalten.

### Subviews

#### UnfallhergangView
Multi-Select Chips in zwei Gruppen. Mehrfachauswahl möglich.

**Trauma:**
KFZ-Insasse · Motorradfahrer · Fahrradfahrer · Fußgänger · Zug/Schiff · Sturz >3m · Sturz <3m · Schlag (Gegenstand) · Schuss · Stich · Gewaltverbrechen · Maschinenunfall/Einklemmung · Verschüttung

**Medizinisch:**
Plötzlicher Kollaps · Bewusstlosigkeit · Krampfanfall · Brustschmerz · Atemnot · Allergische Reaktion · Suizidversuch · Intoxikation · Ertrinken/Beinaheertrinken

**Sonstiges:**
andere Unfallarten · nicht bekannt

Freitext: „Ergänzungen / Sonstiges"

#### UnfallmechanismusView
Single-Select Liste (nur einer auswählbar):
Stumpfes Trauma · Penetrierendes Trauma · Explosionstrauma · Verbrennung/Verbrühung · Inhalationstrauma · Elektrounfall · Barotrauma · Kein Trauma (internistisch) · Unbekannt

Freitext: „Ergänzungen"

#### PreEmergencyStatusView
Single-Select Liste:
Gut (selbstständig) · Reduziert (hilfsbedürftig) · Chronisch krank · Demenziell verändert · Pflegebedürftig · Unbekannt

#### NACASoreView
Picker oder Segmented mit Beschreibung je Stufe:
- 0 – Kein Schaden
- 1 – Geringfügige Störung
- 2 – Ambulante Abklärung
- 3 – Stationäre Behandlung
- 4 – Akute Lebensgefahr nicht auszuschließen
- 5 – Akute Lebensgefahr
- 6 – Reanimation
- 7 – Tod

#### ErstbefundView
Multi-Select Chips + Freitext:
Ansprechbar · Verwirrt · Bewusstlos · Liegend · Sitzend · Stehend · Schnappatmung · Atemstillstand · Pulslos · Krampfend

Freitext: `erstbefundVorOrt` (bestehendes Feld)

#### VerlaufsbemerkungView
Zustandschips (schnelle Auswahl): Stabil · Leicht verbessert · Verbessert · Leicht verschlechtert · Verschlechtert · Kritisch verschlechtert

Freitext: `verlaufsbemerkungen`

#### DynamischeErweiterungView
Freitext (TextEditor): `dynamischeErweiterung`  
Hint: Besonderheiten, MANV-Details, Nachforderungen

---

## Diagnosen — Redesign

### Übersicht-Screen
- Suchleiste oben (filtert Kategorien und Diagnosen)
- Subtitle: „Tippe eine Kategorie an"
- Gruppierte List-Sections (wie Bild 1)

### Kategorien und Diagnosen

| Kategorie | Diagnosen |
|---|---|
| ZNS Erkrankungen | Schlaganfall/Apoplex · TIA · Epilepsie/Krampfanfall · Synkope · Bewusstlosigkeit unklarer Genese · Meningitis/Enzephalitis · Migräne/Kopfschmerz |
| Herz-Kreislauf | ACS/Herzinfarkt · Angina pectoris · Herzrhythmusstörung · Herzinsuffizienz · Hypertensive Krise · Hypotonie/Schock · Perikarditis |
| Atemwegserkrankungen | COPD-Exazerbation · Asthma-Anfall · Pneumonie · Lungenödem · Lungenembolie · Hyperventilation · Fremdkörperaspiration |
| Abdominelle Erkrankungen | Akutes Abdomen · Appendizitisverdacht · Übelkeit/Erbrechen · GI-Blutung · Nierenkolik · Ileus · Gallenkolik |
| Psychiatrische Erkrankungen / Intoxikation | Psychose/Erregungszustand · Suizidversuch · Alkoholintoxikation · Medikamenten-/Drogenintoxikation · Panikattacke · Depression |
| Stoffwechsel Erkrankungen | Hypoglykämie · Hyperglykämie/Diabetisches Koma · Elektrolytentgleisung · Schilddrüsenkrise · Addison-Krise |
| Gyn-/Geburtshilfe Notfälle | Geburt/drohende Geburt · Schwangerschaftskomplikation · Eklampsie/Präeklampsie · Extrauteringravidität · Fehlgeburt |
| sonst. Erkrankungen | Allergische Reaktion · Anaphylaxie · Hitzenotfall · Kältenotfall/Unterkühlung · Ertrinken/Beinaheertrinken |
| Infektionen | Sepsis · Fieber unklarer Genese · Meningitis (infektiös) · Gastroenteritis |
| Traumen und Verletzungen | SHT (leicht/mittel/schwer) · Wirbelsäulenverletzung · Thoraxtrauma · Abdominaltrauma · Extremitätentrauma · Polytrauma · Verbrennung/Verbrühung · Stromunfall |

### DiagnoseKategorieView
- Liste der Diagnosen der gewählten Kategorie
- Antippen = Diagnose als Verdachtsdiagnose hinzufügen (Wahrscheinlichkeit: „Möglich" als Default)
- Bereits hinzugefügte Diagnosen zeigen Checkmark
- Bestehende Trichter-Logik (`DiagnoseWahrscheinlichkeit`) bleibt erhalten

### Freitext-Eingabe
Verbleibt als „+" Button oben rechts für manuelle Eingabe (bestehendes Sheet)

---

## Befunde (ABCDEUebersichtView) — Vereinfachung

### Entfernt
- SAMPLER-Schema Button
- Diagnose (Trichter) Button
- Verlauf & Therapie Button
- Maßnahmen Button
- SINNHAFT-Schema Button
- Bilder & Dateien Button
- Reanimations-Toggle + Button

### Behalten
- Kritisch / Nicht kritisch Buttons (oben)
- A · B · C · D · E Zeilen (mit Status-Buttons und Navigation zu Detailviews)

---

## Modell-Änderungen

### NotfallgeschehenBefund (neue Felder)
```swift
var unfallhergangAuswahl: [String] = []
var unfallhergangFreitext: String = ""
var unfallmechanismus: String = ""
var unfallmechanismusFreitext: String = ""
var preEmergencyStatus: String = ""
var nacaScore: Int? = nil
var erstbefundAuswahl: [String] = []
var verlaufsbemerkungen: String = ""
var dynamischeErweiterung: String = ""
```

### DiagnoseBefund
Keine Änderungen am Modell — neue UI nutzt bestehende `verdachtsdiagnosen: [VerdachtsdiagnoseEintrag]`.

---

## Badge-Anpassungen in iPhoneMenuView

Die bestehende `rtdBadge` (zählt Adresse + Patient gemeinsam) wird aufgeteilt:

- `konfigurationBadge`: `adresse`, `einsatzNummer`, `stichwort`, `fahrzeugName`
- `patientBadge`: `vorname`, `nachname`, `geburtsDatum`, `geschlecht`
- `zeitenBadge`: bleibt unverändert

---

## Betroffene Dateien

| Datei | Änderung |
|---|---|
| `Models/Models.swift` | Neue Felder in `NotfallgeschehenBefund` |
| `ContentView 2.swift` | Neue Step-Cases + NavigationDestinations |
| `Views/iPhoneMenuView.swift` | Step-Mapping für Konfiguration/Zeiten/Patient |
| `Views/EinsatzOrtView.swift` | Aufgeteilt in 3 Views (Datei bleibt als Legacy) |
| `Views/NotfallgeschehenView.swift` | Komplett ersetzt durch Navigationsliste + Subviews |
| `Views/DiagnoseView.swift` | Ersetzt durch Kategorieliste + DiagnoseKategorieView |
| `Views/ABCDEUebersichtView.swift` | Vereinfacht (Navigation-Buttons entfernt) |
| `Views/KonfigurationView.swift` | Neu |
| `Views/EinsatzzeitenView.swift` | Neu |
| `Views/PatientView.swift` | Neu |
