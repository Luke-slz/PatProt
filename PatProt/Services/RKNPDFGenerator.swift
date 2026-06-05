// PatProt/Services/RKNPDFGenerator.swift
import UIKit

struct RKNPDFGenerator {

    // MARK: - Seitenmaße
    static let W: CGFloat = 595
    static let H: CGFloat = 842

    // MARK: - Layout-Konstanten Seite 1
    // Berechnungsgrundlage:
    //   Header:    y=4,  endet ~32
    //   Section1:  y=33, endet ~94  (inkl. Besatzung rechts)
    //   Section2:  y=127, Höhe: 10(hdr)+7×13(Zeilen)=101 → endet 228
    //   Section3:  y=230, Höhe: ~218 (max col=Neurologie ~214+4) → endet ~448
    //   Section4:  y=450
    private static let p1HeaderY: CGFloat = 4
    private static let p1S1Y: CGFloat     = 33
    private static let p1S2Y: CGFloat     = 157
    private static let p1S3Y: CGFloat     = 262
    private static let p1S4Y: CGFloat     = 490

    // MARK: - Layout-Konstanten Seite 2
    // Linke Spalte (S4.2→S5→Graf→S65→S7→S8) wird dynamisch verkettet — kein festes y.
    // Rechte Spalte: S6 startet bei y=4, S9 folgt, NACA fest am Seitenende (H-50).

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

    /// Grauer Unterabschnitt-Header (Text zentriert)
    private static func subHeader(_ title: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 8.5) {
        fillR(CGRect(x: x, y: y, width: w, height: h), UIColor(white: 0.75, alpha: 1))
        txt(title, CGRect(x: x+2, y: y+1, width: w-4, height: h-2), font: f5b, color: .black, align: .center)
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
        txt(label, CGRect(x: x+1.5, y: y+0.5, width: w-3, height: 5), font: f5, color: UIColor(white: 0.3, alpha: 1))
        txt(value, CGRect(x: x+1.5, y: y+5.5, width: w-3, height: max(h-6, 6)), font: f6b)
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

    // MARK: - Seite 2 Layout-Konstanten
    // maaX = W*0.555+2 ≈ 332pt — Spaltentrennlinie
    private static let maaX: CGFloat = W * 0.555 + 2   // ≈ 332
    private static var maaW: CGFloat { W - maaX - 4 }  // ≈ 259

    // MARK: - Seite 2 (Dispatcher)
    private static func drawPage2(protokoll: EinsatzProtokoll) {
        fillR(CGRect(x: 0, y: 0, width: W, height: H))
        // Linke Spalte — dynamisch verketten, damit keine Überschneidungen entstehen
        var leftY = drawSection42(protokoll: protokoll, y0: 4) + 2
        leftY = drawSection5(protokoll: protokoll, y0: leftY) + 2
        leftY = drawVerlaufsgrafik(protokoll: protokoll, y0: leftY) + 2
        leftY = drawSection65(protokoll: protokoll, y0: leftY) + 2
        leftY = drawSection7(protokoll: protokoll, y0: leftY) + 2
        drawSection8(protokoll: protokoll, y0: leftY)
        // Rechte Spalte: NACA ganz unten, volle Breite, fest
        let nacaY: CGFloat = H - 50
        let s6Bottom = drawSection6(protokoll: protokoll)
        drawSection9(protokoll: protokoll, y0: s6Bottom, maxY: nacaY - 2)
        drawNaca(protokoll: protokoll, y0: nacaY)
        // Trennlinie linke / rechte Spalte
        vline(maaX, 4, H - 8)
        UIColor(white:0.2, alpha:1).setStroke()
        let b2 = UIBezierPath(rect: CGRect(x: 3, y: 3, width: W-6, height: H-6))
        b2.lineWidth = 0.6; b2.stroke()
    }

    // MARK: - Kopf (linke Spalte: KV + EINSATZPROTOKOLL)
    // Spaltenlayout: Links=4..221 (217pt) | Mitte=223..491 (268pt) | Rechts=493..591 (98pt)
    private static let hdrLW: CGFloat = 217   // Breite linke Spalte
    private static let hdrMX: CGFloat = 223   // Start Mittelspalte
    private static let hdrMW: CGFloat = 268   // Breite Mittelspalte
    private static let hdrGX: CGFloat = 493   // Start Zeitraster
    private static let hdrGW: CGFloat = 98    // Breite Zeitraster
    private static let hdrBottom: CGFloat = 157  // Unterkante Header+Section1 = Section2-Start

    private static func drawHeader(protokoll: EinsatzProtokoll) {
        let p = protokoll.patientDaten
        let e = protokoll.einsatzOrt
        let b = protokoll.besatzung
        let v = protokoll.verfasser
        let lx: CGFloat = 4
        let lw = hdrLW
        let nameStr = [p.nachname, p.vorname].filter { !$0.isEmpty }.joined(separator: ", ")
        let small = UIFont.systemFont(ofSize: 4.5)

        // ── KV-Personalienblock (y=4..52) ──
        labeledField("Krankenkasse bzw. Kostenträger", p.kostentraeger,       x: lx,     y: 4,  w: lw,      h: 12)
        labeledField("Name, Vorname des Versicherten", nameStr,               x: lx,     y: 16, w: lw-64,   h: 12)
        labeledField("geb. am",                        d(p.geburtsDatum),     x: lx+lw-64, y: 16, w: 64,   h: 12)
        labeledField("Kostenträgerkennung",             "",                   x: lx,     y: 28, w: 74,      h: 11)
        labeledField("Versicherten-Nr.",                p.versicherungsNummer, x: lx+74, y: 28, w: 80,      h: 11)
        labeledField("Status",                          "",                   x: lx+154, y: 28, w: lw-154,  h: 11)
        labeledField("Betriebsstätten-Nr.",             "",                   x: lx,     y: 39, w: 74,      h: 11)
        labeledField("Arzt-Nr.",                        "",                   x: lx+74,  y: 39, w: 68,      h: 11)
        labeledField("Datum",                           d(e.alarmzeit),       x: lx+142, y: 39, w: lw-142,  h: 11)
        hline(lx, 50, lw)

        // ── EINSATZPROTOKOLL-Block (y=50..157) ──
        // Titel + Notarzt/NetSan rechts auf gleicher Zeile
        txt("EINSATZPROTOKOLL", CGRect(x: lx+2, y: 51, width: 115, height: 10), font: f9b, color: .black)
        // Verfasser (klein, inline)
        txt("Verfasser:", CGRect(x: lx+2, y: 69.5, width: 36, height: 5), font: small)
        var qx = lx + 38
        for (label, val) in [("Notarzt", ProtokollVerfasser.arzt), ("NotSan", .notfallsanitaeter),
                              ("RS", .rettungssanitaeter), ("SanB", .sanitaeterB)] {
            cb(v == val, x: qx, y: 69.5, size: 4)
            txt(label, CGRect(x: qx+5, y: 69, width: 34, height: 5), font: small)
            qx += CGFloat(label.count) * 3.0 + 10
        }
        hline(lx, 75, lw)

        // Einsatznummer (volle Breite, auffällig)
        labeledField("Einsatznummer", e.einsatzNummer, x: lx, y: 75, w: lw, h: 12)

        // Stichwort / Einsatzart
        let stichStr = [e.stichwort, e.einsatzArt].filter { !$0.isEmpty }.joined(separator: " · ")
        labeledField("Stichwort / Einsatzart", stichStr, x: lx, y: 87, w: lw, h: 11)

        // Einsatzdatum | Standort RM | Geschlecht
        hline(lx, 98, lw)
        txt("Einsatzdatum", CGRect(x: lx+2, y: 99, width: 60, height: 5), font: small, color: UIColor(white:0.35,alpha:1))
        txt(d(e.alarmzeit), CGRect(x: lx+2, y: 104, width: 66, height: 7), font: f6b)
        txt("Standort RM",  CGRect(x: lx+70, y: 99, width: 60, height: 5), font: small, color: UIColor(white:0.35,alpha:1))
        txt(e.fahrzeugName, CGRect(x: lx+70, y: 104, width: 90, height: 7), font: f5b)
        cb(p.geschlecht == .maennlich, x: lx+163, y: 101, size: 5)
        txt("m", CGRect(x: lx+170, y: 100.5, width: 12, height: 6), font: f5)
        cb(p.geschlecht == .weiblich,  x: lx+181, y: 101, size: 5)
        txt("w", CGRect(x: lx+188, y: 100.5, width: 12, height: 6), font: f5)
        hline(lx, 111, lw)

        // Einsatzind. | Fehleinsatz | □Einsatzabbruch □Transportverweigerung
        labeledField("Einsatzind.", "", x: lx,    y: 111, w: 42, h: 11)
        labeledField("Fehleinsatz", "", x: lx+42, y: 111, w: 42, h: 11)
        cbLabel("Einsatzabbruch",       checked: false, x: lx+88,  y: 113, cbSize: 4, labelW: 58)
        cbLabel("Transportverweig.",    checked: false, x: lx+88,  y: 120, cbSize: 4, labelW: 62)
        hline(lx, 122, lw)

        // Notarznummer | Abrechnungsnummer
        labeledField("Notarznummer",      "", x: lx,     y: 122, w: 110, h: 11)
        labeledField("Abrechnungsnummer", "", x: lx+110, y: 122, w: lw-110, h: 11)
        hline(lx, 133, lw)

        // Besatzung
        txt("Besatzung:", CGRect(x: lx+2, y: 134, width: 36, height: 6), font: f5b)
        let besStr = [(b.sanitaeter1, b.qualifikation1),(b.sanitaeter2, b.qualifikation2),
                      (b.sanitaeter3, b.qualifikation3),(b.sanitaeter4, b.qualifikation4)]
            .filter { !$0.0.isEmpty }.map { "\($0.0) (\($0.1.rawValue))" }.joined(separator: ", ")
        txt(besStr, CGRect(x: lx+38, y: 134, width: lw-42, height: 11), font: f5)

        // Trennlinie linke/rechte Spalte
        vline(lx+lw, 4, hdrBottom-4)
    }

    private static func drawSection1(protokoll: EinsatzProtokoll) {
        let e  = protokoll.einsatzOrt
        let b  = protokoll.besatzung
        let mx = hdrMX
        let mw = hdrMW
        let gx = hdrGX
        let gw = hdrGW
        let bot = hdrBottom
        let small = UIFont.systemFont(ofSize: 4.5)

        // ══ MITTELSPALTE: 1. Rettungstechnische Daten ════════════════════════
        secHeader("1. Rettungstechnische Daten", x: mx, y: 4, w: mw)

        // □RTW □KTW □NEF □NAW □BabyNAW □V-RTW
        let fz = e.fahrzeugName.uppercased()
        let isVRTW = fz.contains("V-RTW") || fz.contains("VRTW")
        let fahrzeuge: [(String, Bool)] = [
            ("RTW",     fz.contains("RTW") && !isVRTW),
            ("KTW",     fz.contains("KTW")),
            ("NEF",     fz.contains("NEF")),
            ("NAW",     fz.contains("NAW") && !fz.contains("BABY")),
            ("Baby NAW",fz.contains("BABY")),
            ("V-RTW",   isVRTW),
            ("FR",      fz.contains("FR")),
        ]
        var cx = mx + 2
        for (label, checked) in fahrzeuge {
            cb(checked, x: cx, y: 15, size: 5)
            txt(label, CGRect(x: cx+6, y: 14.7, width: 38, height: 6), font: f5b)
            cx += label.count > 3 ? 42 : 30
        }
        hline(mx, 22, mw)

        var y: CGFloat = 22
        // Dokumentierendes RM | Weiteres RM
        labeledField("Dokumentierendes Rettungsmittel", e.fahrzeugName,
                     x: mx, y: y, w: mw*0.5, h: 12)
        labeledField("Weiteres Rettungsmittel", e.weitereEinsatzmittel.joined(separator: ", "),
                     x: mx+mw*0.5, y: y, w: mw*0.5, h: 12); y += 12

        // E-Ort: Art | Einsatzort: Objekt aus Stammdaten
        labeledField("E-Ort: Art", e.einsatzArt, x: mx, y: y, w: mw*0.2, h: 12)
        labeledField("Einsatzort: Objekt aus Stammdaten", e.stichwort,
                     x: mx+mw*0.2, y: y, w: mw*0.8, h: 12); y += 12

        // Einsatzort Straße | Haus-Nr.
        labeledField("Straße", e.adresse, x: mx, y: y, w: mw*0.72, h: 12)
        labeledField("Haus-Nr.", e.zusatz, x: mx+mw*0.72, y: y, w: mw*0.28, h: 12); y += 12
        // PLZ | Ort
        labeledField("PLZ", e.plz, x: mx, y: y, w: mw*0.28, h: 12)
        labeledField("Ort", e.ort, x: mx+mw*0.28, y: y, w: mw*0.72, h: 12); y += 12

        // Transportziel (leer)
        labeledField("Transportziel: Objekt aus Stammdaten", "", x: mx, y: y, w: mw, h: 12); y += 12
        labeledField("Straße", "", x: mx, y: y, w: mw*0.72, h: 12)
        labeledField("Haus-Nr.", "", x: mx+mw*0.72, y: y, w: mw*0.28, h: 12); y += 12
        labeledField("PLZ", "", x: mx, y: y, w: mw*0.28, h: 12)
        labeledField("Ort", "", x: mx+mw*0.28, y: y, w: mw*0.72, h: 12); y += 12

        // NotSan/RettAss/RS | NotSan/RettAss/RS
        let be1 = b.sanitaeter1.isEmpty ? "" : "\(b.sanitaeter1) (\(b.qualifikation1.rawValue))"
        let be2 = b.sanitaeter2.isEmpty ? "" : "\(b.sanitaeter2) (\(b.qualifikation2.rawValue))"
        labeledField("NotSan/RettAss/RS", be1, x: mx,        y: y, w: mw*0.5, h: 12)
        labeledField("NotSan/RettAss/RS", be2, x: mx+mw*0.5, y: y, w: mw*0.5, h: 12); y += 12

        // NA | Praktikant
        labeledField("NA", "", x: mx,        y: y, w: mw*0.5, h: 12)
        labeledField("Praktikant", "", x: mx+mw*0.5, y: y, w: mw*0.5, h: 12); y += 12

        // Vorsorgebevollmächtigter | Name/Telefon
        labeledField("Vorsorgebevollmächtigter/Betreuer", "", x: mx,        y: y, w: mw*0.6, h: min(14, bot-y))
        labeledField("Name/Telefonnummer",                "", x: mx+mw*0.6, y: y, w: mw*0.4, h: min(14, bot-y))

        // Trennlinie Mitte/Rechts
        vline(gx-2, 4, bot-4)

        // ══ RECHTSSPALTE: Sondersignal + Zeitraster ══════════════════════════
        // Sondersignal / Hin / mit Patient
        cbLabel("Sondersignal", checked: e.sondersignal, x: gx+1, y: 5,  cbSize: 4, labelW: 30)
        cbLabel("Hin",          checked: e.mitPatient,   x: gx+1, y: 11, cbSize: 4, labelW: 12)
        cbLabel("mit Patient",  checked: e.mitPatient,   x: gx+18,y: 11, cbSize: 4, labelW: 32)
        cbLabel("Notarzt nachgefordert", checked: e.naAngefordert,  x: gx+1, y: 17, cbSize: 4, labelW: 64)
        hline(gx-2, 23, gw+2)
        txt("Uhrzeit", CGRect(x: gx+45, y: 24, width: gw-46, height: 5), font: small, align: .center)
        hline(gx-2, 30, gw+2)

        // Zeitraster-Zeilen
        let grH: CGFloat = 10
        let lblW: CGFloat = 44
        let valW = gw - lblW
        var gy: CGFloat = 30
        let zeilen: [(String, String)] = [
            ("Alarm",         t(e.alarmzeit)),
            ("Ausfahrt",      t(e.ausfahrtzeit)),
            ("Ankunft",       t(e.ankunftzeit)),
            ("Abfahrt",       t(e.abfahrtzeit)),
            ("Übergabe",      t(e.uebergabeZeit ?? e.krankenHausAnkunft)),
            ("Einsatzbereit", t(e.einsatzbereitZeit)),
            ("Ende",          t(e.endeZeit)),
        ]
        for (label, val) in zeilen {
            fillR(CGRect(x: gx,   y: gy, width: lblW, height: grH), cLight)
            strokeR(CGRect(x: gx, y: gy, width: lblW, height: grH), lw: 0.3)
            txt(label, CGRect(x: gx+2, y: gy+2, width: lblW-3, height: 5), font: small)
            strokeR(CGRect(x: gx+lblW, y: gy, width: valW, height: grH), lw: 0.3)
            txt(val, CGRect(x: gx+lblW+1, y: gy+2, width: valW-2, height: 5), font: f5b, align: .center)
            gy += grH
        }
        // km Gesamt / km Patient (einspaltig)
        for (label, val) in [("km\nGesamt", e.kmGesamt), ("km\nPatient", e.kmPatient)] {
            fillR(CGRect(x: gx,      y: gy, width: lblW, height: grH), cLight)
            strokeR(CGRect(x: gx,    y: gy, width: lblW, height: grH), lw: 0.3)
            txt(label, CGRect(x: gx+2, y: gy+1.5, width: lblW-3, height: 7), font: small)
            strokeR(CGRect(x: gx+lblW, y: gy, width: gw-lblW, height: grH), lw: 0.3)
            txt(val,   CGRect(x: gx+lblW+2, y: gy+2, width: gw-lblW-4, height: 5), font: f5b)
            gy += grH
        }

        // Abschlusskante (volle Breite)
        hline(4, bot, W-8)
    }
    private static func drawSection2(protokoll: EinsatzProtokoll) {
        let lx: CGFloat = 4
        let y0: CGFloat = 157   // under section 1 bottom line

        secHeader("2. Notfallgeschehen / Anamnese / Erstbefund", x: lx, y: y0, w: W-8)

        // Komponierter Fließtext: Geschehen → ABCDE → SAMPLER (+ MANV)
        let text = section2Text(protokoll)
        let boxY = y0 + 10
        let boxH: CGFloat = 91          // 7 Zeilen × 13 → Section 3 bleibt bei 230
        strokeR(CGRect(x: lx, y: boxY, width: W-8, height: boxH))
        mtxt(text, CGRect(x: lx+3, y: boxY+2, width: W-14, height: boxH-4), font: f6)
    }

    /// Komponiert den Anamnese-/Befund-Fließtext für Sektion 2.
    private static func section2Text(_ p: EinsatzProtokoll) -> String {
        let ng = p.notfallGeschehen
        let s  = p.sampler
        var blocks: [String] = []

        // ── Was passiert ist ──
        var geschehen: [String] = []
        if ng.manv {
            let sk = ng.manvGesamtSK
            geschehen.append("MANV" + (sk > 0 ? " (\(sk) Betroffene)" : ""))
        }
        for v in [s.ereignis, ng.erstbefundVorOrt, ng.patientGefunden,
                  ng.unfallhergangFreitext, ng.unfallmechanismusFreitext, ng.notfallFreitext]
            where !v.isEmpty { geschehen.append(v) }
        if !geschehen.isEmpty { blocks.append("Geschehen: " + geschehen.joined(separator: "; ")) }

        // ── ABCDE ──
        let a = p.airway, b = p.breathing, c = p.circulation, di = p.disability, ex = p.exposure
        var abcde: [String] = []
        do {  // A
            var t: [String] = []
            if a.verlegung { t.append("Atemweg verlegt") } else if a.status != .unbewertet && a.freiheit { t.append("Atemweg frei") }
            if a.intubiert { t.append("intubiert") }
            if a.konikotomie { t.append("Koniotomie") }
            if !a.freitext.isEmpty { t.append(a.freitext) }
            if !t.isEmpty { abcde.append("A: " + t.joined(separator: ", ")) }
        }
        do {  // B
            var t: [String] = []
            if let f = b.atemFrequenz { t.append("AF \(f)") }
            if let sp = b.spo2 { t.append("SpO₂ \(sp)%") }
            if b.dyspnoe { t.append("Dyspnoe") }
            if b.zyanose { t.append("Zyanose") }
            if !b.atemgeraeusche.isEmpty { t.append(b.atemgeraeusche) }
            if !b.freitext.isEmpty { t.append(b.freitext) }
            if !t.isEmpty { abcde.append("B: " + t.joined(separator: ", ")) }
        }
        do {  // C
            var t: [String] = []
            if let pu = c.puls { t.append("HF \(pu)") }
            if let sys = c.blutdruckSystolisch, let dia = c.blutdruckDiastolisch { t.append("RR \(sys)/\(dia)") }
            if !c.pulsRhythmus.isEmpty { t.append(c.pulsRhythmus) }
            if c.blutung { t.append("Blutung" + (c.blutungLokalisation.isEmpty ? "" : " \(c.blutungLokalisation)")) }
            if !c.freitext.isEmpty { t.append(c.freitext) }
            if !t.isEmpty { abcde.append("C: " + t.joined(separator: ", ")) }
        }
        do {  // D
            var t: [String] = []
            if di.status != .unbewertet { t.append("GCS \(di.gcsGesamt)") }
            if di.bewusstlos { t.append("bewusstlos") }
            if let bz = di.blutzucker { t.append("BZ \(String(format: "%.0f", bz))") }
            if !di.freitext.isEmpty { t.append(di.freitext) }
            if !t.isEmpty { abcde.append("D: " + t.joined(separator: ", ")) }
        }
        do {  // E
            var t: [String] = []
            if let tp = ex.temperatur { t.append("Temp \(String(format: "%.1f", tp))°C") }
            if !ex.hautfarbe.isEmpty { t.append("Haut \(ex.hautfarbe)") }
            if !ex.verletzungen.isEmpty { t.append(ex.verletzungen) }
            if !ex.freitext.isEmpty { t.append(ex.freitext) }
            if !t.isEmpty { abcde.append("E: " + t.joined(separator: ", ")) }
        }
        if !abcde.isEmpty { blocks.append("ABCDE: " + abcde.joined(separator: "  ")) }

        // ── SAMPLER ──
        var sampler: [String] = []
        func addS(_ key: String, _ val: String, _ unbekannt: Bool) {
            if unbekannt { sampler.append("\(key): unbek.") }
            else if !val.isEmpty { sampler.append("\(key): \(val)") }
        }
        addS("S", s.symptome, false)
        addS("A", s.allergien, s.allergienUnbekannt)
        addS("M", s.medikamente, s.medikamenteUnbekannt)
        addS("P", s.patientenVorgeschichte, s.patientenVorgeschichteUnbekannt)
        var lParts: [String] = []
        if s.letztesMahlUnbekannt { lParts.append("Mahlzeit unbek.") } else if !s.letztesMahl.isEmpty { lParts.append("Mahlzeit \(s.letztesMahl)") }
        if s.letzteRegelblutungUnbekannt { lParts.append("Regel unbek.") } else if !s.letzteRegelblutung.isEmpty { lParts.append("Regel \(s.letzteRegelblutung)") }
        if !lParts.isEmpty { sampler.append("L: " + lParts.joined(separator: ", ")) }
        addS("E", s.ereignis, false)
        addS("R", s.risikofaktoren, s.risikofaktorenUnbekannt)
        if s.schwangerschaft {
            sampler.append("Schwanger" + (s.schwangerschaftSSW > 0 ? " (\(s.schwangerschaftSSW). SSW)" : ""))
        }
        if !sampler.isEmpty { blocks.append("SAMPLER — " + sampler.joined(separator: "; ")) }

        return blocks.joined(separator: "\n")
    }

    /// Draw a standalone checkbox (square with optional fill) at exact position.
    private static func drawCb(_ checked: Bool, x: CGFloat, y: CGFloat, size: CGFloat) {
        let r = CGRect(x: x, y: y, width: size, height: size)
        if checked {
            UIColor(white: 0.15, alpha: 1).setFill()
            UIRectFill(r)
        } else {
            UIColor.white.setFill()
            UIRectFill(r)
        }
        UIColor(white: 0.2, alpha: 1).setStroke()
        let p = UIBezierPath(rect: r)
        p.lineWidth = 0.5
        p.stroke()
        if checked {
            UIColor.white.setStroke()
            let cross = UIBezierPath()
            cross.move(to: CGPoint(x: x+1.5, y: y+1.5))
            cross.addLine(to: CGPoint(x: x+size-1.5, y: y+size-1.5))
            cross.move(to: CGPoint(x: x+size-1.5, y: y+1.5))
            cross.addLine(to: CGPoint(x: x+1.5, y: y+size-1.5))
            cross.lineWidth = 1.0
            cross.stroke()
        }
    }
    private static func drawSection3(protokoll: EinsatzProtokoll) {
        let ub = protokoll.uebergabeBefunde          // Übergabe-Befunde (rechte CB-Spalte)
        let um = protokoll.uebergabeMesswerte        // Übergabe-Messwerte
        let br = protokoll.breathing                  // Ankunft A+B
        let ci = protokoll.circulation                // Ankunft C
        let di = protokoll.disability                 // Ankunft D
        let ps = protokoll.psyche                     // Psyche
        let ex = protokoll.exposure                   // Haut (in Col 3)
        let lx: CGFloat = 4
        let y0: CGFloat = 262   // unter Section2

        // ── Maße ─────────────────────────────────────────────────────────────
        let colW: CGFloat = (W - 8) / 5   // ≈ 117.4 pt
        let rowH: CGFloat = 6.5
        let cbSz: CGFloat = 5.0
        let tinyF = UIFont.systemFont(ofSize: 4.5)
        let shH: CGFloat  = 8.5           // sub-header height (einfach)
        let dshH: CGFloat = 15.0          // doppelzeiliger sub-header für A+B / C / D

        // Hilfsfunktionen (nutzen die col-lokalen ankXRel/uebXRel)
        let ankXRel: CGFloat = 5    // Einrückung links vom Spaltenrand
        let uebXRelFn: (CGFloat) -> CGFloat = { cw in cw - cbSz - 5 }  // Einrückung rechts
        let lblXRel = ankXRel + cbSz + 1.5

        // Zeile: [Ankunft-cb] [Label zentriert] [Übergabe-cb] innerhalb einer Spalte
        func dualCb(_ label: String, ank: Bool, ueb: Bool, colX: CGFloat, colWid: CGFloat = colW, rowY: CGFloat) {
            let uebX = uebXRelFn(colWid)
            let lblW = uebX - lblXRel - 1
            cb(ank, x: colX + ankXRel, y: rowY, size: cbSz)
            txt(label, CGRect(x: colX + lblXRel, y: rowY - 0.3, width: lblW, height: 6), font: f5, align: .center)
            cb(ueb, x: colX + uebX, y: rowY, size: cbSz)
        }

        // Sub-header mit zweizeiligem Layout: Zeile1 = Titel, Zeile2 = "Ankunft □ unauff. □ Übergabe"
        func dualSubHeader(_ title: String, colX: CGFloat, ankUnauff: Bool, uebUnauff: Bool, startY: CGFloat) {
            fillR(CGRect(x: colX, y: startY, width: colW, height: dshH), UIColor(white: 0.75, alpha: 1))
            // Zeile 1: Spaltenname (zentriert)
            txt(title, CGRect(x: colX+2, y: startY+1, width: colW-4, height: 6), font: f5b, align: .center)
            // Zeile 2: Ankunft □  unauffällig  □ Übergabe — CBs mehr zur Mitte verschoben
            let r2y = startY + 8
            let cbSz2: CGFloat = 4.5
            // Layout: Ankunft  [ankCb] unauffällig [uebCb]  Übergabe
            // CBs direkt neben "unauffällig", Labels außen
            let unauffW: CGFloat = 26
            let unauffX = colX + (colW - unauffW) / 2   // zentriert in der Spalte
            let ankCbX2 = unauffX - cbSz2 - 1
            let uebCbX2 = unauffX + unauffW + 1
            txt("Ankunft",     CGRect(x: colX+3, y: r2y+0.5, width: ankCbX2-colX-5, height: 4.5), font: tinyF)
            cb(ankUnauff,  x: ankCbX2, y: r2y, size: cbSz2)
            txt("unauffällig", CGRect(x: unauffX, y: r2y+0.5, width: unauffW, height: 4.5), font: tinyF, align: .center)
            cb(uebUnauff,  x: uebCbX2, y: r2y, size: cbSz2)
            txt("Übergabe",    CGRect(x: uebCbX2+cbSz2+1, y: r2y+0.5, width: colX+colW-3-(uebCbX2+cbSz2+1), height: 4.5), font: tinyF)
        }

        // ── Sektion-Header mit "Messwerte □ keine" im linken Teil ────────────
        secHeader("3. Befunde", x: lx, y: y0, w: W-8)
        // Overlay: "Messwerte □ keine" im linken Sub-Bereich der Header-Zeile
        let hdrY = y0 + 1.5
        txt("Messwerte", CGRect(x: lx + colW*0.35, y: hdrY, width: 50, height: 6), font: f6b, color: .white)
        txt("keine", CGRect(x: lx + colW*0.35 + 52, y: hdrY + 0.5, width: 30, height: 5), font: tinyF, color: .white)
        cb(false, x: lx + colW*0.35 + 50, y: hdrY + 0.5, size: 4.5)

        let y = y0 + 10

        // ─────────────────────────────────────────────────────────────────────
        // SPALTE 1: Messwerte
        // ─────────────────────────────────────────────────────────────────────
        let x1 = lx
        // Sub-header für Col 1: Label/Ankunft/Übergabe Spalten
        let mwAnkW: CGFloat = (colW * 0.37)
        let mwUebW: CGFloat = (colW * 0.37)
        let mwLblW: CGFloat = colW - mwAnkW - mwUebW
        fillR(CGRect(x: x1, y: y, width: colW, height: shH), UIColor(white: 0.75, alpha: 1))
        txt("Ankunft",  CGRect(x: x1 + mwLblW,          y: y+2, width: mwAnkW, height: 5), font: tinyF, align: .center)
        txt("Übergabe", CGRect(x: x1 + mwLblW + mwAnkW, y: y+2, width: mwUebW, height: 5), font: tinyF, align: .center)

        var y1 = y + shH

        func numStr(_ v: Int?) -> String { v.map { "\($0)" } ?? "" }
        func dblStr(_ v: Double?, _ f: String = "%.0f") -> String { v.map { String(format: f, $0) } ?? "" }

        // Messwert-Zeile zeichnen
        func mwRow(_ label: String, _ va: String, _ vu: String, atY: CGFloat) {
            strokeR(CGRect(x: x1, y: atY, width: mwLblW, height: 9))
            strokeR(CGRect(x: x1+mwLblW, y: atY, width: mwAnkW, height: 9))
            strokeR(CGRect(x: x1+mwLblW+mwAnkW, y: atY, width: mwUebW, height: 9))
            txt(label, CGRect(x: x1+2, y: atY+2, width: mwLblW-3, height: 6),
                font: f5, color: UIColor(white:0.35, alpha:1))
            txt(va, CGRect(x: x1+mwLblW+1,         y: atY+1.5, width: mwAnkW-2, height: 7), font: f6b, align: .center)
            txt(vu, CGRect(x: x1+mwLblW+mwAnkW+1,  y: atY+1.5, width: mwUebW-2, height: 7), font: f6b, align: .center)
        }

        // Messwert-Zeile mit "regelm. □ja □nein" Sub-Zeile
        func mwRowRegelm(_ label: String, _ va: String, _ vu: String,
                         ankRegelm: Bool, uebRegelm: Bool, atY: CGFloat) -> CGFloat {
            let mainH: CGFloat = 9
            let subH:  CGFloat = 6
            // Rahmen Label-Spalte: mainH+subH hoch
            strokeR(CGRect(x: x1, y: atY, width: mwLblW, height: mainH + subH))
            // Rahmen Wert-Spalten
            strokeR(CGRect(x: x1+mwLblW, y: atY, width: mwAnkW, height: mainH + subH))
            strokeR(CGRect(x: x1+mwLblW+mwAnkW, y: atY, width: mwUebW, height: mainH + subH))
            // Trennlinie horizontal nach mainH
            hline(x1, atY + mainH, colW)
            // Wert-Text
            txt(label, CGRect(x: x1+2, y: atY+2, width: mwLblW-3, height: 6),
                font: f5, color: UIColor(white:0.35, alpha:1))
            txt(va, CGRect(x: x1+mwLblW+1,         y: atY+1.5, width: mwAnkW-2, height: 7), font: f6b, align: .center)
            txt(vu, CGRect(x: x1+mwLblW+mwAnkW+1,  y: atY+1.5, width: mwUebW-2, height: 7), font: f6b, align: .center)
            // Sub-Zeile: "regelm. □ja □nein"
            txt("regelm.", CGRect(x: x1+2, y: atY+mainH+0.5, width: mwLblW-3, height: 5), font: tinyF)
            // Ankunft Seite: □ja □nein
            let jaN: CGFloat = 4.0
            let ankCbX = x1 + mwLblW + 1
            cb(ankRegelm,  x: ankCbX,        y: atY+mainH+0.5, size: jaN)
            txt("ja",  CGRect(x: ankCbX+jaN+0.5,   y: atY+mainH+0.5, width: 8, height: 5), font: tinyF)
            cb(!ankRegelm, x: ankCbX+jaN+9,  y: atY+mainH+0.5, size: jaN)
            txt("nein",CGRect(x: ankCbX+jaN*2+9.5, y: atY+mainH+0.5, width: 10, height: 5), font: tinyF)
            // Übergabe Seite: □ja □nein
            let uebCbX = x1 + mwLblW + mwAnkW + 1
            cb(uebRegelm,  x: uebCbX,        y: atY+mainH+0.5, size: jaN)
            txt("ja",  CGRect(x: uebCbX+jaN+0.5,   y: atY+mainH+0.5, width: 8, height: 5), font: tinyF)
            cb(!uebRegelm, x: uebCbX+jaN+9,  y: atY+mainH+0.5, size: jaN)
            txt("nein",CGRect(x: uebCbX+jaN*2+9.5, y: atY+mainH+0.5, width: 10, height: 5), font: tinyF)
            return atY + mainH + subH
        }

        // Messwert-Zeile mit "mit O₂ □ja □nein" Sub-Zeile
        func mwRowO2(_ label: String, _ va: String, _ vu: String,
                     ankO2: Bool, uebO2: Bool, atY: CGFloat) -> CGFloat {
            let mainH: CGFloat = 9
            let subH:  CGFloat = 6
            strokeR(CGRect(x: x1, y: atY, width: mwLblW, height: mainH + subH))
            strokeR(CGRect(x: x1+mwLblW, y: atY, width: mwAnkW, height: mainH + subH))
            strokeR(CGRect(x: x1+mwLblW+mwAnkW, y: atY, width: mwUebW, height: mainH + subH))
            hline(x1, atY + mainH, colW)
            txt(label, CGRect(x: x1+2, y: atY+2, width: mwLblW-3, height: 6),
                font: f5, color: UIColor(white:0.35, alpha:1))
            txt(va, CGRect(x: x1+mwLblW+1,         y: atY+1.5, width: mwAnkW-2, height: 7), font: f6b, align: .center)
            txt(vu, CGRect(x: x1+mwLblW+mwAnkW+1,  y: atY+1.5, width: mwUebW-2, height: 7), font: f6b, align: .center)
            txt("mit O₂", CGRect(x: x1+2, y: atY+mainH+0.5, width: mwLblW-3, height: 5), font: tinyF)
            let jaN: CGFloat = 4.0
            let ankCbX = x1 + mwLblW + 1
            cb(ankO2,  x: ankCbX,       y: atY+mainH+0.5, size: jaN)
            txt("ja", CGRect(x: ankCbX+jaN+0.5,   y: atY+mainH+0.5, width: 8, height: 5), font: tinyF)
            cb(!ankO2, x: ankCbX+jaN+9, y: atY+mainH+0.5, size: jaN)
            txt("nein",CGRect(x: ankCbX+jaN*2+9.5,y: atY+mainH+0.5, width: 10, height: 5), font: tinyF)
            let uebCbX = x1 + mwLblW + mwAnkW + 1
            cb(uebO2,  x: uebCbX,       y: atY+mainH+0.5, size: jaN)
            txt("ja", CGRect(x: uebCbX+jaN+0.5,   y: atY+mainH+0.5, width: 8, height: 5), font: tinyF)
            cb(!uebO2, x: uebCbX+jaN+9, y: atY+mainH+0.5, size: jaN)
            txt("nein",CGRect(x: uebCbX+jaN*2+9.5,y: atY+mainH+0.5, width: 10, height: 5), font: tinyF)
            return atY + mainH + subH
        }

        // RR SYS
        mwRow("RR SYS", numStr(ci.blutdruckSystolisch), um.rrSys, atY: y1); y1 += 9
        // RR DIA
        mwRow("RR DIA", numStr(ci.blutdruckDiastolisch), um.rrDia, atY: y1); y1 += 9
        // HF mit regelm. sub-row
        y1 = mwRowRegelm("HF", numStr(ci.puls), um.hf,
                         ankRegelm: ci.pulsRhythmus == "regelmäßig",
                         uebRegelm: false, atY: y1)
        // SpO₂ mit O₂ sub-row
        y1 = mwRowO2("SpO₂", numStr(br.spo2), um.spo2,
                     ankO2: br.sauerstoffGabe, uebO2: false, atY: y1)
        // AF
        mwRow("AF", numStr(br.atemFrequenz), um.af, atY: y1); y1 += 9
        // etCO₂
        mwRow("etCO₂", "", "", atY: y1); y1 += 9
        // BZ
        mwRow("BZ", dblStr(di.blutzucker), um.bz, atY: y1); y1 += 9
        // Temp.
        mwRow("Temp.", dblStr(ex.temperatur, "%.1f"), um.temp, atY: y1); y1 += 9

        // Col 1 endet nach Messwerten — Schmerz ist in Col 2 (unter Atmung)

        // ─────────────────────────────────────────────────────────────────────
        // SPALTE 2: A+B Atmung
        // ─────────────────────────────────────────────────────────────────────
        let x2 = lx + colW
        dualSubHeader("A+B Atmung", colX: x2, ankUnauff: false, uebUnauff: ub.abUnauffaellig, startY: y)
        var y2 = y + dshH

        let atmung: [(String, Bool, Bool)] = [
            ("Dyspnoe",           br.dyspnoe,            ub.dyspnoe),
            ("Zyanose",           br.zyanose,            ub.zyanose),
            ("Spastik",           br.spastik,            ub.spastik),
            ("Rasselgeräusche",   br.rasselgeraeusche,   ub.rasselgeraeusche),
            ("Stridor",           br.stridor,            ub.stridor),
            ("Atemwegsverlegung", protokoll.airway.verlegung, ub.atemwegsverlegung),
            ("Schnappatmung",     br.schnappatmung,      ub.schnappatmung),
            ("Apnoe",             br.apnoe,              ub.apnoe),
            ("Beatmung",          br.beatmung,           ub.beatmung),
            ("Hyperventilation",  br.hyperventilation,   ub.hyperventilation),
            ("Sonstige",          false,                 false),
            ("n. beurteilbar",    br.abNichtBeurteilbar, ub.abNichtBeurteilbar),
        ]
        for (label, a, u) in atmung {
            dualCb(label, ank: a, ueb: u, colX: x2, rowY: y2); y2 += rowH
        }
        y2 += 2

        // ── Schmerz (0-10) in Col 2 ──
        subHeader("Schmerz (0-10)", x: x2, y: y2, w: colW); y2 += shH
        let opqrstW: CGFloat = 8
        let schmerzBodyH: CGFloat = 28
        let schmerzLblW: CGFloat = 28
        let schmerzBoxW: CGFloat = colW - schmerzLblW - opqrstW - 2
        // Label-Spalte
        strokeR(CGRect(x: x2, y: y2, width: schmerzLblW, height: schmerzBodyH))
        txt("Erstbefund", CGRect(x: x2+1, y: y2+2, width: schmerzLblW-2, height: 5), font: tinyF, color: UIColor(white:0.35,alpha:1))
        txt("Übergabe",   CGRect(x: x2+1, y: y2+schmerzBodyH/2+2, width: schmerzLblW-2, height: 5), font: tinyF, color: UIColor(white:0.35,alpha:1))
        hline(x2, y2 + schmerzBodyH/2, schmerzLblW)
        // Wert-Spalte (Erstbefund oben, Übergabe unten)
        strokeR(CGRect(x: x2+schmerzLblW, y: y2, width: schmerzBoxW, height: schmerzBodyH))
        hline(x2+schmerzLblW, y2 + schmerzBodyH/2, schmerzBoxW)
        txt(di.schmerz > 0 ? "\(di.schmerz)" : "",
            CGRect(x: x2+schmerzLblW+1, y: y2+2, width: schmerzBoxW-2, height: schmerzBodyH/2-3),
            font: f7b, align: .center)
        txt(ub.schmerz > 0 ? "\(ub.schmerz)" : "",
            CGRect(x: x2+schmerzLblW+1, y: y2+schmerzBodyH/2+2, width: schmerzBoxW-2, height: schmerzBodyH/2-3),
            font: f7b, align: .center)
        // OPQRST-Spalte rechts
        let opLabels = ["O","P","Q","R","S","T"]
        let opqrstX = x2 + schmerzLblW + schmerzBoxW + 1
        for (i, letter) in opLabels.enumerated() {
            txt(letter, CGRect(x: opqrstX, y: y2 + CGFloat(i) * (schmerzBodyH/6),
                               width: opqrstW-1, height: schmerzBodyH/6), font: tinyF, align: .center)
        }
        y2 += schmerzBodyH + 2

        // ── Psyche-Block (in Col 2, unter Schmerz) ──
        subHeader("Psyche", x: x2, y: y2, w: colW)
        cb(ps.unauffaellig, x: x2 + colW - cbSz - 28, y: y2 + 1.5, size: cbSz)
        txt("unauffällig", CGRect(x: x2 + colW - 27, y: y2+1.5, width: 26, height: 5.5), font: tinyF)
        y2 += shH
        let psHalfW = colW / 2
        let psycheItems: [(String, Bool)] = [
            ("ängstlich",         ps.aengstlich),   ("wahnhaft",      ps.wahnhaft),
            ("suizidal",          ps.suizidal),      ("erregt",        ps.erregt),
            ("verlangsamt",       ps.verlangsamt),   ("depressiv",     ps.depressiv),
            ("euphorisch",        ps.euphorisch),    ("verwirrt",      ps.verwirrt),
            ("mot. unruhig",      ps.motorischUnruhig), ("n. beurteilbar", ps.nichtBeurteilbar),
            ("aggressiv",         ps.aggressiv),     ("Sonstige",      ps.sonstige),
        ]
        for (i, (label, checked)) in psycheItems.enumerated() {
            let px = x2 + 2 + CGFloat(i % 2) * psHalfW
            let py = y2 + CGFloat(i / 2) * rowH
            cbLabel(label, checked: checked, x: px, y: py, cbSize: cbSz, labelW: psHalfW - 9)
        }
        y2 += CGFloat((psycheItems.count + 1) / 2) * rowH + 2

        // ─────────────────────────────────────────────────────────────────────
        // SPALTE 3: C Cirkulat. + EKG  (+ Haut unten)
        // ─────────────────────────────────────────────────────────────────────
        let x3 = lx + 2*colW
        dualSubHeader("C Cirkulat. + EKG", colX: x3, ankUnauff: false, uebUnauff: ub.cUnauffaellig, startY: y)
        var y3 = y + dshH

        let ekg: [(String, Bool, Bool)] = [
            ("Rekap. > 2 Sek.",      ci.rekapillierung,         ub.rekapillierung),
            ("Sinusrhythmus",         ci.sinusrhythmus,          ub.sinusrhythmus),
            ("abs. Arrhythmie",       ci.absoluteArrhythmie,     ub.absoluteArrhythmie),
            ("AV-Block II°/III°",     ci.avBlockII || ci.avBlockIII, ub.avBlockII || ub.avBlockIII),
            ("QRS Tachy - breit",     ci.qrsTachykardieBreit,    ub.qrsTachykardieBreit),
            ("QRS Tachy - schmal",    ci.qrsTachykardieSchmal,   ub.qrsTachykardieSchmal),
            ("Kammerflatten/-flimmern", ci.kammerflattern || ci.kammerflimmern, ub.kammerflattern || ub.kammerflimmern),
            ("pulslose el. Aktivität",ci.pea,                    ub.pea),
            ("Asystolie",             ci.asystolie,              ub.asystolie),
            ("Schrittmacherrhythmus", ci.schrittmacher,          ub.schrittmacher),
            ("Infarkt-EKG (STEMI/LSB)",ci.infarktEkg,           ub.infarktEkg),
        ]
        for (label, a, u) in ekg {
            dualCb(label, ank: a, ueb: u, colX: x3, rowY: y3); y3 += rowH
        }
        // Freitextfeld "Sonstige EKG" nach EKG-Liste
        let ekgSonstW = colW - ankXRel - 3
        strokeR(CGRect(x: x3 + ankXRel, y: y3, width: ekgSonstW, height: rowH - 1))
        txt(ci.ekgSonstige, CGRect(x: x3 + ankXRel + 1, y: y3 + 0.5, width: ekgSonstW - 2, height: rowH - 2), font: f5)
        y3 += rowH

        // Extrasystolen sub-header
        subHeader("Extrasystolen", x: x3, y: y3, w: colW); y3 += shH
        let extraRows: [(String, Bool, Bool)] = [
            ("SVES",              ci.sves,                   ub.sves),
            ("VES",               ci.ves,                    ub.ves),
            ("monomorph",         ci.extrasystolenMonomorph, ub.extrasystolenMonomorph),
            ("polymorph",         ci.extrasystolenPolymorph, ub.extrasystolenPolymorph),
            ("n. beurteilbar",    ci.cNichtBeurteilbar,      ub.cNichtBeurteilbar),
        ]
        for (label, a, u) in extraRows {
            dualCb(label, ank: a, ueb: u, colX: x3, rowY: y3); y3 += rowH
        }
        y3 += 2

        // Haut-Block (unten in Col 3 – 2-spaltig)
        subHeader("Haut", x: x3, y: y3, w: colW)
        cb(ex.hautUnauffaellig, x: x3 + colW - cbSz - 28, y: y3 + 2, size: cbSz)
        txt("unauffällig", CGRect(x: x3 + colW - 27, y: y3+1.5, width: 26, height: 6), font: tinyF)
        y3 += shH
        let hautHalfW = colW / 2
        let hautLeft: [(String, Bool)] = [
            ("nicht untersucht",    ex.hautNichtUntersucht),
            ("stehende Hautfalten", ex.stehendeHautfalten),
            ("Oedeme",              ex.oedeme),
            ("kaltschweißig",       ex.kaltschweissig),
        ]
        let hautRight: [(String, Bool)] = [
            ("Dekubitus",      ex.dekubitus),
            ("Exanthem",       ex.exanthem),
            ("n. beurteilbar", ex.hautNichtBeurteilbar),
            ("Sonstige",       ex.hautSonstige),
        ]
        let hautRowCount = max(hautLeft.count, hautRight.count)
        for i in 0..<hautRowCount {
            let py = y3 + CGFloat(i) * rowH
            if i < hautLeft.count {
                let (label, checked) = hautLeft[i]
                cbLabel(label, checked: checked, x: x3+2, y: py, cbSize: cbSz, labelW: hautHalfW-9)
            }
            if i < hautRight.count {
                let (label, checked) = hautRight[i]
                cbLabel(label, checked: checked, x: x3+hautHalfW+2, y: py, cbSize: cbSz, labelW: hautHalfW-9)
            }
        }
        y3 += CGFloat(hautRowCount) * rowH

        // ─────────────────────────────────────────────────────────────────────
        // SPALTE 4: D Neurologie
        // ─────────────────────────────────────────────────────────────────────
        let x4 = lx + 3*colW
        dualSubHeader("D Neurologie", colX: x4, ankUnauff: false, uebUnauff: ub.dUnauffaellig, startY: y)
        var y4 = y + dshH

        // Bewusstseinslage (bold label)
        txt("Bewusstseinslage", CGRect(x: x4+2, y: y4, width: colW-4, height: 6), font: f5b); y4 += 6.5
        let bewRows: [(String, Bool, Bool)] = [
            ("wach",                 di.bewWach,           ub.bewWach),
            ("reagiert auf Ansprache",di.bewAnsprache,     ub.bewAnsprache),
            ("reagiert auf Schmerz", di.bewSchmerzreiz,    ub.bewSchmerzreiz),
            ("bewusstlos",           di.bewusstlos,        ub.bewusstlos),
            ("n. beurteilbar",       di.dNichtBeurteilbar, ub.dNichtBeurteilbar),
            ("Sonstige",             false,                false),
        ]
        for (label, a, u) in bewRows { dualCb(label, ank: a, ueb: u, colX: x4, rowY: y4); y4 += rowH }

        // Pupillenfunktion — 4 CBs per row: ank-re, ank-li, üb-re, üb-li
        hline(x4, y4, colW); y4 += 2
        let p4sz: CGFloat = cbSz
        let p4gap: CGFloat = 1.5
        let p4colW2 = p4sz + p4gap
        let p4totalCB: CGFloat = 4 * p4colW2
        let p4labelW = colW - p4totalCB - 4
        let p4x0 = x4 + p4labelW + 2

        // Header row: "re  li  Pupillenfunktion  re  li"
        txt("re", CGRect(x: p4x0,              y: y4, width: p4colW2, height: 5), font: tinyF, align: .center)
        txt("li", CGRect(x: p4x0+p4colW2,      y: y4, width: p4colW2, height: 5), font: tinyF, align: .center)
        txt("Pupillenfunktion", CGRect(x: x4+2, y: y4, width: p4labelW, height: 5), font: f5b)
        txt("re", CGRect(x: p4x0+2*p4colW2,    y: y4, width: p4colW2, height: 5), font: tinyF, align: .center)
        txt("li", CGRect(x: p4x0+3*p4colW2,    y: y4, width: p4colW2, height: 5), font: tinyF, align: .center)
        y4 += 5.5

        let pupillenRows: [(String, Bool, Bool, Bool, Bool)] = [
            ("eng",               di.pupilleReEng,                di.pupilleLiEng,               ub.pupilleReEng,                ub.pupilleLiEng),
            ("mittel",            di.pupilleReMittel,             di.pupilleLiMittel,            ub.pupilleReMittel,             ub.pupilleLiMittel),
            ("weit",              di.pupilleReWeit,               di.pupilleLiWeit,              ub.pupilleReWeit,               ub.pupilleLiWeit),
            ("entrundet",         di.pupilleReEntrundet,          di.pupilleLiEntrundet,         ub.pupilleReEntrundet,          ub.pupilleLiEntrundet),
            ("n. beurteilbar",    di.pupilleReNichtBeurteilbar,   di.pupilleLiNichtBeurteilbar,  ub.pupilleReNichtBeurteilbar,   ub.pupilleLiNichtBeurteilbar),
            ("keine Lichtreakt.", di.pupilleReKeineLichtreaktion, di.pupilleLiKeineLichtreaktion, ub.pupilleReKeineLichtreaktion, ub.pupilleLiKeineLichtreaktion),
        ]
        for (label, ar, al, ur, ul) in pupillenRows {
            txt(label, CGRect(x: x4+2, y: y4-0.3, width: p4labelW, height: 6), font: f5)
            cb(ar, x: p4x0,            y: y4, size: p4sz)
            cb(al, x: p4x0+p4colW2,    y: y4, size: p4sz)
            cb(ur, x: p4x0+2*p4colW2,  y: y4, size: p4sz)
            cb(ul, x: p4x0+3*p4colW2,  y: y4, size: p4sz)
            y4 += rowH
        }
        // isochor / anisochor
        cbLabel("isochor",   checked: di.pupillenIsochor,  x: x4+2,       y: y4, cbSize: p4sz, labelW: 38)
        cbLabel("anisochor", checked: !di.pupillenIsochor, x: x4+colW/2,  y: y4, cbSize: p4sz, labelW: 40)
        y4 += rowH

        hline(x4, y4, colW); y4 += 2
        // Neurologische Auffälligkeiten header
        txt("Neurol. Auffälligkeiten", CGRect(x: x4+2, y: y4, width: colW-28, height: 6), font: f5b)
        cb(di.neuroNichtBeurteilbar, x: x4+colW-cbSz-18, y: y4, size: cbSz)
        txt("keine", CGRect(x: x4+colW-17, y: y4, width: 16, height: 6), font: tinyF)
        y4 += 6.5

        // BE-FAST untereinander (volle Spaltenbreite, Reihenfolge B→E→F→A→S)
        let beFastRows: [(String, Bool, Bool)] = [
            ("Gleichgewicht B", di.neuroGleichgewicht,  ub.neuroGleichgewicht),
            ("Sehstörung E",    di.neuroSehstoerung,    ub.neuroSehstoerung),
            ("Facialisparese F",di.neuroFacialisparese, ub.neuroFacialisparese),
            ("Armparese A",     di.neuroArmparese,      ub.neuroArmparese),
            ("Sprachstörung S", di.neuroSprachstoerung, ub.neuroSprachstoerung),
        ]
        for (label, a, u) in beFastRows {
            dualCb(label, ank: a, ueb: u, colX: x4, rowY: y4); y4 += rowH
        }
        // T: Zeit-Freifeld (Uhrzeit oder "unbekannt")
        let zeitVal: String
        if di.befastZeitUnbekannt { zeitVal = "unbekannt" }
        else if let d = di.befastSymptombeginn { zeitVal = timeFmt.string(from: d) }
        else { zeitVal = "" }
        let tBoxX = x4 + ankXRel
        let tBoxW = uebXRelFn(colW) - ankXRel + cbSz
        strokeR(CGRect(x: tBoxX, y: y4, width: tBoxW, height: rowH - 1))
        txt("Zeit T:", CGRect(x: tBoxX+1, y: y4+0.5, width: 18, height: 5), font: tinyF,
            color: UIColor(white: 0.35, alpha: 1))
        txt(zeitVal, CGRect(x: tBoxX+20, y: y4+0.5, width: tBoxW-22, height: 5), font: f5b, align: .center)
        y4 += rowH

        hline(x4, y4, colW); y4 += 1.5

        // Weitere Neuro-Items im 2-Spalten-Layout
        let neuroHalf = colW / 2
        func neuroHalfCb(_ label: String, ank: Bool, ueb: Bool, colX: CGFloat, rowY: CGFloat) {
            let uebX2 = uebXRelFn(neuroHalf)
            let lblW2 = uebX2 - lblXRel - 1
            cb(ank, x: colX + ankXRel, y: rowY, size: cbSz)
            txt(label, CGRect(x: colX + lblXRel, y: rowY - 0.3, width: lblW2, height: 6), font: tinyF, align: .center)
            cb(ueb, x: colX + uebX2, y: rowY, size: cbSz)
        }
        let neuroPairs: [(String, Bool, Bool, String, Bool, Bool)] = [
            ("vorb. Defizit",    di.neuroVorbestehendesDefizit, ub.neuroVorbestehendesDefizit,
             "Querschnittsympt.",di.neuroQuerschnitt,           ub.neuroQuerschnitt),
            ("Babinski-Zeichen", di.neuroBabinski,              ub.neuroBabinski,
             "Meningismus",      di.neuroMeningismus,           ub.neuroMeningismus),
            ("Demenz",           di.neuroDemenz,                ub.neuroDemenz,
             "n. beurteilbar",   di.neuroNichtBeurteilbar,      ub.neuroNichtBeurteilbar),
            ("Sonstige",         false,                         false,
             "",                 false,                         false),
        ]
        for (lL, aL, uL, lR, aR, uR) in neuroPairs {
            neuroHalfCb(lL, ank: aL, ueb: uL, colX: x4,            rowY: y4)
            if !lR.isEmpty {
                neuroHalfCb(lR, ank: aR, ueb: uR, colX: x4+neuroHalf, rowY: y4)
            }
            y4 += rowH
        }

        // ─────────────────────────────────────────────────────────────────────
        // SPALTE 5: GCS
        // ─────────────────────────────────────────────────────────────────────
        let x5 = lx + 4*colW
        // GCS sub-header with Ankunft | GCS | Übergabe
        fillR(CGRect(x: x5, y: y, width: colW, height: shH), UIColor(white: 0.75, alpha: 1))
        txt("Ankunft",  CGRect(x: x5+1,             y: y+2, width: colW/3, height: 5), font: tinyF, align: .left)
        txt("GCS",      CGRect(x: x5+colW/3,         y: y+1.5, width: colW/3, height: 6), font: f5b, align: .center)
        txt("Übergabe", CGRect(x: x5+2*colW/3,       y: y+2, width: colW/3-1, height: 5), font: tinyF, align: .right)
        var y5 = y + shH

        // Column layout: [numW][cbW+gap][labelW][cbW+gap][numW]
        let gcsNumW: CGFloat  = 8
        let gcsCbGap: CGFloat = 1.5
        let gcsCbW: CGFloat   = cbSz + gcsCbGap
        let gcsLblW: CGFloat  = colW - 2*gcsNumW - 2*gcsCbW - 4
        let gcsAnkNumX = x5 + 1
        let gcsAnkCbX  = gcsAnkNumX + gcsNumW
        let gcsLblX    = gcsAnkCbX + gcsCbW
        let gcsUebCbX  = gcsLblX + gcsLblW + 1
        let gcsUebNumX = gcsUebCbX + gcsCbW

        // GCS sub-section: Augen öffnen (4 rows)
        subHeader("Augen öffnen", x: x5, y: y5, w: colW); y5 += shH
        let gcsAugenRows: [(Int, String)] = [
            (4, "spontan"), (3, "auf Aufforderung"), (2, "auf Schmerzreiz"), (1, "kein")
        ]
        for (num, label) in gcsAugenRows {
            txt("\(num)", CGRect(x: gcsAnkNumX, y: y5, width: gcsNumW, height: 6), font: f5b, align: .center)
            cb(di.gcsAugen == num, x: gcsAnkCbX,  y: y5, size: cbSz)
            txt(label, CGRect(x: gcsLblX, y: y5-0.3, width: gcsLblW, height: 6), font: f5, align: .center)
            cb(ub.gcsAugen == num, x: gcsUebCbX, y: y5, size: cbSz)
            txt("\(num)", CGRect(x: gcsUebNumX, y: y5, width: gcsNumW, height: 6), font: f5b, align: .center)
            y5 += rowH
        }

        // GCS sub-section: beste verbale Reaktion (5 rows)
        subHeader("beste verbale Reaktion", x: x5, y: y5, w: colW); y5 += shH
        let gcsVerbalRows: [(Int, String)] = [
            (5, "orientiert"), (4, "desorientiert"), (3, "inadäquat"), (2, "unverständlich"), (1, "keine")
        ]
        for (num, label) in gcsVerbalRows {
            txt("\(num)", CGRect(x: gcsAnkNumX, y: y5, width: gcsNumW, height: 6), font: f5b, align: .center)
            cb(di.gcsVerbal == num, x: gcsAnkCbX,  y: y5, size: cbSz)
            txt(label, CGRect(x: gcsLblX, y: y5-0.3, width: gcsLblW, height: 6), font: f5, align: .center)
            cb(ub.gcsVerbal == num, x: gcsUebCbX, y: y5, size: cbSz)
            txt("\(num)", CGRect(x: gcsUebNumX, y: y5, width: gcsNumW, height: 6), font: f5b, align: .center)
            y5 += rowH
        }

        // GCS sub-section: beste motorische Reaktion (6 rows)
        subHeader("beste motorische Reaktion", x: x5, y: y5, w: colW); y5 += shH
        let gcsMotorRows: [(Int, String)] = [
            (6, "auf Aufforderung"), (5, "gezielte Abwehr"), (4, "ungezielte Abwehr"),
            (3, "Beugesynergie"), (2, "Strecksynergie"), (1, "keine")
        ]
        for (num, label) in gcsMotorRows {
            txt("\(num)", CGRect(x: gcsAnkNumX, y: y5, width: gcsNumW, height: 6), font: f5b, align: .center)
            cb(di.gcsMotor == num, x: gcsAnkCbX,  y: y5, size: cbSz)
            txt(label, CGRect(x: gcsLblX, y: y5-0.3, width: gcsLblW, height: 6), font: f5, align: .center)
            cb(ub.gcsMotor == num, x: gcsUebCbX, y: y5, size: cbSz)
            txt("\(num)", CGRect(x: gcsUebNumX, y: y5, width: gcsNumW, height: 6), font: f5b, align: .center)
            y5 += rowH
        }

        // GCS Summe row — Ankunft links, Label mitte, Übergabe rechts
        hline(x5, y5, colW)
        txt("\(di.gcsGesamt)", CGRect(x: x5+2,    y: y5+1, width: gcsNumW+gcsCbW, height: 6), font: f6b, align: .left)
        txt("GCS Summe",       CGRect(x: gcsLblX,  y: y5+1, width: gcsLblW,        height: 6), font: f5b, align: .center)
        txt("\(ub.gcsGesamt)", CGRect(x: gcsUebCbX+gcsCbW, y: y5+1, width: gcsNumW, height: 6), font: f6b, align: .center)
        y5 += rowH + 2

        // ── Spalten-Trennlinien + untere Abschlusskante ──────────────────────
        let s3Bottom = max(y1, y2, y3, y4, y5) + 4
        let colLineTop = y + shH
        vline(x2, colLineTop, s3Bottom - colLineTop)
        vline(x3, colLineTop, s3Bottom - colLineTop)
        vline(x4, colLineTop, s3Bottom - colLineTop)
        vline(x5, colLineTop, s3Bottom - colLineTop)
        hline(lx, s3Bottom, W-8)
    }
    private static func drawSection4(protokoll: EinsatzProtokoll) {
        let d = protokoll.diagnose
        let lx: CGFloat = 4
        let y0: CGFloat = 490
        let rH: CGFloat = 6.5   // Zeilenhöhe
        let ghH: CGFloat = 8.0  // Gruppenheader-Höhe
        let cw = (W - 8) / 4   // 4 Spalten

        secHeader("4. Diagnose", x: lx, y: y0, w: W-8)
        subHeader("4.1 Erkrankung", x: lx, y: y0+10, w: W-8)

        let y = y0 + 20  // Inhalt ab hier

        // Gruppenheader: fetter Titel + "□ Sonstige" rechts
        func grpHeader(_ title: String, x: CGFloat, atY: CGFloat, colW: CGFloat) {
            txt(title, CGRect(x: x, y: atY, width: colW-33, height: ghH-1), font: f5b)
            cb(false, x: x+colW-30, y: atY+1.5, size: 5)
            txt("Sonstige", CGRect(x: x+colW-24, y: atY+0.5, width: 24, height: 6), font: f5)
        }
        // Standard-Checkbox-Zeile
        func row(_ label: String, _ checked: Bool, x: CGFloat, atY: CGFloat, colW: CGFloat) {
            cbLabel(label, checked: checked, x: x, y: atY, cbSize: 5, gap: 2, labelW: colW-9)
        }

        // ── Spalte 1: ZNS + Herz-Kreislauf ───────────────────────────────────
        let c1x = lx + 2; var c1y = y
        grpHeader("ZNS", x: c1x, atY: c1y, colW: cw); c1y += ghH
        for (l, c) in [
            ("akutes zentral-neurol. Defizit", d.znsAkutNeuro),
            ("Schlaganfall",                   d.znsSchlaganfall),
            ("ICB",                            d.znsIcb),
            ("SAB",                            d.znsSab),
            ("Krampfanfall",                   d.znsKrampfanfall),
            ("Status Epilepticus",             d.znsEpilepsie),
            ("Fieberkrampf",                   d.znsFieberkrampf),
        ] as [(String,Bool)] { row(l, c, x: c1x, atY: c1y, colW: cw); c1y += rH }

        grpHeader("Herz-Kreislauf", x: c1x, atY: c1y, colW: cw); c1y += ghH
        row("ACS", d.herzAcs, x: c1x, atY: c1y, colW: cw); c1y += rH
        // STEMI □ VW □ HW inline
        cbLabel("STEMI", checked: d.herzStemi, x: c1x, y: c1y, cbSize: 5, gap: 2, labelW: cw*0.42)
        cbLabel("VW", checked: d.herzVW, x: c1x+cw*0.50, y: c1y, cbSize: 5, gap: 2, labelW: 16)
        cbLabel("HW", checked: d.herzHW, x: c1x+cw*0.69, y: c1y, cbSize: 5, gap: 2, labelW: 16)
        c1y += rH
        row("kardiogener Schock", d.herzKardiogenerSchock, x: c1x, atY: c1y, colW: cw); c1y += rH
        // Rhythmusstörung □ tachy. □ brady. inline
        cbLabel("Rhythmusstörung", checked: d.herzRhythmus, x: c1x, y: c1y, cbSize: 5, gap: 2, labelW: cw*0.46)
        cbLabel("tachy.", checked: d.herzRhythmusTachy, x: c1x+cw*0.53, y: c1y, cbSize: 5, gap: 2, labelW: 18)
        cbLabel("brady.", checked: d.herzRhythmusBrady, x: c1x+cw*0.73, y: c1y, cbSize: 5, gap: 2, labelW: 18)
        c1y += rH
        for (l, c) in [
            ("PM/ICD Fehlfunktion",          d.herzPmFehlfunktion),
            ("Lungenembolie",                d.herzLungenembolie),
            ("dekomp. Herzinsuffizienz",     d.herzDekomp),
            ("hypertensiver Notfall",        d.herzHypertonerNotfall),
            ("Aortenaneurysma",              d.herzAortenaneurysma),
            ("Hypotonie",                    d.herzHypotonie),
            ("Synkope",                      d.herzSynkope),
            ("Thrombose/Embolie",            d.herzThromboseEmbolie),
            ("Herz-Kreislauf-Stillstand",    d.herzStillstand),
            ("Schock unklarer Genese",       d.herzSchockUnklarGenese),
            ("orthostatische Fehlregulation",d.herzOrthostatisch),
            ("unklarer Thoraxschmerz",       d.herzUnklarerThoraxschmerz),
        ] as [(String,Bool)] { row(l, c, x: c1x, atY: c1y, colW: cw); c1y += rH }

        // ── Spalte 2: Atmung + Stoffwechsel + Abdomen ─────────────────────────
        let c2x = lx + cw + 2; var c2y = y
        grpHeader("Atmung", x: c2x, atY: c2y, colW: cw); c2y += ghH
        for (l, c) in [
            ("Asthma",                   d.atmungAsthma),
            ("Status asthm.",            d.atmungStatusAsthmaticus),
            ("exacerbierte COPD",        d.atmungExazerbiert),
            ("Aspiration",               d.atmungAspiration),
            ("Pneumonie / Bronchitis",   d.atmungPneumonie),
            ("Hyperventilationstetanie", d.atmungHyperventilation),
            ("LTB (L/T/Bronchitis)",     d.atmungLtb),
            ("Epiglottitis",             d.atmungEpiglottitis),
            ("Spontanpneumothorax",      d.atmungSpontanpneumothorax),
            ("Hämoptysis",               d.atmungHaemoptysis),
            ("unkl. Dyspnoe",            d.atmungUnklareDyspnoe),
            ("Lungenödem",               d.atmungLungenodem),
            ("Pseudokrupp",              d.atmungPseudokrupp),
        ] as [(String,Bool)] { row(l, c, x: c2x, atY: c2y, colW: cw); c2y += rH }

        grpHeader("Stoffwechsel", x: c2x, atY: c2y, colW: cw); c2y += ghH
        for (l, c) in [
            ("Exsikkose",             d.stoffExsikkose),
            ("Hypoglycämie",          d.stoffHypoglykämie),
            ("Hyperglycämie",         d.stoffHyperglykämie),
            ("Urämie/ANV",            d.stoffUremie),
            ("bek. dialysepflichtig", d.stoffDialyse),
        ] as [(String,Bool)] { row(l, c, x: c2x, atY: c2y, colW: cw); c2y += rH }

        grpHeader("Abdomen", x: c2x, atY: c2y, colW: cw); c2y += ghH
        row("akutes Abdomen", d.abdoAkutes, x: c2x, atY: c2y, colW: cw); c2y += rH
        row("Kolik allgemein", d.abdoKoliken, x: c2x, atY: c2y, colW: cw); c2y += rH
        // GIB □ obere □ untere inline
        cbLabel("GIB", checked: d.abdoGibOben||d.abdoGibUnten, x: c2x, y: c2y, cbSize: 5, gap: 2, labelW: 16)
        cbLabel("obere", checked: d.abdoGibOben, x: c2x+cw*0.24, y: c2y, cbSize: 5, gap: 2, labelW: 20)
        cbLabel("untere", checked: d.abdoGibUnten, x: c2x+cw*0.57, y: c2y, cbSize: 5, gap: 2, labelW: 20)
        c2y += rH
        row("Gallenkolik", d.abdoGallenkolik||d.abdoGalleNiere, x: c2x, atY: c2y, colW: cw); c2y += rH
        row("Nierenkolik", d.abdoNierenkolik, x: c2x, atY: c2y, colW: cw); c2y += rH

        // ── Spalte 3: Psychiatrie + Gyn./Geb.-hilfe + Infektionen ─────────────
        let c3x = lx + 2*cw + 2; var c3y = y
        grpHeader("Psychiatrie", x: c3x, atY: c3y, colW: cw); c3y += ghH
        for (l, c) in [
            ("psych. Ausnahmezustand", d.psychAkut),
            ("psychosoz. Krise",       d.psychKrise),
            ("Depressionen",           d.psychDepressionen),
            ("Manie",                  d.psychManie),
            ("Intoxikation",           d.psychIntoxikation),
            ("Entzug/Delir",           d.psychEntzug),
            ("Suizidalität",           d.psychSuizidal),
        ] as [(String,Bool)] { row(l, c, x: c3x, atY: c3y, colW: cw); c3y += rH }

        grpHeader("Gyn./Geb.-hilfe", x: c3x, atY: c3y, colW: cw); c3y += ghH
        for (l, c) in [
            ("Schwangerschaft > 35. SSW", d.gynSchwangerschaft35),
            ("Geburt",                    d.gynGeburt),
            ("Extrauterine Gravidität",   d.gynExtrauterine||d.gynSonstige),
            ("Eklampsie",                 d.gynEklampsie),
            ("vaginale Blutung",          d.gynVaginalblutung),
        ] as [(String,Bool)] { row(l, c, x: c3x, atY: c3y, colW: cw); c3y += rH }

        grpHeader("Infektionen", x: c3x, atY: c3y, colW: cw); c3y += ghH
        row("unkl. Fieber", d.infektUnklarFieber, x: c3x, atY: c3y, colW: cw); c3y += rH
        row("Meningitis/Enzephalitis", d.infektMeningitis, x: c3x, atY: c3y, colW: cw); c3y += rH
        // offen -MRSA- □ gedeckt inline
        cbLabel("offen -MRSA-", checked: d.infektMrsaOffen, x: c3x, y: c3y, cbSize: 5, gap: 2, labelW: cw*0.47)
        cbLabel("gedeckt", checked: d.infektMrsaGedeckt, x: c3x+cw*0.56, y: c3y, cbSize: 5, gap: 2, labelW: 28)
        c3y += rH
        row("MRE", d.infektMre, x: c3x, atY: c3y, colW: cw); c3y += rH
        row("Hepatitis", d.infektHepatitis, x: c3x, atY: c3y, colW: cw); c3y += rH

        // ── Spalte 4: HIV-Gruppe + Sonstiges ──────────────────────────────────
        let c4x = lx + 3*cw + 2; let c4w = W - 8 - 3*cw; var c4y = y
        for (l, c) in [
            ("HIV",                        d.infektHiv),
            ("TBC",                        d.infektTbc),
            ("hochkontag. Erreger (SARS)", d.infektHighToxSars),
            ("Gastroenteritis",            d.infektGastro),
        ] as [(String,Bool)] { row(l, c, x: c4x, atY: c4y, colW: c4w); c4y += rH }

        // "Sonstiges" + "□ unklar"
        txt("Sonstiges", CGRect(x: c4x, y: c4y, width: c4w-24, height: ghH-1), font: f5b)
        cb(false, x: c4x+c4w-22, y: c4y+1.5, size: 5)
        txt("unklar", CGRect(x: c4x+c4w-16, y: c4y+0.5, width: 16, height: 6), font: f5)
        c4y += ghH
        for (l, c) in [
            ("Anaphylaxie Grad 1/2",      d.infektAnaphylaxie12),
            ("Anaphylaxie Grad 3/4",      d.infektAnaphylaxie34),
            ("sept. Schock",              d.infektSeptSchock),
            ("Hitzeerschöpf./Hitzschl.", d.infektHitze),
            ("Unterkül./Erfrierung",      d.infektUnterku),
            ("Ertrinken",                 d.infektErtrinken),
            ("SIDS",                      d.infektSids),
            ("Intoxikation",              d.infektIntoxikation),
            ("akute Lumbago",             d.infektAkuteLumbalgie),
            ("palliative Situation",      d.infektPalliativ),
            ("med. Behandlungskomplik.",  d.infektBehandlungKompl),
            ("Epistaxis",                 d.infektEpistaxis),
            ("urologische Erkrankung",    d.infektUrologisch),
        ] as [(String,Bool)] { row(l, c, x: c4x, atY: c4y, colW: c4w); c4y += rH }

        // ── Trennlinien ────────────────────────────────────────────────────────
        let diagBottom = max(c1y, c2y, c3y, c4y) + 2
        for i in 1..<4 { vline(lx + CGFloat(i)*cw, y0+20, diagBottom - y0 - 20) }
        hline(lx, diagBottom, W-8)

        // ── Diagnose/Leitsymptom ───────────────────────────────────────────────
        var diagText: [String] = []
        if !d.leitsymptom.isEmpty { diagText.append(d.leitsymptom) }
        let vd = d.verdachtsdiagnosen.map(\.name).filter { !$0.isEmpty }
        if !vd.isEmpty { diagText.append("V.a. " + vd.joined(separator: ", ")) }
        if !d.diagnoseFreitext.isEmpty { diagText.append(d.diagnoseFreitext) }
        labeledField("Diagnose/Leitsymptom", diagText.joined(separator: " · "), x: lx, y: diagBottom, w: W-8, h: 14)
    }
    @discardableResult
    private static func drawSection42(protokoll: EinsatzProtokoll, y0: CGFloat) -> CGFloat {
        let d  = protokoll.diagnose
        let vm = d.verletzungsMatrix
        let lx: CGFloat = 4
        let leftW = maaX - 4   // left column width

        // Section header with "□ keine" checkbox inline
        fillR(CGRect(x: lx, y: y0, width: leftW, height: 10), cHeader)
        txt("4.2 Verletzungen", CGRect(x: lx+2, y: y0+1.5, width: leftW-60, height: 7), font: f6b, color: .white)
        cb(false, x: lx+leftW-34, y: y0+2.5, size: 5)
        txt("keine", CGRect(x: lx+leftW-28, y: y0+2, width: 26, height: 6), font: f5, color: .white)

        // Matrix header: Region | leicht | schwer  (2-col, no "keine")
        var y = y0 + 10
        // Layout: region-label 0..matW-48, leicht col 0..24, schwer col 24..48 (rightmost 48pt)
        let matW: CGFloat = leftW - 4   // 4pt padding
        let cbColW: CGFloat = 24
        let lblColW = matW - 2 * cbColW
        fillR(CGRect(x: lx, y: y, width: leftW, height: 8), cLight)
        strokeR(CGRect(x: lx, y: y, width: leftW, height: 8))
        txt("Region", CGRect(x: lx+2, y: y+1, width: lblColW-2, height: 6), font: f5b)
        txt("leicht",  CGRect(x: lx+lblColW,           y: y+1, width: cbColW, height: 6), font: f5b, align: .center)
        txt("schwer",  CGRect(x: lx+lblColW+cbColW,    y: y+1, width: cbColW, height: 6), font: f5b, align: .center)
        vline(lx+lblColW, y, 8); vline(lx+lblColW+cbColW, y, 8); vline(lx+leftW, y, 8)
        y += 8

        let verletzungen: [(String, Verletzungsgrad)] = [
            ("Schädel-Hirn",         vm.schaedelHirn),
            ("Gesicht",              vm.gesicht),
            ("HWS",                  vm.hws),
            ("Thorax",               vm.thorax),
            ("Abdomen",              vm.abdomen),
            ("BWS / LWS",            vm.bwsLws),
            ("Becken",               vm.becken),
            ("Obere Extremitäten",   vm.obereExtrem),
            ("Untere Extremitäten",  vm.untereExtrem),
            ("Weichteile",           vm.weichteile),
        ]
        let rowH42: CGFloat = 9
        for (name, grad) in verletzungen {
            strokeR(CGRect(x: lx, y: y, width: leftW, height: rowH42))
            txt(name, CGRect(x: lx+2, y: y+1.5, width: lblColW-4, height: 6), font: f5)
            vline(lx+lblColW, y, rowH42); vline(lx+lblColW+cbColW, y, rowH42); vline(lx+leftW, y, rowH42)
            cb(grad == .leicht, x: lx+lblColW+(cbColW-5)/2,        y: y+2, size: 5)
            cb(grad == .schwer, x: lx+lblColW+cbColW+(cbColW-5)/2, y: y+2, size: 5)
            y += rowH42
        }

        // Body silhouette positioned in right portion of the matrix area
        drawKoerperschema(vm: vm, x: lx + lblColW - 118, y: y0 + 10)

        // Spezielle Traumen — 3+3 items in 2 columns
        hline(lx, y, leftW); y += 2
        txt("Spezielle Traumen:", CGRect(x: lx+2, y: y, width: leftW-4, height: 6), font: f5b); y += 7
        let specTop: [(String, Bool)] = [
            ("Verbr./Verbrüh.",   d.spezVerbrVerbrh),
            ("Elektrounfall",     d.spezElektrounfall),
            ("Tauchunfall",       d.spezTauchunfall),
        ]
        let specTopR: [(String, Bool)] = [
            ("Inhalationstrauma", false),
            ("Verätzung",         false),
            ("Sonstige",          false),
        ]
        let halfW = leftW / 2
        for (i, (label, checked)) in specTop.enumerated() {
            cbLabel(label, checked: checked, x: lx+2, y: y + CGFloat(i)*7, cbSize: 5, gap: 2, labelW: halfW-12)
        }
        for (i, (label, checked)) in specTopR.enumerated() {
            cbLabel(label, checked: checked, x: lx+halfW+2, y: y + CGFloat(i)*7, cbSize: 5, gap: 2, labelW: halfW-12)
        }
        y += CGFloat(max(specTop.count, specTopR.count)) * 7 + 2

        // Unfall sub-label
        txt("Unfall:", CGRect(x: lx+2, y: y, width: leftW-4, height: 6), font: f5b); y += 7
        let unfallItems: [(String, Bool)] = [
            ("PKW/LKW-Insasse",   d.spezPkwLkw),
            ("nicht bekannt",     false),
            ("Motorradfahrer",    d.spezMotorrad),
            ("Fahrradfahrer",     d.spezFahrrad),
            ("Fußg. angefahren",  d.spezFussgaenger),
            ("and. Verkehrsm.",   d.spezAndVerkehr),
            ("Sturz >3m",         d.spezSturzHoehe),
            ("Sturz <3m",         false),
            ("Schlag",            false),
            ("Schuss",            false),
            ("Stich",             false),
            ("Gewaltverbrechen",  d.spezGewalt),
            ("Verschüttung",      false),
            ("andere Unfallart",  d.spezAndererUnfall),
        ]
        let colCount = 2
        let unfallColW = leftW / CGFloat(colCount)
        let unfallRows = (unfallItems.count + colCount - 1) / colCount
        for (i, (label, checked)) in unfallItems.enumerated() {
            let col = i % colCount
            let row = i / colCount
            cbLabel(label, checked: checked,
                    x: lx + 2 + CGFloat(col)*unfallColW,
                    y: y + CGFloat(row)*7,
                    cbSize: 5, gap: 2, labelW: unfallColW - 12)
        }
        y += CGFloat(unfallRows) * 7 + 2

        // Verletzungsmuster
        hline(lx, y, leftW); y += 2
        let muster = d.verletzungsMuster
        let musterW = leftW / 3
        cbLabel("Einzelverletzung",   checked: muster == "Einzelverletzung",   x: lx+2,         y: y, cbSize: 5, gap: 2, labelW: musterW-12)
        cbLabel("Mehrfachverletzung", checked: muster == "Mehrfachverletzung", x: lx+musterW+2, y: y, cbSize: 5, gap: 2, labelW: musterW-12)
        cbLabel("Polytrauma",         checked: muster == "Polytrauma",         x: lx+2*musterW+2, y: y, cbSize: 5, gap: 2, labelW: musterW-12)
        y += 8

        // Unfallmechanismus
        let art = d.verletzungsArt
        cbLabel("stumpf",       checked: art.lowercased().contains("stumpf"),  x: lx+2,         y: y, cbSize: 5, gap: 2, labelW: musterW-12)
        cbLabel("penetrierend", checked: art.lowercased().contains("penetr"),  x: lx+musterW+2, y: y, cbSize: 5, gap: 2, labelW: musterW-12)
        cbLabel("nicht bekannt", checked: false,                                x: lx+2*musterW+2, y: y, cbSize: 5, gap: 2, labelW: musterW-12)
        y += 8

        hline(lx, y, leftW)
        return y
    }

    private static func drawKoerperschema(vm: VerletzungsMatrix, x: CGFloat, y: CGFloat) {
        func colorFor(_ g: Verletzungsgrad) -> UIColor {
            switch g {
            case .schwer: return UIColor(red:0.8, green:0.1, blue:0.1, alpha:0.7)
            case .leicht: return UIColor(red:1.0, green:0.6, blue:0.0, alpha:0.7)
            case .keine:  return UIColor(white: 0.90, alpha: 1)
            }
        }
        let rumpfColor: UIColor = [vm.thorax, vm.abdomen].contains(.schwer) ? colorFor(.schwer) :
                                   [vm.thorax, vm.abdomen].contains(.leicht) ? colorFor(.leicht) : colorFor(.keine)
        let beckenColor: UIColor = [vm.bwsLws, vm.becken].contains(.schwer) ? colorFor(.schwer) :
                                    [vm.bwsLws, vm.becken].contains(.leicht) ? colorFor(.leicht) : colorFor(.keine)

        // Eine Figur (Strichmännchen-Silhouette) ab Basis-X zeichnen
        func drawFigure(at fx: CGFloat, label: (String, String)) {
            // li/re-Beschriftung über der Figur
            txt(label.0, CGRect(x: fx,    y: y-6, width: 24, height: 5), font: f5, align: .center)
            txt(label.1, CGRect(x: fx+24, y: y-6, width: 24, height: 5), font: f5, align: .center)
            vline(fx+24, y-1, 80, lw: 0.15)   // Mittellinie li/re

            // Kopf
            let kopfR = CGRect(x: fx+18, y: y, width: 12, height: 12)
            colorFor(vm.schaedelHirn).setFill(); UIBezierPath(ovalIn: kopfR).fill()
            UIColor(white:0.4,alpha:1).setStroke()
            let kp = UIBezierPath(ovalIn: kopfR); kp.lineWidth = 0.4; kp.stroke()
            // Hals/HWS
            fillR(CGRect(x: fx+21, y: y+12, width: 6, height: 4), colorFor(vm.hws))
            strokeR(CGRect(x: fx+21, y: y+12, width: 6, height: 4), lw: 0.4)
            // Rumpf
            fillR(CGRect(x: fx+13, y: y+16, width: 22, height: 22), rumpfColor)
            strokeR(CGRect(x: fx+13, y: y+16, width: 22, height: 22), lw: 0.4)
            // Becken/BWS
            fillR(CGRect(x: fx+15, y: y+38, width: 18, height: 7), beckenColor)
            strokeR(CGRect(x: fx+15, y: y+38, width: 18, height: 7), lw: 0.4)
            // Arme
            fillR(CGRect(x: fx+5,  y: y+16, width: 7, height: 20), colorFor(vm.obereExtrem))
            strokeR(CGRect(x: fx+5,  y: y+16, width: 7, height: 20), lw: 0.4)
            fillR(CGRect(x: fx+36, y: y+16, width: 7, height: 20), colorFor(vm.obereExtrem))
            strokeR(CGRect(x: fx+36, y: y+16, width: 7, height: 20), lw: 0.4)
            // Beine
            fillR(CGRect(x: fx+16, y: y+45, width: 7, height: 28), colorFor(vm.untereExtrem))
            strokeR(CGRect(x: fx+16, y: y+45, width: 7, height: 28), lw: 0.4)
            fillR(CGRect(x: fx+25, y: y+45, width: 7, height: 28), colorFor(vm.untereExtrem))
            strokeR(CGRect(x: fx+25, y: y+45, width: 7, height: 28), lw: 0.4)
        }

        // Ventral (li | re) und dorsal (re | li)
        drawFigure(at: x,      label: ("li", "re"))
        drawFigure(at: x + 56, label: ("re", "li"))
    }

    @discardableResult
    private static func drawSection5(protokoll: EinsatzProtokoll, y0: CGFloat) -> CGFloat {
        let d = protokoll.diagnose
        let lx: CGFloat = 4
        let leftW = maaX - 4

        let boxH: CGFloat = 96
        secHeader("5. Verlauf", x: lx, y: y0, w: leftW)
        strokeR(CGRect(x: lx, y: y0+10, width: leftW, height: boxH))
        mtxt(d.verlauf, CGRect(x: lx+2, y: y0+12, width: leftW-4, height: boxH-4), font: f6)
        hline(lx, y0+10+boxH, leftW)
        return y0 + 10 + boxH
    }

    @discardableResult
    private static func drawVerlaufsgrafik(protokoll: EinsatzProtokoll, y0: CGFloat) -> CGFloat {
        let messungen = protokoll.verlaufMessungen.sorted { $0.zeitpunkt < $1.zeitpunkt }
        let lx: CGFloat = 4
        let h: CGFloat  = 178
        let leftW = maaX - 4
        // Label area on left for Y-axis row labels
        let rowLabelW: CGFloat = 52
        let plotX = lx + rowLabelW
        let plotW = leftW - rowLabelW - 2

        // Outer frame
        strokeR(CGRect(x: lx, y: y0, width: leftW, height: h))

        // Header
        fillR(CGRect(x: lx, y: y0, width: leftW, height: 8), cLight)
        txt("UHRZEIT", CGRect(x: lx+2, y: y0+1, width: 26, height: 6), font: f5b)
        hline(lx, y0+8, leftW)

        // Row labels (binary event rows)
        let rowLabels: [String] = [
            "Puls", "RR", "HDM", "Defibrillation", "Transport",
            "In/Extubation", "Spontanatmung", "assist. Beatmung",
            "kont. Beatmung", "Maßnahmen", "SpO₂", "O₂ L/min",
            "Temp.", "et CO₂"
        ]
        let nRows = rowLabels.count
        // Reserve top portion for numeric plot (puls/RR), bottom for event rows
        let plotH: CGFloat = 60
        let eventSectionH = h - 8 - plotH - 10   // remaining after header, plot, time-label row
        let eventRowH = nRows > 0 ? eventSectionH / CGFloat(nRows) : 6
        let plotY = y0 + 8 + 4

        // Y-axis numeric grid (60–260)
        let yMin: CGFloat = 60; let yMax: CGFloat = 260
        for val in stride(from: Int(yMin), through: Int(yMax), by: 20) {
            let fy = plotY + plotH * (1 - CGFloat(val - Int(yMin)) / CGFloat(yMax - yMin))
            hline(plotX-2, fy, plotW+2, lw: 0.15)
            txt("\(val)", CGRect(x: lx, y: fy-3, width: rowLabelW-2, height: 6), font: f5, align: .right)
        }

        // Event row labels
        let eventY0 = plotY + plotH + 8
        for (i, label) in rowLabels.enumerated() {
            let ry = eventY0 + CGFloat(i) * eventRowH
            fillR(CGRect(x: lx, y: ry, width: rowLabelW, height: eventRowH), cLight)
            strokeR(CGRect(x: lx, y: ry, width: rowLabelW, height: eventRowH), lw: 0.3)
            strokeR(CGRect(x: plotX, y: ry, width: plotW, height: eventRowH), lw: 0.15)
            txt(label, CGRect(x: lx+1, y: ry+1, width: rowLabelW-2, height: eventRowH-2), font: f5)
        }

        // Curves
        guard messungen.count >= 2 else {
            hline(lx, y0+h, leftW)
            return y0 + h
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

        drawCurve(messungen.compactMap { m in m.puls.map { CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor($0)) } }, color: .red)
        drawCurve(messungen.compactMap { m in m.blutdruckSys.map { CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor($0)) } }, color: .blue)
        drawCurve(messungen.compactMap { m in m.blutdruckDia.map { CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor($0)) } }, color: UIColor(red:0.3, green:0.3, blue:1, alpha:1), lw: 0.5)
        drawCurve(messungen.compactMap { m in m.spo2.map { CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor($0)) } }, color: UIColor(red:0, green:0.6, blue:0, alpha:1))

        // Time labels
        for m in messungen {
            let x = xFor(m.zeitpunkt.timeIntervalSinceReferenceDate)
            vline(x, plotY, plotH, lw: 0.15)
            txt(t(m.zeitpunkt), CGRect(x: x-9, y: plotY+plotH+1, width: 20, height: 5), font: f5, align: .center)
        }

        hline(lx, y0+h, leftW)
        return y0 + h
    }
    @discardableResult
    private static func drawSection6(protokoll: EinsatzProtokoll) -> CGFloat {
        let m   = protokoll.massnahmen
        let x   = maaX
        let w   = maaW
        let y0: CGFloat = 4

        // Local layout constants
        let rH: CGFloat = 9.5
        let rdX = x + 2
        let lblX = rdX + 9
        let lblW = x + w - lblX - 2

        func mRow(_ label: String, rd: Bool, atY: CGFloat) {
            cb(rd, x: rdX, y: atY+2, size: 5)
            txt(label, CGRect(x: lblX, y: atY+1.5, width: lblW, height: rH-3), font: f5)
        }
        func mHdr(_ title: String, atY: CGFloat, rightLbl: String = "keine") {
            fillR(CGRect(x: x, y: atY, width: w, height: 9), UIColor(white:0.75, alpha:1))
            txt(title, CGRect(x: x+2, y: atY+1.5, width: w-38, height: 6.5), font: f5b)
            cb(false, x: x+w-34, y: atY+2, size: 5)
            txt(rightLbl, CGRect(x: x+w-28, y: atY+1.5, width: 26, height: 6.5), font: f5)
        }
        func m3(_ items: [(String, Bool)], atY: CGFloat) {
            let iw = w / CGFloat(items.count)
            for (i, (l, c)) in items.enumerated() {
                cbLabel(l, checked: c, x: x+CGFloat(i)*iw+2, y: atY, cbSize: 5, gap: 2, labelW: iw-14)
            }
        }

        // Section header
        secHeader("6. Maßnahmen", x: x, y: y0, w: w)
        var cy = y0 + 10

        // ── Airway / Stabilisation ────────────────────────────────────────────
        mHdr("Airway / Stabilisation", atY: cy); cy += 9
        // RD col header
        txt("RD", CGRect(x: rdX, y: cy, width: 9, height: 6), font: f5, align: .center)
        cy += 7

        mRow("Atemweg freimachen/freihalten", rd: m.atemwegFreimachen,        atY: cy); cy += rH
        mRow("Cervikalstütze/HWS Stabilisation", rd: m.cervikalStuetze,       atY: cy); cy += rH
        mRow("Absaugung",                        rd: m.absaugung,              atY: cy); cy += rH

        // Sauerstoffgabe with field
        mRow("Sauerstoffgabe",                   rd: m.sauerstoffgabe,         atY: cy)
        txt("O₂", CGRect(x: x+w-56, y: cy+1.5, width: 10, height: rH-3), font: f5)
        strokeR(CGRect(x: x+w-45, y: cy+1, width: 28, height: rH-2))
        txt(m.sauerstoffLitMin, CGRect(x: x+w-44, y: cy+1.5, width: 26, height: rH-4), font: f5b)
        txt("l/min", CGRect(x: x+w-16, y: cy+1.5, width: 14, height: rH-3), font: f5)
        cy += rH

        mRow("Maskenbeatmung",                   rd: m.maskenbeatmung,         atY: cy); cy += rH
        mRow("Maskenbeatmung unmöglich",          rd: m.maskenbeatmungUnmoeglich, atY: cy); cy += rH
        mRow("Supraglott. Atemwegshilfe (EGA)",   rd: m.supraglottisch,         atY: cy); cy += rH

        // EGA sub-row
        let egaTyp = m.supraglottischTyp.lowercased()
        cbLabel("Larynxmaske",  checked: egaTyp.contains("maske"),  x: lblX,    y: cy, cbSize: 4, gap: 1, labelW: 28)
        cbLabel("Larynxtubus",  checked: egaTyp.contains("tubus"),  x: lblX+32, y: cy, cbSize: 4, gap: 1, labelW: 28)
        cbLabel("sonst.",       checked: egaTyp.contains("sonst"),  x: lblX+64, y: cy, cbSize: 4, gap: 1, labelW: 16)
        txt("Gr:", CGRect(x: lblX+84, y: cy, width: 10, height: 7), font: f5)
        strokeR(CGRect(x: lblX+95, y: cy, width: 18, height: 7))
        txt(m.supraglottischGr, CGRect(x: lblX+96, y: cy+0.5, width: 16, height: 6), font: f5b)
        cy += 7

        mRow("Atemwegszugang erschwert",   rd: m.atemwegErschwert,       atY: cy); cy += rH
        mRow("Intubation",                 rd: protokoll.airway.intubiert, atY: cy); cy += rH
        mRow("Konikotomie/chir. Atemweg",  rd: protokoll.airway.konikotomie, atY: cy); cy += rH
        mRow("Sonstige",                   rd: !m.airwaySonstige.isEmpty,  atY: cy); cy += rH

        // ── Atmung ────────────────────────────────────────────────────────────
        mHdr("Atmung", atY: cy); cy += 9
        txt("RD", CGRect(x: rdX, y: cy, width: 9, height: 6), font: f5, align: .center)
        txt("FiO₂", CGRect(x: x+w-42, y: cy, width: 18, height: 6), font: f5)
        txt("CPAP/PEEP", CGRect(x: x+w-22, y: cy, width: 20, height: 6), font: f5)
        cy += 7

        // Thoraxdrainage with re/li
        mRow("Thoraxdrainage", rd: false, atY: cy)
        cbLabel("re", checked: false, x: x+w-20, y: cy+2, cbSize: 4, gap: 1, labelW: 8)
        cbLabel("li", checked: false, x: x+w-10, y: cy+2, cbSize: 4, gap: 1, labelW: 7)
        cy += rH

        mRow("CPAP/NIV",                         rd: m.cpap,                   atY: cy); cy += rH

        // Entlastungspunktion with re/li
        mRow("Entlastungspunktion", rd: false, atY: cy)
        cbLabel("re", checked: false, x: x+w-20, y: cy+2, cbSize: 4, gap: 1, labelW: 8)
        cbLabel("li", checked: false, x: x+w-10, y: cy+2, cbSize: 4, gap: 1, labelW: 7)
        cy += rH

        mRow("kontrollierte Beatmung (PCV, CMV)", rd: m.maschinelleBeatmung,   atY: cy); cy += rH
        mRow("Sonstige",                          rd: false,                    atY: cy); cy += rH

        // Bem. text field
        txt("Bem.:", CGRect(x: x+2, y: cy+1, width: 14, height: 6), font: f5)
        strokeR(CGRect(x: x+16, y: cy, width: w-18, height: 8))
        cy += 8

        // IE/AF and AZV/PS fields
        txt("IE:", CGRect(x: x+2, y: cy+1, width: 12, height: 6), font: f5)
        strokeR(CGRect(x: x+14, y: cy, width: w/2-16, height: 8))
        txt("AF:", CGRect(x: x+w/2+2, y: cy+1, width: 12, height: 6), font: f5)
        strokeR(CGRect(x: x+w/2+14, y: cy, width: w/2-16, height: 8))
        cy += 8
        txt("AZV:", CGRect(x: x+2, y: cy+1, width: 14, height: 6), font: f5)
        strokeR(CGRect(x: x+16, y: cy, width: w/2-18, height: 8))
        txt("PS:", CGRect(x: x+w/2+2, y: cy+1, width: 12, height: 6), font: f5)
        strokeR(CGRect(x: x+w/2+14, y: cy, width: w/2-16, height: 8))
        cy += 8

        // ── Cirkulation ───────────────────────────────────────────────────────
        // Custom header: Cirkulation + □vorhanden □keine
        fillR(CGRect(x: x, y: cy, width: w, height: 9), UIColor(white:0.75, alpha:1))
        txt("Cirkulation", CGRect(x: x+2, y: cy+1.5, width: 58, height: 6.5), font: f5b)
        cb(false, x: x+62, y: cy+2, size: 5)
        txt("vorh. (HA, etc.)", CGRect(x: x+68, y: cy+1.5, width: 68, height: 6.5), font: f5)
        cb(false, x: x+w-28, y: cy+2, size: 5)
        txt("keine", CGRect(x: x+w-22, y: cy+1.5, width: 20, height: 6.5), font: f5)
        cy += 9
        txt("RD", CGRect(x: rdX, y: cy, width: 9, height: 6), font: f5, align: .center)
        cy += 7

        // 2 Zugänge mit je einem Beschreibungsfeld (Ort/Größe)
        let zugFeldX = lblX + 58
        let zugFeldW = x + w - zugFeldX - 2
        func zugRow2(_ label: String, rd: Bool, info: String, atY: CGFloat) {
            mRow(label, rd: rd, atY: atY)
            strokeR(CGRect(x: zugFeldX, y: atY+1, width: zugFeldW, height: rH-2))
            txt(info, CGRect(x: zugFeldX+1, y: atY+2, width: zugFeldW-2, height: rH-4), font: f5b)
        }
        let pvkInfo = [m.peripherVenoesOrt, m.peripherVenoesGroesse.isEmpty ? "" : "\(m.peripherVenoesGroesse)G"]
            .filter{!$0.isEmpty}.joined(separator: " ")
        zugRow2("peripher-ven. Zugang", rd: m.peripherVenoes, info: pvkInfo, atY: cy); cy += rH
        zugRow2("zentral-ven. Zugang",  rd: false, info: "", atY: cy); cy += rH
        // intraoss. Kanüle/Port
        mRow("intraoss. Kanüle/Port",  rd: m.intraossaer, atY: cy)
        strokeR(CGRect(x: zugFeldX, y: cy+1, width: zugFeldW, height: rH-2))
        txt(m.intraossaerOrt, CGRect(x: zugFeldX+1, y: cy+2, width: zugFeldW-2, height: rH-4), font: f5b)
        cy += rH
        mRow("art. Kanüle",             rd: false, atY: cy); cy += rH
        mRow("intranasale Applikation", rd: false, atY: cy); cy += rH
        mRow("Sonstige",                rd: false, atY: cy); cy += rH

        // ── Weitere Maßnahmen ─────────────────────────────────────────────────
        mHdr("Weitere Maßnahmen", atY: cy); cy += 9
        m3([("Kühlung", m.kuehlung), ("Wärmeerhalt", m.waermeerhalt), ("Entbindung", m.entbindung)], atY: cy); cy += rH
        m3([("Krisenintervention", m.krisenintervention), ("Kardioversion", m.kardioversion), ("Sonstige", false)], atY: cy); cy += rH

        // Tourniquet + Zeit + Narkose
        cbLabel("Tourniquet", checked: m.tourniquet, x: x+2, y: cy, cbSize: 5, gap: 2, labelW: 28)
        txt("Zeit", CGRect(x: x+36, y: cy, width: 10, height: 7), font: f5)
        strokeR(CGRect(x: x+46, y: cy, width: 40, height: 7))
        txt(m.tourniquetZeit.map { t($0) } ?? "", CGRect(x: x+47, y: cy+0.5, width: 38, height: 6), font: f5b)
        cbLabel("Narkose/Analgesed.", checked: false, x: x+w/2, y: cy, cbSize: 5, gap: 2, labelW: w/2-12)
        cy += rH

        // ── Lagerung / Transport ──────────────────────────────────────────────
        mHdr("Lagerung / Transport", atY: cy); cy += 9
        m3([("OK Hochlagerung", m.okHochlagerung), ("Flachlagerung", m.flachlagerung), ("Schocklagerung", m.schocklagerung)], atY: cy); cy += rH
        m3([("stabile Seitenlage", m.linksseitenlage), ("Spineboard", false), ("sitzender Transport", m.sitzenderTransport)], atY: cy); cy += rH
        m3([("Vakuummatratze", m.vakuummatratze), ("Schaufeltrage", m.schaufeltrage), ("Extremitätenschienung", m.extremitaetenschienung)], atY: cy); cy += rH
        m3([("Reposition", false), ("Verband", m.verband), ("Beckenschlinge", m.beckenschlinge)], atY: cy); cy += rH
        cbLabel("Sonstige", checked: false, x: x+2, y: cy, cbSize: 5, gap: 2, labelW: w-12); cy += rH

        // ── Monitoring ────────────────────────────────────────────────────────
        mHdr("Monitoring", atY: cy); cy += 9
        m3([("EKG", m.monEkg), ("12-Kanal-EKG", m.mon12KanalEkg), ("NIBP", m.monNibp)], atY: cy); cy += rH
        m3([("BZ", m.monBz), ("invasive RR Messung", m.monInvasiveRR), ("SpO₂", m.monSpo2)], atY: cy); cy += rH
        m3([("Temperatur", m.monTemperatur), ("Kapnom./Kapnografie", m.monKapnografie), ("Sonstige", false)], atY: cy); cy += rH

        // ── Medizintechnik ────────────────────────────────────────────────────
        mHdr("Medizintechnik", atY: cy); cy += 9
        m3([("Ultraschall/Sono", m.medUltraschall), ("Funk EKG Übermittlung", m.medFunkEkg)], atY: cy); cy += rH
        m3([("Notfallpacer", m.medNotfallspacer), ("Spritzenpumpe", m.medSpritzenpumpe)], atY: cy); cy += rH
        m3([("Video Laryngoskop", m.medVideoLaryngoskop), ("Transportinkubator", m.medTransportinkubator)], atY: cy); cy += rH
        m3([("Mechanische Thoraxkompression", m.medMechThorax), ("Sonstige", false)], atY: cy); cy += rH

        hline(x, cy, w)
        return cy
    }
    @discardableResult
    private static func drawSection65(protokoll: EinsatzProtokoll, y0: CGFloat) -> CGFloat {
        let meds = protokoll.medikamente
        let lx: CGFloat = 4
        let leftW = maaX - 4

        secHeader("6.5 Medikamente", x: lx, y: y0, w: leftW)

        // Column layout proportional to leftW
        let col0W: CGFloat = leftW * 0.37
        let col1W: CGFloat = leftW * 0.11
        let col2W: CGFloat = leftW * 0.08
        let col3W: CGFloat = leftW * 0.08
        let col4W: CGFloat = leftW * 0.08
        let col5W: CGFloat = leftW * 0.11
        let col6W = leftW - col0W - col1W - col2W - col3W - col4W - col5W

        let cols: [(String, CGFloat, CGFloat)] = [
            ("Medikament", lx,                                    col0W),
            ("Dosis",      lx+col0W,                              col1W),
            ("mg",         lx+col0W+col1W,                        col2W),
            ("ml",         lx+col0W+col1W+col2W,                  col3W),
            ("IE",         lx+col0W+col1W+col2W+col3W,            col4W),
            ("Route",      lx+col0W+col1W+col2W+col3W+col4W,      col5W),
            ("Zeit",       lx+col0W+col1W+col2W+col3W+col4W+col5W, col6W),
        ]
        var y = y0 + 10
        for (header, cx, cw) in cols {
            strokeR(CGRect(x: cx, y: y, width: cw, height: 8))
            txt(header, CGRect(x: cx+1.5, y: y+1, width: cw-3, height: 6), font: f5b)
        }
        y += 8

        let medTimeFmt = DateFormatter(); medTimeFmt.dateFormat = "HH:mm"

        let maxRows = 8
        for i in 0..<maxRows {
            let med: MedikamentEintrag? = i < meds.count ? meds[i] : nil
            for (_, cx, cw) in cols { strokeR(CGRect(x: cx, y: y, width: cw, height: 10)) }
            if let med = med {
                txt(med.name,  CGRect(x: lx+1.5,           y: y+2, width: col0W-3,  height: 7), font: f5)
                txt(med.dosis, CGRect(x: lx+col0W+1.5,     y: y+2, width: col1W-3,  height: 7), font: f5)
                switch med.einheit {
                case "mg": txt(med.dosis, CGRect(x: lx+col0W+col1W+1.5,              y: y+2, width: col2W-3, height: 7), font: f5)
                case "ml": txt(med.dosis, CGRect(x: lx+col0W+col1W+col2W+1.5,        y: y+2, width: col3W-3, height: 7), font: f5)
                case "IE": txt(med.dosis, CGRect(x: lx+col0W+col1W+col2W+col3W+1.5,  y: y+2, width: col4W-3, height: 7), font: f5)
                default: break
                }
                txt(med.route, CGRect(x: lx+col0W+col1W+col2W+col3W+col4W+1.5, y: y+2, width: col5W-3, height: 7), font: f5)
                txt(medTimeFmt.string(from: med.zeit), CGRect(x: lx+col0W+col1W+col2W+col3W+col4W+col5W+1.5, y: y+2, width: col6W-3, height: 7), font: f5)
            }
            y += 10
        }
        hline(lx, y, leftW)
        return y
    }
    @discardableResult
    private static func drawSection7(protokoll: EinsatzProtokoll, y0: CGFloat) -> CGFloat {
        let rea   = protokoll.reanimation
        let aktiv = protokoll.reanimationAktiv
        let lx: CGFloat = 4
        let leftW = maaX - 4
        let w = leftW
        let col2 = lx + w/2

        secHeader("7. Reanimation / Tod", x: lx, y: y0, w: w)
        var y = y0 + 10

        // Beginn CPR + Kollaps/Start-Zeiten
        cbLabel("Beginn CPR", checked: aktiv, x: lx+2, y: y, cbSize: 5)
        if let kz = rea.kollapsZeit { txt("Kollaps \(t(kz))", CGRect(x: col2, y: y-0.3, width: w/2-4, height: 6), font: f5) }
        y += 7
        cbLabel("Ersthelfer",     checked: rea.erstHelfer,      x: lx+2,   y: y, cbSize: 5, labelW: 44)
        cbLabel("Vorab Tel.-Rea", checked: rea.vorabTelefonRea, x: lx+56,  y: y, cbSize: 5, labelW: 52)
        cbLabel("Rettungsdienst", checked: aktiv,               x: col2,   y: y, cbSize: 5)
        y += 7
        if let cprS = rea.startErsthelferCPR {
            txt("CPR-Beginn Ersthelfer: \(t(cprS))", CGRect(x: lx+8, y: y, width: w-10, height: 6), font: f5); y += 7
        }
        hline(lx, y, w); y += 2

        // Initialrhythmus + AED
        txt("Initialrhythmus: \(rea.initialRhythmus.rawValue)", CGRect(x: lx+2, y: y, width: w/2-4, height: 6), font: f5)
        cbLabel("AED", checked: rea.aed, x: col2, y: y, cbSize: 5)
        y += 7
        if rea.defiAnzahl > 0 {
            txt("Defibrillation: \(rea.defiAnzahl)× \(rea.defiJoule) J", CGRect(x: lx+2, y: y, width: w-4, height: 6), font: f5); y += 7
        }
        hline(lx, y, w); y += 2

        // ROSC
        cbLabel("ROSC im Verlauf", checked: rea.roscImVerlauf, x: lx+2, y: y, cbSize: 5, labelW: 54)
        cbLabel("niemals ROSC",    checked: rea.nieROSC,       x: col2, y: y, cbSize: 5)
        y += 7
        if let rz = rea.roscZeit { txt("ROSC um \(t(rz))", CGRect(x: lx+8, y: y, width: w-10, height: 6), font: f5); y += 7 }
        cbLabel("erfolgreiche Rea",   checked: rea.erfolgreicheRea,      x: lx+2, y: y, cbSize: 5, labelW: 54)
        cbLabel("KH-Aufn. bei ROSC",  checked: rea.khAufnahmeVorROSC,   x: col2, y: y, cbSize: 5, labelW: 70)
        y += 7
        cbLabel("laufende Reanimation", checked: rea.laufendeReanimation, x: lx+2, y: y, cbSize: 5, labelW: 90)
        y += 7
        txt("Ergebnis: \(rea.outcome.rawValue)", CGRect(x: lx+2, y: y, width: w-4, height: 6), font: f5); y += 7
        hline(lx, y, w); y += 2

        // DNR + Sterbezeitpunkt
        cbLabel("DNR Order", checked: rea.dnrOrder, x: lx+2, y: y, cbSize: 5, labelW: 50)
        if let tod = rea.todFeststellungsZeit {
            txt("Sterbezeitpunkt: \(t(tod))", CGRect(x: col2, y: y-0.3, width: w/2-4, height: 6), font: f5b)
        }
        y += 7
        hline(lx, y, w)
        return y
    }
    private static func drawSection8(protokoll: EinsatzProtokoll, y0: CGFloat) {
        let er = protokoll.ergebnis
        let lx: CGFloat = 4
        let leftW = maaX - 4
        let halfW = leftW / 2

        secHeader("8. Ergebnis", x: lx, y: y0, w: leftW)
        var y = y0 + 10

        // Left part: Ergebnis items
        let ergebnisItems: [(String, Bool)] = [
            ("ambulante Vers. vor Ort",      er.ambulantVorOrt),
            ("Transport ohne NA",            false),
            ("Transport mit NA (NEF)",       false),
            ("Transport mit NA (RTH)",       false),
            ("Übergabe an anderes RM",       false),
            ("Fehleinsatz kein Patient",     false),
            ("Patient nicht transportfähig", er.patNichtTransportfaehig),
            ("Tod an Einsatzstelle",         er.todAnEinsatzstelle),
            ("Sonstige",                     false),
        ]
        for (label, checked) in ergebnisItems {
            cbLabel(label, checked: checked, x: lx+2, y: y, cbSize: 5, gap: 2, labelW: halfW-12)
            y += 6
        }

        // Right part: Einsatzbesonderheiten header + items
        var y2 = y0 + 10
        // Header for right sub-column
        fillR(CGRect(x: lx+halfW, y: y0, width: halfW, height: 10), UIColor(white:0.75, alpha:1))
        txt("Einsatzbesonderheiten", CGRect(x: lx+halfW+2, y: y0+1.5, width: halfW-30, height: 6.5), font: f5b)
        cb(false, x: lx+leftW-22, y: y0+2.5, size: 5)
        txt("keine", CGRect(x: lx+leftW-16, y: y0+2, width: 14, height: 6), font: f5)

        let besItems: [(String, Bool)] = [
            ("nächstes KH nicht aufnehmefähig", er.naechstesKHNichtErreichbar),
            ("Palliation",                       false),
            ("vorsorgl. Bereitstellung",          false),
            ("erhöht. Hygieneaufwand",           er.infektionsSchutz),
            ("Schwerlasttransport",               er.schwerlasttransport),
            ("aufwendige Rettung",                er.aufwaendigeRettung),
            ("kein NA erreichbar",                false),
            ("mehrere Patienten",                 er.mehrerePatient),
            ("Infektionstransport",               false),
            ("MANV",                              false),
            ("verz. Pat.-übergabe",               false),
            ("mehrere Pat.",                      false),
        ]
        for (label, checked) in besItems {
            cbLabel(label, checked: checked, x: lx+halfW+2, y: y2, cbSize: 5, gap: 2, labelW: halfW-12)
            y2 += 6
        }

        // Bottom row: Mitfahrverweigerung | Voranmeldung | Gelb/Rot Alarm
        let bottomY = max(y, y2) + 2
        vline(lx+halfW, y0+10, bottomY - y0 - 10)
        hline(lx, bottomY, leftW)
        var bx = lx + 2
        cbLabel("Mitfahrverweigerung", checked: er.mifahrverweigerung, x: bx, y: bottomY+2, cbSize: 5, gap: 2, labelW: 52); bx += 60
        cbLabel("Voranmeldung",        checked: er.voranmeldung,       x: bx, y: bottomY+2, cbSize: 5, gap: 2, labelW: 38); bx += 46
        cbLabel("Gelb Alarm",          checked: er.gelbAlarm,          x: bx, y: bottomY+2, cbSize: 5, gap: 2, labelW: 32); bx += 40
        cbLabel("Rot Alarm",           checked: er.rotAlarm,           x: bx, y: bottomY+2, cbSize: 5, gap: 2, labelW: 32)
        hline(lx, bottomY+10, leftW)
    }
    @discardableResult
    private static func drawSection9(protokoll: EinsatzProtokoll, y0: CGFloat, maxY: CGFloat = 9999) -> CGFloat {
        let er  = protokoll.ergebnis
        let x   = maaX
        let w   = maaW
        let cw3 = w / 3

        secHeader("9. Übergabe / Transportziel", x: x, y: y0, w: w)
        var y = y0 + 10

        // 3-column grid of destinations (4 rows × 3 cols)
        let zieleGrid: [[( String, Bool)]] = [
            [("ZNA/INA",              er.transportzielZna),
             ("Allgemeinstation",     false),
             ("Schockraum",           false)],
            [("Herzkatheterlabor HKL", er.transportzielKathLabor),
             ("OP direkt",            false),
             ("Intensivstation",      false)],
            [("Stroke Unit",          er.transportzielStrokeUnit),
             ("Fachambulanz",         false),
             ("CPU",                  false)],
            [("Arztpraxis",           false),
             ("Einsatzstelle",        false),
             ("Sonstige",             !er.transportzielSonstigesKH.isEmpty)],
        ]
        for row in zieleGrid {
            for (col, (label, checked)) in row.enumerated() {
                cbLabel(label, checked: checked, x: x+2+CGFloat(col)*cw3, y: y, cbSize: 5, gap: 2, labelW: cw3-12)
            }
            y += 8
        }

        // "Anbei:" rows
        hline(x, y, w); y += 2
        txt("Anbei:", CGRect(x: x+2, y: y+1, width: 20, height: 6), font: f5b)
        cbLabel("Pat.-Doku",      checked: false, x: x+24,       y: y, cbSize: 5, gap: 2, labelW: cw3-26)
        cbLabel("Medikationsplan",checked: false, x: x+24+cw3,   y: y, cbSize: 5, gap: 2, labelW: cw3-12)
        cbLabel("12-Kanal-EKG",   checked: false, x: x+24+2*cw3, y: y, cbSize: 5, gap: 2, labelW: cw3-12)
        y += 8
        cbLabel("Chipkarte",      checked: false, x: x+24,       y: y, cbSize: 5, gap: 2, labelW: cw3-12)
        cbLabel("Prothese",       checked: false, x: x+24+cw3,   y: y, cbSize: 5, gap: 2, labelW: cw3-12)
        cbLabel("Wertsachen",     checked: false, x: x+24+2*cw3, y: y, cbSize: 5, gap: 2, labelW: cw3-12)
        y += 8

        // Bemerkungen text box — fills remaining space up to maxY
        hline(x, y, w); y += 2
        txt("Bemerkungen:", CGRect(x: x+2, y: y+1, width: 45, height: 6), font: f5b)
        let bemH = max(50, maxY - y - 12)
        strokeR(CGRect(x: x, y: y+8, width: w, height: bemH))
        mtxt(er.anmerkungen, CGRect(x: x+2, y: y+10, width: w-4, height: bemH-4), font: f5)
        y += bemH + 8

        hline(x, y, w)
        return y
    }
    private static func drawNaca(protokoll: EinsatzProtokoll, y0: CGFloat) {
        let naca  = protokoll.notfallGeschehen.nacaScoreWert
        let x: CGFloat = 4       // volle Seitenbreite
        let w: CGFloat = W - 8

        secHeader("NACA Score", x: x, y: y0, w: w)
        var cy = y0 + 10
        var bx = x + 2

        for i in 1...7 {
            let isSelected = naca?.rawValue == i
            let boxW: CGFloat = (w - 4) / 7
            let boxR = CGRect(x: bx, y: cy, width: boxW-1, height: 10)
            fillR(boxR, isSelected ? UIColor(white:0.15, alpha:1) : .white)
            strokeR(boxR, lw: 0.4)
            let label: String
            switch i {
            case 1: label = "1 – Geringe Störung"
            case 2: label = "2 – Ambulant"
            case 3: label = "3 – Stationär"
            case 4: label = "4 – Lebensgef. n. ausgeschl."
            case 5: label = "5 – Akute Lebensgef."
            case 6: label = "6 – Reanimation"
            case 7: label = "7 – Tod"
            default: label = "\(i)"
            }
            txt(label, boxR.insetBy(dx: 2, dy: 1.5), font: f5, color: isSelected ? .white : .black)
            bx += boxW
        }
        cy += 10

        // EVM/SOP checkbox
        hline(x, cy, w); cy += 2
        cbLabel("EVM/SOP (nichtärztliches Personal)", checked: false, x: x+2, y: cy, cbSize: 5, gap: 2, labelW: w-12)
        cy += 8

        // Übergabe-Zeile
        hline(x, cy, w); cy += 2
        txt("Übergabe an:", CGRect(x: x+2, y: cy+1, width: 46, height: 7), font: f5)
        txt(protokoll.uebergabeAn, CGRect(x: x+50, y: cy+1, width: w/2-52, height: 7), font: f6b)
        txt("Unterschrift:", CGRect(x: x+w/2, y: cy+1, width: 36, height: 7), font: f5)
        let sigRect = CGRect(x: x+w/2+38, y: cy, width: w/2-40, height: 12)
        strokeR(sigRect, lw: 0.4)
        if let data = protokoll.unterschriftData, let img = UIImage(data: data) {
            let pad: CGFloat = 1
            let avail = sigRect.insetBy(dx: pad, dy: pad)
            let scale = min(avail.width / img.size.width, avail.height / img.size.height)
            let drawW = img.size.width * scale, drawH = img.size.height * scale
            img.draw(in: CGRect(x: avail.minX, y: avail.midY - drawH/2, width: drawW, height: drawH))
        }
        cy += 12
        hline(x, cy, w)
    }
}
