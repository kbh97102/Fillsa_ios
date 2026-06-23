//
//  QuoteListSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListSection: View {
    let list: [MemberQuotesResponse]
    let onClick: (MemberQuotesResponse) -> Void
    let loadMore: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
    ]

    var body: some View {
        if list.isEmpty {
            QuoteListEmptySection()
        } else {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(list) { item in
                        QuoteListItem(data: item)
                            .aspectRatio(150 / 162, contentMode: .fit)
                            .onTapGesture {
                                onClick(item)
                            }
                            .onAppear {
                                if item.id == list.last?.id {
                                    loadMore()
                                }
                            }
                    }
                }
                .padding(.top, 10)
            }
        }
    }
}

#Preview {
    QuoteListSection(list: QuoteListSampleData.items, onClick: { _ in }, loadMore: {})
        .padding()
        .background(FillsaColor.background)
}
