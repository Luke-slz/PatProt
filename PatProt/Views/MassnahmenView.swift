import SwiftUI

struct MassnahmenView: View {
    @Binding var befund: MassnahmenBefund
    var onBack: () -> Void

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
                        TextField("z.B. 8", text: $befund.sauerstoffLitMin)
                            .keyboardType(.decimalPad)
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
                        TextField("Gr.", text: $befund.supraglottischGr)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
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
                        TextField("FiO₂", text: $befund.beatmungFiO2)
                            .keyboardType(.decimalPad)
                        Text("FiO₂")
                        Spacer()
                        TextField("CPAP/PEEP", text: $befund.beatmungCpapPeep)
                            .keyboardType(.decimalPad)
                        Text("CPAP/PEEP")
                    }
                    HStack {
                        TextField("IE", text: $befund.beatmungIE)
                            .keyboardType(.decimalPad)
                        Text("IE")
                        Spacer()
                        TextField("AF", text: $befund.beatmungAF)
                            .keyboardType(.numberPad)
                        Text("AF")
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
                        TextField("Größe", text: $befund.peripherVenoesGroesse)
                            .keyboardType(.decimalPad)
                        Stepper("Anz: \(befund.peripherVenoesAnz)", value: $befund.peripherVenoesAnz, in: 1...4)
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

            Section {
                Button(action: onBack) {
                    Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("RDOrange"))
            }
        }
        .navigationTitle("Maßnahmen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
