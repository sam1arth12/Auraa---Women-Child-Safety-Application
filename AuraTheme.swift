import SwiftUI

struct AuraTheme {
    // Gradients
    static let primaryRedGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.2, blue: 0.2), Color(red: 0.8, green: 0.05, blue: 0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let guardianIndigoGradient = LinearGradient(
        colors: [Color(red: 0.35, green: 0.35, blue: 0.85), Color(red: 0.2, green: 0.2, blue: 0.65)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let safeGreenGradient = LinearGradient(
        colors: [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.1, green: 0.6, blue: 0.25)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let pageBackground = Color(.systemGroupedBackground)
}

// Custom Top-Left Back Button View Component
struct TopLeftBackButton: View {
    var title: String = "Back"
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.body.weight(.medium))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
