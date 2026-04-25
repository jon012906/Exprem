//
//  ProductCardView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import UIKit

struct ProductCardView: View {
    var item: Product
    var onDone: (Product) -> Void
    @Environment(\.appTheme) private var theme

    @State private var showConfirm = false
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 14) {
            thumbnailView
                
            VStack(alignment: .leading, spacing: 6) {
                Text(item.nameProduct)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    
                Text("EXP Date: \(Text(formatDate(item.expiryDate)).fontWeight(.bold))")
                    .font(.subheadline)
                    .foregroundStyle(theme.appTextSecondary)
                
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
                .fill(theme.appCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(theme.appBorder, lineWidth: 0.8)
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
                Label("Delete", systemImage: "trash")
            }
            .tint(theme.statusExpired)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(theme.statusExpired)
        }
        .confirmationDialog("Delete Item?", isPresented: $showConfirm, titleVisibility: .visible){
            Button("Delete", role: .none){
                onDone(item)
            }
            Button("Cancel", role: .cancel){}
        }message: {
            Text("Are you sure you want to delete this item?")
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                EditPrroductView(product: item)
                    .appTheme(theme)
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
            let overdueDays = abs(days)

            if overdueDays < 7 {
                return "\(overdueDays)d ago"
            } else if overdueDays < 30 {
                return "\(overdueDays / 7)w ago"
            } else if overdueDays < 365 {
                return "\(overdueDays / 30)m ago"
            } else {
                return "Throw away"
            }
        } else if days == 0 {
            return "Today"
        } else {
            if days < 7 {
                return "\(days)d left"
            }
            else if days < 30 {
                return "\(days / 7)w left"
            }
            else {
                return "\(days / 30)m left"
            }
        }
    }
    
    private func colorForExpiry() -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
        
        if days < 0 {
            return theme.statusExpired
        } else if days <= 7 {
            return theme.statusExpiredSoon
        } else {
            return theme.statusLong
        }
    }

    private var thumbnailView: some View {
        Group {
            if let image = ProductImageStore.loadImage(filename: item.thumbnailPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "cart")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 74, height: 74)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview("Normal") {
    ProductCardView(
        item: Product(
            nameProduct: "Cheese",
            expiryDate: Calendar.current.date(byAdding: .day, value: 70, to: Date())!
        ),
        onDone: {_ in }
    )
    .padding()
}
