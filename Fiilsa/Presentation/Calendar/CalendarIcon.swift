//
//  CalendarIcon.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

enum CalendarIconKind {
    case note
    case heart
    case flame
}

struct CalendarIcon: View {
    let kind: CalendarIconKind
    var color: Color = FillsaColor.purple01

    var body: some View {
        Canvas { context, size in
            switch kind {
            case .note:
                context.scaleBy(x: size.width / 16, y: size.height / 17)
                context.fill(notePath, with: .color(color))
            case .heart:
                context.scaleBy(x: size.width / 24, y: size.height / 24)
                context.fill(heartPath, with: .color(Color(hex: 0xFF3434)))
            case .flame:
                context.scaleBy(x: size.width / 12, y: size.height / 12)
                context.fill(flamePath, with: .color(Color(hex: 0xFF0000)))
            }
        }
    }

    private var notePath: Path {
        var path = Path()
        path.move(to: CGPoint(x: 2, y: 12.9))
        path.addLine(to: CGPoint(x: 2, y: 4.08))
        path.addCurve(to: CGPoint(x: 3.62, y: 2.5), control1: CGPoint(x: 2, y: 3.2), control2: CGPoint(x: 2.74, y: 2.5))
        path.addLine(to: CGPoint(x: 12.4, y: 2.5))
        path.addCurve(to: CGPoint(x: 14, y: 4.1), control1: CGPoint(x: 13.28, y: 2.5), control2: CGPoint(x: 14, y: 3.22))
        path.addLine(to: CGPoint(x: 14, y: 9.84))
        path.addCurve(to: CGPoint(x: 13.54, y: 10.96), control1: CGPoint(x: 14, y: 10.28), control2: CGPoint(x: 13.84, y: 10.66))
        path.addLine(to: CGPoint(x: 10.46, y: 14.04))
        path.addCurve(to: CGPoint(x: 9.34, y: 14.5), control1: CGPoint(x: 10.16, y: 14.34), control2: CGPoint(x: 9.78, y: 14.5))
        path.addLine(to: CGPoint(x: 3.6, y: 14.5))
        path.addCurve(to: CGPoint(x: 2, y: 12.9), control1: CGPoint(x: 2.72, y: 14.5), control2: CGPoint(x: 2, y: 13.78))
        path.closeSubpath()
        path.move(to: CGPoint(x: 12.4, y: 9.7))
        path.addLine(to: CGPoint(x: 10, y: 9.7))
        path.addCurve(to: CGPoint(x: 9.2, y: 10.5), control1: CGPoint(x: 9.56, y: 9.7), control2: CGPoint(x: 9.2, y: 10.06))
        path.addLine(to: CGPoint(x: 9.2, y: 12.9))
        path.closeSubpath()
        return path
    }

    private var heartPath: Path {
        var path = Path()
        path.move(to: CGPoint(x: 12.001, y: 4.529))
        path.addCurve(to: CGPoint(x: 20.243, y: 4.757), control1: CGPoint(x: 13.144, y: 3.507), control2: CGPoint(x: 17.7, y: 3.045))
        path.addCurve(to: CGPoint(x: 20.479, y: 12.993), control1: CGPoint(x: 22.042, y: 6.556), control2: CGPoint(x: 22.042, y: 10.359))
        path.addLine(to: CGPoint(x: 11.999, y: 21.485))
        path.addLine(to: CGPoint(x: 3.521, y: 12.993))
        path.addCurve(to: CGPoint(x: 3.759, y: 4.752), control1: CGPoint(x: 1.956, y: 10.358), control2: CGPoint(x: 2.045, y: 7.292))
        path.addCurve(to: CGPoint(x: 12.001, y: 4.529), control1: CGPoint(x: 5.474, y: 3.039), control2: CGPoint(x: 10.859, y: 3.506))
        path.closeSubpath()
        return path
    }

    private var flamePath: Path {
        var path = Path()
        path.move(to: CGPoint(x: 6.521, y: 1.437))
        path.addCurve(to: CGPoint(x: 9.85, y: 6.555), control1: CGPoint(x: 7.969, y: 2.267), control2: CGPoint(x: 9.849, y: 3.989))
        path.addCurve(to: CGPoint(x: 7.241, y: 10.503), control1: CGPoint(x: 9.85, y: 8.6), control2: CGPoint(x: 8.74, y: 9.98))
        path.addCurve(to: CGPoint(x: 7.65, y: 9.222), control1: CGPoint(x: 7.5, y: 10.17), control2: CGPoint(x: 7.65, y: 9.763))
        path.addCurve(to: CGPoint(x: 6.846, y: 7.856), control1: CGPoint(x: 7.65, y: 8.501), control2: CGPoint(x: 7.193, y: 8.059))
        path.addCurve(to: CGPoint(x: 6.399, y: 8.102), control1: CGPoint(x: 6.61, y: 7.78), control2: CGPoint(x: 6.43, y: 7.92))
        path.addCurve(to: CGPoint(x: 6.056, y: 8.388), control1: CGPoint(x: 6.38, y: 8.24), control2: CGPoint(x: 6.22, y: 8.55))
        path.addCurve(to: CGPoint(x: 5.797, y: 7.667), control1: CGPoint(x: 5.877, y: 8.181), control2: CGPoint(x: 5.797, y: 7.865))
        path.addLine(to: CGPoint(x: 5.797, y: 7.373))
        path.addCurve(to: CGPoint(x: 5.239, y: 7.038), control1: CGPoint(x: 5.797, y: 7.097), control2: CGPoint(x: 5.507, y: 6.88))
        path.addCurve(to: CGPoint(x: 3.85, y: 9.222), control1: CGPoint(x: 4.654, y: 7.387), control2: CGPoint(x: 3.85, y: 8.118))
        path.addCurve(to: CGPoint(x: 4.557, y: 10.724), control1: CGPoint(x: 3.85, y: 9.924), control2: CGPoint(x: 4.136, y: 10.396))
        path.addCurve(to: CGPoint(x: 1.65, y: 6.555), control1: CGPoint(x: 3.1, y: 10.37), control2: CGPoint(x: 1.65, y: 9.1))
        path.addCurve(to: CGPoint(x: 3.021, y: 3.817), control1: CGPoint(x: 1.65, y: 5.224), control2: CGPoint(x: 2.347, y: 4.329))
        path.addCurve(to: CGPoint(x: 3.716, y: 4.199), control1: CGPoint(x: 3.32, y: 3.59), control2: CGPoint(x: 3.68, y: 3.85))
        path.addLine(to: CGPoint(x: 3.759, y: 4.618))
        path.addCurve(to: CGPoint(x: 4.937, y: 5.376), control1: CGPoint(x: 3.84, y: 5.36), control2: CGPoint(x: 4.36, y: 5.75))
        path.addCurve(to: CGPoint(x: 6.15, y: 2.667), control1: CGPoint(x: 5.83, y: 4.8), control2: CGPoint(x: 6.15, y: 3.36))
        path.addLine(to: CGPoint(x: 6.15, y: 1.752))
        path.addCurve(to: CGPoint(x: 6.521, y: 1.437), control1: CGPoint(x: 6.15, y: 1.527), control2: CGPoint(x: 6.342, y: 1.391))
        path.closeSubpath()
        return path
    }
}
