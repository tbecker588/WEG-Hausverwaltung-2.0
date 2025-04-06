import SwiftUI

struct SignaturePadView: UIViewRepresentable {
    // Closure, das das erzeugte UIImage übergibt.
    var onComplete: (UIImage) -> Void

    func makeUIView(context: Context) -> SignatureCanvas {
        let view = SignatureCanvas()
        view.backgroundColor = .white
        view.onComplete = onComplete
        return view
    }
    
    func updateUIView(_ uiView: SignatureCanvas, context: Context) { }
}

class SignatureCanvas: UIView {
    private var path = UIBezierPath()
    private var previousPoint: CGPoint?
    
    // Closure, das beim Beenden der Signatur aufgerufen wird.
    var onComplete: ((UIImage) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .white
        path.lineWidth = 2.0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            previousPoint = touch.location(in: self)
            if let point = previousPoint {
                path.move(to: point)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Hinweis: Anstatt 'if let previous = previousPoint' (da vorher nie verwendet) prüfen wir einfach, ob previousPoint != nil.
        if let touch = touches.first, previousPoint != nil {
            let currentPoint = touch.location(in: self)
            path.addLine(to: currentPoint)
            previousPoint = currentPoint
            setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let image = getSignatureImage() {
            onComplete?(image)
        }
        path.removeAllPoints()
        setNeedsDisplay()
        previousPoint = nil
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        path.stroke()
    }
    
    private func getSignatureImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

struct SignaturePadView_Previews: PreviewProvider {
    static var previews: some View {
        SignaturePadView { image in
            // Hier einfach nichts tun – für die Vorschau reicht das.
        }
        .frame(width: 300, height: 200)
    }
}