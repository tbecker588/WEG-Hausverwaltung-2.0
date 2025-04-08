import SwiftUI

struct StatusBadgeView: View {
    let status: BillingStatus
    
    var statusColor: Color {
        switch status {
        case .paid:
            return DesignSystem.Colors.success
        case .unpaid:
            return DesignSystem.Colors.error
        case .partial:
            return DesignSystem.Colors.secondary
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

struct StatusBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Hell-Modus
            HStack(spacing: 10) {
                StatusBadgeView(status: .paid)
                StatusBadgeView(status: .unpaid)
                StatusBadgeView(status: .partial)
            }
            
            // Dunkel-Modus
            HStack(spacing: 10) {
                StatusBadgeView(status: .paid)
                StatusBadgeView(status: .unpaid)
                StatusBadgeView(status: .partial)
            }
            .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .previewDisplayName("Status Badges")
    }
}