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
            FillsaColor.backgroundDim
                .ignoresSafeArea()

            VStack(spacing: 12) {
                VStack(spacing: MyPageLayout.themeOptionSpacing) {
                    themeRow(title: "라이트", theme: .light)
                    themeRow(title: "다크", theme: .dark)
                    themeRow(title: "시스템", theme: .system)
                }

                Button(action: confirm) {
                    Text("확인")
                        .font(FillsaTypography.subtitle1)
                        .foregroundStyle(FillsaColor.white)
                        .frame(
                            width: MyPageLayout.confirmButtonSize.width,
                            height: MyPageLayout.confirmButtonSize.height
                        )
                        .background(
                            RoundedRectangle(cornerRadius: MyPageLayout.themeDialogCornerRadius)
                                .fill(Color(hex: 0x5E67FD))
                        )
                }
                .buttonStyle(.plain)
                .frame(height: 73)
                .accessibilityIdentifier(MyPageAccessibilityIdentifier.themeConfirm)
            }
            .padding(.top, 20)
            .background(
                RoundedRectangle(cornerRadius: MyPageLayout.themeDialogCornerRadius)
                    .fill(FillsaColor.backgroundContainer)
            )
            .overlay {
                RoundedRectangle(cornerRadius: MyPageLayout.themeDialogCornerRadius)
                    .stroke(FillsaColor.myPageCardOutline, lineWidth: 1)
            }
            .shadow(color: FillsaColor.myPageShadow, radius: 16, x: 0, y: 0)
            .frame(
                width: MyPageLayout.themeDialogSize.width,
                height: MyPageLayout.themeDialogSize.height
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(MyPageAccessibilityIdentifier.themeDialog)
        }
    }

    private func themeRow(title: String, theme: DarkModeType) -> some View {
        Button {
            selectedTheme = theme
        } label: {
            HStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(FillsaColor.onBackground1)

                Spacer()

                radioIcon(isSelected: selectedTheme == theme)
            }
            .frame(width: MyPageLayout.confirmButtonSize.width, height: MyPageLayout.themeOptionSize)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier(for: theme))
        .accessibilityValue(selectedTheme == theme ? "selected" : "unselected")
    }

    private func accessibilityIdentifier(for theme: DarkModeType) -> String {
        switch theme {
        case .light:
            MyPageAccessibilityIdentifier.themeLight
        case .dark:
            MyPageAccessibilityIdentifier.themeDark
        case .system:
            MyPageAccessibilityIdentifier.themeSystem
        }
    }

    @ViewBuilder
    private func radioIcon(isSelected: Bool) -> some View {
        Image(isSelected ? "my_page_radio_checked" : "my_page_radio_unchecked")
            .resizable()
            .scaledToFit()
            .frame(width: MyPageLayout.themeOptionSize, height: MyPageLayout.themeOptionSize)
    }
}

#Preview {
    @Previewable @State var selectedTheme: DarkModeType = .system

    MyPageThemeDialog(selectedTheme: $selectedTheme, confirm: {})
}
