import SwiftUI
import UIKit
import PhotosUI

// MARK: - In-App Fotos (werden NICHT auf dem Gerät gespeichert)

struct BilderView: View {
    @Binding var fotos: [FotoEintrag]
    var onBack: () -> Void

    @State private var zeigeKameraAuswahl = false
    @State private var zeigeKamera = false
    @State private var zeigeBibliothek = false
    @State private var vollbildFoto: FotoEintrag? = nil
    @State private var bearbeiteBezeichnung: FotoEintrag? = nil
    @State private var neueBezeichnung = ""
    @State private var keinKameraAlert = false

    private let spalten = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                infoHinweis
                fotosGrid
                aufnahmeButtons
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bilder & Dateien")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
                Button { zeigeKameraAuswahl = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog("Foto hinzufügen", isPresented: $zeigeKameraAuswahl) {
            Button("Kamera") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    zeigeKamera = true
                } else {
                    keinKameraAlert = true
                }
            }
            Button("Aus Fotoauswahl importieren") { zeigeBibliothek = true }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $zeigeKamera) {
            KameraController(onCapture: { bild in
                fotoHinzufuegen(bild)
                zeigeKamera = false
            }, onAbbrechen: { zeigeKamera = false })
            .ignoresSafeArea()
        }
        .sheet(isPresented: $zeigeBibliothek) {
            PHBilderPicker { bild in
                fotoHinzufuegen(bild)
                zeigeBibliothek = false
            }
        }
        .fullScreenCover(item: $vollbildFoto) { foto in
            VollbildFotoView(foto: foto, onClose: { vollbildFoto = nil })
        }
        .sheet(item: $bearbeiteBezeichnung) { foto in
            BezeichnungSheet(
                bezeichnung: $neueBezeichnung,
                onSpeichern: {
                    if let idx = fotos.firstIndex(where: { $0.id == foto.id }) {
                        fotos[idx].bezeichnung = neueBezeichnung
                    }
                    bearbeiteBezeichnung = nil
                },
                onAbbrechen: { bearbeiteBezeichnung = nil }
            )
        }
        .alert("Keine Kamera verfügbar", isPresented: $keinKameraAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Info

    private var infoHinweis: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundColor(.green)
                .font(.subheadline)
            Text("Fotos werden nur innerhalb dieses Einsatzes gespeichert und nicht auf dem Gerät abgelegt.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.green.opacity(0.08))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Foto-Grid

    private var fotosGrid: some View {
        Group {
            if fotos.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Noch keine Bilder")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("Füge Fotos mit der Kamera hinzu.\nSie werden nur im Einsatz gespeichert.")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
            } else {
                LazyVGrid(columns: spalten, spacing: 8) {
                    ForEach(fotos) { foto in
                        FotoKachel(
                            foto: foto,
                            onTap: { vollbildFoto = foto },
                            onBezeichnungBearbeiten: {
                                neueBezeichnung = foto.bezeichnung
                                bearbeiteBezeichnung = foto
                            },
                            onLoeschen: {
                                foto.loeschen()
                                fotos.removeAll { $0.id == foto.id }
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Aufnahme-Buttons

    private var aufnahmeButtons: some View {
        VStack(spacing: 10) {
            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    zeigeKamera = true
                } else {
                    keinKameraAlert = true
                }
            } label: {
                Label("Foto aufnehmen", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("RDOrange"))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .font(.headline)
            }

            Button { zeigeBibliothek = true } label: {
                Label("Aus Fotoauswahl importieren", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundColor(Color("RDOrange"))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("RDOrange").opacity(0.4), lineWidth: 1.5))
                    .font(.headline)
            }
        }
    }

    // MARK: - Foto speichern

    private func fotoHinzufuegen(_ bild: UIImage) {
        guard let data = bild.jpegData(compressionQuality: 0.7) else { return }
        let dateiname = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(dateiname)
        guard (try? data.write(to: url, options: [.atomicWrite, .completeFileProtection])) != nil else { return }
        fotos.append(FotoEintrag(bildDateiname: dateiname))
    }
}

// MARK: - Foto Kachel

private struct FotoKachel: View {
    let foto: FotoEintrag
    let onTap: () -> Void
    let onBezeichnungBearbeiten: () -> Void
    let onLoeschen: () -> Void

    private var zeitStempel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: foto.zeitpunkt)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                if let img = UIImage(contentsOfFile: foto.bildURL.path) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 110)
                        .clipped()
                } else {
                    Color(.systemGray4)
                        .frame(height: 110)
                }

                LinearGradient(colors: [.clear, .black.opacity(0.55)],
                               startPoint: .center, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 2) {
                    if !foto.bezeichnung.isEmpty {
                        Text(foto.bezeichnung)
                            .font(.system(size: 9)).fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Text(zeitStempel)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(6)
            }
        }
        .cornerRadius(10)
        .contextMenu {
            Button { onBezeichnungBearbeiten() } label: {
                Label("Bezeichnung bearbeiten", systemImage: "pencil")
            }
            Button(role: .destructive) { onLoeschen() } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}

// MARK: - Vollbild Foto

private struct VollbildFotoView: View {
    let foto: FotoEintrag
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let img = UIImage(contentsOfFile: foto.bildURL.path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
                if !foto.bezeichnung.isEmpty {
                    Text(foto.bezeichnung)
                        .foregroundColor(.white)
                        .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - Bezeichnung Sheet

private struct BezeichnungSheet: View {
    @Binding var bezeichnung: String
    let onSpeichern: () -> Void
    let onAbbrechen: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Bezeichnung") {
                    TextField("z.B. Wunde linker Unterarm", text: $bezeichnung)
                }
            }
            .navigationTitle("Bezeichnung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onAbbrechen)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern", action: onSpeichern)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

// MARK: - Kamera UIViewControllerRepresentable (speichert NICHT auf Gerät)

struct KameraController: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onAbbrechen: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: KameraController
        init(_ parent: KameraController) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let bild = info[.originalImage] as? UIImage {
                // WICHTIG: Kein UIImageWriteToSavedPhotosAlbum – Bild wird NICHT gespeichert
                parent.onCapture(bild)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.onAbbrechen()
        }
    }
}

// MARK: - PHPicker (moderner Bibliotheks-Picker, keine Berechtigung nötig)

struct PHBilderPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHBilderPicker
        init(_ parent: PHBilderPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let bild = object as? UIImage else { return }
                DispatchQueue.main.async { self.parent.onCapture(bild) }
            }
        }
    }
}
