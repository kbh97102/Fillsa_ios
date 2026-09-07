import SwiftUI

/// Figma `2929:19015` / `2929:19016` zero-streak guidance.
struct HomeStreakTooltip: View {
    let openCalendar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("연속 필사를 완료해 주세요!")
                .font(FillsaTypography.subtitle2)
                .foregroundStyle(FillsaColor.white)

            Button(action: openCalendar) {
                Text("나의 필사현황 보기")
                    .font(FillsaTypography.body4)
                    .foregroundStyle(Color(hex: 0xFFE9A8))
                    .underline()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 231, height: 68, alignment: .leading)
        .background(FillsaColor.gray700)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            Triangle()
                .fill(FillsaColor.gray700)
                .frame(width: 21, height: 18)
                .offset(x: -31, y: -9)
        }
        .accessibilityIdentifier("home.streakTooltip")
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
