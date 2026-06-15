//
//  OnboardingGuideImageSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct OnboardingGuideImageSection: View {
    @Binding var currentPage: Int

    var body: some View {
        TabView(selection: $currentPage) {
            GuidePhoneMock(page: .home)
                .tag(0)

            GuidePhoneMock(page: .list)
                .tag(1)

            GuidePhoneMock(page: .calendar)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

private enum GuidePage {
    case home
    case list
    case calendar
}

private struct GuidePhoneMock: View {
    let page: GuidePage

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width, proxy.size.height * 0.8)

            VStack(spacing: 0) {
                guideContent
            }
            .frame(width: width, height: width * 1.25)
            .background(FillsaColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.vertical, 18)
    }

    @ViewBuilder
    private var guideContent: some View {
        switch page {
        case .home:
            homeGuide
        case .list:
            listGuide
        case .calendar:
            calendarGuide
        }
    }

    private var homeGuide: some View {
        VStack(spacing: 16) {
            topBar

            HStack(spacing: 10) {
                guideDateCard

                guideImageCard
            }
            .frame(maxHeight: 110)

            guideQuoteCard

            Spacer()

            guideBottomBar(selectedIndex: 0)
        }
        .padding(10)
    }

    private var listGuide: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(FillsaColor.white.opacity(0.6))
                .overlay {
                    VStack(spacing: 8) {
                        guideDateFilter
                        guideLikeFilter
                    }
                    .padding(8)
                }
                .frame(height: 90)

            VStack(spacing: 8) {
                guideListItem("인생은 가까이서 보면 비극...")
                guideListItem("The future depends on...")
                guideListItem("모든 순간은 새로운 시작...")
            }

            Spacer()

            guideBottomBar(selectedIndex: 1)
        }
        .padding(10)
    }

    private var calendarGuide: some View {
        VStack(spacing: 12) {
            guideCalendarCard
                .frame(height: 210)

            guideCalendarCount

            Spacer()

            guideBottomBar(selectedIndex: 2)
        }
        .padding(10)
    }

    private var guideDateCard: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(FillsaColor.white)
            .overlay {
                VStack(spacing: 0) {
                    HStack {
                        Text("2025.03")
                        Spacer()
                        Text("수요일")
                    }
                    .font(FillsaTypography.body4)
                    .foregroundStyle(FillsaColor.gray700)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                            .fill(FillsaColor.purple02)
                    )

                    Text("25")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(FillsaColor.gray700)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }

    private var guideImageCard: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0x6B77FF), Color(hex: 0xE6C3D6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(FillsaColor.purple01)
                    .frame(width: 48, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FillsaColor.purple02)
                    )
            }
    }

    private var guideQuoteCard: some View {
        VStack(spacing: 10) {
            Text("Be yourself; everyone else is already taken.")
                .font(FillsaTypography.quote)
                .foregroundStyle(FillsaColor.gray700)
                .multilineTextAlignment(.center)

            Text("Oscar Wilde")
                .font(FillsaTypography.body4)
                .foregroundStyle(FillsaColor.gray500)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FillsaColor.white.opacity(0.6))
        )
    }

    private var guideDateFilter: some View {
        HStack {
            Text("2025.03.01")
            Spacer()
            Text("~")
            Spacer()
            Text("2025.03.31")
        }
        .font(FillsaTypography.body4)
        .foregroundStyle(FillsaColor.gray700)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FillsaColor.white)
        )
    }

    private var guideLikeFilter: some View {
        HStack(spacing: 8) {
            guideChip("전체", isSelected: true)
            guideChip("좋아요", isSelected: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func guideChip(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(FillsaTypography.body4)
            .foregroundStyle(isSelected ? FillsaColor.white : FillsaColor.gray700)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? FillsaColor.purple01 : FillsaColor.white)
            )
    }

    private var guideCalendarCount: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 4) {
                Text("필사")
                    .font(FillsaTypography.body4)
                Text("100")
                    .font(FillsaTypography.subtitle1)
            }

            VStack(alignment: .trailing, spacing: 4) {
                Text("좋아요")
                    .font(FillsaTypography.body4)
                Text("25")
                    .font(FillsaTypography.subtitle1)
            }
        }
        .foregroundStyle(FillsaColor.gray700)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var guideCalendarCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                Text("2025.03")
                    .font(FillsaTypography.subtitle2)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(FillsaColor.gray700)

            HStack {
                ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                    Text(day)
                        .font(FillsaTypography.body4)
                        .foregroundStyle(FillsaColor.gray500)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(1...35, id: \.self) { index in
                    let day = index <= 31 ? "\(index)" : ""

                    Text(day)
                        .font(FillsaTypography.body4)
                        .foregroundStyle(index == 25 ? FillsaColor.white : FillsaColor.gray700)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(index == 25 ? FillsaColor.purple01 : Color.clear)
                        )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FillsaColor.white.opacity(0.6))
        )
    }

    private var topBar: some View {
        HStack {
            Image("icn_top_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 38)

            Spacer()

            Image(systemName: "flame.fill")
                .foregroundStyle(.red)

            Text("100일")
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(FillsaColor.gray700)
        }
    }

    private func guideListItem(_ text: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(FillsaColor.white)
            .overlay {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(text)
                            .font(FillsaTypography.body3)
                            .foregroundStyle(FillsaColor.gray700)
                            .lineLimit(1)

                        Text("2025.03.25")
                            .font(FillsaTypography.body4)
                            .foregroundStyle(FillsaColor.gray500)
                    }

                    Spacer()

                    Circle()
                        .fill(FillsaColor.yellow02)
                        .frame(width: 6, height: 6)
                }
                .padding(12)
            }
            .frame(height: 58)
    }

    private func guideBottomBar(selectedIndex: Int) -> some View {
        HStack(spacing: 0) {
            guideTab(systemName: "house.fill", title: "Home", isSelected: selectedIndex == 0)
            guideTab(systemName: "doc.text.fill", title: "List", isSelected: selectedIndex == 1)
            guideTab(systemName: "calendar", title: "Calendar", isSelected: selectedIndex == 2)
            guideTab(systemName: "person.fill", title: "My page", isSelected: selectedIndex == 3)
        }
        .padding(.vertical, 6)
    }

    private func guideTab(systemName: String, title: String, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))

            Text(title)
                .font(.system(size: 9))
        }
        .foregroundStyle(isSelected ? FillsaColor.purple01 : FillsaColor.gray700)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var currentPage = 0

    OnboardingGuideImageSection(currentPage: $currentPage)
        .frame(height: 440)
        .background(FillsaColor.background)
}
