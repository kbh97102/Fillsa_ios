import SwiftUI

struct NoticeDetailView: View {
    let notice: NoticeResponse
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HeaderSection(title: "공지사항", back: back)
                .background(FillsaColor.background)

            VStack(alignment: .leading, spacing: 0) {
                Text(notice.title)
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .padding(.top, 16)
                    .accessibilityIdentifier(NoticeDetailAccessibilityIdentifier.title)

                Text(notice.createdAt)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.dynamic(light: FillsaColor.gray400, dark: FillsaColor.gray200))
                    .padding(.top, 10)
                    .accessibilityIdentifier(NoticeDetailAccessibilityIdentifier.date)

                Divider()
                    .background(FillsaColor.gray200)
                    .padding(.top, 10)

                Text(notice.content)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .padding(.top, 20)
                    .accessibilityIdentifier(NoticeDetailAccessibilityIdentifier.content)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .background(FillsaColor.dynamic(light: FillsaColor.yellow01, dark: FillsaColor.gray600))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background.ignoresSafeArea())
    }
}

private enum NoticeDetailAccessibilityIdentifier {
    static let title = "noticeDetail.title"
    static let date = "noticeDetail.date"
    static let content = "noticeDetail.content"
}

#Preview {
    NoticeDetailView(notice: NoticeSampleData.items[0], back: {})
}
