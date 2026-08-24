//
//  SAMPLERView.swift
//  PatProt
//
//  Created by Luke Schulz on 07.05.26.
//


import SwiftUI

// MARK: - SAMPLER

struct SAMPLERView: View {
    @Binding var befund: SAMPLERBefund
    @Binding var medikamentFotos: [FotoEintrag]
    var onZurueck: () -> Void

    @State private var zeigeBMPScanner = false
    @State private var scanFehler: String? = nil

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("S — Symptome").font(.subheadline.bold())
                    Text("Hauptbeschwerde des Patienten").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $befund.symptome).frame(minHeight: 70)
                    Text("→ PDF S. 1 · SAMPLER · S").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("A — Allergien").font(.subheadline.bold())
                    Text("Bekannte Allergien und Unverträglichkeiten").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.allergienUnbekannt)
                        .onChange(of: befund.allergienUnbekannt) { _, isUnknown in
                            if isUnknown { befund.allergien = "" }
                        }
                    if !befund.allergienUnbekannt {
                        TextEditor(text: $befund.allergien).frame(minHeight: 60)
                    }
                    Text("→ PDF S. 1 · SAMPLER · A").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("M — Medikamente").font(.subheadline.bold())
                    Text("Aktuelle Medikation (Text und/oder Foto)").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.medikamenteUnbekannt)
                        .onChange(of: befund.medikamenteUnbekannt) { _, isUnknown in
                            if isUnknown { befund.medikamente = "" }
                        }
                    if !befund.medikamenteUnbekannt {
                        TextField("z.B. Metoprolol 50mg, ASS 100mg", text: $befund.medikamente, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    if let fehler = scanFehler {
                        Text(fehler).font(.caption).foregroundColor(.red)
                    }
                    // TODO: BMP-QR-Scan-Feature (BMPScannerSheet / BMPParser) ist noch nicht
                    // implementiert – auskommentiert, um den Build für den TestFlight-Upload
                    // zu entsperren. Vor dem Wiederaktivieren erst BMPScannerSheet und
                    // BMPParser fertig implementieren (analog zu KVKarteScanView / KVKarteParser).
                    //
                    // Button {
                    //     zeigeBMPScanner = true
                    // } label: {
                    //     Label("Medikationsplan QR scannen", systemImage: "qrcode.viewfinder")
                    //         .font(.subheadline)
                    // }
                    // .sheet(isPresented: $zeigeBMPScanner) {
                    //     BMPScannerSheet { payload in
                    //         if let text = BMPParser.medikamenteText(payload) {
                    //             befund.medikamente = text
                    //             scanFehler = nil
                    //         } else {
                    //             scanFehler = "Kein gültiger BMP-Medikationsplan erkannt."
                    //         }
                    //     }
                    // }
                    Text("→ PDF S. 1 · SAMPLER · M").font(.caption2).foregroundColor(.secondary)
                    Divider()
                    Text("Medikamentenplan als Foto").font(.caption).foregroundColor(.secondary)
                    MedikamentFotoSektion(fotos: $medikamentFotos)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("P — Patientenvorgeschichte").font(.subheadline.bold())
                    Text("Relevante Vorerkrankungen und Operationen").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.patientenVorgeschichteUnbekannt)
                        .onChange(of: befund.patientenVorgeschichteUnbekannt) { _, isUnknown in
                            if isUnknown { befund.patientenVorgeschichte = "" }
                        }
                    if !befund.patientenVorgeschichteUnbekannt {
                        TextEditor(text: $befund.patientenVorgeschichte).frame(minHeight: 70)
                    }
                    Text("→ PDF S. 1 · SAMPLER · P").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                SamplerLRow(
                    titel: "L — Letzte Mahlzeit",
                    placeholder: "z.B. Brot und Kaffee",
                    text: $befund.letztesMahl,
                    zeit: $befund.letztesMahlZeit,
                    unbekannt: $befund.letztesMahlUnbekannt
                )
                SamplerLRow(
                    titel: "L — Letzter Stuhlgang",
                    placeholder: "Freitext",
                    text: $befund.letzterStuhlgang,
                    zeit: $befund.letzterStuhlgangZeit,
                    unbekannt: $befund.letzterStuhlgangUnbekannt
                )
                SamplerLRow(
                    titel: "L — Letzte Regelblutung",
                    placeholder: "Freitext",
                    text: $befund.letzteRegelblutung,
                    zeit: $befund.letzteRegelblutungZeit,
                    unbekannt: $befund.letzteRegelblutungUnbekannt,
                    nurDatum: true
                )
                Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("E — Ereignis").font(.subheadline.bold())
                    Text("Was hat zum Notfall geführt?").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.ereignisUnbekannt)
                        .onChange(of: befund.ereignisUnbekannt) { _, isUnknown in
                            if isUnknown { befund.ereignis = "" }
                        }
                    if !befund.ereignisUnbekannt {
                        TextEditor(text: $befund.ereignis).frame(minHeight: 70)
                    }
                    Text("→ PDF S. 1 · SAMPLER · E").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("R — Risikofaktoren").font(.subheadline.bold())
                    Text("Bekannte Risikofaktoren").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.risikofaktorenUnbekannt)
                        .onChange(of: befund.risikofaktorenUnbekannt) { _, isUnknown in
                            if isUnknown { befund.risikofaktoren = "" }
                        }
                    if !befund.risikofaktorenUnbekannt {
                        TextEditor(text: $befund.risikofaktoren).frame(minHeight: 60)
                    }
                    Text("→ PDF S. 1 · SAMPLER · R").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                Picker("Status", selection: $befund.schwangerschaftStatus) {
                    Text("Unbekannt").tag("Unbekannt")
                    Text("Nein").tag("Nein")
                    Text("Ja").tag("Ja")
                }
                .pickerStyle(.segmented)
                if befund.schwangerschaftStatus == "Ja" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(befund.schwangerschaftSSW == 0 ? "SSW unbekannt" : "SSW \(befund.schwangerschaftSSW)")
                            .foregroundStyle(.secondary)
                        Slider(value: Binding(
                            get: { Double(befund.schwangerschaftSSW) },
                            set: { befund.schwangerschaftSSW = Int($0.rounded()) }
                        ), in: 0...42, step: 1)
                    }
                }
            } header: { Label("Schwangerschaft", systemImage: "figure.and.child.holdinghands") }
        }
        .keyboardDismissToolbar()
        .navigationTitle("SAMPLER")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - SAMPLER L Row (kompaktes Hilfselement)

private struct SamplerLRow: View {
    let titel: String
    let placeholder: String
    @Binding var text: String
    @Binding var zeit: Date?
    @Binding var unbekannt: Bool
    var nurDatum: Bool = false   // true = Regelblutung (Datum ohne Uhrzeit)

    @State private var zeigeNumpad = false

    private var zeitFormatiert: String {
        guard let d = zeit else { return "" }
        let f = DateFormatter()
        f.dateFormat = nurDatum ? "dd.MM.yyyy" : "HH:mm"
        return f.string(from: d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(titel).font(.subheadline.bold())
                Spacer()
                Toggle("Unbek.", isOn: $unbekannt)
                    .labelsHidden()
                    .onChange(of: unbekannt) { _, isUnknown in
                        if isUnknown { zeit = nil }
                    }
                Text("Unbekannt").font(.caption).foregroundColor(.secondary)
            }
            if !unbekannt {
                HStack(spacing: 8) {
                    TextField(placeholder, text: $text)
                        .font(.subheadline)
                    Spacer()
                    // Uhrzeit/Datum Anzeige – immer tippen um zu setzen
                    HStack(spacing: 6) {
                        if nurDatum {
                            // Datum: kompakter DatePicker ohne Gate
                            DatePicker("", selection: Binding(
                                get: { zeit ?? Date() },
                                set: { zeit = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                            .frame(width: 120)
                            .onAppear { if zeit == nil { /* kein Auto-Set */ } }
                        } else {
                            // Uhrzeit: NumpadSheet wie ZeitFeld
                            Text(zeitFormatiert.isEmpty ? "--:--" : zeitFormatiert)
                                .foregroundStyle(zeit == nil ? .secondary : .primary)
                                .monospacedDigit()
                                .frame(width: 44, alignment: .trailing)
                                .contentShape(Rectangle())
                                .onTapGesture { zeigeNumpad = true }
                            Button("Jetzt") {
                                let now = Date()
                                let cal = Calendar.current
                                var c = cal.dateComponents([.year, .month, .day], from: Date())
                                c.hour   = cal.component(.hour,   from: now)
                                c.minute = cal.component(.minute, from: now)
                                zeit = cal.date(from: c)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color("RDOrange"))
                            .controlSize(.small)
                        }
                        if zeit != nil {
                            Button {
                                zeit = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .sheet(isPresented: $zeigeNumpad) {
            NumpadSheet(mode: .time(label: titel), initial: zeitFormatiert) { timeStr in
                guard timeStr.count == 5 else { return }
                let parts = timeStr.split(separator: ":")
                guard parts.count == 2,
                      let h = Int(parts[0]), let m = Int(parts[1]) else { return }
                var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                c.hour = h; c.minute = m
                zeit = Calendar.current.date(from: c)
            }
        }
    }
}

// MARK: - Reanimation

struct ReanimationView: View {
    @Binding var protokoll: ReanimationsProtokoll
    var onWeiter: () -> Void

    var body: some View {
        Form {
            // EREIGNIS
            Section {
                Toggle("Kollaps-Uhrzeit unbekannt", isOn: $protokoll.kollapsZeitUnbekannt)
                if !protokoll.kollapsZeitUnbekannt {
                    ZeitFeld(label: "Kollaps-Uhrzeit", datum: $protokoll.kollapsZeit)
                }
                Toggle("Ersthelfer anwesend", isOn: $protokoll.erstHelfer)
                if protokoll.erstHelfer {
                    Toggle("AED durch Ersthelfer", isOn: $protokoll.aed)
                    Toggle("Start Ersthelfer-CPR unbekannt", isOn: $protokoll.startErsthelferUnbekannt)
                    if !protokoll.startErsthelferUnbekannt {
                        ZeitFeld(label: "Start Ersthelfer-CPR", datum: $protokoll.startErsthelferCPR)
                    }
                }
                Toggle("Vorab Telefon-Reanimation", isOn: $protokoll.vorabTelefonRea)
                Toggle("DNR-Order vorhanden", isOn: $protokoll.dnrOrder)
            } header: { Label("Ereignis", systemImage: "clock.badge.exclamationmark") }

            // INITIAL-RHYTHMUS
            Section {
                Picker("Initialrhythmus", selection: $protokoll.initialRhythmus) {
                    ForEach(InitialRhythmus.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.inline)
            } header: { Label("Initialrhythmus", systemImage: "waveform.path.ecg") }

            // CPR-ZEITEN
            Section {
                Toggle("Start RD-CPR unbekannt", isOn: $protokoll.startRDUnbekannt)
                if !protokoll.startRDUnbekannt {
                    ZeitFeld(label: "Start Rettungsdienst", datum: $protokoll.startRettungsdienst)
                }
                ZeitFeld(label: "Ende Rettungsdienst", datum: $protokoll.endeRettungsdienst)
            } header: { Label("CPR-Zeiten", systemImage: "repeat.circle") }

            // DEFIBRILLATION
            Section {
                Stepper("Anzahl: \(protokoll.defiAnzahl)", value: $protokoll.defiAnzahl, in: 0...30)
                if protokoll.defiAnzahl > 0 {
                    HStack {
                        Text("Joule")
                        TextField("z.B. 200", value: $protokoll.defiJoule, format: .number)
                            .keyboardType(.numberPad)
                    }
                }
            } header: { Label("Defibrillation", systemImage: "bolt.heart") }

            // OUTCOME
            Section {
                Picker("Outcome", selection: $protokoll.outcome) {
                    ForEach(ReaniOutcome.allCases, id: \.self) { o in
                        Text(o.rawValue).tag(o)
                    }
                }
                .pickerStyle(.inline)

                if protokoll.outcome == .rosc {
                    ZeitFeld(label: "ROSC-Zeitpunkt", datum: $protokoll.roscZeit)
                    Toggle("KH-Aufnahme vor ROSC", isOn: $protokoll.khAufnahmeVorROSC)
                }

                if protokoll.outcome == .transportiert {
                    Toggle("Laufende Reanimation bei Übergabe", isOn: $protokoll.laufendeReanimation)
                }

                if protokoll.outcome == .verstorben {
                    ZeitFeld(label: "Todeszeitpunkt", datum: $protokoll.todFeststellungsZeit)
                }
            } header: { Label("Outcome", systemImage: "heart.text.square") }

            Section {
                TextEditor(text: $protokoll.freitext).frame(minHeight: 80)
            } header: { Text("Freitext / Notizen") }

        }
        .navigationTitle("Reanimationsprotokoll")
        .navigationBarTitleDisplayMode(.large)
    }
}