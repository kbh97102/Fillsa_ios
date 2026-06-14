//
//  HomeImageSection.swift
//  Fiilsa
//
//  Created by Codex on 6/14/26.
//

import SwiftUI

struct HomeImageSection: View {
    let imageUri: String
    let isLogged: Bool
    let onClick: () -> Void

    private let cardAspectRatio: CGFloat = 155 / 120
    private let cornerRadius: CGFloat = 12

    init(
        imageUri: String = "",
        isLogged: Bool = false,
        onClick: @escaping () -> Void = {}
    ) {
        self.imageUri = imageUri
        self.isLogged = isLogged
        self.onClick = onClick
    }

    var body: some View {
        Button(action: onClick) {
            ZStack {
                imageContent

                if !isLogged {
                    FillsaColor.black0C
                        .opacity(0.6)

                    LockIcon()
                        .frame(width: 40, height: 40)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var imageContent: some View {
        if imageUri.isEmpty {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0xFEFED6), location: 0),
                    .init(color: Color(hex: 0xE6B5C1), location: 0.49),
                    .init(color: Color(hex: 0xC990CE), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if let url = URL(string: imageUri) {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: 0xFEFED6), location: 0),
                            .init(color: Color(hex: 0xE6B5C1), location: 0.49),
                            .init(color: Color(hex: 0xC990CE), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
    }
}

private struct LockIcon: View {
    var body: some View {
        Canvas { context, size in
            let scaleX = size.width / 40
            let scaleY = size.height / 40

            context.scaleBy(x: scaleX, y: scaleY)
            context.fill(lockBodyPath, with: .color(FillsaColor.purple02))
            context.fill(lockDetailPath, with: .color(FillsaColor.purple01))
        }
    }

    private var lockBodyPath: Path {
        var path = Path()
        path.move(to: CGPoint(x: 3.333, y: 28.334))
        path.addCurve(to: CGPoint(x: 4.799, y: 18.376), control1: CGPoint(x: 3.333, y: 22.835), control2: CGPoint(x: 3.333, y: 20.083))
        path.addCurve(to: CGPoint(x: 13.333, y: 16.667), control1: CGPoint(x: 6.262, y: 16.667), control2: CGPoint(x: 8.62, y: 16.667))
        path.addLine(to: CGPoint(x: 26.667, y: 16.667))
        path.addCurve(to: CGPoint(x: 35.202, y: 18.376), control1: CGPoint(x: 31.38, y: 16.667), control2: CGPoint(x: 33.738, y: 16.667))
        path.addCurve(to: CGPoint(x: 36.667, y: 28.334), control1: CGPoint(x: 36.667, y: 20.083), control2: CGPoint(x: 36.667, y: 22.835))
        path.addCurve(to: CGPoint(x: 35.202, y: 38.291), control1: CGPoint(x: 36.667, y: 33.833), control2: CGPoint(x: 36.667, y: 36.584))
        path.addCurve(to: CGPoint(x: 26.667, y: 40), control1: CGPoint(x: 33.738, y: 40), control2: CGPoint(x: 31.38, y: 40))
        path.addLine(to: CGPoint(x: 13.333, y: 40))
        path.addCurve(to: CGPoint(x: 4.799, y: 38.291), control1: CGPoint(x: 8.62, y: 40), control2: CGPoint(x: 6.262, y: 40))
        path.addCurve(to: CGPoint(x: 3.333, y: 28.334), control1: CGPoint(x: 3.333, y: 36.584), control2: CGPoint(x: 3.333, y: 33.833))
        path.closeSubpath()
        return path
    }

    private var lockDetailPath: Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 16.667, y: 25, width: 6.666, height: 6.666))
        path.move(to: CGPoint(x: 11.25, y: 13.333))
        path.addCurve(to: CGPoint(x: 13.813, y: 7.146), control1: CGPoint(x: 11.25, y: 11.012), control2: CGPoint(x: 12.172, y: 8.787))
        path.addCurve(to: CGPoint(x: 20, y: 4.583), control1: CGPoint(x: 15.454, y: 5.505), control2: CGPoint(x: 17.679, y: 4.583))
        path.addCurve(to: CGPoint(x: 28.75, y: 13.333), control1: CGPoint(x: 24.833, y: 4.583), control2: CGPoint(x: 28.75, y: 8.5))
        path.addLine(to: CGPoint(x: 28.75, y: 16.673))
        path.addCurve(to: CGPoint(x: 31.25, y: 16.756), control1: CGPoint(x: 29.695, y: 16.681), control2: CGPoint(x: 30.523, y: 16.703))
        path.addLine(to: CGPoint(x: 31.25, y: 13.333))
        path.addCurve(to: CGPoint(x: 20, y: 2.083), control1: CGPoint(x: 31.25, y: 7.12), control2: CGPoint(x: 26.213, y: 2.083))
        path.addCurve(to: CGPoint(x: 8.75, y: 13.333), control1: CGPoint(x: 13.787, y: 2.083), control2: CGPoint(x: 8.75, y: 7.12))
        path.addLine(to: CGPoint(x: 8.75, y: 16.758))
        path.addCurve(to: CGPoint(x: 11.25, y: 16.673), control1: CGPoint(x: 9.582, y: 16.704), control2: CGPoint(x: 10.416, y: 16.675))
        path.addLine(to: CGPoint(x: 11.25, y: 13.333))
        path.closeSubpath()
        return path
    }
}

#Preview {
    HomeImageSection()
        .padding(24)
        .previewLayout(.sizeThatFits)
}
