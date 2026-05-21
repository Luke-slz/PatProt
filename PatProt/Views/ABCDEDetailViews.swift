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
            } header: { Text("Freitext / Notizen") }

            Section {
                Label("Atemwegssicherung & Maßnahmen werden unter \"Maßnahmen\" dokumentiert.", systemImage: "info.circle")
                    .font(.caption).foregroundColor(.secondary)
            }

            Section {
                Button(action: onZurueck) {
                    Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
            }
        }
        .navigationTitle("A — Airway")
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
    }
}

// MARK: - B: Breathing

struct BreathingView: View {
    @Binding var befund: BreathingBefund
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
                Picker("Atemgeräusche", selection: $befund.atemgeraeusche) {
                    Text("").tag("")
                    Text("Vesikulär (normal)").tag("Vesikulär (normal)")
                    Text("Giemen").tag("Giemen")
                    Text("Rasseln").tag("Rasseln")
                    Text("Stridor").tag("Stridor")
                    Text("Brummen").tag("Brummen")
                    Text("Kein Atemgeräusch").tag("Kein Atemgeräusch")
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
                if befund.atemgeraeusche != "Andere" && !["", "Vesikulär (normal)", "Giemen", "Rasseln", "Stridor", "Brummen", "Kein Atemgeräusch"].contains(befund.atemgeraeusche) {
                    andereAtemgeraeusche = befund.atemgeraeusche
                }
            }

            Section {
                Toggle("Dyspnoe", isOn: $befund.dyspnoe)
                Toggle("Zyanose", isOn: $befund.zyanose)
            } header: { Label("Klinische Zeichen", systemImage: "eye") }

            Section {
                Label("Maßnahmen (O₂, Beatmung etc.) werden unter \"Maßnahmen\" dokumentiert.", systemImage: "info.circle")
                    .font(.caption).foregroundColor(.secondary)
            }

            Section {
                TextEditor(text: $befund.freitext).frame(minHeight: 80)
            } header: { Text("Freitext / Notizen") }

            Section {
                Button(action: onZurueck) {
                    Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
            }
        }
        .navigationTitle("B — Breathing")
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
    }
}

// MARK: - C: Circulation

struct CirculationView: View {
    @Binding var befund: CirculationBefund
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
            } header: { Label("Kreislauf", systemImage: "heart.fill") }

            Section {
                Toggle("EKG abgeleitet", isOn: $befund.ekg)
                if befund.ekg {
                    TextField("EKG-Befund", text: $befund.ekgBefund)
                }
            } header: { Label("EKG", systemImage: "waveform.path.ecg") }

            Section {
                Toggle("Blutung vorhanden", isOn: $befund.blutung)
                if befund.blutung {
                    TextField("Lokalisation der Blutung", text: $befund.blutungLokalisation)
                }
                Label("Zugänge & weitere Maßnahmen werden unter \"Maßnahmen\" dokumentiert.", systemImage: "info.circle")
                    .font(.caption).foregroundColor(.secondary)
            } header: { Label("Befunde", systemImage: "cross.case") }

            Section {
                TextEditor(text: $befund.freitext).frame(minHeight: 80)
            } header: { Text("Freitext / Notizen") }

            Section {
                Button(action: onZurueck) {
                    Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
            }
        }
        .navigationTitle("C — Circulation")
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
    }
}

// MARK: - D: Disability

struct DisabilityView: View {
    @Binding var befund: DisabilityBefund
    var onZurueck: () -> Void

    private var bzWarn: (String, Bool)? {
        vitalWarnText(befund.blutzucker, normal: 3.9...7.8, warning: 3.0...10.0,
                      lowWarn: "Hypoglykämie (< 3.9 mmol/L)", highWarn: "Hyperglykämie (> 7.8 mmol/L)")
    }
    private var gcsBg: Color {
        // Only color once at least one subscore has been changed from minimum
        guard befund.gcsAugen > 1 || befund.gcsVerbal > 1 || befund.gcsMotor > 1 else { return .clear }
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

                    HStack {
                        Text("Augen öffnen (E)").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Menu {
                            Button("Spontan (4)") { befund.gcsAugen = 4 }
                            Button("Auf Ansprache (3)") { befund.gcsAugen = 3 }
                            Button("Auf Schmerz (2)") { befund.gcsAugen = 2 }
                            Button("Keine Reaktion (1)") { befund.gcsAugen = 1 }
                        } label: {
                            Text(labelForGCSAugen(befund.gcsAugen)).font(.subheadline)
                        }
                    }
                    HStack {
                        Text("Verbale Reaktion (V)").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Menu {
                            Button("Orientiert (5)") { befund.gcsVerbal = 5 }
                            Button("Verwirrt (4)") { befund.gcsVerbal = 4 }
                            Button("Unangemessene Worte (3)") { befund.gcsVerbal = 3 }
                            Button("Unverständliche Laute (2)") { befund.gcsVerbal = 2 }
                            Button("Keine Reaktion (1)") { befund.gcsVerbal = 1 }
                        } label: {
                            Text(labelForGCSVerbal(befund.gcsVerbal)).font(.subheadline)
                        }
                    }
                    HStack {
                        Text("Motorische Reaktion (M)").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Menu {
                            Button("Folgt Aufforderungen (6)") { befund.gcsMotor = 6 }
                            Button("Gezielte Schmerzabwehr (5)") { befund.gcsMotor = 5 }
                            Button("Beugesynergismen (4)") { befund.gcsMotor = 4 }
                            Button("Strecksynergismen (3)") { befund.gcsMotor = 3 }
                            Button("Auf Schmerz verzieht (2)") { befund.gcsMotor = 2 }
                            Button("Keine Reaktion (1)") { befund.gcsMotor = 1 }
                        } label: {
                            Text(labelForGCSMotor(befund.gcsMotor)).font(.subheadline)
                        }
                    }
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
                TextField("Pupillen links (z.B. weit, eng, mittel)", text: $befund.pupillenLinks)
                TextField("Pupillen rechts", text: $befund.pupillenRechts)
                Toggle("Lichtreaktion vorhanden", isOn: $befund.pupillenReaktion)
            } header: { Label("Pupillen", systemImage: "eye.circle") }

            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Blutzucker (mmol/L)")
                        Spacer()
                        TextField("optional", value: $befund.blutzucker, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
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
            } header: { Text("Freitext / Notizen") }

            Section {
                Button(action: onZurueck) {
                    Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
            }
        }
        .navigationTitle("D — Disability")
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
    }
}

fileprivate func labelForGCSAugen(_ score: Int) -> String {
    switch score {
    case 4: return "Spontan (4)"
    case 3: return "Auf Ansprache (3)"
    case 2: return "Auf Schmerz (2)"
    case 1: return "Keine Reaktion (1)"
    default: return "—"
    }
}

fileprivate func labelForGCSVerbal(_ score: Int) -> String {
    switch score {
    case 5: return "Orientiert (5)"
    case 4: return "Verwirrt (4)"
    case 3: return "Unangemessene Worte (3)"
    case 2: return "Unverständliche Laute (2)"
    case 1: return "Keine Reaktion (1)"
    default: return "—"
    }
}

fileprivate func labelForGCSMotor(_ score: Int) -> String {
    switch score {
    case 6: return "Folgt Aufforderungen (6)"
    case 5: return "Gezielte Schmerzabwehr (5)"
    case 4: return "Beugesynergismen (4)"
    case 3: return "Strecksynergismen (3)"
    case 2: return "Auf Schmerz verzieht (2)"
    case 1: return "Keine Reaktion (1)"
    default: return "—"
    }
}

struct GCSStepper: View {
    let titel: String
    @Binding var wert: Int
    let min: Int
    let max: Int

    var body: some View {
        HStack {
            Text(titel).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Stepper("\(wert)", value: $wert, in: min...max)
                .labelsHidden()
            Text("\(wert)").frame(width: 24).font(.subheadline.monospacedDigit())
        }
    }
}

// MARK: - E: Exposure

struct ExposureView: View {
    @Binding var befund: ExposureBefund
    var onZurueck: () -> Void

    private var tempBg: Color {
        vitalBg(befund.temperatur, normal: 36.0...37.5, warning: 35.0...38.5)
    }
    private var tempWarn: (String, Bool)? {
        vitalWarnText(befund.temperatur, normal: 36.0...37.5, warning: 35.0...38.5,
                      lowWarn: "Hypothermie (< 36.0°C)", highWarn: "Fieber / Hyperthermie (> 37.5°C)")
    }

    var body: some View {
        Form {
            Section {
                StatusPickerView(status: $befund.status)
            } header: { Text("Gesamtstatus") }

            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Körpertemperatur (°C)")
                        Spacer()
                        TextField("z.B. 37.0", value: $befund.temperatur, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    }
                    if let (msg, crit) = tempWarn {
                        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
                    }
                }
                .listRowBackground(tempBg)
                TextField("Hautfarbe / Hautturgor", text: $befund.hautfarbe)
                Toggle("Ödeme", isOn: $befund.oedeme)
            } header: { Label("Allgemeinbefund", systemImage: "person.fill") }

            Section {
                TextField("Verletzungen / Befunde (z.B. Hämatome, Wunden)", text: $befund.verletzungen)
                    .lineLimit(4)
            } header: { Label("Verletzungen", systemImage: "bandage") }
            
            Section {
                Toggle("Trauma", isOn: $befund.trauma)
                if befund.trauma {
                    TextField("Traumamechanismus (z.B. Sturz, VU, Assault)", text: $befund.traumaMechanismus)
                    Toggle("Bewusstseinsverlust", isOn: $befund.bewusstseinsverlust)
                    Toggle("Helm getragen", isOn: $befund.helmGetragen)
                    Toggle("Gurt getragen", isOn: $befund.gurtGetragen)
                    TextField("Sichtbare Deformitäten", text: $befund.sichtbareDeformitaeten)
                    TextField("Schmerzlokalisation", text: $befund.schmerzLokalisation)
                    Toggle("Frakturverdacht", isOn: $befund.frakturVerdacht)
                    Toggle("Äußere Blutung", isOn: $befund.blutungExtern)
                    Toggle("Rücken-/Nackenschmerz", isOn: $befund.rueckenNackenSchmerz)
                    Toggle("Bewegungseinschränkung", isOn: $befund.bewegungseinschraenkung)
                }
            } header: { Label("Trauma", systemImage: "figure.fall") }

            Section {
                TextEditor(text: $befund.freitext).frame(minHeight: 80)
            } header: { Text("Freitext / Notizen") }

            Section {
                Button(action: onZurueck) {
                    Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
            }
        }
        .navigationTitle("E — Exposure")
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
    }
}

