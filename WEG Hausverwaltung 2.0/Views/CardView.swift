import SwiftUI

/// Eine wiederverwendbare Kartenansicht mit konfigurierbarem Inhalt
struct CardView<Content: View>: View {
    // MARK: - Properties
    let content: Content
    
    // MARK: - Initialization
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        content
            .padding(DesignSystem.Layout.Spacing.medium)
            .background(DesignSystem.Colors.card)
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// MARK: - Preview
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CardView {
                Text("Standard Card")
            }
            
            CardView {
                Text("Custom Card")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}