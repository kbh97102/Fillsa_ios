import SwiftUI

struct QuoteToast: View {
    let message: String
    let presentation: HomeToastPresentation
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                if presentation == .success {
                    Image(colorScheme == .dark ? "toast_check_dark" : "toast_check_light")
                        .resizable()
                        .scaledToFit()
                        .padding(1)
                        .frame(width: 24, height: 24)
                }
                Text(message)
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.onToastMessage1)
            }
            .padding(.horizontal, presentation == .success ? 12 : 16)
            .frame(maxWidth: presentation == .success ? .infinity : nil, alignment: .leading)
            .frame(height: presentation == .success ? 50 : 36)
            .background(FillsaColor.toastMessageBackground, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, presentation == .success ? 20 : 0)
            .padding(.bottom, 28)
        }
    }

}
