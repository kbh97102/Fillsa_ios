import SwiftUI

struct MyPageResignDialog: View {
    let confirm: () -> Void
    let dismiss: () -> Void
    let isProcessing: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            VStack(spacing: 0) {
                Text("탈퇴하시겠습니까?")
                    .font(FillsaTypography.heading4)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .padding(.top, 27)

                Text("탈퇴 후에는 작성하신 필사 정보를 되돌릴 수 없습니다. 😢")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, 10)
                    .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    Button(action: confirm) {
                        Text("탈퇴하기")
                            .font(FillsaTypography.subtitle1)
                            .foregroundStyle(FillsaColor.white)
                            .frame(width: 142, height: 49)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(FillsaColor.purple01)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    .accessibilityIdentifier(MyPageAccessibilityIdentifier.resignConfirm)

                    Button(action: dismiss) {
                        Text("취소")
                            .font(FillsaTypography.subtitle1)
                            .foregroundStyle(FillsaColor.purple01)
                            .frame(width: 142, height: 49)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(FillsaColor.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(FillsaColor.purple01, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    .accessibilityIdentifier(MyPageAccessibilityIdentifier.resignCancel)
                }
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .frame(width: 320, height: 189)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FillsaColor.backgroundContainer)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        FillsaColor.dynamic(light: .clear, dark: FillsaColor.gray500),
                        lineWidth: 1
                    )
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(MyPageAccessibilityIdentifier.resignDialog)
        }
    }
}
