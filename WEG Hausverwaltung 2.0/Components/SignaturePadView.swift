import PencilKit
import SwiftUI

/// Eine Unterschriften-Komponente basierend auf PencilKit
///
/// Ermöglicht das Erfassen von Unterschriften mit den folgenden Funktionen:
/// - Zeichnen mit Apple Pencil oder Finger
/// - Löschen der Unterschrift
/// - Export als Bild
/// - Orientierungshilfen für die Unterschrift
struct SignaturePadView: UIViewRepresentable {
    // MARK: - Properties

    /// Callback für das Speichern der Unterschrift
    var onSave: (UIImage?) -> Void

    /// Optionale Hilfslinie für die Unterschrift
    var showGuideline: Bool = true

    /// Stiftfarbe
    var inkColor: UIColor = .black

    /// Stiftbreite
    var inkWidth: CGFloat = 3.0

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .white
        canvas.isOpaque = false

        // Zeichenwerkzeug konfigurieren
        let ink = PKInkingTool(.pen, color: inkColor, width: inkWidth)
        canvas.tool = ink

        // Delegat zuweisen
        canvas.delegate = context.coordinator

        // Accessibility
        canvas.isAccessibilityElement = true
        canvas.accessibilityLabel = "Unterschriftenfeld"
        canvas.accessibilityHint = "Doppeltippen zum Zeichnen der Unterschrift"

        return canvas
    }

    func updateUIView(_: PKCanvasView, context _: Context) {
        // Nichts zu aktualisieren
    }

    // Koordinator für Callback-Handling
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SignaturePadView

        init(_ parent: SignaturePadView) {
            self.parent = parent
        }

        // Reagieren auf Änderungen der Zeichnung
        func canvasViewDrawingDidChange(_: PKCanvasView) {
            // Optional: Hier könnte man automatisches Speichern implementieren
        }
    }

    // Methode zum Exportieren des Bilds
    static func getSignatureImage(from canvas: PKCanvasView) -> UIImage? {
        // Erstellt ein Bild aus der Zeichnung
        let bounds = canvas.bounds

        // UIGraphicsImageRenderer für die Bildgenerierung verwenden
        let renderer = UIGraphicsImageRenderer(size: bounds.size)

        let image = renderer.image { ctx in
            // Weißer Hintergrund
            UIColor.white.setFill()
            ctx.fill(bounds)

            // Zeichnung darüber rendern
            canvas.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }

        return image
    }
}

// MARK: - Erweiterte SignatureView

struct SignatureView: View {
    @State
    private var canvas = PKCanvasView()
    @State
    private var showSaveConfirmation = false
    @Binding
    var signatureImage: UIImage?

    var onSave: (UIImage?) -> Void

    init(signatureImage: Binding<UIImage?>, onSave: @escaping (UIImage?) -> Void) {
        _signatureImage = signatureImage
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 15) {
            Text("Unterschrift")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            SignaturePadView(onSave: { image in
                signatureImage = image
                onSave(image)
            }, showGuideline: true)
                .frame(height: 200)
                .background(
                    ZStack {
                        Color.white
                        // Hilfslinie für Unterschrift
                        if signatureImage == nil {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                                .offset(y: 40)
                        }
                    }
                )
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding(.horizontal)

            Text("Bitte unterschreiben Sie hier")
                .font(.caption)
                .foregroundColor(.gray)
                .accessibilityLabel("Hinweis: Bitte unterschreiben Sie hier")

            HStack(spacing: 30) {
                Button(action: clearSignature) {
                    Label("Löschen", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .accessibilityHint("Löscht die aktuelle Unterschrift")

                Button(action: saveSignature) {
                    Label("Speichern", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                }
                .accessibilityHint("Speichert die Unterschrift")
            }
            .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("Unterschrift gespeichert"),
                message: Text("Die Unterschrift wurde erfolgreich gespeichert."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Private Methods

    private func clearSignature() {
        canvas.drawing = PKDrawing()
        signatureImage = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func saveSignature() {
        let image = SignaturePadView.getSignatureImage(from: canvas)
        signatureImage = image
        onSave(image)
        showSaveConfirmation = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// Vereinfachte Version für direkte Verwendung
struct SimpleSignatureView: View {
    @State
    private var signatureImage: UIImage?
    var onSignatureSaved: (UIImage?) -> Void

    var body: some View {
        VStack {
            SignatureView(signatureImage: $signatureImage, onSave: onSignatureSaved)
                .frame(height: 300)

            if let image = signatureImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
    }
}

// Vorschau
struct SignaturePadView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SimpleSignatureView { _ in
                print("Signature saved")
            }
            .padding()
        }
    }
}
