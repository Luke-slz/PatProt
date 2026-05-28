import SwiftUI
import MessageUI

struct AbschlussView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var protokoll: EinsatzProtokoll
    @State private var pdfURL: URL? = nil
    @State private var zeigeShareSheet = false
    @State private var isGenerating = false
    @AppStorage("recipientEmail") private var recipientEmail: String = ""
    @State private var zeigeEinstellungen = false
    @State private var zeigeMailComposer = false
    @State private var pdfFehler = false
    @State private var gespeichert = false
    @State private var speicherFehler = false
    @State private var mailNichtVerfügbar = false
    @State private var zeigeUebRrSys  = false
    @State private var zeigeUebRrDia  = false
    @State private var zeigeUebHf     = false
    @State private var zeigeUebSpo2   = false
    @State private var zeigeUebAf     = false
    @State private var zeigeUebBz     = false
    @State private var zeigeUebTemp   = false
    var onBack: () -> Void

    var body: some View {
        Form {
            // Übersicht
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green).font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protokoll bereit")
                            .font(.subheadline.bold())
                        Text("\(protokoll.patientDaten.vorname) \(protokoll.patientDaten.nachname)")
                            .font(.caption).foregroundColor(.secondary)
                        if let alarmzeit = protokoll.einsatzOrt.alarmzeit {
                            Text(alarmzeit, style: .date)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Verfasser
            Section {
                Picker("Verfasser", selection: $protokoll.verfasser) {
                    ForEach(ProtokollVerfasser.allCases, id: \.self) { v in
                        Text(v.rawValue).tag(v as ProtokollVerfasser)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Label("Protokoll geschrieben von", systemImage: "person.text.rectangle")
            }

            // Übergabe-Messwerte
            Section {
                uebRow("RR syst.",   $protokoll.uebergabeMesswerte.rrSys,  "mmHg", $zeigeUebRrSys)
                uebRow("RR diast.",  $protokoll.uebergabeMesswerte.rrDia,  "mmHg", $zeigeUebRrDia)
                uebRow("HF /min",    $protokoll.uebergabeMesswerte.hf,     "/min", $zeigeUebHf)
                uebRow("SpO₂ %",     $protokoll.uebergabeMesswerte.spo2,   "%",    $zeigeUebSpo2)
                uebRow("AF /min",    $protokoll.uebergabeMesswerte.af,     "/min", $zeigeUebAf)
                uebRow("BZ",         $protokoll.uebergabeMesswerte.bz,     "mg/dL", $zeigeUebBz, useDecimal: true)
                uebRow("Temp °C",    $protokoll.uebergabeMesswerte.temp,   "°C",   $zeigeUebTemp, useDecimal: true)
            } header: {
                Label("Übergabe-Messwerte", systemImage: "waveform.path.ecg")
            }

            // Verlaufstrend — nur wenn ≥2 Verlaufs-Messungen
            let sortedMessungen = protokoll.verlaufMessungen.sorted(by: { $0.zeitpunkt < $1.zeitpunkt })
            if sortedMessungen.count >= 2,
               let ersteMessung = sortedMessungen.first,
               let letzteMessung = sortedMessungen.last {
                Section {
                    trendRow("Puls",  ersteMessung.puls,      letzteMessung.puls,      "/min", normal: 60...100)
                    trendRow("SpO₂",  ersteMessung.spo2,      letzteMessung.spo2,      "%",    normal: 95...100)
                    trendRow("GCS",   ersteMessung.gcsGesamt, letzteMessung.gcsGesamt, "",     normal: 13...15)
                    if let es = ersteMessung.blutdruckSys, let ed = ersteMessung.blutdruckDia,
                       let ls = letzteMessung.blutdruckSys, let ld = letzteMessung.blutdruckDia {
                        let pfeil = ls > es ? "↑" : ls < es ? "↓" : "→"
                        let farbe: Color = (100...140).contains(ls) ? .green : .red
                        HStack {
                            Text("RR").foregroundColor(.secondary).font(.subheadline)
                            Spacer()
                            Text("\(es)/\(ed) \(pfeil) \(ls)/\(ld) mmHg")
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(farbe)
                        }
                    }
                } header: {
                    Label("Verlaufstrend (Anfang → Aktuell)", systemImage: "chart.line.uptrend.xyaxis")
                }
            }

            // Transportziel
            Section {
                TextField("Rettungsmittel / Kennung (z.B. RTW 10/83-2)", text: $protokoll.uebergabeAn)
                TextField("Zustand bei Übergabe", text: $protokoll.zustandBeiUebergabe)
            } header: {
                Label("Übergabe an anderes Rettungsmittel", systemImage: "cross.vial.fill")
            }
            .onAppear {
                if protokoll.uebergabeAn.isEmpty,
                   !protokoll.einsatzOrt.weitereEinsatzmittel.isEmpty {
                    protokoll.uebergabeAn = protokoll.einsatzOrt
                        .weitereEinsatzmittel.joined(separator: " / ")
                }
            }

            // Transportziel Klinik
            Section {
                CheckboxRow("ZNA / Notaufnahme", isOn: $protokoll.ergebnis.transportzielZna)
                CheckboxRow("Stroke Unit", isOn: $protokoll.ergebnis.transportzielStrokeUnit)
                CheckboxRow("Kath.-Labor", isOn: $protokoll.ergebnis.transportzielKathLabor)
                TextField("Sonstiges Ziel", text: $protokoll.ergebnis.transportzielSonstigesKH)
            } header: {
                Label("Transportziel Klinik", systemImage: "building.2.crop.circle")
            }

            // Einsatzbesonderheiten
            Section {
                CheckboxRow("Ambulante Versorgung vor Ort", isOn: $protokoll.ergebnis.ambulantVorOrt)
                CheckboxRow("Nächstes KH nicht erreichbar", isOn: $protokoll.ergebnis.naechstesKHNichtErreichbar)
                CheckboxRow("Patient nicht transportfähig", isOn: $protokoll.ergebnis.patNichtTransportfaehig)
                CheckboxRow("Tod an der Einsatzstelle", isOn: $protokoll.ergebnis.todAnEinsatzstelle)
                CheckboxRow("Zwangsunterbringung", isOn: $protokoll.ergebnis.zwangsunterbringung)
                CheckboxRow("LNA/GRG im Einsatz", isOn: $protokoll.ergebnis.lnaGrleimEinsatz)
                CheckboxRow("Mehrere Patienten", isOn: $protokoll.ergebnis.mehrerePatient)
                CheckboxRow("Aufwändige Rettung", isOn: $protokoll.ergebnis.aufwaendigeRettung)
                CheckboxRow("Infektionsschutz", isOn: $protokoll.ergebnis.infektionsSchutz)
                CheckboxRow("Schwerlasttransport", isOn: $protokoll.ergebnis.schwerlasttransport)
            } header: {
                Label("Einsatzbesonderheiten", systemImage: "exclamationmark.triangle")
            }

            // Archiv
            Section {
                Button {
                    do {
                        try ProtokollArchiv.shared.speichern(protokoll)
                        gespeichert = true
                    } catch {
                        speicherFehler = true
                    }
                } label: {
                    Label(gespeichert ? "Gespeichert ✓" : "Protokoll im Archiv speichern",
                          systemImage: gespeichert ? "checkmark.circle.fill" : "archivebox")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(gespeichert ? .green : Color("RDOrange"))
            } header: {
                Label("Archiv", systemImage: "archivebox")
            } footer: {
                Text("Daten werden lokal auf dem Gerät gespeichert (DSGVO-konform).").font(.footnote).foregroundStyle(.secondary)
            }

            // PDF EXPORT
            Section {
                Button {
                    isGenerating = true
                    let prot = protokoll
                    Task.detached(priority: .userInitiated) {
                        let url = DINPDFGenerator.generate(protokoll: prot)
                        await MainActor.run {
                            pdfURL = url
                            isGenerating = false
                            if url != nil {
                                zeigeShareSheet = true
                            } else {
                                pdfFehler = true
                            }
                        }
                    }
                } label: {
                    HStack {
                        if isGenerating {
                            ProgressView().padding(.trailing, 4)
                        } else {
                            Image(systemName: "doc.fill")
                        }
                        Text(isGenerating ? "PDF wird generiert..." : "PDF generieren & exportieren")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("RDOrange"))
                .disabled(isGenerating)

                Button {
                    guard MFMailComposeViewController.canSendMail() else {
                        mailNichtVerfügbar = true
                        return
                    }
                    if pdfURL == nil {
                        isGenerating = true
                        let prot = protokoll
                        Task.detached(priority: .userInitiated) {
                            let url = DINPDFGenerator.generate(protokoll: prot)
                            await MainActor.run {
                                pdfURL = url
                                isGenerating = false
                                if url != nil {
                                    zeigeMailComposer = true
                                } else {
                                    pdfFehler = true
                                }
                            }
                        }
                    } else {
                        zeigeMailComposer = true
                    }
                } label: {
                    Label("Per E‑Mail senden", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(Color("RDOrange"))
                .disabled(isGenerating || recipientEmail.isEmpty)
            } header: {
                Label("PDF Export", systemImage: "square.and.arrow.up")
            } footer: {
                Text("Das Protokoll bleibt 24 Stunden nach dem Export im Archiv.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .onAppear {
            protokoll.prefillUebergabeMesswerteAusVerlauf()
        }
        .navigationTitle("Abschluss & Export")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { zeigeEinstellungen = true } label: {
                    Label("Einstellungen", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $zeigeShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url]) { completed in
                    if completed {
                        if !gespeichert {
                            try? ProtokollArchiv.shared.speichern(protokoll)
                            gespeichert = true
                        }
                        ProtokollArchiv.shared.markierePDFExport(id: protokoll.id)
                        nachExportBereinigen()
                    }
                }
            }
        }
        .alert("PDF-Fehler", isPresented: $pdfFehler) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Das PDF konnte nicht erstellt werden. Bitte versuche es erneut.")
        }
        .alert("Speicherfehler", isPresented: $speicherFehler) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Das Protokoll konnte nicht gespeichert werden.")
        }
        .alert("E-Mail nicht verfügbar", isPresented: $mailNichtVerfügbar) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Auf diesem Gerät ist kein E-Mail-Konto eingerichtet.")
        }
        .sheet(isPresented: $zeigeMailComposer) {
            if let url = pdfURL {
                MailComposer(
                    recipient: recipientEmail,
                    subject: "Einsatzprotokoll \(protokoll.einsatzOrt.einsatzNummer)",
                    body: "Im Anhang finden Sie das Einsatzprotokoll.",
                    attachmentURL: url
                ) { result in
                    if result == .sent {
                        if !gespeichert {
                            try? ProtokollArchiv.shared.speichern(protokoll)
                            gespeichert = true
                        }
                        ProtokollArchiv.shared.markierePDFExport(id: protokoll.id)
                        nachExportBereinigen()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func uebRow(_ label: String, _ value: Binding<String>,
                         _ unit: String, _ zeige: Binding<Bool>,
                         useDecimal: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value.wrappedValue.isEmpty ? "—" : "\(value.wrappedValue) \(unit)")
                .foregroundColor(value.wrappedValue.isEmpty ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeige.wrappedValue = true }
        .sheet(isPresented: zeige) {
            if useDecimal {
                NumpadSheet(mode: .decimal(label: label, unit: unit),
                            initial: value.wrappedValue) { val in value.wrappedValue = val }
            } else {
                NumpadSheet(mode: .integer(label: label, unit: unit, maxDigits: 4),
                            initial: value.wrappedValue) { val in value.wrappedValue = val }
            }
        }
    }

    private func nachExportBereinigen() {
        if let url = pdfURL {
            try? FileManager.default.removeItem(at: url)
            pdfURL = nil
        }
        protokoll.reset()
        onBack()
    }

    @ViewBuilder
    private func trendRow(_ label: String, _ erst: Int?, _ letzt: Int?, _ einheit: String, normal: ClosedRange<Int>) -> some View {
        if let e = erst, let l = letzt {
            let pfeil = l > e ? "↑" : l < e ? "↓" : "→"
            let farbe: Color = normal.contains(l) ? .green : .red
            HStack {
                Text(label).foregroundColor(.secondary).font(.subheadline)
                Spacer()
                Text("\(e) \(pfeil) \(l) \(einheit)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(farbe)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var onCompletion: ((Bool) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in
            onCompletion?(completed)
        }
        return vc
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - Mail Composer

struct MailComposer: UIViewControllerRepresentable {
    enum Result { case cancelled, saved, sent, failed }

    var recipient: String
    var subject: String
    var body: String
    var attachmentURL: URL
    var completion: (Result) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        if !recipient.isEmpty { vc.setToRecipients([recipient]) }
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        if let data = try? Data(contentsOf: attachmentURL) {
            vc.addAttachmentData(data, mimeType: "application/pdf", fileName: attachmentURL.lastPathComponent)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let completion: (Result) -> Void
        init(completion: @escaping (Result) -> Void) { self.completion = completion }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            switch result {
            case .cancelled: completion(.cancelled)
            case .saved: completion(.saved)
            case .sent: completion(.sent)
            case .failed: completion(.failed)
            @unknown default: completion(.failed)
            }
            controller.dismiss(animated: true)
        }
    }
}
