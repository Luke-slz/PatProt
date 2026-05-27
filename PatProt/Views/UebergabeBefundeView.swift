import SwiftUI

// MARK: - Dual-Checkbox Zeile (Ankunft read-only, Übergabe tippbar)

struct DualCheckRow: View {
    let label: String
    let ankunft: Bool
    @Binding var uebergabe: Bool

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: ankunft ? "checkmark.square.fill" : "square")
                .foregroundColor(ankunft ? Color("RDOrange").opacity(0.5) : .secondary)
                .font(.title3)
                .frame(width: 32)
            Text(label)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
            Button { uebergabe.toggle() } label: {
                Image(systemName: uebergabe ? "checkmark.square.fill" : "square")
                    .foregroundColor(uebergabe ? Color("RDOrange") : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .frame(width: 32)
        }
    }
}

// MARK: - Übergabe-Befunde View

struct UebergabeBefundeView: View {
    @ObservedObject var protokoll: EinsatzProtokoll
    var onBack: () -> Void

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Ankunft")
                        .font(.caption).foregroundColor(.secondary)
                        .frame(width: 32)
                    Spacer()
                    Text("Übergabe")
                        .font(.caption).foregroundColor(.secondary)
                        .frame(width: 32)
                }
            }

            // MARK: A+B Atmung
            Section("A+B Atmung") {
                DualCheckRow(label: "unauffällig",
                             ankunft: protokoll.breathing.status == .nicht_kritisch,
                             uebergabe: $protokoll.uebergabeBefunde.abUnauffaellig)
                DualCheckRow(label: "Dyspnoe",
                             ankunft: protokoll.breathing.dyspnoe,
                             uebergabe: $protokoll.uebergabeBefunde.dyspnoe)
                DualCheckRow(label: "Zyanose",
                             ankunft: protokoll.breathing.zyanose,
                             uebergabe: $protokoll.uebergabeBefunde.zyanose)
                DualCheckRow(label: "Spastik",
                             ankunft: protokoll.breathing.spastik,
                             uebergabe: $protokoll.uebergabeBefunde.spastik)
                DualCheckRow(label: "Rasselgeräusche",
                             ankunft: protokoll.breathing.rasselgeraeusche,
                             uebergabe: $protokoll.uebergabeBefunde.rasselgeraeusche)
                DualCheckRow(label: "Brodeln",
                             ankunft: protokoll.breathing.brodeln,
                             uebergabe: $protokoll.uebergabeBefunde.brodeln)
                DualCheckRow(label: "Stridor",
                             ankunft: protokoll.breathing.stridor,
                             uebergabe: $protokoll.uebergabeBefunde.stridor)
                DualCheckRow(label: "Atemwegsverl.",
                             ankunft: protokoll.airway.verlegung,
                             uebergabe: $protokoll.uebergabeBefunde.atemwegsverlegung)
                DualCheckRow(label: "Schnappatmung",
                             ankunft: protokoll.breathing.schnappatmung,
                             uebergabe: $protokoll.uebergabeBefunde.schnappatmung)
                DualCheckRow(label: "Apnoe",
                             ankunft: protokoll.breathing.apnoe,
                             uebergabe: $protokoll.uebergabeBefunde.apnoe)
                DualCheckRow(label: "Beatmung",
                             ankunft: protokoll.breathing.beatmung,
                             uebergabe: $protokoll.uebergabeBefunde.beatmung)
                DualCheckRow(label: "Hyperventilation",
                             ankunft: protokoll.breathing.hyperventilation,
                             uebergabe: $protokoll.uebergabeBefunde.hyperventilation)
                DualCheckRow(label: "n. beurteilbar",
                             ankunft: protokoll.breathing.abNichtBeurteilbar,
                             uebergabe: $protokoll.uebergabeBefunde.abNichtBeurteilbar)
            }

            // MARK: Schmerz
            Section("Schmerz (NRS 0–10)") {
                HStack {
                    Text("Ankunft: \(protokoll.disability.schmerz)/10")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                HStack {
                    Text("Übergabe: \(protokoll.uebergabeBefunde.schmerz)/10")
                    Spacer()
                    Stepper("", value: $protokoll.uebergabeBefunde.schmerz, in: 0...10)
                        .labelsHidden()
                }
            }

            // MARK: C Kreislauf + EKG
            Section("C Kreislauf + EKG") {
                DualCheckRow(label: "unauffällig",
                             ankunft: protokoll.circulation.status == .nicht_kritisch,
                             uebergabe: $protokoll.uebergabeBefunde.cUnauffaellig)
                DualCheckRow(label: "Rekap. > 2 Sek.",
                             ankunft: protokoll.circulation.rekapillierung,
                             uebergabe: $protokoll.uebergabeBefunde.rekapillierung)
                DualCheckRow(label: "Sinusrhythmus",
                             ankunft: protokoll.circulation.sinusrhythmus,
                             uebergabe: $protokoll.uebergabeBefunde.sinusrhythmus)
                DualCheckRow(label: "Abs. Arrhythmie",
                             ankunft: protokoll.circulation.absoluteArrhythmie,
                             uebergabe: $protokoll.uebergabeBefunde.absoluteArrhythmie)
                DualCheckRow(label: "AV-Block II°/III°",
                             ankunft: protokoll.circulation.avBlock,
                             uebergabe: $protokoll.uebergabeBefunde.avBlock)
                DualCheckRow(label: "QRS-Tachy breit",
                             ankunft: protokoll.circulation.qrsTachykardieBreit,
                             uebergabe: $protokoll.uebergabeBefunde.qrsTachykardieBreit)
                DualCheckRow(label: "QRS-Tachy schmal",
                             ankunft: protokoll.circulation.qrsTachykardieSchmal,
                             uebergabe: $protokoll.uebergabeBefunde.qrsTachykardieSchmal)
                DualCheckRow(label: "Kammerflattern",
                             ankunft: protokoll.circulation.kammerflattern,
                             uebergabe: $protokoll.uebergabeBefunde.kammerflattern)
                DualCheckRow(label: "PEA",
                             ankunft: protokoll.circulation.pea,
                             uebergabe: $protokoll.uebergabeBefunde.pea)
                DualCheckRow(label: "Asystolie",
                             ankunft: protokoll.circulation.asystolie,
                             uebergabe: $protokoll.uebergabeBefunde.asystolie)
                DualCheckRow(label: "Schrittmacher",
                             ankunft: protokoll.circulation.schrittmacher,
                             uebergabe: $protokoll.uebergabeBefunde.schrittmacher)
                DualCheckRow(label: "Infarkt-EKG",
                             ankunft: protokoll.circulation.infarktEkg,
                             uebergabe: $protokoll.uebergabeBefunde.infarktEkg)
                DualCheckRow(label: "SVES",
                             ankunft: protokoll.circulation.sves,
                             uebergabe: $protokoll.uebergabeBefunde.sves)
                DualCheckRow(label: "VES",
                             ankunft: protokoll.circulation.ves,
                             uebergabe: $protokoll.uebergabeBefunde.ves)
                DualCheckRow(label: "Monomorph",
                             ankunft: protokoll.circulation.extrasystolenMonomorph,
                             uebergabe: $protokoll.uebergabeBefunde.extrasystolenMonomorph)
                DualCheckRow(label: "Polymorph",
                             ankunft: protokoll.circulation.extrasystolenPolymorph,
                             uebergabe: $protokoll.uebergabeBefunde.extrasystolenPolymorph)
                DualCheckRow(label: "n. beurteilbar",
                             ankunft: protokoll.circulation.cNichtBeurteilbar,
                             uebergabe: $protokoll.uebergabeBefunde.cNichtBeurteilbar)
            }

            // MARK: D Neurologie
            Section("D Neurologie") {
                DualCheckRow(label: "unauffällig",
                             ankunft: protokoll.disability.status == .nicht_kritisch,
                             uebergabe: $protokoll.uebergabeBefunde.dUnauffaellig)
                // Bewusstsein
                DualCheckRow(label: "Wach",
                             ankunft: protokoll.disability.bewWach,
                             uebergabe: $protokoll.uebergabeBefunde.bewWach)
                DualCheckRow(label: "Reagiert Ansprache",
                             ankunft: protokoll.disability.bewAnsprache,
                             uebergabe: $protokoll.uebergabeBefunde.bewAnsprache)
                DualCheckRow(label: "Reagiert Schmerz",
                             ankunft: protokoll.disability.bewSchmerzreiz,
                             uebergabe: $protokoll.uebergabeBefunde.bewSchmerzreiz)
                DualCheckRow(label: "Bewusstlos",
                             ankunft: protokoll.disability.bewusstlos,
                             uebergabe: $protokoll.uebergabeBefunde.bewusstlos)
                DualCheckRow(label: "n. beurteilbar",
                             ankunft: protokoll.disability.dNichtBeurteilbar,
                             uebergabe: $protokoll.uebergabeBefunde.dNichtBeurteilbar)
            }

            // MARK: Pupillen
            Section("Pupillen") {
                Text("Rechts").font(.caption).foregroundColor(.secondary)
                DualCheckRow(label: "eng",
                             ankunft: protokoll.disability.pupilleReEng,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleReEng)
                DualCheckRow(label: "mittel",
                             ankunft: protokoll.disability.pupilleReMittel,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleReMittel)
                DualCheckRow(label: "weit",
                             ankunft: protokoll.disability.pupilleReWeit,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleReWeit)
                DualCheckRow(label: "entrundet",
                             ankunft: protokoll.disability.pupilleReEntrundet,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleReEntrundet)
                DualCheckRow(label: "keine Lichtreakt.",
                             ankunft: protokoll.disability.pupilleReKeineLichtreaktion,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleReKeineLichtreaktion)
                DualCheckRow(label: "n. beurteilbar",
                             ankunft: protokoll.disability.pupilleReNichtBeurteilbar,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleReNichtBeurteilbar)
                Text("Links").font(.caption).foregroundColor(.secondary)
                DualCheckRow(label: "eng",
                             ankunft: protokoll.disability.pupilleLiEng,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleLiEng)
                DualCheckRow(label: "mittel",
                             ankunft: protokoll.disability.pupilleLiMittel,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleLiMittel)
                DualCheckRow(label: "weit",
                             ankunft: protokoll.disability.pupilleLiWeit,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleLiWeit)
                DualCheckRow(label: "entrundet",
                             ankunft: protokoll.disability.pupilleLiEntrundet,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleLiEntrundet)
                DualCheckRow(label: "keine Lichtreakt.",
                             ankunft: protokoll.disability.pupilleLiKeineLichtreaktion,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleLiKeineLichtreaktion)
                DualCheckRow(label: "n. beurteilbar",
                             ankunft: protokoll.disability.pupilleLiNichtBeurteilbar,
                             uebergabe: $protokoll.uebergabeBefunde.pupilleLiNichtBeurteilbar)
            }

            // MARK: GCS
            Section("GCS") {
                HStack {
                    Text("Ankunft: \(protokoll.disability.gcsGesamt)/15")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                GCSStepper(titel: "Augen (E)", wert: $protokoll.uebergabeBefunde.gcsAugen, min: 1, max: 4)
                GCSStepper(titel: "Verbal (V)", wert: $protokoll.uebergabeBefunde.gcsVerbal, min: 1, max: 5)
                GCSStepper(titel: "Motorik (M)", wert: $protokoll.uebergabeBefunde.gcsMotor, min: 1, max: 6)
                HStack {
                    Text("Übergabe gesamt:")
                    Spacer()
                    Text("\(protokoll.uebergabeBefunde.gcsGesamt)/15")
                        .fontWeight(.semibold)
                }
            }

            // MARK: Neuro Auffälligkeiten
            Section("Neurologische Auffälligkeiten") {
                DualCheckRow(label: "Vorb. neurol. Defizit",
                             ankunft: protokoll.disability.neuroVorbestehendesDefizit,
                             uebergabe: $protokoll.uebergabeBefunde.neuroVorbestehendesDefizit)
                DualCheckRow(label: "Facialisparese",
                             ankunft: protokoll.disability.neuroFacialisparese,
                             uebergabe: $protokoll.uebergabeBefunde.neuroFacialisparese)
                DualCheckRow(label: "Armparese",
                             ankunft: protokoll.disability.neuroArmparese,
                             uebergabe: $protokoll.uebergabeBefunde.neuroArmparese)
                DualCheckRow(label: "Sprachstörung",
                             ankunft: protokoll.disability.neuroSprachstoerung,
                             uebergabe: $protokoll.uebergabeBefunde.neuroSprachstoerung)
                DualCheckRow(label: "Sehstörung",
                             ankunft: protokoll.disability.neuroSehstoerung,
                             uebergabe: $protokoll.uebergabeBefunde.neuroSehstoerung)
                DualCheckRow(label: "Babinski-Zeichen",
                             ankunft: protokoll.disability.neuroBabinski,
                             uebergabe: $protokoll.uebergabeBefunde.neuroBabinski)
                DualCheckRow(label: "Querschnittsympt.",
                             ankunft: protokoll.disability.neuroQuerschnitt,
                             uebergabe: $protokoll.uebergabeBefunde.neuroQuerschnitt)
                DualCheckRow(label: "Meningismus",
                             ankunft: protokoll.disability.neuroMeningismus,
                             uebergabe: $protokoll.uebergabeBefunde.neuroMeningismus)
                DualCheckRow(label: "Demenz",
                             ankunft: protokoll.disability.neuroDemenz,
                             uebergabe: $protokoll.uebergabeBefunde.neuroDemenz)
                DualCheckRow(label: "n. beurteilbar",
                             ankunft: protokoll.disability.neuroNichtBeurteilbar,
                             uebergabe: $protokoll.uebergabeBefunde.neuroNichtBeurteilbar)
            }
        }
        .navigationTitle("Übergabe-Befunde")
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            Button(action: onBack) {
                Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("RDOrange"))
            .padding([.horizontal, .bottom])
            .background(.bar)
        }
    }
}
