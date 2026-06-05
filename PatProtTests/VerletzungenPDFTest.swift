import Foundation
import Testing
@testable import PatProt

// Testet das neue 4.2-Verletzungen-Layout im PDFGenerator
struct VerletzungenPDFTest {

    @Test func renderVerletzungenPDF() throws {
        let p = EinsatzProtokoll()

        // ── Patient & Einsatz ──
        p.patientDaten.nachname = "Testmann"
        p.patientDaten.vorname  = "Unfall"
        p.patientDaten.geburtsDatum = Calendar.current.date(
            from: DateComponents(year: 1975, month: 6, day: 20))
        p.patientDaten.geschlecht = .maennlich
        p.verfasser = .notfallsanitaeter
        let now = Date()
        p.einsatzOrt.adresse    = "Industriestraße 7"
        p.einsatzOrt.plz        = "21502"
        p.einsatzOrt.ort        = "Geesthacht"
        p.einsatzOrt.einsatzArt = "NOTF"
        p.einsatzOrt.stichwort  = "Arbeitsunfall"
        p.einsatzOrt.alarmzeit  = now
        p.einsatzOrt.ankunftzeit = now.addingTimeInterval(300)
        p.einsatzOrt.uebergabeZeit = now.addingTimeInterval(1800)
        p.einsatzOrt.endeZeit = now.addingTimeInterval(2100)

        // ── Besatzung ──
        p.besatzung.sanitaeter1 = "Schulz, L."
        p.besatzung.qualifikation1 = .notfallsanitaeter
        p.besatzung.sanitaeter2 = "Meyer, T."
        p.besatzung.qualifikation2 = .rettungssanitaeter

        // ── 4.2 Verletzungen – alle neuen Felder ──
        p.diagnose.verletzungsMatrix.schaedelHirn = .leicht
        p.diagnose.verletzungsMatrix.thorax       = .schwer
        p.diagnose.verletzungsMatrix.obereExtrem  = .leicht

        // Verletzungsmuster
        p.diagnose.verletzungPolytrauma = true

        // Unfallmechanismus
        p.diagnose.unfallmechStumpf = true

        // Spezielle Traumen
        p.diagnose.spezInhalationstrauma = true
        p.diagnose.spezVeraetzung        = false
        p.diagnose.spezElektrounfall     = false
        p.diagnose.spezVerbrVerbrh       = false

        // Unfallart – alle neuen Felder
        p.diagnose.spezSturzKlein  = true   // NEU: Sturz < 3m
        p.diagnose.spezSchlag      = false
        p.diagnose.spezSchuss      = false
        p.diagnose.spezStich       = false
        p.diagnose.spezVerschuettung = false
        p.diagnose.spezMaschine    = true   // Maschinenunfall
        p.diagnose.spezGewalt      = false

        // ── Diagnose ──
        p.diagnose.leitsymptom = "Polytrauma nach Arbeitsunfall"
        p.diagnose.diagnoseFreitext = "SHT leicht, Thoraxtrauma mit Rippenfrakturen, Unterarmfraktur li."

        // ── ABCDE (kurz) ──
        p.airway.status  = .nicht_kritisch
        p.breathing.status = .kritisch
        p.breathing.atemFrequenz = 22
        p.breathing.spo2 = 91
        p.circulation.status = .kritisch
        p.circulation.blutdruckSystolisch = 95
        p.circulation.blutdruckDiastolisch = 60
        p.circulation.puls = 112
        p.disability.status = .kritisch
        p.disability.gcsAugen  = 3
        p.disability.gcsVerbal = 4
        p.disability.gcsMotor  = 5
        p.disability.bewusstlos = true
        p.exposure.status = .nicht_kritisch

        // ── Maßnahmen ──
        p.massnahmen.sauerstoffgabe  = true
        p.massnahmen.sauerstoffLitMin = "10"
        p.massnahmen.peripherVenoes  = true
        p.massnahmen.peripherVenoesOrt = "re. Ellenbeuge"

        // ── Abschluss ──
        p.ergebnis.transportzielZna  = true
        p.ergebnis.frEinsatz         = true
        p.uebergabeAn = "RTW 10/83-2"
        p.zustandBeiUebergabe = "GCS 12, SpO2 94% unter O2, RR 110/70"

        // ── PDF generieren ──
        let url = try #require(PDFGenerator.generate(protokoll: p),
                               "PDFGenerator returned nil")

        // In erreichbares Verzeichnis kopieren
        // /tmp ist im Simulator erreichbar
        let out = URL(fileURLWithPath: "/tmp/VERLETZUNGEN_TEST.pdf")
        try? FileManager.default.removeItem(at: out)
        try  FileManager.default.copyItem(at: url, to: out)
        print("VERLETZUNGEN_PDF>>>\(out.path)<<<")
        #expect(FileManager.default.fileExists(atPath: out.path))
    }
}
