import SwiftUI

struct MedikamenteView: View {
    @Binding var medikamente: [MedikamentEintrag]
    var onBack: () -> Void

    @State private var zeigeHinzufuegen = false

    private let einheiten = ["mg", "ml", "IE", "µg", "g", "mmol"]
    private let routen = ["i.v.", "i.o.", "i.m.", "s.c.", "p.o.", "inhalativ", "nasal", "rektal"]

    var body: some View {
        Form {
            if medikamente.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "pills.circle")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Noch keine Medikamente erfasst")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }

            ForEach($medikamente) { $med in
                Section {
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundColor(Color("RDOrange"))
                        TextField("Medikament", text: $med.name)
                            .font(.headline)
                    }
                    HStack(spacing: 12) {
                        TextField("Dosis", text: $med.dosis)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 80)
                        Picker("Einheit", selection: $med.einheit) {
                            ForEach(einheiten, id: \.self) { e in
                                Text(e).tag(e)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 70)
                        Spacer()
                        Picker("Route", selection: $med.route) {
                            Text("Route").tag("")
                            ForEach(routen, id: \.self) { r in
                                Text(r).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    DatePicker("Uhrzeit", selection: $med.zeit, displayedComponents: .hourAndMinute)
                }
            }
            .onDelete { indices in
                medikamente.remove(atOffsets: indices)
            }

            Section {
                Button {
                    medikamente.append(MedikamentEintrag())
                } label: {
                    Label("Medikament hinzufügen", systemImage: "plus.circle.fill")
                        .foregroundColor(Color("RDOrange"))
                }
            }

            Section {
                Button(action: onBack) {
                    Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("RDOrange"))
            }
        }
        .navigationTitle("Medikamente")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            EditButton()
        }
    }
}
