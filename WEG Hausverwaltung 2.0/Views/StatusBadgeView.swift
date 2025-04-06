import SwiftUI

struct StatusBadgeView: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(
                Circle()
                    .fill(Color.red)
                    .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 2)
            )
            .overlay(
                Circle()
                    .stroke(Color.cardWhite, lineWidth: 2)
            )
    }
}

struct StatusBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBadgeView(count: 5)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}