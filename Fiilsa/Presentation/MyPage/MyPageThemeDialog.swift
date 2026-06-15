//
//  MyPageThemeDialog.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MyPageThemeDialog: View {
    @Binding var selectedTheme: DarkModeType
    let confirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                themeRow(title: "라이트", theme: .light)
                themeRow(title: "다크", theme: .dark)
                    .padding(.top, 15)
                themeRow(title: "시스템", theme: .system)
                    .padding(.top, 15)

                Button(action: confirm) {
                    Text("확인")
                        .font(FillsaTypography.subtitle1)
                        .foregroundStyle(FillsaColor.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(FillsaColor.purple01)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 24)
            }
            .padding(.horizontal, 12)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FillsaColor.white)
            )
            .padding(.horizontal, 20)
        }
    }

    private func themeRow(title: String, theme: DarkModeType) -> some View {
        Button {
            selectedTheme = theme
        } label: {
            HStack(spacing: 0) {
                Text(title)
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.gray700)

                Spacer()

                radioIcon(isSelected: selectedTheme == theme)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func radioIcon(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? FillsaColor.purple01 : FillsaColor.gray300, lineWidth: 2)
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(FillsaColor.purple01)
                    .frame(width: 12, height: 12)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTheme: DarkModeType = .system

    MyPageThemeDialog(selectedTheme: $selectedTheme, confirm: {})
}
