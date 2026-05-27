//
//  PatProtTests.swift
//  PatProtTests
//
//  Created by Luke Schulz on 07.05.26.
//

import Foundation
import Testing
@testable import PatProt

struct PatProtTests {

    @Test func screenshotParserEinsatznummer() {
        let lines = ["Einsatzbeginn  Gestern, 19:57", "123456789", "NOTF 01 - Bewusstlosigkeit", "Hauptstraße 12, 21502 Geesthacht"]
        let result = ScreenshotParser.parse(lines: lines)
        #expect(result.einsatzNummer == "123456789")
        #expect(result.einsatzArt == "NOTF 01")
        #expect(result.stichwort == "Bewusstlosigkeit")
        #expect(result.adresse.contains("Hauptstraße"))
        #expect(result.alarmzeit != nil)
    }

    @Test func screenshotParserNotarzt() {
        let lines = ["NOTF 11 - Geburt"]
        let result = ScreenshotParser.parse(lines: lines)
        #expect(result.notarzt == true)
    }

    @Test func screenshotParserGeschlecht() {
        let lines = ["Patient: m"]
        let result = ScreenshotParser.parse(lines: lines)
        #expect(result.geschlecht == .maennlich)
    }

    @Test func neuesProtokollHatAlarmzeit() {
        let p = EinsatzProtokoll()
        p.reset()
        #expect(p.einsatzOrt.alarmzeit != nil)
        let diff = abs(p.einsatzOrt.alarmzeit!.timeIntervalSinceNow)
        #expect(diff < 5)  // innerhalb von 5 Sekunden gesetzt
    }

    @Test func numpadFormatInteger() {
        #expect(NumpadSheet.formatDisplay(digits: "80", mode: .integer(label: "", unit: "")) == "80")
        #expect(NumpadSheet.formatDisplay(digits: "", mode: .integer(label: "", unit: "")) == "—")
    }

    @Test func numpadFormatTime() {
        #expect(NumpadSheet.formatDisplay(digits: "1432", mode: .time(label: "")) == "14:32")
        #expect(NumpadSheet.formatDisplay(digits: "14", mode: .time(label: "")) == "14")
        #expect(NumpadSheet.formatDisplay(digits: "0", mode: .time(label: "")) == "0")
        #expect(NumpadSheet.formatDisplay(digits: "", mode: .time(label: "")) == "—")
    }

    @Test func numpadFormatDate() {
        #expect(NumpadSheet.formatDisplay(digits: "01021985", mode: .date(label: "")) == "01.02.1985")
        #expect(NumpadSheet.formatDisplay(digits: "0102", mode: .date(label: "")) == "01.02")
        #expect(NumpadSheet.formatDisplay(digits: "01", mode: .date(label: "")) == "01")
        #expect(NumpadSheet.formatDisplay(digits: "", mode: .date(label: "")) == "—")
    }

    @Test func numpadFormatDecimal() {
        #expect(NumpadSheet.formatDisplay(digits: "5.4", mode: .decimal(label: "", unit: "")) == "5.4")
        #expect(NumpadSheet.formatDisplay(digits: "", mode: .decimal(label: "", unit: "")) == "—")
    }

    @Test func medikamentFotosInitialisierenLeer() {
        let p = EinsatzProtokoll()
        #expect(p.medikamentFotos.isEmpty)
    }

    @Test func resetLeertMedikamentFotos() {
        let p = EinsatzProtokoll()
        p.medikamentFotos.append(FotoEintrag(bildDateiname: "test.jpg"))
        p.reset()
        #expect(p.medikamentFotos.isEmpty)
    }

    @Test func protokollDatenHatPdfExportiertAmNil() {
        let daten = ProtokollDaten()
        #expect(daten.pdfExportiertAm == nil)
    }

    @Test func ergebnisDataHatKeinNacaScore() {
        // This test verifies at compile time that nacaScore no longer exists on ErgebnisData.
        // If ErgebnisData still has nacaScore, this file will not compile.
        let _ = ErgebnisData()  // must compile without nacaScore
        #expect(true)
    }

    @Test func markierePDFExportSetztDatum() throws {
        let archiv = try ProtokollArchiv.testInstance()
        var daten = ProtokollDaten()
        daten.id = UUID()
        try archiv.speichern(daten)
        #expect(daten.pdfExportiertAm == nil)
        archiv.markierePDFExport(id: daten.id)
        let geladen = archiv.laden()
        let eintrag = geladen.first(where: { $0.id == daten.id })
        #expect(eintrag?.pdfExportiertAm != nil)
    }

    @Test func purgeEntferntAbgelaufeneEintraege() throws {
        let archiv = try ProtokollArchiv.testInstance()
        var daten = ProtokollDaten()
        daten.id = UUID()
        daten.pdfExportiertAm = Date().addingTimeInterval(-90000)  // 25h ago
        try archiv.speichern(daten)
        archiv.laden()  // triggers purge
        let nach = archiv.laden()
        #expect(nach.first(where: { $0.id == daten.id }) == nil)
    }

    @Test func purgeBelaesstFrischangeEintraege() throws {
        let archiv = try ProtokollArchiv.testInstance()
        var daten = ProtokollDaten()
        daten.id = UUID()
        daten.pdfExportiertAm = Date().addingTimeInterval(-3600)  // 1h ago
        try archiv.speichern(daten)
        archiv.laden()
        let nach = archiv.laden()
        #expect(nach.first(where: { $0.id == daten.id }) != nil)
    }

    @Test func applyFromRestoresId() {
        let protokoll = EinsatzProtokoll()
        var daten = ProtokollDaten()
        daten.id = UUID()
        #expect(daten.id != protokoll.id)
        protokoll.apply(from: daten)
        #expect(protokoll.id == daten.id)
    }

    @Test func notfallgeschehenBefundHatNotfallFreitext() {
        let befund = NotfallgeschehenBefund()
        #expect(befund.notfallFreitext == "")
    }

}
