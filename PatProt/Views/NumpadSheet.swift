import SwiftUI

// MARK: - Numpad Mode

enum NumpadMode: Equatable {
    case integer(label: String, unit: String, maxDigits: Int = 3)
    case decimal(label: String, unit: String)
    case time(label: String)        // HH:MM — 4 Ziffern, Doppelpunkt auto
    case date(label: String)        // TT.MM.JJJJ — 8 Ziffern, Punkte auto
    case bloodPressure              // Zwei-Schritt: sys dann dia
}

// MARK: - NumpadSheet

struct NumpadSheet: View {
    let mode: NumpadMode
    let initial: String
    let onConfirm: (String) -> Void
    let initialSys: String
    let initialDia: String
    let onConfirmBP: ((String, String) -> Void)?

    @State private var digits: String = ""
    @State private var bpStep: BPStep = .sys
    @State private var sysDigits: String = ""
    @Environment(\.dismiss) private var dismiss

    enum BPStep { case sys, dia }

    // Initializer für alle Modi außer bloodPressure
    init(mode: NumpadMode, initial: String = "", onConfirm: @escaping (String) -> Void) {
        self.mode = mode
        self.initial = initial
        self.onConfirm = onConfirm
        self.initialSys = ""
        self.initialDia = ""
        self.onConfirmBP = nil
    }

    // Initializer für bloodPressure
    init(initialSys: String = "", initialDia: String = "",
         onConfirmBP: @escaping (String, String) -> Void) {
        self.mode = .bloodPressure
        self.initial = initialSys
        self.onConfirm = { _ in }
        self.initialSys = initialSys
        self.initialDia = initialDia
        self.onConfirmBP = onConfirmBP
    }

    // MARK: - Statische Formatierung (testbar)

    static func formatDisplay(digits: String, mode: NumpadMode) -> String {
        guard !digits.isEmpty else { return "—" }
        switch mode {
        case .integer, .decimal, .bloodPressure:
            return digits
        case .time:
            guard digits.count > 2 else { return digits }
            let h = String(digits.prefix(2))
            let m = String(digits.dropFirst(2))
            return "\(h):\(m)"
        case .date:
            var s = digits
            if s.count > 2 {
                s.insert(".", at: s.index(s.startIndex, offsetBy: 2))
            }
            if s.count > 5 {
                s.insert(".", at: s.index(s.startIndex, offsetBy: 5))
            }
            return s
        }
    }

    // MARK: - Computed

    private var title: String {
        switch mode {
        case .integer(let label, _, _): return label
        case .decimal(let label, _):    return label
        case .time(let label):          return label
        case .date(let label):          return label
        case .bloodPressure:            return bpStep == .sys ? "Blutdruck systolisch" : "Blutdruck diastolisch"
        }
    }

    private var unitText: String {
        switch mode {
        case .integer(_, let unit, _): return unit
        case .decimal(_, let unit):    return unit
        default: return ""
        }
    }

    private var maxDigits: Int {
        switch mode {
        case .integer(_, _, let m): return m
        case .decimal:              return 4
        case .time:                 return 4
        case .date:                 return 8
        case .bloodPressure:        return 3
        }
    }

    private var displayText: String {
        Self.formatDisplay(digits: digits, mode: mode)
    }

    // MARK: - Aktionen

    private func appendDigit(_ d: String) {
        let pure = digits.filter { $0.isNumber }
        if pure.count < maxDigits { digits += d }
    }

    private func appendDecimalPoint() {
        if !digits.contains(".") && !digits.isEmpty { digits += "." }
    }

    private func delete() {
        if !digits.isEmpty { digits.removeLast() }
    }

    private func confirm() {
        switch mode {
        case .bloodPressure:
            if bpStep == .sys {
                guard !digits.isEmpty else { return }
                sysDigits = digits
                digits = initialDia.filter { $0.isNumber }
                bpStep = .dia
            } else {
                guard !sysDigits.isEmpty, !digits.isEmpty else { return }
                onConfirmBP?(sysDigits, digits)
                dismiss()
            }
        case .time:
            let d = displayText
            guard d.count == 5 else { return }
            let parts = d.split(separator: ":")
            guard parts.count == 2,
                  let h = Int(parts[0]), let m = Int(parts[1]),
                  (0..<24).contains(h), (0..<60).contains(m) else { return }
            onConfirm(d)
            dismiss()
        default:
            guard !digits.isEmpty else { return }
            onConfirm(displayText)
            dismiss()
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.top, 24)

            if !unitText.isEmpty {
                Text(unitText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }

            Text(displayText)
                .font(.system(size: 52, weight: .light, design: .monospaced))
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

            Divider().padding(.bottom, 10)

            VStack(spacing: 10) {
                ForEach([[7, 8, 9], [4, 5, 6], [1, 2, 3]], id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { digit in
                            NumpadKey(label: "\(digit)") { appendDigit("\(digit)") }
                        }
                    }
                }

                HStack(spacing: 10) {
                    if case .decimal = mode {
                        NumpadKey(label: ".") { appendDecimalPoint() }
                    } else {
                        NumpadKey(label: "⌫", style: .secondary) { delete() }
                    }
                    NumpadKey(label: "0") { appendDigit("0") }
                    if case .decimal = mode {
                        NumpadKey(label: "⌫", style: .secondary) { delete() }
                    } else {
                        NumpadKey(label: "✓", style: .primary) { confirm() }
                    }
                }

                if case .decimal = mode {
                    HStack(spacing: 10) {
                        NumpadKey(label: "⌫", style: .secondary) { delete() }
                        NumpadKey(label: "Bestätigen", style: .primary, wide: true) { confirm() }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 24)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { dismiss() }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            switch mode {
            case .bloodPressure:
                digits = initialSys.filter { $0.isNumber }
            case .decimal:
                digits = initial.filter { $0.isNumber || $0 == "." }
            default:
                digits = initial.filter { $0.isNumber }
            }
        }
    }
}

// MARK: - NumpadKey

private struct NumpadKey: View {
    enum Style { case normal, primary, secondary }
    let label: String
    var style: Style = .normal
    var wide: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2.weight(.medium))
                .frame(maxWidth: wide ? .infinity : nil)
                .frame(width: wide ? nil : 100, height: 72)
                .background(background)
                .foregroundColor(style == .primary ? .white : .primary)
                .cornerRadius(14)
        }
    }

    private var background: Color {
        switch style {
        case .primary:   return Color("RDOrange")
        case .secondary: return Color(.systemGray4)
        case .normal:    return Color(.systemGray5)
        }
    }
}
