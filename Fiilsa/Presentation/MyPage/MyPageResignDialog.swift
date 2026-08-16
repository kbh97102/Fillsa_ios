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
                    .padding(.top, 28)

                Text("탈퇴 후에는 작성하신 필사 정보를 되돌릴 수 없습니다.")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                HStack(spacing: 0) {
                    Button(action: confirm) {
                        Text("탈퇴하기")
                            .font(FillsaTypography.subtitle1)
                            .foregroundStyle(FillsaColor.purple01)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    .accessibilityIdentifier(MyPageAccessibilityIdentifier.resignConfirm)

                    Rectangle()
                        .fill(FillsaColor.gray200)
                        .frame(width: 1, height: 50)

                    Button(action: dismiss) {
                        Text("취소")
                            .font(FillsaTypography.subtitle1)
                            .foregroundStyle(FillsaColor.onBackground1)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    .accessibilityIdentifier(MyPageAccessibilityIdentifier.resignCancel)
                }
                .padding(.top, 24)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(FillsaColor.gray200)
                        .frame(height: 1)
                }
            }
            .frame(maxWidth: 312)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FillsaColor.backgroundContainer)
            )
            .padding(.horizontal, 24)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(MyPageAccessibilityIdentifier.resignDialog)
        }
    }
}
