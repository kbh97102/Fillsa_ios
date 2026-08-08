import ComposableArchitecture
import Testing
@testable import Fiilsa

@MainActor
struct QuoteListFeatureTests {
    @Test
    func initialEmptyResponseUsesGeneralEmptyState() async {
        let store = TestStore(initialState: QuoteListFeature.State()) {
            QuoteListFeature()
        }

        await store.send(.quotesLoaded(.success(emptyResponse))) {
            $0.hasLoaded = true
        }

        #expect(store.state.emptyState == .general)
    }

    @Test
    func filteredEmptyResponseUsesSearchResultEmptyState() async {
        var initialState = QuoteListFeature.State()
        initialState.hasAppliedSearchCondition = true
        let store = TestStore(initialState: initialState) {
            QuoteListFeature()
        }

        await store.send(.quotesLoaded(.success(emptyResponse))) {
            $0.hasLoaded = true
        }

        #expect(store.state.emptyState == .searchResult)
    }

    private var emptyResponse: PageResponseMemberQuotesResponse {
        PageResponseMemberQuotesResponse(
            content: [],
            totalElements: 0,
            totalPages: 0,
            currentPage: 0
        )
    }
}
