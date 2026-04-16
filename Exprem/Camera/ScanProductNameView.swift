import SwiftUI

struct ScanProductNameView: View {
    let origin: ScanFlowOrigin

    @Environment(\.dismiss) private var dismiss
    @State private var showManualInput = false
    @State private var showScanExpiry = false

    var body: some View {
        ZStack {
//            Color(red: 0.93, green: 0.93, blue: 0.95)
//                .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(red: 0.84, green: 0.84, blue: 0.86))

                    VStack(spacing: 26) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 190, weight: .regular))
                            .foregroundStyle(.blue)

                        Image(systemName: "doc.fill")
                            .font(.system(size: 80, weight: .regular))
                            .foregroundStyle(.blue)
                            .offset(y: -128)

                        Spacer()

                        Button("Type your product name") {
                            showManualInput = true
                        }
                        .buttonStyle(.plain)
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 36)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                captureBar {
                    showScanExpiry = true
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .navigationTitle("Scan Product Name")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    GlassBackButton()
                }
            }
        }
        .navigationDestination(isPresented: $showManualInput) {
            InputProductNameView(origin: origin)
        }
        .navigationDestination(isPresented: $showScanExpiry) {
            ScanProductExpiryView(origin: origin)
        }
    }

    private func captureBar(action: @escaping () -> Void) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)

            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)

                    Circle()
                        .stroke(Color.gray.opacity(0.35), lineWidth: 3)
                        .frame(width: 74, height: 74)

                    Image(systemName: "camera.fill")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(height: 108)
        .padding(.top, 10)
    }
}

#Preview {
    NavigationStack {
        ScanProductNameView(origin: .onboarding)
    }
}
