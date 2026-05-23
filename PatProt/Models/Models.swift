import Foundation
import SwiftUI
import Combine

// MARK: - Enums

enum Geschlecht: String, CaseIterable, Codable {
    case maennlich = "Männlich"
    case weiblich = "Weiblich"
    case unbekannt = "Unbekannt"
}

enum FahrzeugTyp: String, CaseIterable, Codable {
    case ktw = "KTW"
    case rtw = "RTW"
    case nef = "NEF"
}

enum ABCDEStatus: String, Codable {
    case kritisch = "Problem"
    case nicht_kritisch = "Kein Problem"
    case unbewertet = "Unbewertet"

    var color: Color {
        switch self {
        case .nicht_kritisch: return .green
        case .kritisch: return .red
        case .unbewertet: return .gray
        }
    }

    var symbol: String {
        switch self {
        case .nicht_kritisch: return "checkmark.circle.fill"
        case .kritisch: return "xmark.circle.fill"
        case .unbewertet: return "questionmark.circle.fill"
        }
    }
}

enum InitialRhythmus: String, CaseIterable, Codable {
    case vf = "Kammerflimmern (VF)"
    case vtPulslos = "VT pulslos"
    case asystolie = "Asystolie"
    case pea = "PEA"
    case unbekannt = "Unbekannt"
}

enum ReaniOutcome: String, CaseIterable, Codable {
    case rosc = "ROSC erreicht"
    case verstorben = "Verstorben"
    case transportiert = "Transportiert ohne ROSC"
}

enum Verletzungsgrad: String, CaseIterable, Codable {
    case keine = "–"
    case leicht = "Leicht"
    case schwer = "Schwer"
}

enum NacaScore: Int, CaseIterable, Codable {
    case naca0 = 0, naca1 = 1, naca2 = 2, naca3 = 3
    case naca4 = 4, naca5 = 5, naca6 = 6, naca7 = 7

    var beschreibung: String {
        switch self {
        case .naca0: return "0 – Keine Verletzung / Erkrankung"
        case .naca1: return "1 – Geringe Störung, keine ärztliche Behandlung"
        case .naca2: return "2 – Ambulante Abklärung / Behandlung"
        case .naca3: return "3 – Stationäre Behandlung, keine Lebensgefahr"
        case .naca4: return "4 – Akute Lebensgefahr nicht ausgeschlossen"
        case .naca5: return "5 – Akute Lebensgefahr"
        case .naca6: return "6 – Reanimation"
        case .naca7: return "7 – Tod"
        }
    }
}

enum ProtokollVerfasser: String, CaseIterable, Codable {
    case notfallsanitaeter = "Notfallsanitäter"
    case rettungssanitaeter = "Rettungssanitäter"
}

enum TransportZiel: String, CaseIterable, Codable {
    case anderesRettungsmittel = "Anderes Rettungsmittel"
}

// MARK: - Models

class EinsatzProtokoll: ObservableObject, Identifiable {
    let id = UUID()

    // Einsatzdaten
    @Published var einsatzOrt = EinsatzOrt()
    @Published var patientDaten = PatientDaten()
    @Published var besatzung = Besatzung()

    // Notfallgeschehen
    @Published var notfallGeschehen = NotfallgeschehenBefund()

    // Gesamtbewertung
    @Published var kritisch: Bool = false

    // ABCDE
    @Published var airway = AirwayBefund()
    @Published var breathing = BreathingBefund()
    @Published var circulation = CirculationBefund()
    @Published var disability = DisabilityBefund()
    @Published var exposure = ExposureBefund()

    // SAMPLER
    @Published var sampler = SAMPLERBefund()

    // SINNHAFT
    @Published var sinnhaft = SINNHAFTBefund()

    // Diagnose (Trichter)
    @Published var diagnose = DiagnoseBefund()

    // Verlauf & Therapie
    @Published var verlaufMessungen: [VerlaufsMessung] = []

    // Maßnahmen
    @Published var massnahmen = MassnahmenBefund()

    // Medikamente
    @Published var medikamente: [MedikamentEintrag] = []

    // Reanimation
    @Published var reanimationAktiv = false
    @Published var reanimation = ReanimationsProtokoll()

    // Bilder (in-app only, nicht auf Gerät gespeichert)
    @Published var fotos: [FotoEintrag] = []

    // Medikamentenplan-Fotos (in-app only, nicht archiviert)
    @Published var medikamentFotos: [FotoEintrag] = []

    // Ergebnis
    @Published var ergebnis = ErgebnisData()

    // Abschluss
    @Published var uebergabeAn = ""
    @Published var zustandBeiUebergabe = ""
    @Published var verfasser: ProtokollVerfasser = .notfallsanitaeter

    var erstelltAm: Date = Date()

    func reset() {
        einsatzOrt = EinsatzOrt()
        einsatzOrt.alarmzeit = Date()
        patientDaten = PatientDaten()
        besatzung = Besatzung()
        notfallGeschehen = NotfallgeschehenBefund()
        kritisch = false
        airway = AirwayBefund()
        breathing = BreathingBefund()
        circulation = CirculationBefund()
        disability = DisabilityBefund()
        exposure = ExposureBefund()
        sampler = SAMPLERBefund()
        sinnhaft = SINNHAFTBefund()
        diagnose = DiagnoseBefund()
        verlaufMessungen = []
        massnahmen = MassnahmenBefund()
        medikamente = []
        reanimationAktiv = false
        reanimation = ReanimationsProtokoll()
        fotos.forEach { $0.loeschen() }
        fotos = []
        medikamentFotos.forEach { $0.loeschen() }
        medikamentFotos = []
        ergebnis = ErgebnisData()
        uebergabeAn = ""
        zustandBeiUebergabe = ""
        verfasser = .notfallsanitaeter
        erstelltAm = Date()
    }
}

struct EinsatzOrt: Codable {
    var adresse = ""
    var zusatz = ""
    var einsatzArt = ""
    var stichwort = ""
    var fahrzeugName: String = ""  // war: fahrzeugTyp + customFahrzeugName
    var weitereEinsatzmittel: [String] = []
    var alarmzeit: Date? = nil
    var ankunftzeit: Date? = nil
    var abfahrtzeit: Date? = nil
    var krankenHausAnkunft: Date? = nil
    var einsatzNummer = ""
    var notarzt: Bool = false
    var sondersignal: Bool = false
    var mitPatient: Bool = false
}


struct PatientDaten: Codable {
    var vorname = ""
    var nachname = ""
    var geburtsDatum: Date? = nil
    var geschlecht: Geschlecht = .unbekannt
    var versicherungsNummer = ""
    var kostentraeger = ""
    var gewicht: Double? = nil
    var ansprechbar = false

    var alter: Int? {
        guard let geb = geburtsDatum else { return nil }
        return Calendar.current.dateComponents([.year], from: geb, to: Date()).year
    }
}

struct Besatzung: Codable {
    var sanitaeter1 = ""
    var sanitaeter2 = ""
    var sanitaeter3 = ""
    var sanitaeter4 = ""
}

// MARK: - ABCDE Befunde

struct AirwayBefund: Codable {
    var status: ABCDEStatus = .unbewertet
    var freiheit: Bool = true
    var verlegung: Bool = false
    var verlegungsUrsache = ""
    var massnahmen: [String] = []
    var oropharyngealtubus: Bool = false
    var nasopharyngealtubus: Bool = false
    var intubiert: Bool = false
    var konikotomie: Bool = false
    var freitext = ""
}

struct BreathingBefund: Codable {
    var status: ABCDEStatus = .unbewertet
    var atemFrequenz: Int? = nil
    var spo2: Int? = nil
    var atemgeraeusche = ""
    var dyspnoe: Bool = false
    var zyanose: Bool = false
    var sauerstoffGabe: Bool = false
    var sauerstoffLiter: Double? = nil
    var beatmung: Bool = false
    var beatmungsform = ""
    var freitext = ""
}

struct CirculationBefund: Codable {
    var status: ABCDEStatus = .unbewertet
    var puls: Int? = nil
    var pulsRhythmus = ""
    var pulslosigkeit: Bool = false
    var blutdruckSystolisch: Int? = nil
    var blutdruckDiastolisch: Int? = nil
    var ekg: Bool = false
    var ekgBefund = ""
    var blutung: Bool = false
    var blutungLokalisation = ""
    var ivZugang: Bool = false
    var ivLokalisation = ""
    var freitext = ""
}

struct DisabilityBefund: Codable {
    var status: ABCDEStatus = .unbewertet
    var gcsAugen: Int = 4
    var gcsVerbal: Int = 5
    var gcsMotor: Int = 6
    var pupillenLinks = ""
    var pupillenRechts = ""
    var pupillenReaktion: Bool = true
    var blutzucker: Double? = nil
    var schmerz: Int = 0
    var freitext = ""

    // BEFAST
    var befastAktiv: Bool = false
    var befastBalance: Bool = false
    var befastEyes: Bool = false
    var befastFace: Bool = false
    var befastArm: Bool = false
    var befastSpeech: Bool = false
    var befastZeitUnbekannt: Bool = false
    var befastSymptombeginn: Date? = nil

    var gcsGesamt: Int { gcsAugen + gcsVerbal + gcsMotor }
}

struct ExposureBefund: Codable {
    var status: ABCDEStatus = .unbewertet
    var temperatur: Double? = nil
    var verletzungen = ""
    var hautfarbe = ""
    var oedeme: Bool = false

    // Trauma
    var trauma: Bool = false
    var traumaMechanismus: String = ""
    var bewusstseinsverlust: Bool = false
    var helmGetragen: Bool = false
    var gurtGetragen: Bool = false
    var sichtbareDeformitaeten: String = ""
    var schmerzLokalisation: String = ""
    var frakturVerdacht: Bool = false
    var blutungExtern: Bool = false
    var rueckenNackenSchmerz: Bool = false
    var bewegungseinschraenkung: Bool = false

    var freitext = ""
}

// MARK: - SAMPLER

struct SAMPLERBefund: Codable {
    var symptome = ""
    var allergien = ""
    var medikamente = ""
    var patientenVorgeschichte = ""
    var letztesMahl = ""
    var ereignis = ""
    var risikofaktoren = ""
}

// MARK: - Diagnose (Sektion 4 des Formulars)

struct VerletzungsMatrix: Codable {
    var schaedelHirn: Verletzungsgrad = .keine
    var gesicht: Verletzungsgrad = .keine
    var hws: Verletzungsgrad = .keine
    var thorax: Verletzungsgrad = .keine
    var abdomen: Verletzungsgrad = .keine
    var bwsLws: Verletzungsgrad = .keine
    var becken: Verletzungsgrad = .keine
    var obereExtrem: Verletzungsgrad = .keine
    var untereExtrem: Verletzungsgrad = .keine
    var weichteile: Verletzungsgrad = .keine
}

struct DiagnoseBefund: Codable {
    // 4.1 Erkrankung – ZNS
    var znsAkutNeuro: Bool = false
    var znsSab: Bool = false
    var znsTransplantat: Bool = false
    var znsEpilepsie: Bool = false
    var znsFieberkrampf: Bool = false

    // Atmung
    var atmungAsthma: Bool = false
    var atmungExazerbiert: Bool = false
    var atmungPneumonie: Bool = false
    var atmungLtb: Bool = false
    var atmungEpiglottitis: Bool = false

    // Herz-Kreislauf
    var herzAcs: Bool = false
    var herzStemi: Bool = false
    var herzVW: Bool = false
    var herzHW: Bool = false
    var herzPmFehlfunktion: Bool = false
    var herzRhythmus: Bool = false
    var herzHypertonerNotfall: Bool = false
    var herzAortenaneurysma: Bool = false
    var herzHypotonie: Bool = false
    var herzDekomp: Bool = false
    var herzSynkope: Bool = false
    var herzThromboseEmbolie: Bool = false
    var herzSchockUnklarGenese: Bool = false
    var herzOrthostatisch: Bool = false
    var herzUnklarerThoraxschmerz: Bool = false

    // Psychiatrie
    var psychAkut: Bool = false
    var psychKrise: Bool = false
    var psychManie: Bool = false
    var psychIntoxikation: Bool = false
    var psychEntzug: Bool = false
    var psychSuizidal: Bool = false

    // Gyn/Geb.-hilfe
    var gynSonstige: Bool = false
    var gynSchwangerschaft35: Bool = false
    var gynGeburt: Bool = false
    var gynEklampsie: Bool = false
    var gynVaginalblutung: Bool = false

    // Infektionen
    var infektHiv: Bool = false
    var infektHighToxSars: Bool = false
    var infektGastro: Bool = false
    var infektAnaphylaxie12: Bool = false
    var infektSids: Bool = false
    var infektIntoxikation: Bool = false
    var infektAkuteLumbalgie: Bool = false
    var infektPalliativ: Bool = false
    var infektBehandlungKompl: Bool = false
    var infektUrologisch: Bool = false

    // Stoffwechsel
    var stoffExsikkose: Bool = false
    var stoffHypoglykämie: Bool = false
    var stoffHyperglykämie: Bool = false
    var stoffUremie: Bool = false
    var stoffDia: Bool = false

    // Abdomen
    var abdoAkutes: Bool = false
    var abdoKoliken: Bool = false
    var abdoGibOben: Bool = false
    var abdoGibUnten: Bool = false
    var abdoGalleNiere: Bool = false

    // 4.2 Verletzungen
    var verletzungsMatrix = VerletzungsMatrix()
    var verletzungsMuster: String = ""   // Einzelverletzung, Mehrfachverletzung, Polytrauma
    var verletzungsArt: String = ""      // oberflächlich, stumpf, Stich, Schuss, penetrierend
    var verletzungNichtBekannt: Bool = false

    // Spezielle Traumen
    var spezVerbrVerbrh: Bool = false
    var spezTauchunfall: Bool = false
    var spezElektrounfall: Bool = false
    var spezPkwLkw: Bool = false
    var spezMotorrad: Bool = false
    var spezFahrrad: Bool = false
    var spezFussgaenger: Bool = false
    var spezSturzHoehe: Bool = false
    var spezAndVerkehr: Bool = false
    var spezMaschine: Bool = false
    var spezGewalt: Bool = false
    var spezAndererUnfall: Bool = false

    // Diagnose/Leitsymptom + Verlauf (Sektion 5)
    var leitsymptom: String = ""
    var diagnoseFreitext: String = ""
    var verlauf: String = ""

    // Trichter-System
    var verdachtsdiagnosen: [VerdachtsdiagnoseEintrag] = []
}

// MARK: - Medikamente (Sektion 6.5)

struct MedikamentEintrag: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var dosis: String = ""
    var einheit: String = "mg"
    var route: String = ""
    var zeit: Date = Date()
}

// MARK: - Maßnahmen (Sektion 6)

struct MassnahmenBefund: Codable {
    // Airway / Stabilisation
    var atemwegFreimachen: Bool = false
    var cervikalStuetze: Bool = false
    var absaugung: Bool = false
    var sauerstoffgabe: Bool = false
    var sauerstoffLitMin: String = ""
    var maskenbeatmung: Bool = false
    var maskenbeatmungUnmoeglich: Bool = false
    var supraglottisch: Bool = false
    var supraglottischTyp: String = ""
    var supraglottischGr: String = ""
    var atemwegErschwert: Bool = false
    var airwaySonstige: String = ""

    // Kreislauf / Zugänge
    var peripherVenoes: Bool = false
    var peripherVenoesOrt: String = ""
    var peripherVenoesGroesse: String = ""
    var peripherVenoesAnz: Int = 1
    var circSonstige: String = ""

    // Weitere Maßnahmen
    var kuehlung: Bool = false
    var waermeerhalt: Bool = false
    var entbindung: Bool = false
    var krisenintervention: Bool = false
    var tourniquet: Bool = false
    var tourniquetZeit: Date? = nil
    var weitereSonstige: String = ""

    // Lagerung / Transport
    var okHochlagerung: Bool = false
    var flachlagerung: Bool = false
    var schocklagerung: Bool = false
    var herzTieflage: Bool = false
    var linksseitenlage: Bool = false
    var sitzenderTransport: Bool = false
    var vakuummatratze: Bool = false
    var schaufeltrage: Bool = false
    var extremitaetenschienung: Bool = false
    var verband: Bool = false
    var beckenschlinge: Bool = false
    var lagerungSonstige: String = ""

    // Airway-Erweiterungen
    var cpap: Bool = false
    var cpapMbar: String = ""
    var heimlich: Bool = false

    // Kreislauf-Erweiterungen
    var defibrillation: Bool = false
    var defiJoule: Int = 200
    var defiAnzahl: Int = 1
    var kardioversion: Bool = false
    var kardioversionJoule: Int = 100
    var intraossaer: Bool = false
    var intraossaerOrt: String = ""

    // Monitoring
    var monEkg: Bool = false
    var monNibp: Bool = false
    var monBz: Bool = false
    var monSpo2: Bool = false
    var monTemperatur: Bool = false
}

// MARK: - Ergebnis / Transportziel (Sektion 8 + 9)

struct ErgebnisData: Codable {
    var nacaScore: NacaScore = .naca3
    var transportZiel: TransportZiel = .anderesRettungsmittel

    // Einsatzbesonderheiten
    var ambulantVorOrt: Bool = false
    var naechstesKHNichtErreichbar: Bool = false
    var patNichtTransportfaehig: Bool = false
    var todAnEinsatzstelle: Bool = false
    var zwangsunterbringung: Bool = false
    var lnaGrleimEinsatz: Bool = false
    var mehrerePatient: Bool = false
    var aufwaendigeRettung: Bool = false
    var infektionsSchutz: Bool = false
    var schwerlasttransport: Bool = false

    var mifahrverweigerung: Bool = false
    var voranmeldung: Bool = false
    var gelbAlarm: Bool = false
    var rotAlarm: Bool = false

    var anmerkungen: String = ""

    // Transportziel Klinik
    var transportzielZna: Bool = false
    var transportzielStrokeUnit: Bool = false
    var transportzielKathLabor: Bool = false
    var transportzielSonstigesKH: String = ""
}

// MARK: - Notfallgeschehen

struct NotfallgeschehenBefund: Codable {
    var erstbefundVorOrt = ""
    var patientGefunden = ""
    var ersthelferMassnahmen = ""
    var anzahlBeteiligte: Int = 1
    var manv: Bool = false
    var ersteEintreffendeKraft: Bool = false
    var manvSK1: Int = 0        // SK I  — Rot   — sofortige Behandlung
    var manvSK2: Int = 0        // SK II — Gelb  — aufgeschobene Behandlung
    var manvSK3: Int = 0        // SK III— Grün  — leicht verletzt
    var manvSK4: Int = 0        // SK IV — Blau  — ohne realistische Überlebenschance
    var manvVerstorben: Int = 0 // T    — Schwarz— verstorben
    var manvLagemeldung: String = ""
    var manvNachforderung: String = ""

    // Neue Felder
    var unfallhergangAuswahl: [String] = []
    var unfallhergangFreitext: String = ""
    var unfallmechanismus: String = ""
    var unfallmechanismusFreitext: String = ""
    var preEmergencyStatus: String = ""
    var nacaScoreWert: NacaScore? = nil
    var erstbefundAuswahl: [String] = []
    var verlaufsbemerkungen: String = ""
    var dynamischeErweiterung: String = ""

    var manvGesamtSK: Int { manvSK1 + manvSK2 + manvSK3 + manvSK4 + manvVerstorben }
}

// MARK: - Verdachtsdiagnose (Trichter)

enum DiagnoseWahrscheinlichkeit: String, CaseIterable, Codable {
    case fuehrend       = "Führende Diagnose"
    case wahrscheinlich = "Wahrscheinlich"
    case moeglich       = "Möglich"
    case unwahrscheinlich = "Unwahrscheinlich"

    var farbe: Color {
        switch self {
        case .fuehrend:       return .red
        case .wahrscheinlich: return .orange
        case .moeglich:       return .yellow
        case .unwahrscheinlich: return .gray
        }
    }

    var symbol: String {
        switch self {
        case .fuehrend:       return "star.fill"
        case .wahrscheinlich: return "circle.fill"
        case .moeglich:       return "circle"
        case .unwahrscheinlich: return "minus.circle"
        }
    }
}

struct VerdachtsdiagnoseEintrag: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var wahrscheinlichkeit: DiagnoseWahrscheinlichkeit = .moeglich
    var begruendung: String = ""
}

// MARK: - Verlaufsmessung

struct VerlaufsMessung: Codable, Identifiable {
    var id = UUID()
    var zeitpunkt: Date = Date()
    var atemFrequenz: Int? = nil
    var spo2: Int? = nil
    var puls: Int? = nil
    var blutdruckSys: Int? = nil
    var blutdruckDia: Int? = nil
    var gcsGesamt: Int? = nil
    var blutzucker: Double? = nil
    var temperatur: Double? = nil
    var massnahmen: String = ""
    var freitext: String = ""
    var autoImportiert: Bool = false  // aus ABCDE automatisch übernommen
}

// MARK: - Foto

struct FotoEintrag: Identifiable {
    let id = UUID()
    var bildDateiname: String
    var zeitpunkt: Date = Date()
    var bezeichnung: String = ""

    var bildURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(bildDateiname)
    }

    func loeschen() {
        try? FileManager.default.removeItem(at: bildURL)
    }
}

// MARK: - SINNHAFT

struct SINNHAFTBefund: Codable {
    var situation = ""          // S – Schilderung der Einsatzsituation
    var identifikation = ""     // I – Identifikation (Team, Fahrzeug)
    var notfall = ""            // N – Notfallgeschehen (Was ist passiert?)
    var notwendigeMassnahmen = "" // N – Durchgeführte Maßnahmen
    var hintergrund = ""        // H – Hintergrundinformationen / Anamnese
    var aktuellerZustand = ""   // A – Aktueller Patientenzustand
    var forderung = ""          // F – Forderungen / Folgeempfehlung
    var transport = ""          // T – Transport (Ziel, Modus)
}

// MARK: - Protokoll Archiv Snapshot (Codable, ohne Fotos)

struct ProtokollDaten: Codable, Identifiable {
    var id: UUID
    var erstelltAm: Date
    var einsatzOrt: EinsatzOrt
    var patientDaten: PatientDaten
    var besatzung: Besatzung
    var notfallGeschehen: NotfallgeschehenBefund
    var kritisch: Bool
    var airway: AirwayBefund
    var breathing: BreathingBefund
    var circulation: CirculationBefund
    var disability: DisabilityBefund
    var exposure: ExposureBefund
    var sampler: SAMPLERBefund
    var sinnhaft: SINNHAFTBefund
    var diagnose: DiagnoseBefund
    var verlaufMessungen: [VerlaufsMessung]
    var massnahmen: MassnahmenBefund
    var medikamente: [MedikamentEintrag]
    var reanimationAktiv: Bool
    var reanimation: ReanimationsProtokoll
    var ergebnis: ErgebnisData
    var uebergabeAn: String
    var zustandBeiUebergabe: String
    var verfasser: ProtokollVerfasser?
}

extension EinsatzProtokoll {
    func toDaten() -> ProtokollDaten {
        ProtokollDaten(
            id: id, erstelltAm: erstelltAm,
            einsatzOrt: einsatzOrt, patientDaten: patientDaten, besatzung: besatzung,
            notfallGeschehen: notfallGeschehen, kritisch: kritisch,
            airway: airway, breathing: breathing, circulation: circulation,
            disability: disability, exposure: exposure,
            sampler: sampler, sinnhaft: sinnhaft, diagnose: diagnose,
            verlaufMessungen: verlaufMessungen, massnahmen: massnahmen,
            medikamente: medikamente, reanimationAktiv: reanimationAktiv,
            reanimation: reanimation, ergebnis: ergebnis,
            uebergabeAn: uebergabeAn,
            zustandBeiUebergabe: zustandBeiUebergabe,
            verfasser: verfasser
        )
    }

    func apply(from d: ProtokollDaten) {
        einsatzOrt = d.einsatzOrt; patientDaten = d.patientDaten; besatzung = d.besatzung
        notfallGeschehen = d.notfallGeschehen; kritisch = d.kritisch
        airway = d.airway; breathing = d.breathing; circulation = d.circulation
        disability = d.disability; exposure = d.exposure
        sampler = d.sampler; sinnhaft = d.sinnhaft; diagnose = d.diagnose
        verlaufMessungen = d.verlaufMessungen; massnahmen = d.massnahmen
        medikamente = d.medikamente; reanimationAktiv = d.reanimationAktiv
        reanimation = d.reanimation; ergebnis = d.ergebnis
        uebergabeAn = d.uebergabeAn
        zustandBeiUebergabe = d.zustandBeiUebergabe
        verfasser = d.verfasser ?? .notfallsanitaeter
        erstelltAm = d.erstelltAm
    }
}

// MARK: - SINNHAFT AutoFill

extension SINNHAFTBefund {
    static func autoFilled(from protokoll: EinsatzProtokoll) -> SINNHAFTBefund {
        var befund = SINNHAFTBefund()

        var situationParts: [String] = []
        if !protokoll.einsatzOrt.einsatzNummer.isEmpty { situationParts.append("Einsatz-Nr.: \(protokoll.einsatzOrt.einsatzNummer)") }
        if !protokoll.einsatzOrt.stichwort.isEmpty { situationParts.append("Einsatzart: \(protokoll.einsatzOrt.stichwort)") }
        if !protokoll.einsatzOrt.einsatzArt.isEmpty { situationParts.append("Stichwort: \(protokoll.einsatzOrt.einsatzArt)") }
        if !protokoll.einsatzOrt.adresse.isEmpty { situationParts.append("Ort: \(protokoll.einsatzOrt.adresse)") }
        befund.situation = situationParts.joined(separator: "\n")

        let pat = protokoll.patientDaten
        var patParts: [String] = []
        let name = "\(pat.vorname) \(pat.nachname)".trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { patParts.append(name) }
        if let alter = pat.alter { patParts.append("\(alter) J.") }
        if pat.geschlecht != .unbekannt { patParts.append(pat.geschlecht.rawValue) }
        befund.identifikation = patParts.joined(separator: ", ")

        var notfallParts: [String] = []
        if !protokoll.notfallGeschehen.erstbefundVorOrt.isEmpty { notfallParts.append(protokoll.notfallGeschehen.erstbefundVorOrt) }
        if !protokoll.notfallGeschehen.patientGefunden.isEmpty { notfallParts.append("Pat. vorgefunden: \(protokoll.notfallGeschehen.patientGefunden)") }
        if !protokoll.sampler.ereignis.isEmpty { notfallParts.append(protokoll.sampler.ereignis) }
        befund.notfall = notfallParts.joined(separator: "\n")

        let m = protokoll.massnahmen
        var massnahmenList: [String] = []

        // Ersthelfer & Reanimation
        if !protokoll.notfallGeschehen.ersthelferMassnahmen.isEmpty { massnahmenList.append("Ersthelfer: \(protokoll.notfallGeschehen.ersthelferMassnahmen)") }
        if protokoll.reanimationAktiv {
            let rea = protokoll.reanimation
            var reaTeile: [String] = ["Reanimation"]
            reaTeile.append("Init. Rhythmus: \(rea.initialRhythmus.rawValue)")
            if rea.defiAnzahl > 0 { reaTeile.append("\(rea.defiAnzahl)× Defibrillation") }
            reaTeile.append("Outcome: \(rea.outcome.rawValue)")
            massnahmenList.append(reaTeile.joined(separator: ", "))
        }

        // Atemweg
        if m.atemwegFreimachen  { massnahmenList.append("Atemweg freimachen") }
        if m.atemwegFreimachen  { massnahmenList.append("Atemweg freimachen") }
        if m.absaugung          { massnahmenList.append("Absaugung") }
        if m.cervikalStuetze    { massnahmenList.append("Cervikalstütze") }
        if m.sauerstoffgabe     { massnahmenList.append("O₂-Gabe\(m.sauerstoffLitMin.isEmpty ? "" : " \(m.sauerstoffLitMin) l/min")") }
        if m.maskenbeatmung     { massnahmenList.append("Maskenbeatmung") }
        if m.supraglottisch     { massnahmenList.append("Supraglottischer Atemweg\(m.supraglottischTyp.isEmpty ? "" : " (\(m.supraglottischTyp))")") }
        if protokoll.airway.konikotomie { massnahmenList.append("Konikotomie") }
        if m.atemwegErschwert   { massnahmenList.append("Erschwerter Atemweg") }
        if m.peripherVenoes     { massnahmenList.append("Peripher-venöser Zugang\(m.peripherVenoesOrt.isEmpty ? "" : " (\(m.peripherVenoesOrt))")") }
        if m.tourniquet         { massnahmenList.append("Tourniquet") }
        if m.krisenintervention { massnahmenList.append("Krisenintervention") }
        if m.vakuummatratze     { massnahmenList.append("Vakuummatratze") }
        if m.beckenschlinge     { massnahmenList.append("Beckenschlinge") }
        if m.extremitaetenschienung { massnahmenList.append("Extremitätenschienung") }
        if m.verband            { massnahmenList.append("Verband") }
        befund.notwendigeMassnahmen = massnahmenList.joined(separator: "\n")

        var hintParts: [String] = []
        if !protokoll.sampler.patientenVorgeschichte.isEmpty { hintParts.append("Vorgeschichte: \(protokoll.sampler.patientenVorgeschichte)") }
        if !protokoll.sampler.allergien.isEmpty { hintParts.append("Allergien: \(protokoll.sampler.allergien)") }
        if !protokoll.sampler.medikamente.isEmpty { hintParts.append("Medikation: \(protokoll.sampler.medikamente)") }
        if !protokoll.sampler.risikofaktoren.isEmpty { hintParts.append("Risikofaktoren: \(protokoll.sampler.risikofaktoren)") }
        if !protokoll.sampler.letztesMahl.isEmpty { hintParts.append("Letzte Mahlzeit: \(protokoll.sampler.letztesMahl)") }
        befund.hintergrund = hintParts.joined(separator: "\n")

        var zustandParts: [String] = []
        // ABCDE-Statusübersicht für strukturierte Übergabe
        let abcdeStatus: [(String, ABCDEStatus)] = [
            ("A", protokoll.airway.status), ("B", protokoll.breathing.status),
            ("C", protokoll.circulation.status), ("D", protokoll.disability.status),
            ("E", protokoll.exposure.status)
        ]
        let abcdeText = abcdeStatus
            .filter { $0.1 != .unbewertet }
            .map { "\($0.0) \($0.1 == .nicht_kritisch ? "o.B." : "kritisch")" }
            .joined(separator: " · ")
        if !abcdeText.isEmpty { zustandParts.append("ABCDE: \(abcdeText)") }
        if let af = protokoll.breathing.atemFrequenz { zustandParts.append("AF: \(af)/min") }
        if let spo2 = protokoll.breathing.spo2 { zustandParts.append("SpO₂: \(spo2)%") }
        if let puls = protokoll.circulation.puls { zustandParts.append("Puls: \(puls)/min") }
        if let sys = protokoll.circulation.blutdruckSystolisch,
           let dia = protokoll.circulation.blutdruckDiastolisch { zustandParts.append("RR: \(sys)/\(dia) mmHg") }
        if protokoll.disability.status != .unbewertet { zustandParts.append("GCS: \(protokoll.disability.gcsGesamt)") }
        if let bz = protokoll.disability.blutzucker { zustandParts.append("BZ: \(String(format: "%.1f", bz)) mmol/L") }
        if let temp = protokoll.exposure.temperatur { zustandParts.append("Temp: \(String(format: "%.1f", temp))°C") }
        if let letzte = protokoll.verlaufMessungen.sorted(by: { $0.zeitpunkt < $1.zeitpunkt }).last {
            let f = DateFormatter(); f.dateFormat = "HH:mm"
            var verlaufTeile: [String] = []
            if let af = letzte.atemFrequenz { verlaufTeile.append("AF \(af)") }
            if let spo2 = letzte.spo2 { verlaufTeile.append("SpO₂ \(spo2)%") }
            if let p = letzte.puls { verlaufTeile.append("Puls \(p)") }
            if !verlaufTeile.isEmpty { zustandParts.append("Verlauf \(f.string(from: letzte.zeitpunkt)): \(verlaufTeile.joined(separator: ", "))") }
        }
        befund.aktuellerZustand = zustandParts.joined(separator: "\n")

        var forderungParts: [String] = []
        if let fuehrend = protokoll.diagnose.verdachtsdiagnosen.first(where: { $0.wahrscheinlichkeit == .fuehrend }) {
            forderungParts.append("V.a. \(fuehrend.name)")
        } else if !protokoll.diagnose.leitsymptom.isEmpty {
            forderungParts.append("V.a. \(protokoll.diagnose.leitsymptom)")
        }
        let wahrscheinlich = protokoll.diagnose.verdachtsdiagnosen.filter { $0.wahrscheinlichkeit == .wahrscheinlich }
        if !wahrscheinlich.isEmpty { forderungParts.append("DD: \(wahrscheinlich.map(\.name).joined(separator: ", "))") }
        befund.forderung = forderungParts.joined(separator: "\n")

        var transportParts: [String] = ["Anderes Rettungsmittel"]
        if !protokoll.uebergabeAn.isEmpty { transportParts.append(protokoll.uebergabeAn) }
        befund.transport = transportParts.joined(separator: ": ")

        return befund
    }
}

// MARK: - Reanimation

struct ReanimationsProtokoll: Codable {
    var kollapsZeit: Date? = nil
    var kollapsZeitUnbekannt: Bool = false

    var erstHelfer: Bool = false
    var vorabTelefonRea: Bool = false
    var startErsthelferCPR: Date? = nil
    var startErsthelferUnbekannt: Bool = false
    var aed: Bool = false

    var startRettungsdienst: Date? = nil
    var startRDUnbekannt: Bool = false
    var endeRettungsdienst: Date? = nil

    var initialRhythmus: InitialRhythmus = .unbekannt

    var defiAnzahl: Int = 0
    var defiJoule: Int = 0

    var outcome: ReaniOutcome = .transportiert
    var roscZeit: Date? = nil
    var roscImVerlauf: Bool = false
    var nieROSC: Bool = false
    var erfolgreicheRea: Bool = false
    var todFeststellungsZeit: Date? = nil
    var dnrOrder: Bool = false

    var khAufnahmeVorROSC: Bool = false
    var laufendeReanimation: Bool = false

    var freitext = ""
}
