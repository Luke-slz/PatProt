import SwiftUI
import VisionKit

// MARK: - VNDocumentCameraViewController Wrapper

struct DocumentCameraWrapper: UIViewControllerRepresentable {
    let onScan: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController,
                                context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentCameraWrapper
        init(_ parent: DocumentCameraWrapper) { self.parent = parent }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let image = scan.imageOfPage(at: 0)
            parent.onScan(image)
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            parent.dismiss()
        }
    }
}

// MARK: - Scan-Sektion für PatientView

struct KVKarteScanSektion: View {
    @Binding var patientDaten: PatientDaten
    @State private var zeigeScanner = false
    @State private var scanStatus: ScanStatus = .idle

    private enum ScanStatus {
        case idle
        case success(String)
        case noResult
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { zeigeScanner = true } label: {
                Label("Karte scannen", systemImage: "creditcard.viewfinder")
            }
            .buttonStyle(.bordered)

            switch scanStatus {
            case .idle:
                EmptyView()
            case .success(let summary):
                Label(summary, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .noResult:
                Label("Keine Daten erkannt – bitte erneut versuchen",
                      systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $zeigeScanner) {
            DocumentCameraWrapper { image in
                Task {
                    let daten = await KVKarteParser.parse(image)
                    applyAndUpdateStatus(daten)
                }
            }
        }
    }

    @MainActor private func applyAndUpdateStatus(_ daten: ParsedKVDaten) {
        if !daten.vorname.isEmpty             { patientDaten.vorname = daten.vorname }
        if !daten.nachname.isEmpty            { patientDaten.nachname = daten.nachname }
        if let geb = daten.geburtsDatum       { patientDaten.geburtsDatum = geb }
        if !daten.versicherungsNummer.isEmpty  { patientDaten.versicherungsNummer = daten.versicherungsNummer }
        if !daten.kostentraeger.isEmpty        { patientDaten.kostentraeger = daten.kostentraeger }

        let empty = daten.vorname.isEmpty && daten.nachname.isEmpty
                 && daten.geburtsDatum == nil && daten.versicherungsNummer.isEmpty
                 && daten.kostentraeger.isEmpty

        if empty {
            scanStatus = .noResult
        } else {
            var parts: [String] = []
            if !daten.nachname.isEmpty            { parts.append(daten.nachname) }
            if !daten.vorname.isEmpty             { parts.append(daten.vorname) }
            if !daten.versicherungsNummer.isEmpty  { parts.append(daten.versicherungsNummer) }
            scanStatus = .success("Gelesen: " + parts.joined(separator: ", "))
        }
    }
}
