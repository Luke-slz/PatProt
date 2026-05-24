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
                               lFont: UIFont? = nil, vFont: UIFont? = nil) {
        let bg = hl ? hlYellow : .white
        fillRect(CGRect(x:x,y:y,width:w,height:h), bg)
        strokeRect(CGRect(x:x,y:y,width:w,height:h))
        if lw > 0 {
            vline(x+lw, y, h)
            txt(label, CGRect(x:x+1.5,y:y+1.5,width:lw-3,height:h-3),
                font:lFont ?? f6, color:.darkGray)
        }
        txt(value, CGRect(x:x+lw+1.5,y:y+1.5,width:w-lw-3,height:h-3),
            font:vFont ?? f7, color:.black)
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
                ctx.beginPage()
                drawPage1(p: protokoll)
                ctx.beginPage()
                drawPage2(p: protokoll)
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

        // ── Header bar ───────────────────────────────────
        let hh: CGFloat = 22
        fillRect(CGRect(x:0,y:0,width:pageSize.width,height:hh), colBlue)
        txt("EINSATZPROTOKOLL",
            CGRect(x:lx,y:3,width:230,height:16), font:f13b, color:.white)
        txt("Einsatz-Nr.: \(p.einsatzOrt.einsatzNummer)   Datum: \(d(p.einsatzOrt.alarmzeit))",
            CGRect(x:260,y:5,width:240,height:9), font:f7b, color:.white)
        txt("Seite 1 / 2",
            CGRect(x:pageSize.width-55,y:13,width:50,height:8), font:f6, color:.white, align:.right)

        var y: CGFloat = hh

        // ── Row A: Patient (left) | Section 1 (right) ──

        // Left: patient header (klinisch relevante Felder)
        do {
            let x = lx; let w = c1 - lx
            field("Name des Patienten",
                  "\(p.patientDaten.nachname), \(p.patientDaten.vorname)",
                  x:x, y:y, w:w, h:14, lw:w*0.38, hl:true)
            field("geb. am", d(p.patientDaten.geburtsDatum),
                  x:x, y:y+14, w:w*0.55, h:12, lw:38)
            field("Geschlecht", p.patientDaten.geschlecht.rawValue,
                  x:x+w*0.55, y:y+14, w:w*0.45, h:12, lw:42)
            let fw2 = w / 2
            field("Versicherten-Nr.", p.patientDaten.versicherungsNummer,
                  x:x, y:y+26, w:fw2, h:12, lw:fw2*0.5)
            let gewStr = p.patientDaten.gewicht.map { String(format: "%.0f kg", $0) } ?? ""
            field("Gewicht", gewStr, x:x+fw2, y:y+26, w:fw2, h:12, lw:fw2*0.5)
        }

        // Right: Section 1 Rettungstechnische Daten
        do {
            let x = c1; let w = rx - c1
            secHeader("1. Rettungstechnische Daten", x:x, y:y, w:w)
            let sh: CGFloat = 11; y += sh

            // Vehicle checkboxes — auto-detect aus fahrzeugName
            let fzUp = p.einsatzOrt.fahrzeugName.uppercased()
            let vItems: [(String, Bool)] = [
                ("RTW", fzUp.contains("RTW")),
                ("KTW", fzUp.contains("KTW")),
                ("NEF", fzUp.contains("NEF")),
                ("MHW", fzUp.contains("MHW")),
                ("VRW", fzUp.contains("VRW")),
                ("RTH", fzUp.contains("RTH")),
                ("FR",  fzUp.contains("FR") || fzUp.contains("FIRST")),
            ]
            let vColW = w / CGFloat(vItems.count)
            fillRect(CGRect(x:x, y:y, width:w, height:11), .white)
            strokeRect(CGRect(x:x, y:y, width:w, height:11))
            for (i,(label,checked)) in vItems.enumerated() {
                cb(label, checked, x:x+CGFloat(i)*vColW+2, y:y+1.5, bs:7, lw:vColW-11)
            }
            y += 11

            // Sondersignal / Notarzt
            let r2h: CGFloat = 11
            fillRect(CGRect(x:x,y:y,width:w,height:r2h), .white)
            strokeRect(CGRect(x:x,y:y,width:w,height:r2h))
            cb("Sondersignal", p.einsatzOrt.sondersignal, x:x+2, y:y+1.5, bs:7, lw:55)
            cb("Notarzt", p.einsatzOrt.notarzt, x:x+80, y:y+1.5, bs:7, lw:35)
            cb("mit Patient", p.einsatzOrt.mitPatient, x:x+130, y:y+1.5, bs:7, lw:45)
            y += r2h

            // Dokumentations-RM
            field("Dokumentations-Rettungsmittel", p.einsatzOrt.fahrzeugName,
                  x:x, y:y, w:w/2, h:11, lw:w*0.22)
            field("Weitere Rettungsmittel", p.einsatzOrt.weitereEinsatzmittel.joined(separator: ", "),
                  x:x+w/2, y:y, w:w/2, h:11, lw:w*0.22)
            y += 11

            // Times block (alarm / ankunft / abfahrt)
            let tW = w / 3
            labeledVal("Alarm", t(p.einsatzOrt.alarmzeit),
                       x:x, y:y, w:tW, labelH:7, valH:11)
            labeledVal("Ankunft Einsatzort", t(p.einsatzOrt.ankunftzeit),
                       x:x+tW, y:y, w:tW, labelH:7, valH:11)
            labeledVal("Abfahrt Einsatzstelle", t(p.einsatzOrt.abfahrtzeit),
                       x:x+tW*2, y:y, w:tW, labelH:7, valH:11)
            y += 18

            let tW2 = w / 2
            labeledVal("Ankunft Zielklinik", t(p.einsatzOrt.krankenHausAnkunft),
                       x:x, y:y, w:tW2, labelH:7, valH:11)
            labeledVal("Einsatz-Nr.", p.einsatzOrt.einsatzNummer,
                       x:x+tW2, y:y, w:tW2, labelH:7, valH:11)
            y += 18
            let adresseText = [p.einsatzOrt.adresse, p.einsatzOrt.zusatz].filter { !$0.isEmpty }.joined(separator: ", ")
            let stichwortText = [p.einsatzOrt.stichwort, p.einsatzOrt.einsatzArt]
                .filter { !$0.isEmpty }.joined(separator: " · ")
            field("Einsatzort", adresseText, x:x, y:y, w:w/2, h:11, lw:42)
            field("Stichwort", stichwortText, x:x+w/2, y:y, w:w/2, h:11, lw:42)
            y += 11
        }
        let rightY = y   // Section 1 right column bottom

        // ── EINSATZPROTOKOLL title block (directly below patient block) ──
        let titleY = hh + 38
        do {
            let x = lx; let w = c1 - lx; let bh: CGFloat = 36
            fillRect(CGRect(x:x,y:titleY,width:w,height:bh), vLightB)
            strokeRect(CGRect(x:x,y:titleY,width:w,height:bh))
            txt("EINSATZPROTOKOLL",
                CGRect(x:x+3,y:titleY+3,width:w-6,height:14), font:f13b, color:colBlue)
            cb("Notfallsanitäter", p.verfasser == .notfallsanitaeter, x:x+3, y:titleY+19, bs:7, lw:80)
            cb("Rettungssanitäter", p.verfasser == .rettungssanitaeter, x:x+95, y:titleY+19, bs:7, lw:80)
        }

        y = max(rightY, titleY + 36)

        // ── SECTION 2 ──────────────────────────────────────
        secHeader("2. Notfallgeschehen / Anamnese / Erstbefund", x:lx, y:y, w:rx-lx)
        y += 11

        // Notfallgeschehen Felder
        let ng = p.notfallGeschehen
        if !ng.erstbefundVorOrt.isEmpty {
            field("Erstbefund", ng.erstbefundVorOrt, x:lx, y:y, w:rx-lx, h:11, lw:50)
            y += 11
        }
        if !ng.patientGefunden.isEmpty || ng.manv {
            let beteiligteLabel = ng.manv
                ? "MANV\(ng.ersteEintreffendeKraft ? " · 1. Eintreffend" : "") · \(ng.anzahlBeteiligte) Bet."
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
        if !ng.manvLagemeldung.isEmpty {
            field("Lagemeldung", ng.manvLagemeldung, x:lx, y:y, w:rx-lx, h:11, lw:55)
            y += 11
        }
        if !ng.manvNachforderung.isEmpty {
            field("Nachforderung", ng.manvNachforderung, x:lx, y:y, w:rx-lx, h:11, lw:60)
            y += 11
        }
        if !ng.ersthelferMassnahmen.isEmpty {
            field("Ersthelfer", ng.ersthelferMassnahmen, x:lx, y:y, w:rx-lx, h:11, lw:50)
            y += 11
        }

        // Neue Notfallgeschehen-Felder
        let unfallHergangText = (ng.unfallhergangAuswahl + (ng.unfallhergangFreitext.isEmpty ? [] : [ng.unfallhergangFreitext])).joined(separator: ", ")
        if !unfallHergangText.isEmpty {
            field("Unfallhergang", unfallHergangText, x:lx, y:y, w:rx-lx, h:11, lw:65)
            y += 11
        }
        let unfallMechText = [ng.unfallmechanismus, ng.unfallmechanismusFreitext].filter{!$0.isEmpty}.joined(separator: " – ")
        if !unfallMechText.isEmpty {
            field("Unfallmechanismus", unfallMechText, x:lx, y:y, w:rx-lx, h:11, lw:72)
            y += 11
        }
        if !ng.preEmergencyStatus.isEmpty {
            field("Pre-Emergency Status", ng.preEmergencyStatus, x:lx, y:y, w:rx-lx, h:11, lw:85)
            y += 11
        }
        let erstbefundAuswahlText = ng.erstbefundAuswahl.joined(separator: ", ")
        if !erstbefundAuswahlText.isEmpty {
            field("Erstbefund (Auswahl)", erstbefundAuswahlText, x:lx, y:y, w:rx-lx, h:11, lw:85)
            y += 11
        }
        if !ng.verlaufsbemerkungen.isEmpty {
            field("Verlaufsbemerkungen", ng.verlaufsbemerkungen, x:lx, y:y, w:rx-lx, h:11, lw:85)
            y += 11
        }

        // SAMPLER — immer alle 7 Zeilen anzeigen
        let samplerAllRows: [(String, String)] = [
            ("S – Symptome",       p.sampler.symptome),
            ("A – Allergien",      p.sampler.allergien),
            ("M – Medikamente",    p.medikamentFotos.isEmpty
                                    ? p.sampler.medikamente
                                    : "Medikamentenplan: Foto-Anhang (S. 3ff.)"),
            ("P – Vorgeschichte",  p.sampler.patientenVorgeschichte),
            ("L – Letztes Essen",  p.sampler.letztesMahl),
            ("E – Ereignis",       p.sampler.ereignis),
            ("R – Risikofaktoren", p.sampler.risikofaktoren),
        ]
        for (label, value) in samplerAllRows {
            field(label, value, x:lx, y:y, w:rx-lx, h:11, lw:85)
            y += 11
        }

        // ABCDE grid
        let abcdeLetters = ["A","B","C","D","E"]
        func buildAirwayDetail() -> String {
            var parts = [p.airway.freitext]
            if p.airway.verlegung && !p.airway.verlegungsUrsache.isEmpty { parts.append("Ursache: \(p.airway.verlegungsUrsache)") }
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        func buildBreathingDetail() -> String {
            var parts = [p.breathing.freitext]
            if !p.breathing.atemgeraeusche.isEmpty { parts.append("Atemger.: \(p.breathing.atemgeraeusche)") }
            if p.breathing.sauerstoffGabe, let lit = p.breathing.sauerstoffLiter { parts.append("O₂: \(String(format: "%.0f", lit))l/min") }
            if p.breathing.beatmung && !p.breathing.beatmungsform.isEmpty { parts.append("Beatm.: \(p.breathing.beatmungsform)") }
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        func buildCirculationDetail() -> String {
            var parts = [p.circulation.freitext]
            if !p.circulation.ekgBefund.isEmpty { parts.append("EKG: \(p.circulation.ekgBefund)") }
            if p.circulation.blutung && !p.circulation.blutungLokalisation.isEmpty { parts.append("Blutung: \(p.circulation.blutungLokalisation)") }
            if p.circulation.ivZugang && !p.circulation.ivLokalisation.isEmpty { parts.append("IV: \(p.circulation.ivLokalisation)") }
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
            if !flags.isEmpty { parts.append(flags.joined(separator: ", ")) }
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        let abcdeRaw = [buildAirwayDetail(), buildBreathingDetail(), buildCirculationDetail(), p.disability.freitext, buildExposureDetail()]
        let abcdeVals   = abcdeRaw.map { $0.isEmpty ? "o.B." : $0 }
        let abcdeColors = abcdeRaw.map { $0.isEmpty ? UIColor.lightGray : UIColor.black }
        let rowH: CGFloat = 15
        for i in 0..<5 {
            let ry = y + CGFloat(i)*rowH
            // Letter box A-E (12pt)
            fillRect(CGRect(x:lx, y:ry, width:12, height:rowH), subBlue)
            txt(abcdeLetters[i], CGRect(x:lx+1, y:ry+3, width:10, height:rowH-6),
                font:f7b, color:.white, align:.center)
            // Content (volle Breite bis rx)
            let cw = rx - lx - 12
            fillRect(CGRect(x:lx+12, y:ry, width:cw, height:rowH),
                     i%2==0 ? .white : UIColor(white:0.97,alpha:1))
            strokeRect(CGRect(x:lx+12, y:ry, width:cw, height:rowH))
            let isOB = abcdeRaw[i].isEmpty
            txt(abcdeVals[i], CGRect(x:lx+14, y:ry+3, width:cw-4, height:rowH-6),
                font: isOB ? UIFont.italicSystemFont(ofSize: 7) : f7,
                color: abcdeColors[i])
        }
        y += CGFloat(5)*rowH

        // ── SECTION 3 ──────────────────────────────────────
        secHeader("3. Befunde", x:lx, y:y, w:rx-lx)
        y += 11

        // Sub-headers for columns
        let bW1 = c1 - lx                     // messwerte
        let bW2 = (c2 - c1) * 0.50            // A+B Atmung
        let bW3 = (c2 - c1) * 0.50            // C Cirkulation
        let bW4 = (rx - c2) * 0.55            // D Neurologie
        let bW5 = (rx - c2) * 0.45            // E/Haut

        subHeader("Messwerte", x:lx, y:y, w:bW1)
        let mvLbl: CGFloat = 42
        let mvAnk: CGFloat = (bW1 - mvLbl) / 2
        let mvUeb: CGFloat = bW1 - mvLbl - mvAnk
        txt("Ankunft",  CGRect(x:lx+mvLbl,       y:y+2.5, width:mvAnk-2, height:4.5),
            font:f5, color:.white, align:.center)
        txt("Übergabe", CGRect(x:lx+mvLbl+mvAnk, y:y+2.5, width:mvUeb-2, height:4.5),
            font:f5, color:.white, align:.center)
        subHeader("A+B Atmung", x:lx+bW1, y:y, w:bW2)
        subHeader("C Cirkulation+EKG", x:lx+bW1+bW2, y:y, w:bW3)
        subHeader("D Neurologie", x:c2, y:y, w:bW4)
        subHeader("E/Haut", x:c2+bW4, y:y, w:bW5)
        y += 9.5

        // Messwerte: Ankunft | Übergabe
        let u = p.uebergabeMesswerte
        let mvH: CGFloat = 11
        let mvItems: [(String, String, String)] = [
            ("RR syst.",  p.circulation.blutdruckSystolisch.map  { "\($0)" } ?? "", u.rrSys),
            ("RR diast.", p.circulation.blutdruckDiastolisch.map { "\($0)" } ?? "", u.rrDia),
            ("HF (/min)", p.circulation.puls.map                 { "\($0)" } ?? "", u.hf),
            ("SpO₂ (%)",  p.breathing.spo2.map                   { "\($0)" } ?? "", u.spo2),
            ("AF (/min)", p.breathing.atemFrequenz.map            { "\($0)" } ?? "", u.af),
            ("BZ",        p.disability.blutzucker.map { String(format:"%.1f",$0) } ?? "", u.bz),
            ("Temp (°C)", p.exposure.temperatur.map   { String(format:"%.1f",$0) } ?? "", u.temp),
        ]
        let mvColY = y
        for (i,(label,ankVal,uebVal)) in mvItems.enumerated() {
            let ry = mvColY + CGFloat(i)*mvH
            let hl = (label == "RR syst." || label == "RR diast.")
            let bg: UIColor = i%2 == 0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:lx,y:ry,width:bW1,height:mvH), hl ? hlYellow : bg)
            strokeRect(CGRect(x:lx,y:ry,width:bW1,height:mvH))
            vline(lx+mvLbl, ry, mvH)
            vline(lx+mvLbl+mvAnk, ry, mvH)
            txt(label,  CGRect(x:lx+1.5,              y:ry+2, width:mvLbl-3,  height:mvH-4), font:f6, color:.darkGray)
            txt(ankVal, CGRect(x:lx+mvLbl+1.5,        y:ry+2, width:mvAnk-3,  height:mvH-4), font:f7b, align:.center)
            txt(uebVal, CGRect(x:lx+mvLbl+mvAnk+1.5,  y:ry+2, width:mvUeb-3,  height:mvH-4), font:f7b, align:.center)
        }

        // A+B Atmung checkboxes
        let atAx = lx + bW1
        let atItems: [(String,Bool)] = [
            ("unauffällig", p.breathing.status == .nicht_kritisch),
            ("Dyspnoe", p.breathing.dyspnoe),
            ("Atemweg frei", p.airway.freiheit),
            ("Verlegt", p.airway.verlegung),
            ("Guedel", p.airway.oropharyngealtubus),
            ("Wendl", p.airway.nasopharyngealtubus),
            ("iGel/EGA", p.massnahmen.supraglottisch),
            ("Intubiert", p.airway.intubiert),
            ("Konikotomie", p.airway.konikotomie),
            ("O₂-Gabe", p.breathing.sauerstoffGabe),
            ("Beatmung", p.breathing.beatmung),
        ]
        fillRect(CGRect(x:atAx,y:mvColY,width:bW2,height:CGFloat(atItems.count)*mvH), .white)
        strokeRect(CGRect(x:atAx,y:mvColY,width:bW2,height:CGFloat(atItems.count)*mvH))
        for (i,(label,checked)) in atItems.enumerated() {
            let ry = mvColY + CGFloat(i)*mvH
            if i%2 == 1 { fillRect(CGRect(x:atAx,y:ry,width:bW2,height:mvH), UIColor(white:0.97,alpha:1)) }
            cb(label, checked, x:atAx+2, y:ry+2, bs:7, lw:bW2-12)
        }

        // C Cirkulation
        let ciAx = atAx + bW2
        let ciItems: [(String,Bool)] = [
            ("unauffällig", p.circulation.status == .nicht_kritisch),
            ("Pulslosigkeit", p.circulation.pulslosigkeit),
            ("Blutung", p.circulation.blutung),
            ("IV-Zugang", p.circulation.ivZugang),
            ("EKG", p.circulation.ekg),
            ("Sinusrhythmus", false),
            ("Tachykardie", false),
            ("Bradykardie", false),
            ("AV-Block", false),
            ("Kammerflattern", false),
            ("Asystolie", p.reanimationAktiv && p.reanimation.initialRhythmus == .asystolie),
        ]
        fillRect(CGRect(x:ciAx,y:mvColY,width:bW3,height:CGFloat(ciItems.count)*mvH), .white)
        strokeRect(CGRect(x:ciAx,y:mvColY,width:bW3,height:CGFloat(ciItems.count)*mvH))
        for (i,(label,checked)) in ciItems.enumerated() {
            let ry = mvColY + CGFloat(i)*mvH
            if i%2 == 1 { fillRect(CGRect(x:ciAx,y:ry,width:bW3,height:mvH), UIColor(white:0.97,alpha:1)) }
            cb(label, checked, x:ciAx+2, y:ry+2, bs:7, lw:bW3-12)
        }

        // D Neurologie / GCS
        let neAx = c2
        let gcs = p.disability
        var neItems: [(String,String)] = [
            ("Bewusstsein", p.patientDaten.ansprechbar ? "ansprechbar" : "nicht ansprechbar"),
            ("GCS gesamt", "\(gcs.gcsGesamt)/15"),
            ("Augen (E)", "\(gcs.gcsAugen)"),
            ("Verbal (V)", "\(gcs.gcsVerbal)"),
            ("Motorik (M)", "\(gcs.gcsMotor)"),
            ("Pupille re", gcs.pupillenRechts),
            ("Pupille li", gcs.pupillenLinks),
            ("Lichtreaktion", gcs.pupillenReaktion ? "+" : "–"),
            ("Schmerz NRS", "\(gcs.schmerz)/10"),
        ]
        if gcs.befastAktiv {
            let tf = DateFormatter()
            tf.dateFormat = "HH:mm"
            let zeitStr: String = {
                if gcs.befastZeitUnbekannt { return "unbekannt" }
                if let d = gcs.befastSymptombeginn { return tf.string(from: d) }
                return "—"
            }()
            neItems += [
                ("BEFAST B", gcs.befastBalance ? "+" : "–"),
                ("BEFAST E", gcs.befastEyes    ? "+" : "–"),
                ("BEFAST F", gcs.befastFace    ? "+" : "–"),
                ("BEFAST A", gcs.befastArm     ? "+" : "–"),
                ("BEFAST S", gcs.befastSpeech  ? "+" : "–"),
                ("BEFAST T", zeitStr),
            ]
        }
        for (i,(label,value)) in neItems.enumerated() {
            let ry = mvColY + CGFloat(i)*mvH
            let hl2 = label == "GCS gesamt"
            let bg2: UIColor = hl2 ? hlYellow : (i%2==0 ? .white : UIColor(white:0.97,alpha:1))
            fillRect(CGRect(x:neAx,y:ry,width:bW4,height:mvH), bg2)
            strokeRect(CGRect(x:neAx,y:ry,width:bW4,height:mvH))
            vline(neAx+42, ry, mvH)
            txt(label, CGRect(x:neAx+1.5,y:ry+2,width:40,height:mvH-4), font:f6, color:.darkGray)
            txt(value, CGRect(x:neAx+44,y:ry+2,width:bW4-46,height:mvH-4), font:f7b)
        }

        // E / Haut
        let haAx = c2 + bW4
        let haItems: [(String,Bool)] = [
            ("unauffällig", p.exposure.status == .nicht_kritisch),
            ("Trauma", p.exposure.trauma),
            ("Ödeme", p.exposure.oedeme),
            ("Verletzt", !p.exposure.verletzungen.isEmpty),
            ("Bewusstlos", p.exposure.bewusstseinsverlust),
            ("Zyanose", p.breathing.zyanose),
            ("Blass", false),
            ("Gerötet", false),
            ("Ikterisch", false),
        ]
        fillRect(CGRect(x:haAx,y:mvColY,width:bW5,height:CGFloat(haItems.count)*mvH), .white)
        strokeRect(CGRect(x:haAx,y:mvColY,width:bW5,height:CGFloat(haItems.count)*mvH))
        for (i,(label,checked)) in haItems.enumerated() {
            let ry = mvColY + CGFloat(i)*mvH
            if i%2 == 1 { fillRect(CGRect(x:haAx,y:ry,width:bW5,height:mvH), UIColor(white:0.97,alpha:1)) }
            cb(label, checked, x:haAx+2, y:ry+2, bs:7, lw:bW5-12)
        }

        y = mvColY + CGFloat(max(mvItems.count, atItems.count, ciItems.count, neItems.count, haItems.count))*mvH + 2

        // Hautfarbe / Verletzungen (Temp ist bereits in Messwerte)
        field("Hautfarbe", p.exposure.hautfarbe, x:lx, y:y, w:(rx-lx)/2, h:11, lw:42)
        field("Verletzungen", p.exposure.verletzungen, x:lx+(rx-lx)/2, y:y, w:(rx-lx)/2, h:11, lw:45)
        y += 11

        // ── SECTION 4 ──────────────────────────────────────
        secHeader("4. Diagnose", x:lx, y:y, w:rx-lx)
        y += 11

        // Leitsymptom (full width)
        let leitsymptomText = p.diagnose.leitsymptom.isEmpty
            ? (p.diagnose.verdachtsdiagnosen.first { $0.wahrscheinlichkeit == .fuehrend }?.name ?? "")
            : p.diagnose.leitsymptom
        field("Leitsymptom / Diagnose", leitsymptomText,
              x:lx, y:y, w:rx-lx, h:13, lw:85, hl:true)
        y += 13

        // Verdachtsdiagnosen
        if !p.diagnose.verdachtsdiagnosen.isEmpty {
            let diagText = DiagnoseWahrscheinlichkeit.allCases
                .flatMap { stufe in p.diagnose.verdachtsdiagnosen.filter { $0.wahrscheinlichkeit == stufe }.map { "\($0.name) (\(stufe.rawValue))" } }
                .joined(separator: " · ")
            field("Verdachtsdiagnosen", diagText, x:lx, y:y, w:rx-lx, h:11, lw:85)
            y += 11
        }

        // 4.1 Three-column erkrankung layout
        let dW = (rx-lx)/3
        let d1x = lx; let d2x = lx+dW; let d3x = lx+dW*2
        subHeader("ZNS / Neurologie", x:d1x, y:y, w:dW)
        subHeader("Herz-Kreislauf", x:d2x, y:y, w:dW)
        subHeader("Infektionen / Sonstiges", x:d3x, y:y, w:dW)
        y += 9.5

        let col1Items: [(String,Bool)] = [
            ("Akutes neurol. Defizit", p.diagnose.znsAkutNeuro),
            ("SAB / ICB", p.diagnose.znsSab),
            ("Status Epilepticus", p.diagnose.znsEpilepsie),
            ("Fieberkrampf", p.diagnose.znsFieberkrampf),
            ("Transplantation", p.diagnose.znsTransplantat),
        ]
        let col1b: [(String,Bool)] = [
            ("Asthma", p.diagnose.atmungAsthma),
            ("Exazerbierte COPD", p.diagnose.atmungExazerbiert),
            ("Pneumonie", p.diagnose.atmungPneumonie),
            ("LTB", p.diagnose.atmungLtb),
            ("Epiglottitis", p.diagnose.atmungEpiglottitis),
        ]

        let col2Items: [(String,Bool)] = [
            ("ACS", p.diagnose.herzAcs),
            ("STEMI", p.diagnose.herzStemi),
            ("VW (Vorderwand)", p.diagnose.herzVW),
            ("HW (Hinterwand)", p.diagnose.herzHW),
            ("PM/ICD-Fehlfunktion", p.diagnose.herzPmFehlfunktion),
            ("Rhythmusstörung", p.diagnose.herzRhythmus),
            ("Hypertensiver Notfall", p.diagnose.herzHypertonerNotfall),
            ("Aortenaneurysma", p.diagnose.herzAortenaneurysma),
            ("Hypotonie", p.diagnose.herzHypotonie),
            ("Dekomp. Herzinsuff.", p.diagnose.herzDekomp),
            ("Synkope", p.diagnose.herzSynkope),
            ("Thrombose / Embolie", p.diagnose.herzThromboseEmbolie),
            ("Schock unkl. Genese", p.diagnose.herzSchockUnklarGenese),
            ("Orthostatisch", p.diagnose.herzOrthostatisch),
            ("Unkl. Thoraxschmerz", p.diagnose.herzUnklarerThoraxschmerz),
        ]

        let col3Items: [(String,Bool)] = [
            ("HIV", p.diagnose.infektHiv),
            ("Hochkontagiös/SARS", p.diagnose.infektHighToxSars),
            ("Gastrointestinal", p.diagnose.infektGastro),
            ("Anaphylaxie Gr 1/2", p.diagnose.infektAnaphylaxie12),
            ("SIDS", p.diagnose.infektSids),
            ("Intoxikation", p.diagnose.infektIntoxikation),
            ("Akute Lumbago", p.diagnose.infektAkuteLumbalgie),
            ("Palliative Situation", p.diagnose.infektPalliativ),
            ("Behandlungskompl.", p.diagnose.infektBehandlungKompl),
            ("Urologisch", p.diagnose.infektUrologisch),
        ]

        let cbH: CGFloat = 10
        let allCol1 = col1Items + col1b
        let maxRows = max(allCol1.count, col2Items.count, col3Items.count)

        for (i,(label,checked)) in allCol1.enumerated() {
            let ry = y + CGFloat(i)*cbH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:d1x,y:ry,width:dW,height:cbH), bg)
            strokeRect(CGRect(x:d1x,y:ry,width:dW,height:cbH))
            cb(label, checked, x:d1x+2, y:ry+1, bs:7, lw:dW-12)
        }
        for (i,(label,checked)) in col2Items.enumerated() {
            let ry = y + CGFloat(i)*cbH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:d2x,y:ry,width:dW,height:cbH), bg)
            strokeRect(CGRect(x:d2x,y:ry,width:dW,height:cbH))
            cb(label, checked, x:d2x+2, y:ry+1, bs:7, lw:dW-12)
        }
        for (i,(label,checked)) in col3Items.enumerated() {
            let ry = y + CGFloat(i)*cbH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:d3x,y:ry,width:dW,height:cbH), bg)
            strokeRect(CGRect(x:d3x,y:ry,width:dW,height:cbH))
            cb(label, checked, x:d3x+2, y:ry+1, bs:7, lw:dW-12)
        }
        y += CGFloat(maxRows)*cbH + 2

        // Psychiatrie + Gyn + Stoffwechsel + Abdomen
        subHeader("Psychiatrie", x:d1x, y:y, w:dW)
        subHeader("Gyn / Geburtshilfe", x:d2x, y:y, w:dW)
        subHeader("Stoffwechsel / Abdomen", x:d3x, y:y, w:dW)
        y += 9.5

        let psyItems: [(String,Bool)] = [
            ("Psych. Akutzustand", p.diagnose.psychAkut),
            ("Psych. Krise", p.diagnose.psychKrise),
            ("Manie / Depression", p.diagnose.psychManie),
            ("Intoxikation/Drogen", p.diagnose.psychIntoxikation),
            ("Entzug / Delir", p.diagnose.psychEntzug),
            ("Suizidal", p.diagnose.psychSuizidal),
        ]
        let gynItems: [(String,Bool)] = [
            ("Schwangersch. >35. SSW", p.diagnose.gynSchwangerschaft35),
            ("Geburt", p.diagnose.gynGeburt),
            ("Eklampsie", p.diagnose.gynEklampsie),
            ("Vaginale Blutung", p.diagnose.gynVaginalblutung),
            ("Extrauterine Gravidität", p.diagnose.gynSonstige),
        ]
        let stoffItems: [(String,Bool)] = [
            ("Exsikkose", p.diagnose.stoffExsikkose),
            ("Hypoglykämie", p.diagnose.stoffHypoglykämie),
            ("Hyperglykämie", p.diagnose.stoffHyperglykämie),
            ("Urämie / ARI", p.diagnose.stoffUremie),
            ("Diabetes", p.diagnose.stoffDia),
            ("Akutes Abdomen", p.diagnose.abdoAkutes),
            ("Kolik", p.diagnose.abdoKoliken),
            ("GIB oben", p.diagnose.abdoGibOben),
            ("GIB unten", p.diagnose.abdoGibUnten),
            ("Gallen-/Nierenstein", p.diagnose.abdoGalleNiere),
        ]
        let maxRows2 = max(psyItems.count, gynItems.count, stoffItems.count)
        for (i,(label,checked)) in psyItems.enumerated() {
            let ry = y + CGFloat(i)*cbH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:d1x,y:ry,width:dW,height:cbH), bg)
            strokeRect(CGRect(x:d1x,y:ry,width:dW,height:cbH))
            cb(label, checked, x:d1x+2, y:ry+1, bs:7, lw:dW-12)
        }
        for (i,(label,checked)) in gynItems.enumerated() {
            let ry = y + CGFloat(i)*cbH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:d2x,y:ry,width:dW,height:cbH), bg)
            strokeRect(CGRect(x:d2x,y:ry,width:dW,height:cbH))
            cb(label, checked, x:d2x+2, y:ry+1, bs:7, lw:dW-12)
        }
        for (i,(label,checked)) in stoffItems.enumerated() {
            let ry = y + CGFloat(i)*cbH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:d3x,y:ry,width:dW,height:cbH), bg)
            strokeRect(CGRect(x:d3x,y:ry,width:dW,height:cbH))
            cb(label, checked, x:d3x+2, y:ry+1, bs:7, lw:dW-12)
        }
        y += CGFloat(maxRows2)*cbH + 2

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

    private static func drawBodySilhouette(_ m: VerletzungsMatrix, rect: CGRect) {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        let sx = w / 60.0, sy = h / 130.0
        let cr = 1.5 * min(sx, sy)

        func rr(_ rx: CGFloat, _ ry: CGFloat, _ rw: CGFloat, _ rh: CGFloat) -> UIBezierPath {
            UIBezierPath(roundedRect: CGRect(x: x + rx*sx, y: y + ry*sy, width: rw*sx, height: rh*sy),
                         cornerRadius: cr)
        }
        func oval(_ rx: CGFloat, _ ry: CGFloat, _ rw: CGFloat, _ rh: CGFloat) -> UIBezierPath {
            UIBezierPath(ovalIn: CGRect(x: x + rx*sx, y: y + ry*sy, width: rw*sx, height: rh*sy))
        }
        func fill(_ path: UIBezierPath, _ grad: Verletzungsgrad) {
            gradColor(grad).setFill(); UIColor.darkGray.setStroke()
            path.lineWidth = 0.5; path.fill(); path.stroke()
        }

        fill(oval(18, 0, 24, 22),   higherGrad(m.schaedelHirn, m.gesicht))
        fill(rr(24, 22, 12,  7),    m.hws)
        fill(rr(12, 29, 36, 24),    m.thorax)
        fill(rr(12, 53, 36, 18),    m.abdomen)
        fill(rr(10, 71, 40, 13),    m.becken)
        fill(rr( 0, 29, 11, 38),    m.obereExtrem)
        fill(rr(49, 29, 11, 38),    m.obereExtrem)
        fill(rr(11, 84, 18, 46),    m.untereExtrem)
        fill(rr(31, 84, 18, 46),    m.untereExtrem)
        if m.bwsLws != .keine { fill(rr(12, 30, 3.5, 40), m.bwsLws) }
        if m.weichteile != .keine { fill(rr(55, 50, 4, 12), m.weichteile) }

        // Region labels (tiny)
        let lf = UIFont.systemFont(ofSize: 4.5)
        func lbl(_ s: String, _ rx: CGFloat, _ ry: CGFloat) {
            txt(s, CGRect(x: x+rx*sx, y: y+ry*sy, width: 24*sx, height: 6*sy), font:lf, color:.darkGray, align:.center)
        }
        lbl("Schädel", 18,  4);  lbl("Gesicht", 18, 11)
        lbl("HWS",    24, 23);   lbl("Thorax",  12, 38)
        lbl("Abdomen",12, 58);   lbl("Becken",  10, 75)
        lbl("OE",      0, 45);   lbl("OE",      49, 45)
        lbl("UE",     11,104);   lbl("UE",      31,104)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - PAGE 2  (Seiten 3+4 des Originals)
    // Sections: 4.2 Verletzungen · 6 Maßnahmen · 6.5 Medi · 7 Reani · 8 Ergebnis · 9 Übergabe
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

        var y: CGFloat = hh

        // ── SECTION 4.2 Verletzungen ──────────────────────
        let v2TotalW = (rx - lx) * 0.42
        let v2RW = (rx - lx) * 0.58
        let v2Rx = lx + v2TotalW
        let v2BodyW: CGFloat = 72          // silhouette column
        let v2TableX = lx + v2BodyW
        let v2TableW = v2TotalW - v2BodyW  // table column

        secHeader("4.2 Verletzungen", x:lx, y:y, w:v2TotalW)
        secHeader("Spezielle Traumen", x:v2Rx, y:y, w:v2RW)
        y += 11

        // Region table (right of silhouette)
        let regions: [(String, Verletzungsgrad)] = [
            ("Schädel-Hirn", p.diagnose.verletzungsMatrix.schaedelHirn),
            ("Gesicht",      p.diagnose.verletzungsMatrix.gesicht),
            ("HWS",          p.diagnose.verletzungsMatrix.hws),
            ("Thorax",       p.diagnose.verletzungsMatrix.thorax),
            ("Abdomen",      p.diagnose.verletzungsMatrix.abdomen),
            ("BWS / LWS",    p.diagnose.verletzungsMatrix.bwsLws),
            ("Becken",       p.diagnose.verletzungsMatrix.becken),
            ("Ob. Extrem.",  p.diagnose.verletzungsMatrix.obereExtrem),
            ("Un. Extrem.",  p.diagnose.verletzungsMatrix.untereExtrem),
            ("Weichteile",   p.diagnose.verletzungsMatrix.weichteile),
        ]
        let colW3 = v2TableW / 3
        fillRect(CGRect(x:v2TableX, y:y, width:v2TableW, height:9), vLightB)
        txt("Region",  CGRect(x:v2TableX+2,           y:y+1, width:colW3-4,   height:7), font:f6b, color:colBlue)
        txt("leicht",  CGRect(x:v2TableX+colW3+2,     y:y+1, width:colW3-4,   height:7), font:f6b, color:colBlue, align:.center)
        txt("schwer",  CGRect(x:v2TableX+colW3*2+2,   y:y+1, width:colW3-4,   height:7), font:f6b, color:colBlue, align:.center)
        strokeRect(CGRect(x:v2TableX, y:y, width:v2TableW, height:9))
        let regH: CGFloat = 10
        let regY0 = y + 9
        for (i,(region,grad)) in regions.enumerated() {
            let ry = regY0 + CGFloat(i)*regH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:v2TableX, y:ry, width:v2TableW, height:regH), bg)
            strokeRect(CGRect(x:v2TableX, y:ry, width:v2TableW, height:regH))
            vline(v2TableX+colW3, ry, regH); vline(v2TableX+colW3*2, ry, regH)
            txt(region, CGRect(x:v2TableX+2, y:ry+1.5, width:colW3-4, height:regH-3), font:f6)
            cb("", grad == .leicht, x:v2TableX+colW3+colW3/2-4, y:ry+1.5, bs:7, lw:0)
            cb("", grad == .schwer, x:v2TableX+colW3*2+colW3/2-4, y:ry+1.5, bs:7, lw:0)
        }

        // Verletzungsmuster + art
        let vmY = regY0 + CGFloat(regions.count)*regH
        field("Verletzungsmuster", p.diagnose.verletzungsMuster,
              x:v2TableX, y:vmY, w:v2TableW, h:10, lw:65)
        field("Verletzungsart", p.diagnose.verletzungsArt,
              x:v2TableX, y:vmY+10, w:v2TableW, h:10, lw:55)

        // Body silhouette (left of table)
        let silhH = 9 + CGFloat(regions.count)*regH + 20
        drawBodySilhouette(p.diagnose.verletzungsMatrix,
                           rect: CGRect(x:lx+2, y:y+1, width:v2BodyW-4, height:silhH-2))

        // Spezielle Traumen (right side)
        let spezItems: [(String,Bool)] = [
            ("Verbrennung / Verbrühung", p.diagnose.spezVerbrVerbrh),
            ("Tauchunfall", p.diagnose.spezTauchunfall),
            ("Elektrounfall", p.diagnose.spezElektrounfall),
            ("PKW / LKW-Insasse", p.diagnose.spezPkwLkw),
            ("Motorradfahrer", p.diagnose.spezMotorrad),
            ("Fahrradfahrer", p.diagnose.spezFahrrad),
            ("Fußgänger", p.diagnose.spezFussgaenger),
            ("Sturz > 3m Höhe", p.diagnose.spezSturzHoehe),
            ("And. Verkehrsunfall", p.diagnose.spezAndVerkehr),
            ("Maschinenunfall", p.diagnose.spezMaschine),
            ("Gewaltvergehen", p.diagnose.spezGewalt),
            ("Anderer Unfall", p.diagnose.spezAndererUnfall),
            ("Nicht bekannt", p.diagnose.verletzungNichtBekannt),
        ]
        let spezH: CGFloat = 10
        let spezY0 = y
        for (i,(label,checked)) in spezItems.enumerated() {
            let ry = spezY0 + CGFloat(i)*spezH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:v2Rx,y:ry,width:v2RW,height:spezH), bg)
            strokeRect(CGRect(x:v2Rx,y:ry,width:v2RW,height:spezH))
            cb(label, checked, x:v2Rx+2, y:ry+1.5, bs:7, lw:v2RW-12)
        }

        y = max(vmY + 20, spezY0 + CGFloat(spezItems.count)*spezH) + 2

        // ── SECTION 6 Maßnahmen ────────────────────────────
        secHeader("6. Maßnahmen", x:lx, y:y, w:rx-lx)
        y += 11

        let m6W = (rx-lx) / 3
        let m6x1 = lx; let m6x2 = lx+m6W; let m6x3 = lx+m6W*2

        // Sub-headers
        subHeader("Airway / Stabilisation", x:m6x1, y:y, w:m6W)
        subHeader("Kreislauf / Zugänge", x:m6x2, y:y, w:m6W)
        subHeader("Lagerung / Transport", x:m6x3, y:y, w:m6W)
        y += 9.5

        let maH: CGFloat = 9.5
        let maItems1: [(String,Bool)] = [
            ("Atemweg freimachen", p.massnahmen.atemwegFreimachen),
            ("Cervikalstütze/HWS", p.massnahmen.cervikalStuetze),
            ("Absaugung", p.massnahmen.absaugung),
            ("Sauerstoffgabe", p.massnahmen.sauerstoffgabe),
            ("Maskenbeatmung", p.massnahmen.maskenbeatmung),
            ("Mask.beat. unmöglich", p.massnahmen.maskenbeatmungUnmoeglich),
            ("EGA supraglottisch", p.massnahmen.supraglottisch),
            ("Atemweg erschwert", p.massnahmen.atemwegErschwert),
            ("CPAP", p.massnahmen.cpap),
            ("Heimlich (FK)", p.massnahmen.heimlich),
        ]
        let maItems2: [(String,Bool)] = [
            ("Peripher-venös", p.massnahmen.peripherVenoes),
            ("Defibrillation", p.massnahmen.defibrillation),
            ("Kardioversion", p.massnahmen.kardioversion),
            ("Intraossär", p.massnahmen.intraossaer),
            ("Tourniquet", p.massnahmen.tourniquet),
            ("Verband / Wundvers.", p.massnahmen.verband),
            ("Beckenschlinge", p.massnahmen.beckenschlinge),
            ("Wärmeerhalt", p.massnahmen.waermeerhalt),
            ("Kühlung", p.massnahmen.kuehlung),
            ("Krisenintervention", p.massnahmen.krisenintervention),
            ("Entbindung", p.massnahmen.entbindung),
        ]
        let maItems3: [(String,Bool)] = [
            ("OK-Hochlagerung", p.massnahmen.okHochlagerung),
            ("Flachlagerung", p.massnahmen.flachlagerung),
            ("Schocklagerung", p.massnahmen.schocklagerung),
            ("Herz-Tieflage", p.massnahmen.herzTieflage),
            ("Linksseitenlage", p.massnahmen.linksseitenlage),
            ("Sitzender Transport", p.massnahmen.sitzenderTransport),
            ("Vakuummatratze", p.massnahmen.vakuummatratze),
            ("Schaufeltrage", p.massnahmen.schaufeltrage),
            ("Extremit.schienung", p.massnahmen.extremitaetenschienung),
        ]
        let maY0 = y
        for (i,(label,checked)) in maItems1.enumerated() {
            let ry = maY0 + CGFloat(i)*maH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:m6x1,y:ry,width:m6W,height:maH), bg)
            strokeRect(CGRect(x:m6x1,y:ry,width:m6W,height:maH))
            cb(label, checked, x:m6x1+2, y:ry+1, bs:7, lw:m6W-12)
        }
        for (i,(label,checked)) in maItems2.enumerated() {
            let ry = maY0 + CGFloat(i)*maH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:m6x2,y:ry,width:m6W,height:maH), bg)
            strokeRect(CGRect(x:m6x2,y:ry,width:m6W,height:maH))
            cb(label, checked, x:m6x2+2, y:ry+1, bs:7, lw:m6W-12)
        }
        for (i,(label,checked)) in maItems3.enumerated() {
            let ry = maY0 + CGFloat(i)*maH
            let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:m6x3,y:ry,width:m6W,height:maH), bg)
            strokeRect(CGRect(x:m6x3,y:ry,width:m6W,height:maH))
            cb(label, checked, x:m6x3+2, y:ry+1, bs:7, lw:m6W-12)
        }
        y = maY0 + CGFloat(max(maItems1.count, maItems2.count, maItems3.count))*maH + 1

        // Monitoring row
        subHeader("Monitoring", x:m6x1, y:y, w:m6W)
        y += 9.5

        let monItems: [(String,Bool)] = [
            ("SpO₂", p.massnahmen.monSpo2),
            ("NIBP", p.massnahmen.monNibp),
            ("BZ", p.massnahmen.monBz),
            ("EKG / AED-Monitor", p.massnahmen.monEkg),
            ("Temperatur", p.massnahmen.monTemperatur),
        ]
        let maY1 = y
        let monColW = (rx - lx) / CGFloat(monItems.count)
        for (i,(label,checked)) in monItems.enumerated() {
            let col = lx + CGFloat(i) * monColW
            fillRect(CGRect(x:col,y:maY1,width:monColW,height:maH), i%2==0 ? .white : UIColor(white:0.97,alpha:1))
            strokeRect(CGRect(x:col,y:maY1,width:monColW,height:maH))
            cb(label, checked, x:col+2, y:maY1+1, bs:7, lw:monColW-12)
        }
        y = maY1 + maH + 2

        // Maßnahmen-Details (nicht-leere Textfelder)
        var maDetails: [(String,String)] = []
        if p.massnahmen.supraglottisch && !p.massnahmen.supraglottischTyp.isEmpty {
            let gr = p.massnahmen.supraglottischGr.isEmpty ? "" : " Gr.\(p.massnahmen.supraglottischGr)"
            maDetails.append(("EGA-Typ", "\(p.massnahmen.supraglottischTyp)\(gr)"))
        }
        if p.massnahmen.peripherVenoes && !p.massnahmen.peripherVenoesOrt.isEmpty {
            var iv = p.massnahmen.peripherVenoesOrt
            if !p.massnahmen.peripherVenoesGroesse.isEmpty { iv += " \(p.massnahmen.peripherVenoesGroesse)" }
            if p.massnahmen.peripherVenoesAnz > 1 { iv += " (\(p.massnahmen.peripherVenoesAnz)×)" }
            maDetails.append(("IV-Zugang", iv))
        }
        if p.massnahmen.tourniquet, let tz = p.massnahmen.tourniquetZeit {
            maDetails.append(("Tourniquet Zeit", t(tz)))
        }
        if p.massnahmen.defibrillation {
            maDetails.append(("Defi", "\(p.massnahmen.defiJoule) J × \(p.massnahmen.defiAnzahl)"))
        }
        if p.massnahmen.kardioversion {
            maDetails.append(("Kardioversion", "\(p.massnahmen.kardioversionJoule) J"))
        }
        if p.massnahmen.cpap && !p.massnahmen.cpapMbar.isEmpty {
            maDetails.append(("CPAP", "\(p.massnahmen.cpapMbar) mBar"))
        }
        if p.massnahmen.intraossaer && !p.massnahmen.intraossaerOrt.isEmpty {
            maDetails.append(("IO-Zugang", p.massnahmen.intraossaerOrt))
        }
        if !p.massnahmen.sauerstoffLitMin.isEmpty { maDetails.append(("O₂ (l/min)", p.massnahmen.sauerstoffLitMin)) }
        if !p.massnahmen.airwaySonstige.isEmpty  { maDetails.append(("Airway sonstige", p.massnahmen.airwaySonstige)) }
        if !p.massnahmen.circSonstige.isEmpty    { maDetails.append(("Kreislauf sonstige", p.massnahmen.circSonstige)) }
        if !p.massnahmen.weitereSonstige.isEmpty { maDetails.append(("Weitere sonstige", p.massnahmen.weitereSonstige)) }
        if !p.massnahmen.lagerungSonstige.isEmpty { maDetails.append(("Lagerung sonstige", p.massnahmen.lagerungSonstige)) }
        for (lbl, val) in maDetails {
            if y + 10 > pageSize.height - 15 { break }
            field(lbl, val, x:lx, y:y, w:rx-lx, h:10, lw:80)
            y += 10
        }

        // ── SECTION 6.5 Medikamente ────────────────────────
        if !p.medikamente.isEmpty {
            if y + 11 < pageSize.height - 15 {
                secHeader("6.5 Medikamente", x:lx, y:y, w:rx-lx)
                y += 11
            }
            let mTotW = rx - lx
            let mC: [CGFloat] = [mTotW*0.32, mTotW*0.14, mTotW*0.12, mTotW*0.20, mTotW*0.11, mTotW*0.11]
            let mHdr = ["Medikament","Dosis","Einheit","Applikationsweg","Zeit",""]
            if y + 9 < pageSize.height - 15 {
                fillRect(CGRect(x:lx,y:y,width:mTotW,height:9), vLightB)
                strokeRect(CGRect(x:lx,y:y,width:mTotW,height:9))
                var hx = lx
                for (i,h2) in mHdr.enumerated() {
                    txt(h2, CGRect(x:hx+1,y:y+1,width:mC[i]-2,height:7), font:f6b, color:colBlue)
                    hx += mC[i]
                }
                y += 9
            }
            let medH: CGFloat = 10
            for (idx, med) in p.medikamente.enumerated() {
                if y + medH > pageSize.height - 15 { break }
                let bg = idx%2==0 ? UIColor.white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:lx,y:y,width:mTotW,height:medH), bg)
                strokeRect(CGRect(x:lx,y:y,width:mTotW,height:medH))
                var mx2 = lx
                let vals2 = [med.name, med.dosis, med.einheit, med.route, t(med.zeit), ""]
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
        let r7W = (rx-lx) * 0.55
        let r8W = (rx-lx) * 0.45
        let r8x = lx + r7W

        secHeader("7. Reanimation / Tod", x:lx, y:y, w:r7W)
        secHeader("8. Ergebnis / NACA", x:r8x, y:y, w:r8W)
        y += 11

        // Reanimation content
        let rea = p.reanimation
        let r7H: CGFloat = 10
        let r7items: [(String,Bool)] = [
            ("Beginn CPR Ersthelfer", rea.erstHelfer),
            ("Vorab Telefon-Rea", rea.vorabTelefonRea),
            ("Rettungsdienst", !p.reanimationAktiv ? false : true),
            ("AED eingesetzt", rea.aed),
            ("DNR-Order", rea.dnrOrder),
            ("KH-Aufnahme v. ROSC", rea.khAufnahmeVorROSC),
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

        // NACA Score (right side)
        let nacaRows: [(String,Bool)] = NacaScore.allCases.map {
            ($0.beschreibung, p.notfallGeschehen.nacaScoreWert == $0)
        }
        let nacaH: CGFloat = r7H
        for (i,(label,active)) in nacaRows.enumerated() {
            let ry = r7y0 + CGFloat(i)*nacaH
            let bg: UIColor = active ? hlYellow : (i%2==0 ? .white : UIColor(white:0.97,alpha:1))
            fillRect(CGRect(x:r8x,y:ry,width:r8W,height:nacaH), bg)
            strokeRect(CGRect(x:r8x,y:ry,width:r8W,height:nacaH))
            cb(label, active, x:r8x+2, y:ry+1, bs:7, lw:r8W-12)
        }

        let maxR78 = max(r7items.count + (rea.defiAnzahl>0 ? 1 : 0), nacaRows.count)
        y = r7y0 + CGFloat(maxR78)*r7H + 2
        if !rea.freitext.isEmpty && y + 11 < pageSize.height - 15 {
            field("Reanimation – Notizen", rea.freitext, x:lx, y:y, w:rx-lx, h:11, lw:90)
            y += 11
        }

        // ── SECTION 9 Übergabe ────────────────────────────
        secHeader("9. Übergabe / Transportziel / Einsatzbesonderheiten", x:lx, y:y, w:rx-lx)
        y += 11

        // Transportziel Klinik
        let tzItems: [(String, Bool)] = [
            ("ZNA / Notaufnahme", p.ergebnis.transportzielZna),
            ("Stroke Unit",       p.ergebnis.transportzielStrokeUnit),
            ("Kath.-Labor",       p.ergebnis.transportzielKathLabor),
        ]
        let tzColW = (rx - lx) / CGFloat(tzItems.count + 1)
        fillRect(CGRect(x:lx, y:y, width:rx-lx, height:10), .white)
        strokeRect(CGRect(x:lx, y:y, width:rx-lx, height:10))
        for (i,(label,checked)) in tzItems.enumerated() {
            cb(label, checked, x:lx+CGFloat(i)*tzColW+2, y:y+1.5, bs:7, lw:tzColW-12)
        }
        if !p.ergebnis.transportzielSonstigesKH.isEmpty {
            field("Sonstiges KH", p.ergebnis.transportzielSonstigesKH,
                  x:lx+tzColW*3, y:y, w:tzColW, h:10, lw:50)
        }
        y += 10

        field("Übergabe an Rettungsmittel", p.uebergabeAn, x:lx, y:y, w:rx-lx, h:12, lw:100, hl:true)
        y += 12

        field("Zustand bei Übergabe", p.zustandBeiUebergabe, x:lx, y:y, w:rx-lx, h:11, lw:80)
        y += 11
        if !p.diagnose.diagnoseFreitext.isEmpty && y + 11 < pageSize.height - 15 {
            field("Diagnose-Freitext", p.diagnose.diagnoseFreitext, x:lx, y:y, w:rx-lx, h:11, lw:80)
            y += 11
        }
        if !p.ergebnis.anmerkungen.isEmpty && y + 11 < pageSize.height - 15 {
            field("Anmerkungen", p.ergebnis.anmerkungen, x:lx, y:y, w:rx-lx, h:11, lw:80)
            y += 11
        }

        let besatzungNames = [p.besatzung.sanitaeter1, p.besatzung.sanitaeter2,
                              p.besatzung.sanitaeter3, p.besatzung.sanitaeter4]
            .filter { !$0.isEmpty }.joined(separator: " · ")
        if !besatzungNames.isEmpty {
            field("Besatzung", besatzungNames, x:lx, y:y, w:rx-lx, h:11, lw:42)
            y += 11
        }

        // Einsatzbesonderheiten checkboxes
        let besItems: [(String,Bool)] = [
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
        let besColW = (rx-lx) / 3
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
        y += CGFloat(besPerCol)*besH + 2


        // ── Unterschrift ──────────────────────────────────
        let sigH: CGFloat = min(40, pageSize.height - y - 10)
        if sigH > 15 {
            fillRect(CGRect(x:lx,y:y,width:rx-lx,height:sigH), .white)
            strokeRect(CGRect(x:lx,y:y,width:rx-lx,height:sigH))
            let sigDate = DateFormatter()
            sigDate.dateFormat = "dd.MM.yyyy HH:mm"
            txt("Datum / Uhrzeit: \(sigDate.string(from: Date()))          Unterschrift: ________________________________________",
                CGRect(x:lx+4,y:y+sigH-12,width:rx-lx-8,height:10), font:f7)
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
