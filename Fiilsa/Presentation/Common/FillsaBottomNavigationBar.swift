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
        .frame(height: 60)
        .background(FillsaColor.background)
        .accessibilityIdentifier(FillsaAccessibilityIdentifier.bottomNavigation)
    }
}

private struct BottomNavigationItem: View {
    let tab: AppTab
    let isSelected: Bool
    let select: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: select) {
            VStack(spacing: 2) {
                navigationIcon

                Text(tab.title)
                    .font(FillsaTypography.body4)
            }
            .foregroundStyle(navigationForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var navigationIcon: some View {
        if colorScheme == .dark {
            Image(tab.darkFigmaAssetName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        } else if let assetName = tab.lightFigmaAssetName {
            Image(assetName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        } else {
            Image(systemName: tab.systemImageName)
                .font(.system(size: 24, weight: .regular))
                .frame(width: 32, height: 32)
        }
    }

    private var navigationForeground: Color {
        if colorScheme == .dark {
            return isSelected ? FillsaColor.white : FillsaColor.gray400
        }
        return isSelected ? FillsaColor.onBackground2 : FillsaColor.onBackground1
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

    var darkFigmaAssetName: String {
        switch self {
        case .home:
            "icn_nav_dark_home"
        case .quoteList:
            "icn_nav_dark_list"
        case .calendar:
            "icn_nav_dark_calendar"
        case .myPage:
            "icn_nav_dark_mypage"
        }
    }

    var lightFigmaAssetName: String? {
        switch self {
        case .home:
            "home_nav_home"
        case .quoteList:
            nil
        case .calendar:
            "home_nav_calendar"
        case .myPage:
            "home_nav_mypage"
        }
    }
}

#Preview {
    FillsaBottomNavigationBar(selectedTab: .home, select: { _ in })
        .background(FillsaColor.background)
}
