//
//  OnboardingGuideImageSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct OnboardingGuideImageSection: View {
    @Binding var currentPage: Int

    var body: some View {
        TabView(selection: $currentPage) {
            GuidePhoneMock(imageName: "onboarding_guide_home", size: CGSize(width: 288, height: 430))
                .tag(0)

            GuidePhoneMock(imageName: "onboarding_guide_list", size: CGSize(width: 288, height: 430))
                .tag(1)

            GuidePhoneMock(imageName: "onboarding_guide_calendar", size: CGSize(width: 280, height: 430))
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

private struct GuidePhoneMock: View {
    let imageName: String
    let size: CGSize

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    @Previewable @State var currentPage = 0

    OnboardingGuideImageSection(currentPage: $currentPage)
        .frame(height: 440)
        .background(FillsaColor.background)
}
