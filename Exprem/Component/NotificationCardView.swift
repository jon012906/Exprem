//
//  NotificationCardView.swift
//  Exprem
//
//  Created by Jon on 19/04/26.
//

import SwiftUI

struct NotificationCardView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Don't forget to use your **milk**!")
                    .font(.subheadline)
                    .foregroundStyle(theme.appTextPrimary)

                Text("2 Days Left!")
                    .fontWeight(.bold)
                    .foregroundStyle(theme.appTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.appCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.appBorder, lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 14) {
        NotificationCardView()
            .appTheme(.light)

        NotificationCardView()
            .appTheme(.dark)
            .preferredColorScheme(.dark)
    }
}
