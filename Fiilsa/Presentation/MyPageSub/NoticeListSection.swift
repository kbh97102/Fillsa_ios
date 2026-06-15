import SwiftUI

struct NoticeListSection: View {
    let items: [NoticeResponse]
    let select: (NoticeResponse) -> Void

    var body: some View {
        if items.isEmpty {
            EmptyNoticeSection()
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items) { notice in
                        NoticeItem(notice: notice) {
                            select(notice)
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
    }
}

private struct NoticeItem: View {
    let notice: NoticeResponse
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 10) {
                Text(notice.createdAt)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray400)

                Text(notice.title)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(FillsaColor.gray200)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyNoticeSection: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(FillsaColor.purple01)

            Text("공지사항이 없습니다.")
                .font(FillsaTypography.heading4)
                .foregroundStyle(FillsaColor.gray700)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background)
    }
}

#Preview {
    NoticeListSection(items: NoticeSampleData.items, select: { _ in })
        .padding(.horizontal, 20)
        .background(FillsaColor.background)
}
