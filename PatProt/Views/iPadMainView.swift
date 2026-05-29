import SwiftUI
import PhotosUI

// MARK: - iPad Hauptview mit NavigationSplitView

struct iPadMainView: View {
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    @EnvironmentObject private var appState: AppState

    @State private var selectedSection: iPadSection? = nil

    @State private var isParsing = false
    @State private var parseError: String? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isLoadingPhoto = false

    @State private var showingStart = true
    @State private var zeigeArchiv = false

    @AppStorage("einheitenname") private var einheitenname: String = "First Responder Geesthacht"
    @AppStorage("startseiteUntertitel") private var startseiteUntertitel: String = "Einsatzprotokollierung First Responder"

    enum iPadSection: Hashable {
        case konfiguration
        case einsatzzeiten
        case patient
        case notfallGeschehen
        case abcde
        case airway, breathing, circulation, disability, exposure
        case sampler
        case diagnose
        case verlauf
        case massnahmen
        case sinnhaft
        case reanimation
        case bilder
        case uebergabeBefunde
        case abschluss
        case settings
    }

    var body: some View {
        if showingStart {
            startScreen
        } else {
            hauptProtokoll
        }
    }

    // MARK: - Start Screen

    private var startScreen: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("RDOrange"))
                    Text(einheitenname.isEmpty ? "First Responder Geesthacht" : einheitenname)
                        .font(.largeTitle).fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text(startseiteUntertitel.isEmpty ? "Einsatzprotokollierung First Responder" : startseiteUntertitel)
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                VStack(spacing: 14) {
                    Button {
                        protokoll.reset()
                        showingStart = false
                        selectedSection = .konfiguration
                    } label: {
                        Label("Neuen Einsatz starten", systemImage: "plus.circle.fill")
                            .frame(maxWidth: 480)
                            .padding()
                            .background(Color("RDOrange"))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .font(.headline)
                    }

                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            if isLoadingPhoto {
                                ProgressView().tint(Color("RDOrange"))
                                Text("Wird geladen…").foregroundColor(.secondary)
                            } else {
                                Label("Meldezettel importieren", systemImage: "photo.badge.plus")
                                    .foregroundColor(Color("RDOrange"))
                            }
                        }
                        .frame(maxWidth: 480)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color("RDOrange").opacity(0.4), lineWidth: 1.5))
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
                                    handleScreenshot(image)
                                }
                            } else {
                                await MainActor.run {
                                    isLoadingPhoto = false
                                    selectedPhoto = nil
                                }
                            }
                        }
                    }

                    Button { zeigeArchiv = true } label: {
                        Label("Protokoll-Archiv", systemImage: "archivebox.fill")
                            .frame(maxWidth: 480)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1))
                            .font(.headline)
                    }

                    Button {
                        showingStart = false
                        selectedSection = .settings
                    } label: {
                        Label("Einstellungen", systemImage: "gearshape.fill")
                            .frame(maxWidth: 480)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1))
                            .font(.headline)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $zeigeArchiv) {
            ArchivView(onLaden: {
                showingStart = false
                selectedSection = .konfiguration
            })
            .environmentObject(protokoll)
        }
    }

    // MARK: - Haupt-Protokoll (NavigationSplitView)

    private var hauptProtokoll: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebarContent
                .navigationTitle(einheitenname.isEmpty ? "RD Protokoll" : einheitenname)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingStart = true
                            selectedSection = nil
                        } label: {
                            Image(systemName: "house.fill")
                        }
                    }
                }
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color("RDOrange"))
        .environmentObject(protokoll)
        .overlay {
            if isParsing {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView().scaleEffect(1.4).tint(.white)
                        Text("Meldezettel wird ausgewertet…")
                            .foregroundColor(.white).font(.headline)
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
        .onChange(of: appState.pendingImage) { _, image in
            guard let img = image else { return }
            appState.pendingImage = nil
            handleScreenshot(img)
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
        List(selection: $selectedSection) {
            einsatzInfoHeader

            Section {
                iPadNavRow(icon: "gearshape.fill",  farbe: .gray,   titel: "Konfiguration",  section: .konfiguration,  badge: konfigurationBadge)
                iPadNavRow(icon: "clock.fill",       farbe: .blue,   titel: "Einsatzzeiten",  section: .einsatzzeiten)
                iPadNavRow(icon: "person.fill",      farbe: .teal,   titel: "Patient",         section: .patient,         badge: patientBadge)
            }

            Section {
                iPadNavRow(icon: "bell.fill",                        farbe: .orange, titel: "Notfallgeschehen",   section: .notfallGeschehen, badge: notfallBadge)
                iPadNavRow(icon: "staroflife.fill",                  farbe: .red,    titel: "ABCDE",               section: .abcde,            badge: befundeBadge)
                iPadNavRow(icon: "list.clipboard.fill",              farbe: .indigo, titel: "SAMPLER-Schema",      section: .sampler)
                iPadNavRow(icon: "eye.fill",                         farbe: .purple, titel: "Diagnosen",           section: .diagnose,         badge: diagnoseBadge)
            }
            .disabled(!patientErfasst)
            .opacity(patientErfasst ? 1 : 0.45)

            Section {
                iPadNavRow(icon: "waveform.path.ecg",                farbe: Color(.systemGreen), titel: "Verlauf und Therapie",   section: .verlauf,    badge: verlaufBadge)
                iPadNavRow(icon: "cross.fill",                       farbe: .green,              titel: "Maßnahmen",               section: .massnahmen, badge: moduleBadge)
                iPadNavRow(icon: "bubble.left.and.bubble.right.fill",farbe: .cyan,               titel: "SINNHAFT-Schema",          section: .sinnhaft)
                iPadNavRow(icon: "heart.fill",                       farbe: .red,                titel: "Reanimation und Tod",      section: .reanimation)
                iPadNavRow(icon: "photo.stack.fill",                 farbe: .brown,              titel: "Bilder & Dateien",         section: .bilder,           badge: bilderBadge)
                iPadNavRow(icon: "cross.case.fill",                  farbe: Color("RDOrange"),   titel: "Übergabe-Befunde",          section: .uebergabeBefunde)
            }
            .disabled(!patientErfasst)
            .opacity(patientErfasst ? 1 : 0.45)

            Section {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.body)
                    }
                    Text("Einsatz beenden")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .tag(iPadSection.abschluss)
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Einsatz-Info Header

    private var einsatzInfoHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("RDOrange").opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "cross.circle.fill")
                    .foregroundColor(Color("RDOrange"))
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                if protokoll.einsatzOrt.einsatzNummer.isEmpty {
                    Text("Neuer Einsatz")
                        .font(.subheadline).fontWeight(.semibold)
                } else {
                    Text("Einsatz \(protokoll.einsatzOrt.einsatzNummer)")
                        .font(.subheadline).fontWeight(.semibold)
                }
                let name = [protokoll.patientDaten.vorname, protokoll.patientDaten.nachname]
                    .filter { !$0.isEmpty }.joined(separator: " ")
                Text(name.isEmpty ? "Patient unbekannt" : name)
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch selectedSection {
        case .konfiguration:
            NavigationStack {
                KonfigurationView(protokoll: protokoll)
            }
        case .einsatzzeiten:
            NavigationStack {
                EinsatzzeitenView(protokoll: protokoll)
            }
        case .patient:
            NavigationStack {
                PatientView(protokoll: protokoll)
            }
        case .notfallGeschehen:
            NavigationStack {
                NotfallgeschehenView(befund: $protokoll.notfallGeschehen)
            }
        case .abcde:
            NavigationStack {
                ABCDEUebersichtView(
                    protokoll: protokoll,
                    onAirway:      { selectedSection = .airway },
                    onBreathing:   { selectedSection = .breathing },
                    onCirculation: { selectedSection = .circulation },
                    onDisability:  { selectedSection = .disability },
                    onExposure:    { selectedSection = .exposure }
                )
            }
        case .airway:
            NavigationStack {
                AirwayView(befund: $protokoll.airway, massnahmen: $protokoll.massnahmen) { selectedSection = .breathing }
            }
        case .breathing:
            NavigationStack {
                BreathingView(befund: $protokoll.breathing, massnahmen: $protokoll.massnahmen) { selectedSection = .circulation }
            }
        case .circulation:
            NavigationStack {
                CirculationView(befund: $protokoll.circulation, massnahmen: $protokoll.massnahmen) { selectedSection = .disability }
            }
        case .disability:
            NavigationStack {
                DisabilityView(befund: $protokoll.disability, massnahmen: $protokoll.massnahmen) { selectedSection = .exposure }
            }
        case .exposure:
            NavigationStack {
                ExposureView(protokoll: protokoll) { selectedSection = .sampler }
            }
        case .sampler:
            NavigationStack {
                SAMPLERView(befund: $protokoll.sampler,
                            medikamentFotos: $protokoll.medikamentFotos) { selectedSection = .diagnose }
            }
        case .sinnhaft:
            NavigationStack {
                SINNHAFTView(befund: $protokoll.sinnhaft) { selectedSection = .reanimation }
                    .environmentObject(protokoll)
            }
        case .diagnose:
            NavigationStack {
                DiagnoseView(befund: $protokoll.diagnose)
            }
        case .verlauf:
            NavigationStack {
                VerlaufView(messungen: $protokoll.verlaufMessungen) { selectedSection = .massnahmen }
            }
        case .massnahmen:
            NavigationStack {
                MassnahmenView(befund: $protokoll.massnahmen, onBack: { selectedSection = nil })
            }
        case .reanimation:
            NavigationStack {
                ReanimationView(protokoll: $protokoll.reanimation) { selectedSection = .abschluss }
            }
        case .bilder:
            NavigationStack {
                BilderView(fotos: $protokoll.fotos) { selectedSection = nil }
            }
        case .uebergabeBefunde:
            NavigationStack {
                UebergabeBefundeView(protokoll: protokoll) { selectedSection = nil }
            }
        case .abschluss:
            NavigationStack {
                AbschlussView(protokoll: protokoll, onBack: {
                    protokoll.reset()
                    showingStart = true
                    selectedSection = nil
                })
            }
        case .settings:
            NavigationStack {
                SettingsView(onBack: { selectedSection = nil })
            }
        case nil:
            placeholderDetail
        }
    }

    private var placeholderDetail: some View {
        VStack(spacing: 20) {
            Image(systemName: "cross.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("RDOrange").opacity(0.4))
            Text("Bereich auswählen")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Wähle einen Abschnitt aus dem Menü")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Screenshot

    private func handleScreenshot(_ image: UIImage) {
        isParsing = true
        Task {
            let daten = await ScreenshotParser.parse(image)
            await MainActor.run {
                protokoll.einsatzOrt.einsatzNummer = daten.einsatzNummer
                let code = daten.einsatzArt
                protokoll.einsatzOrt.stichwort  = code
                protokoll.einsatzOrt.einsatzArt = code
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
                isParsing = false
                showingStart = false
                selectedSection = .notfallGeschehen
            }
        }
    }

    // MARK: - Gate

    private var patientErfasst: Bool {
        let p = protokoll.patientDaten
        return !p.vorname.isEmpty || !p.nachname.isEmpty || p.geburtsDatum != nil
    }

    // MARK: - Badge Berechnungen

    private var konfigurationBadge: Int? {
        let eo = protokoll.einsatzOrt
        var count = 0
        if !eo.adresse.isEmpty       { count += 1 }
        if !eo.einsatzNummer.isEmpty { count += 1 }
        if !eo.stichwort.isEmpty     { count += 1 }
        if !eo.fahrzeugName.isEmpty  { count += 1 }
        return count > 0 ? count : nil
    }

    private var patientBadge: Int? {
        let p = protokoll.patientDaten
        var count = 0
        if !p.vorname.isEmpty         { count += 1 }
        if !p.nachname.isEmpty        { count += 1 }
        if p.geburtsDatum != nil      { count += 1 }
        if p.geschlecht != .unbekannt { count += 1 }
        return count > 0 ? count : nil
    }

    private var notfallBadge: Int? {
        let b = protokoll.notfallGeschehen
        var count = 0
        if !b.unfallhergangAuswahl.isEmpty                              { count += 1 }
        if !b.unfallmechanismus.isEmpty                                  { count += 1 }
        if !b.preEmergencyStatus.isEmpty                                 { count += 1 }
        if !b.erstbefundAuswahl.isEmpty || !b.erstbefundVorOrt.isEmpty  { count += 1 }
        if !b.verlaufsbemerkungen.isEmpty                                { count += 1 }
        return count > 0 ? count : nil
    }

    private var diagnoseBadge: Int? {
        let c = protokoll.diagnose.verdachtsdiagnosen.count
        return c > 0 ? c : nil
    }

    private var befundeBadge: Int? {
        let count = [protokoll.airway.status,
                     protokoll.breathing.status,
                     protokoll.circulation.status,
                     protokoll.disability.status,
                     protokoll.exposure.status]
            .filter { $0 != .unbewertet }.count
        return count > 0 ? count : nil
    }

    private var verlaufBadge: Int? {
        let c = protokoll.verlaufMessungen.count
        return c > 0 ? c : nil
    }

    private var moduleBadge: Int? {
        let m = protokoll.massnahmen
        var count = protokoll.medikamente.count
        if m.sauerstoffgabe  { count += 1 }
        if m.maskenbeatmung  { count += 1 }
        if m.supraglottisch  { count += 1 }
        if m.peripherVenoes  { count += 1 }
        if m.vakuummatratze  { count += 1 }
        if m.tourniquet      { count += 1 }
        return count > 0 ? count : nil
    }

    private var bilderBadge: Int? {
        let c = protokoll.fotos.count
        return c > 0 ? c : nil
    }
}

// MARK: - Sidebar Row

private struct iPadNavRow: View {
    let icon: String
    let farbe: Color
    let titel: String
    let section: iPadMainView.iPadSection
    var badge: Int? = nil

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(farbe.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(farbe)
                    .font(.body)
            }
            Text(titel)
                .foregroundColor(.primary)
                .fontWeight(.medium)
            Spacer()
            if let count = badge, count > 0 {
                Text("\(min(count, 99))")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color("RDOrange"))
                    .clipShape(Capsule())
            }
        }
        .tag(section)
    }
}
