import SwiftUI

// MARK: - Weiter Button

struct WeiterButton: View {
    var label: String = "Weiter"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: "arrow.right.circle.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("RDOrange"))
                .foregroundColor(.white)
                .cornerRadius(14)
                .font(.headline)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}

// MARK: - View Extensions

extension View {
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                }
            }
        }
    }
}
