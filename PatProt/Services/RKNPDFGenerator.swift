// PatProt/Services/RKNPDFGenerator.swift
import UIKit

struct RKNPDFGenerator {

    // MARK: - Seitenmaße
    static let W: CGFloat = 595
    static let H: CGFloat = 842

    // MARK: - Layout-Konstanten Seite 1
    private static let p1HeaderY: CGFloat = 4
    private static let p1S1Y: CGFloat     = 33
    private static let p1S2Y: CGFloat     = 127
    private static let p1S3Y: CGFloat     = 193
    private static let p1S4Y: CGFloat     = 465

    // MARK: - Layout-Konstanten Seite 2
    private static let p2S42Y: CGFloat    = 4
    private static let p2GrafY: CGFloat   = 143
    private static let p2S6Y: CGFloat     = 245
    private static let p2S65Y: CGFloat    = 560
    private static let p2S8Y: CGFloat     = 684
    private static let p2S9Y: CGFloat     = 758
    private static let p2NacaY: CGFloat   = 820

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
        // outer border drawn last so it's on top
        drawHeader(protokoll: protokoll)
        drawSection1(protokoll: protokoll)
        drawSection2(protokoll: protokoll)
        drawSection3(protokoll: protokoll)
        drawSection4(protokoll: protokoll)
        UIColor(white:0.2, alpha:1).setStroke()
        let b1 = UIBezierPath(rect: CGRect(x: 3, y: 3, width: W-6, height: H-6))
        b1.lineWidth = 0.6; b1.stroke()
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
        UIColor(white:0.2, alpha:1).setStroke()
        let b2 = UIBezierPath(rect: CGRect(x: 3, y: 3, width: W-6, height: H-6))
        b2.lineWidth = 0.6; b2.stroke()
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
        let verfasser = protokoll.verfasser.rawValue
        if !verfasser.isEmpty {
            txt("Verfasser: \(verfasser)", CGRect(x: 476, y: 19, width: 115, height: 6), font: f5)
        }

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
        txt("Besatzung:", CGRect(x: rx+2, y: y+47, width: 38, height: 7), font: f5b)
        let besatzungMitQual: String = {
            let eintraege: [(String, Qualifikation)] = [
                (b.sanitaeter1, b.qualifikation1),
                (b.sanitaeter2, b.qualifikation2),
                (b.sanitaeter3, b.qualifikation3),
                (b.sanitaeter4, b.qualifikation4),
            ]
            return eintraege.filter { !$0.0.isEmpty }
                .map { "\($0.0) (\($0.1.rawValue))" }
                .joined(separator: ", ")
        }()
        txt(besatzungMitQual, CGRect(x: rx+42, y: y+47, width: W/2-50, height: 14), font: f5)

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
    private static func drawSection42(protokoll: EinsatzProtokoll) {
        let d = protokoll.diagnose
        let vm = d.verletzungsMatrix
        let lx: CGFloat = 4
        let y0: CGFloat = 4
        let colW = W * 0.55

        secHeader("4.2 Verletzungen", x: lx, y: y0, w: colW)

        // Header-Zeile der Matrix
        var y = y0 + 10
        fillR(CGRect(x: lx, y: y, width: colW, height: 8), cLight)
        strokeR(CGRect(x: lx, y: y, width: colW, height: 8))
        txt("Region",  CGRect(x: lx+2,    y: y+1, width: 80, height: 6), font: f5b)
        txt("keine",   CGRect(x: lx+102,  y: y+1, width: 22, height: 6), font: f5b, align: .center)
        txt("leicht",  CGRect(x: lx+124,  y: y+1, width: 22, height: 6), font: f5b, align: .center)
        txt("schwer",  CGRect(x: lx+146,  y: y+1, width: 22, height: 6), font: f5b, align: .center)
        vline(lx+100, y, 8); vline(lx+122, y, 8); vline(lx+144, y, 8); vline(lx+166, y, 8)
        y += 8

        let verletzungen: [(String, Verletzungsgrad)] = [
            ("Schädel-Hirn/Gesicht", vm.schaedelHirn),
            ("HWS",                  vm.hws),
            ("Thorax",               vm.thorax),
            ("Abdomen",              vm.abdomen),
            ("BWS / LWS",            vm.bwsLws),
            ("Becken",               vm.becken),
            ("Obere Extremitäten",   vm.obereExtrem),
            ("Untere Extremitäten",  vm.untereExtrem),
            ("Weichteile",           vm.weichteile),
        ]
        for (name, grad) in verletzungen {
            strokeR(CGRect(x: lx, y: y, width: colW, height: 9))
            txt(name, CGRect(x: lx+2, y: y+1.5, width: 96, height: 6), font: f5)
            vline(lx+100, y, 9); vline(lx+122, y, 9); vline(lx+144, y, 9); vline(lx+166, y, 9)
            cb(grad == .keine,  x: lx+108, y: y+2)
            cb(grad == .leicht, x: lx+130, y: y+2)
            cb(grad == .schwer, x: lx+152, y: y+2)
            y += 9
        }

        // Verletzungsmuster
        hline(lx, y, colW); y += 3
        let muster = d.verletzungsMuster
        cbLabel("Einzelverletzung",   checked: muster == "Einzelverletzung",   x: lx+2,   y: y)
        cbLabel("Mehrfachverletzung", checked: muster == "Mehrfachverletzung", x: lx+72,  y: y)
        cbLabel("Polytrauma",         checked: muster == "Polytrauma",         x: lx+148, y: y)
        y += 9
        let art = d.verletzungsArt
        cbLabel("offen",        checked: art.lowercased().contains("offen"),   x: lx+2,   y: y)
        cbLabel("stumpf",       checked: art.lowercased().contains("stumpf"),  x: lx+60,  y: y)
        cbLabel("penetrierend", checked: art.lowercased().contains("penetr"),  x: lx+120, y: y)
        y += 9

        // Spezielle Traumen
        hline(lx, y, colW); y += 3
        txt("Spezielle Traumen:", CGRect(x: lx+2, y: y, width: colW-4, height: 6), font: f5b); y += 7
        let spec: [(String, Bool)] = [
            ("Verbr./Verbrüh.",   d.spezVerbrVerbrh),
            ("Tauchunfall",       d.spezTauchunfall),
            ("Elektrounfall",     d.spezElektrounfall),
            ("PKW/LKW-Insasse",   d.spezPkwLkw),
            ("Motorradfahrer",    d.spezMotorrad),
            ("Fahrradfahrer",     d.spezFahrrad),
            ("Fußgänger",         d.spezFussgaenger),
            ("Sturz >3m Höhe",    d.spezSturzHoehe),
            ("and. Verkehrsteil.",d.spezAndVerkehr),
            ("Maschinenunfall",   d.spezMaschine),
            ("Gewaltverbrechen",  d.spezGewalt),
            ("anderer Unfall",    d.spezAndererUnfall),
        ]
        var sx = lx + 2
        for (i, (label, checked)) in spec.enumerated() {
            cbLabel(label, checked: checked, x: sx, y: y, labelW: colW/2 - 12)
            if i % 2 == 1 { y += 8; sx = lx+2 } else { sx = lx + colW/2 }
        }

        // Körperschema rechts in der Spalte
        drawKoerperschema(vm: vm, x: lx + colW - 58, y: y0 + 12)

        // Rechte Spalte: Spezielle Traumen Label
        let rx2 = lx + colW + 2
        secHeader("Spezielle Traumen", x: rx2, y: y0, w: W - rx2 - 4)
        vline(lx + colW, y0, y - y0 + 8)
        hline(lx, y+8, W-8)
    }

    private static func drawKoerperschema(vm: VerletzungsMatrix, x: CGFloat, y: CGFloat) {
        func colorFor(_ g: Verletzungsgrad) -> UIColor {
            switch g {
            case .schwer: return UIColor(red:0.8, green:0.1, blue:0.1, alpha:0.7)
            case .leicht: return UIColor(red:1.0, green:0.6, blue:0.0, alpha:0.7)
            case .keine:  return UIColor(white: 0.88, alpha: 1)
            }
        }
        // Kopf (oval)
        let kopfR = CGRect(x: x+19, y: y, width: 14, height: 14)
        colorFor(vm.schaedelHirn).setFill()
        UIBezierPath(ovalIn: kopfR).fill()
        UIColor(white:0.4,alpha:1).setStroke()
        let kopfPath = UIBezierPath(ovalIn: kopfR); kopfPath.lineWidth = 0.5; kopfPath.stroke()

        // Hals/HWS
        fillR(CGRect(x: x+23, y: y+14, width: 6, height: 5), colorFor(vm.hws))
        strokeR(CGRect(x: x+23, y: y+14, width: 6, height: 5), lw: 0.4)

        // Rumpf (Thorax + Abdomen)
        let rumpfColor: UIColor = [vm.thorax, vm.abdomen].contains(.schwer) ? colorFor(.schwer) :
                                   [vm.thorax, vm.abdomen].contains(.leicht) ? colorFor(.leicht) : colorFor(.keine)
        fillR(CGRect(x: x+14, y: y+19, width: 24, height: 26), rumpfColor)
        strokeR(CGRect(x: x+14, y: y+19, width: 24, height: 26), lw: 0.4)

        // BWS/Becken (unter Rumpf)
        let beckenColor: UIColor = [vm.bwsLws, vm.becken].contains(.schwer) ? colorFor(.schwer) :
                                    [vm.bwsLws, vm.becken].contains(.leicht) ? colorFor(.leicht) : colorFor(.keine)
        fillR(CGRect(x: x+16, y: y+45, width: 20, height: 8), beckenColor)
        strokeR(CGRect(x: x+16, y: y+45, width: 20, height: 8), lw: 0.4)

        // Arme
        fillR(CGRect(x: x+3,  y: y+19, width: 9, height: 22), colorFor(vm.obereExtrem))
        strokeR(CGRect(x: x+3, y: y+19, width: 9, height: 22), lw: 0.4)
        fillR(CGRect(x: x+40, y: y+19, width: 9, height: 22), colorFor(vm.obereExtrem))
        strokeR(CGRect(x: x+40, y: y+19, width: 9, height: 22), lw: 0.4)

        // Beine
        fillR(CGRect(x: x+16, y: y+53, width: 8, height: 28), colorFor(vm.untereExtrem))
        strokeR(CGRect(x: x+16, y: y+53, width: 8, height: 28), lw: 0.4)
        fillR(CGRect(x: x+28, y: y+53, width: 8, height: 28), colorFor(vm.untereExtrem))
        strokeR(CGRect(x: x+28, y: y+53, width: 8, height: 28), lw: 0.4)
    }

    private static func drawSection5(protokoll: EinsatzProtokoll) {
        let d = protokoll.diagnose
        let rx = W * 0.55 + 4
        let y0: CGFloat = 4
        let w = W - rx - 4

        secHeader("5. Verlauf", x: rx, y: y0, w: w)
        strokeR(CGRect(x: rx, y: y0+10, width: w, height: 128))
        mtxt(d.verlauf, CGRect(x: rx+2, y: y0+12, width: w-4, height: 124), font: f6)
        vline(W * 0.55 + 2, y0, 138)
    }

    private static func drawVerlaufsgrafik(protokoll: EinsatzProtokoll) {
        let messungen = protokoll.verlaufMessungen.sorted { $0.zeitpunkt < $1.zeitpunkt }
        let lx: CGFloat = 4
        let y0: CGFloat = 143
        let h: CGFloat = 98
        let w = W - 8
        let labelW: CGFloat = 30
        let plotX = lx + labelW
        let plotW = w - labelW - 4

        // Rahmen
        strokeR(CGRect(x: lx, y: y0, width: w, height: h))

        // Header-Zeile
        fillR(CGRect(x: lx, y: y0, width: w, height: 8), cLight)
        txt("UHRZEIT", CGRect(x: lx+2, y: y0+1, width: 26, height: 6), font: f5b)
        hline(lx, y0+8, w)

        let plotY = y0 + 8
        let plotH = h - 8 - 8   // 8 header, 8 legend bottom

        // Y-Achse 60–260, 20er-Schritte
        let yMin: CGFloat = 60; let yMax: CGFloat = 260
        for val in stride(from: Int(yMin), through: Int(yMax), by: 20) {
            let fy = plotY + plotH * (1 - CGFloat(val - Int(yMin)) / CGFloat(yMax - yMin))
            hline(plotX-2, fy, plotW+2, lw: 0.15)
            txt("\(val)", CGRect(x: lx, y: fy-3, width: labelW-2, height: 6), font: f5, align: .right)
        }

        // Y-Achsen-Beschriftungen links
        let axisLabels: [(String, CGFloat)] = [
            ("Puls",  plotY + plotH * 0.1),
            ("RR",    plotY + plotH * 0.3),
            ("HF",    plotY + plotH * 0.5),
            ("HDM",   plotY + plotH * 0.65),
            ("Defi",  plotY + plotH * 0.78),
        ]
        for (label, fy) in axisLabels {
            txt(label, CGRect(x: lx+1, y: fy-3, width: labelW-3, height: 6), font: f5)
        }

        // Kurven zeichnen (nur wenn Messungen vorhanden)
        guard messungen.count >= 2 else {
            hline(lx, y0+h, w)
            return
        }
        let tMin = messungen.first!.zeitpunkt.timeIntervalSinceReferenceDate
        let tMax = max(messungen.last!.zeitpunkt.timeIntervalSinceReferenceDate, tMin + 60)
        let tRange = tMax - tMin

        func xFor(_ ti: TimeInterval) -> CGFloat {
            plotX + plotW * CGFloat((ti - tMin) / tRange)
        }
        func yFor(_ v: Int) -> CGFloat {
            plotY + plotH * (1 - CGFloat(v - Int(yMin)) / CGFloat(yMax - yMin))
        }

        func drawCurve(_ points: [CGPoint], color: UIColor, lw: CGFloat = 0.7) {
            guard points.count >= 2 else { return }
            color.setStroke()
            let path = UIBezierPath(); path.lineWidth = lw
            path.move(to: points[0])
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.stroke()
            color.setFill()
            points.forEach { p in
                UIBezierPath(ovalIn: CGRect(x: p.x-1.5, y: p.y-1.5, width: 3, height: 3)).fill()
            }
        }

        drawCurve(messungen.compactMap { m in m.puls.map { CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor($0)) } },
                  color: .red)
        drawCurve(messungen.compactMap { m in m.blutdruckSys.map { CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor($0)) } },
                  color: .blue)
        drawCurve(messungen.compactMap { m in m.blutdruckDia.map { CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor($0)) } },
                  color: UIColor(red:0.3, green:0.3, blue:1, alpha:1), lw: 0.5)
        drawCurve(messungen.compactMap { m in m.spo2.map { CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor($0)) } },
                  color: UIColor(red:0, green:0.6, blue:0, alpha:1))

        // Zeitstempel X-Achse
        for m in messungen {
            let x = xFor(m.zeitpunkt.timeIntervalSinceReferenceDate)
            vline(x, plotY, plotH, lw: 0.15)
            txt(t(m.zeitpunkt), CGRect(x: x-9, y: plotY+plotH+1, width: 20, height: 5), font: f5, align: .center)
        }

        // Legende
        let ly = y0 + h - 6
        UIColor.red.setFill();  UIRectFill(CGRect(x: plotX, y: ly+1, width: 10, height: 3))
        txt("Puls", CGRect(x: plotX+12, y: ly, width: 18, height: 6), font: f5)
        UIColor.blue.setFill(); UIRectFill(CGRect(x: plotX+34, y: ly+1, width: 10, height: 3))
        txt("RR sys", CGRect(x: plotX+46, y: ly, width: 22, height: 6), font: f5)
        UIColor(red:0.3,green:0.3,blue:1,alpha:1).setFill(); UIRectFill(CGRect(x: plotX+72, y: ly+1, width: 10, height: 3))
        txt("RR dia", CGRect(x: plotX+84, y: ly, width: 22, height: 6), font: f5)
        UIColor(red:0,green:0.6,blue:0,alpha:1).setFill(); UIRectFill(CGRect(x: plotX+110, y: ly+1, width: 10, height: 3))
        txt("SpO₂", CGRect(x: plotX+122, y: ly, width: 20, height: 6), font: f5)

        hline(lx, y0+h, w)
    }
    private static func drawSection6(protokoll: EinsatzProtokoll) {
        let m = protokoll.massnahmen
        let lx: CGFloat = 4
        let y0: CGFloat = 245
        let colW = (W-8) / 3

        secHeader("6. Maßnahmen", x: lx, y: y0, w: W-8)
        let y = y0 + 10

        // ── Spalte 1: Airway / Stabilisation ────────────────────────────────
        subHeader("Airway / Stabilisation", x: lx, y: y, w: colW)
        var y1 = y + 8.5
        for (l, c) in [
            ("Atemweg freimachen/freihalten", m.atemwegFreimachen),
            ("Cervikalstütze/HWS-Stabil.",   m.cervikalStuetze),
            ("Absaugung",                     m.absaugung),
            ("Sauerstoffgabe",                m.sauerstoffgabe),
            ("Maskenbeatmung",                m.maskenbeatmung),
            ("Maskenbeatm. unmöglich",        m.maskenbeatmungUnmoeglich),
            ("Supraglottisch",                m.supraglottisch),
            ("Guedel-Tubus",                  m.guedelTubus),
            ("Wendel-Tubus",                  m.wendlTubus),
            ("Intubation",                    protokoll.airway.intubiert),
            ("Konikotomie",                   protokoll.airway.konikotomie),
            ("Atemwegszugang erschwert",      m.atemwegErschwert),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: lx+2, y: y1, labelW: colW-12); y1 += 8 }
        if m.sauerstoffgabe && !m.sauerstoffLitMin.isEmpty {
            txt("O₂: \(m.sauerstoffLitMin) l/min", CGRect(x: lx+10, y: y1, width: colW-14, height: 7), font: f5b)
            y1 += 8
        }
        if m.maschinelleBeatmung {
            subHeader("Beatmung", x: lx, y: y1, w: colW); y1 += 8.5
            if !m.fio2.isEmpty       { txt("FiO₂: \(m.fio2)%",       CGRect(x: lx+2, y: y1, width: colW-4, height: 7), font: f5); y1 += 7 }
            if !m.peep.isEmpty       { txt("PEEP: \(m.peep)",         CGRect(x: lx+2, y: y1, width: colW-4, height: 7), font: f5); y1 += 7 }
            if !m.tidalvolumen.isEmpty { txt("AZV: \(m.tidalvolumen) ml", CGRect(x: lx+2, y: y1, width: colW-4, height: 7), font: f5); y1 += 7 }
        }

        // ── Spalte 2: Atmung + Zirkulation ──────────────────────────────────
        let x2 = lx + colW
        subHeader("Atmung", x: x2, y: y, w: colW)
        var y2 = y + 8.5
        for (l, c) in [
            ("Thoraxdrainage",       false),
            ("CPAP/NIV",             m.cpap),
            ("Maschinelle Beatmung", m.maschinelleBeatmung),
            ("Heimlich-Manöver",     m.heimlich),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: x2+2, y: y2, labelW: colW-12); y2 += 8 }

        y2 += 3
        subHeader("Cirkulation", x: x2, y: y2, w: colW); y2 += 8.5
        cbLabel("peripher-ven. Zugang", checked: m.peripherVenoes, x: x2+2, y: y2, labelW: colW-12); y2 += 8
        if m.peripherVenoes {
            let zugInfo = [m.peripherVenoesOrt, m.peripherVenoesGroesse.isEmpty ? "" : "\(m.peripherVenoesGroesse) G"]
                .filter { !$0.isEmpty }.joined(separator: "  ")
            if !zugInfo.isEmpty { txt(zugInfo, CGRect(x: x2+10, y: y2, width: colW-14, height: 7), font: f5); y2 += 7 }
        }
        cbLabel("intraossärer Zugang",  checked: m.intraossaer,    x: x2+2, y: y2, labelW: colW-12); y2 += 8
        if m.intraossaer && !m.intraossaerOrt.isEmpty {
            txt(m.intraossaerOrt, CGRect(x: x2+10, y: y2, width: colW-14, height: 7), font: f5); y2 += 7
        }
        cbLabel("Defibrillation",       checked: m.defibrillation, x: x2+2, y: y2, labelW: colW-12); y2 += 8
        if m.defibrillation {
            txt("\(m.defiAnzahl)× \(m.defiJoule) J", CGRect(x: x2+10, y: y2, width: colW-14, height: 7), font: f5); y2 += 7
        }
        cbLabel("Kardioversion",        checked: m.kardioversion,  x: x2+2, y: y2, labelW: colW-12); y2 += 8
        if m.kardioversion {
            txt("\(m.kardioversionJoule) J", CGRect(x: x2+10, y: y2, width: colW-14, height: 7), font: f5); y2 += 7
        }

        // ── Spalte 3: Weitere + Lagerung + Monitoring ────────────────────────
        let x3 = lx + 2*colW
        subHeader("Weitere Maßnahmen", x: x3, y: y, w: colW)
        var y3 = y + 8.5
        for (l, c) in [
            ("Kühlung",            m.kuehlung),
            ("Wärmeerhalt",        m.waermeerhalt),
            ("Entbindung",         m.entbindung),
            ("Krisenintervention", m.krisenintervention),
            ("Tourniquet",         m.tourniquet),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: x3+2, y: y3, labelW: colW-12); y3 += 8 }

        y3 += 3
        subHeader("Lagerung / Transport", x: x3, y: y3, w: colW); y3 += 8.5
        for (l, c) in [
            ("OK-Hochlagerung",       m.okHochlagerung),
            ("Flachlagerung",         m.flachlagerung),
            ("Schocklagerung",        m.schocklagerung),
            ("Linksseitenlage",       m.linksseitenlage),
            ("Vakuummatratze",        m.vakuummatratze),
            ("Schaufeltrage",         m.schaufeltrage),
            ("Extremitätenschienung", m.extremitaetenschienung),
            ("Verband",               m.verband),
            ("Beckenschlinge",        m.beckenschlinge),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: x3+2, y: y3, labelW: colW-12); y3 += 8 }

        y3 += 3
        subHeader("Monitoring", x: x3, y: y3, w: colW); y3 += 8.5
        for (l, c) in [
            ("EKG",          m.monEkg),
            ("12-Kanal-EKG", false),
            ("NIBP",         m.monNibp),
            ("BZ",           m.monBz),
            ("SpO₂",         m.monSpo2),
            ("Temperatur",   m.monTemperatur),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: x3+2, y: y3, labelW: colW-12); y3 += 7 }

        let s6Bottom = max(y1, y2, y3) + 4
        vline(x2, y+8.5, s6Bottom - y - 8.5)
        vline(x3, y+8.5, s6Bottom - y - 8.5)
        hline(lx, s6Bottom, W-8)
    }
    private static func drawSection65(protokoll: EinsatzProtokoll) {
        let meds = protokoll.medikamente
        let lx: CGFloat = 4
        let y0: CGFloat = 560
        let w = W * 0.55 - 2

        secHeader("6.5 Medikamente", x: lx, y: y0, w: w)

        // Spalten-Definition: (header, x-offset, width)
        let cols: [(String, CGFloat, CGFloat)] = [
            ("Medikament", 0,   88),
            ("Dosis",      88,  28),
            ("mg",         116, 20),
            ("ml",         136, 20),
            ("IE",         156, 20),
            ("Route",      176, 28),
            ("Zeit",       204, w-204),
        ]
        var y = y0 + 10
        // Header-Zeile
        for (header, xOff, cw) in cols {
            strokeR(CGRect(x: lx+xOff, y: y, width: cw, height: 8))
            txt(header, CGRect(x: lx+xOff+1.5, y: y+1, width: cw-3, height: 6), font: f5b)
        }
        y += 8

        let medTimeFmt = DateFormatter()
        medTimeFmt.dateFormat = "HH:mm"

        let maxRows = 8
        for i in 0..<maxRows {
            let med: MedikamentEintrag? = i < meds.count ? meds[i] : nil
            for (_, xOff, cw) in cols {
                strokeR(CGRect(x: lx+xOff, y: y, width: cw, height: 10))
            }
            if let med = med {
                txt(med.name,  CGRect(x: lx+1.5,   y: y+2, width: 86,  height: 7), font: f5)
                txt(med.dosis, CGRect(x: lx+89.5,  y: y+2, width: 26,  height: 7), font: f5)
                switch med.einheit {
                case "mg": txt(med.dosis, CGRect(x: lx+117.5, y: y+2, width: 18, height: 7), font: f5)
                case "ml": txt(med.dosis, CGRect(x: lx+137.5, y: y+2, width: 18, height: 7), font: f5)
                case "IE": txt(med.dosis, CGRect(x: lx+157.5, y: y+2, width: 18, height: 7), font: f5)
                default: break
                }
                txt(med.route, CGRect(x: lx+177.5, y: y+2, width: 26,  height: 7), font: f5)
                txt(medTimeFmt.string(from: med.zeit), CGRect(x: lx+205.5, y: y+2, width: w-207, height: 7), font: f5)
            }
            y += 10
        }
        hline(lx, y, w)
    }
    private static func drawSection7(protokoll: EinsatzProtokoll) {
        let rea = protokoll.reanimation
        let aktiv = protokoll.reanimationAktiv
        let rx = W * 0.55 + 2
        let y0: CGFloat = 560
        let w = W - rx - 4

        secHeader("7. Reanimation / Tod", x: rx, y: y0, w: w)
        var y = y0 + 10

        cbLabel("Beginn CPR",         checked: aktiv,             x: rx+2, y: y); y += 8
        cbLabel("Ersthelfer",         checked: rea.erstHelfer,    x: rx+2, y: y); y += 8
        cbLabel("Vorab Telefon-Rea.", checked: rea.vorabTelefonRea, x: rx+2, y: y); y += 8
        cbLabel("Rettungsdienst",     checked: aktiv,             x: rx+2, y: y); y += 8
        hline(rx, y, w); y += 2

        cbLabel("ROSC im Verlauf",    checked: rea.roscImVerlauf, x: rx+2,  y: y)
        cbLabel("niemals ROSC",       checked: rea.nieROSC,       x: rx+50, y: y); y += 8
        cbLabel("erfolgreiche Rea.",  checked: rea.erfolgreicheRea, x: rx+2, y: y); y += 8
        hline(rx, y, w); y += 2

        if let kz = rea.kollapsZeit {
            txt("Kollaps: \(t(kz))", CGRect(x: rx+2, y: y, width: w-4, height: 7), font: f5); y += 8
        }
        if rea.dnrOrder { cbLabel("DNR Order", checked: true, x: rx+2, y: y); y += 8 }

        hline(rx, y, w); y += 2
        if rea.defiAnzahl > 0 {
            cbLabel("Defibrillation", checked: true, x: rx+2, y: y); y += 8
            txt("Anzahl: \(rea.defiAnzahl)   \(rea.defiJoule) J",
                CGRect(x: rx+10, y: y, width: w-14, height: 7), font: f5); y += 8
        }
        if let tod = rea.todFeststellungsZeit {
            hline(rx, y, w); y += 2
            txt("Sterbezeitpunkt: \(t(tod))", CGRect(x: rx+2, y: y, width: w-4, height: 7), font: f5b)
        }

        vline(rx, y0, 120)
        hline(rx, y0+120, w)
    }
    private static func drawSection8(protokoll: EinsatzProtokoll) {
        let er = protokoll.ergebnis
        let lx: CGFloat = 4
        let y0: CGFloat = 684

        secHeader("8. Ergebnis", x: lx, y: y0, w: W*0.55)
        subHeader("Einsatzbesonderheiten", x: lx+W*0.55, y: y0, w: W*0.45-4)

        var y  = y0 + 10
        var y2 = y0 + 10

        for (l, c) in [
            ("ambulante Vers. vor Ort",         er.ambulantVorOrt),
            ("nächstes KH nicht aufnehmefähig", er.naechstesKHNichtErreichbar),
            ("Pat. nicht transportfähig",        er.patNichtTransportfaehig),
            ("Tod an Einsatzstelle",             er.todAnEinsatzstelle),
            ("Mitfahrverweigerung",              er.mifahrverweigerung),
            ("Zwangsunterbringung",              er.zwangsunterbringung),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: lx+2, y: y, labelW: W*0.55-14); y += 8 }

        let bx = lx + W*0.55 + 2
        for (l, c) in [
            ("LNA/OrgL im Einsatz",    er.lnaGrleimEinsatz),
            ("mehrere Patienten",      er.mehrerePatient),
            ("aufwendige Rettung",     er.aufwaendigeRettung),
            ("Infektionsschutz",       er.infektionsSchutz),
            ("Schwerlasttransport",    er.schwerlasttransport),
            ("Voranmeldung",           er.voranmeldung),
            ("Gelb Alarm",             er.gelbAlarm),
            ("Rot Alarm",              er.rotAlarm),
        ] as [(String,Bool)] { cbLabel(l, checked: c, x: bx, y: y2, labelW: W*0.45-14); y2 += 8 }

        vline(lx+W*0.55, y0, 70)
        hline(lx, y0+70, W-8)
    }
    private static func drawSection9(protokoll: EinsatzProtokoll) {
        let er = protokoll.ergebnis
        let lx: CGFloat = 4
        let y0: CGFloat = 758

        secHeader("9. Übergabe / Transportziel", x: lx, y: y0, w: W*0.65)
        secHeader("Bemerkungen", x: lx+W*0.65, y: y0, w: W*0.35-4)

        let cw3 = W*0.65 / 3
        var y = y0 + 10

        let ziele: [(String, Bool)] = [
            ("ZNA / INA",              er.transportzielZna),
            ("Herzkatheterlabor",       er.transportzielKathLabor),
            ("DP direkt",              false),
            ("Stroke Unit",            er.transportzielStrokeUnit),
            ("Intensivstation",        false),
            ("Fachambulanz",           false),
            ("CPU",                    false),
            ("Normalstation",          false),
            ("Sonstiges KH",           !er.transportzielSonstigesKH.isEmpty),
        ]
        for (i, (label, checked)) in ziele.enumerated() {
            let col = CGFloat(i % 3)
            let row = CGFloat(i / 3)
            cbLabel(label, checked: checked, x: lx+2+col*cw3, y: y+row*8, labelW: cw3-12)
        }
        y += CGFloat((ziele.count + 2) / 3) * 8

        if !er.transportzielSonstigesKH.isEmpty {
            txt(er.transportzielSonstigesKH, CGRect(x: lx+2, y: y, width: W*0.65-4, height: 7), font: f5b); y += 8
        }

        // Bemerkungen rechts
        let bx = lx + W*0.65 + 2
        mtxt(er.anmerkungen, CGRect(x: bx, y: y0+10, width: W*0.35-8, height: 48), font: f5)

        vline(lx+W*0.65, y0, 60)
        hline(lx, y0+60, W-8)
    }
    private static func drawNaca(protokoll: EinsatzProtokoll) {
        let naca = protokoll.notfallGeschehen.nacaScoreWert
        let lx: CGFloat = 4
        let y0: CGFloat = 820

        secHeader("NACA Score", x: lx, y: y0, w: W-8)
        var y = y0 + 10
        var x = lx + 2

        for i in 1...7 {
            let isSelected = naca?.rawValue == i
            let boxW: CGFloat = (W-12) / 7
            let boxR = CGRect(x: x, y: y, width: boxW-1, height: 10)
            fillR(boxR, isSelected ? UIColor(white:0.15, alpha:1) : .white)
            strokeR(boxR, lw: 0.4)
            let label: String
            switch i {
            case 1: label = "1 – Geringe Störung"
            case 2: label = "2 – Ambulante Behandlung"
            case 3: label = "3 – Stationär, keine Lebensgefahr"
            case 4: label = "4 – Lebensgefahr nicht ausgeschl."
            case 5: label = "5 – Akute Lebensgefahr"
            case 6: label = "6 – Reanimation"
            case 7: label = "7 – Tod"
            default: label = "\(i)"
            }
            txt(label, boxR.insetBy(dx: 2, dy: 1.5),
                font: f5, color: isSelected ? .white : .black)
            x += boxW
        }
        y += 10

        // Übergabe-Zeile
        hline(lx, y, W-8); y += 2
        txt("Übergabe an:", CGRect(x: lx+2, y: y+1, width: 46, height: 7), font: f5)
        txt(protokoll.uebergabeAn, CGRect(x: lx+50, y: y+1, width: 160, height: 7), font: f6b)
        txt("Unterschrift:", CGRect(x: W*0.5, y: y+1, width: 46, height: 7), font: f5)
        strokeR(CGRect(x: W*0.5+48, y: y, width: W*0.5-56, height: 12), lw: 0.4)

        hline(lx, y+12, W-8)
    }
}
