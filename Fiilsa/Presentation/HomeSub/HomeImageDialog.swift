//
//  HomeImageDialog.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import PhotosUI
import SwiftUI

struct HomeImageDialog: View {
    let quote: String
    let author: String
    let imagePath: String
    let dismiss: () -> Void
    let delete: () -> Void
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            ZStack(alignment: .topLeading) {
                background

                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Button(action: dismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(FillsaColor.gray700)
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)

                        if !imagePath.isEmpty {
                            Button(action: delete) {
                                Text("삭제하기")
                                    .font(FillsaTypography.body2)
                                    .foregroundStyle(FillsaColor.gray700)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }

                    Text(quote)
                        .font(FillsaTypography.body2)
                        .foregroundStyle(FillsaColor.gray700)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 90)

                    Text(author)
                        .font(FillsaTypography.body2)
                        .foregroundStyle(FillsaColor.gray700)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)

                    HStack(spacing: 10) {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images
                        ) {
                            Text("이미지 변경")
                                .font(FillsaTypography.subtitle1)
                                .foregroundStyle(FillsaColor.gray700)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(FillsaColor.white.opacity(0.9))
                                )
                        }
                        .buttonStyle(.plain)

                        dialogButton("확인", action: dismiss)
                    }
                    .padding(.top, 86)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var background: some View {
        if let url = URL(string: imagePath), !imagePath.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                default:
                    defaultBackground
                }
            }
        } else {
            defaultBackground
        }
    }

    private var defaultBackground: some View {
        LinearGradient(
            colors: [Color(hex: 0xFEFED6), Color(hex: 0xE6B5C1), Color(hex: 0xC990CE)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func dialogButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(FillsaColor.gray700)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FillsaColor.white.opacity(0.9))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeImageDialog(
        quote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        author: "존 우든",
        imagePath: "",
        dismiss: {},
        delete: {},
        selectedPhotoItem: .constant(nil)
    )
}
