import SwiftUI
import PhotosUI

// MARK: - Kamera-Picker

struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var fotos: [FotoEintrag]
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        init(_ parent: CameraImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.85) {
                let filename = "medifoto_\(UUID().uuidString).jpg"
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try? data.write(to: url)
                DispatchQueue.main.async {
                    self.parent.fotos.append(FotoEintrag(bildDateiname: filename))
                }
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Fotobibliothek-Picker

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var fotos: [FotoEintrag]
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                    guard let image = obj as? UIImage,
                          let data = image.jpegData(compressionQuality: 0.85) else { return }
                    let filename = "medifoto_\(UUID().uuidString).jpg"
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                    try? data.write(to: url)
                    DispatchQueue.main.async {
                        self.parent.fotos.append(FotoEintrag(bildDateiname: filename))
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail-Sektion + Buttons

struct MedikamentFotoSektion: View {
    @Binding var fotos: [FotoEintrag]
    @State private var zeigeKamera = false
    @State private var zeigeBibliothek = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !fotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(fotos) { foto in
                            ZStack(alignment: .topTrailing) {
                                Group {
                                    if let image = UIImage(contentsOfFile: foto.bildURL.path) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Color.secondary.opacity(0.2)
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button {
                                    fotos.removeAll { $0.id == foto.id }
                                    foto.loeschen()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, Color.black.opacity(0.6))
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 92)
            }

            HStack(spacing: 12) {
                Button {
                    zeigeKamera = true
                } label: {
                    Label("Kamera", systemImage: "camera")
                }
                .buttonStyle(.bordered)

                Button {
                    zeigeBibliothek = true
                } label: {
                    Label("Bibliothek", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
            }

            Text("→ PDF S. 3ff. · Foto-Anhang")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $zeigeKamera) {
            CameraImagePicker(fotos: $fotos)
        }
        .sheet(isPresented: $zeigeBibliothek) {
            PhotoLibraryPicker(fotos: $fotos)
        }
    }
}
