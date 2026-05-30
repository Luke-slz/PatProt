import SwiftUI
import UIKit

// MARK: - Swipe Back Enabler

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { Ctrl() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {}

    private class Ctrl: UIViewController {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

extension View {
    func swipeBackEnabled() -> some View {
        background(SwipeBackEnabler())
    }
}

// MARK: - Shared CheckboxRow

struct CheckboxRow: View {
    let label: String
    @Binding var isOn: Bool

    init(_ label: String, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn ? Color("RDOrange") : .secondary)
                    .font(.title3)
                Text(label)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vital color/warning helpers

private func vitalBg(_ val: Double?, normal: ClosedRange<Double>, warning: ClosedRange<Double>) -> Color {
    guard let v = val else { return .clear }
    if normal.contains(v) { return Color.green.opacity(0.12) }
    if warning.contains(v) { return Color.yellow.opacity(0.18) }
    return Color.red.opacity(0.15)
}

private func vitalWarnText(_ val: Double?, normal: ClosedRange<Double>, warning: ClosedRange<Double>,
                            lowWarn: String, highWarn: String) -> (String, Bool)? {
    guard let v = val else { return nil }
    if normal.contains(v) { return nil }
    let critical = !warning.contains(v)
    return (v < normal.lowerBound ? lowWarn : highWarn, critical)
}

// MARK: - Shared StatusPicker

struct StatusPickerView: View {
    @Binding var status: ABCDEStatus
    var body: some View {
        Picker("Status", selection: $status) {
            Label("Kein Problem", systemImage: "checkmark.circle.fill").tag(ABCDEStatus.nicht_kritisch)
            Label("Problem", systemImage: "xmark.circle.fill").tag(ABCDEStatus.kritisch)
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - A: Airway

struct AirwayView: View {
    @Binding var befund: AirwayBefund
    @Binding var massnahmen: MassnahmenBefund
    var onZurueck: () -> Void

    let massnahmenOptionen = ["Kopf überstrecken", "Mundinspektion", "Absaugen", "Stabile Seitenlage", "Esmarch-Handgriff"]

    var body: some View {
        Form {
            Section {
                StatusPickerView(status: $befund.status)
            } header: { Text("Gesamtstatus") }

            Section {
                Toggle("Atemweg frei", isOn: $befund.freiheit)
                Toggle("Atemweg verlegt", isOn: $befund.verlegung)
                if befund.verlegung {
                    TextField("Ursache der Verlegung", text: $befund.verlegungsUrsache)
                }
            } header: { Label("Atemweg", systemImage: "wind") }

            Section {
                TextEditor(text: $befund.freitext)
                    .frame(minHeight: 80)
                Text("→ PDF S. 1 · ABCDE · A")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } header: { Text("Freitext / Notizen") }

            Section {
                CheckboxRow("Atemweg freimachen", isOn: $massnahmen.atemwegFreimachen)
                CheckboxRow("Absaugung", isOn: $massnahmen.absaugung)
                CheckboxRow("Cervikalstütze", isOn: $massnahmen.cervikalStuetze)
                CheckboxRow("Guedel-Tubus (OPA)", isOn: $massnahmen.guedelTubus)
                CheckboxRow("Wendel-Tubus (NPA)", isOn: $massnahmen.wendlTubus)
                CheckboxRow("Heimlich-Manöver", isOn: $massnahmen.heimlich)
                CheckboxRow("Erschwerter Atemweg", isOn: $massnahmen.atemwegErschwert)
                Toggle("Supraglottischer AW", isOn: $massnahmen.supraglottisch)
                if massnahmen.supraglottisch {
                    TextField("Typ (z.B. LMA, i-gel)", text: $massnahmen.supraglottischTyp)
                }
                CheckboxRow("Konikotomie", isOn: $befund.konikotomie)
            } header: { Label("Maßnahmen Atemweg", systemImage: "cross.fill") }

        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onZurueck) {
                Label("Weiter zu Breathing", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("RDOrange"))
            .padding([.horizontal, .bottom])
            .background(.bar)
        }
        .navigationTitle("A — Airway")
        .navigationBarTitleDisplayMode(.large)
        .swipeBackEnabled()
    }
}

// MARK: - B: Breathing

struct BreathingView: View {
    @Binding var befund: BreathingBefund
    @Binding var massnahmen: MassnahmenBefund
    var onZurueck: () -> Void

    @State private var andereAtemgeraeusche: String = ""
    @State private var zeigeAfNumpad = false
    @State private var zeigeSpo2Numpad = false

    private var afBg: Color {
        vitalBg(befund.atemFrequenz.map(Double.init), normal: 12...20, warning: 8...30)
    }
    private var afWarn: (String, Bool)? {
        vitalWarnText(befund.atemFrequenz.map(Double.init), normal: 12...20, warning: 8...30,
                      lowWarn: "Bradypnoe (< 12/min)", highWarn: "Tachypnoe (> 20/min)")
    }
    private var spo2Bg: Color {
        guard let v = befund.spo2, v > 0 else { return .clear }
        if v >= 95 { return Color.green.opacity(0.12) }
        if v >= 90 { return Color.yellow.opacity(0.18) }
        return Color.red.opacity(0.15)
    }
    private var spo2Warn: (String, Bool)? {
        guard let v = befund.spo2, v > 0 else { return nil }
        if v >= 95 { return nil }
        if v >= 90 { return ("SpO₂ erniedrigt (90–94%)", false) }
        return ("Kritisch! SpO₂ < 90%", true)
    }

    var body: some View {
        Form {
            Section {
                StatusPickerView(status: $befund.status)
            } header: { Text("Gesamtstatus") }

            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Atemfrequenz (/min)")
                        Spacer()
                        Text(befund.atemFrequenz.map(String.init) ?? "—")
                            .foregroundColor(befund.atemFrequenz == nil ? .secondary : .primary)
                    }
                    if let (msg, crit) = afWarn {
                        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
                    }
                }
                .listRowBackground(afBg)
                .contentShape(Rectangle())
                .onTapGesture { zeigeAfNumpad = true }
                .sheet(isPresented: $zeigeAfNumpad) {
                    NumpadSheet(mode: .integer(label: "Atemfrequenz", unit: "/min"),
                                initial: befund.atemFrequenz.map(String.init) ?? "") { val in
                        befund.atemFrequenz = Int(val)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("SpO₂ (%)")
                        Spacer()
                        Text(befund.spo2.map(String.init) ?? "—")
                            .foregroundColor(befund.spo2 == nil ? .secondary : .primary)
                    }
                    if let (msg, crit) = spo2Warn {
                        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
                    }
                }
                .listRowBackground(spo2Bg)
                .contentShape(Rectangle())
                .onTapGesture { zeigeSpo2Numpad = true }
                .sheet(isPresented: $zeigeSpo2Numpad) {
                    NumpadSheet(mode: .integer(label: "SpO₂", unit: "%"),
                                initial: befund.spo2.map(String.init) ?? "") { val in
                        befund.spo2 = Int(val)
                    }
                }
                Picker("Atemgeräusche / Atemstörung", selection: $befund.atemgeraeusche) {
                    Text("").tag("")
                    Text("Vesikulär (normal)").tag("Vesikulär (normal)")
                    Text("Giemen").tag("Giemen")
                    Text("Rasseln").tag("Rasseln")
                    Text("Brodeln").tag("Brodeln")
                    Text("Stridor").tag("Stridor")
                    Text("Brummen").tag("Brummen")
                    Text("Spastik").tag("Spastik")
                    Text("Schnappatmung").tag("Schnappatmung")
                    Text("Apnoe").tag("Apnoe")
                    Text("Hyperventilation").tag("Hyperventilation")
                    Text("Kein Atemgeräusch").tag("Kein Atemgeräusch")
                    Text("Nicht beurteilbar").tag("Nicht beurteilbar")
                    Text("Andere …").tag("Andere")
                }

                if befund.atemgeraeusche == "Andere" {
                    TextField("Atemgeräusch eingeben", text: $andereAtemgeraeusche)
                        .onChange(of: andereAtemgeraeusche) { _, value in
                            befund.atemgeraeusche = value.isEmpty ? "Andere" : value
                        }
                }
            } header: { Label("Vitalparameter", systemImage: "lungs") }
            .onAppear {
                let knownOptions = ["", "Vesikulär (normal)", "Giemen", "Rasseln", "Brodeln", "Stridor", "Brummen", "Spastik", "Schnappatmung", "Apnoe", "Hyperventilation", "Kein Atemgeräusch", "Nicht beurteilbar", "Andere"]
                if !knownOptions.contains(befund.atemgeraeusche) {
                    andereAtemgeraeusche = befund.atemgeraeusche
                }
            }

            Section {
                Toggle("Dyspnoe", isOn: $befund.dyspnoe)
                Toggle("Zyanose", isOn: $befund.zyanose)
            } header: { Label("Klinische Zeichen", systemImage: "eye") }

            Section {
                TextEditor(text: $befund.freitext).frame(minHeight: 80)
                Text("→ PDF S. 1 · ABCDE · B")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } header: { Text("Freitext / Notizen") }

            Section {
                Toggle("Sauerstoffgabe", isOn: $massnahmen.sauerstoffgabe)
                if massnahmen.sauerstoffgabe {
                    HStack {
                        TextField("Liter/min", text: $massnahmen.sauerstoffLitMin)
                            .keyboardType(.decimalPad)
                        Text("l/min").foregroundColor(.secondary)
                    }
                }
                CheckboxRow("Maskenbeatmung", isOn: $massnahmen.maskenbeatmung)
                CheckboxRow("Maschinelle Beatmung", isOn: $massnahmen.maschinelleBeatmung)
                Toggle("CPAP", isOn: $massnahmen.cpap)
                if massnahmen.cpap {
                    HStack {
                        TextField("Druck", text: $massnahmen.cpapMbar)
                            .keyboardType(.decimalPad)
                        Text("mbar").foregroundColor(.secondary)
                    }
                }
            } header: { Label("Maßnahmen Beatmung / O₂", systemImage: "cross.fill") }

        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onZurueck) {
                Label("Weiter zu Circulation", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("RDOrange"))
            .padding([.horizontal, .bottom])
            .background(.bar)
        }
        .navigationTitle("B — Breathing")
        .navigationBarTitleDisplayMode(.large)
        .swipeBackEnabled()
    }
}

// MARK: - C: Circulation

struct CirculationView: View {
    @Binding var befund: CirculationBefund
    @Binding var massnahmen: MassnahmenBefund
    var onZurueck: () -> Void

    @State private var zeigePulsNumpad = false
    @State private var zeigeRrNumpad = false

    private var pulsBg: Color {
        if befund.pulslosigkeit { return Color.red.opacity(0.15) }
        return vitalBg(befund.puls.map(Double.init), normal: 60...100, warning: 40...120)
    }
    private var pulsWarn: (String, Bool)? {
        if befund.pulslosigkeit { return nil }
        return vitalWarnText(befund.puls.map(Double.init), normal: 60...100, warning: 40...120,
                             lowWarn: "Bradykardie (< 60/min)", highWarn: "Tachykardie (> 100/min)")
    }
    private var rrBg: Color {
        let sys = befund.blutdruckSystolisch.map(Double.init)
        let dia = befund.blutdruckDiastolisch.map(Double.init)
        guard sys != nil || dia != nil else { return .clear }
        if let s = sys, !(80.0...179.0).contains(s) { return Color.red.opacity(0.15) }
        if let d = dia, !(40.0...109.0).contains(d) { return Color.red.opacity(0.15) }
        if let s = sys, !(100.0...139.0).contains(s) { return Color.yellow.opacity(0.18) }
        if let d = dia, !(60.0...89.0).contains(d)  { return Color.yellow.opacity(0.18) }
        return Color.green.opacity(0.12)
    }
    private var rrWarn: (String, Bool)? {
        let sys = befund.blutdruckSystolisch.map(Double.init)
        let dia = befund.blutdruckDiastolisch.map(Double.init)
        var msgs: [String] = []
        var critical = false
        if let s = sys {
            if s < 80        { msgs.append("sys kritisch niedrig"); critical = true }
            else if s < 100  { msgs.append("Hypotonie (sys)") }
            else if s > 179  { msgs.append("sys kritisch hoch"); critical = true }
            else if s > 139  { msgs.append("Hypertonie (sys)") }
        }
        if let d = dia {
            if d < 40        { msgs.append("dia kritisch niedrig"); critical = true }
            else if d < 60   { msgs.append("dia erniedrigt") }
            else if d > 109  { msgs.append("dia kritisch hoch"); critical = true }
            else if d > 89   { msgs.append("dia erhöht") }
        }
        return msgs.isEmpty ? nil : (msgs.joined(separator: " · "), critical)
    }

    var body: some View {
        Form {
            Section {
                StatusPickerView(status: $befund.status)
            } header: { Text("Gesamtstatus") }

            Section {
                Toggle("Pulslosigkeit", isOn: $befund.pulslosigkeit)
                    .listRowBackground(befund.pulslosigkeit ? Color.red.opacity(0.15) : Color.clear)
                if !befund.pulslosigkeit {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Puls (/min)")
                            Spacer()
                            Text(befund.puls.map(String.init) ?? "—")
                                .foregroundColor(befund.puls == nil ? .secondary : .primary)
                        }
                        if let (msg, crit) = pulsWarn {
                            Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
                        }
                    }
                    .listRowBackground(pulsBg)
                    .contentShape(Rectangle())
                    .onTapGesture { zeigePulsNumpad = true }
                    .sheet(isPresented: $zeigePulsNumpad) {
                        NumpadSheet(mode: .integer(label: "Puls", unit: "/min"),
                                    initial: befund.puls.map(String.init) ?? "") { val in
                            befund.puls = Int(val)
                        }
                    }
                    Picker("Rhythmus", selection: $befund.pulsRhythmus) {
                        Text("").tag("")
                        Text("Regelmäßig").tag("regelmäßig")
                        Text("Arrhythmisch").tag("arrhythmisch")
                        Text("Tachykard").tag("tachykard")
                        Text("Bradykard").tag("bradykard")
                        Text("Undokumentiert").tag("undokumentiert")
                        Text("Andere …").tag("Andere")
                    }

                    if befund.pulsRhythmus == "Andere" {
                        TextField("Rhythmus eingeben", text: $befund.pulsRhythmus)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Blutdruck")
                            Spacer()
                            Text("\(befund.blutdruckSystolisch.map(String.init) ?? "—") / \(befund.blutdruckDiastolisch.map(String.init) ?? "—")")
                                .foregroundColor(befund.blutdruckSystolisch == nil && befund.blutdruckDiastolisch == nil ? .secondary : .primary)
                            Text("mmHg").font(.caption).foregroundColor(.secondary)
                        }
                        if let (msg, crit) = rrWarn {
                            Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
                        }
                    }
                    .listRowBackground(rrBg)
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeRrNumpad = true }
                    .sheet(isPresented: $zeigeRrNumpad) {
                        NumpadSheet(
                            initialSys: befund.blutdruckSystolisch.map(String.init) ?? "",
                            initialDia: befund.blutdruckDiastolisch.map(String.init) ?? ""
                        ) { sys, dia in
                            befund.blutdruckSystolisch = Int(sys)
                            befund.blutdruckDiastolisch = Int(dia)
                        }
                    }
                }
                CheckboxRow("Rekap. > 2 Sek.", isOn: $befund.rekapillierung)
            } header: { Label("Kreislauf", systemImage: "heart.fill") }

            Section {
                Toggle("EKG abgeleitet", isOn: $befund.ekg)
            } header: { Label("EKG", systemImage: "waveform.path.ecg") }

            if befund.ekg {
                Section {
                    CheckboxRow("Sinusrhythmus",            isOn: $befund.sinusrhythmus)
                    CheckboxRow("Absolute Arrhythmie",      isOn: $befund.absoluteArrhythmie)
                    CheckboxRow("AV-Block II°/III°",        isOn: $befund.avBlock)
                    CheckboxRow("QRS-Tachykardie breit",    isOn: $befund.qrsTachykardieBreit)
                    CheckboxRow("QRS-Tachykardie schmal",   isOn: $befund.qrsTachykardieSchmal)
                    CheckboxRow("Kammerflattern/-flimmern", isOn: $befund.kammerflattern)
                    CheckboxRow("Pulslose elektr. Akt.",    isOn: $befund.pea)
                    CheckboxRow("Asystolie",                isOn: $befund.asystolie)
                    CheckboxRow("Schrittmacherrhythmus",    isOn: $befund.schrittmacher)
                    CheckboxRow("Infarkt-EKG (STEMI/LSB)", isOn: $befund.infarktEkg)
                    CheckboxRow("Nicht beurteilbar",        isOn: $befund.cNichtBeurteilbar)
                } header: { Label("EKG-Rhythmus", systemImage: "waveform") }

                Section {
                    CheckboxRow("SVES",      isOn: $befund.sves)
                    CheckboxRow("VES",       isOn: $befund.ves)
                    CheckboxRow("Monomorph", isOn: $befund.extrasystolenMonomorph)
                    CheckboxRow("Polymorph", isOn: $befund.extrasystolenPolymorph)
                } header: { Text("Extrasystolen") }
            }

            Section {
                Toggle("Blutung vorhanden", isOn: $befund.blutung)
                if befund.blutung {
                    TextField("Lokalisation der Blutung", text: $befund.blutungLokalisation)
                }
            } header: { Label("Befunde", systemImage: "cross.case") }

            Section {
                TextEditor(text: $befund.freitext).frame(minHeight: 80)
                Text("→ PDF S. 1 · ABCDE · C")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } header: { Text("Freitext / Notizen") }

            Section {
                Toggle("Peripher-venöser Zugang", isOn: $massnahmen.peripherVenoes)
                if massnahmen.peripherVenoes {
                    TextField("Ort (z.B. RE Kubital)", text: $massnahmen.peripherVenoesOrt)
                    HStack {
                        TextField("Größe", text: $massnahmen.peripherVenoesGroesse)
                            .keyboardType(.numberPad)
                        Text("G").foregroundColor(.secondary)
                    }
                }
                Toggle("Intraossärer Zugang", isOn: $massnahmen.intraossaer)
                if massnahmen.intraossaer {
                    TextField("Ort (z.B. Tibia)", text: $massnahmen.intraossaerOrt)
                }
                CheckboxRow("Tourniquet", isOn: $massnahmen.tourniquet)
                CheckboxRow("Defibrillation", isOn: $massnahmen.defibrillation)
                CheckboxRow("Kardioversion", isOn: $massnahmen.kardioversion)
            } header: { Label("Maßnahmen Kreislauf", systemImage: "cross.fill") }

        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onZurueck) {
                Label("Weiter zu Disability", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("RDOrange"))
            .padding([.horizontal, .bottom])
            .background(.bar)
        }
        .navigationTitle("C — Circulation")
        .navigationBarTitleDisplayMode(.large)
        .swipeBackEnabled()
    }
}

// MARK: - D: Disability

struct DisabilityView: View {
    @Binding var befund: DisabilityBefund
    @Binding var massnahmen: MassnahmenBefund
    var onZurueck: () -> Void
    @State private var zeigeBzNumpad = false

    private var bzWarn: (String, Bool)? {
        vitalWarnText(befund.blutzucker, normal: 70...140, warning: 54...180,
                      lowWarn: "Hypoglykämie (< 70 mg/dL)", highWarn: "Hyperglykämie (> 140 mg/dL)")
    }
    private var gcsBg: Color {
        // Only color once at least one subscore has been changed from default (E4V5M6)
        guard befund.gcsAugen != 4 || befund.gcsVerbal != 5 || befund.gcsMotor != 6 else { return .clear }
        let gcs = befund.gcsGesamt
        if gcs >= 13 { return Color.green.opacity(0.12) }
        if gcs >= 9  { return Color.yellow.opacity(0.18) }
        return Color.red.opacity(0.15)
    }
    private var schmerzBg: Color {
        let s = befund.schmerz
        if s == 0 { return .clear }
        if s <= 3 { return Color.green.opacity(0.12) }
        if s <= 6 { return Color.yellow.opacity(0.18) }
        return Color.red.opacity(0.15)
    }

    var body: some View {
        Form {
            Section {
                StatusPickerView(status: $befund.status)
            } header: { Text("Gesamtstatus") }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("GCS Gesamt: \(befund.gcsGesamt)")
                        .font(.headline)
                        .foregroundColor(gcsBg == .clear ? .primary : (befund.gcsGesamt >= 13 ? Color.green : (befund.gcsGesamt >= 9 ? Color.orange : Color.red)))
                        .padding(.bottom, 4)

                    GCSStepper(titel: "Augen öffnen (E)",           wert: $befund.gcsAugen,  min: 1, max: 4, labelFor: labelForGCSAugen)
                    GCSStepper(titel: "Verbale Reaktion (V)",        wert: $befund.gcsVerbal, min: 1, max: 5, labelFor: labelForGCSVerbal)
                    GCSStepper(titel: "Motorische Reaktion (M)",     wert: $befund.gcsMotor,  min: 1, max: 6, labelFor: labelForGCSMotor)
                }
                .padding(.vertical, 4)
            } header: { Label("Glasgow Coma Scale", systemImage: "brain.head.profile") }
            .listRowBackground(gcsBg)

            Section {
                Toggle("BEFAST-Schema", isOn: $befund.befastAktiv)
                if befund.befastAktiv {
                    CheckboxRow("B – Balance (Schwindel / Gleichgewichtsstörung)", isOn: $befund.befastBalance)
                    CheckboxRow("E – Eyes (Sehstörung / Doppelbilder)", isOn: $befund.befastEyes)
                    CheckboxRow("F – Face (Gesichtslähmung / hängender Mundwinkel)", isOn: $befund.befastFace)
                    CheckboxRow("A – Arm (Armparese / Armhalteversuch auffällig)", isOn: $befund.befastArm)
                    CheckboxRow("S – Speech (Sprachstörung / Aphasie)", isOn: $befund.befastSpeech)
                    Toggle("T – Zeitpunkt unbekannt", isOn: $befund.befastZeitUnbekannt)
                    if !befund.befastZeitUnbekannt {
                        ZeitFeld(label: "T – Symptombeginn", datum: $befund.befastSymptombeginn)
                    }
                }
            } header: {
                Label("BEFAST-Schema (Schlaganfall)", systemImage: "brain")
            }

            Section {
                CheckboxRow("Wach",                     isOn: $befund.bewWach)
                CheckboxRow("Reagiert auf Ansprache",   isOn: $befund.bewAnsprache)
                CheckboxRow("Reagiert auf Schmerzreiz", isOn: $befund.bewSchmerzreiz)
                CheckboxRow("Bewusstlos",               isOn: $befund.bewusstlos)
                CheckboxRow("Nicht beurteilbar",        isOn: $befund.dNichtBeurteilbar)
            } header: { Label("Bewusstseinslage", systemImage: "person.fill.questionmark") }

            Section {
                Text("Rechts").font(.caption).foregroundColor(.secondary)
                CheckboxRow("Eng",                 isOn: $befund.pupilleReEng)
                CheckboxRow("Mittel",              isOn: $befund.pupilleReMittel)
                CheckboxRow("Weit",                isOn: $befund.pupilleReWeit)
                CheckboxRow("Entrundet",           isOn: $befund.pupilleReEntrundet)
                CheckboxRow("Lichtreaktion", isOn: Binding(
                    get: { !befund.pupilleReKeineLichtreaktion },
                    set: { befund.pupilleReKeineLichtreaktion = !$0 }
                ))
                CheckboxRow("Nicht beurteilbar",   isOn: $befund.pupilleReNichtBeurteilbar)
                Text("Links").font(.caption).foregroundColor(.secondary)
                CheckboxRow("Eng",                 isOn: $befund.pupilleLiEng)
                CheckboxRow("Mittel",              isOn: $befund.pupilleLiMittel)
                CheckboxRow("Weit",                isOn: $befund.pupilleLiWeit)
                CheckboxRow("Entrundet",           isOn: $befund.pupilleLiEntrundet)
                CheckboxRow("Lichtreaktion", isOn: Binding(
                    get: { !befund.pupilleLiKeineLichtreaktion },
                    set: { befund.pupilleLiKeineLichtreaktion = !$0 }
                ))
                CheckboxRow("Nicht beurteilbar",   isOn: $befund.pupilleLiNichtBeurteilbar)
            } header: { Label("Pupillen", systemImage: "eye.circle") }

            Section {
                CheckboxRow("Vorb. neurol. Defizit",  isOn: $befund.neuroVorbestehendesDefizit)
                CheckboxRow("Facialisparese",          isOn: $befund.neuroFacialisparese)
                CheckboxRow("Armparese",               isOn: $befund.neuroArmparese)
                CheckboxRow("Sprachstörung",           isOn: $befund.neuroSprachstoerung)
                CheckboxRow("Sehstörung",              isOn: $befund.neuroSehstoerung)
                CheckboxRow("Babinski-Zeichen",        isOn: $befund.neuroBabinski)
                CheckboxRow("Querschnittsymptomatik",  isOn: $befund.neuroQuerschnitt)
                CheckboxRow("Meningismus",             isOn: $befund.neuroMeningismus)
                CheckboxRow("Demenz",                  isOn: $befund.neuroDemenz)
                CheckboxRow("Nicht beurteilbar",       isOn: $befund.neuroNichtBeurteilbar)
            } header: { Label("Neurologische Auffälligkeiten", systemImage: "brain") }

            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Blutzucker (mg/dL)")
                        Spacer()
                        Text(befund.blutzucker.map { String(format: "%.0f", $0) } ?? "—")
                            .foregroundColor(befund.blutzucker == nil ? .secondary : .primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeBzNumpad = true }
                    .sheet(isPresented: $zeigeBzNumpad) {
                        NumpadSheet(mode: .decimal(label: "Blutzucker", unit: "mg/dL"),
                                    initial: befund.blutzucker.map { String(format: "%.0f", $0) } ?? "") { val in
                            befund.blutzucker = Double(val.replacingOccurrences(of: ",", with: "."))
                        }
                    }
                    if let (msg, crit) = bzWarn {
                        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Schmerzskala NRS: \(befund.schmerz)/10")
                    Slider(value: Binding(
                        get: { Double(befund.schmerz) },
                        set: { befund.schmerz = Int($0) }
                    ), in: 0...10, step: 1)
                    .tint(Color("RDOrange"))
                }
                .listRowBackground(schmerzBg)
            } header: { Label("Weitere Parameter", systemImage: "gauge") }

            Section {
                TextEditor(text: $befund.freitext).frame(minHeight: 80)
                Text("→ PDF S. 1 · ABCDE · D")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } header: { Text("Freitext / Notizen") }

            Section {
                CheckboxRow("BZ-Monitoring", isOn: $massnahmen.monBz)
                CheckboxRow("Krisenintervention", isOn: $massnahmen.krisenintervention)
            } header: { Label("Maßnahmen Neurologie", systemImage: "cross.fill") }

        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onZurueck) {
                Label("Weiter zu Exposure", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("RDOrange"))
            .padding([.horizontal, .bottom])
            .background(.bar)
        }
        .navigationTitle("D — Disability")
        .navigationBarTitleDisplayMode(.large)
        .swipeBackEnabled()
    }
}

func labelForGCSAugen(_ score: Int) -> String {
    switch score {
    case 4: return "Spontan (4)"
    case 3: return "Auf Ansprache (3)"
    case 2: return "Auf Schmerz (2)"
    case 1: return "Keine Reaktion (1)"
    default: return "—"
    }
}

func labelForGCSVerbal(_ score: Int) -> String {
    switch score {
    case 5: return "Orientiert (5)"
    case 4: return "Verwirrt (4)"
    case 3: return "Unangemessene Worte (3)"
    case 2: return "Unverständliche Laute (2)"
    case 1: return "Keine Reaktion (1)"
    default: return "—"
    }
}

func labelForGCSMotor(_ score: Int) -> String {
    switch score {
    case 6: return "Befolgt Aufforderungen (6)"
    case 5: return "Gezielte Schmerzabwehr (5)"
    case 4: return "Auf Schmerzreiz zurückziehen (4)"
    case 3: return "Beugesynergismus (pathologisch) (3)"
    case 2: return "Strecksynergismus (2)"
    case 1: return "Keine Reaktion (1)"
    default: return "—"
    }
}

struct GCSStepper: View {
    let titel: String
    @Binding var wert: Int
    let min: Int
    let max: Int
    let labelFor: (Int) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(titel).font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Stepper(value: $wert, in: min...max) {
                    Text("\(wert)")
                        .font(.subheadline.monospacedDigit())
                        .frame(minWidth: 24, alignment: .trailing)
                }
            }
            Text(labelFor(wert))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 2)
        }
    }
}

// MARK: - E: Exposure

struct ExposureView: View {
    @ObservedObject var protokoll: EinsatzProtokoll
    var onZurueck: () -> Void
    @State private var zeigeTempNumpad = false

    private var tempBg: Color {
        vitalBg(protokoll.exposure.temperatur, normal: 36.0...37.5, warning: 35.0...38.5)
    }
    private var tempWarn: (String, Bool)? {
        vitalWarnText(protokoll.exposure.temperatur, normal: 36.0...37.5, warning: 35.0...38.5,
                      lowWarn: "Hypothermie (< 36.0°C)", highWarn: "Fieber / Hyperthermie (> 37.5°C)")
    }

    var body: some View {
        Form {
            Section {
                StatusPickerView(status: $protokoll.exposure.status)
            } header: { Text("Gesamtstatus") }

            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Körpertemperatur (°C)")
                        Spacer()
                        Text(protokoll.exposure.temperatur.map { String(format: "%.1f", $0) } ?? "—")
                            .foregroundColor(protokoll.exposure.temperatur == nil ? .secondary : .primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeTempNumpad = true }
                    .sheet(isPresented: $zeigeTempNumpad) {
                        NumpadSheet(mode: .decimal(label: "Körpertemperatur", unit: "°C"),
                                    initial: protokoll.exposure.temperatur.map { String(format: "%.1f", $0) } ?? "") { val in
                            protokoll.exposure.temperatur = Double(val.replacingOccurrences(of: ",", with: "."))
                        }
                    }
                    if let (msg, crit) = tempWarn {
                        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
                    }
                }
                .listRowBackground(tempBg)
                TextField("Hautfarbe / Hautturgor", text: $protokoll.exposure.hautfarbe)
                Toggle("Ödeme", isOn: $protokoll.exposure.oedeme)
            } header: { Label("Allgemeinbefund", systemImage: "person.fill") }

            Section {
                CheckboxRow("Nicht untersucht",    isOn: $protokoll.exposure.hautNichtUntersucht)
                CheckboxRow("Stehende Hautfalten", isOn: $protokoll.exposure.stehendeHautfalten)
                CheckboxRow("Kaltschweißig",       isOn: $protokoll.exposure.kaltschweissig)
                CheckboxRow("Dekubitus",           isOn: $protokoll.exposure.dekubitus)
                CheckboxRow("Exanthem",            isOn: $protokoll.exposure.exanthem)
                CheckboxRow("Nicht beurteilbar",   isOn: $protokoll.exposure.hautNichtBeurteilbar)
            } header: { Label("Haut", systemImage: "hand.raised") }

            Section {
                TextField("Verletzungen / Befunde (z.B. Hämatome, Wunden)", text: $protokoll.exposure.verletzungen)
                    .lineLimit(4)
            } header: { Label("Verletzungen", systemImage: "bandage") }

            Section {
                Toggle("Trauma", isOn: $protokoll.exposure.trauma)
                if protokoll.exposure.trauma {
                    TextField("Traumamechanismus (z.B. Sturz, VU, Assault)", text: $protokoll.exposure.traumaMechanismus)
                    Toggle("Bewusstseinsverlust", isOn: $protokoll.exposure.bewusstseinsverlust)
                    Toggle("Helm getragen", isOn: $protokoll.exposure.helmGetragen)
                    Toggle("Gurt getragen", isOn: $protokoll.exposure.gurtGetragen)
                    TextField("Sichtbare Deformitäten", text: $protokoll.exposure.sichtbareDeformitaeten)
                    TextField("Schmerzlokalisation", text: $protokoll.exposure.schmerzLokalisation)
                    Toggle("Frakturverdacht", isOn: $protokoll.exposure.frakturVerdacht)
                    Toggle("Äußere Blutung", isOn: $protokoll.exposure.blutungExtern)
                    Toggle("Rücken-/Nackenschmerz", isOn: $protokoll.exposure.rueckenNackenSchmerz)
                    Toggle("Bewegungseinschränkung", isOn: $protokoll.exposure.bewegungseinschraenkung)
                }
            } header: { Label("Trauma", systemImage: "figure.fall") }

            Section {
                CheckboxRow("Unauffällig",       isOn: $protokoll.psyche.unauffaellig)
                CheckboxRow("Ängstlich",         isOn: $protokoll.psyche.aengstlich)
                CheckboxRow("Wahnhaft",          isOn: $protokoll.psyche.wahnhaft)
                CheckboxRow("Suizidal",          isOn: $protokoll.psyche.suizidal)
                CheckboxRow("Erregt",            isOn: $protokoll.psyche.erregt)
                CheckboxRow("Verlangsamt",       isOn: $protokoll.psyche.verlangsamt)
                CheckboxRow("Depressiv",         isOn: $protokoll.psyche.depressiv)
                CheckboxRow("Euphorisch",        isOn: $protokoll.psyche.euphorisch)
                CheckboxRow("Verwirrt",          isOn: $protokoll.psyche.verwirrt)
                CheckboxRow("Motorisch unruhig", isOn: $protokoll.psyche.motorischUnruhig)
                CheckboxRow("Aggressiv",         isOn: $protokoll.psyche.aggressiv)
                CheckboxRow("Nicht beurteilbar", isOn: $protokoll.psyche.nichtBeurteilbar)
            } header: { Label("Psyche", systemImage: "brain.head.profile") }

            Section {
                TextEditor(text: $protokoll.exposure.freitext).frame(minHeight: 80)
                Text("→ PDF S. 1 · ABCDE · E")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } header: { Text("Freitext / Notizen") }

            Section {
                CheckboxRow("Wärmeerhalt", isOn: $protokoll.massnahmen.waermeerhalt)
                CheckboxRow("Kühlung", isOn: $protokoll.massnahmen.kuehlung)
                CheckboxRow("Verband", isOn: $protokoll.massnahmen.verband)
                CheckboxRow("Beckenschlinge", isOn: $protokoll.massnahmen.beckenschlinge)
                CheckboxRow("Extremitätenschienung", isOn: $protokoll.massnahmen.extremitaetenschienung)
                CheckboxRow("Vakuummatratze", isOn: $protokoll.massnahmen.vakuummatratze)
            } header: { Label("Maßnahmen Exposure", systemImage: "cross.fill") }

        }
        .navigationTitle("E — Exposure")
        .navigationBarTitleDisplayMode(.large)
        .swipeBackEnabled()
    }
}

