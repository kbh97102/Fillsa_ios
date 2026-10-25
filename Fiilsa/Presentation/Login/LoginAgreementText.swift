import SwiftUI

struct LoginAgreementText: View {
    var body: some View {
        Text(agreement)
            .font(FillsaTypography.body3)
            .foregroundStyle(FillsaColor.dynamic(light: FillsaColor.gray500, dark: FillsaColor.white))
            .tint(FillsaColor.dynamic(light: FillsaColor.gray500, dark: FillsaColor.white))
            .multilineTextAlignment(.center)
    }

    private var agreement: AttributedString {
        var text = AttributedString("로그인 시, 이용약관 및 개인정보 처리방침에 동의하는 것으로 간주됩니다.")
        for (title, url) in [("이용약관", "https://www.fillsa.com/terms/"),
                             ("개인정보 처리방침", "https://www.fillsa.com/privacy/")] {
            if let range = text.range(of: title) {
                text[range].link = URL(string: url)
                text[range].underlineStyle = .single
                text[range].font = FillsaTypography.subtitle2
            }
        }
        return text
    }
}
