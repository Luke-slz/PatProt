# Befunderhebung Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign der Befunderhebung-Sektion: Konfiguration/Zeiten/Patient als fokussierte Views, Notfallgeschehen als Navigationsliste mit Auswahlfeldern, Diagnosen als Kategoriepicker, Befunde vereinfacht auf ABCDE.

**Architecture:** Drei neue fokussierte Views (KonfigurationView, EinsatzzeitenView, PatientView) ersetzen den Menü-Zugang zur monolithischen EinsatzOrtView. NotfallgeschehenView wird zur NavigationList mit 7 Subviews. DiagnoseView nutzt Kategorien statt Trichter. ABCDEUebersichtView zeigt nur A–E. Alle Views nutzen Standard iOS-Zurück-Navigation (kein navigationBarBackButtonHidden).

**Tech Stack:** SwiftUI, iOS 17+, NavigationStack (existing), @Binding, @ObservedObject

---

## Dateiübersicht

| Datei | Aktion |
|---|---|
| `Models/Models.swift` | Modify: neue Felder in NotfallgeschehenBefund |
| `ContentView 2.swift` | Modify: neue AppStep-Cases + Destinations, vereinfachte Callbacks |
| `Views/iPhoneMenuView.swift` | Modify: Step-Mapping + Badge-Split |
| `Views/EinsatzOrtView.swift` | Modify: `private` von BesatzungsFeld entfernen |
| `Views/NotfallgeschehenView.swift` | Replace: Navigationsliste + alle Subviews |
| `Views/DiagnoseView.swift` | Replace: Kategorieliste + DiagnoseKategorieView |
| `Views/ABCDEUebersichtView.swift` | Modify: NavigationsButtons entfernen, Callbacks reduzieren |
| `Views/KonfigurationView.swift` | Create: Einsatzort + Einsatzart |
| `Views/EinsatzzeitenView.swift` | Create: nur Zeitfelder |
| `Views/PatientView.swift` | Create: Patient + klinische Angaben + Besatzung |

---

## Task 1: Modell erweitern — NotfallgeschehenBefund

**Files:**
- Modify: `PatProt/PatProt/Models/Models.swift` (Zeile ~537, struct NotfallgeschehenBefund)

- [ ] **Schritt 1: Neue Felder in NotfallgeschehenBefund einfügen**

  Ersetze die Struct-Definition (Zeile 537–553) durch:

  ```swift
  struct NotfallgeschehenBefund: Codable {
      var erstbefundVorOrt = ""
      var patientGefunden = ""
      var ersthelferMassnahmen = ""
      var anzahlBeteiligte: Int = 1
      var manv: Bool = false
      var ersteEintreffendeKraft: Bool = false
      var manvSK1: Int = 0
      var manvSK2: Int = 0
      var manvSK3: Int = 0
      var manvSK4: Int = 0
      var manvVerstorben: Int = 0
      var manvLagemeldung: String = ""
      var manvNachforderung: String = ""

      // Neue Felder
      var unfallhergangAuswahl: [String] = []
      var unfallhergangFreitext: String = ""
      var unfallmechanismus: String = ""
      var unfallmechanismusFreitext: String = ""
      var preEmergencyStatus: String = ""
      var nacaScoreWert: NacaScore? = nil
      var erstbefundAuswahl: [String] = []
      var verlaufsbemerkungen: String = ""
      var dynamischeErweiterung: String = ""

      var manvGesamtSK: Int { manvSK1 + manvSK2 + manvSK3 + manvSK4 + manvVerstorben }
  }
  ```

- [ ] **Schritt 2: Build prüfen**

  Xcode → Product → Build (⌘B). Erwartetes Ergebnis: 0 Errors (neue Felder sind optional/mit Default).

- [ ] **Schritt 3: Commit**

  ```
  git add PatProt/PatProt/Models/Models.swift
  git commit -m "feat: extend NotfallgeschehenBefund with assessment fields"
  ```

---

## Task 2: BesatzungsFeld sichtbar machen

**Files:**
- Modify: `PatProt/PatProt/Views/EinsatzOrtView.swift` (Zeile ~294)

- [ ] **Schritt 1: `private` von BesatzungsFeld entfernen**

  Zeile 294 ändern von:
  ```swift
  private struct BesatzungsFeld: View {
  ```
  zu:
  ```swift
  struct BesatzungsFeld: View {
  ```

- [ ] **Schritt 2: Build prüfen** (⌘B, 0 Errors erwartet)

- [ ] **Schritt 3: Commit**

  ```
  git add PatProt/PatProt/Views/EinsatzOrtView.swift
  git commit -m "refactor: make BesatzungsFeld internal for reuse"
  ```

---

## Task 3: Neue iPhoneAppStep Cases + NavigationDestinations

**Files:**
- Modify: `PatProt/PatProt/ContentView 2.swift`

- [ ] **Schritt 1: Neue Cases zum Enum hinzufügen**

  Den Enum `iPhoneAppStep` (Zeile ~26) erweitern:

  ```swift
  enum iPhoneAppStep: Hashable {
      case einsatzOrt
      case konfiguration    // NEU
      case einsatzzeiten    // NEU
      case patient          // NEU
      case notfallGeschehen
      case abcde
      case airway, breathing, circulation, disability, exposure
      case sampler, sinnhaft, diagnose, verlauf, massnahmen, reanimation
      case bilder
      case abschluss, settings
  }
  ```

- [ ] **Schritt 2: NavigationDestinations für neue Cases einfügen**

  Im switch-Block (nach `case .einsatzOrt:`) folgende Cases ergänzen:

  ```swift
  case .konfiguration:
      KonfigurationView(protokoll: protokoll, onMenuOpen: { showMenu = true })
  case .einsatzzeiten:
      EinsatzzeitenView(protokoll: protokoll)
  case .patient:
      PatientView(protokoll: protokoll)
  ```

- [ ] **Schritt 3: NotfallgeschehenView-Aufruf vereinfachen**

  Alten Aufruf:
  ```swift
  case .notfallGeschehen:
      NotfallgeschehenView(
          befund: $protokoll.notfallGeschehen,
          onWeiter: { path.append(.abcde) },
          onBack: { path.removeLast() }
      )
  ```
  Ersetzen durch:
  ```swift
  case .notfallGeschehen:
      NotfallgeschehenView(befund: $protokoll.notfallGeschehen)
  ```

- [ ] **Schritt 4: DiagnoseView-Aufruf vereinfachen**

  Alten Aufruf:
  ```swift
  case .diagnose:
      DiagnoseView(befund: $protokoll.diagnose, onBack: { path.removeLast() })
  ```
  Ersetzen durch:
  ```swift
  case .diagnose:
      DiagnoseView(befund: $protokoll.diagnose)
  ```

- [ ] **Schritt 5: ABCDEUebersichtView-Aufruf vereinfachen**

  Alten Aufruf (viele Callbacks) ersetzen durch:
  ```swift
  case .abcde:
      ABCDEUebersichtView(
          protokoll: protokoll,
          onAirway:      { path.append(.airway) },
          onBreathing:   { path.append(.breathing) },
          onCirculation: { path.append(.circulation) },
          onDisability:  { path.append(.disability) },
          onExposure:    { path.append(.exposure) }
      )
  ```

- [ ] **Schritt 6: Build prüfen** — Es werden Fehler wegen noch fehlender Views erwartet; trotzdem prüfen ob der Enum korrekt ist.

- [ ] **Schritt 7: Commit**

  ```
  git add "PatProt/PatProt/ContentView 2.swift"
  git commit -m "feat: add konfiguration/einsatzzeiten/patient navigation steps"
  ```

---

## Task 4: iPhoneMenuView aktualisieren

**Files:**
- Modify: `PatProt/PatProt/Views/iPhoneMenuView.swift`

- [ ] **Schritt 1: Step-Mapping ändern**

  Die ersten drei `menuRow`-Aufrufe (Zeilen 17–19) ersetzen durch:
  ```swift
  menuRow("Konfiguration",           icon: "gearshape",                     step: .konfiguration,   badge: konfigurationBadge)
  menuRow("Einsatzzeiten",            icon: "clock",                         step: .einsatzzeiten,   badge: zeitenBadge)
  menuRow("Rettungstechnische Daten", icon: "doc.on.clipboard",              step: .patient,         badge: patientBadge)
  ```

- [ ] **Schritt 2: Badges aufteilen**

  Die bestehende `rtdBadge`-Computed-Property **ersetzen** durch zwei neue:
  ```swift
  private var konfigurationBadge: Int? {
      let eo = protokoll.einsatzOrt
      var count = 0
      if !eo.adresse.isEmpty       { count += 1 }
      if !eo.einsatzNummer.isEmpty { count += 1 }
      if !eo.stichwort.isEmpty     { count += 1 }
      if !eo.fahrzeugName.isEmpty  { count += 1 }
      return count > 0 ? count : nil
  }

  private var patientBadge: Int? {
      let p = protokoll.patientDaten
      var count = 0
      if !p.vorname.isEmpty         { count += 1 }
      if !p.nachname.isEmpty        { count += 1 }
      if p.geburtsDatum != nil      { count += 1 }
      if p.geschlecht != .unbekannt { count += 1 }
      return count > 0 ? count : nil
  }
  ```

- [ ] **Schritt 3: notfallBadge erweitern**

  Bestehende `notfallBadge` aktualisieren:
  ```swift
  private var notfallBadge: Int? {
      let b = protokoll.notfallGeschehen
      var count = 0
      if !b.unfallhergangAuswahl.isEmpty  { count += 1 }
      if !b.unfallmechanismus.isEmpty      { count += 1 }
      if !b.preEmergencyStatus.isEmpty     { count += 1 }
      if b.nacaScoreWert != nil            { count += 1 }
      if !b.erstbefundAuswahl.isEmpty || !b.erstbefundVorOrt.isEmpty { count += 1 }
      if !b.verlaufsbemerkungen.isEmpty    { count += 1 }
      return count > 0 ? count : nil
  }
  ```

- [ ] **Schritt 4: Build prüfen** (⌘B)

- [ ] **Schritt 5: Commit**

  ```
  git add PatProt/PatProt/Views/iPhoneMenuView.swift
  git commit -m "feat: update menu routing for split einsatz views"
  ```

---

## Task 5: KonfigurationView erstellen

**Files:**
- Create: `PatProt/PatProt/Views/KonfigurationView.swift`

- [ ] **Schritt 1: Datei erstellen**

  ```swift
  import SwiftUI

  struct KonfigurationView: View {
      @ObservedObject var protokoll: EinsatzProtokoll
      var onMenuOpen: (() -> Void)? = nil

      @StateObject private var locationManager = LocationManager()
      @AppStorage("customFahrzeuge") private var customFahrzeugeJSON: String = "[]"
      @State private var zeigeStichwortPicker = false
      @State private var zeigeEinsatzNrNumpad = false
      @State private var zeigeWeiteresEinsatzmittel = false
      @State private var neuesEinsatzmittel = ""

      private var customFahrzeuge: [String] {
          (try? JSONDecoder().decode([String].self, from: Data(customFahrzeugeJSON.utf8))) ?? []
      }

      var body: some View {
          Form {
              Section {
                  TextField("Straße und Hausnummer", text: $protokoll.einsatzOrt.adresse)
                  TextField("Zusatz (Stockwerk, Wohnung...)", text: $protokoll.einsatzOrt.zusatz)
                  HStack {
                      Text("Einsatz-Nr.")
                      Spacer()
                      Text(protokoll.einsatzOrt.einsatzNummer.isEmpty
                           ? "—" : protokoll.einsatzOrt.einsatzNummer)
                          .foregroundColor(protokoll.einsatzOrt.einsatzNummer.isEmpty ? .secondary : .primary)
                  }
                  .contentShape(Rectangle())
                  .onTapGesture { zeigeEinsatzNrNumpad = true }

                  Button {
                      locationManager.requestLocation()
                  } label: {
                      HStack {
                          Image(systemName: locationManager.isLoading ? "location.slash" : "location.fill")
                              .foregroundStyle(locationManager.isLoading ? .gray : .blue)
                          Text(locationManager.isLoading ? "Ermittle Standort…" : "Standort ermitteln")
                              .foregroundStyle(locationManager.isLoading ? .gray : .blue)
                          if locationManager.isLoading { Spacer(); ProgressView() }
                      }
                  }
                  .disabled(locationManager.isLoading)

                  if let fehler = locationManager.locationError {
                      Text(fehler).font(.caption).foregroundColor(.red)
                  }
              } header: {
                  Label("Einsatzort", systemImage: "mappin.circle")
              }

              Section {
                  HStack {
                      TextField("Einsatzart (z.B. NOTF)", text: $protokoll.einsatzOrt.stichwort)
                      Button { zeigeStichwortPicker = true } label: {
                          Image(systemName: "list.bullet").foregroundStyle(Color("RDOrange"))
                      }
                      .buttonStyle(.plain)
                  }
                  TextField("Stichwort (z.B. Bewusstlos)", text: $protokoll.einsatzOrt.einsatzArt)
                  Toggle("Sondersignal", isOn: $protokoll.einsatzOrt.sondersignal)
                  Toggle("Notarzt", isOn: $protokoll.einsatzOrt.notarzt)

                  Picker("Primärfahrzeug", selection: $protokoll.einsatzOrt.fahrzeugName) {
                      Text("—").tag("")
                      ForEach(customFahrzeuge, id: \.self) { fz in Text(fz).tag(fz) }
                  }

                  ForEach(protokoll.einsatzOrt.weitereEinsatzmittel, id: \.self) { fz in
                      HStack {
                          Image(systemName: "car.2").foregroundStyle(.secondary)
                          Text(fz)
                          Spacer()
                          Button(role: .destructive) {
                              protokoll.einsatzOrt.weitereEinsatzmittel.removeAll { $0 == fz }
                          } label: {
                              Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                          }
                          .buttonStyle(.plain)
                      }
                  }

                  Button {
                      neuesEinsatzmittel = ""; zeigeWeiteresEinsatzmittel = true
                  } label: {
                      Label("Weiteres Einsatzmittel", systemImage: "plus.circle")
                  }
              } header: {
                  Label("Einsatzart & Fahrzeuge", systemImage: "exclamationmark.triangle")
              }
          }
          .navigationTitle("Konfiguration")
          .navigationBarTitleDisplayMode(.large)
          .toolbar {
              if let openMenu = onMenuOpen {
                  ToolbarItem(placement: .navigationBarLeading) {
                      Button(action: openMenu) {
                          Image(systemName: "line.3.horizontal").font(.title3)
                      }
                  }
              }
          }
          .onChange(of: locationManager.address) { _, newAddress in
              if !newAddress.isEmpty { protokoll.einsatzOrt.adresse = newAddress }
          }
          .sheet(isPresented: $zeigeStichwortPicker) {
              StichwortPickerSheet(
                  code: $protokoll.einsatzOrt.stichwort,
                  beschreibung: $protokoll.einsatzOrt.einsatzArt
              )
          }
          .sheet(isPresented: $zeigeEinsatzNrNumpad) {
              NumpadSheet(mode: .integer(label: "Einsatz-Nr.", unit: "", maxDigits: 10),
                          initial: protokoll.einsatzOrt.einsatzNummer) { val in
                  protokoll.einsatzOrt.einsatzNummer = val
              }
          }
          .sheet(isPresented: $zeigeWeiteresEinsatzmittel) {
              EinsatzmittelPickerSheet(customFahrzeuge: customFahrzeuge) { name in
                  if !protokoll.einsatzOrt.weitereEinsatzmittel.contains(name) {
                      protokoll.einsatzOrt.weitereEinsatzmittel.append(name)
                  }
              }
          }
      }
  }
  ```

- [ ] **Schritt 2: Build prüfen** (⌘B, 0 Errors erwartet)

- [ ] **Schritt 3: Commit**

  ```
  git add PatProt/PatProt/Views/KonfigurationView.swift
  git commit -m "feat: add KonfigurationView for focused einsatzort/einsatzart editing"
  ```

---

## Task 6: EinsatzzeitenView erstellen

**Files:**
- Create: `PatProt/PatProt/Views/EinsatzzeitenView.swift`

- [ ] **Schritt 1: Datei erstellen**

  ```swift
  import SwiftUI

  struct EinsatzzeitenView: View {
      @ObservedObject var protokoll: EinsatzProtokoll

      private var zeitFehler: [String] {
          let alarm   = protokoll.einsatzOrt.alarmzeit
          let ankunft = protokoll.einsatzOrt.ankunftzeit
          let abfahrt = protokoll.einsatzOrt.abfahrtzeit
          let kh      = protokoll.einsatzOrt.krankenHausAnkunft
          var fehler: [String] = []
          if let a = alarm,   let b = ankunft, b < a { fehler.append("Ankunft liegt vor der Alarmzeit") }
          if let a = ankunft, let b = abfahrt, b < a { fehler.append("Abfahrt liegt vor der Ankunft") }
          if let a = abfahrt, let b = kh,      b < a { fehler.append("KH-Ankunft liegt vor der Abfahrt") }
          return fehler
      }

      var body: some View {
          Form {
              Section {
                  DatePicker(
                      "Alarmdatum",
                      selection: Binding(
                          get: { protokoll.einsatzOrt.alarmzeit ?? Date() },
                          set: { protokoll.einsatzOrt.alarmzeit = $0 }
                      ),
                      displayedComponents: .date
                  )
                  ZeitFeld(label: "Alarmzeit",             datum: $protokoll.einsatzOrt.alarmzeit)
                  ZeitFeld(label: "Ankunft Patient",        datum: $protokoll.einsatzOrt.ankunftzeit)
                  ZeitFeld(label: "Abfahrt Einsatzstelle",  datum: $protokoll.einsatzOrt.abfahrtzeit)
                  ZeitFeld(label: "Übergabe an RD",         datum: $protokoll.einsatzOrt.krankenHausAnkunft)
              } header: {
                  Label("Zeiten", systemImage: "clock")
              } footer: {
                  if !zeitFehler.isEmpty {
                      VStack(alignment: .leading, spacing: 2) {
                          ForEach(zeitFehler, id: \.self) { fehler in
                              Label(fehler, systemImage: "exclamationmark.triangle.fill")
                                  .font(.caption).foregroundStyle(.orange)
                          }
                      }
                  }
              }
          }
          .navigationTitle("Einsatzzeiten")
          .navigationBarTitleDisplayMode(.large)
      }
  }
  ```

- [ ] **Schritt 2: Build prüfen** (⌘B)

- [ ] **Schritt 3: Commit**

  ```
  git add PatProt/PatProt/Views/EinsatzzeitenView.swift
  git commit -m "feat: add EinsatzzeitenView for focused time entry"
  ```

---

## Task 7: PatientView erstellen

**Files:**
- Create: `PatProt/PatProt/Views/PatientView.swift`

- [ ] **Schritt 1: Datei erstellen**

  ```swift
  import SwiftUI

  struct PatientView: View {
      @ObservedObject var protokoll: EinsatzProtokoll

      @AppStorage("gespeichertesPersonal") private var personalJSON: String = "[]"
      @State private var geburtsdatumText: String = ""
      @State private var zeigeGeburtsdatumNumpad = false
      @State private var zeigeGewichtNumpad = false

      private var gespeichertesPersonal: [String] {
          (try? JSONDecoder().decode([String].self, from: Data(personalJSON.utf8))) ?? []
      }

      var body: some View {
          Form {
              Section {
                  TextField("Vorname",  text: $protokoll.patientDaten.vorname)
                  TextField("Nachname", text: $protokoll.patientDaten.nachname)
                  Picker("Geschlecht", selection: $protokoll.patientDaten.geschlecht) {
                      ForEach(Geschlecht.allCases, id: \.self) { g in
                          Text(g.rawValue).tag(g)
                      }
                  }
                  HStack {
                      Text("Geburtsdatum")
                      Spacer()
                      Text(geburtsdatumText.isEmpty ? "TT.MM.JJJJ" : geburtsdatumText)
                          .foregroundColor(geburtsdatumText.isEmpty ? .secondary : .primary)
                  }
                  .contentShape(Rectangle())
                  .onTapGesture { zeigeGeburtsdatumNumpad = true }
                  TextField("Versicherungsnummer", text: $protokoll.patientDaten.versicherungsNummer)
                  TextField("Kostenträger / Krankenkasse", text: $protokoll.patientDaten.kostentraeger)
              } header: {
                  Label("Patient", systemImage: "person.circle")
              }

              Section {
                  HStack {
                      Text("Gewicht")
                      Spacer()
                      Text(protokoll.patientDaten.gewicht.map { String(format: "%.1f kg", $0) } ?? "—")
                          .foregroundColor(protokoll.patientDaten.gewicht == nil ? .secondary : .primary)
                  }
                  .contentShape(Rectangle())
                  .onTapGesture { zeigeGewichtNumpad = true }
                  Toggle("Ansprechbar", isOn: $protokoll.patientDaten.ansprechbar)
              } header: {
                  Label("Klinische Angaben", systemImage: "stethoscope")
              }

              Section {
                  BesatzungsFeld(label: "Sanitäter 1", text: $protokoll.besatzung.sanitaeter1, personal: gespeichertesPersonal)
                  BesatzungsFeld(label: "Sanitäter 2", text: $protokoll.besatzung.sanitaeter2, personal: gespeichertesPersonal)
                  BesatzungsFeld(label: "Sanitäter 3", text: $protokoll.besatzung.sanitaeter3, personal: gespeichertesPersonal)
                  BesatzungsFeld(label: "Sanitäter 4", text: $protokoll.besatzung.sanitaeter4, personal: gespeichertesPersonal)
              } header: {
                  Label("Besatzung", systemImage: "person.2")
              } footer: {
                  if !gespeichertesPersonal.isEmpty {
                      Text("Tippe auf \(Image(systemName: "person.badge.plus")) um aus gespeichertem Personal auszuwählen.")
                          .font(.footnote).foregroundStyle(.secondary)
                  }
              }
          }
          .navigationTitle("Rettungstechnische Daten")
          .navigationBarTitleDisplayMode(.large)
          .onAppear {
              if let geb = protokoll.patientDaten.geburtsDatum {
                  let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"
                  geburtsdatumText = f.string(from: geb)
              }
          }
          .sheet(isPresented: $zeigeGeburtsdatumNumpad) {
              NumpadSheet(mode: .date(label: "Geburtsdatum"), initial: geburtsdatumText) { dateStr in
                  geburtsdatumText = dateStr
                  let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"
                  if let date = f.date(from: dateStr) { protokoll.patientDaten.geburtsDatum = date }
              }
          }
          .sheet(isPresented: $zeigeGewichtNumpad) {
              NumpadSheet(mode: .decimal(label: "Gewicht", unit: "kg"),
                          initial: protokoll.patientDaten.gewicht.map { String(format: "%.1f", $0) } ?? "") { val in
                  protokoll.patientDaten.gewicht = Double(val.replacingOccurrences(of: ",", with: "."))
              }
          }
      }
  }
  ```

- [ ] **Schritt 2: Build prüfen** (⌘B)

- [ ] **Schritt 3: Commit**

  ```
  git add PatProt/PatProt/Views/PatientView.swift
  git commit -m "feat: add PatientView for focused patient data entry"
  ```

---

## Task 8: NotfallgeschehenView komplett ersetzen

**Files:**
- Replace: `PatProt/PatProt/Views/NotfallgeschehenView.swift`

Enthält: Haupt-Navigationsliste + alle 7 Subviews + NfgZeile-Helper.

- [ ] **Schritt 1: Gesamte Datei ersetzen**

  ```swift
  import SwiftUI

  // MARK: - Hauptliste

  struct NotfallgeschehenView: View {
      @Binding var befund: NotfallgeschehenBefund

      var body: some View {
          List {
              Section {
                  NavigationLink {
                      UnfallhergangView(auswahl: $befund.unfallhergangAuswahl,
                                        freitext: $befund.unfallhergangFreitext)
                  } label: {
                      NfgZeile(
                          titel: "Unfallhergang",
                          wert: befund.unfallhergangAuswahl.isEmpty
                              ? (befund.unfallhergangFreitext.isEmpty ? nil : befund.unfallhergangFreitext)
                              : befund.unfallhergangAuswahl.prefix(2).joined(separator: ", ")
                      )
                  }
                  NavigationLink {
                      UnfallmechanismusView(auswahl: $befund.unfallmechanismus,
                                            freitext: $befund.unfallmechanismusFreitext)
                  } label: {
                      NfgZeile(
                          titel: "Unfallmechanismus",
                          wert: befund.unfallmechanismus.isEmpty ? nil : befund.unfallmechanismus
                      )
                  }
              }

              Section {
                  NavigationLink {
                      PreEmergencyStatusView(auswahl: $befund.preEmergencyStatus)
                  } label: {
                      NfgZeile(
                          titel: "Pre Emergency Status",
                          wert: befund.preEmergencyStatus.isEmpty ? nil : befund.preEmergencyStatus
                      )
                  }
                  NavigationLink {
                      NacaScoreView(score: $befund.nacaScoreWert)
                  } label: {
                      NfgZeile(
                          titel: "NACA-Score",
                          wert: befund.nacaScoreWert.map { "NACA \($0.rawValue)" }
                      )
                  }
              }

              Section {
                  NavigationLink {
                      ErstbefundView(auswahl: $befund.erstbefundAuswahl,
                                     freitext: $befund.erstbefundVorOrt)
                  } label: {
                      NfgZeile(
                          titel: "Erstbefund bei Ankunft",
                          wert: befund.erstbefundAuswahl.isEmpty
                              ? (befund.erstbefundVorOrt.isEmpty ? nil : befund.erstbefundVorOrt)
                              : befund.erstbefundAuswahl.prefix(2).joined(separator: ", ")
                      )
                  }
              }

              Section {
                  NavigationLink {
                      VerlaufsbemerkungView(bemerkung: $befund.verlaufsbemerkungen)
                  } label: {
                      NfgZeile(
                          titel: "Verlaufsbemerkungen",
                          wert: befund.verlaufsbemerkungen.isEmpty ? nil : befund.verlaufsbemerkungen
                      )
                  }
                  NavigationLink {
                      DynamischeErweiterungView(befund: $befund)
                  } label: {
                      NfgZeile(
                          titel: "Dynamische Erweiterung / MANV",
                          wert: befund.manv ? "MANV aktiv" : (befund.dynamischeErweiterung.isEmpty ? nil : "Erfasst")
                      )
                  }
              }
          }
          .navigationTitle("Notfallgeschehen")
          .navigationBarTitleDisplayMode(.large)
      }
  }

  // MARK: - Zeilenhelfer

  private struct NfgZeile: View {
      let titel: String
      let wert: String?

      var body: some View {
          VStack(alignment: .leading, spacing: 2) {
              Text(titel).font(.body)
              if let w = wert {
                  Text(w)
                      .font(.caption)
                      .foregroundColor(.secondary)
                      .lineLimit(1)
              } else {
                  Text("Nicht erfasst")
                      .font(.caption)
                      .foregroundColor(Color(.tertiaryLabel))
              }
          }
          .padding(.vertical, 2)
      }
  }

  // MARK: - Unfallhergang (Multi-Select)

  struct UnfallhergangView: View {
      @Binding var auswahl: [String]
      @Binding var freitext: String

      private let traumaOptionen = [
          "KFZ-Insasse", "Motorradfahrer", "Fahrradfahrer", "Fußgänger",
          "Zug / Schiff", "Sturz >3 m", "Sturz <3 m",
          "Schlag (Gegenstand)", "Schuss", "Stich",
          "Gewaltverbrechen", "Maschinenunfall / Einklemmung", "Verschüttung"
      ]

      private let medizinischOptionen = [
          "Plötzlicher Kollaps", "Bewusstlosigkeit", "Krampfanfall",
          "Brustschmerz", "Atemnot", "Allergische Reaktion",
          "Suizidversuch", "Intoxikation", "Ertrinken / Beinaheertrinken"
      ]

      private let sonstigesOptionen = [
          "andere Unfallarten", "nicht bekannt"
      ]

      var body: some View {
          Form {
              AuswahlSection(titel: "Trauma", optionen: traumaOptionen, auswahl: $auswahl)
              AuswahlSection(titel: "Medizinisch", optionen: medizinischOptionen, auswahl: $auswahl)
              AuswahlSection(titel: "Sonstiges", optionen: sonstigesOptionen, auswahl: $auswahl)

              Section {
                  TextField("Ergänzungen / Sonstiges", text: $freitext, axis: .vertical)
                      .lineLimit(3...6)
              } header: {
                  Text("Freitext")
              }
          }
          .navigationTitle("Unfallhergang")
          .navigationBarTitleDisplayMode(.inline)
      }
  }

  // MARK: - Unfallmechanismus (Single-Select)

  struct UnfallmechanismusView: View {
      @Binding var auswahl: String
      @Binding var freitext: String

      private let optionen = [
          "Stumpfes Trauma", "Penetrierendes Trauma", "Explosionstrauma",
          "Verbrennung / Verbrühung", "Inhalationstrauma", "Elektrounfall",
          "Barotrauma", "Kein Trauma (internistisch)", "Unbekannt"
      ]

      var body: some View {
          Form {
              Section {
                  ForEach(optionen, id: \.self) { option in
                      Button {
                          auswahl = (auswahl == option) ? "" : option
                      } label: {
                          HStack {
                              Text(option).foregroundColor(.primary)
                              Spacer()
                              if auswahl == option {
                                  Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                              }
                          }
                      }
                  }
              }
              Section {
                  TextField("Ergänzungen", text: $freitext, axis: .vertical)
                      .lineLimit(2...4)
              } header: {
                  Text("Freitext")
              }
          }
          .navigationTitle("Unfallmechanismus")
          .navigationBarTitleDisplayMode(.inline)
      }
  }

  // MARK: - Pre Emergency Status (Single-Select)

  struct PreEmergencyStatusView: View {
      @Binding var auswahl: String

      private let optionen = [
          "Gut (selbstständig)",
          "Reduziert (hilfsbedürftig)",
          "Chronisch krank",
          "Demenziell verändert",
          "Pflegebedürftig",
          "Unbekannt"
      ]

      var body: some View {
          Form {
              Section {
                  ForEach(optionen, id: \.self) { option in
                      Button {
                          auswahl = (auswahl == option) ? "" : option
                      } label: {
                          HStack {
                              Text(option).foregroundColor(.primary)
                              Spacer()
                              if auswahl == option {
                                  Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                              }
                          }
                      }
                  }
              }
          }
          .navigationTitle("Pre Emergency Status")
          .navigationBarTitleDisplayMode(.inline)
      }
  }

  // MARK: - NACA-Score

  struct NacaScoreView: View {
      @Binding var score: NacaScore?

      var body: some View {
          Form {
              Section {
                  ForEach(NacaScore.allCases, id: \.self) { naca in
                      Button {
                          score = (score == naca) ? nil : naca
                      } label: {
                          HStack {
                              Text(naca.beschreibung).foregroundColor(.primary)
                              Spacer()
                              if score == naca {
                                  Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                              }
                          }
                      }
                  }
              } footer: {
                  Text("Tippe erneut um die Auswahl aufzuheben.")
                      .font(.caption)
              }
          }
          .navigationTitle("NACA-Score")
          .navigationBarTitleDisplayMode(.inline)
      }
  }

  // MARK: - Erstbefund (Multi-Select + Freitext)

  struct ErstbefundView: View {
      @Binding var auswahl: [String]
      @Binding var freitext: String

      private let optionen = [
          "Ansprechbar", "Verwirrt", "Bewusstlos",
          "Liegend", "Sitzend", "Stehend",
          "Schnappatmung", "Atemstillstand", "Pulslos", "Krampfend"
      ]

      var body: some View {
          Form {
              AuswahlSection(titel: "Zustand bei Erstkontakt", optionen: optionen, auswahl: $auswahl)
              Section {
                  TextField("Freitext (Zustand bei Ankunft)", text: $freitext, axis: .vertical)
                      .lineLimit(3...8)
              } header: {
                  Text("Ergänzungen")
              }
          }
          .navigationTitle("Erstbefund")
          .navigationBarTitleDisplayMode(.inline)
      }
  }

  // MARK: - Verlaufsbemerkungen

  struct VerlaufsbemerkungView: View {
      @Binding var bemerkung: String

      private let schnellauswahl = [
          "Stabil", "Leicht verbessert", "Verbessert",
          "Leicht verschlechtert", "Verschlechtert", "Kritisch verschlechtert"
      ]

      var body: some View {
          Form {
              Section {
                  ForEach(schnellauswahl, id: \.self) { chip in
                      Button {
                          let aktuell = bemerkung.trimmingCharacters(in: .whitespaces)
                          if aktuell == chip {
                              bemerkung = ""
                          } else {
                              bemerkung = chip
                          }
                      } label: {
                          HStack {
                              Text(chip).foregroundColor(.primary)
                              Spacer()
                              if bemerkung.trimmingCharacters(in: .whitespaces) == chip {
                                  Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                              }
                          }
                      }
                  }
              } header: {
                  Text("Schnellauswahl")
              }
              Section {
                  TextField("Freitext Verlauf", text: $bemerkung, axis: .vertical)
                      .lineLimit(3...8)
              } header: {
                  Text("Freitext")
              }
          }
          .navigationTitle("Verlaufsbemerkungen")
          .navigationBarTitleDisplayMode(.inline)
      }
  }

  // MARK: - Dynamische Erweiterung / MANV

  struct DynamischeErweiterungView: View {
      @Binding var befund: NotfallgeschehenBefund

      var body: some View {
          Form {
              Section {
                  TextField("Besonderheiten, Nachforderungen, Notizen…",
                            text: $befund.dynamischeErweiterung, axis: .vertical)
                      .lineLimit(4...12)
              } header: {
                  Text("Dynamische Erweiterung")
              }

              Section {
                  Stepper("Anzahl Beteiligte: \(befund.anzahlBeteiligte)",
                          value: $befund.anzahlBeteiligte, in: 1...999)
                  Toggle("MANV-Lage", isOn: $befund.manv).tint(.red)
                  if befund.manv {
                      Toggle("1. Eintreffende Kraft", isOn: $befund.ersteEintreffendeKraft)
                          .tint(Color("RDOrange"))
                  }
              } header: {
                  Label("Besonderheiten", systemImage: "exclamationmark.triangle.fill")
              }

              if befund.manv && befund.ersteEintreffendeKraft {
                  Section {
                      SKZeile(farbe: .red,    kuerzel: "SK I",   bezeichnung: "Sofortige Behandlung",        count: $befund.manvSK1)
                      SKZeile(farbe: .yellow, kuerzel: "SK II",  bezeichnung: "Aufgeschobene Behandlung",    count: $befund.manvSK2)
                      SKZeile(farbe: .green,  kuerzel: "SK III", bezeichnung: "Leicht verletzt",              count: $befund.manvSK3)
                      SKZeile(farbe: .blue,   kuerzel: "SK IV",  bezeichnung: "Ohne Überlebenschance",        count: $befund.manvSK4)
                      SKZeile(farbe: .gray,   kuerzel: "T",      bezeichnung: "Verstorben",                   count: $befund.manvVerstorben)
                      HStack {
                          Text("Gesamt").fontWeight(.semibold)
                          Spacer()
                          Text("\(befund.manvGesamtSK) Personen").fontWeight(.semibold).foregroundColor(.secondary)
                      }
                  } header: {
                      Label("Sichtungsergebnis", systemImage: "person.3.fill")
                  } footer: {
                      Text("Anzahl direkt tippen oder mit + / − anpassen").font(.caption)
                  }
              }

              if befund.manv {
                  Section {
                      TextField("Lagemeldung an Leitstelle", text: $befund.manvLagemeldung, axis: .vertical)
                          .lineLimit(2...5)
                      TextField("Nachgeforderte Kräfte / Mittel", text: $befund.manvNachforderung)
                  } header: {
                      Label("MANV-Meldung", systemImage: "megaphone.fill")
                  }
              }
          }
          .navigationTitle("Dyn. Erweiterung / MANV")
          .navigationBarTitleDisplayMode(.inline)
      }
  }

  // MARK: - SKZeile (aus alter NotfallgeschehenView übernommen)

  private struct SKZeile: View {
      let farbe: Color
      let kuerzel: String
      let bezeichnung: String
      @Binding var count: Int
      @State private var zeigeNumpad = false

      var body: some View {
          HStack(spacing: 12) {
              ZStack {
                  RoundedRectangle(cornerRadius: 6)
                      .fill(farbe == .yellow ? Color.yellow : farbe.opacity(0.15))
                      .frame(width: 44, height: 32)
                  Text(kuerzel).font(.caption).fontWeight(.bold)
                      .foregroundColor(farbe == .yellow ? .black : farbe)
              }
              VStack(alignment: .leading, spacing: 1) {
                  Text(bezeichnung).font(.subheadline)
              }
              Spacer()
              HStack(spacing: 0) {
                  Button { if count > 0 { count -= 1 } } label: {
                      Image(systemName: "minus.circle.fill").font(.title2)
                          .foregroundColor(count > 0 ? farbe : .secondary)
                  }.buttonStyle(.plain)
                  Text("\(count)").font(.title3).fontWeight(.semibold)
                      .frame(minWidth: 36, alignment: .center)
                      .contentShape(Rectangle())
                      .onTapGesture { zeigeNumpad = true }
                  Button { count += 1 } label: {
                      Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(farbe)
                  }.buttonStyle(.plain)
              }
          }
          .sheet(isPresented: $zeigeNumpad) {
              NumpadSheet(mode: .integer(label: kuerzel, unit: "Personen", maxDigits: 3),
                          initial: "\(count)") { val in count = Int(val) ?? count }
          }
      }
  }

  // MARK: - AuswahlSection Helper (Multi-Select)

  private struct AuswahlSection: View {
      let titel: String
      let optionen: [String]
      @Binding var auswahl: [String]

      var body: some View {
          Section(titel) {
              ForEach(optionen, id: \.self) { option in
                  Button {
                      if auswahl.contains(option) {
                          auswahl.removeAll { $0 == option }
                      } else {
                          auswahl.append(option)
                      }
                  } label: {
                      HStack {
                          Text(option).foregroundColor(.primary)
                          Spacer()
                          if auswahl.contains(option) {
                              Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                          }
                      }
                  }
              }
          }
      }
  }
  ```

- [ ] **Schritt 2: Build prüfen** (⌘B, 0 Errors erwartet)

- [ ] **Schritt 3: Commit**

  ```
  git add PatProt/PatProt/Views/NotfallgeschehenView.swift
  git commit -m "feat: redesign NotfallgeschehenView as navigation list with selection subviews"
  ```

---

## Task 9: DiagnoseView ersetzen — Kategorieliste

**Files:**
- Replace: `PatProt/PatProt/Views/DiagnoseView.swift`

Enthält: Hauptliste mit Suche + DiagnoseKategorie-Daten + DiagnoseKategorieView.

- [ ] **Schritt 1: Gesamte Datei ersetzen**

  ```swift
  import SwiftUI

  // MARK: - Datenschicht

  struct DiagnoseKategorie: Identifiable {
      let id = UUID()
      let name: String
      let diagnosen: [String]

      static let alle: [DiagnoseKategorie] = [
          DiagnoseKategorie(name: "ZNS Erkrankungen", diagnosen: [
              "Schlaganfall / Apoplex", "TIA (transitorische ischämische Attacke)",
              "Epilepsie / Krampfanfall", "Fieberkrampf", "Synkope",
              "Bewusstlosigkeit unklarer Genese", "Meningitis / Enzephalitis",
              "Migräne / Kopfschmerz", "Subarachnoidalblutung (SAB)"
          ]),
          DiagnoseKategorie(name: "Herz-Kreislauf Erkrankungen", diagnosen: [
              "ACS / Herzinfarkt (STEMI)", "ACS / Herzinfarkt (NSTEMI)",
              "Angina pectoris", "Herzrhythmusstörung", "Herzinsuffizienz / Dekompensation",
              "Hypertensive Krise", "Hypotonie / Schock", "Lungenembolie",
              "Synkope (kardial)", "Aortenaneurysma / Dissektion", "Perikarditis"
          ]),
          DiagnoseKategorie(name: "Atemwegserkrankungen", diagnosen: [
              "COPD-Exazerbation", "Asthma-Anfall", "Pneumonie",
              "Lungenödem (kardial)", "Lungenembolie", "Hyperventilation",
              "Fremdkörperaspiration", "Epiglottitis", "Krupp-Syndrom"
          ]),
          DiagnoseKategorie(name: "Abdominelle Erkrankungen", diagnosen: [
              "Akutes Abdomen", "Appendizitisverdacht", "Übelkeit / Erbrechen",
              "GI-Blutung (obere)", "GI-Blutung (untere)", "Nierenkolik",
              "Gallenkolik", "Ileus", "Ulkus-Perforation"
          ]),
          DiagnoseKategorie(name: "Psychiatrische Erkrankungen / Intoxikation", diagnosen: [
              "Akute Psychose / Erregungszustand", "Suizidversuch",
              "Alkoholintoxikation", "Medikamenten-Intoxikation",
              "Drogenintoxikation", "Panikattacke",
              "Psychiatrische Krise", "Manie", "Alkoholentzugsdelir"
          ]),
          DiagnoseKategorie(name: "Stoffwechsel Erkrankungen", diagnosen: [
              "Hypoglykämie", "Hyperglykämie", "Diabetisches Koma",
              "Elektrolytentgleisung", "Exsikkose / Dehydration",
              "Schilddrüsenkrise", "Addison-Krise", "Urämie"
          ]),
          DiagnoseKategorie(name: "Gyn-/Geburtshilfe Notfälle", diagnosen: [
              "Drohende / stattfindende Geburt", "Schwangerschaftskomplikation",
              "Eklampsie / Präeklampsie", "Extrauteringravidität",
              "Vaginale Blutung", "Fehlgeburt / Abort", "HELLP-Syndrom"
          ]),
          DiagnoseKategorie(name: "sonst. Erkrankungen", diagnosen: [
              "Allergische Reaktion (leicht)", "Anaphylaxie (schwer)",
              "Hitzeerschöpfung", "Hitzschlag", "Unterkühlung",
              "Ertrinken / Beinaheertrinken", "SIDS-Verdacht", "Palliativversorgung"
          ]),
          DiagnoseKategorie(name: "Infektionen", diagnosen: [
              "Sepsis / septischer Schock", "Fieber unklarer Genese",
              "Meningitis (bakteriell)", "Gastroenteritis",
              "Pneumonie (infektiös)", "COVID-19 / SARS",
              "Harnwegsinfekt / Urosepsis"
          ]),
          DiagnoseKategorie(name: "Traumen und Verletzungen", diagnosen: [
              "SHT leicht (Commotio)", "SHT mittel", "SHT schwer",
              "Wirbelsäulenverletzung", "Thoraxtrauma",
              "Abdominaltrauma", "Beckentrauma",
              "Extremitätentrauma", "Polytrauma",
              "Verbrennung / Verbrühung", "Stromunfall",
              "Tauchunfall / Barotrauma", "Einzelverletzung (oberflächlich)"
          ])
      ]
  }

  // MARK: - Hauptliste

  struct DiagnoseView: View {
      @Binding var befund: DiagnoseBefund
      @State private var suche = ""
      @State private var zeigeNeuEingabe = false
      @State private var neuerName = ""
      @State private var neueWahrscheinlichkeit: DiagnoseWahrscheinlichkeit = .moeglich

      private var gefilterteKategorien: [DiagnoseKategorie] {
          guard !suche.isEmpty else { return DiagnoseKategorie.alle }
          let q = suche.lowercased()
          return DiagnoseKategorie.alle.compactMap { kat in
              let passendeDiagnosen = kat.diagnosen.filter { $0.lowercased().contains(q) }
              let katTrifft = kat.name.lowercased().contains(q)
              if katTrifft {
                  return kat
              } else if !passendeDiagnosen.isEmpty {
                  return DiagnoseKategorie(name: kat.name, diagnosen: passendeDiagnosen)
              }
              return nil
          }
      }

      var body: some View {
          List {
              if !befund.verdachtsdiagnosen.isEmpty {
                  Section("Ausgewählte Diagnosen") {
                      ForEach(befund.verdachtsdiagnosen) { eintrag in
                          HStack {
                              Image(systemName: eintrag.wahrscheinlichkeit.symbol)
                                  .foregroundColor(eintrag.wahrscheinlichkeit.farbe)
                                  .frame(width: 22)
                              Text(eintrag.name)
                              Spacer()
                              Button(role: .destructive) {
                                  befund.verdachtsdiagnosen.removeAll { $0.id == eintrag.id }
                              } label: {
                                  Image(systemName: "minus.circle.fill").foregroundColor(.red)
                              }
                              .buttonStyle(.plain)
                          }
                      }
                  }
              }

              ForEach(gefilterteKategorien, id: \.name) { kat in
                  Section(kat.name) {
                      NavigationLink {
                          DiagnoseKategorieView(kategorie: kat, befund: $befund)
                      } label: {
                          HStack {
                              Text(kat.name)
                              Spacer()
                              let anzahl = befund.verdachtsdiagnosen
                                  .filter { kat.diagnosen.contains($0.name) }.count
                              if anzahl > 0 {
                                  Text("\(anzahl)")
                                      .font(.caption.weight(.bold))
                                      .foregroundColor(.white)
                                      .padding(.horizontal, 7).padding(.vertical, 3)
                                      .background(Color("RDOrange"))
                                      .clipShape(Capsule())
                              }
                          }
                      }
                  }
              }
          }
          .searchable(text: $suche, prompt: "Diagnose suchen")
          .navigationTitle("Diagnosen")
          .navigationBarTitleDisplayMode(.large)
          .toolbar {
              ToolbarItem(placement: .navigationBarTrailing) {
                  Button { zeigeNeuEingabe = true } label: {
                      Image(systemName: "plus")
                  }
              }
          }
          .sheet(isPresented: $zeigeNeuEingabe) {
              NavigationStack {
                  Form {
                      Section { TextField("Diagnose / Verdacht", text: $neuerName) } header: { Text("Bezeichnung") }
                      Section {
                          Picker("Wahrscheinlichkeit", selection: $neueWahrscheinlichkeit) {
                              ForEach(DiagnoseWahrscheinlichkeit.allCases, id: \.self) { stufe in
                                  Label(stufe.rawValue, systemImage: stufe.symbol).tag(stufe)
                              }
                          }
                          .pickerStyle(.inline)
                      } header: { Text("Einschätzung") }
                  }
                  .navigationTitle("Neue Diagnose")
                  .navigationBarTitleDisplayMode(.inline)
                  .toolbar {
                      ToolbarItem(placement: .cancellationAction) {
                          Button("Abbrechen") { zeigeNeuEingabe = false; neuerName = "" }
                      }
                      ToolbarItem(placement: .confirmationAction) {
                          Button("Speichern") {
                              let name = neuerName.trimmingCharacters(in: .whitespaces)
                              guard !name.isEmpty else { return }
                              befund.verdachtsdiagnosen.append(
                                  VerdachtsdiagnoseEintrag(name: name, wahrscheinlichkeit: neueWahrscheinlichkeit, begruendung: "")
                              )
                              if neueWahrscheinlichkeit == .fuehrend { befund.leitsymptom = name }
                              zeigeNeuEingabe = false
                              neuerName = ""
                          }
                          .disabled(neuerName.trimmingCharacters(in: .whitespaces).isEmpty)
                      }
                  }
              }
              .presentationDetents([.medium])
          }
      }
  }

  // MARK: - Kategorie-Detailansicht

  struct DiagnoseKategorieView: View {
      let kategorie: DiagnoseKategorie
      @Binding var befund: DiagnoseBefund

      @State private var zeigeWahrscheinlichkeit = false
      @State private var gewaehlterName = ""

      private func istGewaehlt(_ name: String) -> Bool {
          befund.verdachtsdiagnosen.contains { $0.name == name }
      }

      private func toggleDiagnose(_ name: String) {
          if istGewaehlt(name) {
              befund.verdachtsdiagnosen.removeAll { $0.name == name }
          } else {
              gewaehlterName = name
              zeigeWahrscheinlichkeit = true
          }
      }

      var body: some View {
          List {
              ForEach(kategorie.diagnosen, id: \.self) { diagnose in
                  Button {
                      toggleDiagnose(diagnose)
                  } label: {
                      HStack {
                          Text(diagnose).foregroundColor(.primary)
                          Spacer()
                          if istGewaehlt(diagnose) {
                              let stufe = befund.verdachtsdiagnosen.first { $0.name == diagnose }?.wahrscheinlichkeit
                              Image(systemName: stufe?.symbol ?? "checkmark")
                                  .foregroundColor(stufe?.farbe ?? Color("RDOrange"))
                          }
                      }
                  }
              }
          }
          .navigationTitle(kategorie.name)
          .navigationBarTitleDisplayMode(.inline)
          .sheet(isPresented: $zeigeWahrscheinlichkeit) {
              WahrscheinlichkeitPickerSheet(name: gewaehlterName) { stufe in
                  befund.verdachtsdiagnosen.append(
                      VerdachtsdiagnoseEintrag(name: gewaehlterName, wahrscheinlichkeit: stufe, begruendung: "")
                  )
                  if stufe == .fuehrend { befund.leitsymptom = gewaehlterName }
              }
          }
      }
  }

  // MARK: - Wahrscheinlichkeit Picker Sheet

  private struct WahrscheinlichkeitPickerSheet: View {
      let name: String
      let onAuswahl: (DiagnoseWahrscheinlichkeit) -> Void
      @Environment(\.dismiss) private var dismiss

      var body: some View {
          NavigationStack {
              List {
                  ForEach(DiagnoseWahrscheinlichkeit.allCases, id: \.self) { stufe in
                      Button {
                          onAuswahl(stufe)
                          dismiss()
                      } label: {
                          Label(stufe.rawValue, systemImage: stufe.symbol)
                              .foregroundColor(stufe.farbe)
                      }
                  }
              }
              .navigationTitle(name)
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button("Abbrechen") { dismiss() }
                  }
              }
          }
          .presentationDetents([.medium])
      }
  }
  ```

- [ ] **Schritt 2: Build prüfen** (⌘B)

- [ ] **Schritt 3: Commit**

  ```
  git add PatProt/PatProt/Views/DiagnoseView.swift
  git commit -m "feat: redesign DiagnoseView as category picker with subcategory navigation"
  ```

---

## Task 10: ABCDEUebersichtView vereinfachen

**Files:**
- Modify: `PatProt/PatProt/Views/ABCDEUebersichtView.swift`

- [ ] **Schritt 1: Signature auf 5 Callbacks reduzieren**

  Die Struct-Definition ersetzen:
  ```swift
  struct ABCDEUebersichtView: View {
      @ObservedObject var protokoll: EinsatzProtokoll
      var onAirway: () -> Void
      var onBreathing: () -> Void
      var onCirculation: () -> Void
      var onDisability: () -> Void
      var onExposure: () -> Void
  ```

- [ ] **Schritt 2: body bereinigen**

  Den gesamten `body` auf Kritisch-Buttons + ABCDE-Zeilen reduzieren:

  ```swift
  var body: some View {
      ScrollView {
          VStack(spacing: 16) {
              // Kritisch / Nicht kritisch
              HStack(spacing: 12) {
                  Button { protokoll.kritisch = true } label: {
                      HStack {
                          Image(systemName: protokoll.kritisch
                                ? "exclamationmark.triangle.fill"
                                : "exclamationmark.triangle")
                          Text("Kritisch").fontWeight(.semibold)
                      }
                      .frame(maxWidth: .infinity).padding()
                      .background(protokoll.kritisch ? Color.red : Color(.secondarySystemGroupedBackground))
                      .foregroundColor(protokoll.kritisch ? .white : .primary)
                      .cornerRadius(12)
                  }
                  Button { protokoll.kritisch = false } label: {
                      HStack {
                          Image(systemName: !protokoll.kritisch
                                ? "checkmark.circle.fill"
                                : "checkmark.circle")
                          Text("Nicht kritisch").fontWeight(.semibold)
                      }
                      .frame(maxWidth: .infinity).padding()
                      .background(!protokoll.kritisch ? Color.green : Color(.secondarySystemGroupedBackground))
                      .foregroundColor(!protokoll.kritisch ? .white : .primary)
                      .cornerRadius(12)
                  }
              }
              .buttonStyle(.plain)
              .padding(.horizontal)

              // ABCDE
              VStack(spacing: 1) {
                  ABCDEZeile(buchstabe: "A", titel: "Airway",      untertitel: atemwegSubtitel(),    status: $protokoll.airway.status,      farbe: .orange, action: onAirway)
                  ABCDEZeile(buchstabe: "B", titel: "Breathing",   untertitel: breathingSubtitel(),  status: $protokoll.breathing.status,   farbe: .blue,   action: onBreathing)
                  ABCDEZeile(buchstabe: "C", titel: "Circulation", untertitel: circulationSubtitel(),status: $protokoll.circulation.status, farbe: .red,    action: onCirculation)
                  ABCDEZeile(buchstabe: "D", titel: "Disability",  untertitel: disabilitySubtitel(), status: $protokoll.disability.status,  farbe: .purple, action: onDisability)
                  ABCDEZeile(buchstabe: "E", titel: "Exposure",    untertitel: exposureSubtitel(),   status: $protokoll.exposure.status,    farbe: .green,  action: onExposure)
              }
              .cornerRadius(14)
              .padding(.horizontal)
              .padding(.bottom)
          }
          .padding(.top)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Befunde")
      .navigationBarTitleDisplayMode(.inline)
  }
  ```

- [ ] **Schritt 3: Alle Hilfsfunktionen behalten** (`atemwegSubtitel`, `breathingSubtitel`, `circulationSubtitel`, `disabilitySubtitel`, `exposureSubtitel`) — nur `diagnoseUntertitel` und `massnahmenSubtitel` entfernen.

- [ ] **Schritt 4: Build prüfen** (⌘B, 0 Errors)

- [ ] **Schritt 5: Commit**

  ```
  git add PatProt/PatProt/Views/ABCDEUebersichtView.swift
  git commit -m "refactor: simplify ABCDEUebersichtView to show only A-E assessment rows"
  ```

---

## Abschluss-Check

- [ ] App auf Simulator starten
- [ ] "Neu" → EinsatzOrtView öffnet (bestehender Flow unverändert)
- [ ] Hamburger-Menü öffnen → Konfiguration, Einsatzzeiten, Rettungstechnische Daten navigieren korrekt
- [ ] Notfallgeschehen → 7 Zeilen sichtbar, alle Sub-Views öffnen, Wisch-zurück funktioniert
- [ ] Diagnosen → Kategorieliste sichtbar, Tippen auf Kategorie → Unterliste, Diagnose auswählen → landet in "Ausgewählte Diagnosen"
- [ ] Befunde → nur Kritisch/Nicht-kritisch + A–E sichtbar
- [ ] Badges in der Menüliste aktualisieren sich nach Dateneingabe
