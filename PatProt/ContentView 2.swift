import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var protokoll = EinsatzProtokoll()

    private var isiPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        if isiPad {
            iPadMainView()
                .environmentObject(appState)
                .environmentObject(protokoll)
        } else {
            iPhoneContentView()
                .environmentObject(appState)
                .environmentObject(protokoll)
        }
    }
}

// MARK: - iPhone App Steps (top-level, shared with iPhoneMenuView)

enum iPhoneAppStep: Hashable {
    case einsatzOrt
    case notfallGeschehen
    case abcde
    case airway, breathing, circulation, disability, exposure
    case sampler, sinnhaft, diagnose, verlauf, massnahmen, medikamente, reanimation
    case bilder
    case abschluss, settings
}

// MARK: - iPhone Flow

struct iPhoneContentView: View {
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    @State private var path: [iPhoneAppStep] = []
    @EnvironmentObject private var appState: AppState

    @State private var isParsing = false
    @State private var parseError: String? = nil
    @State private var showMenu = false
    @State private var zeigeArchiv = false

    // AppStep kept as typealias for backward compatibility
    typealias AppStep = iPhoneAppStep

    var body: some View {
        NavigationStack(path: $path) {
            StartView(
                onNeu: {
                    protokoll.reset()
                    path = [.einsatzOrt]
                },
                onSettings: { path.append(.settings) },
                onArchiv: { zeigeArchiv = true },
                onImportScreenshot: { image in handleScreenshot(image) }
            )
            .navigationDestination(for: AppStep.self) { step in
                switch step {
                case .einsatzOrt:
                    EinsatzOrtView(
                        protokoll: protokoll,
                        onWeiter: { path.append(.abcde) },
                        onBack: { path.removeLast() },
                        onMenuOpen: { showMenu = true }
                    )
                case .notfallGeschehen:
                    NotfallgeschehenView(
                        befund: $protokoll.notfallGeschehen,
                        onWeiter: { path.append(.abcde) },
                        onBack: { path.removeLast() }
                    )
                case .abcde:
                    ABCDEUebersichtView(
                        protokoll: protokoll,
                        onWeiter:      { path.append(.abschluss) },
                        onAirway:      { path.append(.airway) },
                        onBreathing:   { path.append(.breathing) },
                        onCirculation: { path.append(.circulation) },
                        onDisability:  { path.append(.disability) },
                        onExposure:    { path.append(.exposure) },
                        onNotfall:     { path.append(.notfallGeschehen) },
                        onSampler:     { path.append(.sampler) },
                        onSinnhaft:    { path.append(.sinnhaft) },
                        onDiagnose:    { path.append(.diagnose) },
                        onVerlauf:     { path.append(.verlauf) },
                        onMassnahmen:  { path.append(.massnahmen) },
                        onMedikamente: { path.append(.medikamente) },
                        onReanimation: { path.append(.reanimation) },
                        onBilder:      { path.append(.bilder) },
                        onZurueck:     { path.removeLast() }
                    )
                case .airway:
                    AirwayView(befund: $protokoll.airway) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                        path.append(.breathing)
                    }
                case .breathing:
                    BreathingView(befund: $protokoll.breathing) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                        path.append(.circulation)
                    }
                case .circulation:
                    CirculationView(befund: $protokoll.circulation) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                        path.append(.disability)
                    }
                case .disability:
                    DisabilityView(befund: $protokoll.disability) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                        path.append(.exposure)
                    }
                case .exposure:
                    ExposureView(befund: $protokoll.exposure) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                    }
                case .sampler:
                    SAMPLERView(befund: $protokoll.sampler) { path.removeLast() }
                case .sinnhaft:
                    SINNHAFTView(befund: $protokoll.sinnhaft) { path.removeLast() }
                case .diagnose:
                    DiagnoseView(befund: $protokoll.diagnose, onBack: { path.removeLast() })
                case .verlauf:
                    VerlaufView(messungen: $protokoll.verlaufMessungen) { path.removeLast() }
                case .massnahmen:
                    MassnahmenView(befund: $protokoll.massnahmen, onBack: { path.removeLast() })
                case .medikamente:
                    MedikamenteView(medikamente: $protokoll.medikamente, onBack: { path.removeLast() })
                case .reanimation:
                    ReanimationView(protokoll: $protokoll.reanimation) { path.append(.abschluss) }
                case .bilder:
                    BilderView(fotos: $protokoll.fotos) { path.removeLast() }
                case .abschluss:
                    AbschlussView(protokoll: protokoll, onBack: { path.removeLast() })
                case .settings:
                    SettingsView(onBack: { path.removeLast() })
                }
            }
        }
        .tint(Color("RDOrange"))
        .environmentObject(protokoll)
        // iPhone-Menü
        .sheet(isPresented: $showMenu) {
            iPhoneMenuView(path: $path, isPresented: $showMenu)
        }
        .sheet(isPresented: $zeigeArchiv) {
            ArchivView(onLaden: { path = [.einsatzOrt] })
                .environmentObject(protokoll)
        }
        // Bild aus Share-Sheet anderer Apps empfangen
        .onChange(of: appState.pendingImage) { _, image in
            guard let img = image else { return }
            appState.pendingImage = nil
            handleScreenshot(img)
        }
        // Ladeoverlay während OCR läuft
        .overlay {
            if isParsing {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(.white)
                        Text("Meldezettel wird ausgewertet…")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .alert("Import fehlgeschlagen", isPresented: Binding(
            get: { parseError != nil },
            set: { if !$0 { parseError = nil } }
        )) {
            Button("OK", role: .cancel) { parseError = nil }
        } message: {
            Text(parseError ?? "")
        }
    }

    // MARK: - Screenshot verarbeiten

    private func handleScreenshot(_ image: UIImage) {
        isParsing = true
        Task {
            let daten = await ScreenshotParser.parse(image)
            await MainActor.run {
                applyToCurrentProtokoll(daten)
                isParsing = false
                path = [.einsatzOrt]
            }
        }
    }

    private func applyToCurrentProtokoll(_ daten: ParsedMeldungDaten) {
        protokoll.einsatzOrt.einsatzNummer = daten.einsatzNummer
        protokoll.einsatzOrt.einsatzArt    = daten.einsatzArt
        protokoll.einsatzOrt.stichwort     = daten.stichwort
        protokoll.einsatzOrt.adresse       = daten.adresse
        protokoll.einsatzOrt.zusatz        = daten.zusatz
        protokoll.einsatzOrt.sondersignal  = daten.sondersignal
        protokoll.einsatzOrt.notarzt       = daten.notarzt
        if let zeit = daten.alarmzeit {
            protokoll.einsatzOrt.alarmzeit   = zeit
            protokoll.einsatzOrt.abfahrtzeit = zeit
            protokoll.einsatzOrt.ankunftzeit = zeit
        }
        protokoll.patientDaten.geschlecht = daten.geschlecht
        protokoll.sampler.ereignis        = daten.ereignis
    }

}
