import SwiftUI

struct FillsaBottomNavigationBar: View {
    let selectedTab: AppTab
    let select: (AppTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                BottomNavigationItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    select: {
                        select(tab)
                    }
                )
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(FillsaColor.background)
    }
}

private struct BottomNavigationItem: View {
    let tab: AppTab
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImageName)
                    .font(.system(size: 22, weight: .regular))

                Text(tab.title)
                    .font(FillsaTypography.body4)
            }
            .foregroundStyle(isSelected ? FillsaColor.purple01 : FillsaColor.gray700)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension AppTab {
    var systemImageName: String {
        switch self {
        case .home:
            "house.fill"
        case .quoteList:
            "list.bullet"
        case .calendar:
            "calendar"
        case .myPage:
            "person.fill"
        }
    }
}

#Preview {
    FillsaBottomNavigationBar(selectedTab: .home, select: { _ in })
        .background(FillsaColor.background)
}
