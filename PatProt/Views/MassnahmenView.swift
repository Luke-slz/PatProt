import SwiftUI

struct MassnahmenView: View {
    @Binding var befund: MassnahmenBefund
    var onBack: () -> Void

    @State private var zeigeSauerstoffNumpad = false
    @State private var zeigeEgaGrNumpad = false
    @State private var zeigeFiO2Numpad = false
    @State private var zeigeCpapPeepNumpad = false
    @State private var zeigeIeNumpad = false
    @State private var zeigeBeatmungAfNumpad = false
    @State private var zeigeVenoesGroesseNumpad = false

    var body: some View {
        Form {
            // Airway / Stabilisation
            Section {
                CheckboxRow("Atemweg freimachen / freihalten", isOn: $befund.atemwegFreimachen)
                CheckboxRow("Cervikalstütze / HWS-Stabilisierung", isOn: $befund.cervikalStuetze)
                CheckboxRow("Absaugung", isOn: $befund.absaugung)
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
                CheckboxRow("Maskenbeatmung", isOn: $befund.maskenbeatmung)
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
                CheckboxRow("Intubation", isOn: $befund.intubationRD)
                CheckboxRow("Tracheotomie / chir. Atemweg", isOn: $befund.tracheotomie)
                TextField("Sonstige Airway-Maßnahmen", text: $befund.airwaySonstige)
            } header: { Label("Airway / Stabilisation", systemImage: "lungs") }

            // Atmung
            Section {
                CheckboxRow("Thoraxdrainage", isOn: $befund.thoraxdrainage)
                CheckboxRow("CPAP / NIV", isOn: $befund.cpapNiv)
                CheckboxRow("Entlastungspunktion re", isOn: $befund.entlastungspunktionRe)
                CheckboxRow("Entlastungspunktion li", isOn: $befund.entlastungspunktionLi)
                CheckboxRow("Kontrollierte Beatmung (PCV, CMV)", isOn: $befund.kontrollierteBeatmung)
                if befund.kontrollierteBeatmung || befund.cpapNiv {
                    HStack {
                        Text(befund.beatmungFiO2.isEmpty ? "—" : befund.beatmungFiO2)
                            .foregroundColor(befund.beatmungFiO2.isEmpty ? .secondary : .primary)
                            .contentShape(Rectangle())
                            .onTapGesture { zeigeFiO2Numpad = true }
                        Text("FiO₂")
                        Spacer()
                        Text(befund.beatmungCpapPeep.isEmpty ? "—" : befund.beatmungCpapPeep)
                            .foregroundColor(befund.beatmungCpapPeep.isEmpty ? .secondary : .primary)
                            .contentShape(Rectangle())
                            .onTapGesture { zeigeCpapPeepNumpad = true }
                        Text("CPAP/PEEP")
                    }
                    .sheet(isPresented: $zeigeFiO2Numpad) {
                        NumpadSheet(mode: .decimal(label: "FiO₂", unit: ""),
                                    initial: befund.beatmungFiO2) { val in befund.beatmungFiO2 = val }
                    }
                    .sheet(isPresented: $zeigeCpapPeepNumpad) {
                        NumpadSheet(mode: .decimal(label: "CPAP/PEEP", unit: "mbar"),
                                    initial: befund.beatmungCpapPeep) { val in befund.beatmungCpapPeep = val }
                    }
                    HStack {
                        Text(befund.beatmungIE.isEmpty ? "—" : befund.beatmungIE)
                            .foregroundColor(befund.beatmungIE.isEmpty ? .secondary : .primary)
                            .contentShape(Rectangle())
                            .onTapGesture { zeigeIeNumpad = true }
                        Text("IE")
                        Spacer()
                        Text(befund.beatmungAF.isEmpty ? "—" : befund.beatmungAF)
                            .foregroundColor(befund.beatmungAF.isEmpty ? .secondary : .primary)
                            .contentShape(Rectangle())
                            .onTapGesture { zeigeBeatmungAfNumpad = true }
                        Text("AF")
                    }
                    .sheet(isPresented: $zeigeIeNumpad) {
                        NumpadSheet(mode: .decimal(label: "Tidalvolumen", unit: "IE"),
                                    initial: befund.beatmungIE) { val in befund.beatmungIE = val }
                    }
                    .sheet(isPresented: $zeigeBeatmungAfNumpad) {
                        NumpadSheet(mode: .integer(label: "Beatmungs-AF", unit: "/min"),
                                    initial: befund.beatmungAF) { val in befund.beatmungAF = val }
                    }
                }
                TextField("Sonstige Atmungs-Maßnahmen", text: $befund.atmungSonstige)
            } header: { Label("Atmung", systemImage: "wind") }

            // Cirkulation / Zugänge
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
                CheckboxRow("Zentral-venöser Zugang", isOn: $befund.zentralVenoes)
                if befund.zentralVenoes {
                    TextField("Ort ZVK", text: $befund.zentralVenoesOrt)
                }
                CheckboxRow("Intraossäre Kanüle / Port", isOn: $befund.intraossaer)
                if befund.intraossaer {
                    TextField("Ort IO", text: $befund.intraossaerOrt)
                }
                CheckboxRow("Art. Kanüle", isOn: $befund.artKanule)
                CheckboxRow("Intraossale Applikation", isOn: $befund.intraossaleApplikation)
                TextField("Sonstige Kreislauf-Maßnahmen", text: $befund.circSonstige)
            } header: { Label("Cirkulation / Zugänge", systemImage: "drop.fill") }

            // Weitere Maßnahmen
            Section {
                CheckboxRow("Kühlung", isOn: $befund.kuehlung)
                CheckboxRow("Wärmeerhalt", isOn: $befund.waermeerhalt)
                CheckboxRow("Entbindung", isOn: $befund.entbindung)
                CheckboxRow("Krisenintervention", isOn: $befund.krisenintervention)
                CheckboxRow("Kardioversion", isOn: $befund.kardioversion)
                CheckboxRow("Tourniquet", isOn: $befund.tourniquet)
                if befund.tourniquet {
                    DatePicker("Tourniquet Zeit", selection: Binding(
                        get: { befund.tourniquetZeit ?? Date() },
                        set: { befund.tourniquetZeit = $0 }
                    ), displayedComponents: .hourAndMinute)
                }
                CheckboxRow("Narkose / Analgesedierung", isOn: $befund.narkoseAnalgesedierung)
                TextField("Sonstige Maßnahmen", text: $befund.weitereSonstige)
            } header: { Label("Weitere Maßnahmen", systemImage: "cross.circle") }

            // Lagerung / Transport
            Section {
                CheckboxRow("OK-Hochlagerung", isOn: $befund.okHochlagerung)
                CheckboxRow("Flachlagerung", isOn: $befund.flachlagerung)
                CheckboxRow("Schocklagerung", isOn: $befund.schocklagerung)
                CheckboxRow("Herz-Tieflage", isOn: $befund.herzTieflage)
                CheckboxRow("Linksseitenlage", isOn: $befund.linksseitenlage)
                CheckboxRow("Sitzender Transport", isOn: $befund.sitzenderTransport)
                CheckboxRow("Vakuummatratze", isOn: $befund.vakuummatratze)
                CheckboxRow("Schaufeltrage", isOn: $befund.schaufeltrage)
                CheckboxRow("Extremitätenschienung", isOn: $befund.extremitaetenschienung)
                CheckboxRow("Reposition", isOn: $befund.reposition)
                CheckboxRow("Verband", isOn: $befund.verband)
                CheckboxRow("Beckenschlinge", isOn: $befund.beckenschlinge)
                TextField("Sonstige Lagerung", text: $befund.lagerungSonstige)
            } header: { Label("Lagerung / Transport", systemImage: "bed.double") }

            // Monitoring
            Section {
                CheckboxRow("EKG", isOn: $befund.monEkg)
                CheckboxRow("12-Kanal-EKG", isOn: $befund.mon12KanalEkg)
                CheckboxRow("NIBP", isOn: $befund.monNibp)
                CheckboxRow("BZ", isOn: $befund.monBz)
                CheckboxRow("Invasive RR-Messung", isOn: $befund.monInvaRR)
                CheckboxRow("SpO₂", isOn: $befund.monSpo2)
                CheckboxRow("Temperatur", isOn: $befund.monTemperatur)
                CheckboxRow("Kapnometrie / Kapnografie", isOn: $befund.monKapnografie)
            } header: { Label("Monitoring", systemImage: "waveform.path.ecg.rectangle") }

            // Medizintechnik
            Section {
                CheckboxRow("Ultraschall / Sono", isOn: $befund.ultraschall)
                CheckboxRow("Funk-EKG-Übermittlung", isOn: $befund.funkEkgUebermittlung)
                CheckboxRow("Notfallpager", isOn: $befund.notfallpager)
                CheckboxRow("Spritzenpumpe", isOn: $befund.spritzenpumpe)
                CheckboxRow("Video-Laryngoskop", isOn: $befund.videoLaryngoskop)
                CheckboxRow("Transportinkubator", isOn: $befund.transportinkubator)
                CheckboxRow("Mechanische Thoraxkompression", isOn: $befund.mechanischeThorax)
                TextField("Sonstige Medizintechnik", text: $befund.medtechSonstige)
            } header: { Label("Medizintechnik", systemImage: "gear.badge.questionmark") }

        }
        .navigationTitle("Maßnahmen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            Button(action: onBack) {
                Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("RDOrange"))
            .padding([.horizontal, .bottom])
            .background(.bar)
        }
    }
}
