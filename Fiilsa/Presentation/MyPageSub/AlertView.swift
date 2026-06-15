import SwiftUI

struct AlertView: View {
    @AppStorage("alarm_key") private var selected = false
    @State private var isLogged = false

    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HeaderSection(title: "알림", back: back)
                .padding(.horizontal, 20)
                .background(FillsaColor.background)

            AlertSwitchSection(selected: $selected)

            if isLogged {
                resignButton
                    .padding(.top, 50)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private var resignButton: some View {
        Button(action: {}) {
            HStack {
                Text("탈퇴하기")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.gray700)

                Spacer()

                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(FillsaColor.gray700)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 19)
            .background(FillsaColor.yellow01)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AlertView(back: {})
}
