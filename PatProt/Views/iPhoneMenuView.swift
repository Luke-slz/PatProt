import SwiftUI

// MARK: - iPhone Navigation Menu Sheet

struct iPhoneMenuView: View {
    @Binding var path: [iPhoneAppStep]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Einsatzdaten") {
                    menuRow("Rettungstechnische Daten", icon: "car.fill", farbe: Color("RDOrange"), step: .einsatzOrt)
                    menuRow("Notfallgeschehen", icon: "exclamationmark.bubble.fill", farbe: .red, step: .notfallGeschehen)
                }

                Section("ABCDE-Schema") {
                    menuRow("Befunderhebung (Übersicht)", icon: "list.bullet.clipboard.fill", farbe: .orange, step: .abcde)
                    menuRow("A – Airway", icon: "lungs.fill", farbe: .orange, step: .airway)
                    menuRow("B – Breathing", icon: "wind", farbe: .blue, step: .breathing)
                    menuRow("C – Circulation", icon: "heart.fill", farbe: .red, step: .circulation)
                    menuRow("D – Disability", icon: "brain.head.profile", farbe: .purple, step: .disability)
                    menuRow("E – Exposure", icon: "thermometer.medium", farbe: .green, step: .exposure)
                }

                Section("Anamnese & Schemata") {
                    menuRow("SAMPLER-Schema", icon: "list.clipboard.fill", farbe: .teal, step: .sampler)
                    menuRow("SINNHAFT-Schema", icon: "bubble.left.and.bubble.right.fill", farbe: .indigo, step: .sinnhaft)
                }

                Section("Diagnose & Verlauf") {
                    menuRow("Diagnose (Trichter)", icon: "slider.horizontal.3", farbe: .blue, step: .diagnose)
                    menuRow("Verlauf & Therapie", icon: "waveform.path.ecg", farbe: .orange, step: .verlauf)
                }

                Section("Therapie") {
                    menuRow("Maßnahmen", icon: "cross.circle.fill", farbe: Color("RDOrange"), step: .massnahmen)
                    menuRow("Medikamente", icon: "pills.fill", farbe: .green, step: .medikamente)
                    menuRow("Bilder & Dateien", icon: "camera.fill", farbe: .purple, step: .bilder)
                }

                Section("Abschluss") {
                    menuRow("Reanimation", icon: "heart.slash.fill", farbe: .red, step: .reanimation)
                    menuRow("Abschluss & PDF", icon: "checkmark.seal.fill", farbe: .green, step: .abschluss)
                }

                Section {
                    menuRow("Einstellungen", icon: "gearshape.fill", farbe: .gray, step: .settings)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Menü")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { isPresented = false }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func menuRow(_ title: String, icon: String, farbe: Color, step: iPhoneAppStep) -> some View {
        Button {
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                path = [step]
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(farbe)
                    .frame(width: 30, height: 30)
                    .background(farbe.opacity(0.15))
                    .cornerRadius(7)
                Text(title)
                    .foregroundColor(.primary)
            }
        }
    }
}
