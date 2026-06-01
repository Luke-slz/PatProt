import SwiftUI

struct VerlaufView: View {
    @Binding var messungen: [VerlaufsMessung]
    var onBack: () -> Void

    @EnvironmentObject private var protokoll: EinsatzProtokoll

    @State private var zeigeNeueMessung = false
    @State private var bearbeiteMessung: VerlaufsMessung? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                kreislaufHinweis
                if !messungen.isEmpty {
                    trendUebersicht
                }
                messungsListe
                neueMessungButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Verlauf & Therapie")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .onAppear { abcdeUebernehmen() }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    bearbeiteMessung = nil
                    zeigeNeueMessung = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $zeigeNeueMessung) {
            MessungEingabeSheet(
                messung: bearbeiteMessung,
                onSpeichern: { messung in
                    if let idx = messungen.firstIndex(where: { $0.id == messung.id }) {
                        messungen[idx] = messung
                    } else {
                        messungen.append(messung)
                    }
                    messungen.sort { $0.zeitpunkt < $1.zeitpunkt }
                    zeigeNeueMessung = false
                },
                onAbbrechen: { zeigeNeueMessung = false }
            )
        }
    }

    // MARK: - Kreislauf-Hinweis

    private var kreislaufHinweis: some View {
        let sorted = messungen.sorted { $0.zeitpunkt < $1.zeitpunkt }
        let letzte3 = sorted.suffix(3).compactMap { $0.blutdruckSys }
        let pathologisch = letzte3.count >= 3 && letzte3.allSatisfy { $0 < 90 || $0 > 180 }

        return Group {
            if pathologisch {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kreislaufinstabilität").font(.subheadline).fontWeight(.semibold)
                        Text("3 konsekutive pathologische Blutdruckwerte – Kreislauf neu beurteilen.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Trend-Übersicht

    private var trendUebersicht: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verlaufsüberblick")
                .font(.subheadline).fontWeight(.semibold)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if let erste = messungen.first, let letzte = messungen.last, messungen.count > 1 {
                        TrendBadge(icon: "wind",       label: "AF",   erster: erste.atemFrequenz.map(Double.init),  letzter: letzte.atemFrequenz.map(Double.init),  einheit: "/min",  normal: 12...20)
                        TrendBadge(icon: "lungs",      label: "SpO₂", erster: erste.spo2.map(Double.init),          letzter: letzte.spo2.map(Double.init),          einheit: "%",     normal: 95...100)
                        TrendBadge(icon: "heart",      label: "Puls", erster: erste.puls.map(Double.init),          letzter: letzte.puls.map(Double.init),          einheit: "/min",  normal: 60...100)
                        TrendBadge(icon: "drop",       label: "sys",  erster: erste.blutdruckSys.map(Double.init),  letzter: letzte.blutdruckSys.map(Double.init),  einheit: "mmHg",  normal: 100...140)
                        TrendBadge(icon: "brain",      label: "GCS",  erster: erste.gcsGesamt.map(Double.init),     letzter: letzte.gcsGesamt.map(Double.init),     einheit: "",      normal: 13...15)
                        TrendBadge(icon: "thermometer",label: "Temp", erster: erste.temperatur,                    letzter: letzte.temperatur,                     einheit: "°C",    normal: 36.0...37.5)
                    } else {
                        Text("Für Trends mindestens 2 Messungen erfassen")
                            .font(.caption).foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Messungsliste

    private var dreifachRRWarnung: Bool {
        let sorted = protokoll.verlaufMessungen.sorted { $0.zeitpunkt < $1.zeitpunkt }
        guard sorted.count >= 3 else { return false }
        let letzte3 = sorted.suffix(3).compactMap { $0.blutdruckSys }
        guard letzte3.count == 3 else { return false }
        return letzte3.allSatisfy { $0 < 90 || $0 > 180 }
    }

    private var messungsListe: some View {
        VStack(spacing: 10) {
            if dreifachRRWarnung {
                Label("Kreislaufinstabilität: Blutdruck seit 3 Messungen pathologisch – Kreislauf neu beurteilen",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.orange.opacity(0.10))
                    .cornerRadius(10)
            }
            ForEach(Array(messungen.enumerated()), id: \.element.id) { index, messung in
                MessungsKarte(
                    messung: messung,
                    label: index == 0 ? "Auffindewert" : "Verlauf \(index + 1)",
                    onEdit: {
                        bearbeiteMessung = messung
                        zeigeNeueMessung = true
                    },
                    onDelete: {
                        messungen.removeAll { $0.id == messung.id }
                    }
                )
            }

            if messungen.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Noch keine Verlaufsmessungen")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("Füge Messungen mit Zeitstempel hinzu,\num den Verlauf zu dokumentieren.")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
            }
        }
    }

    private var neueMessungButton: some View {
        Button {
            bearbeiteMessung = nil
            zeigeNeueMessung = true
        } label: {
            Label("Neue Messung erfassen", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("RDOrange"))
                .foregroundColor(.white)
                .cornerRadius(14)
                .font(.headline)
        }
    }

    // MARK: - ABCDE-Werte automatisch übernehmen (bei onAppear)

    private func abcdeUebernehmen() {
        // Werte aus Protokoll lesen
        let af   = protokoll.breathing.atemFrequenz
        let spo2 = protokoll.breathing.spo2
        let puls = protokoll.circulation.puls
        let sys  = protokoll.circulation.blutdruckSystolisch
        let dia  = protokoll.circulation.blutdruckDiastolisch
        let gcs  = protokoll.disability.status != .unbewertet ? protokoll.disability.gcsGesamt : nil
        let bz   = protokoll.disability.blutzucker
        let temp = protokoll.exposure.temperatur

        // Nichts eingetragen → gar nichts tun
        guard af != nil || spo2 != nil || puls != nil || sys != nil ||
              gcs != nil || bz != nil || temp != nil else { return }

        if let idx = messungen.firstIndex(where: { $0.autoImportiert }) {
            // Bestehenden Auto-Eintrag aktualisieren (Zeitstempel bleibt)
            messungen[idx].atemFrequenz  = af
            messungen[idx].spo2          = spo2
            messungen[idx].puls          = puls
            messungen[idx].blutdruckSys  = sys
            messungen[idx].blutdruckDia  = dia
            messungen[idx].gcsGesamt     = gcs
            messungen[idx].blutzucker    = bz
            messungen[idx].temperatur    = temp
        } else {
            // Ersten Eintrag anlegen
            var m = VerlaufsMessung()
            m.autoImportiert = true
            m.atemFrequenz   = af
            m.spo2           = spo2
            m.puls           = puls
            m.blutdruckSys   = sys
            m.blutdruckDia   = dia
            m.gcsGesamt      = gcs
            m.blutzucker     = bz
            m.temperatur     = temp
            messungen.append(m)
            messungen.sort { $0.zeitpunkt < $1.zeitpunkt }
        }
    }
}

// MARK: - Messungs-Karte

private struct MessungsKarte: View {
    let messung: VerlaufsMessung
    var label: String = ""
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var zeitFormatiert: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: messung.zeitpunkt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color("RDOrange"))
                        .font(.caption)
                    Text(zeitFormatiert + " Uhr")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(Color("RDOrange"))
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 9)).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(label == "Auffindewert" ? Color("RDOrange") : Color.secondary.opacity(0.7))
                            .cornerRadius(4)
                    }
                    if messung.autoImportiert {
                        Text("ABCDE")
                            .font(.system(size: 9)).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
                Spacer()
                Menu {
                    Button { onEdit() } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }

            // Vitalwerte-Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                if let af = messung.atemFrequenz {
                    VitalBadge(label: "AF", wert: "\(af)/min", farbe: atemFarbe(af))
                }
                if let spo2 = messung.spo2 {
                    VitalBadge(label: "SpO₂", wert: "\(spo2)%", farbe: spo2Farbe(spo2))
                }
                if let puls = messung.puls {
                    VitalBadge(label: "Puls", wert: "\(puls)/min", farbe: pulsFarbe(puls))
                }
                if let sys = messung.blutdruckSys, let dia = messung.blutdruckDia {
                    VitalBadge(label: "RR", wert: "\(sys)/\(dia)", farbe: rrFarbe(sys))
                }
                if let gcs = messung.gcsGesamt {
                    VitalBadge(label: "GCS", wert: "\(gcs)", farbe: gcsFarbe(gcs))
                }
                if let bz = messung.blutzucker {
                    VitalBadge(label: "BZ", wert: String(format: "%.0f", bz), farbe: .blue)
                }
                if let temp = messung.temperatur {
                    VitalBadge(label: "Temp", wert: String(format: "%.1f°C", temp), farbe: .orange)
                }
            }

            if !messung.massnahmen.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "cross.circle.fill")
                        .foregroundColor(Color("RDOrange"))
                        .font(.caption)
                    Text(messung.massnahmen)
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            if !messung.freitext.isEmpty {
                Text(messung.freitext)
                    .font(.caption).foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private func atemFarbe(_ v: Int) -> Color {
        (12...20).contains(v) ? .green : (v < 8 || v > 30) ? .red : .orange
    }
    private func spo2Farbe(_ v: Int) -> Color {
        v >= 95 ? .green : v >= 90 ? .orange : .red
    }
    private func pulsFarbe(_ v: Int) -> Color {
        (60...100).contains(v) ? .green : (v < 40 || v > 130) ? .red : .orange
    }
    private func rrFarbe(_ v: Int) -> Color {
        (100...140).contains(v) ? .green : (v < 80 || v > 180) ? .red : .orange
    }
    private func gcsFarbe(_ v: Int) -> Color {
        v >= 13 ? .green : v >= 9 ? .orange : .red
    }
}

// MARK: - Vital Badge

private struct VitalBadge: View {
    let label: String
    let wert: String
    let farbe: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10)).foregroundColor(.secondary)
            Text(wert)
                .font(.system(size: 13)).fontWeight(.semibold)
                .foregroundColor(farbe)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(farbe.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Trend Badge

private struct TrendBadge: View {
    let icon: String
    let label: String
    let erster: Double?
    let letzter: Double?
    let einheit: String
    let normal: ClosedRange<Double>

    private var pfeil: String {
        guard let e = erster, let l = letzter else { return "minus" }
        if l > e { return "arrow.up" }
        if l < e { return "arrow.down" }
        return "minus"
    }

    private var farbe: Color {
        guard let l = letzter else { return .secondary }
        return normal.contains(l) ? .green : .red
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            if let l = letzter {
                HStack(spacing: 2) {
                    Text(einheit.isEmpty ? String(format: "%.0f", l) : String(format: l < 10 ? "%.1f" : "%.0f", l))
                        .font(.system(size: 13)).fontWeight(.bold)
                        .foregroundColor(farbe)
                    Image(systemName: pfeil)
                        .font(.system(size: 9))
                        .foregroundColor(farbe)
                }
            } else {
                Text("–").font(.caption).foregroundColor(.secondary)
            }
            Text(label)
                .font(.system(size: 9)).foregroundColor(.secondary)
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Messungs-Eingabe Sheet

struct MessungEingabeSheet: View {
    let messung: VerlaufsMessung?
    let onSpeichern: (VerlaufsMessung) -> Void
    let onAbbrechen: () -> Void

    @State private var zeitpunkt: Date
    @State private var af: String
    @State private var spo2: String
    @State private var puls: String
    @State private var rrSys: String
    @State private var rrDia: String
    @State private var gcs: String
    @State private var bz: String
    @State private var temp: String
    @State private var massnahmen: String
    @State private var freitext: String

    init(messung: VerlaufsMessung?, onSpeichern: @escaping (VerlaufsMessung) -> Void, onAbbrechen: @escaping () -> Void) {
        self.messung = messung
        self.onSpeichern = onSpeichern
        self.onAbbrechen = onAbbrechen

        _zeitpunkt   = State(initialValue: messung?.zeitpunkt ?? Date())
        _af          = State(initialValue: messung?.atemFrequenz.map(String.init) ?? "")
        _spo2        = State(initialValue: messung?.spo2.map(String.init) ?? "")
        _puls        = State(initialValue: messung?.puls.map(String.init) ?? "")
        _rrSys       = State(initialValue: messung?.blutdruckSys.map(String.init) ?? "")
        _rrDia       = State(initialValue: messung?.blutdruckDia.map(String.init) ?? "")
        _gcs         = State(initialValue: messung?.gcsGesamt.map(String.init) ?? "")
        _bz          = State(initialValue: messung?.blutzucker.map { String(format: "%.1f", $0) } ?? "")
        _temp        = State(initialValue: messung?.temperatur.map { String(format: "%.1f", $0) } ?? "")
        _massnahmen  = State(initialValue: messung?.massnahmen ?? "")
        _freitext    = State(initialValue: messung?.freitext ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeitpunkt") {
                    DatePicker("Uhrzeit", selection: $zeitpunkt, displayedComponents: .hourAndMinute)
                }

                Section("Vitalparameter") {
                    ZahlenFeld(label: "AF (/min)", text: $af, placeholder: "z.B. 16")
                    ZahlenFeld(label: "SpO₂ (%)", text: $spo2, placeholder: "z.B. 97")
                    ZahlenFeld(label: "Puls (/min)", text: $puls, placeholder: "z.B. 72")
                    HStack {
                        ZahlenFeld(label: "RR syst.", text: $rrSys, placeholder: "120")
                        Text("/").foregroundColor(.secondary)
                        ZahlenFeld(label: "RR diast.", text: $rrDia, placeholder: "80")
                    }
                    ZahlenFeld(label: "GCS (3–15)", text: $gcs, placeholder: "z.B. 15")
                    ZahlenFeld(label: "BZ (mg/dL)", text: $bz, placeholder: "z.B. 95", istDezimal: true)
                    ZahlenFeld(label: "Temp (°C)", text: $temp, placeholder: "z.B. 36.8", istDezimal: true)
                }

                Section("Maßnahmen in dieser Phase") {
                    TextEditor(text: $massnahmen)
                        .frame(minHeight: 60)
                }

                Section("Notizen / Freitext") {
                    TextEditor(text: $freitext)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(messung == nil ? "Neue Messung" : "Messung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onAbbrechen)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { speichern() }
                }
            }
        }
    }

    private func speichern() {
        var m = messung ?? VerlaufsMessung()
        m.zeitpunkt     = zeitpunkt
        m.atemFrequenz  = Int(af)
        m.spo2          = Int(spo2)
        m.puls          = Int(puls)
        m.blutdruckSys  = Int(rrSys)
        m.blutdruckDia  = Int(rrDia)
        m.gcsGesamt     = Int(gcs)
        m.blutzucker    = Double(bz.replacingOccurrences(of: ",", with: "."))
        m.temperatur    = Double(temp.replacingOccurrences(of: ",", with: "."))
        m.massnahmen    = massnahmen
        m.freitext      = freitext
        onSpeichern(m)
    }
}

private struct ZahlenFeld: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var istDezimal: Bool = false
    @State private var zeigeNumpad = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(text.isEmpty ? placeholder : text)
                .foregroundColor(text.isEmpty ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeigeNumpad = true }
        .sheet(isPresented: $zeigeNumpad) {
            if istDezimal {
                NumpadSheet(mode: .decimal(label: label, unit: ""),
                            initial: text) { val in text = val }
            } else {
                NumpadSheet(mode: .integer(label: label, unit: "", maxDigits: 4),
                            initial: text) { val in text = val }
            }
        }
    }
}
