//
//  ShareView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct ShareView: View {
    let quote: String
    let author: String
    let back: () -> Void

    @State private var selectedPage = 0

    private let backgrounds: [Color] = [
        Color(hex: 0xFFEFCC),
        Color(hex: 0xFFFFFF),
        Color(hex: 0xD3D5FF),
        Color(hex: 0xFFCB5C),
        Color(hex: 0xE6B5C1),
        Color(hex: 0x212121),
        Color(hex: 0x6B77FF),
        Color(hex: 0xFEFED6)
    ]

    var body: some View {
        VStack(spacing: 0) {
            topSection

            Text("배경을 선택해주세요.")
                .font(FillsaTypography.heading4)
                .foregroundStyle(FillsaColor.gray700)

            Text("필사한 문장이 이미지로 저장됩니다.")
                .font(FillsaTypography.body2)
                .foregroundStyle(FillsaColor.gray700)
                .padding(.top, 4)

            TabView(selection: $selectedPage) {
                ForEach(backgrounds.indices, id: \.self) { index in
                    ShareCard(
                        quote: quote,
                        author: author,
                        background: backgrounds[index],
                        textColor: [1, 5].contains(index) ? FillsaColor.white : FillsaColor.gray700
                    )
                    .padding(.horizontal, 60)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.vertical, 30)

            bottomSection
                .padding(.bottom, 50)
        }
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private var topSection: some View {
        HStack {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 9)
    }

    private var bottomSection: some View {
        HStack(spacing: 50) {
            shareButton(systemName: "square.and.arrow.down", text: "저장", action: {})
            shareButton(systemName: "doc.on.doc", text: "복사") {
                UIPasteboard.general.string = "\(quote)\n\(author)"
            }
            shareButton(systemName: "message.fill", text: "카카오톡", action: {})
        }
    }

    private func shareButton(systemName: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(FillsaColor.white)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: systemName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(FillsaColor.gray700)
                    }

                Text(text)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray700)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ShareCard: View {
    let quote: String
    let author: String
    let background: Color
    let textColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(background)
            .overlay {
                VStack(spacing: 18) {
                    Text(quote)
                        .font(FillsaTypography.body2)
                        .multilineTextAlignment(.center)

                    Text(author)
                        .font(FillsaTypography.body2)
                }
                .foregroundStyle(textColor)
                .padding(26)
            }
    }
}

#Preview {
    ShareView(
        quote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        author: "존 우든",
        back: {}
    )
}
