import SwiftUI
import WebKit

// ShareSheet zur Anzeige eines UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

// PDFPreviewView als Wrapper für WKWebView, um ein PDF anzuzeigen.
struct PDFPreviewView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct BillingView: View {
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var showPDFPreview = false
    
    var body: some View {
        VStack(spacing: 16) {
            Button("PDF generieren") {
                let pdfService = PDFService()
                // Verwende hier den Beispiel-Owner (Extension in Owner+Example.swift)
                let owner = Owner.example
                // Erzeuge das PDF – beachte, dass generatePDF hier eine Instanzmethode von PDFService sein sollte.
                pdfURL = pdfService.generatePDF(for: owner, year: 2024)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            if let url = pdfURL {
                Button("PDF teilen") {
                    showShareSheet = true
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(items: [url])
                }
                .buttonStyle(.bordered)
                .padding()
                
                Button("PDF Vorschau") {
                    showPDFPreview = true
                }
                .sheet(isPresented: $showPDFPreview) {
                    PDFPreviewView(url: url)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .navigationTitle("Abrechnung")
    }
}

struct BillingView_Previews: PreviewProvider {
    static var previews: some View {
        BillingView()
    }
}