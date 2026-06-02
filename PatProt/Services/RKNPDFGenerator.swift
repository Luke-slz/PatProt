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
    private static func drawSection1(protokoll: EinsatzProtokoll) {}
    private static func drawSection2(protokoll: EinsatzProtokoll) {}
    private static func drawSection3(protokoll: EinsatzProtokoll) {}
    private static func drawSection4(protokoll: EinsatzProtokoll) {}
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
