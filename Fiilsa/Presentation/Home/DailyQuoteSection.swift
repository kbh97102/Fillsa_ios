//
//  DailyQuoteSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import Foundation
import SwiftUI

struct DailyQuoteSection: View {
    let text: String
    let author: String
    let date: Date
    let next: () -> Void
    let before: () -> Void
    let navigate: () -> Void
    let authorTapped: () -> Void

    private let cardAspectRatio: CGFloat = 320 / 250
    private let cornerRadius: CGFloat = 12

    init(
        text: String,
        author: String,
        date: Date = Date(),
        next: @escaping () -> Void = {},
        before: @escaping () -> Void = {},
        navigate: @escaping () -> Void = {},
        authorTapped: @escaping () -> Void = {}
    ) {
        self.text = text
        self.author = author
        self.date = date
        self.next = next
        self.before = before
        self.navigate = navigate
        self.authorTapped = authorTapped
    }

    var body: some View {
        ZStack {
            Button(action: navigate) {
                ZStack {
                    FillsaColor.yellow01

                    NotebookLineBackground()
                        .foregroundStyle(FillsaColor.purple02.opacity(0.6))

                    VStack(spacing: 12) {
                        Text(text)
                            .font(FillsaTypography.quote)
                            .foregroundStyle(FillsaColor.gray700)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Button(action: authorTapped) {
                            Text(author)
                                .font(FillsaTypography.quote)
                                .foregroundStyle(FillsaColor.gray700)
                                .underline()
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: Color(hex: 0xCBC0A8).opacity(0.7), radius: 3)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 150 {
                            before()
                        } else if value.translation.width < -150 {
                            next()
                        }
                    }
            )

            if displayBeforeButton {
                HStack {
                    ArrowCircleButton(direction: .left, action: before)
                        .offset(x: -16)
                    Spacer()
                }
            }

            if displayNextButton {
                HStack {
                    Spacer()
                    ArrowCircleButton(direction: .right, action: next)
                        .offset(x: 16)
                }
            }
        }
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private var displayBeforeButton: Bool {
        let startDay = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 10)) ?? Date()
        return Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: startDay)
    }

    private var displayNextButton: Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
}

private struct NotebookLineBackground: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let scaleY = size.height / 247

            for y in stride(from: 0.0, through: 246.0, by: 20.5) {
                let scaledY = y * scaleY
                path.move(to: CGPoint(x: 0, y: scaledY))
                path.addLine(to: CGPoint(x: size.width, y: scaledY))
            }

            context.stroke(path, with: .foreground, lineWidth: 0.5)
        }
    }
}

private enum ArrowDirection {
    case left
    case right
}

private struct ArrowCircleButton: View {
    let direction: ArrowDirection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(FillsaColor.purple02)

                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(FillsaColor.purple01)
                    .rotationEffect(direction == .right ? .degrees(180) : .degrees(0))
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DailyQuoteSection(
        text: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        author: "jone wooden"
    )
    .padding(20)
    .background(FillsaColor.background)
    .previewLayout(.sizeThatFits)
}
