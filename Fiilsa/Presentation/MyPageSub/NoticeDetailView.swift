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
                    .foregroundStyle(FillsaColor.gray700)
                    .padding(.top, 16)

                Text(notice.createdAt)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray400)
                    .padding(.top, 10)

                Divider()
                    .background(FillsaColor.gray200)
                    .padding(.top, 10)

                Text(notice.content)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray700)
                    .padding(.top, 20)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background.ignoresSafeArea())
    }
}

#Preview {
    NoticeDetailView(notice: NoticeSampleData.items[0], back: {})
}
