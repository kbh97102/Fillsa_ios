import SwiftUI

struct AlertSwitchSection: View {
    @Binding var selected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("오늘의 필사 알림")
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.gray700)

                Text("매일 오전 9시에 새로운 문장 알림을 받을 수 있습니다.")
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray700)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)

            Toggle("", isOn: $selected)
                .labelsHidden()
                .tint(FillsaColor.purple01)
        }
        .padding(.horizontal, 20)
        .background(FillsaColor.yellow01)
    }
}

#Preview {
    AlertSwitchSection(selected: .constant(true))
}
