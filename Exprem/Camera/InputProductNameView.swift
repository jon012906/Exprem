import SwiftUI

struct InputProductNameView: View {
    let origin: ScanFlowOrigin

    @Environment(\.dismiss) private var dismiss
    @State private var productName = ""
    @State private var showScanExpiry = false

    var body: some View {
        ZStack {
//            Color(red: 0.93, green: 0.93, blue: 0.95)
//                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Product Name", text: $productName)
                        .font(.body)
                        .padding(.top, 4)

                    Divider()

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Input Product Name")
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

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScanExpiry = true
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }.buttonStyle(.borderedProminent)
                 
            }
        }
        .navigationDestination(isPresented: $showScanExpiry) {
            ScanProductExpiryView(origin: origin)
        }
    }
}

#Preview {
    NavigationStack {
        InputProductNameView(origin: .onboarding)
    }
}
