import SwiftUI

struct InputProductExpiryDateView: View {
    let origin: ScanFlowOrigin

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var showAddProduct = false

    var body: some View {
        ZStack {
//            Color(red: 0.93, green: 0.93, blue: 0.95)
//                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 6)

                    Spacer()
                }
                .padding(.horizontal, 12)
            }
        }
        .navigationTitle("Input Product Expiry Date")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            showAddProduct = false
        }
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
                    if origin == .onboarding {
                        showAddProduct = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }.buttonStyle(.borderedProminent)
                
            }
        }
        .navigationDestination(isPresented: $showAddProduct) {
            AddProductView()
        }
    }
}

#Preview {
    NavigationStack {
        InputProductExpiryDateView(origin: .onboarding)
    }
}
