//
//  RKNPDFRenderTest.swift
//  PatProtTests
//
//  Render-Harness für visuelle Layout-Prüfung des RKN-Formulars.
//

import Foundation
import Testing
@testable import PatProt

struct RKNPDFRenderTest {

    @Test func renderSamplePDF() throws {
        let p = EinsatzProtokoll()

        // ── Kopfzeile / Patient ──
        p.patientDaten.kostentraeger = "AOK Rheinland/Hamburg"
        p.patientDaten.nachname = "Mustermann"
        p.patientDaten.vorname  = "Max"
        p.patientDaten.geburtsDatum = Calendar.current.date(from: DateComponents(year: 1958, month: 4, day: 12))
        p.patientDaten.versicherungsNummer = "A123456789"
        p.patientDaten.geschlecht = .maennlich
        p.verfasser = .notfallsanitaeter

        // ── Section 1: Rettungstechnische Daten ──
        p.einsatzOrt.fahrzeugName = "RTW Neuss 01"
        p.einsatzOrt.einsatzNummer = "2026-0612"
        p.einsatzOrt.sondersignal = true
        p.einsatzOrt.mitPatient = true
        p.einsatzOrt.notarzt = false
        let now = Date()
        p.einsatzOrt.alarmzeit = now
        p.einsatzOrt.ausfahrtzeit = now.addingTimeInterval(120)
        p.einsatzOrt.ankunftzeit = now.addingTimeInterval(420)
        p.einsatzOrt.abfahrtzeit = now.addingTimeInterval(1500)
        p.einsatzOrt.uebergabeZeit = now.addingTimeInterval(2400)
        p.einsatzOrt.einsatzbereitZeit = now.addingTimeInterval(3000)
        p.einsatzOrt.endeZeit = now.addingTimeInterval(3300)
        p.einsatzOrt.krankenHausAnkunft = now.addingTimeInterval(2400)
        p.einsatzOrt.kmGesamt = "12"
        p.einsatzOrt.kmPatient = "8"
        p.einsatzOrt.adresse = "Hauptstraße 12"
        p.einsatzOrt.zusatz = "12"
        p.einsatzOrt.plz = "41460"
        p.einsatzOrt.ort = "Neuss"

        // ── Besatzung ──
        p.besatzung.sanitaeter1 = "Schulz"
        p.besatzung.qualifikation1 = .notfallsanitaeter
        p.besatzung.sanitaeter2 = "Meyer"
        p.besatzung.qualifikation2 = .rettungssanitaeter

        // ── Section 2: SAMPLER ──
        p.notfallGeschehen.erstbefundVorOrt = "Pat. sitzend, Thoraxschmerz seit 30 Min"
        p.sampler.allergien = "Penicillin"
        p.sampler.medikamente = "ASS 100, Ramipril 5mg"
        p.sampler.patientenVorgeschichte = "KHK, Z.n. Stent 2021"
        p.sampler.letztesMahl = "12:30 Uhr leichte Mahlzeit"
        p.sampler.ereignis = "Akut einsetzender Druck retrosternal"
        p.sampler.risikofaktoren = "Raucher, Hypertonie, Diabetes"

        // ── ABCDE-Status + Freitext (für Section-2-Text) ──
        p.airway.status = .nicht_kritisch
        p.airway.freiheit = true
        p.breathing.status = .kritisch
        p.breathing.freitext = "Tachypnoe"
        p.circulation.status = .kritisch
        p.disability.status = .nicht_kritisch
        p.exposure.status = .nicht_kritisch
        p.exposure.hautfarbe = "blass"
        // BEFAST + ZOP
        p.disability.befastAktiv = true
        p.disability.befastFace = true
        p.disability.befastArm = true
        p.disability.zopAktiv = true
        p.disability.zopZeit = "Orientiert"
        p.disability.zopOrt = "Orientiert"
        p.disability.zopPerson = "Desorientiert"

        // ── Reanimation ──
        p.reanimationAktiv = false
        p.reanimation.initialRhythmus = .unbekannt
        p.reanimation.outcome = .transportiert

        // ── Section 3: Ankunfts-Befunde (linke Spalte) ──
        p.circulation.blutdruckSystolisch = 150
        p.circulation.blutdruckDiastolisch = 95
        p.circulation.puls = 96
        p.circulation.sinusrhythmus = true
        p.breathing.spo2 = 94
        p.breathing.atemFrequenz = 20
        p.breathing.dyspnoe = true
        p.disability.blutzucker = 118
        p.disability.bewWach = true
        p.disability.gcsAugen = 4
        p.disability.gcsVerbal = 5
        p.disability.gcsMotor = 6
        p.disability.schmerz = 8
        p.exposure.temperatur = 36.5
        p.psyche.aengstlich = true

        // ── Section 3: Übergabe-Befunde ──
        p.uebergabeMesswerte.rrSys = "145"
        p.uebergabeMesswerte.rrDia = "90"
        p.uebergabeMesswerte.hf = "92"
        p.uebergabeMesswerte.spo2 = "96"
        p.uebergabeMesswerte.af = "18"
        p.uebergabeMesswerte.bz = "120"
        p.uebergabeMesswerte.temp = "36.7"
        p.uebergabeBefunde.schmerz = 7
        p.uebergabeBefunde.gcsAugen = 4
        p.uebergabeBefunde.gcsVerbal = 5
        p.uebergabeBefunde.gcsMotor = 6
        p.uebergabeBefunde.dyspnoe = true
        p.uebergabeBefunde.sinusrhythmus = true
        p.uebergabeBefunde.bewWach = true
        p.uebergabeBefunde.pupilleReMittel = true
        p.uebergabeBefunde.pupilleLiMittel = true

        // ── Section 4: Diagnose ──
        p.diagnose.herzAcs = true
        p.diagnose.leitsymptom = "ACS / instabile Angina pectoris"

        // ── Section 4.2: Verletzungen ──
        p.diagnose.verletzungsMatrix.thorax = .leicht

        // ── Section 5: Verlauf ──
        p.diagnose.verlauf = "10:35 Eintreffen, Pat. wach. 10:40 O2-Gabe + ASS. 10:50 Transport unter Monitoring."

        // ── Verlaufsgrafik ──
        for i in 0..<5 {
            var m = VerlaufsMessung()
            m.zeitpunkt = now.addingTimeInterval(Double(i) * 300)
            m.puls = 88 + i * 2
            m.blutdruckSys = 145 - i * 3
            m.blutdruckDia = 90 - i
            m.spo2 = 95 + i % 3
            p.verlaufMessungen.append(m)
        }

        // ── Section 6: Maßnahmen ──
        p.massnahmen.sauerstoffgabe = true
        p.massnahmen.sauerstoffLitMin = "6"
        p.massnahmen.peripherVenoes = true
        p.massnahmen.peripherVenoesOrt = "li. Hand"
        p.massnahmen.peripherVenoesGroesse = "18"
        p.massnahmen.monEkg = true
        p.massnahmen.monNibp = true
        p.massnahmen.monSpo2 = true

        // ── Section 6.5: Medikamente ──
        var med1 = MedikamentEintrag()
        med1.name = "ASS"; med1.dosis = "250"; med1.einheit = "mg"; med1.route = "i.v."; med1.zeit = now
        p.medikamente.append(med1)
        var med2 = MedikamentEintrag()
        med2.name = "Heparin"; med2.dosis = "5000"; med2.einheit = "IE"; med2.route = "i.v."; med2.zeit = now.addingTimeInterval(120)
        p.medikamente.append(med2)

        // ── Section 8/9 ──
        p.ergebnis.transportzielKathLabor = true
        p.ergebnis.voranmeldung = true
        p.ergebnis.anmerkungen = "Voranmeldung HKL erfolgt"

        // ── NACA ──
        p.notfallGeschehen.nacaScoreWert = NacaScore(rawValue: 4)

        // ── Übergabe ──
        p.uebergabeAn = "Dr. Schmidt, ZNA"

        // Generieren
        let url = try #require(PDFGenerator.generate(protokoll: p))

        // In ein persistentes, host-zugängliches Verzeichnis kopieren (Documents)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let out = docs.appendingPathComponent("RKN_RENDER_TEST.pdf")
        try? FileManager.default.removeItem(at: out)
        try FileManager.default.copyItem(at: url, to: out)

        print("RKN_PDF_PATH_MARKER>>>\(out.path)<<<RKN_PDF_PATH_MARKER")
        #expect(FileManager.default.fileExists(atPath: out.path))
    }
}
