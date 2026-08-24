import SwiftUI

// MARK: - Body region model

enum BodyMapRegion: CaseIterable, Hashable {
    case schaedelHirn, gesicht, hws, thorax, abdomen, bwsLws, becken, obereExtrem, untereExtrem, weichteile

    var label: String {
        switch self {
        case .schaedelHirn: return "Schädel-Hirn"
        case .gesicht:      return "Gesicht"
        case .hws:          return "HWS"
        case .thorax:       return "Thorax"
        case .abdomen:      return "Abdomen"
        case .bwsLws:       return "BWS / LWS"
        case .becken:       return "Becken"
        case .obereExtrem:  return "Ob. Extremitäten"
        case .untereExtrem: return "Un. Extremitäten"
        case .weichteile:   return "Weichteile"
        }
    }

    // Normalized rect in 60×130 reference space
    var normRect: CGRect {
        switch self {
        case .schaedelHirn: return CGRect(x:18, y:0,  width:24, height:11)
        case .gesicht:      return CGRect(x:18, y:11, width:24, height:11)
        case .hws:          return CGRect(x:24, y:22, width:12, height:7)
        case .thorax:       return CGRect(x:12, y:29, width:36, height:24)
        case .abdomen:      return CGRect(x:12, y:53, width:36, height:18)
        case .bwsLws:       return CGRect(x:12, y:29, width:4,  height:42)
        case .becken:       return CGRect(x:10, y:71, width:40, height:13)
        case .obereExtrem:  return CGRect(x:0,  y:29, width:60, height:38) // both arms tap area
        case .untereExtrem: return CGRect(x:11, y:84, width:38, height:46) // both legs tap area
        case .weichteile:   return CGRect(x:55, y:50, width:5,  height:12)
        }
    }

    func tapFrame(in size: CGSize) -> CGRect {
        let sx = size.width / 60.0, sy = size.height / 130.0
        let n = normRect
        return CGRect(x: n.minX*sx, y: n.minY*sy, width: n.width*sx, height: n.height*sy)
    }

    func grad(from m: VerletzungsMatrix) -> Verletzungsgrad {
        switch self {
        case .schaedelHirn: return m.schaedelHirn
        case .gesicht:      return m.gesicht
        case .hws:          return m.hws
        case .thorax:       return m.thorax
        case .abdomen:      return m.abdomen
        case .bwsLws:       return m.bwsLws
        case .becken:       return m.becken
        case .obereExtrem:  return m.obereExtrem
        case .untereExtrem: return m.untereExtrem
        case .weichteile:   return m.weichteile
        }
    }

    func setGrad(_ g: Verletzungsgrad, on m: inout VerletzungsMatrix) {
        switch self {
        case .schaedelHirn: m.schaedelHirn = g
        case .gesicht:      m.gesicht = g
        case .hws:          m.hws = g
        case .thorax:       m.thorax = g
        case .abdomen:      m.abdomen = g
        case .bwsLws:       m.bwsLws = g
        case .becken:       m.becken = g
        case .obereExtrem:  m.obereExtrem = g
        case .untereExtrem: m.untereExtrem = g
        case .weichteile:   m.weichteile = g
        }
    }
}

// MARK: - Color helpers

private func gradColor(_ g: Verletzungsgrad) -> Color {
    switch g {
    case .keine:  return Color(.secondarySystemGroupedBackground)
    case .leicht: return Color(red: 1.0, green: 0.88, blue: 0.3)
    case .schwer: return Color(red: 1.0, green: 0.35, blue: 0.35)
    }
}

private func higherGrad(_ a: Verletzungsgrad, _ b: Verletzungsgrad) -> Verletzungsgrad {
    if a == .schwer || b == .schwer { return .schwer }
    if a == .leicht || b == .leicht { return .leicht }
    return .keine
}

// MARK: - Body figure canvas

private struct BodyFigure: View {
    let matrix: VerletzungsMatrix

    var body: some View {
        Canvas { ctx, size in
            let sx = size.width / 60.0
            let sy = size.height / 130.0
            let cr = 2.0 * min(sx, sy)

            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: x*sx, y: y*sy, width: w*sx, height: h*sy), cornerRadius: cr)
            }
            func e(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: x*sx, y: y*sy, width: w*sx, height: h*sy))
            }

            func draw(_ path: Path, _ grad: Verletzungsgrad) {
                ctx.fill(path, with: .color(gradColor(grad)))
                ctx.stroke(path, with: .color(.init(uiColor: .darkGray)), lineWidth: 0.8)
            }

            draw(e(18,  0, 24, 11), higherGrad(matrix.schaedelHirn, matrix.gesicht))
            draw(e(18, 11, 24, 11), higherGrad(matrix.schaedelHirn, matrix.gesicht))
            draw(r(24, 22, 12,  7), matrix.hws)
            draw(r(12, 29, 36, 24), matrix.thorax)
            draw(r(12, 53, 36, 18), matrix.abdomen)
            draw(r(10, 71, 40, 13), matrix.becken)
            draw(r( 0, 29, 11, 38), matrix.obereExtrem)
            draw(r(49, 29, 11, 38), matrix.obereExtrem)
            draw(r(11, 84, 18, 46), matrix.untereExtrem)
            draw(r(31, 84, 18, 46), matrix.untereExtrem)
            if matrix.bwsLws   != .keine { draw(r(12, 30,  4, 40), matrix.bwsLws) }
            if matrix.weichteile != .keine { draw(r(55, 50,  4, 12), matrix.weichteile) }
        }
    }
}

// MARK: - BodyMapView

struct BodyMapView: View {
    @Binding var matrix: VerletzungsMatrix

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Tippe auf eine Körperregion, um den Verletzungsgrad zu ändern.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                HStack(alignment: .top, spacing: 24) {
                    figureTapArea
                        .frame(width: 150, height: 260)
                        .padding(.leading)

                    VStack(alignment: .leading, spacing: 10) {
                        legendSection
                        Divider()
                        activeRegionsSection
                    }
                    .padding(.trailing)
                }

                regionList
                    .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Körperkarte")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Body figure with tap overlays

    private var figureTapArea: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                BodyFigure(matrix: matrix)

                ForEach(BodyMapRegion.allCases, id: \.self) { region in
                    let frame = region.tapFrame(in: geo.size)
                    Color.clear
                        .frame(width: frame.width, height: frame.height)
                        .offset(x: frame.minX, y: frame.minY)
                        .contentShape(Rectangle())
                        .onTapGesture { cycle(region) }
                }
            }
        }
    }

    // MARK: Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Legende").font(.caption.bold())
            legendRow("Keine Verletzung", grad: .keine)
            legendRow("Leicht", grad: .leicht)
            legendRow("Schwer", grad: .schwer)
        }
    }

    private func legendRow(_ label: String, grad: Verletzungsgrad) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(gradColor(grad))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.secondary.opacity(0.4), lineWidth: 0.5))
                .frame(width: 22, height: 14)
            Text(label).font(.caption)
        }
    }

    // MARK: Active regions summary

    private var activeRegionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Befunde").font(.caption.bold())
            let active = BodyMapRegion.allCases.filter { $0.grad(from: matrix) != .keine }
            if active.isEmpty {
                Text("–").font(.caption).foregroundColor(.secondary)
            } else {
                ForEach(active, id: \.self) { r in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(gradColor(r.grad(from: matrix)))
                            .frame(width: 8, height: 8)
                        Text(r.label).font(.caption)
                    }
                }
            }
        }
    }

    // MARK: Region list (stepper-style)

    private var regionList: some View {
        VStack(spacing: 1) {
            ForEach(BodyMapRegion.allCases, id: \.self) { region in
                let grad = region.grad(from: matrix)
                HStack {
                    Text(region.label)
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach([Verletzungsgrad.keine, .leicht, .schwer], id: \.self) { g in
                            Button {
                                region.setGrad(g, on: &matrix)
                            } label: {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(gradColor(g))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(grad == g ? Color.primary : Color.secondary.opacity(0.3),
                                                    lineWidth: grad == g ? 1.5 : 0.5)
                                    )
                                    .frame(width: 28, height: 22)
                                    .overlay(
                                        Text(g == .keine ? "–" : g.rawValue.prefix(1))
                                            .font(.caption2.bold())
                                            .foregroundColor(grad == g ? .primary : .secondary)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .cornerRadius(12)
    }

    // MARK: Helper

    private func cycle(_ region: BodyMapRegion) {
        let next: Verletzungsgrad
        switch region.grad(from: matrix) {
        case .keine:  next = .leicht
        case .leicht: next = .schwer
        case .schwer: next = .keine
        }
        region.setGrad(next, on: &matrix)
    }
}
