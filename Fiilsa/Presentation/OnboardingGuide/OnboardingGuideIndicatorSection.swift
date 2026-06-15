//
//  OnboardingGuideIndicatorSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct OnboardingGuideIndicatorSection: View {
    let currentPage: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? FillsaColor.purple01 : FillsaColor.gray200)
                        .frame(height: 5)
                }
            }

            Text("필사, 이렇게 사용하면 편리해요🖋️")
                .font(FillsaTypography.heading4)
                .foregroundStyle(FillsaColor.black)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
        }
    }
}

#Preview {
    OnboardingGuideIndicatorSection(currentPage: 1)
        .padding()
        .background(FillsaColor.background)
}
