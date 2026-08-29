//
//  OnboardingGuideView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct OnboardingGuideView: View {
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topSection

            VStack(spacing: 0) {
                OnboardingGuideIndicatorSection(currentPage: currentPage)

                OnboardingGuideImageSection(currentPage: $currentPage)
                    .frame(maxHeight: .infinity)

                okButton
            }
            .padding(.horizontal, 20)
        }
        .background(
            FillsaColor.dynamic(light: FillsaColor.white, dark: FillsaColor.gray700)
                .ignoresSafeArea()
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboardingGuide.root.\(colorScheme == .dark ? "dark" : "light")")
    }

    private var topSection: some View {
        HStack {
            Button(action: finish) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FillsaColor.onBackground1)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)

            Spacer()

            Button(action: finish) {
                Text("건너뛰기")
                    .font(FillsaTypography.body3)
                    .underline()
                    .foregroundStyle(FillsaColor.onBackground1)
                    .padding(.trailing, 20)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 9)
    }

    private var okButton: some View {
        Button {
            if currentPage == 2 {
                finish()
            } else {
                withAnimation(.easeInOut) {
                    currentPage += 1
                }
            }
        } label: {
            Text(currentPage == 2 ? "필사 시작하기" : "다음")
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(FillsaColor.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            FillsaColor.dynamic(
                                light: currentPage == 2 ? FillsaColor.purple01 : FillsaColor.gray700,
                                dark: FillsaColor.gray600
                            )
                        )
                )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 30)
    }
}

#Preview {
    OnboardingGuideView(finish: {})
}
