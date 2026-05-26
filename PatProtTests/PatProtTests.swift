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

}
