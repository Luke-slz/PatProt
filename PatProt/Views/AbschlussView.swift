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
                        Text(v.rawValue).tag(v)
                    }
                }
                .pickerStyle(.segmented)
            } header: { Label("Protokoll geschrieben von", systemImage: "person.text.rectangle") }

            // NACA Score
            Section {
                Picker("NACA-Score", selection: $protokoll.ergebnis.nacaScore) {
                    ForEach(NacaScore.allCases, id: \.self) { score in
                        Text(score.beschreibung).tag(score)
                    }
                }
                .pickerStyle(.inline)
            } header: { Label("NACA-Score", systemImage: "chart.bar.fill") }

            // Transportziel
            Section {
                Picker("Übergabe / Transportziel", selection: $protokoll.ergebnis.transportZiel) {
                    ForEach(TransportZiel.allCases, id: \.self) { ziel in
                        Text(ziel.rawValue).tag(ziel)
                    }
                }
                .pickerStyle(.inline)
                if protokoll.ergebnis.transportZiel == .sonstige {
                    TextField("Sonstiges Ziel", text: $protokoll.ergebnis.transportZielSonstige)
                }
                TextField("Zielklinik (Name)", text: $protokoll.zielKlinik)
                TextField("Übergabe an", text: $protokoll.uebergabeAn)
                TextField("Zustand bei Übergabe", text: $protokoll.zustandBeiUebergabe)
            } header: { Label("Übergabe / Transportziel", systemImage: "building.2.crop.circle") }

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
            } header: { Label("Einsatzbesonderheiten", systemImage: "exclamationmark.triangle") }

            // Alarm
            Section {
                CheckboxRow("Mitfahrverweigerung", isOn: $protokoll.ergebnis.mifahrverweigerung)
                CheckboxRow("Voranmeldung", isOn: $protokoll.ergebnis.voranmeldung)
                CheckboxRow("Gelb Alarm", isOn: $protokoll.ergebnis.gelbAlarm)
                CheckboxRow("Rot Alarm", isOn: $protokoll.ergebnis.rotAlarm)
            } header: { Label("Alarm / Meldung", systemImage: "bell.badge") }

            // Freitext
            Section {
                TextEditor(text: $protokoll.freitext)
                    .frame(minHeight: 80)
            } header: { Label("Freitext / Abschlussbemerkung", systemImage: "note.text") }

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
            } header: { Label("Archiv", systemImage: "archivebox") }
              footer: { Text("Daten werden lokal auf dem Gerät gespeichert (DSGVO-konform).").font(.footnote).foregroundStyle(.secondary) }

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
            } header: { Label("PDF Export", systemImage: "square.and.arrow.up") }
              footer: { Text("Nach erfolgreichem Export wird das Protokoll automatisch vom Gerät gelöscht.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Abschluss & Export")
        .navigationBarTitleDisplayMode(.inline)
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
                        nachExportBereinigen()
                    }
                }
            }
        }
    }

    private func nachExportBereinigen() {
        if let url = pdfURL {
            try? FileManager.default.removeItem(at: url)
            pdfURL = nil
        }
        if gespeichert {
            ProtokollArchiv.shared.loeschen(protokoll.id)
        }
        protokoll.reset()
        onBack()
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
