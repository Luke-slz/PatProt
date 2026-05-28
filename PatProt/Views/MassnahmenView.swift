import SwiftUI

struct MassnahmenView: View {
    @Binding var befund: MassnahmenBefund
    var onBack: () -> Void

    @State private var zeigeSauerstoffNumpad = false
    @State private var zeigeEgaGrNumpad = false
    @State private var zeigeVenoesGroesseNumpad = false
    @State private var zeigeCpapNumpad = false
    @State private var zeigeDefiJouleNumpad = false
    @State private var zeigeDefiAnzahlNumpad = false
    @State private var zeigeKardioversionJouleNumpad = false
    @State private var zeigeTvNumpad      = false
    @State private var zeigePeepNumpad    = false
    @State private var zeigeFio2Numpad    = false
    @State private var zeigeBfMaschNumpad = false

    var body: some View {
        Form {
            // Airway
            Section {
                CheckboxRow("Atemweg freimachen / freihalten", isOn: $befund.atemwegFreimachen)
                CheckboxRow("Cervikalstütze / HWS-Stabilisierung", isOn: $befund.cervikalStuetze)
                CheckboxRow("Absaugung", isOn: $befund.absaugung)
                CheckboxRow("Guedel-Tubus (OPA)", isOn: $befund.guedelTubus)
                CheckboxRow("Wendel-Tubus (NPA)",  isOn: $befund.wendlTubus)
                CheckboxRow("Sauerstoffgabe", isOn: $befund.sauerstoffgabe)
                if befund.sauerstoffgabe {
                    HStack {
                        Text("L/min")
                        Spacer()
                        Text(befund.sauerstoffLitMin.isEmpty ? "—" : befund.sauerstoffLitMin)
                            .foregroundColor(befund.sauerstoffLitMin.isEmpty ? .secondary : .primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeSauerstoffNumpad = true }
                    .sheet(isPresented: $zeigeSauerstoffNumpad) {
                        NumpadSheet(mode: .decimal(label: "O₂ Durchfluss", unit: "L/min"),
                                    initial: befund.sauerstoffLitMin) { val in befund.sauerstoffLitMin = val }
                    }
                }
                CheckboxRow("Maskenbeatmung (BVM)", isOn: $befund.maskenbeatmung)
                if befund.maskenbeatmung {
                    CheckboxRow("Maschinelle Beatmung", isOn: $befund.maschinelleBeatmung)
                    if befund.maschinelleBeatmung {
                        HStack {
                            Text("Tidalvolumen (ml)")
                            Spacer()
                            Text(befund.tidalvolumen.isEmpty ? "—" : befund.tidalvolumen)
                                .foregroundColor(befund.tidalvolumen.isEmpty ? .secondary : .primary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { zeigeTvNumpad = true }
                        .sheet(isPresented: $zeigeTvNumpad) {
                            NumpadSheet(mode: .integer(label: "Tidalvolumen", unit: "ml"),
                                        initial: befund.tidalvolumen) { val in befund.tidalvolumen = val }
                        }
                        HStack {
                            Text("PEEP (cmH₂O)")
                            Spacer()
                            Text(befund.peep.isEmpty ? "—" : befund.peep)
                                .foregroundColor(befund.peep.isEmpty ? .secondary : .primary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { zeigePeepNumpad = true }
                        .sheet(isPresented: $zeigePeepNumpad) {
                            NumpadSheet(mode: .integer(label: "PEEP", unit: "cmH₂O"),
                                        initial: befund.peep) { val in befund.peep = val }
                        }
                        HStack {
                            Text("FiO₂ (%)")
                            Spacer()
                            Text(befund.fio2.isEmpty ? "—" : befund.fio2)
                                .foregroundColor(befund.fio2.isEmpty ? .secondary : .primary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { zeigeFio2Numpad = true }
                        .sheet(isPresented: $zeigeFio2Numpad) {
                            NumpadSheet(mode: .integer(label: "FiO₂", unit: "%"),
                                        initial: befund.fio2) { val in befund.fio2 = val }
                        }
                        HStack {
                            Text("AF Gerät (/min)")
                            Spacer()
                            Text(befund.beatmungsfrequenzMasch.isEmpty ? "—" : befund.beatmungsfrequenzMasch)
                                .foregroundColor(befund.beatmungsfrequenzMasch.isEmpty ? .secondary : .primary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { zeigeBfMaschNumpad = true }
                        .sheet(isPresented: $zeigeBfMaschNumpad) {
                            NumpadSheet(mode: .integer(label: "AF Gerät", unit: "/min"),
                                        initial: befund.beatmungsfrequenzMasch) { val in befund.beatmungsfrequenzMasch = val }
                        }
                    }
                }
                CheckboxRow("Maskenbeatmung unmöglich", isOn: $befund.maskenbeatmungUnmoeglich)
                CheckboxRow("Supraglott. Atemwegshilfe (EGA)", isOn: $befund.supraglottisch)
                if befund.supraglottisch {
                    HStack {
                        Picker("Typ", selection: $befund.supraglottischTyp) {
                            Text("Larynxmaske").tag("Larynxmaske")
                            Text("Larynxtubus").tag("Larynxtubus")
                            Text("Sonst.").tag("Sonst.")
                        }
                        .pickerStyle(.segmented)
                        Text(befund.supraglottischGr.isEmpty ? "Gr." : befund.supraglottischGr)
                            .foregroundColor(befund.supraglottischGr.isEmpty ? .secondary : .primary)
                            .frame(width: 50, alignment: .trailing)
                            .contentShape(Rectangle())
                            .onTapGesture { zeigeEgaGrNumpad = true }
                    }
                    .sheet(isPresented: $zeigeEgaGrNumpad) {
                        NumpadSheet(mode: .integer(label: "EGA Größe", unit: "", maxDigits: 2),
                                    initial: befund.supraglottischGr) { val in befund.supraglottischGr = val }
                    }
                }
                CheckboxRow("Atemwegszugang erschwert", isOn: $befund.atemwegErschwert)
                CheckboxRow("CPAP (5–15 mBar)", isOn: $befund.cpap)
                if befund.cpap {
                    HStack {
                        Text("mBar")
                        Spacer()
                        Text(befund.cpapMbar.isEmpty ? "—" : befund.cpapMbar)
                            .foregroundColor(befund.cpapMbar.isEmpty ? .secondary : .primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeCpapNumpad = true }
                    .sheet(isPresented: $zeigeCpapNumpad) {
                        NumpadSheet(mode: .integer(label: "CPAP Druck", unit: "mBar", maxDigits: 2),
                                    initial: befund.cpapMbar) { val in befund.cpapMbar = val }
                    }
                }
                CheckboxRow("Heimlich (Fremdkörperentfernung)", isOn: $befund.heimlich)
                TextField("Sonstige Airway-Maßnahmen", text: $befund.airwaySonstige)
            } header: {
                Label("Airway / Stabilisation", systemImage: "lungs")
            }

            // Kreislauf
            Section {
                CheckboxRow("Peripher-venöser Zugang", isOn: $befund.peripherVenoes)
                if befund.peripherVenoes {
                    HStack {
                        TextField("Ort", text: $befund.peripherVenoesOrt)
                        Text(befund.peripherVenoesGroesse.isEmpty ? "Gr." : befund.peripherVenoesGroesse)
                            .foregroundColor(befund.peripherVenoesGroesse.isEmpty ? .secondary : .primary)
                            .frame(width: 50, alignment: .trailing)
                            .contentShape(Rectangle())
                            .onTapGesture { zeigeVenoesGroesseNumpad = true }
                        Stepper("Anz: \(befund.peripherVenoesAnz)", value: $befund.peripherVenoesAnz, in: 1...4)
                    }
                    .sheet(isPresented: $zeigeVenoesGroesseNumpad) {
                        NumpadSheet(mode: .decimal(label: "Kanülen-Größe", unit: "G"),
                                    initial: befund.peripherVenoesGroesse) { val in befund.peripherVenoesGroesse = val }
                    }
                }
                CheckboxRow("Intraossär-Zugang", isOn: $befund.intraossaer)
                if befund.intraossaer {
                    TextField("Ort (z.B. Tibia re.)", text: $befund.intraossaerOrt)
                }
                CheckboxRow("Defibrillation", isOn: $befund.defibrillation)
                if befund.defibrillation {
                    HStack {
                        Text("Joule")
                        Spacer()
                        Text("\(befund.defiJoule) J")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeDefiJouleNumpad = true }
                    .sheet(isPresented: $zeigeDefiJouleNumpad) {
                        NumpadSheet(mode: .integer(label: "Energie", unit: "J", maxDigits: 3),
                                    initial: String(befund.defiJoule)) { val in
                            befund.defiJoule = Int(val) ?? 200
                        }
                    }
                }
                if befund.defibrillation {
                    HStack {
                        Text("Anzahl Schocks")
                        Spacer()
                        Text("\(befund.defiAnzahl)×")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeDefiAnzahlNumpad = true }
                    .sheet(isPresented: $zeigeDefiAnzahlNumpad) {
                        NumpadSheet(mode: .integer(label: "Anzahl Schocks", unit: "×", maxDigits: 2),
                                    initial: String(befund.defiAnzahl)) { val in
                            befund.defiAnzahl = Int(val) ?? 1
                        }
                    }
                }
                CheckboxRow("Kardioversion", isOn: $befund.kardioversion)
                if befund.kardioversion {
                    HStack {
                        Text("Joule")
                        Spacer()
                        Text("\(befund.kardioversionJoule) J").foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeKardioversionJouleNumpad = true }
                    .sheet(isPresented: $zeigeKardioversionJouleNumpad) {
                        NumpadSheet(mode: .integer(label: "Energie Kardioversion", unit: "J", maxDigits: 3),
                                    initial: String(befund.kardioversionJoule)) { val in
                            befund.kardioversionJoule = Int(val) ?? 100
                        }
                    }
                }
                TextField("Sonstige Kreislauf-Maßnahmen", text: $befund.circSonstige)
            } header: {
                Label("Kreislauf / Zugänge", systemImage: "drop.fill")
            }

            // Weitere Maßnahmen
            Section {
                CheckboxRow("Tourniquet", isOn: $befund.tourniquet)
                if befund.tourniquet {
                    ZeitFeld(label: "Tourniquet Zeit", datum: $befund.tourniquetZeit)
                }
                CheckboxRow("Wärmeerhalt", isOn: $befund.waermeerhalt)
                CheckboxRow("Kühlung", isOn: $befund.kuehlung)
                CheckboxRow("Krisenintervention", isOn: $befund.krisenintervention)
                CheckboxRow("Entbindung", isOn: $befund.entbindung)
                TextField("Sonstige Maßnahmen", text: $befund.weitereSonstige)
            } header: {
                Label("Weitere Maßnahmen", systemImage: "cross.circle")
            }

            // Lagerung
            Section {
                CheckboxRow("OK-Hochlagerung", isOn: $befund.okHochlagerung)
                CheckboxRow("Flachlagerung", isOn: $befund.flachlagerung)
                CheckboxRow("Schocklagerung", isOn: $befund.schocklagerung)
                CheckboxRow("Herz-Tieflage", isOn: $befund.herzTieflage)
                CheckboxRow("Linksseitenlage / stabile SL", isOn: $befund.linksseitenlage)
                CheckboxRow("Sitzender Transport", isOn: $befund.sitzenderTransport)
                CheckboxRow("Vakuummatratze", isOn: $befund.vakuummatratze)
                CheckboxRow("Schaufeltrage", isOn: $befund.schaufeltrage)
                CheckboxRow("Extremitätenschienung", isOn: $befund.extremitaetenschienung)
                CheckboxRow("Beckenschlinge", isOn: $befund.beckenschlinge)
                CheckboxRow("Verband / Wundversorgung", isOn: $befund.verband)
                TextField("Sonstige Lagerung", text: $befund.lagerungSonstige)
            } header: {
                Label("Lagerung / Transport", systemImage: "bed.double")
            }

            // Monitoring
            Section {
                CheckboxRow("SpO₂", isOn: $befund.monSpo2)
                CheckboxRow("NIBP", isOn: $befund.monNibp)
                CheckboxRow("BZ", isOn: $befund.monBz)
                CheckboxRow("EKG / AED-Monitor", isOn: $befund.monEkg)
                CheckboxRow("Temperatur", isOn: $befund.monTemperatur)
            } header: {
                Label("Monitoring", systemImage: "waveform.path.ecg.rectangle")
            }
        }
        .keyboardDismissToolbar()
        .navigationTitle("Maßnahmen")
        .navigationBarTitleDisplayMode(.large)
    }
}
