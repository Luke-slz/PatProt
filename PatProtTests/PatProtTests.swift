//
//  PatProtTests.swift
//  PatProtTests
//
//  Created by Luke Schulz on 07.05.26.
//

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

}
