import SwiftUI

struct AlertSwitchSection: View {
    @Binding var selected: Bool
    var isEnabled = true

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("오늘의 필사 알림")
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.onBackground1)

                Text("매일 오전 9시에 새로운 문장 알림을 받을 수 있습니다.")
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.onBackground1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)

            Toggle("", isOn: $selected)
                .labelsHidden()
                .tint(FillsaColor.purple01)
                .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .background(FillsaColor.dynamic(light: FillsaColor.yellow01, dark: FillsaColor.gray600))
    }
}

#Preview {
    AlertSwitchSection(selected: .constant(true))
}
