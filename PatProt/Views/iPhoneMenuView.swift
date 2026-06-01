import SwiftUI

// MARK: - iPhone Navigation Menu (eigenständiger View im NavigationStack)

struct iPhoneMenuView: View {
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    @Binding var path: [iPhoneAppStep]
    @State private var zeigeVerlassenWarnung = false

    var body: some View {
        List {
            // Einsatz-Basisdaten
            Section {
                menuRow("Konfiguration",    icon: "gearshape.fill",         color: .gray,   step: .konfiguration,    warnBadge: konfigWarn)
                menuRow("Einsatzzeiten",    icon: "clock.fill",              color: .blue,   step: .einsatzzeiten)
                menuRow("Patient",          icon: "person.fill",             color: .teal,   step: .patient,          warnBadge: patientWarn)
            }

            // Klinische Erfassung
            Section {
                menuRow("Notfallgeschehen", icon: "bell.fill",               color: .orange, step: .notfallGeschehen)
                menuRow("ABCDE",            icon: "staroflife.fill",         color: .red,    step: .abcde,            warnBadge: abcdeWarn)
                menuRow("SAMPLER-Schema",   icon: "list.clipboard.fill",     color: .indigo, step: .sampler)
                menuRow("Diagnosen",        icon: "eye.fill",                color: .purple, step: .diagnose)
            }

            // Verlauf & Therapie
            Section {
                menuRow("Verlauf und Therapie",  icon: "waveform.path.ecg",               color: Color(.systemGreen),  step: .verlauf)
                menuRow("Maßnahmen",             icon: "cross.fill",                       color: .green,               step: .massnahmen)
                menuRow("SINNHAFT-Schema",       icon: "bubble.left.and.bubble.right.fill", color: .cyan,              step: .sinnhaft)
                menuRow("Reanimation und Tod",   icon: "heart.fill",                       color: .red,                 step: .reanimation)
                menuRow("Bilder & Dateien",      icon: "photo.stack.fill",                color: .brown,               step: .bilder)
                menuRow("Übergabe-Befunde",      icon: "cross.case.fill",                 color: Color("RDOrange"),    step: .uebergabeBefunde)
            }

            // Abschluss
            Section {
                Button {
                    path.append(.abschluss)
                } label: {
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
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color(.systemGray3))
                            .font(.caption)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Menü")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hatDaten {
                        zeigeVerlassenWarnung = true
                    } else {
                        path = []
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text("Start")
                    }
                }
            }
        }
        .confirmationDialog("Einsatz abbrechen?",
                            isPresented: $zeigeVerlassenWarnung,
                            titleVisibility: .visible) {
            Button("Zurück ohne Speichern", role: .destructive) { path = [] }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Es wurden bereits Daten erfasst. Wenn du zurückgehst, gehen alle Eingaben verloren.")
        }
    }

    private var hatDaten: Bool {
        let p = protokoll.patientDaten
        let eo = protokoll.einsatzOrt
        return !p.vorname.isEmpty
            || !p.nachname.isEmpty
            || p.geburtsDatum != nil
            || !eo.stichwort.isEmpty
            || !eo.einsatzNummer.isEmpty
            || !protokoll.verlaufMessungen.isEmpty
            || protokoll.massnahmen.sauerstoffgabe
            || !protokoll.medikamente.isEmpty
    }

    // MARK: - Menu Row

    private func menuRow(_ title: String, icon: String, color: Color,
                         step: iPhoneAppStep, warnBadge: Int? = nil) -> some View {
        Button { path.append(step) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.body)
                }
                Text(title)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                Spacer()
                if let n = warnBadge, n > 0 {
                    Text("\(n)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.red)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.systemGray3))
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Pflichtfeld-Warnungen (rote Zahl = Anzahl fehlender Pflichtfelder)

    /// Konfiguration: Adresse + Stichwort sind Pflicht
    private var konfigWarn: Int? {
        let eo = protokoll.einsatzOrt
        var m = 0
        if eo.adresse.isEmpty  { m += 1 }
        if eo.stichwort.isEmpty { m += 1 }
        return m > 0 ? m : nil
    }

    /// Patient: Vorname, Nachname, Geburtsdatum sind Pflicht
    private var patientWarn: Int? {
        let p = protokoll.patientDaten
        var m = 0
        if p.vorname.isEmpty     { m += 1 }
        if p.nachname.isEmpty    { m += 1 }
        if p.geburtsDatum == nil { m += 1 }
        return m > 0 ? m : nil
    }

    /// ABCDE: alle 5 Komponenten müssen bewertet sein
    private var abcdeWarn: Int? {
        let n = [protokoll.airway.status, protokoll.breathing.status,
                 protokoll.circulation.status, protokoll.disability.status,
                 protokoll.exposure.status].filter { $0 == .unbewertet }.count
        return n > 0 ? n : nil
    }
}
