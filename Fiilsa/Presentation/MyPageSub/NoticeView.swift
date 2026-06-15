import SwiftUI

struct NoticeView: View {
    let items: [NoticeResponse]
    let back: () -> Void
    let select: (NoticeResponse) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HeaderSection(title: "공지사항", back: back)
                .background(FillsaColor.background)

            NoticeListSection(items: items, select: select)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background.ignoresSafeArea())
    }
}

#Preview {
    NoticeView(
        items: NoticeSampleData.items,
        back: {},
        select: { _ in }
    )
}
