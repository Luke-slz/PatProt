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
}
