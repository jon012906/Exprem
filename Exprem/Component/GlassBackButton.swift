import SwiftUI

struct GlassBackButton: View {
    var body: some View {
        Image(systemName: "chevron.left")
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 46, height: 46)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 0)
            }
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 0)
    }
}
