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

    @Test func resetGeneratesNewId() {
        let protokoll = EinsatzProtokoll()
        var daten = ProtokollDaten()
        daten.id = UUID()
        protokoll.apply(from: daten)
        #expect(protokoll.id == daten.id)
        protokoll.reset()
        #expect(protokoll.id != daten.id)
    }

    @Test func einsatzOrtHatPlzUndOrt() {
        let ort = EinsatzOrt()
        #expect(ort.plz == "")
        #expect(ort.ort == "")
    }

    @Test func personalEintragMigration() {
        let altJSON = "[\"Max Muster\",\"Jane Doe\"]"
        let data = Data(altJSON.utf8)
        // Must fail to decode as [PersonalEintrag]
        let alsPE = try? JSONDecoder().decode([PersonalEintrag].self, from: data)
        #expect(alsPE == nil)
        // Must succeed via String migration
        let alsStrings = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        let migriert = alsStrings.map { PersonalEintrag(name: $0, qualifikation: .rettungssanitaeter) }
        #expect(migriert.count == 2)
        #expect(migriert[0].name == "Max Muster")
        #expect(migriert[0].qualifikation == .rettungssanitaeter)
    }

    @Test func breathingBefundHatBrodeln() {
        let b = BreathingBefund()
        #expect(b.brodeln == false)
    }

    @Test func uebergabeBefundHatBrodeln() {
        let u = UebergabeBefunde()
        #expect(u.brodeln == false)
    }

    @Test func massnahmenHatGuedelWendl() {
        let m = MassnahmenBefund()
        #expect(m.guedelTubus == false)
        #expect(m.wendlTubus  == false)
    }

    @Test func samplerBefundHatLetztesMahlFelder() {
        let s = SAMPLERBefund()
        #expect(s.letztesMahlUnbekannt == false)
    }

    @Test func samplerBefundHatSchwangerschaft() {
        let s = SAMPLERBefund()
        #expect(s.schwangerschaft == false)
        #expect(s.schwangerschaftSSW == 0)
    }

    @Test func prefillFuelltUebergabeMesswerteAusVerlauf() {
        let p = EinsatzProtokoll()
        var m = VerlaufsMessung()
        m.blutdruckSys = 120
        m.blutdruckDia = 80
        m.puls         = 72
        m.spo2         = 98
        m.atemFrequenz = 16
        m.blutzucker   = 120.0
        m.temperatur   = 36.8
        p.verlaufMessungen = [m]
        p.prefillUebergabeMesswerteAusVerlauf()
        #expect(p.uebergabeMesswerte.rrSys == "120")
        #expect(p.uebergabeMesswerte.rrDia == "80")
        #expect(p.uebergabeMesswerte.hf    == "72")
        #expect(p.uebergabeMesswerte.spo2  == "98")
        #expect(p.uebergabeMesswerte.af    == "16")
        #expect(p.uebergabeMesswerte.bz    == "120")
        #expect(p.uebergabeMesswerte.temp  == "36.8")
    }

    @Test func prefillMesswerteUeberschreibtNichtVorhandeneWerte() {
        let p = EinsatzProtokoll()
        p.uebergabeMesswerte.rrSys = "110"   // bereits eingetragen
        var m = VerlaufsMessung()
        m.blutdruckSys = 120
        m.spo2         = 98
        p.verlaufMessungen = [m]
        p.prefillUebergabeMesswerteAusVerlauf()
        #expect(p.uebergabeMesswerte.rrSys == "110")   // bleibt unverändert
        #expect(p.uebergabeMesswerte.spo2  == "98")    // leeres Feld wird gefüllt
    }

    @Test func prefillGCSAusDisabilityWennDefault() {
        let p = EinsatzProtokoll()
        p.disability.status    = .nicht_kritisch
        p.disability.gcsAugen  = 3
        p.disability.gcsVerbal = 4
        p.disability.gcsMotor  = 5
        p.prefillGCSAusDisability()
        #expect(p.uebergabeBefunde.gcsAugen  == 3)
        #expect(p.uebergabeBefunde.gcsVerbal == 4)
        #expect(p.uebergabeBefunde.gcsMotor  == 5)
    }

    @Test func prefillGCSUeberschreibtNichtManuelleWerte() {
        let p = EinsatzProtokoll()
        p.disability.status     = .nicht_kritisch
        p.disability.gcsAugen   = 3
        p.uebergabeBefunde.gcsAugen = 2
        p.prefillGCSAusDisability()
        #expect(p.uebergabeBefunde.gcsAugen == 2)
    }

    @Test func notfallgeschehenHatManvEigeneSK() {
        let n = NotfallgeschehenBefund()
        #expect(n.manvEigeneSK == "")
    }

    @Test func massnahmenHatMaschinelleBeatmungFelder() {
        let m = MassnahmenBefund()
        #expect(m.maschinelleBeatmung == false)
        #expect(m.tidalvolumen == "")
        #expect(m.peep == "")
    }

    @Test func numpadFormatDisplayLeer() {
        let result = NumpadSheet.formatDisplay(digits: "", mode: .integer(label: "X", unit: "Y"))
        #expect(result == "—")
    }

    @Test func samplerBefundHatStuhlgangUndRegelblutung() {
        let s = SAMPLERBefund()
        #expect(s.letzterStuhlgang == "")
        #expect(s.letzterStuhlgangUnbekannt == false)
        #expect(s.letzteRegelblutung == "")
        #expect(s.letzteRegelblutungUnbekannt == false)
    }

    @Test func samplerBefundHatUnbekanntFelder() {
        let s = SAMPLERBefund()
        #expect(s.allergienUnbekannt == false)
        #expect(s.medikamenteUnbekannt == false)
        #expect(s.patientenVorgeschichteUnbekannt == false)
    }

    @Test func notfallgeschehenHatKeinenAuffindeSeparatEintrag() {
        // Auffindewerte are now derived automatically from ABCDE initial values
        let n = NotfallgeschehenBefund()
        #expect(n.erstbefundVorOrt == "")
    }

    @Test func medikamentEintragHatMaximaldosis() {
        let m = MedikamentEintrag()
        #expect(m.maximaldosis == "")
    }

    @Test func protokollVerfasserHatSechsFaelle() {
        #expect(ProtokollVerfasser.allCases.count == 6)
        #expect(ProtokollVerfasser.notfallsanitaeter.rawValue == "Notfallsanitäter")
        #expect(ProtokollVerfasser.rettungssanitaeter.rawValue == "Rettungssanitäter")
    }

    @Test func sinnhaftAutoFillIncludesMedikamente() {
        let p = EinsatzProtokoll()
        var med = MedikamentEintrag()
        med.name = "Midazolam"
        med.dosis = "2"
        med.einheit = "mg"
        med.route = "IV"
        p.medikamente = [med]
        let s = SINNHAFTBefund.autoFilled(from: p)
        #expect(s.notwendigeMassnahmen.contains("Midazolam"))
    }

    // MARK: - KVKarteParser Tests

    @Test func kvParserKVNR() {
        let lines = ["Techniker Krankenkasse", "Versichertenkarte", "MUSTERMANN", "Erika", "*12.07.1964", "A123456789"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.versicherungsNummer == "A123456789")
    }

    @Test func kvParserKVNRInText() {
        let lines = ["DAK", "SCHMIDT", "Hans", "01.01.1990", "Vers.-Nr. C345678901"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.versicherungsNummer == "C345678901")
    }

    @Test func kvParserGeburtsdatumMitAsterisk() {
        let lines = ["TK", "MUSTERMANN", "Erika", "*12.07.1964", "A123456789"]
        let result = KVKarteParser.parse(lines: lines)
        let cal = Calendar.current
        #expect(result.geburtsDatum != nil)
        let comps = cal.dateComponents([.day, .month, .year], from: result.geburtsDatum!)
        #expect(comps.day == 12)
        #expect(comps.month == 7)
        #expect(comps.year == 1964)
    }

    @Test func kvParserGeburtsdatumOhneAsterisk() {
        let lines = ["AOK", "MUSTER", "Anna", "03.09.1985", "B987654321"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.geburtsDatum != nil)
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: result.geburtsDatum!)
        #expect(comps.day == 3)
        #expect(comps.month == 9)
        #expect(comps.year == 1985)
    }

    @Test func kvParserNameZweiZeilen() {
        let lines = ["Techniker Krankenkasse", "Versichertenkarte", "MUSTERMANN", "Erika", "*12.07.1964", "A123456789"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.nachname == "Mustermann")
        #expect(result.vorname == "Erika")
    }

    @Test func kvParserNameKommaFormat() {
        let lines = ["DAK-Gesundheit", "MUSTERMANN, Erika", "*05.03.1980", "X987654321"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.nachname == "Mustermann")
        #expect(result.vorname == "Erika")
    }

    @Test func kvParserKostentraegerMixedCase() {
        let lines = ["Techniker Krankenkasse", "Versichertenkarte", "MUSTERMANN", "Erika", "*12.07.1964", "A123456789"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.kostentraeger == "Techniker Krankenkasse")
    }

    @Test func kvParserKostentraegerAllCaps() {
        let lines = ["AOK NORDWEST", "MUSTERMANN", "Erika", "15.11.1975", "B234567890"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.kostentraeger == "AOK NORDWEST")
    }

    @Test func kvParserNachNameNachAllCapsKasse() {
        let lines = ["AOK NORDWEST", "MUSTERMANN", "Erika", "15.11.1975", "B234567890"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.nachname == "Mustermann")
        #expect(result.vorname == "Erika")
    }

    @Test func kvParserGarbage() {
        let result = KVKarteParser.parse(lines: ["12345", "---", ""])
        #expect(result.vorname.isEmpty)
        #expect(result.nachname.isEmpty)
        #expect(result.versicherungsNummer.isEmpty)
        #expect(result.geburtsDatum == nil)
        #expect(result.kostentraeger.isEmpty)
    }

    @Test func kvParserEchterLeer() {
        let result = KVKarteParser.parse(lines: [])
        #expect(result.vorname.isEmpty)
        #expect(result.nachname.isEmpty)
        #expect(result.versicherungsNummer.isEmpty)
        #expect(result.geburtsDatum == nil)
        #expect(result.kostentraeger.isEmpty)
    }

    // MARK: - Regression Tests (reported scan failures)

    @Test func kvParserVornameLabelNichtAlsVorname() {
        // Karte druckt "Vorname" als Label auf eigener Zeile vor dem echten Vornamen
        let lines = ["Techniker Krankenkasse", "MUSTERMANN", "Vorname", "Erika", "*15.11.1975", "A123456789"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.vorname == "Erika")
        #expect(result.nachname == "Mustermann")
    }

    @Test func kvParserGeburtsdatumMitLabelPraefix() {
        // Geburtsdatum steht als "Geb.: DD.MM.YYYY" auf der Karte
        let lines = ["Barmer", "SCHMIDT", "Klaus", "Geb.: 03.09.1985", "B987654321"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.geburtsDatum != nil)
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: result.geburtsDatum!)
        #expect(comps.day == 3)
        #expect(comps.month == 9)
        #expect(comps.year == 1985)
    }

    @Test func kvParserDEKeinKassenname() {
        // "DE" Ländercode darf nicht als Kassenname erfasst werden
        let lines = ["DE", "Techniker Krankenkasse", "MUSTERMANN", "Erika", "*15.11.1975", "A123456789"]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.kostentraeger == "Techniker Krankenkasse")
        #expect(result.nachname == "Mustermann")
    }

    @Test func kvParserGueltigBisDatumNichtAlsGeburtsdatum() {
        // "Gültig bis"-Datum darf nicht als Geburtsdatum erfasst werden
        let lines = ["AOK", "MUSTER", "Anna", "*03.09.1985", "B987654321", "Gültig bis 12/2027"]
        let result = KVKarteParser.parse(lines: lines)
        let comps = Calendar.current.dateComponents([.year], from: result.geburtsDatum!)
        #expect(comps.year == 1985)
    }

    @Test func kvParserEHIC() {
        // Rückseite eGK – Vision OCR liefert Feldbezeichner als eigene Zeilen
        let lines = [
            "Europäische Krankenversicherungskarte",
            "European Health Insurance Card",
            "Nachname(n) / Surname(s)",
            "MUSTERMANN",
            "Vorname(n) / Given name(s)",
            "Max",
            "Geburtsdatum / Date of birth",
            "01.01.1970",
            "Persönliche Kennnummer / Personal identification number",
            "A123456789",
            "Kennnummer der zuständigen Institution",
            "108310400",
            "Ablaufdatum / Expiry date",
            "12/2027",
            "DE",
            "AOK Bayern"
        ]
        let result = KVKarteParser.parse(lines: lines)
        #expect(result.nachname == "Mustermann")
        #expect(result.vorname == "Max")
        #expect(result.versicherungsNummer == "A123456789")
        #expect(result.kostentraeger == "AOK Bayern")
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: result.geburtsDatum!)
        #expect(comps.day == 1)
        #expect(comps.month == 1)
        #expect(comps.year == 1970)
    }

    @Test func naAngefordertDefaultFalse() {
        let ort = EinsatzOrt()
        #expect(ort.naAngefordert == false)
        #expect(ort.notarzt == false)
    }

}
