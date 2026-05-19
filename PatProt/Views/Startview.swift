import SwiftUI
import PhotosUI

// MARK: - Start Screen

struct StartView: View {
    var onNeu: () -> Void
    var onSettings: () -> Void
    var onArchiv: () -> Void
    var onImportScreenshot: (UIImage) -> Void

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isLoadingPhoto = false

    @AppStorage("einheitenname") private var einheitenname: String = "First Responder Geesthacht"
    @AppStorage("startseiteUntertitel") private var startseiteUntertitel: String = "Einsatzprotokollierung First Responder"

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(Color("RDOrange"))

                    Text(einheitenname.isEmpty ? "First Responder Geesthacht" : einheitenname)
                        .font(.largeTitle).fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(startseiteUntertitel.isEmpty ? "Einsatzprotokollierung First Responder" : startseiteUntertitel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 12) {
                    // ── Neuen Einsatz starten ─────────────────────────
                    Button(action: onNeu) {
                        Label("Neuen Einsatz starten", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("RDOrange"))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .font(.headline)
                    }

                    // ── Meldezettel importieren ───────────────────────
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            if isLoadingPhoto {
                                ProgressView()
                                    .tint(Color("RDOrange"))
                                Text("Wird geladen…")
                                    .foregroundColor(.secondary)
                            } else {
                                Label("Meldezettel importieren", systemImage: "photo.badge.plus")
                                    .foregroundColor(Color("RDOrange"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color("RDOrange").opacity(0.4), lineWidth: 1.5)
                        )
                        .font(.headline)
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        guard let item else { return }
                        isLoadingPhoto = true
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await MainActor.run {
                                    isLoadingPhoto = false
                                    selectedPhoto = nil
                                    onImportScreenshot(image)
                                }
                            } else {
                                await MainActor.run {
                                    isLoadingPhoto = false
                                    selectedPhoto = nil
                                }
                            }
                        }
                    }

                    // ── Protokoll-Archiv ──────────────────────────────
                    Button(action: onArchiv) {
                        Label("Protokoll-Archiv", systemImage: "archivebox.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                            )
                            .font(.headline)
                    }

                    // ── Einstellungen ─────────────────────────────────
                    Button(action: onSettings) {
                        Label("Einstellungen", systemImage: "gearshape.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                            )
                            .font(.headline)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
    }
}
