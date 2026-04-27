//
//  SplashView.swift
//  Exprem
//

import SwiftUI

struct SplashView: View {
    @Environment(\.appTheme) private var theme

    var logoScale: CGFloat
    var contentOpacity: Double
    var textOffset: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.appBackground, theme.appBlueSoft.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.appBlueSoft)
                        .frame(width: 108, height: 108)

                    Image(.logo)
                        .resizable()
                        .frame(width: 64, height: 64)
                }
                .scaleEffect(logoScale)

                VStack(spacing: 6) {
                    Text("Exprem")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.appTextPrimary)

                    Text("Expiry Reminder")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.appTextSecondary)
                }
                .offset(y: textOffset)
            }
            .opacity(contentOpacity)
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SplashView(logoScale: 1, contentOpacity: 1, textOffset: 0)
}
