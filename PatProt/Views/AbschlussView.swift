import SwiftUI
import MessageUI
import PencilKit

struct AbschlussView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var protokoll: EinsatzProtokoll
    @State private var pdfURL: URL? = nil
    @State private var zeigeShareSheet = false
    @State private var isGenerating = false
    @AppStorage("recipientEmail") private var recipientEmail: String = ""
    @AppStorage("defaultVerfasser") private var defaultVerfasserRaw: String = ProtokollVerfasser.notfallsanitaeter.rawValue
    @State private var verfasserPrefilled = false
    @State private var zeigeEinstellungen = false
    @State private var zeigeMailComposer = false
    @State private var pdfFehler = false
    @State private var gespeichert = false
    @State private var speicherFehler = false
    @State private var mailNichtVerfügbar = false
    @State private var zeigeUnterschrift = false

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
                CheckboxRow("FR-Einsatz (First Responder)", isOn: $protokoll.ergebnis.frEinsatz)
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

            // FR-Einsatzbesonderheiten
            Section {
                TextField("Besonderheiten (Lage, Zugang, Gegebenheiten)", text: $protokoll.ergebnis.firstResponderBesonderheiten, axis: .vertical)
                    .lineLimit(3...)
            } header: {
                Label("FR-Einsatzbesonderheiten", systemImage: "exclamationmark.triangle")
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

            // Unterschrift
            Section {
                if let data = protokoll.unterschriftData, let img = UIImage(data: data) {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 80)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        Button(role: .destructive) {
                            protokoll.unterschriftData = nil
                        } label: {
                            Label("Unterschrift löschen", systemImage: "trash")
                                .font(.subheadline)
                        }
                    }
                } else {
                    Button {
                        zeigeUnterschrift = true
                    } label: {
                        Label("Unterschrift erfassen", systemImage: "signature")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("RDOrange"))
                }
            } header: {
                Label("Unterschrift", systemImage: "signature")
            }
            .sheet(isPresented: $zeigeUnterschrift) {
                UnterschriftSheet { data in
                    protokoll.unterschriftData = data
                }
            }

            // Folgeeinheit
            Section {
                Button {
                    let savedNummer = protokoll.einsatzOrt.einsatzNummer
                    protokoll.reset()
                    protokoll.einsatzOrt.einsatzNummer = savedNummer
                    gespeichert = false
                    pdfURL = nil
                } label: {
                    Label("Protokoll für Folgeeinheit erstellen", systemImage: "person.2.badge.key.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            } header: {
                Label("Übergabe an Folgeeinheit", systemImage: "arrow.triangle.2.circlepath")
            } footer: {
                Text("Einsatznummer bleibt erhalten. Alle anderen Felder werden zurückgesetzt.")
                    .font(.footnote).foregroundStyle(.secondary)
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
            if !verfasserPrefilled,
               let v = ProtokollVerfasser(rawValue: defaultVerfasserRaw) {
                protokoll.verfasser = v
                verfasserPrefilled = true
            }
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

// MARK: - Unterschrift Sheet

struct UnterschriftSheet: View {
    var onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var canvasView = PKCanvasView()
    @State private var drawingEmpty = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Hier unterschreiben")
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.top, 12)

                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                        .background(Color(.systemBackground).cornerRadius(12))
                        .padding()

                    UnterschriftCanvas(canvasView: $canvasView, drawingEmpty: $drawingEmpty)
                        .padding(20)

                    if drawingEmpty {
                        Text("Unterschrift")
                            .font(.title3).foregroundColor(Color(.tertiaryLabel))
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 200)
            }
            .navigationTitle("Unterschrift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        // Use actual canvas bounds; fall back to a fixed size if layout
                        // hasn't completed yet (bounds == .zero).
                        let canvasBounds = canvasView.bounds
                        let renderSize = canvasBounds.size == .zero
                            ? CGSize(width: 300, height: 150)
                            : canvasBounds.size
                        let rect = CGRect(origin: .zero, size: renderSize)
                        let image = canvasView.drawing.image(from: rect, scale: UIScreen.main.scale)
                        if let data = image.pngData() {
                            onSave(data)
                        }
                        dismiss()
                    }
                    .disabled(drawingEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        canvasView.drawing = PKDrawing()
                        drawingEmpty = true
                    } label: {
                        Label("Löschen", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
    }
}

struct UnterschriftCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var drawingEmpty: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(drawingEmpty: $drawingEmpty) }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawingEmpty: Bool
        init(drawingEmpty: Binding<Bool>) { _drawingEmpty = drawingEmpty }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawingEmpty = canvasView.drawing.strokes.isEmpty
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
