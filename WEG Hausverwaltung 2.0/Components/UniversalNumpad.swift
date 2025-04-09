import SwiftUI

/// Universelle Numpad-Komponente für die Eingabe von Zahlen
struct UniversalNumpad: View {
    @Binding
    var value: String
    var onConfirm: (() -> Void)?
    var maxDigits: Int = 10
    var allowDecimal: Bool = true
    var decimalSeparator: String = ","

    // Haptic Feedback Generator
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack {
            // Eingabevorschau
            Text(value.isEmpty ? "0" : value)
                .font(.title)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .accessibilityLabel("Eingegebener Wert: \(value.isEmpty ? "0" : value)")

            // Numpad-Raster
            VStack(spacing: 10) {
                // Erste Reihe
                HStack(spacing: 10) {
                    NumpadButton(text: "1", action: { addDigit("1") })
                    NumpadButton(text: "2", action: { addDigit("2") })
                    NumpadButton(text: "3", action: { addDigit("3") })
                }

                // Zweite Reihe
                HStack(spacing: 10) {
                    NumpadButton(text: "4", action: { addDigit("4") })
                    NumpadButton(text: "5", action: { addDigit("5") })
                    NumpadButton(text: "6", action: { addDigit("6") })
                }

                // Dritte Reihe
                HStack(spacing: 10) {
                    NumpadButton(text: "7", action: { addDigit("7") })
                    NumpadButton(text: "8", action: { addDigit("8") })
                    NumpadButton(text: "9", action: { addDigit("9") })
                }

                // Letzte Reihe
                HStack(spacing: 10) {
                    NumpadButton(text: "C", action: { clear() }, color: .red)
                    NumpadButton(text: "0", action: { addDigit("0") })
                    if allowDecimal {
                        NumpadButton(text: decimalSeparator, action: { addDecimalSeparator() })
                    } else {
                        NumpadButton(text: "⌫", action: { deleteLastCharacter() }, color: .orange)
                    }
                }

                // Bestätigungsbutton
                Button(action: {
                    onConfirm?()
                }) {
                    Text("OK")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .disabled(value.isEmpty)
            }
            .padding()
        }
    }

    // MARK: - Hilfsmethoden

    /// Ziffern hinzufügen
    private func addDigit(_ digit: String) {
        feedback.impactOccurred() // Haptic Feedback
        // Begrenzung der Gesamtlänge
        guard value.count < maxDigits else { return }

        // Erste Null entfernen, wenn vorhanden
        if value == "0" {
            value = digit
            return
        }

        value += digit
    }

    /// Komma hinzufügen
    private func addDecimalSeparator() {
        // Komma nur hinzufügen, wenn noch kein Komma vorhanden
        guard !value.contains(decimalSeparator) else { return }

        // Wenn leer, dann 0,
        if value.isEmpty {
            value = "0\(decimalSeparator)"
            return
        }

        value += decimalSeparator
    }

    /// Letztes Zeichen löschen
    private func deleteLastCharacter() {
        guard !value.isEmpty else { return }
        value.removeLast()
    }

    /// Eingabe löschen
    private func clear() {
        value = ""
    }
}

/// Einzelner Numpad-Button als wiederverwendbare Komponente
struct NumpadButton: View {
    let text: String
    let action: () -> Void
    var color: Color = .blue

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color.opacity(0.1))
                .foregroundColor(color)
                .cornerRadius(10)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch text {
        case "C": "Alles löschen"
        case "⌫": "Letzte Ziffer löschen"
        default: text
        }
    }
}

/// Kompakteres Numpad für spezifische Anwendungsfälle
struct CompactNumpad: View {
    @Binding
    var value: String
    var onConfirm: (() -> Void)?
    var title: String = "Eingabe"

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.top)

            Text(value.isEmpty ? "0" : value)
                .font(.title)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            // Kompaktes Layout mit reduzierten Abständen
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(1 ... 3, id: \.self) { num in
                        NumpadButton(text: "\(num)", action: {
                            if value.count < 12 { value += "\(num)" }
                        })
                    }
                }

                HStack(spacing: 8) {
                    ForEach(4 ... 6, id: \.self) { num in
                        NumpadButton(text: "\(num)", action: {
                            if value.count < 12 { value += "\(num)" }
                        })
                    }
                }

                HStack(spacing: 8) {
                    ForEach(7 ... 9, id: \.self) { num in
                        NumpadButton(text: "\(num)", action: {
                            if value.count < 12 { value += "\(num)" }
                        })
                    }
                }

                HStack(spacing: 8) {
                    NumpadButton(text: "C", action: { value = "" }, color: .red)
                    NumpadButton(text: "0", action: {
                        if value.count < 12 { value += "0" }
                    })
                    NumpadButton(text: ",", action: {
                        if !value.contains(",") { value += "," }
                    })
                }
            }
            .padding(.horizontal)

            Button(action: {
                onConfirm?()
            }) {
                Text("Bestätigen")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

// Protokoll für gemeinsame Funktionalität
protocol NumpadViewModel {
    var value: String { get set }
    func addDigit(_ digit: String)
    func clear()
    func addDecimalSeparator()
}

// Vorschau für die Komponente
struct UniversalNumpad_Previews: PreviewProvider {
    @State
    static var previewValue = ""

    static var previews: some View {
        VStack {
            UniversalNumpad(
                value: $previewValue,
                onConfirm: { print("Bestätigt: \(previewValue)") }
            )
            .padding()

            CompactNumpad(
                value: $previewValue,
                onConfirm: { print("Kompaktes Numpad bestätigt: \(previewValue)") },
                title: "Betrag eingeben"
            )
            .padding()
        }
    }
}
