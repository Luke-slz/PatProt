import UIKit

// =========================================================
// MARK: - DLRG Einsatzprotokoll – formgetreues PDF
// =========================================================

struct DINPDFGenerator {

    static let pageSize = CGSize(width: 595.2, height: 841.8)

    // Column X positions (matching original 3-column layout)
    private static let lx: CGFloat = 7    // left edge
    private static let c1: CGFloat = 192  // col 1 → 2 boundary
    private static let c2: CGFloat = 392  // col 2 → 3 boundary
    private static let rx: CGFloat = 588  // right edge

    // Colors
    private static let colBlue   = UIColor(red:0.12, green:0.28, blue:0.50, alpha:1)
    private static let secBlue   = UIColor(red:0.20, green:0.40, blue:0.65, alpha:1)
    private static let subBlue   = UIColor(red:0.45, green:0.62, blue:0.82, alpha:1)
    private static let vLightB   = UIColor(red:0.88, green:0.93, blue:0.98, alpha:1)
    private static let border    = UIColor(white:0.60, alpha:1)
    private static let hlYellow  = UIColor(red:1, green:0.95, blue:0.75, alpha:1)
    private static let checkFill = UIColor(red:0.1, green:0.45, blue:0.15, alpha:1)
    private static let cbBg      = UIColor(red:0.12, green:0.28, blue:0.50, alpha:0.12)

    // Fonts
    private static let f5  = UIFont.systemFont(ofSize: 5.5)
    private static let f5b = UIFont.boldSystemFont(ofSize: 5.5)
    private static let f6  = UIFont.systemFont(ofSize: 6.0)
    private static let f6b = UIFont.boldSystemFont(ofSize: 6.0)
    private static let f7  = UIFont.systemFont(ofSize: 7.0)
    private static let f7b = UIFont.boldSystemFont(ofSize: 7.0)
    private static let f8b = UIFont.boldSystemFont(ofSize: 8.0)
    private static let f10b = UIFont.boldSystemFont(ofSize: 10.0)
    private static let f13b = UIFont.boldSystemFont(ofSize: 13.0)

    // Formatters
    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"; return f
    }()
    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
    private static func d(_ v: Date?) -> String { v.map { dateFmt.string(from: $0) } ?? "" }
    private static func t(_ v: Date?) -> String { v.map { timeFmt.string(from: $0) } ?? "" }

    // ─────────────────────────────────────────────────────
    // MARK: Primitive helpers
    // ─────────────────────────────────────────────────────

    private static func fillRect(_ r: CGRect, _ c: UIColor) {
        c.setFill(); UIRectFill(r)
    }
    private static func strokeRect(_ r: CGRect, _ c: UIColor = UIColor(white:0.60, alpha:1), lw: CGFloat = 0.35) {
        c.setStroke()
        let p = UIBezierPath(rect: r); p.lineWidth = lw; p.stroke()
    }
    private static func hline(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, c: UIColor = UIColor(white:0.60,alpha:1), lw: CGFloat=0.3) {
        c.setStroke(); let p = UIBezierPath(); p.lineWidth=lw
        p.move(to: CGPoint(x:x,y:y)); p.addLine(to: CGPoint(x:x+w,y:y)); p.stroke()
    }
    private static func vline(_ x: CGFloat, _ y: CGFloat, _ h: CGFloat, c: UIColor = UIColor(white:0.60,alpha:1), lw: CGFloat=0.3) {
        c.setStroke(); let p = UIBezierPath(); p.lineWidth=lw
        p.move(to: CGPoint(x:x,y:y)); p.addLine(to: CGPoint(x:x,y:y+h)); p.stroke()
    }

    /// Draw text clipped to rect, single line truncating
    private static func txt(_ s: String, _ r: CGRect,
                             font: UIFont, color: UIColor = .black,
                             align: NSTextAlignment = .left) {
        guard !s.isEmpty else { return }
        let ps = NSMutableParagraphStyle()
        ps.alignment = align; ps.lineBreakMode = .byTruncatingTail
        (s as NSString).draw(in: r, withAttributes: [.font:font,.foregroundColor:color,.paragraphStyle:ps])
    }

    /// Draw text, multiline, returns actual height used
    @discardableResult
    private static func mtxt(_ s: String, _ r: CGRect, font: UIFont) -> CGFloat {
        guard !s.isEmpty else { return 0 }
        let ps = NSMutableParagraphStyle(); ps.alignment = .left
        let attrs: [NSAttributedString.Key:Any] = [.font:font,.paragraphStyle:ps]
        let br = (s as NSString).boundingRect(with: CGSize(width:r.width,height:r.height),
            options:.usesLineFragmentOrigin, attributes:attrs, context:nil)
        (s as NSString).draw(in: CGRect(x:r.minX,y:r.minY,width:r.width,height:min(ceil(br.height)+2,r.height)),
            withAttributes:attrs)
        return min(ceil(br.height)+4, r.height)
    }

    /// Height needed to render s within width, clamped to [minH, maxH]
    private static func fieldH(_ s: String, width: CGFloat, font: UIFont = f7,
                                minH: CGFloat = 11, maxH: CGFloat = 33) -> CGFloat {
        guard !s.isEmpty else { return minH }
        let ps = NSMutableParagraphStyle()
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: ps]
        // Tatsächliche Höhe ohne Cap messen, dann auf maxH begrenzen
        let br = (s as NSString).boundingRect(
            with: CGSize(width: width, height: 9999),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        return max(minH, min(ceil(br.height) + 5, maxH))
    }

    // ─────────────────────────────────────────────────────
    // MARK: Form element helpers
    // ─────────────────────────────────────────────────────

    /// Blue section header bar
    private static func secHeader(_ title: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 11) {
        fillRect(CGRect(x:x,y:y,width:w,height:h), secBlue)
        txt(title, CGRect(x:x+3,y:y+2,width:w-6,height:h-4), font:f7b, color:.white)
    }

    /// Light sub-section header
    private static func subHeader(_ title: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 9.5) {
        fillRect(CGRect(x:x,y:y,width:w,height:h), subBlue)
        txt(title, CGRect(x:x+2,y:y+1.5,width:w-4,height:h-3), font:f6b, color:.white)
    }

    /// Labeled field: [label | value]
    private static func field(_ label: String, _ value: String,
                               x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                               lw: CGFloat = 55, hl: Bool = false,
                               lFont: UIFont? = nil, vFont: UIFont? = nil,
                               multiline: Bool = false) {
        let bg = hl ? hlYellow : .white
        fillRect(CGRect(x:x,y:y,width:w,height:h), bg)
        strokeRect(CGRect(x:x,y:y,width:w,height:h))
        if lw > 0 {
            vline(x+lw, y, h)
            txt(label, CGRect(x:x+1.5,y:y+1.5,width:lw-3,height:h-3),
                font:lFont ?? f6, color:.darkGray)
        }
        let vr = CGRect(x:x+lw+1.5, y:y+1.5, width:w-lw-3, height:h-3)
        if multiline {
            mtxt(value, vr, font: vFont ?? f7)
        } else {
            txt(value, vr, font:vFont ?? f7, color:.black)
        }
    }

    /// Just a bordered value box (no label divider)
    private static func valBox(_ value: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                                font: UIFont? = nil, hl: Bool = false) {
        fillRect(CGRect(x:x,y:y,width:w,height:h), hl ? hlYellow : .white)
        strokeRect(CGRect(x:x,y:y,width:w,height:h))
        txt(value, CGRect(x:x+2,y:y+1.5,width:w-4,height:h-3), font:font ?? f7)
    }

    /// Small label above a value box
    private static func labeledVal(_ label: String, _ value: String,
                                    x: CGFloat, y: CGFloat, w: CGFloat, labelH: CGFloat=8, valH: CGFloat=11) {
        txt(label, CGRect(x:x+1,y:y,width:w-2,height:labelH), font:f5, color:.darkGray)
        valBox(value, x:x, y:y+labelH, w:w, h:valH)
    }

    /// Draw one checkbox with label
    private static func cb(_ label: String, _ checked: Bool,
                            x: CGFloat, y: CGFloat, bs: CGFloat = 7, lw: CGFloat = 80) {
        let box = CGRect(x:x, y:y+0.5, width:bs, height:bs)
        if checked { fillRect(box, cbBg) }
        strokeRect(box)
        if checked {
            checkFill.setStroke()
            let tick = UIBezierPath(); tick.lineWidth = 1.1
            tick.move(to: CGPoint(x:box.minX+1,y:box.midY))
            tick.addLine(to: CGPoint(x:box.midX-0.5,y:box.maxY-1.5))
            tick.addLine(to: CGPoint(x:box.maxX-1,y:box.minY+1.5))
            tick.stroke()
        }
        txt(label, CGRect(x:x+bs+1.5,y:y,width:lw,height:bs+2), font:f6)
    }

    /// Row of checkboxes with equal spacing
    private static func cbRow(_ items: [(String,Bool)], x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 10) {
        let colW = w / CGFloat(items.count)
        for (i,(label,checked)) in items.enumerated() {
            let cx = x + CGFloat(i)*colW
            cb(label, checked, x:cx+1, y:y+1, bs:7, lw:colW-11)
        }
    }

    /// Dual-checkbox row: Ankunft (left, read-only style) | Label | Übergabe (right)
    private static func dualCb(_ label: String, ankunft: Bool, uebergabe: Bool,
                                x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        let cbW: CGFloat = 9
        let lblW = w - 2*cbW - 4
        let bg: UIColor = .white
        fillRect(CGRect(x:x, y:y, width:w, height:h), bg)
        strokeRect(CGRect(x:x, y:y, width:w, height:h))
        // Ankunft checkbox (grayed fill when not set)
        let ankBox = CGRect(x:x+1.5, y:y+1, width:cbW-2, height:h-2)
        if ankunft {
            fillRect(ankBox, cbBg)
            checkFill.setStroke()
            let tick = UIBezierPath(); tick.lineWidth = 0.9
            tick.move(to: CGPoint(x:ankBox.minX+1, y:ankBox.midY))
            tick.addLine(to: CGPoint(x:ankBox.midX-0.5, y:ankBox.maxY-1.5))
            tick.addLine(to: CGPoint(x:ankBox.maxX-1, y:ankBox.minY+1.5))
            tick.stroke()
        }
        strokeRect(ankBox)
        // Label
        txt(label, CGRect(x:x+cbW+2, y:y+1, width:lblW, height:h-2), font:f6)
        // Übergabe checkbox
        let uebBox = CGRect(x:x+w-cbW-1.5, y:y+1, width:cbW-2, height:h-2)
        if uebergabe {
            fillRect(uebBox, cbBg)
            checkFill.setStroke()
            let tick2 = UIBezierPath(); tick2.lineWidth = 0.9
            tick2.move(to: CGPoint(x:uebBox.minX+1, y:uebBox.midY))
            tick2.addLine(to: CGPoint(x:uebBox.midX-0.5, y:uebBox.maxY-1.5))
            tick2.addLine(to: CGPoint(x:uebBox.maxX-1, y:uebBox.minY+1.5))
            tick2.stroke()
        }
        strokeRect(uebBox)
    }

    /// Renders only checked dual-checkbox rows (ankunft || uebergabe).
    /// Returns the total height rendered.
    @discardableResult
    private static func filteredDualCb(
        _ items: [(String, Bool, Bool)],
        x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
    ) -> CGFloat {
        let visible = items.filter { $0.1 || $0.2 }
        if visible.isEmpty {
            // single "o.B." row
            let r = CGRect(x: x, y: y, width: w, height: h)
            fillRect(r, .white)
            strokeRect(r)
            txt("o.B.", CGRect(x: x+3, y: y+1.5, width: w-6, height: h-3),
                font: UIFont.italicSystemFont(ofSize: 7), color: .lightGray)
            return h
        }
        for (i, (label, ank, ueb)) in visible.enumerated() {
            dualCb(label, ankunft: ank, uebergabe: ueb, x: x, y: y + CGFloat(i)*h, w: w, h: h)
        }
        return CGFloat(visible.count) * h
    }

    // ─────────────────────────────────────────────────────
    // MARK: - Compact diagnosis group helper
    // ─────────────────────────────────────────────────────

    @discardableResult
    private static func diagGruppe(
        _ title: String, items: [(String, Bool)],
        x: CGFloat, y: CGFloat, w: CGFloat
    ) -> CGFloat {
        let names = items.filter { $0.1 }.map { $0.0 }
        guard !names.isEmpty else { return 0 }
        subHeader(title, x: x, y: y, w: w)
        field("", names.joined(separator: " · "), x: x, y: y + 9.5, w: w, h: 11, lw: 0)
        return 9.5 + 11
    }

    /// Shows ALL dual-checkbox rows (not filtered) — matches reference form style
    @discardableResult
    private static func allDualCb(
        _ items: [(String, Bool, Bool)],
        x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
    ) -> CGFloat {
        for (i, (label, ank, ueb)) in items.enumerated() {
            let bg: UIColor = i % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            fillRect(CGRect(x: x, y: y + CGFloat(i)*h, width: w, height: h), bg)
            dualCb(label, ankunft: ank, uebergabe: ueb, x: x, y: y + CGFloat(i)*h, w: w, h: h)
        }
        return CGFloat(items.count) * h
    }

    /// Compact checkbox column — shows ALL items (checked or not), like the reference form
    @discardableResult
    private static func cbCol(
        _ title: String, items: [(String, Bool)],
        x: CGFloat, y: CGFloat, w: CGFloat, rowH: CGFloat = 8.0
    ) -> CGFloat {
        subHeader(title, x: x, y: y, w: w, h: 8.5)
        var cy = y + 8.5
        for (i, (label, checked)) in items.enumerated() {
            let bg: UIColor = i % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            fillRect(CGRect(x: x, y: cy, width: w, height: rowH), bg)
            strokeRect(CGRect(x: x, y: cy, width: w, height: rowH))
            cb(label, checked, x: x + 2, y: cy + 0.5, bs: 6, lw: w - 10)
            cy += rowH
        }
        return cy - y
    }

    // ─────────────────────────────────────────────────────
    // MARK: - MAIN GENERATE
    // ─────────────────────────────────────────────────────

    static func generate(protokoll: EinsatzProtokoll) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin:.zero, size:pageSize))
        let fname = protokoll.einsatzOrt.einsatzNummer.isEmpty
            ? "Protokoll" : "Protokoll_\(protokoll.einsatzOrt.einsatzNummer)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fname).pdf")
        do {
            try renderer.writePDF(to: url) { ctx in
                // 36pt (~half-inch) safety margin so nothing is clipped on a standard printer
                let m: CGFloat = 36
                let sx = (pageSize.width - 2*m) / pageSize.width
                let sy = (pageSize.height - 2*m) / pageSize.height
                func applyMarginTransform() {
                    ctx.cgContext.translateBy(x: m, y: m)
                    ctx.cgContext.scaleBy(x: sx, y: sy)
                }
                ctx.beginPage()
                applyMarginTransform()
                drawPage1(p: protokoll)
                ctx.beginPage()
                applyMarginTransform()
                drawPage2(p: protokoll)
                let messungen = protokoll.verlaufMessungen.sorted(by: { $0.zeitpunkt < $1.zeitpunkt })
                if messungen.count >= 2 {
                    ctx.beginPage()
                    applyMarginTransform()
                    drawVerlaufsTabellenSeite(p: protokoll, messungen: messungen)
                    ctx.beginPage()
                    applyMarginTransform()
                    drawVerlaufsChart(p: protokoll, messungen: messungen)
                }
                drawFotoPages(ctx: ctx,
                              mediFotos: protokoll.medikamentFotos,
                              patFotos: protokoll.fotos,
                              erstelltAm: protokoll.erstelltAm)
            }
            return url
        } catch {
            print("PDF-Generierung fehlgeschlagen: \(error)")
            return nil
        }
    }

    // ─────────────────────────────────────────────────────
    // MARK: - PAGE 1  (Seiten 1+2 des Originals)
    // Sections: Insurance · 1 Rettungstech · 2 Anamnese · 3 Befunde · 4.1 Diagnose
    // ─────────────────────────────────────────────────────

    private static func drawPage1(p: EinsatzProtokoll) {

        // ═══════════════════════════════════════════════════
        // KOPFBEREICH — wie Referenzprotokoll (kein voller Balken)
        // ═══════════════════════════════════════════════════

        let lw = c1 - lx   // = 185pt linke Spaltenbreite
        let rw = rx - c1   // = 396pt rechte Spaltenbreite
        let fh: CGFloat = 9 // Feldhöhe im Kopf

        // ── Linke Spalte oben: Versicherung / Patient ──────
        var ly: CGFloat = 7
        // Krankenkasse
        field("Krankenkasse bzw. Kostenträger", p.patientDaten.kostentraeger,
              x:lx, y:ly, w:lw, h:fh, lw:lw*0.52)
        ly += fh
        // Name
        field("Name, Vorname des Versicherten",
              "\(p.patientDaten.nachname), \(p.patientDaten.vorname)",
              x:lx, y:ly, w:lw, h:fh, lw:lw*0.52, hl:true)
        ly += fh
        // geb.am + Alter
        let gebStr: String = {
            var s = d(p.patientDaten.geburtsDatum)
            if let a = p.patientDaten.alter { s += s.isEmpty ? "\(a) J." : " (\(a) J.)" }
            return s
        }()
        field("geb. am", gebStr, x:lx, y:ly, w:lw*0.6, h:fh, lw:32)
        let geschStr = p.patientDaten.geschlecht == .maennlich ? "m" :
                       p.patientDaten.geschlecht == .weiblich  ? "w" : "unbek."
        field("Geschl.", geschStr, x:lx+lw*0.6, y:ly, w:lw*0.4, h:fh, lw:30)
        ly += fh
        // Versicherten-Nr + Status
        field("Versicherten-Nr.", p.patientDaten.versicherungsNummer,
              x:lx, y:ly, w:lw*0.65, h:fh, lw:lw*0.38)
        field("Status", "", x:lx+lw*0.65, y:ly, w:lw*0.35, h:fh, lw:28)
        ly += fh
        // Betriebsstätten-Nr / Arzt-Nr / Datum
        field("Betriebs-Nr.", "", x:lx,           y:ly, w:lw*0.38, h:fh, lw:lw*0.22)
        field("Arzt-Nr.",     "", x:lx+lw*0.38,   y:ly, w:lw*0.32, h:fh, lw:lw*0.19)
        field("Datum", d(p.einsatzOrt.alarmzeit),  x:lx+lw*0.70, y:ly, w:lw*0.30, h:fh, lw:22)
        ly += fh   // ly ≈ 52

        // ── Rechte Spalte oben: Section 1 ──────────────────
        var ry: CGFloat = 7
        let rx1 = c1

        secHeader("1. Rettungstechnische Daten", x:rx1, y:ry, w:rw)
        ry += 11

        // Fahrzeug-Zeile
        let fzUp = p.einsatzOrt.fahrzeugName.uppercased()
        let vItems: [(String, Bool)] = [
            ("RTW", fzUp.contains("RTW")), ("KTW", fzUp.contains("KTW")),
            ("NEF", fzUp.contains("NEF")), ("NAW", fzUp.contains("NAW")),
            ("Baby NAW", fzUp.contains("BABY")), ("V-RTW", fzUp.contains("V-RTW")),
        ]
        let vColW2 = rw * 0.60 / CGFloat(vItems.count)
        fillRect(CGRect(x:rx1, y:ry, width:rw, height:10), .white)
        strokeRect(CGRect(x:rx1, y:ry, width:rw, height:10))
        for (i,(label,checked)) in vItems.enumerated() {
            cb(label, checked, x:rx1+CGFloat(i)*vColW2+1, y:ry+1.5, bs:7, lw:vColW2-10)
        }
        // Sondersignal + Notarzt rechts neben Fahrzeuge
        cb("Sondersignal",     p.einsatzOrt.sondersignal, x:rx1+rw*0.62, y:ry+1.5, bs:7, lw:45)
        cb("mit Patient",      p.einsatzOrt.mitPatient,   x:rx1+rw*0.77, y:ry+1.5, bs:7, lw:40)
        ry += 10

        // Notarzt-Zeile
        fillRect(CGRect(x:rx1, y:ry, width:rw, height:9), .white)
        strokeRect(CGRect(x:rx1, y:ry, width:rw, height:9))
        cb("Notarzt nachgefordert", p.einsatzOrt.notarzt, x:rx1+2, y:ry+1, bs:7, lw:80)
        field("Weitere Rettungsmittel", p.einsatzOrt.weitereEinsatzmittel.joined(separator:","),
              x:rx1+rw*0.35, y:ry, w:rw*0.65, h:9, lw:60)
        ry += 9

        // Einsatzort-Zeile (E-Srt A1)
        let plzOrt = [p.einsatzOrt.plz, p.einsatzOrt.ort].filter { !$0.isEmpty }.joined(separator: " ")
        let adresseVoll = [p.einsatzOrt.adresse, p.einsatzOrt.zusatz, plzOrt].filter { !$0.isEmpty }.joined(separator: ", ")
        fillRect(CGRect(x:rx1, y:ry, width:rw, height:10), .white)
        strokeRect(CGRect(x:rx1, y:ry, width:rw, height:10))
        txt("E-Srt A1", CGRect(x:rx1+1, y:ry+1.5, width:28, height:7), font:f5b, color:colBlue)
        field("Einsatzort / Adresse", adresseVoll,
              x:rx1+30, y:ry, w:rw-30, h:10, lw:65)
        ry += 10

        // Stichwort-Zeile (E-Srt A2)
        let stichwortText = [p.einsatzOrt.stichwort, p.einsatzOrt.einsatzArt].filter{!$0.isEmpty}.joined(separator:" · ")
        fillRect(CGRect(x:rx1, y:ry, width:rw, height:10), .white)
        strokeRect(CGRect(x:rx1, y:ry, width:rw, height:10))
        txt("E-Srt A2", CGRect(x:rx1+1, y:ry+1.5, width:28, height:7), font:f5b, color:colBlue)
        field("Stichwort", stichwortText, x:rx1+30, y:ry, w:rw*0.55, h:10, lw:38)
        field("Einsatz-Nr.", p.einsatzOrt.einsatzNummer, x:rx1+30+rw*0.55, y:ry, w:rw-30-rw*0.55, h:10, lw:40)
        ry += 10   // ry ≈ 57

        // ── EINSATZPROTOKOLL Block (links, ab ly≈52) ────────
        let epY: CGFloat = ly
        let epH: CGFloat = 88  // Höhe des EP-Blocks

        fillRect(CGRect(x:lx, y:epY, width:lw, height:epH), vLightB)
        strokeRect(CGRect(x:lx, y:epY, width:lw, height:epH))
        // Titel
        txt("EINSATZPROTOKOLL",
            CGRect(x:lx+3, y:epY+2, width:lw-6, height:13), font:f10b, color:colBlue)
        // Qualifikation
        let eqY = epY + 16
        cb("Notarzt",           p.verfasser == .arzt,               x:lx+3,    y:eqY,   bs:6, lw:38)
        cb("NotSan/RettAss/RS", p.verfasser != .arzt,               x:lx+3,    y:eqY+9, bs:6, lw:65)
        // Organisation
        let orgY = eqY + 19
        txt("DLRG Herzogtum Lauenburg",
            CGRect(x:lx+3, y:orgY, width:lw-6, height:8), font:f6b, color:colBlue)
        // Trennlinie
        hline(lx+2, orgY+9, lw-4, c:subBlue)
        // Einsatznummer
        let enrY = orgY + 11
        txt("Einsatznummer:", CGRect(x:lx+3, y:enrY, width:lw-6, height:7), font:f5, color:.darkGray)
        txt(p.einsatzOrt.einsatzNummer.isEmpty ? "—" : p.einsatzOrt.einsatzNummer,
            CGRect(x:lx+3, y:enrY+7, width:lw-6, height:12), font:f13b, color:colBlue)
        // Datum + Standort
        let datY = enrY + 20
        txt("Datum:", CGRect(x:lx+3, y:datY, width:25, height:7), font:f5, color:.darkGray)
        txt(d(p.einsatzOrt.alarmzeit), CGRect(x:lx+28, y:datY, width:50, height:7), font:f6b, color:.black)
        txt("Standort RM:", CGRect(x:lx+3, y:datY+8, width:42, height:7), font:f5, color:.darkGray)
        field("", p.einsatzOrt.fahrzeugName, x:lx+3, y:datY+15, w:lw-6, h:8, lw:0)
        // Geschlecht
        let geY = datY + 24
        cb("männlich",  p.patientDaten.geschlecht == .maennlich, x:lx+3,   y:geY, bs:6, lw:38)
        cb("weiblich",  p.patientDaten.geschlecht == .weiblich,  x:lx+60,  y:geY, bs:6, lw:35)
        // Einsatzabbruch
        let eaY = geY + 9
        cb("Einsatzabbruch",      false, x:lx+3,  y:eaY, bs:6, lw:55)
        cb("Transportverweigerung", p.ergebnis.mifahrverweigerung, x:lx+3, y:eaY+9, bs:6, lw:70)

        // ── Section 1 – Uhrzeiten (8 Felder, rechts ab ry≈57) ──
        let tY = ry
        let tItems: [(String, String)] = [
            ("Alarm",      t(p.einsatzOrt.alarmzeit)),
            ("Ausfahrt",   ""),
            ("Ankunft",    t(p.einsatzOrt.ankunftzeit)),
            ("Alarm. NA",  ""),
            ("Abfahrt",    t(p.einsatzOrt.endeZeit)),
            ("Übergabe",   t(p.einsatzOrt.uebergabeZeit)),
            ("Einsatzzeit",""),
            ("Ende",       ""),
        ]
        let tW3 = rw / CGFloat(tItems.count)
        for (i,(label,value)) in tItems.enumerated() {
            let tx = rx1 + CGFloat(i)*tW3
            // Uhr-Symbol + Label oben
            fillRect(CGRect(x:tx, y:tY, width:tW3, height:7), vLightB)
            strokeRect(CGRect(x:tx, y:tY, width:tW3, height:7))
            txt(label, CGRect(x:tx+1, y:tY+0.5, width:tW3-2, height:6), font:f5, color:colBlue, align:.center)
            // Wert-Box unten
            valBox(value, x:tx, y:tY+7, w:tW3, h:11)
        }
        ry = tY + 18

        // Transport + km Zeile
        fillRect(CGRect(x:rx1, y:ry, width:rw, height:9), .white)
        strokeRect(CGRect(x:rx1, y:ry, width:rw, height:9))
        let kW = rw / 4
        txt("km:",       CGRect(x:rx1+2,     y:ry+1, width:15, height:7), font:f5, color:.darkGray)
        vline(rx1+kW,    ry, 9)
        txt("km ges.:",  CGRect(x:rx1+kW+2,  y:ry+1, width:25, height:7), font:f5, color:.darkGray)
        vline(rx1+kW*2,  ry, 9)
        txt("Patient:",  CGRect(x:rx1+kW*2+2,y:ry+1, width:30, height:7), font:f5, color:.darkGray)
        vline(rx1+kW*3,  ry, 9)
        txt("gesamt:",   CGRect(x:rx1+kW*3+2,y:ry+1, width:30, height:7), font:f5, color:.darkGray)
        ry += 9

        // Qualifikation
        fillRect(CGRect(x:rx1, y:ry, width:rw, height:9), .white)
        strokeRect(CGRect(x:rx1, y:ry, width:rw, height:9))
        let qualItems: [(String, Bool)] = [
            ("NotSan",       p.verfasser == .notfallsanitaeter),
            ("NotAss/RS",    p.verfasser == .rettungssanitaeter),
            ("SanB",         p.verfasser == .sanitaeterB),
            ("Arzt",         p.verfasser == .arzt),
        ]
        let qW = rw * 0.62 / CGFloat(qualItems.count)
        for (i,(label,checked)) in qualItems.enumerated() {
            cb(label, checked, x:rx1+CGFloat(i)*qW+1, y:ry+1, bs:6, lw:qW-9)
        }
        field("Praktikant", "", x:rx1+rw*0.64, y:ry, w:rw*0.36, h:9, lw:38)
        ry += 9

        // Personal-Zeile
        let bestEntries = [(p.besatzung.sanitaeter1, p.besatzung.qualifikation1),
                           (p.besatzung.sanitaeter2, p.besatzung.qualifikation2)]
        let bestText = bestEntries.filter{!$0.0.isEmpty}.map{"\($0.0) (\($0.1.rawValue))"}.joined(separator:" · ")
        field("Besatzung", bestText, x:rx1, y:ry, w:rw, h:9, lw:38)
        ry += 9

        // Vorsorgebevollmächtigte
        field("Vorsorgebevollm./Betreuer", "", x:rx1, y:ry, w:rw*0.55, h:9, lw:80)
        field("Name / Telefon", "", x:rx1+rw*0.55, y:ry, w:rw*0.45, h:9, lw:50)
        ry += 9

        var y = max(ly + epH, ry) + 2

        // ── SECTION 2 ──────────────────────────────────────
        secHeader("2. Notfallgeschehen / Anamnese / Erstbefund", x:lx, y:y, w:rx-lx)
        y += 11

        // Notfallgeschehen Felder
        let ng = p.notfallGeschehen
        if !ng.erstbefundVorOrt.isEmpty {
            let h = fieldH(ng.erstbefundVorOrt, width: rx-lx-53)
            field("Erstbefund", ng.erstbefundVorOrt, x:lx, y:y, w:rx-lx, h:h, lw:50, multiline: true)
            y += h
        }
        if !ng.patientGefunden.isEmpty || ng.manv {
            let beteiligteLabel = ng.manv
                ? "MANV\(ng.ersteEintreffendeKraft ? " · 1. Eintreffend" : "") · \(ng.anzahlBeteiligte) Bet.\(ng.manvEigeneSK.isEmpty ? "" : " · \(ng.manvEigeneSK)")"
                : "\(ng.anzahlBeteiligte) Beteiligter"
            let halbW = (rx - lx) / 2
            field("Pat. vorgef.", ng.patientGefunden, x:lx, y:y, w:halbW, h:11, lw:52)
            field("Beteiligte", beteiligteLabel, x:lx + halbW, y:y, w:halbW, h:11, lw:45)
            y += 11
        }
        if ng.manv && ng.ersteEintreffendeKraft && ng.manvGesamtSK > 0 {
            let tW = (rx - lx) / 5
            labeledVal("SK I", "\(ng.manvSK1)",  x:lx,       y:y, w:tW, labelH:7, valH:11)
            labeledVal("SK II", "\(ng.manvSK2)", x:lx+tW,    y:y, w:tW, labelH:7, valH:11)
            labeledVal("SK III","\(ng.manvSK3)", x:lx+tW*2,  y:y, w:tW, labelH:7, valH:11)
            labeledVal("SK IV", "\(ng.manvSK4)", x:lx+tW*3,  y:y, w:tW, labelH:7, valH:11)
            labeledVal("✝",     "\(ng.manvVerstorben)", x:lx+tW*4, y:y, w:tW, labelH:7, valH:11)
            y += 18
        }
        if ng.manv && ng.ersteEintreffendeKraft {
            let pulsWert = [ng.priorPuls, ng.priorPulsFrequenz].filter { !$0.isEmpty }.joined(separator: " ")
            let respWert = [ng.priorRespiration, ng.priorRespFrequenz].filter { !$0.isEmpty }.joined(separator: " ")
            let priorRows: [(String, String)] = [
                ("P – Puls",         pulsWert),
                ("R – Respiration",  respWert),
                ("I – Intoxikation", ng.priorIntoxikation),
                ("O – Orientierung", ng.priorOrientierung),
                ("R – Reizaufnahme", ng.priorReizaufnahme),
            ].filter { !$0.1.isEmpty }
            if !priorRows.isEmpty {
                subHeader("PRIOR-Triage", x: lx, y: y, w: rx-lx)
                y += 9.5
                let priorHalf = (rx - lx) / CGFloat(min(priorRows.count, 3))
                for (i, (label, val)) in priorRows.enumerated() {
                    let col = i % 3; let row = i / 3
                    field(label, val, x: lx + CGFloat(col)*priorHalf, y: y + CGFloat(row)*11,
                          w: priorHalf, h: 11, lw: 68)
                }
                let priorRows2 = (priorRows.count + 2) / 3
                y += CGFloat(priorRows2) * 11
            }
        }
        // ── PRIOR Personenliste ──
        if ng.manv && !ng.triagiertePersonen.isEmpty {
            subHeader("PRIOR-Triage Personenliste", x: lx, y: y, w: rx-lx)
            y += 9.5
            let totalW = rx - lx
            let cNr:  CGFloat = 18
            let cSK:  CGFloat = 42
            let cP:   CGFloat = 75
            let cR:   CGFloat = 75
            let cI:   CGFloat = 50
            let cO:   CGFloat = 68
            let cBem: CGFloat = totalW - cNr - cSK - cP - cR - cI - cO
            let rowH: CGFloat = 10
            // Kopfzeile
            let headers = [
                (cNr, "Nr."), (cSK, "SK"), (cP, "P – Puls"),
                (cR, "R – Resp."), (cI, "I – Intox."), (cO, "O – Orient."), (cBem, "Bemerkung")
            ]
            var cx = lx
            for (w, h) in headers {
                fillRect(CGRect(x: cx, y: y, width: w, height: rowH), subBlue)
                strokeRect(CGRect(x: cx, y: y, width: w, height: rowH))
                txt(h, CGRect(x: cx+2, y: y+1.5, width: w-4, height: rowH-3), font: f6b, color: .white)
                cx += w
            }
            y += rowH
            // Datenzeilen
            for person in ng.triagiertePersonen {
                let pulsWert = [person.priorPuls, person.priorPulsFrequenz].filter { !$0.isEmpty }.joined(separator: " ")
                let respWert = [person.priorRespiration, person.priorRespFrequenz].filter { !$0.isEmpty }.joined(separator: " ")
                let cols: [(CGFloat, String)] = [
                    (cNr,  "P\(person.nummer)"),
                    (cSK,  person.sichtungskategorie.isEmpty ? (person.vorgeschlagenesk.isEmpty ? "–" : "→\(person.vorgeschlagenesk)") : person.sichtungskategorie),
                    (cP,   pulsWert.isEmpty ? "–" : pulsWert),
                    (cR,   respWert.isEmpty ? "–" : respWert),
                    (cI,   person.priorIntoxikation),
                    (cO,   person.priorOrientierung.isEmpty ? "–" : person.priorOrientierung),
                    (cBem, person.bemerkung),
                ]
                var colX = lx
                for (w, val) in cols {
                    valBox(val, x: colX, y: y, w: w, h: rowH, font: f6)
                    colX += w
                }
                y += rowH
            }
            y += 2
        }

        if !ng.manvLagemeldung.isEmpty {
            field("Lagemeldung", ng.manvLagemeldung, x:lx, y:y, w:rx-lx, h:11, lw:55)
            y += 11
        }
        if !ng.manvNachforderung.isEmpty {
            field("Nachforderung", ng.manvNachforderung, x:lx, y:y, w:rx-lx, h:11, lw:60)
            y += 11
        }
        if !ng.ersthelferMassnahmen.isEmpty {
            let h = fieldH(ng.ersthelferMassnahmen, width: rx-lx-53)
            field("Ersthelfer", ng.ersthelferMassnahmen, x:lx, y:y, w:rx-lx, h:h, lw:50, multiline: true)
            y += h
        }

        // Neue Notfallgeschehen-Felder
        let unfallHergangText = (ng.unfallhergangAuswahl + (ng.unfallhergangFreitext.isEmpty ? [] : [ng.unfallhergangFreitext])).joined(separator: ", ")
        if !unfallHergangText.isEmpty {
            let h = fieldH(unfallHergangText, width: rx-lx-68)
            field("Unfallhergang", unfallHergangText, x:lx, y:y, w:rx-lx, h:h, lw:65, multiline: true)
            y += h
        }
        let unfallMechText = [ng.unfallmechanismus, ng.unfallmechanismusFreitext].filter{!$0.isEmpty}.joined(separator: " – ")
        if !unfallMechText.isEmpty {
            let h = fieldH(unfallMechText, width: rx-lx-75)
            field("Unfallmechanismus", unfallMechText, x:lx, y:y, w:rx-lx, h:h, lw:72, multiline: true)
            y += h
        }
        if !ng.preEmergencyStatus.isEmpty {
            let h = fieldH(ng.preEmergencyStatus, width: rx-lx-88)
            field("Pre-Emergency Status", ng.preEmergencyStatus, x:lx, y:y, w:rx-lx, h:h, lw:85, multiline: true)
            y += h
        }
        let erstbefundAuswahlText = ng.erstbefundAuswahl.joined(separator: ", ")
        if !erstbefundAuswahlText.isEmpty {
            let h = fieldH(erstbefundAuswahlText, width: rx-lx-88)
            field("Erstbefund (Auswahl)", erstbefundAuswahlText, x:lx, y:y, w:rx-lx, h:h, lw:85, multiline: true)
            y += h
        }
        if !ng.verlaufsbemerkungen.isEmpty {
            let h = fieldH(ng.verlaufsbemerkungen, width: rx-lx-88)
            field("Verlaufsbemerkungen", ng.verlaufsbemerkungen, x:lx, y:y, w:rx-lx, h:h, lw:85, multiline: true)
            y += h
        }
        if !ng.notfallFreitext.isEmpty {
            let h = fieldH(ng.notfallFreitext, width: rx-lx-58)
            field("Ergänzungen", ng.notfallFreitext, x:lx, y:y, w:rx-lx, h:h, lw:55, multiline: true)
            y += h
        }
        if !ng.dynamischeErweiterung.isEmpty {
            let h = fieldH(ng.dynamischeErweiterung, width: rx-lx-88)
            field("Dyn. Erweiterung", ng.dynamischeErweiterung, x:lx, y:y, w:rx-lx, h:h, lw:85, multiline: true)
            y += h
        }

        // ABCDE grid
        let abcdeLetters = ["A","B","C","D","E"]
        func buildAirwayDetail() -> String {
            var parts = [p.airway.freitext]
            if p.airway.verlegung && !p.airway.verlegungsUrsache.isEmpty { parts.append("Ursache: \(p.airway.verlegungsUrsache)") }
            if p.airway.intubiert  { parts.append("ETI") }
            if p.airway.konikotomie { parts.append("Konikotomie") }
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        func buildBreathingDetail() -> String {
            var parts = [p.breathing.freitext]
            if !p.breathing.atemgeraeusche.isEmpty { parts.append("Atemger.: \(p.breathing.atemgeraeusche)") }
            if p.massnahmen.sauerstoffgabe && !p.massnahmen.sauerstoffLitMin.isEmpty { parts.append("O₂: \(p.massnahmen.sauerstoffLitMin) l/min") }
            if p.breathing.beatmung && !p.breathing.beatmungsform.isEmpty { parts.append("Beatm.: \(p.breathing.beatmungsform)") }
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        func buildCirculationDetail() -> String {
            var parts = [p.circulation.freitext]
            if p.circulation.pulslosigkeit { parts.append("Pulslos") }
            else if !p.circulation.pulsRhythmus.isEmpty { parts.append("Rhythmus: \(p.circulation.pulsRhythmus)") }
            if p.circulation.ekg {
                let c = p.circulation
                if !c.ekgBefund.isEmpty { parts.append("EKG-Befund: \(c.ekgBefund)") }
                let ekgFlags: [(Bool, String)] = [
                    (c.sinusrhythmus,          "Sinusrhythmus"),
                    (c.absoluteArrhythmie,     "Abs. Arrhythmie"),
                    (c.avBlockI,               "AV-Block I°"),
                    (c.avBlockII,              "AV-Block II°"),
                    (c.avBlockIII,             "AV-Block III°"),
                    (c.qrsTachykardieBreit,    "QRS-Tachy breit"),
                    (c.qrsTachykardieSchmal,   "QRS-Tachy schmal"),
                    (c.kammerflimmern,         "Kammerflimmern (VF)"),
                    (c.kammerflattern,         "Kammerflattern (VFlutter)"),
                    (c.pea,                    "PEA"),
                    (c.asystolie,              "Asystolie"),
                    (c.schrittmacher,          "Schrittmacher"),
                    (c.infarktEkg,             "Infarkt-EKG"),
                    (c.sves,                   "SVES"),
                    (c.ves,                    "VES"),
                    (c.extrasystolenMonomorph, "Extrasyst. mono"),
                    (c.extrasystolenPolymorph, "Extrasyst. poly"),
                    (c.cNichtBeurteilbar,      "Nicht beurteilbar"),
                ]
                let active = ekgFlags.filter(\.0).map(\.1)
                let ekgSummary = active.isEmpty ? "EKG abgeleitet" : "EKG: \(active.joined(separator: ", "))"
                parts.append(ekgSummary)
            }
            if p.circulation.blutung && !p.circulation.blutungLokalisation.isEmpty { parts.append("Blutung: \(p.circulation.blutungLokalisation)") }
            if p.massnahmen.peripherVenoes && !p.massnahmen.peripherVenoesOrt.isEmpty {
                var pvk = "PVK"
                if !p.massnahmen.peripherVenoesGroesse.isEmpty { pvk += " \(p.massnahmen.peripherVenoesGroesse) G" }
                pvk += " (\(p.massnahmen.peripherVenoesOrt))"
                parts.append(pvk)
            }
            if p.massnahmen.intraossaer {
                parts.append("IO\(p.massnahmen.intraossaerOrt.isEmpty ? "" : " (\(p.massnahmen.intraossaerOrt))")")
            }
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        func buildExposureDetail() -> String {
            var parts = [p.exposure.freitext]
            if p.exposure.trauma && !p.exposure.traumaMechanismus.isEmpty { parts.append("Mech.: \(p.exposure.traumaMechanismus)") }
            if !p.exposure.sichtbareDeformitaeten.isEmpty { parts.append("Deform.: \(p.exposure.sichtbareDeformitaeten)") }
            if !p.exposure.schmerzLokalisation.isEmpty { parts.append("Schmerz: \(p.exposure.schmerzLokalisation)") }
            var flags: [String] = []
            if p.exposure.helmGetragen { flags.append("Helm getragen") }
            if p.exposure.gurtGetragen { flags.append("Gurt getragen") }
            if p.exposure.frakturVerdacht { flags.append("Frakturverdacht") }
            if p.exposure.blutungExtern { flags.append("Blutung extern") }
            if p.exposure.rueckenNackenSchmerz { flags.append("Rücken/Nackenschmerz") }
            if p.exposure.bewegungseinschraenkung { flags.append("Bewegungseinschr.") }
            if p.exposure.bewusstseinsverlust { flags.append("Bewusstseinsverlust") }
            if p.exposure.oedeme { flags.append("Ödeme") }
            if p.exposure.stehendeHautfalten { flags.append("Stehende Hautfalten") }
            if p.exposure.kaltschweissig { flags.append("Kaltschweißig") }
            if p.exposure.dekubitus { flags.append("Dekubitus") }
            if p.exposure.exanthem { flags.append("Exanthem") }
            if p.exposure.hautNichtUntersucht { flags.append("Haut n. untersucht") }
            if p.exposure.hautNichtBeurteilbar { flags.append("Haut n. beurteilbar") }
            if !flags.isEmpty { parts.append(flags.joined(separator: ", ")) }
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        func buildDisabilityDetail() -> String {
            var parts = [p.disability.freitext]
            if p.disability.befastAktiv {
                var flags: [String] = []
                if p.disability.befastBalance { flags.append("Balance") }
                if p.disability.befastEyes    { flags.append("Eyes") }
                if p.disability.befastFace    { flags.append("Face") }
                if p.disability.befastArm     { flags.append("Arm") }
                if p.disability.befastSpeech  { flags.append("Speech") }
                var befastStr = "BEFAST: \(flags.isEmpty ? "aktiviert" : flags.joined(separator: ", "))"
                if p.disability.befastZeitUnbekannt {
                    befastStr += " · T: unbekannt"
                } else if let ts = p.disability.befastSymptombeginn {
                    let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
                    befastStr += " · T: \(fmt.string(from: ts)) Uhr"
                }
                parts.append(befastStr)
            }
            if p.disability.zopAktiv && !p.disability.zopText.isEmpty {
                parts.append("ZOP \(p.disability.zopText)")
            }
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        // ── ABCDE (links) + SAMPLER (rechts) NEBENEINANDER ──
        let abcdeRaw = [buildAirwayDetail(), buildBreathingDetail(), buildCirculationDetail(), buildDisabilityDetail(), buildExposureDetail()]
        let abcdeVals   = abcdeRaw.map { $0.isEmpty ? "o.B." : $0 }
        let abcdeColors = abcdeRaw.map { $0.isEmpty ? UIColor.lightGray : UIColor.black }

        let abcdeColW = (rx - lx) * 0.62  // ABCDE left column
        let samplerX  = lx + abcdeColW
        let samplerW  = rx - samplerX       // SAMPLER right column
        let sec2StartY = y

        // ABCDE left column — FESTE Zeilenhöhe 11pt wie Referenzformular
        let abcdeRowH: CGFloat = 11
        var abcdeY = sec2StartY
        let abcdeContentW = abcdeColW - 12
        for i in 0..<5 {
            let isOB = abcdeRaw[i].isEmpty
            fillRect(CGRect(x:lx, y:abcdeY, width:12, height:abcdeRowH), subBlue)
            txt(abcdeLetters[i], CGRect(x:lx+1, y:abcdeY+2, width:10, height:abcdeRowH-4),
                font:f7b, color:.white, align:.center)
            fillRect(CGRect(x:lx+12, y:abcdeY, width:abcdeContentW, height:abcdeRowH),
                     i%2==0 ? .white : UIColor(white:0.97,alpha:1))
            strokeRect(CGRect(x:lx+12, y:abcdeY, width:abcdeContentW, height:abcdeRowH))
            let displayVal = abcdeVals[i]
            txt(displayVal, CGRect(x:lx+14, y:abcdeY+2, width:abcdeContentW-4, height:abcdeRowH-4),
                font: isOB ? UIFont.italicSystemFont(ofSize: 6) : f6,
                color: isOB ? .lightGray : abcdeColors[i])
            abcdeY += abcdeRowH
        }

        // SAMPLER right column
        let letztesMahlText: String = {
            if p.sampler.letztesMahlUnbekannt { return "Unbekannt" }
            let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
            let was = p.sampler.letztesMahl.isEmpty ? "–" : p.sampler.letztesMahl
            if let zeit = p.sampler.letztesMahlZeit { return "\(was) · \(fmt.string(from: zeit)) Uhr" }
            return was
        }()
        let schwangerschaftText: String = {
            switch p.sampler.schwangerschaftStatus {
            case "Ja":
                return p.sampler.schwangerschaftSSW == 0 ? "Ja – SSW unbek." : "Ja – SSW \(p.sampler.schwangerschaftSSW)"
            case "Nein": return "Nein"
            default:
                guard p.sampler.schwangerschaft else { return "Unbek." }
                return p.sampler.schwangerschaftSSW == 0 ? "Ja – SSW unbek." : "Ja – SSW \(p.sampler.schwangerschaftSSW)"
            }
        }()
        let samplerRows: [(String, String)] = [
            ("S", p.sampler.symptome),
            ("A", p.sampler.allergienUnbekannt ? "Unbekannt" : p.sampler.allergien),
            ("M", p.sampler.medikamenteUnbekannt ? "Unbekannt" : (p.medikamentFotos.isEmpty ? p.sampler.medikamente : "Foto-Anhang")),
            ("P", p.sampler.patientenVorgeschichteUnbekannt ? "Unbekannt" : p.sampler.patientenVorgeschichte),
            ("L", letztesMahlText),
            ("E", p.sampler.ereignisUnbekannt ? "Unbekannt" : p.sampler.ereignis),
            ("R", p.sampler.risikofaktorenUnbekannt ? "Unbekannt" : p.sampler.risikofaktoren),
        ]
        // SAMPLER right column — FESTE Zeilenhöhe 11pt wie Referenzformular
        let sLblW: CGFloat = 9
        let sRowH: CGFloat = 11
        let sValColW = samplerW - sLblW
        var samplerY = sec2StartY
        for (i, (letter, value)) in samplerRows.enumerated() {
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:samplerX, y:samplerY, width:sLblW, height:sRowH), subBlue)
            txt(letter, CGRect(x:samplerX+1, y:samplerY+2, width:sLblW-2, height:sRowH-4),
                font:f6b, color:.white, align:.center)
            fillRect(CGRect(x:samplerX+sLblW, y:samplerY, width:sValColW, height:sRowH), bg)
            strokeRect(CGRect(x:samplerX+sLblW, y:samplerY, width:sValColW, height:sRowH))
            txt(value, CGRect(x:samplerX+sLblW+2, y:samplerY+2, width:sValColW-4, height:sRowH-4), font:f6)
            samplerY += sRowH
        }

        y = max(abcdeY, samplerY) + 2

        // Schwangerschaft + Auffindewerte als kompakte Zeile
        var auffindeTeile: [String] = []
        if p.sampler.schwangerschaftStatus == "Ja" { auffindeTeile.append("Schwangersch.: \(schwangerschaftText)") }
        if let puls = p.circulation.puls { auffindeTeile.append("Puls \(puls)/min") }
        if let spo2 = p.breathing.spo2   { auffindeTeile.append("SpO₂ \(spo2)%") }
        if let sys = p.circulation.blutdruckSystolisch, let dia = p.circulation.blutdruckDiastolisch {
            auffindeTeile.append("RR \(sys)/\(dia)")
        }
        if let af = p.breathing.atemFrequenz { auffindeTeile.append("AF \(af)/min") }
        if let bz = p.disability.blutzucker  { auffindeTeile.append("BZ \(Int(bz)) mg/dL") }
        if !auffindeTeile.isEmpty {
            field("Auffindewerte", auffindeTeile.joined(separator: " · "),
                  x:lx, y:y, w:rx-lx, h:11, lw:70)
            y += 11
        }

        // ── SECTION 3 ──────────────────────────────────────
        secHeader("3. Befunde", x:lx, y:y, w:rx-lx)
        y += 11

        // Column widths (lx=7, rx=588, total=581) — wie Referenzformular
        let bW_mv:  CGFloat = 100  // Messwerte (kompakter)
        let bW_ab:  CGFloat = 110  // A+B Atmung
        let bW_sch: CGFloat = 0    // Schmerz integriert in Messwerte
        let bW_c:   CGFloat = 125  // C Kreislauf+EKG
        let bW_d:   CGFloat = 246  // D Neurologie+Psyche (mehr Platz)
        let xMv  = lx
        let xAb  = xMv + bW_mv
        let xSch = xAb + bW_ab
        let xC   = xSch + bW_sch
        let xD   = xC + bW_c

        // Sub-headers
        subHeader("Messwerte", x:xMv, y:y, w:bW_mv)
        let mvLbl: CGFloat = 42
        let mvAnk: CGFloat = (bW_mv - mvLbl) / 2
        let mvUeb: CGFloat = bW_mv - mvLbl - mvAnk
        txt("Ankunft",  CGRect(x:xMv+mvLbl,       y:y+2, width:mvAnk-2, height:5.5), font:f5, color:.white, align:.center)
        txt("Übergabe", CGRect(x:xMv+mvLbl+mvAnk, y:y+2, width:mvUeb-2, height:5.5), font:f5, color:.white, align:.center)
        // A+B, C, D: draw manually so "Ank."/"Üb." edge markers don't overlap the title text
        fillRect(CGRect(x:xAb, y:y, width:bW_ab, height:9.5), subBlue)
        txt("Ank.",       CGRect(x:xAb+1.5,        y:y+2,   width:13,         height:5.5), font:f5,  color:.white)
        txt("A+B Atmung", CGRect(x:xAb+15,         y:y+1.5, width:bW_ab-30,   height:6.5), font:f6b, color:.white, align:.center)
        txt("Üb.",        CGRect(x:xAb+bW_ab-14.5, y:y+2,   width:13,         height:5.5), font:f5,  color:.white, align:.right)
        // Schmerz ist in Messwerte integriert
        fillRect(CGRect(x:xC, y:y, width:bW_c, height:9.5), subBlue)
        txt("Ank.",           CGRect(x:xC+1.5,       y:y+2,   width:13,        height:5.5), font:f5,  color:.white)
        txt("C Kreislauf+EKG",CGRect(x:xC+15,        y:y+1.5, width:bW_c-30,  height:6.5), font:f6b, color:.white, align:.center)
        txt("Üb.",            CGRect(x:xC+bW_c-14.5, y:y+2,   width:13,        height:5.5), font:f5,  color:.white, align:.right)
        fillRect(CGRect(x:xD, y:y, width:bW_d, height:9.5), subBlue)
        txt("Ank.",        CGRect(x:xD+1.5,       y:y+2,   width:13,        height:5.5), font:f5,  color:.white)
        txt("D Neurologie",CGRect(x:xD+15,        y:y+1.5, width:bW_d-30,  height:6.5), font:f6b, color:.white, align:.center)
        txt("Üb.",         CGRect(x:xD+bW_d-14.5, y:y+2,   width:13,        height:5.5), font:f5,  color:.white, align:.right)
        y += 9.5

        let mvColY = y
        let dCbH: CGFloat = 8.0   // kompakt wie Referenz

        // ── Messwerte (dual Ankunft/Übergabe) — fixe Zeilenhöhe
        let mvH: CGFloat = 9.0
        let u = p.uebergabeMesswerte
        let mvItems: [(String, String, String)] = [
            ("RR syst.",   p.circulation.blutdruckSystolisch.map  { "\($0)" } ?? "", u.rrSys),
            ("RR diast.",  p.circulation.blutdruckDiastolisch.map { "\($0)" } ?? "", u.rrDia),
            ("HF (/min)",  p.circulation.puls.map                 { "\($0)" } ?? "", u.hf),
            ("regelmäßig", p.circulation.pulsRhythmus.isEmpty ? "" : (p.circulation.pulsRhythmus == "regelmäßig" ? "ja" : "nein"), ""),
            ("SpO₂ (%)",   p.breathing.spo2.map                   { "\($0)" } ?? "", u.spo2),
            ("AF (/min)",  p.breathing.atemFrequenz.map            { "\($0)" } ?? "", u.af),
            ("etCO₂",      "",                                     ""),
            ("BZ (mg/dL)", p.disability.blutzucker.map { String(format:"%.0f",$0) } ?? "", u.bz),
            ("Temp (°C)",  p.exposure.temperatur.map   { String(format:"%.1f",$0) } ?? "", u.temp),
            ("Schmerz",    p.disability.schmerz > 0 ? "\(p.disability.schmerz)/10" : "", p.uebergabeBefunde.schmerz > 0 ? "\(p.uebergabeBefunde.schmerz)/10" : ""),
        ]
        for (i,(label,ankVal,uebVal)) in mvItems.enumerated() {
            let ry = mvColY + CGFloat(i)*mvH
            let hl = (label == "RR syst." || label == "RR diast.")
            let bg: UIColor = i%2 == 0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:xMv,y:ry,width:bW_mv,height:mvH), hl ? hlYellow : bg)
            strokeRect(CGRect(x:xMv,y:ry,width:bW_mv,height:mvH))
            vline(xMv+mvLbl, ry, mvH)
            vline(xMv+mvLbl+mvAnk, ry, mvH)
            txt(label,  CGRect(x:xMv+1.5,              y:ry+2, width:mvLbl-3,  height:mvH-4), font:f6, color:.darkGray)
            txt(ankVal, CGRect(x:xMv+mvLbl+1.5,        y:ry+2, width:mvAnk-3,  height:mvH-4), font:f7b, align:.center)
            txt(uebVal, CGRect(x:xMv+mvLbl+mvAnk+1.5,  y:ry+2, width:mvUeb-3,  height:mvH-4), font:f7b, align:.center)
        }

        // ── A+B Atmung (dual cb) ──
        let ub = p.uebergabeBefunde
        let abItems: [(String, Bool, Bool)] = [
            ("unauffällig",  p.breathing.status == .nicht_kritisch, ub.abUnauffaellig),
            ("Dyspnoe",      p.breathing.dyspnoe,                   ub.dyspnoe),
            ("Zyanose",      p.breathing.zyanose,                   ub.zyanose),
            ("Spastik",      p.breathing.spastik,                   ub.spastik),
            ("Rasselger.",   p.breathing.rasselgeraeusche,           ub.rasselgeraeusche),
            ("Brodeln",      p.breathing.brodeln,                   ub.brodeln),
            ("Stridor",      p.breathing.stridor,                   ub.stridor),
            ("Atemw.-Verl.", p.airway.verlegung,                    ub.atemwegsverlegung),
            ("Schnappatm.",  p.breathing.schnappatmung,             ub.schnappatmung),
            ("Apnoe",        p.breathing.apnoe,                     ub.apnoe),
            ("Beatmung",     p.breathing.beatmung,                  ub.beatmung),
            ("Hypervent.",   p.breathing.hyperventilation,           ub.hyperventilation),
            ("n.beurteilb.", p.breathing.abNichtBeurteilbar,        ub.abNichtBeurteilbar),
        ]
        let abRenderedH = allDualCb(abItems, x: xAb, y: mvColY, w: bW_ab, h: dCbH)

        // ── C Kreislauf + EKG (dual cb) ──
        let rekapLabel: String = {
            var lbl = "Rekap.>2Sek."
            if let t = p.circulation.rekapillierungZeit { lbl += " \(String(format: "%.1f", t))s" }
            return lbl
        }()
        let cItems: [(String, Bool, Bool)] = [
            ("unauffällig",   p.circulation.status == .nicht_kritisch, ub.cUnauffaellig),
            (rekapLabel,      p.circulation.rekapillierung,            ub.rekapillierung),
            ("Sinusrhythmus", p.circulation.sinusrhythmus,             ub.sinusrhythmus),
            ("Abs.Arrhythm.", p.circulation.absoluteArrhythmie,        ub.absoluteArrhythmie),
            ("AV-Block I°",   p.circulation.avBlockI,                  ub.avBlockI),
            ("AV-Block II°",  p.circulation.avBlockII,                 ub.avBlockII),
            ("AV-Block III°", p.circulation.avBlockIII,                ub.avBlockIII),
            ("QRS-Tachy br.", p.circulation.qrsTachykardieBreit,       ub.qrsTachykardieBreit),
            ("QRS-Tachy sm.", p.circulation.qrsTachykardieSchmal,      ub.qrsTachykardieSchmal),
            ("Kammerflimmern",p.circulation.kammerflimmern,            ub.kammerflimmern),
            ("Kammerflattern",p.circulation.kammerflattern,            ub.kammerflattern),
            ("PEA",           p.circulation.pea,                       ub.pea),
            ("Asystolie",     p.circulation.asystolie,                 ub.asystolie),
            ("Schrittmacher", p.circulation.schrittmacher,             ub.schrittmacher),
            ("Infarkt-EKG",   p.circulation.infarktEkg,                ub.infarktEkg),
            ("SVES",          p.circulation.sves,                      ub.sves),
            ("VES",           p.circulation.ves,                       ub.ves),
            ("Monomorph",     p.circulation.extrasystolenMonomorph,    ub.extrasystolenMonomorph),
            ("Polymorph",     p.circulation.extrasystolenPolymorph,    ub.extrasystolenPolymorph),
            ("n.beurteilb.",  p.circulation.cNichtBeurteilbar,         ub.cNichtBeurteilbar),
        ]
        let cRenderedH = allDualCb(cItems, x: xC, y: mvColY, w: bW_c, h: dCbH)

        // ── D Neurologie (dual cb + GCS-Zeile) ──
        let gcs = p.disability
        let dItems: [(String, Bool, Bool)] = [
            ("unauffällig",   gcs.status == .nicht_kritisch,       ub.dUnauffaellig),
            ("Wach",          gcs.bewWach,                          ub.bewWach),
            ("Ansprache",     gcs.bewAnsprache,                     ub.bewAnsprache),
            ("Schmerzreiz",   gcs.bewSchmerzreiz,                   ub.bewSchmerzreiz),
            ("Bewusstlos",    gcs.bewusstlos,                       ub.bewusstlos),
            ("n.b. Bew.",     gcs.dNichtBeurteilbar,                ub.dNichtBeurteilbar),
            ("re: eng",       gcs.pupilleReEng,                     ub.pupilleReEng),
            ("re: mittel",    gcs.pupilleReMittel,                  ub.pupilleReMittel),
            ("re: weit",      gcs.pupilleReWeit,                    ub.pupilleReWeit),
            ("re: entrund.",  gcs.pupilleReEntrundet,               ub.pupilleReEntrundet),
            ("re: kein LR",   gcs.pupilleReKeineLichtreaktion,      ub.pupilleReKeineLichtreaktion),
            ("re: n.b.",      gcs.pupilleReNichtBeurteilbar,        ub.pupilleReNichtBeurteilbar),
            ("li: eng",       gcs.pupilleLiEng,                     ub.pupilleLiEng),
            ("li: mittel",    gcs.pupilleLiMittel,                  ub.pupilleLiMittel),
            ("li: weit",      gcs.pupilleLiWeit,                    ub.pupilleLiWeit),
            ("li: entrund.",  gcs.pupilleLiEntrundet,               ub.pupilleLiEntrundet),
            ("li: kein LR",   gcs.pupilleLiKeineLichtreaktion,      ub.pupilleLiKeineLichtreaktion),
            ("li: n.b.",      gcs.pupilleLiNichtBeurteilbar,        ub.pupilleLiNichtBeurteilbar),
            ("Vorb.Defizit",  gcs.neuroVorbestehendesDefizit,       ub.neuroVorbestehendesDefizit),
            ("Facialispar.",  gcs.neuroFacialisparese,               ub.neuroFacialisparese),
            ("Armparese",     gcs.neuroArmparese,                    ub.neuroArmparese),
            ("Sprachstörung", gcs.neuroSprachstoerung,               ub.neuroSprachstoerung),
            ("Sehstörung",    gcs.neuroSehstoerung,                  ub.neuroSehstoerung),
            ("Babinski",      gcs.neuroBabinski,                     ub.neuroBabinski),
            ("Querschnitt",   gcs.neuroQuerschnitt,                  ub.neuroQuerschnitt),
            ("Meningismus",   gcs.neuroMeningismus,                  ub.neuroMeningismus),
            ("Demenz",        gcs.neuroDemenz,                       ub.neuroDemenz),
            ("n.b. Neuro",    gcs.neuroNichtBeurteilbar,             ub.neuroNichtBeurteilbar),
        ]
        let dRenderedH = allDualCb(dItems, x: xD, y: mvColY, w: bW_d, h: dCbH)
        // GCS-Zeile (Ankunft / Übergabe als Werte, kein dual-cb)
        let gcsRy = mvColY + dRenderedH
        fillRect(CGRect(x:xD, y:gcsRy, width:bW_d, height:dCbH), hlYellow)
        strokeRect(CGRect(x:xD, y:gcsRy, width:bW_d, height:dCbH))
        vline(xD + bW_d/2, gcsRy, dCbH)
        txt("GCS Ank.: \(gcs.gcsGesamt)/15",
            CGRect(x:xD+2, y:gcsRy+1.5, width:bW_d/2-4, height:dCbH-3), font:f6b)
        txt("GCS Üb.: \(ub.gcsGesamt)/15",
            CGRect(x:xD+bW_d/2+2, y:gcsRy+1.5, width:bW_d/2-4, height:dCbH-3), font:f6b)

        // Psyche wird als kompakte Zeile NACH Section 3 angezeigt, nicht als eigene Spalte

        let mvAbsH = CGFloat(mvItems.count) * mvH
        let dAbsH  = dRenderedH + dCbH
        y = mvColY + max(mvAbsH, abRenderedH, cRenderedH, dAbsH) + 2

        // Hautfarbe / Verletzungen kompakt
        if !p.exposure.hautfarbe.isEmpty || !p.exposure.verletzungen.isEmpty {
            field("Hautfarbe", p.exposure.hautfarbe, x:lx, y:y, w:(rx-lx)/2, h:10, lw:42)
            field("Verletzungen", p.exposure.verletzungen, x:lx+(rx-lx)/2, y:y, w:(rx-lx)/2, h:10, lw:45)
            y += 10
        }

        // ── SECTION 4 ──────────────────────────────────────
        secHeader("4. Diagnose", x:lx, y:y, w:rx-lx)
        y += 11

        let diag = p.diagnose
        let rH: CGFloat = 7.0
        let shH: CGFloat = 8.5   // sub-header height
        // 4 columns, col4 gets remainder
        let c1w: CGFloat = 148, c2w: CGFloat = 148, c3w: CGFloat = 148
        let c1x = lx, c2x = lx+c1w, c3x = lx+c1w+c2w
        let c4x = lx+c1w+c2w+c3w, c4w = rx-c4x

        // helper: draw sub-header on blue with "□ Sonstige" label on right
        func diagSubHeader(_ title: String, x: CGFloat, y: CGFloat, w: CGFloat) {
            fillRect(CGRect(x:x,y:y,width:w,height:shH), subBlue)
            txt(title, CGRect(x:x+2,y:y+1.5,width:w-48,height:shH-3), font:f6b, color:.white)
            let bx = x+w-44, bRect = CGRect(x:bx,y:y+2,width:5,height:5)
            UIColor(white:0.85,alpha:1).setStroke()
            let bp = UIBezierPath(rect:bRect); bp.lineWidth=0.4; bp.stroke()
            txt("Sonstige", CGRect(x:bx+6,y:y+1.5,width:38,height:6), font:f5, color:.white)
        }

        // helper: one standard checkbox row
        func diagRow(_ label: String, _ checked: Bool, x: CGFloat, y: CGFloat, w: CGFloat, even: Bool) {
            fillRect(CGRect(x:x,y:y,width:w,height:rH), even ? .white : UIColor(white:0.97,alpha:1))
            strokeRect(CGRect(x:x,y:y,width:w,height:rH))
            cb(label, checked, x:x+2, y:y+0.5, bs:5.5, lw:w-10)
        }

        // helper: inline multi-checkbox row (for STEMI+VW+HW etc.)
        func diagRowInline(_ parts: [(String,Bool)], x: CGFloat, y: CGFloat, w: CGFloat, even: Bool) {
            fillRect(CGRect(x:x,y:y,width:w,height:rH), even ? .white : UIColor(white:0.97,alpha:1))
            strokeRect(CGRect(x:x,y:y,width:w,height:rH))
            // first part gets ~55% width, rest split equally
            let restW = w * 0.45 / CGFloat(parts.count - 1)
            let firstW = w * 0.55
            var cx = x + 2
            for (i, (label, checked)) in parts.enumerated() {
                let partW = i == 0 ? firstW : restW
                cb(label, checked, x:cx, y:y+0.5, bs:5.5, lw:partW-8)
                cx += partW
            }
        }

        let sec4StartY = y

        // ── COL 1: ZNS + Herz-Kreislauf ──────────────────
        var c1y = sec4StartY
        diagSubHeader("ZNS", x:c1x, y:c1y, w:c1w); c1y += shH
        let znsItems: [(String,Bool)] = [
            ("akutes zentral-neurol. Defizit", diag.znsAkutNeuro),
            ("Schlaganfall", diag.znsSchlaganfall),
            ("ICB", diag.znsIcb),
            ("SAB", diag.znsSab),
            ("Krampfanfall", diag.znsKrampfanfall),
            ("Status Epilepticus", diag.znsEpilepsie),
            ("Fieberkrampf", diag.znsFieberkrampf),
        ]
        for (i,(lbl,chk)) in znsItems.enumerated() { diagRow(lbl,chk,x:c1x,y:c1y,w:c1w,even:i%2==0); c1y+=rH }

        diagSubHeader("Herz-Kreislauf", x:c1x, y:c1y, w:c1w); c1y += shH
        diagRow("ACS", diag.herzAcs, x:c1x, y:c1y, w:c1w, even:true); c1y += rH
        diagRowInline([("STEMI",diag.herzStemi),("VW",diag.herzVW),("HW",diag.herzHW)], x:c1x,y:c1y,w:c1w,even:false); c1y+=rH
        diagRow("kardiogener Schock", diag.herzKardiogenerSchock, x:c1x, y:c1y, w:c1w, even:true); c1y += rH
        diagRowInline([("Rhythmusstörung",diag.herzRhythmus),("tachy.",diag.herzRhythmusTachy),("brady.",diag.herzRhythmusBrady)], x:c1x,y:c1y,w:c1w,even:false); c1y+=rH
        let herzRest: [(String,Bool)] = [
            ("PM/ICD Fehlfunktion", diag.herzPmFehlfunktion),
            ("Lungenembolie", diag.herzLungenembolie),
            ("dekomp. Herzinsuffizienz", diag.herzDekomp),
            ("hypertensiver Notfall", diag.herzHypertonerNotfall),
            ("Aortenaneurysma", diag.herzAortenaneurysma),
            ("Hypotonie", diag.herzHypotonie),
            ("Synkope", diag.herzSynkope),
            ("Thrombose/Embolie", diag.herzThromboseEmbolie),
            ("Herz-Kreislauf-Stillstand", diag.herzStillstand),
            ("Schock unklarer Genese", diag.herzSchockUnklarGenese),
            ("orthostatische Fehlregulation", diag.herzOrthostatisch),
            ("unklarer Thoraxschmerz", diag.herzUnklarerThoraxschmerz),
        ]
        for (i,(lbl,chk)) in herzRest.enumerated() { diagRow(lbl,chk,x:c1x,y:c1y,w:c1w,even:i%2==0); c1y+=rH }

        // ── COL 2: Atmung + Stoffwechsel + Abdomen ────────
        var c2y = sec4StartY
        diagSubHeader("Atmung", x:c2x, y:c2y, w:c2w); c2y += shH
        let atmItems: [(String,Bool)] = [
            ("Asthma", diag.atmungAsthma),
            ("Status asthm.", diag.atmungStatusAsthmaticus),
            ("exacerbierte COPD", diag.atmungExazerbiert),
            ("Aspiration", diag.atmungAspiration),
            ("Pneumonie / Bronchitis", diag.atmungPneumonie),
            ("Hyperventilationstetanie", diag.atmungHyperventilation),
            ("LTB (L/T/Bronchitis)", diag.atmungLtb),
            ("Epiglottitis", diag.atmungEpiglottitis),
            ("Spontanpneumothorax", diag.atmungSpontanpneumothorax),
            ("Hämoptysis", diag.atmungHaemoptysis),
            ("unkl. Dyspnoe", diag.atmungUnklareDyspnoe),
            ("Lungenödem", diag.atmungLungenodem),
            ("Pseudokrupp", diag.atmungPseudokrupp),
        ]
        for (i,(lbl,chk)) in atmItems.enumerated() { diagRow(lbl,chk,x:c2x,y:c2y,w:c2w,even:i%2==0); c2y+=rH }

        diagSubHeader("Stoffwechsel", x:c2x, y:c2y, w:c2w); c2y += shH
        let stoffItems: [(String,Bool)] = [
            ("Exsikkose", diag.stoffExsikkose),
            ("Hypoglycämie", diag.stoffHypoglykämie),
            ("Hyperglycämie", diag.stoffHyperglykämie),
            ("Urämie/ANV", diag.stoffUremie),
            ("bek. dialysepflichtig", diag.stoffDialyse),
        ]
        for (i,(lbl,chk)) in stoffItems.enumerated() { diagRow(lbl,chk,x:c2x,y:c2y,w:c2w,even:i%2==0); c2y+=rH }

        diagSubHeader("Abdomen", x:c2x, y:c2y, w:c2w); c2y += shH
        diagRow("akutes Abdomen", diag.abdoAkutes, x:c2x, y:c2y, w:c2w, even:true); c2y+=rH
        diagRow("Kolik allgemein", diag.abdoKoliken, x:c2x, y:c2y, w:c2w, even:false); c2y+=rH
        diagRowInline([("GIB",diag.abdoGibOben||diag.abdoGibUnten),("obere",diag.abdoGibOben),("untere",diag.abdoGibUnten)], x:c2x,y:c2y,w:c2w,even:true); c2y+=rH
        diagRow("Gallenkolik", diag.abdoGallenkolik||diag.abdoGalleNiere, x:c2x, y:c2y, w:c2w, even:false); c2y+=rH
        diagRow("Nierenkolik", diag.abdoNierenkolik, x:c2x, y:c2y, w:c2w, even:true); c2y+=rH

        // ── COL 3: Psychiatrie + Gyn + Infektionen ────────
        var c3y = sec4StartY
        diagSubHeader("Psychiatrie", x:c3x, y:c3y, w:c3w); c3y += shH
        let psychItems: [(String,Bool)] = [
            ("psych. Ausnahmezustand", diag.psychAkut),
            ("psychosoz. Krise", diag.psychKrise),
            ("Depressionen", diag.psychDepressionen),
            ("Manie", diag.psychManie),
            ("Intoxikation", diag.psychIntoxikation),
            ("Entzug/Delir", diag.psychEntzug),
            ("Suizidalität", diag.psychSuizidal),
        ]
        for (i,(lbl,chk)) in psychItems.enumerated() { diagRow(lbl,chk,x:c3x,y:c3y,w:c3w,even:i%2==0); c3y+=rH }

        diagSubHeader("Gyn./Geb.-hilfe", x:c3x, y:c3y, w:c3w); c3y += shH
        let gynItems: [(String,Bool)] = [
            ("Schwangerschaft > 35. SSW", diag.gynSchwangerschaft35),
            ("Geburt", diag.gynGeburt),
            ("Extrauterine Gravidität", diag.gynExtrauterine || diag.gynSonstige),
            ("Eklampsie", diag.gynEklampsie),
            ("vaginale Blutung", diag.gynVaginalblutung),
        ]
        for (i,(lbl,chk)) in gynItems.enumerated() { diagRow(lbl,chk,x:c3x,y:c3y,w:c3w,even:i%2==0); c3y+=rH }

        diagSubHeader("Infektionen", x:c3x, y:c3y, w:c3w); c3y += shH
        diagRow("unkl. Fieber", diag.infektUnklarFieber, x:c3x, y:c3y, w:c3w, even:true); c3y+=rH
        diagRow("Meningitis/Enzephalitis", diag.infektMeningitis, x:c3x, y:c3y, w:c3w, even:false); c3y+=rH
        diagRowInline([("offen -MRSA-",diag.infektMrsaOffen),("gedeckt",diag.infektMrsaGedeckt)], x:c3x,y:c3y,w:c3w,even:true); c3y+=rH
        diagRow("MRE", diag.infektMre, x:c3x, y:c3y, w:c3w, even:false); c3y+=rH
        diagRow("Hepatitis", diag.infektHepatitis, x:c3x, y:c3y, w:c3w, even:true); c3y+=rH

        // ── COL 4: HIV-Gruppe + Sonstiges ─────────────────
        var c4y = sec4StartY
        let hivItems: [(String,Bool)] = [
            ("HIV", diag.infektHiv),
            ("TBC", diag.infektTbc),
            ("hochkontag. Erreger (SARS)", diag.infektHighToxSars),
            ("Gastroenteritis", diag.infektGastro),
        ]
        for (i,(lbl,chk)) in hivItems.enumerated() { diagRow(lbl,chk,x:c4x,y:c4y,w:c4w,even:i%2==0); c4y+=rH }

        // "Sonstiges" header with "□ unklar" label on right
        fillRect(CGRect(x:c4x,y:c4y,width:c4w,height:shH), subBlue)
        txt("Sonstiges", CGRect(x:c4x+2,y:c4y+1.5,width:c4w-50,height:shH-3), font:f6b, color:.white)
        let ubx = c4x+c4w-46
        let ubRect2 = CGRect(x:ubx,y:c4y+2,width:5,height:5)
        UIColor(white:0.85,alpha:1).setStroke()
        let ubp2 = UIBezierPath(rect:ubRect2); ubp2.lineWidth=0.4; ubp2.stroke()
        txt("unklar", CGRect(x:ubx+7,y:c4y+1.5,width:39,height:6), font:f5, color:.white)
        c4y += shH

        let sonstItems: [(String,Bool)] = [
            ("Anaphylaxie Grad 1/2", diag.infektAnaphylaxie12),
            ("Anaphylaxie Grad 3/4", diag.infektAnaphylaxie34),
            ("sept. Schock", diag.infektSeptSchock),
            ("Hitzeerschöpf./Hitzschl.", diag.infektHitze),
            ("Unterkül./Erfrierung", diag.infektUnterku),
            ("Ertrinken", diag.infektErtrinken),
            ("SIDS", diag.infektSids),
            ("Intoxikation", diag.infektIntoxikation),
            ("akute Lumbago", diag.infektAkuteLumbalgie),
            ("palliative Situation", diag.infektPalliativ),
            ("med. Behandlungskomplik.", diag.infektBehandlungKompl),
            ("Epistaxis", diag.infektEpistaxis),
            ("urologische Erkrankung", diag.infektUrologisch),
        ]
        for (i,(lbl,chk)) in sonstItems.enumerated() { diagRow(lbl,chk,x:c4x,y:c4y,w:c4w,even:i%2==0); c4y+=rH }

        // Advance y past tallest column
        y = max(c1y, c2y, c3y, c4y)

        // Diagnose/Leitsymptom boxes (full width, like reference form)
        let leitsymptomText = diag.leitsymptom.isEmpty
            ? (diag.verdachtsdiagnosen.first { $0.wahrscheinlichkeit == .fuehrend }?.name ?? "")
            : diag.leitsymptom
        fillRect(CGRect(x:lx, y:y, width:rx-lx, height:9), vLightB)
        strokeRect(CGRect(x:lx, y:y, width:rx-lx, height:9))
        txt("Diagnose/Leitsymptom", CGRect(x:lx+2,y:y+1.5,width:90,height:6), font:f6b, color:colBlue)
        y += 9
        let leitsH: CGFloat = 13
        fillRect(CGRect(x:lx, y:y, width:rx-lx, height:leitsH), hlYellow)
        strokeRect(CGRect(x:lx, y:y, width:rx-lx, height:leitsH))
        if !leitsymptomText.isEmpty {
            txt(leitsymptomText, CGRect(x:lx+3,y:y+2,width:rx-lx-6,height:leitsH-4), font:f7b)
        }
        y += leitsH

        if !p.diagnose.diagnoseFreitext.isEmpty {
            let h = fieldH(p.diagnose.diagnoseFreitext, width: rx-lx-6, minH: 11)
            fillRect(CGRect(x:lx,y:y,width:rx-lx,height:h), .white)
            strokeRect(CGRect(x:lx,y:y,width:rx-lx,height:h))
            mtxt(p.diagnose.diagnoseFreitext, CGRect(x:lx+3,y:y+2,width:rx-lx-6,height:h-4), font:f6)
            y += h
        }

        // Footer
        drawFooter(erstelltAm: p.erstelltAm)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - Body Silhouette Helpers
    // ─────────────────────────────────────────────────────

    private static func gradColor(_ g: Verletzungsgrad) -> UIColor {
        switch g {
        case .keine:  return UIColor(white: 0.97, alpha: 1)
        case .leicht: return UIColor(red: 1.0, green: 0.93, blue: 0.4,  alpha: 1)
        case .schwer: return UIColor(red: 1.0, green: 0.4,  blue: 0.4,  alpha: 1)
        }
    }

    private static func higherGrad(_ a: Verletzungsgrad, _ b: Verletzungsgrad) -> Verletzungsgrad {
        if a == .schwer || b == .schwer { return .schwer }
        if a == .leicht || b == .leicht { return .leicht }
        return .keine
    }

    /// Zeichnet zwei Körpersilhouetten (Rücken + Vorder) nebeneinander, ohne Text innen.
    /// Layout wie Referenzformular: li [RÜCKEN] re  |  re [VORDER] li
    private static func drawBodySilhouette(_ m: VerletzungsMatrix, rect: CGRect) {

        let lblW: CGFloat = 8          // Breite für "li"/"re" Label
        let gap:  CGFloat = 4          // Abstand zwischen den Figuren
        let figTotalW = (rect.width - gap) / 2   // Breite pro Figur inkl. Label
        let bodyW = figTotalW - lblW * 2         // Breite des Körpers
        let bodyH = rect.height - 2              // Höhe des Körpers (volle Höhe nutzen)

        /// Zeichnet eine Figur. ox/oy = linke obere Ecke des Körper-Bereichs (ohne Label-Spalten)
        func drawFigure(ox: CGFloat, oy: CGFloat, isFront: Bool) {
            let bx = ox, by = oy
            let bw = bodyW, bh = bodyH

            // Proportionen (relativ zu bh)
            let headR  = bw * 0.18           // Kopfradius
            let neckH  = bh * 0.055
            let neckW  = bw * 0.18
            let torsoH = bh * 0.28
            let torsoW = bw * 0.50
            let hipH   = bh * 0.07
            let hipW   = bw * 0.46
            let armW   = bw * 0.15
            let uArmH  = bh * 0.20
            let lArmH  = bh * 0.18
            let uLegW  = bw * 0.20
            let uLegH  = bh * 0.24
            let lLegH  = bh * 0.24
            let jR     = bw * 0.055          // Gelenk-Radius

            let cx  = bx + bw * 0.5           // Körpermitte
            var curY = by + 2

            // ── Kopf ──
            let headGrad = isFront ? higherGrad(m.schaedelHirn, m.gesicht) : m.schaedelHirn
            let headRect = CGRect(x: cx - headR, y: curY, width: headR*2, height: headR*2)
            let headPath = UIBezierPath(ovalIn: headRect)
            gradColor(headGrad).setFill(); UIColor.darkGray.setStroke()
            headPath.lineWidth = 0.5; headPath.fill(); headPath.stroke()
            // Gesicht (Vorderfigur): kleines Gesicht-Oval unten im Kopf
            if isFront && m.gesicht != .keine {
                let faceR = headR * 0.55
                let faceY = curY + headR * 0.7
                let facePath = UIBezierPath(ovalIn: CGRect(x:cx-faceR, y:faceY, width:faceR*2, height:faceR))
                gradColor(m.gesicht).setFill(); facePath.fill()
            }
            curY += headR * 2 + 1

            // ── Hals ──
            let neckRect = CGRect(x: cx - neckW/2, y: curY, width: neckW, height: neckH)
            let neckPath = UIBezierPath(roundedRect: neckRect, cornerRadius: 1)
            gradColor(m.hws).setFill(); neckPath.lineWidth = 0.5; neckPath.fill(); neckPath.stroke()
            curY += neckH

            // ── Schultergelenke ──
            let shoulderY = curY + 1
            let lShoulderX = cx - torsoW/2 - armW/2
            let rShoulderX = cx + torsoW/2 + armW/2

            // ── Torso (Thorax + Abdomen) ──
            let thoraxH = torsoH * 0.55
            let abdoH   = torsoH * 0.45
            let torsoX  = cx - torsoW/2

            let thoraxRect = CGRect(x: torsoX, y: curY, width: torsoW, height: thoraxH)
            let thoraxPath = UIBezierPath(roundedRect: thoraxRect, cornerRadius: 1.5)
            gradColor(m.thorax).setFill(); thoraxPath.lineWidth = 0.5; thoraxPath.fill(); thoraxPath.stroke()

            let abdoRect = CGRect(x: torsoX, y: curY + thoraxH, width: torsoW, height: abdoH)
            let abdoPath = UIBezierPath(roundedRect: abdoRect, cornerRadius: 1.5)
            gradColor(m.abdomen).setFill(); abdoPath.lineWidth = 0.5; abdoPath.fill(); abdoPath.stroke()

            // BWS-Streifen (Rückenfigur)
            if !isFront && m.bwsLws != .keine {
                let spineW: CGFloat = bw * 0.08
                let spinePath = UIBezierPath(roundedRect: CGRect(x:cx-spineW/2, y:curY, width:spineW, height:torsoH), cornerRadius:1)
                gradColor(m.bwsLws).setFill(); spinePath.fill()
            }
            curY += torsoH

            // ── Becken / Hüfte ──
            let hipRect = CGRect(x: cx - hipW/2, y: curY, width: hipW, height: hipH)
            let hipPath = UIBezierPath(roundedRect: hipRect, cornerRadius: 1.5)
            gradColor(m.becken).setFill(); hipPath.lineWidth = 0.5; hipPath.fill(); hipPath.stroke()
            let hipMidY = curY + hipH/2
            curY += hipH

            // ── Arme ──
            let armX_L = cx - torsoW/2 - armW
            let armX_R = cx + torsoW/2
            // Oberarm
            let uArmPathL = UIBezierPath(roundedRect: CGRect(x:armX_L, y:shoulderY, width:armW, height:uArmH), cornerRadius:1.5)
            let uArmPathR = UIBezierPath(roundedRect: CGRect(x:armX_R, y:shoulderY, width:armW, height:uArmH), cornerRadius:1.5)
            gradColor(m.obereExtrem).setFill()
            [uArmPathL, uArmPathR].forEach { $0.lineWidth = 0.5; $0.fill(); $0.stroke() }
            // Ellenbogengelenke
            let elbowY = shoulderY + uArmH
            UIBezierPath(ovalIn: CGRect(x:armX_L+armW/2-jR, y:elbowY-jR, width:jR*2, height:jR*2)).fill()
            UIBezierPath(ovalIn: CGRect(x:armX_R+armW/2-jR, y:elbowY-jR, width:jR*2, height:jR*2)).fill()
            // Unterarm
            let lArmPathL = UIBezierPath(roundedRect: CGRect(x:armX_L, y:elbowY, width:armW, height:lArmH), cornerRadius:1.5)
            let lArmPathR = UIBezierPath(roundedRect: CGRect(x:armX_R, y:elbowY, width:armW, height:lArmH), cornerRadius:1.5)
            gradColor(m.obereExtrem).setFill()
            [lArmPathL, lArmPathR].forEach { $0.lineWidth = 0.5; $0.fill(); $0.stroke() }
            // Schultergelenke (nach Armen zeichnen, damit sie oben liegen)
            UIColor.darkGray.setStroke(); gradColor(m.obereExtrem).setFill()
            [CGPoint(x: lShoulderX, y: shoulderY + armW/2),
             CGPoint(x: rShoulderX, y: shoulderY + armW/2)].forEach {
                UIBezierPath(ovalIn: CGRect(x:$0.x-jR, y:$0.y-jR, width:jR*2, height:jR*2)).fill()
            }

            // ── Beine ──
            let legSpacing: CGFloat = hipW * 0.05
            let legX_L = cx - hipW/2 + legSpacing
            let legX_R = cx + legSpacing
            // Oberschenkel
            let uLegPathL = UIBezierPath(roundedRect: CGRect(x:legX_L, y:curY, width:uLegW, height:uLegH), cornerRadius:1.5)
            let uLegPathR = UIBezierPath(roundedRect: CGRect(x:legX_R, y:curY, width:uLegW, height:uLegH), cornerRadius:1.5)
            gradColor(m.untereExtrem).setFill()
            [uLegPathL, uLegPathR].forEach { $0.lineWidth = 0.5; $0.fill(); $0.stroke() }
            // Hüftgelenke
            UIColor.darkGray.setStroke()
            [CGPoint(x: legX_L+uLegW/2, y: hipMidY),
             CGPoint(x: legX_R+uLegW/2, y: hipMidY)].forEach {
                UIBezierPath(ovalIn: CGRect(x:$0.x-jR, y:$0.y-jR, width:jR*2, height:jR*2)).fill()
            }
            // Knie
            let kneeY = curY + uLegH
            UIBezierPath(ovalIn: CGRect(x:legX_L+uLegW/2-jR, y:kneeY-jR, width:jR*2, height:jR*2)).fill()
            UIBezierPath(ovalIn: CGRect(x:legX_R+uLegW/2-jR, y:kneeY-jR, width:jR*2, height:jR*2)).fill()
            // Unterschenkel
            let lLegPathL = UIBezierPath(roundedRect: CGRect(x:legX_L, y:kneeY, width:uLegW, height:lLegH), cornerRadius:1.5)
            let lLegPathR = UIBezierPath(roundedRect: CGRect(x:legX_R, y:kneeY, width:uLegW, height:lLegH), cornerRadius:1.5)
            gradColor(m.untereExtrem).setFill()
            [lLegPathL, lLegPathR].forEach { $0.lineWidth = 0.5; $0.fill(); $0.stroke() }
            // Knöchel
            let ankleY = kneeY + lLegH
            UIColor.darkGray.setStroke()
            UIBezierPath(ovalIn: CGRect(x:legX_L+uLegW/2-jR, y:ankleY-jR, width:jR*2, height:jR*2)).fill()
            UIBezierPath(ovalIn: CGRect(x:legX_R+uLegW/2-jR, y:ankleY-jR, width:jR*2, height:jR*2)).fill()
        }

        // ── Figur 1: Rückenansicht (links) ──
        let f1x = rect.minX + lblW        // Körper beginnt nach "li"
        let f2x = rect.minX + figTotalW + gap + lblW  // Körper Figur 2
        let fy  = rect.minY + 2

        drawFigure(ox: f1x, oy: fy, isFront: false)
        drawFigure(ox: f2x, oy: fy, isFront: true)

        // ── li / re Labels — in der Mitte der Figur-Höhe ──
        let lf = UIFont.boldSystemFont(ofSize: 5.5)
        let ly = rect.minY + rect.height * 0.42   // leicht unterhalb der Mitte (Hüft-Höhe)
        // Rückenfigur: "li" links, "re" rechts
        txt("li", CGRect(x: rect.minX,                        y: ly, width: lblW, height: 7), font: lf, color: .darkGray, align: .center)
        txt("re", CGRect(x: rect.minX + figTotalW - lblW,     y: ly, width: lblW, height: 7), font: lf, color: .darkGray, align: .center)
        // Vorderfigur: "re" links, "li" rechts
        txt("re", CGRect(x: rect.minX + figTotalW + gap,                   y: ly, width: lblW, height: 7), font: lf, color: .darkGray, align: .center)
        txt("li", CGRect(x: rect.minX + rect.width - lblW,    y: ly, width: lblW, height: 7), font: lf, color: .darkGray, align: .center)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - PAGE 2  (Seiten 3+4 des Originals)
    // Sections: 4.2 Verletzungen · 5 Verlauf · 4.5 Medi · 6 Maßnahmen · 7 Reani · 8 Ergebnis · 9 Übergabe
    // ─────────────────────────────────────────────────────

    private static func drawPage2(p: EinsatzProtokoll) {

        let hh: CGFloat = 22
        fillRect(CGRect(x:0,y:0,width:pageSize.width,height:hh), colBlue)
        txt("EINSATZPROTOKOLL – Seite 2 / 2",
            CGRect(x:lx,y:3,width:280,height:16), font:f13b, color:.white)
        txt("\(p.patientDaten.nachname), \(p.patientDaten.vorname)   |   Einsatz: \(p.einsatzOrt.einsatzNummer)",
            CGRect(x:260,y:5,width:240,height:9), font:f7b, color:.white)
        txt("Seite 2 / 2",
            CGRect(x:pageSize.width-55,y:13,width:50,height:8), font:f6, color:.white, align:.right)

        // ── Layout: rechte Spalte Maßnahmen | linke Seite Rest ──
        let maaX: CGFloat = 395          // rechte Spalte ab hier
        let maaW: CGFloat = rx - maaX    // ≈ 193 pt
        let leftW: CGFloat = maaX - lx   // ≈ 388 pt

        // ═══════════════════════════════════════════════════
        // RECHTE SPALTE: Section 6 Maßnahmen (volle Seitenhöhe)
        // ═══════════════════════════════════════════════════
        var mY: CGFloat = hh
        secHeader("6. Maßnahmen", x: maaX, y: mY, w: maaW)
        mY += 11

        let maR: CGFloat = 8.0  // Zeilenhöhe Maßnahmen-Checkboxen

        // Airway / Stabilisation
        subHeader("Airway / Stabilisation □ keine", x: maaX, y: mY, w: maaW, h: 8.5)
        mY += 8.5
        let m = p.massnahmen
        let airItems: [(String, Bool)] = [
            ("Atemweg freimachen/freihalten", m.atemwegFreimachen),
            ("Cervikalstütze/HWS Stabilisation", m.cervikalStuetze),
            ("Absaugung", m.absaugung),
            ("Guedel-Tubus (OPA)", m.guedelTubus),
            ("Wendel-Tubus (NPA)", m.wendlTubus),
            ("Sauerstoffgabe" + (m.sauerstoffLitMin.isEmpty ? "" : " \(m.sauerstoffLitMin) l/min"), m.sauerstoffgabe),
            ("Maskenbeatmung", m.maskenbeatmung),
            ("Masch. Beatmung", m.maschinelleBeatmung),
            ("Beatmung unmögl./erschwert", m.maskenbeatmungUnmoeglich || m.atemwegErschwert),
            ("EGA supraglottisch" + (m.supraglottischTyp.isEmpty ? "" : " \(m.supraglottischTyp)\(m.supraglottischGr.isEmpty ? "" : " Gr.\(m.supraglottischGr)")"), m.supraglottisch),
            ("CPAP" + (m.cpapMbar.isEmpty ? "" : " \(m.cpapMbar) mBar"), m.cpap),
            ("Heimlich-Manöver", m.heimlich),
            ("Intubation (ETI)", p.airway.intubiert),
            ("Konikotomie", p.airway.konikotomie),
        ]
        for (i, (label, checked)) in airItems.enumerated() {
            let bg: UIColor = i % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            fillRect(CGRect(x: maaX, y: mY, width: maaW, height: maR), bg)
            strokeRect(CGRect(x: maaX, y: mY, width: maaW, height: maR))
            cb(label, checked, x: maaX+2, y: mY+0.5, bs: 6, lw: maaW-10)
            mY += maR
        }

        // Atmung
        subHeader("Atmung □ keine", x: maaX, y: mY, w: maaW, h: 8.5); mY += 8.5
        let atmItems: [(String, Bool)] = [
            ("CPAP/NIV", m.cpap),
            ("Thoraxdrainage", false),
            ("Entlastungspunktion", false),
            ("Sonstiges", !m.airwaySonstige.isEmpty),
        ]
        for (i, (label, checked)) in atmItems.enumerated() {
            let bg: UIColor = i % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            fillRect(CGRect(x: maaX, y: mY, width: maaW, height: maR), bg)
            strokeRect(CGRect(x: maaX, y: mY, width: maaW, height: maR))
            cb(label, checked, x: maaX+2, y: mY+0.5, bs: 6, lw: maaW-10)
            mY += maR
        }
        if m.maschinelleBeatmung {
            let beat = [m.tidalvolumen.isEmpty ? nil : "TV \(m.tidalvolumen)ml",
                        m.peep.isEmpty ? nil : "PEEP \(m.peep)",
                        m.fio2.isEmpty ? nil : "FiO₂ \(m.fio2)%"].compactMap{$0}.joined(separator: " ")
            if !beat.isEmpty {
                fillRect(CGRect(x: maaX, y: mY, width: maaW, height: maR), .white)
                strokeRect(CGRect(x: maaX, y: mY, width: maaW, height: maR))
                txt("Beatmung: \(beat)", CGRect(x: maaX+2, y: mY+1, width: maaW-4, height: maR-2), font: f5)
                mY += maR
            }
        }

        // Cirkulation
        subHeader("Cirkulation □ keine", x: maaX, y: mY, w: maaW, h: 8.5); mY += 8.5
        let circItems: [(String, Bool)] = [
            ("peripher-venöser Zugang" + (m.peripherVenoesOrt.isEmpty ? "" : " (\(m.peripherVenoesOrt)\(m.peripherVenoesGroesse.isEmpty ? "" : " \(m.peripherVenoesGroesse)G"))"), m.peripherVenoes),
            ("zentral-venöser Zugang", false),
            ("intrass. Kanüle/Port" + (m.intraossaerOrt.isEmpty ? "" : " (\(m.intraossaerOrt))"), m.intraossaer),
            ("art. Kanüle", false),
            ("Defibrillation" + (m.defiAnzahl > 0 ? " \(m.defiAnzahl)× \(m.defiJoule)J" : ""), m.defibrillation),
            ("Kardioversion" + (m.kardioversionJoule > 0 ? " \(m.kardioversionJoule)J" : ""), m.kardioversion),
            ("Tourniquet" + (m.tourniquetZeit != nil ? " \(t(m.tourniquetZeit))" : ""), m.tourniquet),
            ("Verband / Wundversorgung", m.verband),
            ("Beckenschlinge", m.beckenschlinge),
        ]
        for (i, (label, checked)) in circItems.enumerated() {
            let bg: UIColor = i % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            fillRect(CGRect(x: maaX, y: mY, width: maaW, height: maR), bg)
            strokeRect(CGRect(x: maaX, y: mY, width: maaW, height: maR))
            cb(label, checked, x: maaX+2, y: mY+0.5, bs: 6, lw: maaW-10)
            mY += maR
        }

        // Weitere Maßnahmen
        subHeader("Weitere Maßnahmen □ keine", x: maaX, y: mY, w: maaW, h: 8.5); mY += 8.5
        let weitItems: [(String, Bool)] = [
            ("Kühlung", m.kuehlung),
            ("Wärmeerhalt", m.waermeerhalt),
            ("Entbindung", m.entbindung),
            ("Krisenintervention", m.krisenintervention),
            ("Kardioversion", m.kardioversion),
            ("Extremitätenschienung", m.extremitaetenschienung),
            ("Sonstiges", !m.weitereSonstige.isEmpty),
        ]
        for (i, (label, checked)) in weitItems.enumerated() {
            let bg: UIColor = i % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            fillRect(CGRect(x: maaX, y: mY, width: maaW, height: maR), bg)
            strokeRect(CGRect(x: maaX, y: mY, width: maaW, height: maR))
            cb(label, checked, x: maaX+2, y: mY+0.5, bs: 6, lw: maaW-10)
            mY += maR
        }

        // Lagerung / Transport
        subHeader("Lagerung / Transport □ keine", x: maaX, y: mY, w: maaW, h: 8.5); mY += 8.5
        let lagItems: [(String, Bool)] = [
            ("OK-Hochlagerung", m.okHochlagerung),
            ("Flachlagerung", m.flachlagerung),
            ("Schocklagerung", m.schocklagerung),
            ("Herztieflagung", m.herzTieflage),
            ("Linksseitenlage", m.linksseitenlage),
            ("Sitzender Transport", m.sitzenderTransport),
            ("Vakuummatratze", m.vakuummatratze),
            ("Schaufeltrage", m.schaufeltrage),
            ("Reposition", false),
            ("Verband", m.verband),
            ("Beckenschlinge", m.beckenschlinge),
        ]
        for (i, (label, checked)) in lagItems.enumerated() {
            let bg: UIColor = i % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            fillRect(CGRect(x: maaX, y: mY, width: maaW, height: maR), bg)
            strokeRect(CGRect(x: maaX, y: mY, width: maaW, height: maR))
            cb(label, checked, x: maaX+2, y: mY+0.5, bs: 6, lw: maaW-10)
            mY += maR
        }

        // Monitoring
        subHeader("Monitoring □ keine", x: maaX, y: mY, w: maaW, h: 8.5); mY += 8.5
        let monItems: [(String, Bool)] = [
            ("EKG", m.monEkg),
            ("12-Kanal-EKG", false),
            ("NIBP", m.monNibp),
            ("BZ", m.monBz),
            ("SpO₂", m.monSpo2),
            ("Temperatur", m.monTemperatur),
            ("Kapnographie", false),
        ]
        for (i, (label, checked)) in monItems.enumerated() {
            let bg: UIColor = i % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            fillRect(CGRect(x: maaX, y: mY, width: maaW, height: maR), bg)
            strokeRect(CGRect(x: maaX, y: mY, width: maaW, height: maR))
            cb(label, checked, x: maaX+2, y: mY+0.5, bs: 6, lw: maaW-10)
            mY += maR
        }

        var y: CGFloat = hh

        // ═══════════════════════════════════════════════════
        // LINKE SEITE: 4.2, 5, 6.5 Medi, 7, 8, 9
        // ═══════════════════════════════════════════════════

        // ── SECTION 4.2 Verletzungen ──────────────────────
        // Layout (wie Originalformular):
        //  [Regionen-Tabelle] | [Silhouette] | [Spez.Traumen + Unfallart]
        //  [Verletzungsmuster (cb)] | [Unfallmechanismus (cb)]
        let d = p.diagnose
        let v2LeftW:  CGFloat = leftW * 0.27   // Regionen-Tabelle
        let v2MidW:   CGFloat = leftW * 0.25   // Silhouette
        let v2RightW: CGFloat = leftW * 0.48   // Spez. Traumen + Unfallart
        let v2MidX  = lx + v2LeftW
        let v2RightX = v2MidX + v2MidW

        secHeader("4.2 Verletzungen", x:lx, y:y, w:v2LeftW + v2MidW)
        cb("keine", d.verletzungNichtBekannt, x:lx + v2LeftW + v2MidW - 35, y:y+2.5, bs:6, lw:30)
        secHeader("Spezielle Traumen", x:v2RightX, y:y, w:v2RightW * 0.5)
        secHeader("Unfallart", x:v2RightX + v2RightW * 0.5, y:y, w:v2RightW * 0.5)
        y += 11

        // ── Regionen-Tabelle (links) ──
        let regH: CGFloat = 10
        let rColW = v2LeftW / 3
        // Header
        fillRect(CGRect(x:lx, y:y, width:v2LeftW, height:8), vLightB)
        txt("Region", CGRect(x:lx+2, y:y+1, width:rColW-2, height:6), font:f5b, color:colBlue)
        txt("leicht", CGRect(x:lx+rColW,     y:y+1, width:rColW-2, height:6), font:f5b, color:colBlue, align:.center)
        txt("schwer", CGRect(x:lx+rColW*2,   y:y+1, width:rColW-2, height:6), font:f5b, color:colBlue, align:.center)
        strokeRect(CGRect(x:lx, y:y, width:v2LeftW, height:8))
        let regY0 = y + 8
        let regions: [(String, Verletzungsgrad)] = [
            ("Schädel-Hirn", d.verletzungsMatrix.schaedelHirn),
            ("Gesicht",      d.verletzungsMatrix.gesicht),
            ("HWS",          d.verletzungsMatrix.hws),
            ("Thorax",       d.verletzungsMatrix.thorax),
            ("Abdomen",      d.verletzungsMatrix.abdomen),
            ("BWS / LWS",    d.verletzungsMatrix.bwsLws),
            ("Becken",       d.verletzungsMatrix.becken),
            ("Ob. Extrem.",  d.verletzungsMatrix.obereExtrem),
            ("Un. Extrem.",  d.verletzungsMatrix.untereExtrem),
            ("Weichteile",   d.verletzungsMatrix.weichteile),
        ]
        for (i,(region,grad)) in regions.enumerated() {
            let ry = regY0 + CGFloat(i)*regH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:lx, y:ry, width:v2LeftW, height:regH), bg)
            strokeRect(CGRect(x:lx, y:ry, width:v2LeftW, height:regH))
            vline(lx+rColW, ry, regH); vline(lx+rColW*2, ry, regH)
            txt(region, CGRect(x:lx+2, y:ry+1.5, width:rColW-4, height:regH-3), font:f5)
            cb("", grad == .leicht, x:lx+rColW+rColW/2-4,   y:ry+1.5, bs:7, lw:0)
            cb("", grad == .schwer, x:lx+rColW*2+rColW/2-4, y:ry+1.5, bs:7, lw:0)
        }

        let regTableBottom = regY0 + CGFloat(regions.count)*regH

        // ── Silhouette (Mitte) ──
        // Silhouette: startet bei regY0 (erste Tabellenzeile), genau so hoch wie die Tabelle
        let silhH = CGFloat(regions.count) * regH
        let silhRect = CGRect(x:v2MidX+1, y:regY0, width:v2MidW-2, height:silhH)
        if let cgCtx = UIGraphicsGetCurrentContext() {
            cgCtx.saveGState(); cgCtx.clip(to: silhRect)
            drawBodySilhouette(d.verletzungsMatrix, rect: silhRect)
            cgCtx.restoreGState()
        } else {
            drawBodySilhouette(d.verletzungsMatrix, rect: silhRect)
        }

        // ── Spezielle Traumen (rechts, 2 Spalten) ──
        let spezColW = v2RightW / 2
        let spezTraumen: [(String,Bool)] = [
            ("Verbr./Verbrüh.",     d.spezVerbrVerbrh),
            ("Inhalationstrauma",   d.spezInhalationstrauma),
            ("Elektrounfall",       d.spezElektrounfall),
            ("Verätzung",           d.spezVeraetzung),
            ("Tauchunfall",         d.spezTauchunfall),
            ("Sonstige",            d.spezSonstige),
        ]
        let stRows = (spezTraumen.count + 1) / 2  // ceiling
        for row in 0..<stRows {
            let ry = y + CGFloat(row)*regH
            for col in 0..<2 {
                let idx = row*2 + col
                guard idx < spezTraumen.count else { continue }
                let (label, checked) = spezTraumen[idx]
                let cx = v2RightX + CGFloat(col)*spezColW
                let bg: UIColor = row%2==0 ? .white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:cx, y:ry, width:spezColW, height:regH), bg)
                strokeRect(CGRect(x:cx, y:ry, width:spezColW, height:regH))
                cb(label, checked, x:cx+2, y:ry+1.5, bs:6, lw:spezColW-10)
            }
        }

        // ── Unfallart (rechts, 2 Spalten, unterhalb Spez.Traumen) ──
        let uaY = y + CGFloat(stRows)*regH + 1
        fillRect(CGRect(x:v2RightX, y:uaY, width:v2RightW, height:7), vLightB)
        txt("Unfallart", CGRect(x:v2RightX+2, y:uaY+1, width:v2RightW*0.5-4, height:5), font:f5b, color:colBlue)
        cb("nicht bekannt", d.verletzungNichtBekannt,
           x:v2RightX+v2RightW*0.5, y:uaY+1, bs:6, lw:v2RightW*0.5-8)
        strokeRect(CGRect(x:v2RightX, y:uaY, width:v2RightW, height:7))
        let unfallart: [(String,Bool)] = [
            ("PKW / LKW-Insasse",   d.spezPkwLkw),
            ("Motorradfahrer",      d.spezMotorrad),
            ("Fahrradfahrer",       d.spezFahrrad),
            ("Fußg. angefahren",    d.spezFussgaenger),
            ("And. Verkehrsm.",     d.spezAndVerkehr),
            ("Maschinenunfall",     d.spezMaschine),
            ("Sturz > 3m",          d.spezSturzHoehe),
            ("Sturz < 3m",          d.spezSturzKlein),
            ("Schlag",              d.spezSchlag),
            ("Schuss",              d.spezSchuss),
            ("Stich",               d.spezStich),
            ("Gewaltverbrechen",    d.spezGewalt),
            ("Verschüttung",        d.spezVerschuettung),
            ("Andere Unfallart",    d.spezAndererUnfall),
        ]
        let uaRows = (unfallart.count + 1) / 2
        for row in 0..<uaRows {
            let ry = uaY + 7 + CGFloat(row)*regH
            for col in 0..<2 {
                let idx = row*2 + col
                guard idx < unfallart.count else { continue }
                let (label, checked) = unfallart[idx]
                let cx = v2RightX + CGFloat(col)*spezColW
                let bg: UIColor = row%2==0 ? .white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:cx, y:ry, width:spezColW, height:regH), bg)
                strokeRect(CGRect(x:cx, y:ry, width:spezColW, height:regH))
                cb(label, checked, x:cx+2, y:ry+1.5, bs:6, lw:spezColW-10)
            }
        }

        let v2Bottom = max(regTableBottom, uaY + 7 + CGFloat(uaRows)*regH)

        // ── Verletzungsmuster + Unfallmechanismus (volle Breite, je 1 Zeile) ──
        let botH: CGFloat = 9
        let botLblW: CGFloat = 58
        let botCbW = (leftW - botLblW) / 3

        fillRect(CGRect(x:lx, y:v2Bottom,    width:leftW, height:botH), vLightB)
        strokeRect(CGRect(x:lx, y:v2Bottom,  width:leftW, height:botH))
        txt("Verletzungsmuster", CGRect(x:lx+2, y:v2Bottom+1.5, width:botLblW-4, height:botH-3), font:f5b, color:colBlue)
        vline(lx+botLblW, v2Bottom, botH)
        cb("Einzelverletzung",   d.verletzungEinzel,     x:lx+botLblW+2,           y:v2Bottom+1.5, bs:6, lw:botCbW-10)
        cb("Mehrfachverletzung", d.verletzungMehrfach,   x:lx+botLblW+botCbW+2,    y:v2Bottom+1.5, bs:6, lw:botCbW-10)
        cb("Polytrauma",         d.verletzungPolytrauma, x:lx+botLblW+botCbW*2+2,  y:v2Bottom+1.5, bs:6, lw:botCbW-10)

        let umBotY = v2Bottom + botH
        fillRect(CGRect(x:lx, y:umBotY,   width:leftW, height:botH), vLightB)
        strokeRect(CGRect(x:lx, y:umBotY, width:leftW, height:botH))
        txt("Unfallmechanismus", CGRect(x:lx+2, y:umBotY+1.5, width:botLblW-4, height:botH-3), font:f5b, color:colBlue)
        vline(lx+botLblW, umBotY, botH)
        cb("Stumpf",        d.unfallmechStumpf,       x:lx+botLblW+2,           y:umBotY+1.5, bs:6, lw:botCbW-10)
        cb("Penetrierend",  d.unfallmechPenetrierend, x:lx+botLblW+botCbW+2,    y:umBotY+1.5, bs:6, lw:botCbW-10)
        cb("Nicht bekannt", d.unfallmechNichtBekannt, x:lx+botLblW+botCbW*2+2,  y:umBotY+1.5, bs:6, lw:botCbW-10)

        y = umBotY + botH + 2

        // ── SECTION 5 Verlauf (Grafischer Chart + Tabelle) ──
        secHeader("5. Verlauf Verlaufsbeschreibung", x:lx, y:y, w:leftW)
        y += 11

        let vMess = Array(p.verlaufMessungen.sorted { $0.zeitpunkt < $1.zeitpunkt }.prefix(8))
        let vTf = DateFormatter(); vTf.dateFormat = "HH:mm"

        // ── Grafischer Chart (wie Referenz) ──
        let chartH: CGFloat = 80
        let chartLblW: CGFloat = 30  // Y-Achsen-Labels
        let chartX = lx + chartLblW
        let chartW = leftW - chartLblW
        let chartY0 = y

        // Hintergrund
        fillRect(CGRect(x:lx, y:chartY0, width:leftW, height:chartH), .white)
        strokeRect(CGRect(x:lx, y:chartY0, width:leftW, height:chartH))

        // Y-Achse: 60–260 (Puls/RR), Gridlinien
        let yMin: CGFloat = 60; let yMax: CGFloat = 260
        let yTicks: [CGFloat] = [60,80,100,120,140,160,180,200,220,240,260]
        for tick in yTicks {
            let gy = chartY0 + chartH - (tick - yMin) / (yMax - yMin) * chartH
            hline(chartX, gy, chartW, c: UIColor(white:0.85,alpha:1), lw: 0.25)
            let isMain = Int(tick) % 40 == 0
            if isMain {
                txt("\(Int(tick))", CGRect(x:lx+1, y:gy-3, width:chartLblW-3, height:6),
                    font: UIFont.systemFont(ofSize: 4.5), color: .darkGray, align: .right)
            }
        }

        // X-Achse: Zeitstempel
        if !vMess.isEmpty {
            let xStep = chartW / CGFloat(max(vMess.count - 1, 1))
            for (i, m) in vMess.enumerated() {
                let cx = chartX + CGFloat(i) * xStep
                vline(cx, chartY0, chartH, c: UIColor(white:0.85,alpha:1), lw: 0.25)
                txt(vTf.string(from: m.zeitpunkt),
                    CGRect(x:cx-12, y:chartY0+chartH-6, width:24, height:5),
                    font: UIFont.systemFont(ofSize: 4), color: .darkGray, align: .center)
            }

            func plotLine(_ values: [CGFloat?], color: UIColor) {
                let pts = values.enumerated().compactMap { (i, v) -> CGPoint? in
                    guard let v else { return nil }
                    let px = chartX + CGFloat(i) * (chartW / CGFloat(max(values.count-1, 1)))
                    let py = chartY0 + chartH - (v - yMin) / (yMax - yMin) * chartH
                    return CGPoint(x: px, y: min(max(py, chartY0+1), chartY0+chartH-1))
                }
                guard pts.count >= 2 else { return }
                color.setStroke()
                let path = UIBezierPath(); path.lineWidth = 0.8
                path.move(to: pts[0])
                pts.dropFirst().forEach { path.addLine(to: $0) }
                path.stroke()
                // Messpunkte
                for pt in pts {
                    let dot = UIBezierPath(ovalIn: CGRect(x:pt.x-1.5, y:pt.y-1.5, width:3, height:3))
                    color.setFill(); dot.fill()
                }
            }

            let pulsCurve: [CGFloat?] = vMess.map { $0.puls.map(CGFloat.init) }
            let rrSysCurve: [CGFloat?] = vMess.map { $0.blutdruckSys.map(CGFloat.init) }
            let rrDiaCurve: [CGFloat?] = vMess.map { $0.blutdruckDia.map(CGFloat.init) }

            plotLine(rrSysCurve, color: UIColor(red:0.8, green:0.1, blue:0.1, alpha:1))
            plotLine(rrDiaCurve, color: UIColor(red:1.0, green:0.5, blue:0.0, alpha:1))
            plotLine(pulsCurve,  color: UIColor(red:0.1, green:0.4, blue:0.8, alpha:1))

            // Legende
            let legY = chartY0 + 2
            cb("RR sys", false, x:chartX+2, y:legY, bs:4, lw:20)
            UIColor(red:0.8,green:0.1,blue:0.1,alpha:1).setFill()
            UIBezierPath(ovalIn:CGRect(x:chartX+2,y:legY+0.5,width:4,height:4)).fill()
            txt("RR sys", CGRect(x:chartX+8, y:legY, width:22, height:5), font:UIFont.systemFont(ofSize:4.5), color:.darkGray)
            UIColor(red:1,green:0.5,blue:0,alpha:1).setFill()
            UIBezierPath(ovalIn:CGRect(x:chartX+33,y:legY+0.5,width:4,height:4)).fill()
            txt("RR dia", CGRect(x:chartX+39, y:legY, width:22, height:5), font:UIFont.systemFont(ofSize:4.5), color:.darkGray)
            UIColor(red:0.1,green:0.4,blue:0.8,alpha:1).setFill()
            UIBezierPath(ovalIn:CGRect(x:chartX+64,y:legY+0.5,width:4,height:4)).fill()
            txt("Puls", CGRect(x:chartX+70, y:legY, width:18, height:5), font:UIFont.systemFont(ofSize:4.5), color:.darkGray)
        }
        y = chartY0 + chartH + 1

        // ── Datentabelle unter dem Chart ──
        let vLabelW: CGFloat = 32
        let vMaxCols = min(vMess.count, 8)
        if vMaxCols > 0 {
            let vColW = (leftW - vLabelW) / CGFloat(vMaxCols)
            let vRowH: CGFloat = 9.5
            let vLabelBg = UIColor(red:0.90, green:0.95, blue:1.0, alpha:1)

            // Uhrzeit-Header
            fillRect(CGRect(x:lx, y:y, width:vLabelW, height:vRowH), vLightB)
            strokeRect(CGRect(x:lx, y:y, width:vLabelW, height:vRowH))
            txt("Uhrzeit", CGRect(x:lx+1, y:y+2, width:vLabelW-2, height:vRowH-4), font:f5, color:colBlue)
            for col in 0..<vMaxCols {
                let cx = lx + vLabelW + CGFloat(col)*vColW
                fillRect(CGRect(x:cx, y:y, width:vColW, height:vRowH), vLightB)
                strokeRect(CGRect(x:cx, y:y, width:vColW, height:vRowH))
                txt(vTf.string(from: vMess[col].zeitpunkt),
                    CGRect(x:cx+1, y:y+2, width:vColW-2, height:vRowH-4), font:f5, color:colBlue, align:.center)
            }
            y += vRowH

            let vRows: [(String, (VerlaufsMessung) -> String)] = [
                ("Puls",   { $0.puls.map { "\($0)" } ?? "" }),
                ("RR",     { ($0.blutdruckSys.map{"\($0)"}  ?? "") + ($0.blutdruckDia != nil ? "/\($0.blutdruckDia!)" : "") }),
                ("SpO₂%",  { $0.spo2.map { "\($0)" } ?? "" }),
                ("AF",     { $0.atemFrequenz.map { "\($0)" } ?? "" }),
                ("GCS",    { $0.gcsGesamt.map { "\($0)" } ?? "" }),
                ("BZ",     { $0.blutzucker.map { String(format:"%.0f",$0) } ?? "" }),
            ]
            for (row,(label,fn)) in vRows.enumerated() {
                let dataBg: UIColor = row%2==0 ? .white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:lx, y:y, width:vLabelW, height:vRowH), vLabelBg)
                strokeRect(CGRect(x:lx, y:y, width:vLabelW, height:vRowH))
                txt(label, CGRect(x:lx+1, y:y+2, width:vLabelW-2, height:vRowH-4), font:f5, color:colBlue)
                for col in 0..<vMaxCols {
                    let cx = lx + vLabelW + CGFloat(col)*vColW
                    fillRect(CGRect(x:cx, y:y, width:vColW, height:vRowH), dataBg)
                    strokeRect(CGRect(x:cx, y:y, width:vColW, height:vRowH))
                    txt(fn(vMess[col]), CGRect(x:cx+1, y:y+2, width:vColW-2, height:vRowH-4),
                        font:f5, color:.black, align:.center)
                }
                y += vRowH
            }
        }
        if !p.diagnose.verlauf.isEmpty {
            let vFtH: CGFloat = 18
            fillRect(CGRect(x:lx, y:y, width:leftW, height:vFtH), .white)
            strokeRect(CGRect(x:lx, y:y, width:leftW, height:vFtH))
            mtxt(p.diagnose.verlauf, CGRect(x:lx+2, y:y+2, width:leftW-4, height:vFtH-4), font:f6)
            y += vFtH
        }
        y += 2

        // ── SECTION 4.5 Medikamente ───────────────────────
        if !p.medikamente.isEmpty {
            secHeader("4.5 Medikamente", x:lx, y:y, w:leftW)
            y += 11
            let mTotW = leftW
            let mC: [CGFloat] = [mTotW*0.32, mTotW*0.14, mTotW*0.12, mTotW*0.20, mTotW*0.11, mTotW*0.11]
            let mHdr = ["Medikament","Dosis","Einheit","Applikationsweg","Zeit","Max.Dos."]
            fillRect(CGRect(x:lx,y:y,width:mTotW,height:9), vLightB)
            strokeRect(CGRect(x:lx,y:y,width:mTotW,height:9))
            var hx = lx
            for (i,h2) in mHdr.enumerated() {
                txt(h2, CGRect(x:hx+1,y:y+1,width:mC[i]-2,height:7), font:f6b, color:colBlue)
                hx += mC[i]
            }
            y += 9
            let medH: CGFloat = 10
            for (idx, med) in p.medikamente.enumerated() {
                if y + medH > pageSize.height - 15 { break }
                let bg = idx%2==0 ? UIColor.white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:lx,y:y,width:mTotW,height:medH), bg)
                strokeRect(CGRect(x:lx,y:y,width:mTotW,height:medH))
                var mx2 = lx
                let vals2 = [med.name, med.dosis, med.einheit, med.route, t(med.zeit), med.maximaldosis]
                for (j,val2) in vals2.enumerated() {
                    if j < vals2.count-1 { vline(mx2+mC[j], y, medH) }
                    txt(val2, CGRect(x:mx2+1.5,y:y+1.5,width:mC[j]-3,height:medH-3), font:f7)
                    mx2 += mC[j]
                }
                y += medH
            }
            y += 2
        }

        // ── SECTION 7 Reanimation / Tod ───────────────────
        let rea = p.reanimation
        let reaRelevant = p.reanimationAktiv || rea.erstHelfer || rea.vorabTelefonRea || rea.aed || rea.dnrOrder || rea.khAufnahmeVorROSC

        if reaRelevant {
            let r7W = leftW * 0.55
            let r8W = leftW * 0.45
            let r8x = lx + r7W

            secHeader("7. Reanimation / Tod", x:lx, y:y, w:r7W)
            secHeader("8. Ergebnis / NACA", x:r8x, y:y, w:r8W)
            y += 11

            let r7H: CGFloat = 10
            let r7items: [(String,Bool)] = [
                ("Beginn CPR Ersthelfer", rea.erstHelfer),
                ("Vorab Telefon-Rea", rea.vorabTelefonRea),
                ("Rettungsdienst", !p.reanimationAktiv ? false : true),
                ("AED eingesetzt", rea.aed),
                ("DNR-Order", rea.dnrOrder),
                ("KH-Aufnahme v. ROSC", rea.khAufnahmeVorROSC),
                ("Laufende Rea. b. Übergabe", rea.laufendeReanimation),
            ]
            let r7y0 = y
            for (i,(label,checked)) in r7items.enumerated() {
                let ry = r7y0 + CGFloat(i)*r7H
                let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:lx,y:ry,width:r7W/2,height:r7H), bg)
                strokeRect(CGRect(x:lx,y:ry,width:r7W/2,height:r7H))
                cb(label, checked, x:lx+2, y:ry+1, bs:7, lw:r7W/2-12)
            }

            // Times column
            let r7tx = lx + r7W/2
            let r7tW = r7W/2
            field("Kollaps-Zeit", rea.kollapsZeitUnbekannt ? "Unbekannt" : t(rea.kollapsZeit),
                  x:r7tx, y:r7y0, w:r7tW, h:r7H, lw:r7tW*0.55)
            field("Init. Rhythmus", rea.initialRhythmus.rawValue,
                  x:r7tx, y:r7y0+r7H, w:r7tW, h:r7H, lw:r7tW*0.55)
            field("Start Ersthelfer", rea.startErsthelferUnbekannt ? "Unbek." : t(rea.startErsthelferCPR),
                  x:r7tx, y:r7y0+r7H*2, w:r7tW, h:r7H, lw:r7tW*0.55)
            field("Start RD-CPR", rea.startRDUnbekannt ? "Unbekannt" : t(rea.startRettungsdienst),
                  x:r7tx, y:r7y0+r7H*3, w:r7tW, h:r7H, lw:r7tW*0.55)
            field("Ende RD-CPR", t(rea.endeRettungsdienst),
                  x:r7tx, y:r7y0+r7H*4, w:r7tW, h:r7H, lw:r7tW*0.55)
            field("Outcome", p.reanimationAktiv ? rea.outcome.rawValue : "–",
                  x:r7tx, y:r7y0+r7H*5, w:r7tW, h:r7H, lw:r7tW*0.55, hl:p.reanimationAktiv)

            if rea.defiAnzahl > 0 {
                let defY = r7y0 + CGFloat(r7items.count)*r7H
                field("Defi Anzahl", "\(rea.defiAnzahl)", x:lx, y:defY, w:r7W/2, h:r7H, lw:r7W*0.22)
                field("Defi Joule", "\(rea.defiJoule) J", x:r7tx, y:defY, w:r7tW, h:r7H, lw:r7tW*0.55)
            }

            // Outcome-spezifische Zeiten
            if rea.outcome == .rosc, let roscT = rea.roscZeit {
                let roscY = r7y0 + CGFloat(r7items.count + (rea.defiAnzahl > 0 ? 1 : 0))*r7H
                field("ROSC-Zeitpunkt", t(roscT), x:r7tx, y:roscY, w:r7tW, h:r7H, lw:r7tW*0.55)
            }
            if rea.outcome == .verstorben, let todT = rea.todFeststellungsZeit {
                let todY = r7y0 + CGFloat(r7items.count + (rea.defiAnzahl > 0 ? 1 : 0))*r7H
                field("Todeszeitpunkt", t(todT), x:r7tx, y:todY, w:r7tW, h:r7H, lw:r7tW*0.55)
            }

            // Section 8 NACA — single line instead of 8-row radio list
            if let naca = p.notfallGeschehen.nacaScoreWert {
                field("NACA", naca.beschreibung, x:r8x, y:r7y0, w:r8W, h:10, lw:20)
            }

            // Update final y — use only Section 7 height (NACA is now max 1 row)
            let r7RowsCount = r7items.count + (rea.defiAnzahl > 0 ? 1 : 0)
                + (rea.outcome == .rosc && rea.roscZeit != nil ? 1 : 0)
                + (rea.outcome == .verstorben && rea.todFeststellungsZeit != nil ? 1 : 0)
            y = r7y0 + CGFloat(r7RowsCount) * r7H + 2

            if !rea.freitext.isEmpty && y + 11 < pageSize.height - 15 {
                let h = fieldH(rea.freitext, width: leftW - 93)
                field("Reanimation – Notizen", rea.freitext, x:lx, y:y, w:leftW, h:h, lw:90, multiline: true)
                y += h
            }
        } else if let naca = p.notfallGeschehen.nacaScoreWert {
            secHeader("8. Ergebnis / NACA", x:lx, y:y, w:leftW)
            y += 11
            field("NACA", naca.beschreibung, x:lx, y:y, w:leftW, h:10, lw:20)
            y += 12
        }

        // ── SECTION 9 Übergabe ────────────────────────────
        secHeader("9. Übergabe / Transportziel / Einsatzbesonderheiten", x:lx, y:y, w:leftW)
        y += 11

        let tzItems: [(String, Bool)] = [
            ("ZNA / Notaufnahme", p.ergebnis.transportzielZna),
            ("Stroke Unit",       p.ergebnis.transportzielStrokeUnit),
            ("Kath.-Labor",       p.ergebnis.transportzielKathLabor),
        ]
        let tzColW = leftW / CGFloat(tzItems.count + 1)
        fillRect(CGRect(x:lx, y:y, width:leftW, height:10), .white)
        strokeRect(CGRect(x:lx, y:y, width:leftW, height:10))
        for (i,(label,checked)) in tzItems.enumerated() {
            cb(label, checked, x:lx+CGFloat(i)*tzColW+2, y:y+1.5, bs:7, lw:tzColW-12)
        }
        if !p.ergebnis.transportzielSonstigesKH.isEmpty {
            field("Sonstiges KH", p.ergebnis.transportzielSonstigesKH,
                  x:lx+tzColW*3, y:y, w:tzColW, h:10, lw:50)
        }
        y += 10

        field("Übergabe an Rettungsmittel", p.uebergabeAn, x:lx, y:y, w:leftW, h:12, lw:100, hl:true)
        y += 12

        let p2ValW: CGFloat = leftW - 83
        let zustandH = fieldH(p.zustandBeiUebergabe, width: p2ValW)
        field("Zustand bei Übergabe", p.zustandBeiUebergabe, x:lx, y:y, w:leftW, h:zustandH, lw:80, multiline: true)
        y += zustandH
        if !p.diagnose.diagnoseFreitext.isEmpty && y + 11 < pageSize.height - 15 {
            let h = fieldH(p.diagnose.diagnoseFreitext, width: p2ValW)
            field("Diagnose-Freitext", p.diagnose.diagnoseFreitext, x:lx, y:y, w:leftW, h:h, lw:80, multiline: true)
            y += h
        }
        if !p.ergebnis.anmerkungen.isEmpty && y + 11 < pageSize.height - 15 {
            let h = fieldH(p.ergebnis.anmerkungen, width: p2ValW)
            field("Anmerkungen", p.ergebnis.anmerkungen, x:lx, y:y, w:leftW, h:h, lw:80, multiline: true)
            y += h
        }
        if !p.ergebnis.firstResponderBesonderheiten.isEmpty && y + 11 < pageSize.height - 15 {
            let h = fieldH(p.ergebnis.firstResponderBesonderheiten, width: p2ValW)
            field("FR-Besonderheiten", p.ergebnis.firstResponderBesonderheiten, x:lx, y:y, w:leftW, h:h, lw:90, multiline: true)
            y += h
        }

        let p2safe = pageSize.height - 16
        let besatzungEntries: [(String, Qualifikation)] = [
            (p.besatzung.sanitaeter1, p.besatzung.qualifikation1),
            (p.besatzung.sanitaeter2, p.besatzung.qualifikation2),
            (p.besatzung.sanitaeter3, p.besatzung.qualifikation3),
            (p.besatzung.sanitaeter4, p.besatzung.qualifikation4),
        ]
        let besatzungNames = besatzungEntries
            .filter { !$0.0.isEmpty }
            .map { "\($0.0) (\($0.1.rawValue))" }
            .joined(separator: " · ")
        if !besatzungNames.isEmpty && y + 11 < p2safe {
            field("Besatzung", besatzungNames, x:lx, y:y, w:leftW, h:11, lw:42)
            y += 11
        }

        // Einsatzbesonderheiten checkboxes
        let besItems: [(String,Bool)] = [
            ("FR-Einsatz", p.ergebnis.frEinsatz),
            ("Ambulant vor Ort", p.ergebnis.ambulantVorOrt),
            ("KH nicht erreichbar", p.ergebnis.naechstesKHNichtErreichbar),
            ("Pat. nicht transp.fähig", p.ergebnis.patNichtTransportfaehig),
            ("Tod Einsatzstelle", p.ergebnis.todAnEinsatzstelle),
            ("Zwangsunterbringung", p.ergebnis.zwangsunterbringung),
            ("Mehrere Patienten", p.ergebnis.mehrerePatient),
            ("Aufwändige Rettung", p.ergebnis.aufwaendigeRettung),
            ("Infektionsschutz", p.ergebnis.infektionsSchutz),
            ("LNA/GRL im Einsatz", p.ergebnis.lnaGrleimEinsatz),
            ("Schwerlasttransport", p.ergebnis.schwerlasttransport),
            ("Voranmeldung", p.ergebnis.voranmeldung),
            ("Gelb Alarm", p.ergebnis.gelbAlarm),
            ("Rot Alarm", p.ergebnis.rotAlarm),
            ("Mitfahrverweigerung", p.ergebnis.mifahrverweigerung),
        ]
        let besH: CGFloat = 9.5
        let besPerCol = (besItems.count + 2) / 3
        let besColW = leftW / 3
        let besBlockH = CGFloat(besPerCol) * besH
        if y + besBlockH < p2safe {
            for (i,(label,checked)) in besItems.enumerated() {
                let col = i / besPerCol
                let row = i % besPerCol
                let bx = lx + CGFloat(col)*besColW
                let by = y + CGFloat(row)*besH
                let bg: UIColor = row%2==0 ? .white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:bx,y:by,width:besColW,height:besH), bg)
                strokeRect(CGRect(x:bx,y:by,width:besColW,height:besH))
                cb(label, checked, x:bx+2, y:by+1, bs:7, lw:besColW-12)
            }
            y += besBlockH + 2
        }

        // ── Unterschrift ──────────────────────────────────
        let sigH: CGFloat = min(40, pageSize.height - y - 16)
        if sigH > 15 {
            fillRect(CGRect(x:lx,y:y,width:leftW,height:sigH), .white)
            strokeRect(CGRect(x:lx,y:y,width:leftW,height:sigH))
            let sigDate = DateFormatter()
            sigDate.dateFormat = "dd.MM.yyyy HH:mm"
            let datumBreite: CGFloat = 140
            txt("Datum / Uhrzeit: \(sigDate.string(from: Date()))",
                CGRect(x:lx+4, y:y+sigH-12, width:datumBreite, height:10), font:f7)
            txt("Unterschrift:", CGRect(x:lx+datumBreite+10, y:y+sigH-12, width:60, height:10), font:f7)
            if let data = p.unterschriftData, let img = UIImage(data: data) {
                let sigW: CGFloat = leftW - datumBreite - 80
                let sigRect = CGRect(x: lx + datumBreite + 74, y: y + 2, width: sigW, height: sigH - 14)
                img.draw(in: sigRect)
            }
        }

        drawFooter(erstelltAm: p.erstelltAm)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - Verlaufs-Tabellen Seite
    // ─────────────────────────────────────────────────────

    /// Trend arrow comparing two optional numeric values (b vs a)
    private static func trendPfeil(_ a: Double?, _ b: Double?) -> String {
        guard let a, let b else { return " " }
        if b > a { return "↑" } else if b < a { return "↓" } else { return "→" }
    }

    private static func drawVerlaufsTabellenSeite(p: EinsatzProtokoll, messungen: [VerlaufsMessung]) {
        let tLx: CGFloat = 7; let tRx: CGFloat = pageSize.width - 7
        var y: CGFloat = 28

        // Page header
        fillRect(CGRect(x:0, y:0, width:pageSize.width, height:22), colBlue)
        txt("Verlaufsmessungen – tabellarische Übersicht",
            CGRect(x:tLx, y:3, width:tRx-tLx, height:16), font:f10b, color:.white)
        txt("\(p.patientDaten.nachname), \(p.patientDaten.vorname)   |   Einsatz: \(p.einsatzOrt.einsatzNummer)",
            CGRect(x:tRx-230, y:13, width:225, height:8), font:f6, color:.white, align:.right)

        let timeFmt = DateFormatter(); timeFmt.dateFormat = "HH:mm"
        let totW = tRx - tLx

        // Column definitions: (header, relative width fraction)
        let colDefs: [(String, CGFloat)] = [
            ("Zeit",         0.09),
            ("AF\n/min",     0.08),
            ("SpO₂\n%",      0.08),
            ("Puls\n/min",   0.09),
            ("RR\nsys/dia",  0.13),
            ("GCS",          0.07),
            ("BZ\nmg/dL",    0.09),
            ("Temp\n°C",     0.10),
            ("Maßnahmen / Bemerkung", 0.27),
        ]
        let colWs = colDefs.map { totW * $0.1 }
        let hdrH: CGFloat = 16
        let rowH: CGFloat = 12

        // Draw header row
        fillRect(CGRect(x:tLx, y:y, width:totW, height:hdrH), vLightB)
        strokeRect(CGRect(x:tLx, y:y, width:totW, height:hdrH))
        var cx = tLx
        for (i, (hdr, _)) in colDefs.enumerated() {
            if i > 0 { vline(cx, y, hdrH) }
            let lines = hdr.components(separatedBy: "\n")
            if lines.count == 2 {
                txt(lines[0], CGRect(x:cx+1.5, y:y+1, width:colWs[i]-3, height:7), font:f6b, color:colBlue, align:.center)
                txt(lines[1], CGRect(x:cx+1.5, y:y+8, width:colWs[i]-3, height:7), font:f5,  color:colBlue, align:.center)
            } else {
                txt(hdr, CGRect(x:cx+1.5, y:y+4, width:colWs[i]-3, height:8), font:f6b, color:colBlue, align:.center)
            }
            cx += colWs[i]
        }
        y += hdrH

        // Draw data rows
        for (idx, m) in messungen.enumerated() {
            if y + rowH > pageSize.height - 16 { break }
            let prev: VerlaufsMessung? = idx > 0 ? messungen[idx-1] : nil
            let bg: UIColor = idx % 2 == 0 ? .white : UIColor(white:0.97, alpha:1)
            fillRect(CGRect(x:tLx, y:y, width:totW, height:rowH), bg)
            strokeRect(CGRect(x:tLx, y:y, width:totW, height:rowH))

            let afTrend   = trendPfeil(prev.flatMap { $0.atemFrequenz.map(Double.init) },   m.atemFrequenz.map(Double.init))
            let spo2Trend = trendPfeil(prev.flatMap { $0.spo2.map(Double.init) },            m.spo2.map(Double.init))
            let pulsTrend = trendPfeil(prev.flatMap { $0.puls.map(Double.init) },            m.puls.map(Double.init))
            let sysTrend  = trendPfeil(prev.flatMap { $0.blutdruckSys.map(Double.init) },    m.blutdruckSys.map(Double.init))
            let gcsTrend  = trendPfeil(prev.flatMap { $0.gcsGesamt.map(Double.init) },       m.gcsGesamt.map(Double.init))
            let bzTrend   = trendPfeil(prev.flatMap { $0.blutzucker },                        m.blutzucker)
            let tempTrend = trendPfeil(prev.flatMap { $0.temperatur },                        m.temperatur)

            let rrText: String = {
                let s = m.blutdruckSys.map { "\($0)" } ?? ""
                let d = m.blutdruckDia.map { "\($0)" } ?? ""
                if s.isEmpty && d.isEmpty { return "" }
                return "\(s)/\(d)\(sysTrend)"
            }()

            let cellValues: [String] = [
                timeFmt.string(from: m.zeitpunkt),
                m.atemFrequenz.map { "\($0)\(afTrend)" } ?? "",
                m.spo2.map        { "\($0)\(spo2Trend)" } ?? "",
                m.puls.map        { "\($0)\(pulsTrend)" } ?? "",
                rrText,
                m.gcsGesamt.map   { "\($0)\(gcsTrend)" } ?? "",
                m.blutzucker.map  { "\(String(format:"%.0f",$0))\(bzTrend)" } ?? "",
                m.temperatur.map  { "\(String(format:"%.1f",$0))\(tempTrend)" } ?? "",
                [m.massnahmen, m.freitext].filter{!$0.isEmpty}.joined(separator: " · "),
            ]

            var vx = tLx
            for (i, val) in cellValues.enumerated() {
                if i > 0 { vline(vx, y, rowH) }
                txt(val, CGRect(x:vx+1.5, y:y+2, width:colWs[i]-3, height:rowH-4), font:f7, align:.center)
                vx += colWs[i]
            }
            y += rowH
        }

        // Maßnahmen legend note
        y += 4
        if y + 9 < pageSize.height - 16 {
            txt("↑ gestiegen  ↓ gefallen  → unverändert  (Trend gegenüber Vormessung)",
                CGRect(x:tLx, y:y, width:totW, height:8), font:f5, color:.darkGray)
        }

        drawFooter(erstelltAm: p.erstelltAm)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - Verlaufs-Chart Seite
    // ─────────────────────────────────────────────────────

    private static func drawVerlaufsChart(p: EinsatzProtokoll, messungen: [VerlaufsMessung]) {
        let ctx = UIGraphicsGetCurrentContext()!
        let lx: CGFloat = 20; let rx: CGFloat = pageSize.width - 20
        var y: CGFloat = 30

        // Header
        let hFont = UIFont.boldSystemFont(ofSize: 11)
        txt("Vitalwerte-Verlauf", CGRect(x: lx, y: y, width: rx - lx, height: 14), font: hFont)
        y += 18

        let timeFmt = DateFormatter(); timeFmt.dateFormat = "HH:mm"

        // Series to draw: label, color, normalRange, values extractor
        struct Series {
            let label: String; let color: UIColor
            let normalMin: Double?; let normalMax: Double?
            let values: [Double?]
        }

        let n = messungen.count
        let series: [Series] = [
            Series(label: "Puls /min",  color: .systemRed,
                   normalMin: 60, normalMax: 100,
                   values: messungen.map { $0.puls.map(Double.init) }),
            Series(label: "SpO₂ %",    color: .systemBlue,
                   normalMin: 95, normalMax: nil,
                   values: messungen.map { $0.spo2.map(Double.init) }),
            Series(label: "RR syst.",  color: .systemOrange,
                   normalMin: 100, normalMax: 140,
                   values: messungen.map { $0.blutdruckSys.map(Double.init) }),
        ]

        let chartW: CGFloat = rx - lx - 60
        let chartH: CGFloat = 70
        let axisX: CGFloat = lx + 44

        for ser in series {
            let vals = ser.values.compactMap { $0 }
            guard !vals.isEmpty else { continue }

            // Label
            txt(ser.label, CGRect(x: lx, y: y + chartH * 0.5 - 6, width: 42, height: 12),
                font: UIFont.systemFont(ofSize: 7), color: .black, align: .right)

            // Background
            fillRect(CGRect(x: axisX, y: y, width: chartW, height: chartH), UIColor.systemGray6)
            strokeRect(CGRect(x: axisX, y: y, width: chartW, height: chartH), UIColor.separator, lw: 0.5)

            // Normal range band
            let allVals = vals
            let dataMin = (allVals.min() ?? 0) - 10
            let dataMax = (allVals.max() ?? 100) + 10
            let valRange = max(dataMax - dataMin, 1)

            if let nMin = ser.normalMin, let nMax = ser.normalMax {
                let bandY1 = y + chartH * CGFloat(1 - (nMax - dataMin) / valRange)
                let bandY2 = y + chartH * CGFloat(1 - (nMin - dataMin) / valRange)
                fillRect(CGRect(x: axisX, y: max(y, bandY1), width: chartW,
                                height: min(chartH, bandY2 - max(0, bandY1 - y))), UIColor.systemGreen.withAlphaComponent(0.08))
            } else if let nMin = ser.normalMin {
                let bandY = y + chartH * CGFloat(1 - (nMin - dataMin) / valRange)
                fillRect(CGRect(x: axisX, y: y, width: chartW, height: max(0, bandY - y)), UIColor.systemGreen.withAlphaComponent(0.08))
            }

            // Draw lines + points
            ctx.saveGState()
            ctx.clip(to: CGRect(x: axisX, y: y, width: chartW, height: chartH))
            ctx.setStrokeColor(ser.color.cgColor)
            ctx.setLineWidth(1.2)
            var prevPt: CGPoint? = nil

            for (i, rawVal) in ser.values.enumerated() {
                guard let v = rawVal else { prevPt = nil; continue }
                let xPos = axisX + chartW * CGFloat(i) / CGFloat(max(n - 1, 1))
                let yPos = y + chartH * CGFloat(1 - (v - dataMin) / valRange)
                let pt = CGPoint(x: xPos, y: yPos)
                if let prev = prevPt {
                    ctx.move(to: prev); ctx.addLine(to: pt); ctx.strokePath()
                }
                fillRect(CGRect(x: pt.x - 2, y: pt.y - 2, width: 4, height: 4), ser.color)
                // Value label
                txt(String(Int(v)), CGRect(x: pt.x - 8, y: pt.y - 10, width: 16, height: 8),
                    font: UIFont.systemFont(ofSize: 6), color: ser.color, align: .center)
                prevPt = pt
            }
            ctx.restoreGState()

            // Time axis labels (max 6)
            let step = max(1, n / 6)
            for (i, m) in messungen.enumerated() where i % step == 0 || i == n - 1 {
                let xPos = axisX + chartW * CGFloat(i) / CGFloat(max(n - 1, 1))
                txt(timeFmt.string(from: m.zeitpunkt),
                    CGRect(x: xPos - 12, y: y + chartH + 2, width: 24, height: 8),
                    font: UIFont.systemFont(ofSize: 5.5), color: .black, align: .center)
            }

            y += chartH + 14
        }

        // Legend
        let legY = y + 4
        var legX = axisX
        for ser in series where !ser.values.compactMap({$0}).isEmpty {
            fillRect(CGRect(x: legX, y: legY + 3, width: 14, height: 4), ser.color)
            txt(ser.label, CGRect(x: legX + 16, y: legY, width: 55, height: 10),
                font: UIFont.systemFont(ofSize: 7), color: ser.color)
            legX += 75
        }

        drawFooter(erstelltAm: p.erstelltAm)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - Foto-Anhang Seiten
    // ─────────────────────────────────────────────────────

    private static func drawFotoPages(ctx: UIGraphicsPDFRendererContext,
                                       mediFotos: [FotoEintrag],
                                       patFotos: [FotoEintrag],
                                       erstelltAm: Date) {
        let groups: [(String, [FotoEintrag])] = [
            ("Medikamentenplan", mediFotos),
            ("Patientenfoto",    patFotos),
        ].filter { !$1.isEmpty }

        for (label, fotos) in groups {
            for (i, foto) in fotos.enumerated() {
                guard let image = UIImage(contentsOfFile: foto.bildURL.path) else { continue }
                ctx.beginPage()

                let hh: CGFloat = 22
                fillRect(CGRect(x: 0, y: 0, width: pageSize.width, height: hh), colBlue)
                txt("\(label) – Foto \(i + 1) / \(fotos.count)",
                    CGRect(x: lx, y: 3, width: pageSize.width - lx - 4, height: 16),
                    font: f13b, color: .white)

                let footerH: CGFloat = 14
                let availW = rx - lx
                let availH = pageSize.height - hh - footerH - 8
                let imageArea = CGRect(x: lx, y: hh + 4, width: availW, height: availH)

                let imgSize = image.size
                guard imgSize.width > 0, imgSize.height > 0 else {
                    drawFooter(erstelltAm: erstelltAm)
                    continue
                }
                let scale = min(imageArea.width / imgSize.width, imageArea.height / imgSize.height)
                let scaledW = imgSize.width * scale
                let scaledH = imgSize.height * scale
                let drawRect = CGRect(
                    x: imageArea.midX - scaledW / 2,
                    y: imageArea.midY - scaledH / 2,
                    width: scaledW,
                    height: scaledH
                )
                image.draw(in: drawRect)
                drawFooter(erstelltAm: erstelltAm)
            }
        }
    }

    // ─────────────────────────────────────────────────────
    // MARK: - Footer
    // ─────────────────────────────────────────────────────

    private static func drawFooter(erstelltAm: Date) {
        let fy = pageSize.height - 14
        fillRect(CGRect(x:0,y:fy,width:pageSize.width,height:14), UIColor(white:0.93,alpha:1))
        UIColor.lightGray.setStroke()
        UIBezierPath(rect: CGRect(x:0,y:fy,width:pageSize.width,height:0.4)).stroke()
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yyyy HH:mm"
        let attrs: [NSAttributedString.Key:Any] = [.font:f5, .foregroundColor:UIColor.gray]
        ("Einsatz vom: \(fmt.string(from: erstelltAm))" as NSString).draw(
            at: CGPoint(x:lx,y:fy+4), withAttributes:attrs)
        ("DLRG Einsatzprotokoll – Vertraulich" as NSString).draw(
            at: CGPoint(x:pageSize.width-175,y:fy+4), withAttributes:attrs)
    }
}
