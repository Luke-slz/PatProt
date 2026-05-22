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
                    TextEditor(text: $befund.allergien).frame(minHeight: 60)
                    Text("→ PDF S. 1 · SAMPLER · A").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("M — Medikamente (Foto)").font(.subheadline.bold())
                    Text("Aktuelle Medikation als Foto dokumentieren").font(.caption).foregroundColor(.secondary)
                    MedikamentFotoSektion(fotos: $medikamentFotos)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("P — Patientenvorgeschichte").font(.subheadline.bold())
                    Text("Relevante Vorerkrankungen und Operationen").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $befund.patientenVorgeschichte).frame(minHeight: 70)
                    Text("→ PDF S. 1 · SAMPLER · P").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("L — Letzte Mahlzeit").font(.subheadline.bold())
                    Text("Wann und was zuletzt gegessen/getrunken").font(.caption).foregroundColor(.secondary)
                    TextField("z.B. heute Morgen, Brot und Kaffee", text: $befund.letztesMahl)
                    Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("E — Ereignis").font(.subheadline.bold())
                    Text("Was hat zum Notfall geführt?").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $befund.ereignis).frame(minHeight: 70)
                    Text("→ PDF S. 1 · SAMPLER · E").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("R — Risikofaktoren").font(.subheadline.bold())
                    Text("Bekannte Risikofaktoren").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $befund.risikofaktoren).frame(minHeight: 60)
                    Text("→ PDF S. 1 · SAMPLER · R").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("SAMPLER")
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button(action: onZurueck) {
                    Label("Zurück", systemImage: "chevron.left.circle.fill")
                        .frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.bordered)
                .tint(Color("RDOrange"))
            }
            .padding([.horizontal, .bottom])
            .background(.bar)
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

            Section {
                Button(action: onWeiter) {
                    Label("Weiter zum Abschluss", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
            }
        }
        .navigationTitle("Reanimationsprotokoll")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}