import SwiftUI
import PhotosUI

// MARK: - iPad Hauptview mit NavigationSplitView

struct iPadMainView: View {
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    @EnvironmentObject private var appState: AppState

    @State private var selectedSection: iPadSection? = nil
    @State private var abcdeExpanded = true

    // Screenshot-Import
    @State private var isParsing = false
    @State private var parseError: String? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isLoadingPhoto = false

    @State private var showingStart = true
    @State private var zeigeArchiv = false

    enum iPadSection: Hashable {
        case einsatzOrt
        case notfallGeschehen
        case airway, breathing, circulation, disability, exposure
        case sampler
        case sinnhaft
        case diagnose
        case verlauf
        case massnahmen
        case reanimation
        case bilder
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
                    Text("RD Protokoll")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("Einsatzprotokollierung Rettungsdienst")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                VStack(spacing: 14) {
                    Button {
                        protokoll.reset()
                        showingStart = false
                        selectedSection = .einsatzOrt
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
                selectedSection = .einsatzOrt
            })
            .environmentObject(protokoll)
        }
    }

    // MARK: - Haupt-Protokoll (NavigationSplitView)

    private var hauptProtokoll: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebarContent
                .navigationTitle("RD Protokoll")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingStart = true
                            selectedSection = nil
                            protokoll.reset()
                        } label: {
                            Label("Einsatz beenden", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
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

            // Einsatz-Info Header
            einsatzInfoHeader

            // Einsatzdaten
            Section("Einsatzdaten") {
                iPadNavRow(icon: "clock", farbe: .primary,
                           titel: "Einsatzzeiten",
                           untertitel: einsatzzeitenUntertitel(),
                           section: .einsatzOrt)
                iPadNavRow(icon: "doc.on.clipboard", farbe: .primary,
                           titel: "Rettungstechnische Daten",
                           untertitel: protokoll.einsatzOrt.adresse.isEmpty
                               ? "Einsatzort & Patient"
                               : protokoll.einsatzOrt.adresse,
                           section: .einsatzOrt)
                iPadNavRow(icon: "bell.fill", farbe: .primary,
                           titel: "Notfallgeschehen",
                           untertitel: protokoll.notfallGeschehen.erstbefundVorOrt.isEmpty
                               ? "Erstbefund & Notfallgeschehen"
                               : protokoll.notfallGeschehen.erstbefundVorOrt,
                           section: .notfallGeschehen)
            }

            // Befunde (ABCDE)
            Section("Befunde") {
                ABCDESidebarZeile(buchstabe: "A", farbe: .orange,
                                  titel: "Airway",
                                  status: protokoll.airway.status,
                                  section: .airway)
                ABCDESidebarZeile(buchstabe: "B", farbe: .blue,
                                  titel: "Breathing",
                                  status: protokoll.breathing.status,
                                  section: .breathing)
                ABCDESidebarZeile(buchstabe: "C", farbe: .red,
                                  titel: "Circulation",
                                  status: protokoll.circulation.status,
                                  section: .circulation)
                ABCDESidebarZeile(buchstabe: "D", farbe: .purple,
                                  titel: "Disability",
                                  status: protokoll.disability.status,
                                  section: .disability)
                ABCDESidebarZeile(buchstabe: "E", farbe: .green,
                                  titel: "Exposure",
                                  status: protokoll.exposure.status,
                                  section: .exposure)
            }

            // Diagnose & Verlauf
            Section("Diagnose") {
                iPadNavRow(icon: "eye.fill", farbe: .primary,
                           titel: "Diagnosen",
                           untertitel: diagnoseUntertitel(),
                           section: .diagnose)
                iPadNavRow(icon: "waveform.path.ecg", farbe: .primary,
                           titel: "Verlauf und Therapie",
                           untertitel: protokoll.verlaufMessungen.isEmpty
                               ? "Noch keine Messungen"
                               : "\(protokoll.verlaufMessungen.count) Messung(en)",
                           section: .verlauf)
            }

            // Module & Therapie
            Section("Module") {
                iPadNavRow(icon: "list.clipboard.fill", farbe: .teal,
                           titel: "SAMPLER",
                           untertitel: "Anamnese & Vorgeschichte",
                           section: .sampler)
                iPadNavRow(icon: "bubble.left.and.bubble.right.fill", farbe: .indigo,
                           titel: "SINNHAFT",
                           untertitel: "Strukturiertes Übergabeschema",
                           section: .sinnhaft)
                iPadNavRow(icon: "square.grid.2x2.fill", farbe: .primary,
                           titel: "Maßnahmen",
                           untertitel: massnahmenUntertitel(),
                           section: .massnahmen)
                iPadNavRow(icon: "photo.stack", farbe: .primary,
                           titel: "Bilder & Dateien",
                           untertitel: protokoll.fotos.isEmpty
                               ? "Keine Fotos"
                               : "\(protokoll.fotos.count) Foto(s)",
                           section: .bilder)
            }

            // Abschluss
            Section("Abschluss") {
                iPadNavRow(icon: "heart.fill",
                           farbe: protokoll.reanimationAktiv ? .red : .primary,
                           titel: "Reanimation und Tod",
                           untertitel: protokoll.reanimationAktiv
                               ? "Protokoll aktiv"
                               : "Nicht durchgeführt",
                           section: .reanimation)
                iPadNavRow(icon: "list.bullet.rectangle.portrait", farbe: .primary,
                           titel: "Ergebnis",
                           untertitel: "Einsatz abschließen und exportieren",
                           section: .abschluss)
                iPadNavRow(icon: "gearshape.fill", farbe: .secondary,
                           titel: "Konfiguration",
                           untertitel: "",
                           section: .settings)
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Einsatz-Info Header im Sidebar

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
        case .einsatzOrt:
            NavigationStack {
                EinsatzOrtView(
                    protokoll: protokoll,
                    onWeiter: { selectedSection = .notfallGeschehen },
                    onBack: { }
                )
            }
        case .notfallGeschehen:
            NavigationStack {
                NotfallgeschehenView(befund: $protokoll.notfallGeschehen)
            }
        case .airway:
            NavigationStack {
                AirwayView(befund: $protokoll.airway) { selectedSection = .breathing }
            }
        case .breathing:
            NavigationStack {
                BreathingView(befund: $protokoll.breathing) { selectedSection = .circulation }
            }
        case .circulation:
            NavigationStack {
                CirculationView(befund: $protokoll.circulation) { selectedSection = .disability }
            }
        case .disability:
            NavigationStack {
                DisabilityView(befund: $protokoll.disability) { selectedSection = .exposure }
            }
        case .exposure:
            NavigationStack {
                ExposureView(befund: $protokoll.exposure) { selectedSection = .sampler }
            }
        case .sampler:
            NavigationStack {
                SAMPLERView(befund: $protokoll.sampler,
                            medikamentFotos: $protokoll.medikamentFotos) { selectedSection = .sinnhaft }
            }
        case .sinnhaft:
            NavigationStack {
                SINNHAFTView(befund: $protokoll.sinnhaft) { selectedSection = .diagnose }
                    .environmentObject(protokoll)
            }
        case .diagnose:
            NavigationStack {
                DiagnoseView(befund: $protokoll.diagnose)
            }
        case .verlauf:
            NavigationStack {
                VerlaufView(messungen: $protokoll.verlaufMessungen) { selectedSection = .diagnose }
            }
        case .massnahmen:
            NavigationStack {
                MassnahmenView(befund: $protokoll.massnahmen, onBack: { selectedSection = .diagnose })
            }
        case .reanimation:
            NavigationStack {
                ReanimationView(protokoll: $protokoll.reanimation) { selectedSection = .abschluss }
            }
        case .bilder:
            NavigationStack {
                BilderView(fotos: $protokoll.fotos) { selectedSection = .reanimation }
            }
        case .abschluss:
            NavigationStack {
                AbschlussView(protokoll: protokoll, onBack: { selectedSection = .massnahmen })
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
                isParsing = false
                showingStart = false
                selectedSection = .notfallGeschehen
            }
        }
    }

    // MARK: - Hilfsfunktionen

    private func einsatzzeitenUntertitel() -> String {
        let eo = protokoll.einsatzOrt
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        if let alarm = eo.alarmzeit {
            return "Alarm \(formatter.string(from: alarm))"
        }
        return "Zeiten noch nicht erfasst"
    }

    private func diagnoseUntertitel() -> String {
        let fuehrend = protokoll.diagnose.verdachtsdiagnosen.first { $0.wahrscheinlichkeit == .fuehrend }
        if let f = fuehrend { return "V.a. \(f.name)" }
        if !protokoll.diagnose.leitsymptom.isEmpty { return protokoll.diagnose.leitsymptom }
        let c = protokoll.diagnose.verdachtsdiagnosen.count
        return c == 0 ? "Noch nicht erfasst" : "\(c) Verdachtsdiagnosen"
    }

    private func massnahmenUntertitel() -> String {
        let m = protokoll.massnahmen
        var aktive: [String] = []
        if m.sauerstoffgabe  { aktive.append("O₂") }
        if m.maskenbeatmung  { aktive.append("Maskenbeatmung") }
        if m.supraglottisch  { aktive.append("Supraglottisch") }
        if m.peripherVenoes  { aktive.append("IV-Zugang") }
        if m.vakuummatratze  { aktive.append("Vakuummatratze") }
        if m.tourniquet      { aktive.append("Tourniquet") }
        return aktive.isEmpty ? "Noch nicht erfasst" : aktive.joined(separator: ", ")
    }
}

// MARK: - Sidebar Hilfskomponenten

private struct iPadNavRow: View {
    let icon: String
    let farbe: Color
    let titel: String
    let untertitel: String
    let section: iPadMainView.iPadSection

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(.subheadline).fontWeight(.semibold)
                if !untertitel.isEmpty {
                    Text(untertitel)
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        } icon: {
            Image(systemName: icon)
                .foregroundColor(farbe)
                .frame(width: 28, height: 28)
                .background(farbe.opacity(0.15))
                .cornerRadius(6)
        }
        .tag(section)
    }
}

private struct ABCDESidebarZeile: View {
    let buchstabe: String
    let farbe: Color
    let titel: String
    let status: ABCDEStatus
    let section: iPadMainView.iPadSection

    var body: some View {
        Label {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel)
                        .font(.subheadline).fontWeight(.semibold)
                    Text(status.rawValue)
                        .font(.caption)
                        .foregroundColor(status.color)
                }
                Spacer()
                Image(systemName: status.symbol)
                    .foregroundColor(status.color)
                    .font(.caption)
            }
        } icon: {
            Text(buchstabe)
                .font(.subheadline).fontWeight(.bold)
                .foregroundColor(status == .unbewertet ? farbe : status.color)
                .frame(width: 28, height: 28)
                .background((status == .unbewertet ? farbe : status.color).opacity(0.15))
                .cornerRadius(6)
        }
        .tag(section)
    }
}
