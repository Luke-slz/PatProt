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
    case menu
    case konfiguration
    case einsatzzeiten
    case patient
    case notfallGeschehen
    case abcde
    case airway, breathing, circulation, disability, exposure
    case sampler, sinnhaft, diagnose, verlauf, massnahmen, reanimation
    case bilder
    case uebergabeBefunde
    case abschluss, settings
}

// MARK: - iPhone Flow

struct iPhoneContentView: View {
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    @State private var path: [iPhoneAppStep] = []
    @EnvironmentObject private var appState: AppState

    @State private var isParsing = false
    @State private var parseError: String? = nil
    @State private var zeigeArchiv = false

    typealias AppStep = iPhoneAppStep

    var body: some View {
        NavigationStack(path: $path) {
            StartView(
                onNeu: {
                    protokoll.reset()
                    path = [.menu]
                },
                onSettings: { path.append(.settings) },
                onArchiv: { zeigeArchiv = true },
                onImportScreenshot: { image in handleScreenshot(image) }
            )
            .navigationDestination(for: AppStep.self) { step in
                switch step {
                case .menu:
                    iPhoneMenuView(path: $path)
                        .environmentObject(protokoll)
                case .einsatzOrt:
                    EinsatzOrtView(
                        protokoll: protokoll,
                        onWeiter: { path.append(.abcde) },
                        onBack: { path.removeLast() }
                    )
                case .konfiguration:
                    KonfigurationView(protokoll: protokoll)
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .einsatzzeiten] }
                        }
                case .einsatzzeiten:
                    EinsatzzeitenView(protokoll: protokoll)
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .patient] }
                        }
                case .patient:
                    PatientView(protokoll: protokoll)
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .notfallGeschehen] }
                        }
                case .notfallGeschehen:
                    NotfallgeschehenView(befund: $protokoll.notfallGeschehen)
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .abcde] }
                        }
                case .abcde:
                    ABCDEUebersichtView(
                        protokoll: protokoll,
                        onAirway:      { path.append(.airway) },
                        onBreathing:   { path.append(.breathing) },
                        onCirculation: { path.append(.circulation) },
                        onDisability:  { path.append(.disability) },
                        onExposure:    { path.append(.exposure) }
                    )
                    .safeAreaInset(edge: .bottom) {
                        WeiterButton { path = [.menu, .sampler] }
                    }
                case .airway:
                    AirwayView(befund: $protokoll.airway, massnahmen: $protokoll.massnahmen) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                        path.append(.breathing)
                    }
                case .breathing:
                    BreathingView(befund: $protokoll.breathing, massnahmen: $protokoll.massnahmen) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                        path.append(.circulation)
                    }
                case .circulation:
                    CirculationView(befund: $protokoll.circulation, massnahmen: $protokoll.massnahmen) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                        path.append(.disability)
                    }
                case .disability:
                    DisabilityView(befund: $protokoll.disability, massnahmen: $protokoll.massnahmen) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                        path.append(.exposure)
                    }
                case .exposure:
                    ExposureView(protokoll: protokoll) {
                        path.removeAll { [.airway,.breathing,.circulation,.disability,.exposure].contains($0) }
                    }
                    .safeAreaInset(edge: .bottom) {
                        WeiterButton { path = [.menu, .sampler] }
                    }
                case .sampler:
                    SAMPLERView(befund: $protokoll.sampler,
                                medikamentFotos: $protokoll.medikamentFotos) { path.removeLast() }
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .diagnose] }
                        }

                case .sinnhaft:
                    SINNHAFTView(befund: $protokoll.sinnhaft) { path.removeLast() }
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .reanimation] }
                        }
                case .diagnose:
                    DiagnoseView(befund: $protokoll.diagnose)
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .verlauf] }
                        }
                case .verlauf:
                    VerlaufView(messungen: $protokoll.verlaufMessungen) { path.removeLast() }
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .massnahmen] }
                        }
                case .massnahmen:
                    MassnahmenView(befund: $protokoll.massnahmen, onBack: { path.removeLast() })
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .sinnhaft] }
                        }
                case .reanimation:
                    ReanimationView(protokoll: $protokoll.reanimation) { path.append(.abschluss) }
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .bilder] }
                        }
                case .bilder:
                    BilderView(fotos: $protokoll.fotos) { path.removeLast() }
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton(label: "Einsatz beenden") { path = [.menu, .abschluss] }
                        }
                case .uebergabeBefunde:
                    UebergabeBefundeView(protokoll: protokoll) { path.removeLast() }
                        .safeAreaInset(edge: .bottom) {
                            WeiterButton { path = [.menu, .abschluss] }
                        }
                case .abschluss:
                    AbschlussView(protokoll: protokoll, onBack: { path = [] })
                case .settings:
                    SettingsView(onBack: { path.removeLast() })
                }
            }
        }
        .tint(Color("RDOrange"))
        .environmentObject(protokoll)
        .sheet(isPresented: $zeigeArchiv) {
            ArchivView(onLaden: { path = [.menu] })
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
                path = [.menu]
            }
        }
    }

    private func applyToCurrentProtokoll(_ daten: ParsedMeldungDaten) {
        protokoll.einsatzOrt.einsatzNummer = daten.einsatzNummer
        let code = daten.einsatzArt
        protokoll.einsatzOrt.stichwort  = code
        protokoll.einsatzOrt.einsatzArt = bestDiagnose(code: code, ocrDiagnose: daten.stichwort)
        protokoll.einsatzOrt.adresse = daten.adresse
        if !daten.plz.isEmpty { protokoll.einsatzOrt.plz = daten.plz }
        if !daten.ort.isEmpty { protokoll.einsatzOrt.ort = daten.ort }
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

    private func bestDiagnose(code: String, ocrDiagnose: String) -> String {
        let tabellen = StichwortStore.laden()
        let codeNorm = code.uppercased().replacingOccurrences(of: " ", with: "")
        let kandidaten = tabellen.filter {
            $0.stichwort.uppercased().replacingOccurrences(of: " ", with: "").hasPrefix(codeNorm)
        }
        guard !ocrDiagnose.isEmpty else {
            return kandidaten.count == 1 ? kandidaten[0].diagnose : ocrDiagnose
        }
        let suchWörter = ocrDiagnose.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 }
        var besteWertung = 0
        var besteDiagnose: String? = nil
        for eintrag in kandidaten {
            let wertung = suchWörter.filter { eintrag.diagnose.lowercased().contains($0) }.count
            if wertung > besteWertung {
                besteWertung = wertung
                besteDiagnose = eintrag.diagnose
            }
        }
        return besteWertung > 0 ? (besteDiagnose ?? ocrDiagnose) : ocrDiagnose
    }
}
