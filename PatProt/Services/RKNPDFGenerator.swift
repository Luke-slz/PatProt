// PatProt/Services/RKNPDFGenerator.swift
import UIKit

struct RKNPDFGenerator {

    // MARK: - Seitenmaße
    static let W: CGFloat = 595
    static let H: CGFloat = 842

    // MARK: - Farben
    private static let cBlack  = UIColor.black
    private static let cBorder = UIColor(white: 0.3, alpha: 1)
    private static let cHeader = UIColor.black          // Sektionsheader: schwarz
    private static let cLight  = UIColor(white: 0.92, alpha: 1) // heller Hintergrund

    // MARK: - Schriften
    private static let f5  = UIFont.systemFont(ofSize: 5)
    private static let f5b = UIFont.boldSystemFont(ofSize: 5)
    private static let f6  = UIFont.systemFont(ofSize: 6)
    private static let f6b = UIFont.boldSystemFont(ofSize: 6)
    private static let f7  = UIFont.systemFont(ofSize: 7)
    private static let f7b = UIFont.boldSystemFont(ofSize: 7)
    private static let f8b = UIFont.boldSystemFont(ofSize: 8)
    private static let f9b = UIFont.boldSystemFont(ofSize: 9)
    private static let f12b = UIFont.boldSystemFont(ofSize: 12)

    // MARK: - Datumsformatierung
    private static let dateFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "dd.MM.yy"; return f }()
    private static let timeFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()
    private static func d(_ v: Date?) -> String { v.map { dateFmt.string(from: $0) } ?? "" }
    private static func t(_ v: Date?) -> String { v.map { timeFmt.string(from: $0) } ?? "" }

    // MARK: - Primitive Zeichenhilfen

    private static func fillR(_ r: CGRect, _ c: UIColor = .white) { c.setFill(); UIRectFill(r) }

    private static func strokeR(_ r: CGRect, lw: CGFloat = 0.4) {
        cBorder.setStroke()
        let p = UIBezierPath(rect: r); p.lineWidth = lw; p.stroke()
    }

    private static func hline(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, lw: CGFloat = 0.4) {
        cBorder.setStroke()
        let p = UIBezierPath(); p.lineWidth = lw
        p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x+w, y: y)); p.stroke()
    }

    private static func vline(_ x: CGFloat, _ y: CGFloat, _ h: CGFloat, lw: CGFloat = 0.4) {
        cBorder.setStroke()
        let p = UIBezierPath(); p.lineWidth = lw
        p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x, y: y+h)); p.stroke()
    }

    /// Einzeiliger Text, abgeschnitten
    private static func txt(_ s: String, _ r: CGRect, font: UIFont = f6, color: UIColor = .black, align: NSTextAlignment = .left) {
        guard !s.isEmpty else { return }
        let ps = NSMutableParagraphStyle(); ps.alignment = align; ps.lineBreakMode = .byTruncatingTail
        (s as NSString).draw(in: r, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: ps])
    }

    /// Mehrzeiliger Text
    private static func mtxt(_ s: String, _ r: CGRect, font: UIFont = f6) {
        guard !s.isEmpty else { return }
        let ps = NSMutableParagraphStyle(); ps.alignment = .left
        (s as NSString).draw(in: r, withAttributes: [.font: font, .foregroundColor: UIColor.black, .paragraphStyle: ps])
    }

    /// Schwarzer Sektionsheader (weißer Text)
    private static func secHeader(_ title: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 10) {
        fillR(CGRect(x: x, y: y, width: w, height: h), cHeader)
        txt(title, CGRect(x: x+2, y: y+1.5, width: w-4, height: h-3), font: f6b, color: .white)
    }

    /// Grauer Unterabschnitt-Header
    private static func subHeader(_ title: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 8.5) {
        fillR(CGRect(x: x, y: y, width: w, height: h), UIColor(white: 0.75, alpha: 1))
        txt(title, CGRect(x: x+2, y: y+1, width: w-4, height: h-2), font: f5b, color: .black)
    }

    /// Checkbox: kleines Quadrat mit optionalem Häkchen
    private static func cb(_ checked: Bool, x: CGFloat, y: CGFloat, size: CGFloat = 5.5) {
        let r = CGRect(x: x, y: y, width: size, height: size)
        fillR(r, .white); strokeR(r, lw: 0.4)
        if checked {
            txt("✓", CGRect(x: x-0.5, y: y-1, width: size+1, height: size+2), font: f5b, color: .black, align: .center)
        }
    }

    /// Checkbox mit Label daneben
    private static func cbLabel(_ label: String, checked: Bool, x: CGFloat, y: CGFloat, cbSize: CGFloat = 5.5, gap: CGFloat = 2, labelW: CGFloat = 80) {
        cb(checked, x: x, y: y, size: cbSize)
        txt(label, CGRect(x: x+cbSize+gap, y: y-0.5, width: labelW, height: cbSize+1), font: f5)
    }

    /// Beschriftetes Eingabefeld mit Unterrand
    private static func labeledField(_ label: String, _ value: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 14) {
        fillR(CGRect(x: x, y: y, width: w, height: h))
        strokeR(CGRect(x: x, y: y, width: w, height: h))
        txt(label, CGRect(x: x+1.5, y: y+1, width: w-3, height: 6), font: f5, color: UIColor(white: 0.3, alpha: 1))
        txt(value, CGRect(x: x+1.5, y: y+7, width: w-3, height: h-8), font: f6b)
    }

    /// Zeitfeld: kleines Label + Uhrzeit-Wert
    private static func timeField(_ label: String, _ value: String, x: CGFloat, y: CGFloat, w: CGFloat = 38, h: CGFloat = 13) {
        strokeR(CGRect(x: x, y: y, width: w, height: h))
        txt(label, CGRect(x: x+1.5, y: y+1, width: w-3, height: 5.5), font: f5, color: UIColor(white: 0.35, alpha: 1))
        txt(value, CGRect(x: x+1.5, y: y+7, width: w-3, height: 6), font: f6b)
    }

    // MARK: - Öffentlicher Einstiegspunkt

    static func generate(protokoll: EinsatzProtokoll) -> URL? {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("RKN_\(protokoll.id).pdf")
        let bounds = CGRect(x: 0, y: 0, width: W, height: H)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        do {
            try renderer.writePDF(to: tmp) { ctx in
                ctx.beginPage()
                drawPage1(protokoll: protokoll)
                ctx.beginPage()
                drawPage2(protokoll: protokoll)
            }
            return tmp
        } catch {
            return nil
        }
    }

    // MARK: - Seite 1 (Dispatcher)
    private static func drawPage1(protokoll: EinsatzProtokoll) {
        fillR(CGRect(x: 0, y: 0, width: W, height: H))
        drawHeader(protokoll: protokoll)
        drawSection1(protokoll: protokoll)
        drawSection2(protokoll: protokoll)
        drawSection3(protokoll: protokoll)
        drawSection4(protokoll: protokoll)
    }

    // MARK: - Seite 2 (Dispatcher)
    private static func drawPage2(protokoll: EinsatzProtokoll) {
        fillR(CGRect(x: 0, y: 0, width: W, height: H))
        drawSection42(protokoll: protokoll)
        drawSection5(protokoll: protokoll)
        drawVerlaufsgrafik(protokoll: protokoll)
        drawSection6(protokoll: protokoll)
        drawSection65(protokoll: protokoll)
        drawSection7(protokoll: protokoll)
        drawSection8(protokoll: protokoll)
        drawSection9(protokoll: protokoll)
        drawNaca(protokoll: protokoll)
    }

    // MARK: - Platzhalter (werden in späteren Tasks implementiert)
    private static func drawHeader(protokoll: EinsatzProtokoll) {
        let p = protokoll.patientDaten
        let e = protokoll.einsatzOrt
        // Äußerer Rahmen oben
        strokeR(CGRect(x: 4, y: 4, width: W-8, height: 28))

        // Krankenkasse / Kostenträger
        txt("Krankenkasse bzw. Kostenträger", CGRect(x: 6, y: 5, width: 130, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
        txt(p.kostentraeger, CGRect(x: 6, y: 12, width: 130, height: 8), font: f6b)
        vline(138, 4, 28)

        // Name
        txt("Name, Vorname des Versicherten", CGRect(x: 140, y: 5, width: 140, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
        let nameStr = [p.nachname, p.vorname].filter { !$0.isEmpty }.joined(separator: ", ")
        txt(nameStr, CGRect(x: 140, y: 12, width: 140, height: 8), font: f6b)
        vline(282, 4, 28)

        // geb. am
        txt("geb. am", CGRect(x: 284, y: 5, width: 60, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
        txt(d(p.geburtsDatum), CGRect(x: 284, y: 12, width: 60, height: 8), font: f6b)
        vline(346, 4, 28)

        // Versicherten-Nr
        txt("Versicherten-Nr.", CGRect(x: 348, y: 5, width: 80, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
        txt(p.versicherungsNummer, CGRect(x: 348, y: 12, width: 80, height: 8), font: f6b)
        vline(430, 4, 28)

        // Status
        txt("Status", CGRect(x: 432, y: 5, width: 40, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
        vline(474, 4, 28)

        // Betriebsstätten-Nr / Datum
        txt("Betriebsstätten-Nr. / Datum", CGRect(x: 476, y: 5, width: 115, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
        txt(d(e.alarmzeit), CGRect(x: 476, y: 12, width: 115, height: 8), font: f6b)

        hline(4, 32, W-8)
    }
    private static func drawSection1(protokoll: EinsatzProtokoll) {
        let e = protokoll.einsatzOrt
        let p = protokoll.patientDaten
        let b = protokoll.besatzung
        let lx: CGFloat = 4
        let y: CGFloat = 33

        // ── Linke Hälfte: Sektionsheader ──────────────────────────────────────
        secHeader("1. Rettungstechnische Daten", x: lx, y: y, w: W/2 - 2)

        // ── Fahrzeugtyp-Checkboxen ────────────────────────────────────────────
        let fahrzeug = e.fahrzeugName.uppercased()
        let fahrzeuge: [(String, Bool)] = [
            ("RTW",      fahrzeug.contains("RTW")),
            ("KTW",      fahrzeug.contains("KTW")),
            ("NEF",      fahrzeug.contains("NEF")),
            ("NAW",      fahrzeug.contains("NAW") && !fahrzeug.contains("BABY")),
            ("Baby NAW", fahrzeug.contains("BABY")),
            ("V-RTW",    fahrzeug.contains("V-RTW") || fahrzeug.contains("VRTW")),
        ]
        var cx = lx + 2
        let fyRow: CGFloat = y + 12
        for (label, checked) in fahrzeuge {
            cb(checked, x: cx, y: fyRow)
            txt(label, CGRect(x: cx+7, y: fyRow-0.5, width: 34, height: 7), font: f5b)
            cx += label.count > 3 ? 36 : 28
        }

        // ── Sondersignal / mit Patient / Notarzt ─────────────────────────────
        let syRow: CGFloat = fyRow + 9
        cbLabel("Sondersignal Hin",      checked: e.sondersignal,  x: lx+2,   y: syRow)
        cbLabel("mit Patient",           checked: e.mitPatient,    x: lx+68,  y: syRow)
        cbLabel("Notarzt nachgefordert", checked: e.notarzt,       x: lx+120, y: syRow)

        hline(lx, syRow+8, W/2-2)

        // ── Zeitenraster ──────────────────────────────────────────────────────
        let tRow: CGFloat = syRow + 8
        let tw: CGFloat = 46
        timeField("Alarmzeit",   t(e.alarmzeit),           x: lx,        y: tRow, w: tw)
        timeField("Ausfahrt",    "",                        x: lx+tw,     y: tRow, w: tw)
        timeField("Ankunft",     t(e.ankunftzeit),          x: lx+tw*2,   y: tRow, w: tw)
        timeField("Abfahrt",     t(e.abfahrtzeit),          x: lx+tw*3,   y: tRow, w: tw)
        timeField("KH-Ankunft",  t(e.krankenHausAnkunft),  x: lx+tw*4,   y: tRow, w: tw)
        timeField("Ende",        "",                        x: lx+tw*5,   y: tRow, w: tw-4)

        // ── Transportziel ─────────────────────────────────────────────────────
        let trRow: CGFloat = tRow + 13
        labeledField("Transportziel / Straße", e.adresse, x: lx,       y: trRow, w: 160, h: 13)
        labeledField("Haus-Nr.",               e.zusatz,  x: lx+160,   y: trRow, w: 40,  h: 13)
        labeledField("PLZ",                    e.plz,     x: lx+200,   y: trRow, w: 34,  h: 13)
        labeledField("Ort",                    e.ort,     x: lx+234,   y: trRow, w: W/2-238, h: 13)

        // ── Rechte Hälfte: EINSATZPROTOKOLL-Titel ─────────────────────────────
        vline(W/2, y, 59)
        let rx = W/2 + 2

        txt("EINSATZPROTOKOLL", CGRect(x: rx, y: y+3, width: W/2-10, height: 14), font: f12b, align: .center)
        hline(rx, y+18, W/2-6)

        // Notarzt / NetSan Checkboxen
        cb(e.notarzt,  x: rx+4,  y: y+21)
        txt("Notarzt",             CGRect(x: rx+11, y: y+20, width: 50,  height: 7), font: f6b)
        cb(!e.notarzt, x: rx+70,  y: y+21)
        txt("NetSan/RettAss/RS",   CGRect(x: rx+77, y: y+20, width: 90,  height: 7), font: f6b)
        hline(rx, y+30, W/2-6)

        // Einsatznummer + Standort
        labeledField("Einsatznummer", e.einsatzNummer, x: rx,     y: y+31, w: 82,       h: 13)
        labeledField("Standort RM",   e.fahrzeugName,  x: rx+82,  y: y+31, w: 82,       h: 13)

        // Männlich / Weiblich
        cb(p.geschlecht == .maennlich, x: rx+172, y: y+33)
        txt("männlich", CGRect(x: rx+179, y: y+32, width: 42, height: 7), font: f5)
        cb(p.geschlecht == .weiblich,  x: rx+172, y: y+41)
        txt("weiblich",  CGRect(x: rx+179, y: y+40, width: 42, height: 7), font: f5)

        hline(rx, y+45, W/2-6)

        // Besatzung
        let besatzungsText: String = {
            let namen = [b.sanitaeter1, b.sanitaeter2, b.sanitaeter3, b.sanitaeter4].filter { !$0.isEmpty }
            return namen.joined(separator: ", ")
        }()
        txt("Besatzung:", CGRect(x: rx+2, y: y+47, width: 38, height: 7), font: f5b)
        txt(besatzungsText, CGRect(x: rx+42, y: y+47, width: W/2-50, height: 14), font: f5)

        // Untere Abschlusskante Sektion 1
        hline(lx, trRow+13, W-8)
    }
    private static func drawSection2(protokoll: EinsatzProtokoll) {
        let ng = protokoll.notfallGeschehen
        let s  = protokoll.sampler
        let lx: CGFloat = 4
        let y0: CGFloat = 127   // under section 1 bottom line

        secHeader("2. Notfallgeschehen / Anamnese / Erstbefund", x: lx, y: y0, w: W-8)

        let lines: [(String, String, String)] = [
            ("A", ng.erstbefundVorOrt,              "S"),
            ("B", ng.patientGefunden,               "A"),
            ("C", ng.unfallhergangFreitext,         "M"),
            ("D", s.patientenVorgeschichte,         "P"),
            ("E", s.ereignis,                       "L"),
        ]
        let lineH: CGFloat = 13
        var y = y0 + 10
        for (letter, value, samplerLetter) in lines {
            // Buchstabe links
            fillR(CGRect(x: lx, y: y, width: 12, height: lineH), cLight)
            txt(letter, CGRect(x: lx+2, y: y+3, width: 8, height: 8), font: f7b)
            vline(lx+12, y, lineH)
            // Inhalt
            strokeR(CGRect(x: lx+12, y: y, width: W-30, height: lineH))
            mtxt(value, CGRect(x: lx+14, y: y+2, width: W-34, height: lineH-3))
            // SAMPLER-Buchstabe rechts
            fillR(CGRect(x: W-14, y: y, width: 10, height: lineH), cLight)
            txt(samplerLetter, CGRect(x: W-13, y: y+3, width: 8, height: 8), font: f7b)
            hline(lx, y+lineH, W-8)
            y += lineH
        }
    }
    private static func drawSection3(protokoll: EinsatzProtokoll) {
        let ub = protokoll.uebergabeBefunde
        let um = protokoll.uebergabeMesswerte
        let lx: CGFloat = 4
        let y0: CGFloat = 193   // under section 2

        secHeader("3. Befunde", x: lx, y: y0, w: W-8)

        let colW: CGFloat = (W-8) / 4
        let y = y0 + 10

        // ── Spalte 1: Messwerte ──────────────────────────────────────────────
        subHeader("Messwerte", x: lx, y: y, w: colW)
        var y1 = y + 8.5

        let messwerte: [(String, String)] = [
            ("RR SYS",  um.rrSys),
            ("RR DIA",  um.rrDia),
            ("HF",      um.hf),
            ("SpO₂",    um.spo2),
            ("AF",      um.af),
            ("etCO₂",   ""),
            ("BZ",      um.bz),
            ("Temp.",   um.temp),
        ]
        for (label, value) in messwerte {
            strokeR(CGRect(x: lx, y: y1, width: colW, height: 11))
            txt(label, CGRect(x: lx+2, y: y1+1.5, width: 28, height: 6), font: f5, color: UIColor(white:0.4,alpha:1))
            txt(value, CGRect(x: lx+32, y: y1+2.5, width: colW-34, height: 8), font: f7b)
            y1 += 11
        }
        // Schmerz
        strokeR(CGRect(x: lx, y: y1, width: colW, height: 11))
        txt("Schmerz (0–10)", CGRect(x: lx+2, y: y1+1.5, width: colW-4, height: 5.5), font: f5, color: UIColor(white:0.4,alpha:1))
        txt(ub.schmerz > 0 ? "\(ub.schmerz)" : "", CGRect(x: lx+2, y: y1+7, width: colW-4, height: 7), font: f7b)
        y1 += 11
        // GCS
        strokeR(CGRect(x: lx, y: y1, width: colW, height: 11))
        txt("GCS", CGRect(x: lx+2, y: y1+1.5, width: 20, height: 5.5), font: f5, color: UIColor(white:0.4,alpha:1))
        txt("\(ub.gcsAugen)+\(ub.gcsVerbal)+\(ub.gcsMotor)=\(ub.gcsGesamt)", CGRect(x: lx+2, y: y1+7, width: colW-4, height: 7), font: f5b)

        // ── Spalte 2: A+B Atmung ─────────────────────────────────────────────
        let x2 = lx + colW
        subHeader("A+B Atmung", x: x2, y: y, w: colW)
        var y2 = y + 8.5

        let atmung: [(String, Bool)] = [
            ("unauffällig",       ub.abUnauffaellig),
            ("Dyspnoe",           ub.dyspnoe),
            ("Zyanose",           ub.zyanose),
            ("Spastik",           ub.spastik),
            ("Rasselgeräusche",   ub.rasselgeraeusche),
            ("Brodeln",           ub.brodeln),
            ("Stridor",           ub.stridor),
            ("Atemwegsverlegung", ub.atemwegsverlegung),
            ("Schnappatmung",     ub.schnappatmung),
            ("Apnoe",             ub.apnoe),
            ("Beatmung",          ub.beatmung),
            ("Hyperventilation",  ub.hyperventilation),
            ("n. beurteilbar",    ub.abNichtBeurteilbar),
        ]
        for (label, checked) in atmung {
            cbLabel(label, checked: checked, x: x2+2, y: y2, labelW: colW-12)
            y2 += 8
        }

        // ── Spalte 3: C Zirkulation + EKG ───────────────────────────────────
        let x3 = lx + 2*colW
        subHeader("C Cirkulat. + EKG", x: x3, y: y, w: colW)
        var y3 = y + 8.5

        let ekg: [(String, Bool)] = [
            ("unauffällig",         ub.cUnauffaellig),
            ("Rekapillierung",      ub.rekapillierung),
            ("Sinusrhythmus",       ub.sinusrhythmus),
            ("Abs. Arrhythmie",     ub.absoluteArrhythmie),
            ("AV-Block I°",         ub.avBlockI),
            ("AV-Block II°",        ub.avBlockII),
            ("AV-Block III°",       ub.avBlockIII),
            ("QRS Tachy breit",     ub.qrsTachykardieBreit),
            ("QRS Tachy schmal",    ub.qrsTachykardieSchmal),
            ("Kammerflattern",      ub.kammerflattern),
            ("Kammerflimmern",      ub.kammerflimmern),
            ("Asystolie",           ub.asystolie),
            ("PEA",                 ub.pea),
            ("Schrittmacher",       ub.schrittmacher),
            ("Infarkt-EKG (STEMI)", ub.infarktEkg),
            ("SVES",                ub.sves),
            ("VES",                 ub.ves),
            ("ES monomorph",        ub.extrasystolenMonomorph),
            ("ES polymorph",        ub.extrasystolenPolymorph),
            ("n. beurteilbar",      ub.cNichtBeurteilbar),
        ]
        for (label, checked) in ekg {
            cbLabel(label, checked: checked, x: x3+2, y: y3, labelW: colW-12)
            y3 += 7
        }

        // ── Spalte 4: D Neurologie ───────────────────────────────────────────
        let x4 = lx + 3*colW
        subHeader("D Neurologie", x: x4, y: y, w: colW)
        var y4 = y + 8.5

        txt("Bewusstsein", CGRect(x: x4+2, y: y4, width: colW-4, height: 6), font: f5b)
        y4 += 7
        for (label, checked) in [
            ("wach",            ub.bewWach),
            ("auf Ansprache",   ub.bewAnsprache),
            ("auf Schmerzreiz", ub.bewSchmerzreiz),
            ("bewusstlos",      ub.bewusstlos),
            ("n. beurteilbar",  ub.dNichtBeurteilbar),
        ] as [(String, Bool)] {
            cbLabel(label, checked: checked, x: x4+2, y: y4, labelW: colW-12)
            y4 += 7
        }
        hline(x4, y4, colW); y4 += 3
        txt("Pupillen re:", CGRect(x: x4+2, y: y4, width: 40, height: 6), font: f5b); y4 += 6
        for (label, checked) in [
            ("eng",               ub.pupilleReEng),
            ("mittel",            ub.pupilleReMittel),
            ("weit",              ub.pupilleReWeit),
            ("entrundet",         ub.pupilleReEntrundet),
            ("keine Lichtreakt.", ub.pupilleReKeineLichtreaktion),
        ] as [(String, Bool)] {
            cbLabel(label, checked: checked, x: x4+2, y: y4, labelW: colW-12)
            y4 += 7
        }
        hline(x4, y4, colW); y4 += 3
        txt("Pupillen li:", CGRect(x: x4+2, y: y4, width: 40, height: 6), font: f5b); y4 += 6
        for (label, checked) in [
            ("eng",               ub.pupilleLiEng),
            ("mittel",            ub.pupilleLiMittel),
            ("weit",              ub.pupilleLiWeit),
            ("entrundet",         ub.pupilleLiEntrundet),
            ("keine Lichtreakt.", ub.pupilleLiKeineLichtreaktion),
        ] as [(String, Bool)] {
            cbLabel(label, checked: checked, x: x4+2, y: y4, labelW: colW-12)
            y4 += 7
        }
        hline(x4, y4, colW); y4 += 3
        for (label, checked) in [
            ("Vorbestehendes Defizit", ub.neuroVorbestehendesDefizit),
            ("Facialisparese",         ub.neuroFacialisparese),
            ("Armparese",              ub.neuroArmparese),
            ("Sprachstörung",          ub.neuroSprachstoerung),
            ("Sehstörung",             ub.neuroSehstoerung),
            ("Babinski",               ub.neuroBabinski),
            ("Querschnitt",            ub.neuroQuerschnitt),
            ("Meningismus",            ub.neuroMeningismus),
            ("Demenz",                 ub.neuroDemenz),
        ] as [(String, Bool)] {
            cbLabel(label, checked: checked, x: x4+2, y: y4, labelW: colW-12)
            y4 += 7
        }

        // ── Spalten-Trennlinien + untere Abschlusskante ──────────────────────
        let s3Bottom = max(y1, y2, y3, y4) + 4
        vline(x2, y+8.5, s3Bottom - y - 8.5)
        vline(x3, y+8.5, s3Bottom - y - 8.5)
        vline(x4, y+8.5, s3Bottom - y - 8.5)
        hline(lx, s3Bottom, W-8)
    }
    private static func drawSection4(protokoll: EinsatzProtokoll) {
        let d = protokoll.diagnose
        let lx: CGFloat = 4
        let y0: CGFloat = 465   // under section 3 — calibrate after first export

        secHeader("4. Diagnose", x: lx, y: y0, w: W-8)
        subHeader("4.1 Erkrankung", x: lx, y: y0+10, w: W-8)

        let cols = 6
        let cw = (W-8) / CGFloat(cols)
        let y = y0 + 20

        // ── Spalte 1: ZNS ────────────────────────────────────────────────────
        var cx = lx+2; var cy = y
        txt("ZNS", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("Akutes neuro. Defizit", d.znsAkutNeuro),
            ("ICB",                   false),
            ("SAB",                   d.znsSab),
            ("Transplantat",          d.znsTransplantat),
            ("Status Epilepticus",    d.znsEpilepsie),
            ("Fieberkrampf",          d.znsFieberkrampf),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }

        // ── Spalte 2: Herz-Kreislauf ─────────────────────────────────────────
        cx = lx+cw+2; cy = y
        txt("Herz-Kreislauf", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("ACS",                    d.herzAcs),
            ("STEMI",                  d.herzStemi),
            ("VW",                     d.herzVW),
            ("HW",                     d.herzHW),
            ("kardiogener Schock",     false),
            ("Rhythmusstörung",        d.herzRhythmus),
            ("PM/ICD Fehlfunktion",    d.herzPmFehlfunktion),
            ("Herzinsuffizienz dekmp.",d.herzDekomp),
            ("hypert. Notfall",        d.herzHypertonerNotfall),
            ("Aortenaneurysma",        d.herzAortenaneurysma),
            ("Hypotonie",              d.herzHypotonie),
            ("Synkope",                d.herzSynkope),
            ("Thrombose/Embolie",      d.herzThromboseEmbolie),
            ("Schock unkl. Genese",    d.herzSchockUnklarGenese),
            ("orthostat. Regul.",      d.herzOrthostatisch),
            ("unkl. Thoraxschmerz",    d.herzUnklarerThoraxschmerz),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }

        // ── Spalte 3: Atmung ─────────────────────────────────────────────────
        cx = lx+2*cw+2; cy = y
        txt("Atmung", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("Asthma",                 d.atmungAsthma),
            ("exazerbiert (COPD)",     d.atmungExazerbiert),
            ("Pneumonie/Bronchitis",   d.atmungPneumonie),
            ("LTB",                    d.atmungLtb),
            ("Epiglottitis",           d.atmungEpiglottitis),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }
        cy += 4
        txt("Psychiatrie", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("psych. Akutzustand",  d.psychAkut),
            ("psychische Krise",    d.psychKrise),
            ("Manie",               d.psychManie),
            ("Intoxikation",        d.psychIntoxikation),
            ("Entzug/Delir",        d.psychEntzug),
            ("Suizidal",            d.psychSuizidal),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }

        // ── Spalte 4: Stoffwechsel + Abdomen ─────────────────────────────────
        cx = lx+3*cw+2; cy = y
        txt("Stoffwechsel", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("Exsikkose",           d.stoffExsikkose),
            ("Hypoglykämie",        d.stoffHypoglykämie),
            ("Hyperglykämie",       d.stoffHyperglykämie),
            ("Urämie",              d.stoffUremie),
            ("bek. diab.pflichtig", d.stoffDia),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }
        cy += 4
        txt("Abdomen", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("akutes Abdomen",  d.abdoAkutes),
            ("Koliken",         d.abdoKoliken),
            ("GIB oben",        d.abdoGibOben),
            ("GIB unten",       d.abdoGibUnten),
            ("Galle/Niere",     d.abdoGalleNiere),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }

        // ── Spalte 5: Gyn/Geb + Infektionen ─────────────────────────────────
        cx = lx+4*cw+2; cy = y
        txt("Gyn./Geb.-hilfe", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("Schwangerschaft >35.SSW", d.gynSchwangerschaft35),
            ("Geburt",                  d.gynGeburt),
            ("Eklampsie",               d.gynEklampsie),
            ("Extrauterine Grav.",       false),
            ("vaginale Blutung",        d.gynVaginalblutung),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }
        cy += 4
        txt("Infektionen", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("HIV",              d.infektHiv),
            ("hochkont. Erk.",   d.infektHighToxSars),
            ("Gastroenteritis",  d.infektGastro),
            ("Anaphylaxie Gr.1/2", d.infektAnaphylaxie12),
            ("SIDS",             d.infektSids),
            ("Intoxikation",     d.infektIntoxikation),
            ("unkl. Fieber",     false),
            ("offen/MRSA",       false),
            ("MRE",              false),
            ("Hepatitis",        false),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }

        // ── Spalte 6: Sonstiges ──────────────────────────────────────────────
        cx = lx+5*cw+2; cy = y
        txt("Sonstiges", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
        for (l, c) in [
            ("Anaphylaxie Gr.3/4", d.infektAnaphylaxie12),
            ("unkl. Lumbago",     d.infektAkuteLumbalgie),
            ("palliative Situation", d.infektPalliativ),
            ("med. Behandlungskpl.", d.infektBehandlungKompl),
            ("urologische Erkr.",  d.infektUrologisch),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: cx, y: cy, labelW: cw-12); cy += 7 }

        // ── Spalten-Trennlinien ──────────────────────────────────────────────
        let diagBottom = y0 + 20 + 140
        for i in 1..<cols {
            vline(lx + CGFloat(i)*cw, y0+10, diagBottom - y0 - 10)
        }
        hline(lx, diagBottom, W-8)

        // ── Diagnose/Leitsymptom ─────────────────────────────────────────────
        labeledField("Diagnose/Leitsymptom", d.leitsymptom, x: lx, y: diagBottom, w: W-8, h: 14)
    }
    private static func drawSection42(protokoll: EinsatzProtokoll) {}
    private static func drawSection5(protokoll: EinsatzProtokoll) {}
    private static func drawVerlaufsgrafik(protokoll: EinsatzProtokoll) {}
    private static func drawSection6(protokoll: EinsatzProtokoll) {}
    private static func drawSection65(protokoll: EinsatzProtokoll) {}
    private static func drawSection7(protokoll: EinsatzProtokoll) {}
    private static func drawSection8(protokoll: EinsatzProtokoll) {}
    private static func drawSection9(protokoll: EinsatzProtokoll) {}
    private static func drawNaca(protokoll: EinsatzProtokoll) {}
}
