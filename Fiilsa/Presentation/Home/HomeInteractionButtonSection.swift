//
//  HomeInteractionButtonSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct HomeInteractionButtonSection: View {
    let copy: () -> Void
    let share: () -> Void
    let isLike: Bool
    let setIsLike: (Bool) -> Void

    init(
        copy: @escaping () -> Void = {},
        share: @escaping () -> Void = {},
        isLike: Bool,
        setIsLike: @escaping (Bool) -> Void = { _ in }
    ) {
        self.copy = copy
        self.share = share
        self.isLike = isLike
        self.setIsLike = setIsLike
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: copy) {
                CopyActionIcon()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Button(action: share) {
                ShareActionIcon()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)

            Button {
                setIsLike(!isLike)
            } label: {
                HeartActionIcon(isFilled: isLike)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CopyActionIcon: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 24, y: size.height / 24)

            context.stroke(
                Path(roundedRect: CGRect(x: 2.4, y: 2.4, width: 13.77, height: 13.77), cornerRadius: 2.35),
                with: .color(FillsaColor.gray700),
                lineWidth: 1.1
            )
            context.fill(
                Path(roundedRect: CGRect(x: 7.834, y: 7.834, width: 13.766, height: 13.766), cornerRadius: 2.35),
                with: .color(FillsaColor.gray700)
            )
            context.fill(
                Path(roundedRect: CGRect(x: 8.921, y: 8.921, width: 11.592, height: 11.592), cornerRadius: 1.27),
                with: .color(FillsaColor.background)
            )
        }
    }
}

private struct ShareActionIcon: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 24, y: size.height / 24)

            var linePath = Path()
            linePath.move(to: CGPoint(x: 8.713, y: 9.591))
            linePath.addLine(to: CGPoint(x: 14.287, y: 6.091))
            linePath.move(to: CGPoint(x: 8.713, y: 14.409))
            linePath.addLine(to: CGPoint(x: 14.287, y: 17.909))

            context.stroke(linePath, with: .color(FillsaColor.gray700), lineWidth: 1)
            context.stroke(Path(ellipseIn: CGRect(x: 4, y: 9.5, width: 5, height: 5)), with: .color(FillsaColor.gray700), lineWidth: 1)
            context.stroke(Path(ellipseIn: CGRect(x: 14, y: 3, width: 5, height: 5)), with: .color(FillsaColor.gray700), lineWidth: 1)
            context.stroke(Path(ellipseIn: CGRect(x: 14, y: 16, width: 5, height: 5)), with: .color(FillsaColor.gray700), lineWidth: 1)
        }
    }
}

private struct HeartActionIcon: View {
    let isFilled: Bool

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 24, y: size.height / 24)

            if isFilled {
                context.fill(heartPath, with: .color(Color(hex: 0xFF3434)))
            } else {
                context.stroke(heartPath, with: .color(FillsaColor.gray700), lineWidth: 1.2)
            }
        }
    }

    private var heartPath: Path {
        var path = Path()
        path.move(to: CGPoint(x: 11.5, y: 20.92))
        path.addLine(to: CGPoint(x: 3.54, y: 12.96))
        path.addCurve(to: CGPoint(x: 2, y: 9.25), control1: CGPoint(x: 2.59, y: 12), control2: CGPoint(x: 2, y: 10.7))
        path.addCurve(to: CGPoint(x: 7.25, y: 4), control1: CGPoint(x: 2, y: 6.35), control2: CGPoint(x: 4.35, y: 4))
        path.addCurve(to: CGPoint(x: 11.5, y: 6.17), control1: CGPoint(x: 9, y: 4), control2: CGPoint(x: 10.55, y: 4.85))
        path.addCurve(to: CGPoint(x: 15.75, y: 4), control1: CGPoint(x: 12.45, y: 4.85), control2: CGPoint(x: 14, y: 4))
        path.addCurve(to: CGPoint(x: 21, y: 9.25), control1: CGPoint(x: 18.65, y: 4), control2: CGPoint(x: 21, y: 6.35))
        path.addCurve(to: CGPoint(x: 19.46, y: 12.96), control1: CGPoint(x: 21, y: 10.7), control2: CGPoint(x: 20.41, y: 12))
        path.closeSubpath()
        return path
    }
}

#Preview {
    HomeInteractionButtonSection(isLike: false)
        .padding()
        .previewLayout(.sizeThatFits)
}
