import SwiftUI

struct ProductCardView: View {
    var item: ProductItem   // use model directly
    var onDone: (ProductItem) -> Void

    @State private var showConfirm = false
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(width: 74, height: 74)

                Text("Image")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Text("EXP Date: \(Text(formatDate(item.expiryDate)).fontWeight(.bold))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
            }

            Spacer(minLength: 8)

            Text(timeLeftText())
                .font(.headline.weight(.bold))
                .foregroundStyle(colorForExpiry())
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(.separator).opacity(0.25), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showEdit = true
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                showConfirm = true
            } label: {
                Label("Done", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showEdit = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .confirmationDialog("Mark as Done?", isPresented: $showConfirm, titleVisibility: .visible){
            Button("Mark as Done", role: .none){
                onDone(item)
            }
            Button("Cancle", role: .cancel){}
        }message: {
            Text("Are you sure you want to mark this item as done?")
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                EditPrroductView(name: item.name, expiryDate: item.expiryDate)
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Date Formatting and Expiry Logic

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }

    private func timeLeftText() -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
        
        if days < 0 {
            return "Expired"
        } else if days == 0 {
            return "Today"
        } else {
            return "\(days)d left"
        }
    }
    
    private func colorForExpiry() -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
        
        if days < 0 {
            return .red
        } else if days <= 7 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview("Normal") {
    ProductCardView(
        item: ProductItem(
            name: "Cheese",
            expiryDate: Calendar.current.date(byAdding: .day, value: 70, to: Date())!
        ),
        onDone: {_ in }
    )
    .padding()
}
