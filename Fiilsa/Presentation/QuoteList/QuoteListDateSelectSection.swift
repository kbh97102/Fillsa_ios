//
//  QuoteListDateSelectSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListDateSelectSection: View {
    let startDate: Date
    let endDate: Date
    let isCalendarDisplayed: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 0) {
                CalendarSelectIcon()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(isCalendarDisplayed ? FillsaColor.purple01 : FillsaColor.gray700)

                Text("\(QuoteListDateSupport.displayDate(startDate)) - \(QuoteListDateSupport.displayDate(endDate))")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.gray700)
                    .padding(.leading, 10)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .rotationEffect(isCalendarDisplayed ? .degrees(180) : .degrees(0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FillsaColor.yellow01)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CalendarSelectIcon: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 20, y: size.height / 20)
            context.fill(path, with: .foreground)
        }
    }

    private var path: Path {
        var path = Path()
        path.move(to: CGPoint(x: 3, y: 14.9))
        path.addCurve(to: CGPoint(x: 5.1, y: 17), control1: CGPoint(x: 3, y: 16.09), control2: CGPoint(x: 3.91, y: 17))
        path.addLine(to: CGPoint(x: 14.9, y: 17))
        path.addCurve(to: CGPoint(x: 17, y: 14.9), control1: CGPoint(x: 16.09, y: 17), control2: CGPoint(x: 17, y: 16.09))
        path.addLine(to: CGPoint(x: 17, y: 9.3))
        path.addLine(to: CGPoint(x: 3, y: 9.3))
        path.closeSubpath()
        path.move(to: CGPoint(x: 14.9, y: 4.4))
        path.addLine(to: CGPoint(x: 13.5, y: 4.4))
        path.addLine(to: CGPoint(x: 13.5, y: 3.7))
        path.addCurve(to: CGPoint(x: 12.1, y: 3.7), control1: CGPoint(x: 13.5, y: 2.77), control2: CGPoint(x: 12.1, y: 2.77))
        path.addLine(to: CGPoint(x: 12.1, y: 4.4))
        path.addLine(to: CGPoint(x: 7.9, y: 4.4))
        path.addLine(to: CGPoint(x: 7.9, y: 3.7))
        path.addCurve(to: CGPoint(x: 6.5, y: 3.7), control1: CGPoint(x: 7.9, y: 2.77), control2: CGPoint(x: 6.5, y: 2.77))
        path.addLine(to: CGPoint(x: 6.5, y: 4.4))
        path.addLine(to: CGPoint(x: 5.1, y: 4.4))
        path.addCurve(to: CGPoint(x: 3, y: 6.5), control1: CGPoint(x: 3.91, y: 4.4), control2: CGPoint(x: 3, y: 5.31))
        path.addLine(to: CGPoint(x: 3, y: 7.9))
        path.addLine(to: CGPoint(x: 17, y: 7.9))
        path.addLine(to: CGPoint(x: 17, y: 6.5))
        path.addCurve(to: CGPoint(x: 14.9, y: 4.4), control1: CGPoint(x: 17, y: 5.31), control2: CGPoint(x: 16.09, y: 4.4))
        path.closeSubpath()
        return path
    }
}

#Preview {
    QuoteListDateSelectSection(
        startDate: Date(),
        endDate: Date(),
        isCalendarDisplayed: false,
        onClick: {}
    )
    .padding()
    .background(FillsaColor.background)
}
