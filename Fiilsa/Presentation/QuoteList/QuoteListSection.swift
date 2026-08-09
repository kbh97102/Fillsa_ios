//
//  QuoteListSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListSection: View {
    let list: [MemberQuotesResponse]
    let emptyState: QuoteListFeature.EmptyState?
    let onClick: (MemberQuotesResponse) -> Void
    let loadMore: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
    ]

    var body: some View {
        if let emptyState {
            QuoteListEmptySection(emptyState: emptyState)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(list) { item in
                        QuoteListItem(data: item)
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
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    QuoteListSection(list: QuoteListSampleData.items, emptyState: nil, onClick: { _ in }, loadMore: {})
        .padding()
        .background(FillsaColor.background)
}
