import SwiftUI

enum TypingSaveResult: String, Equatable {
    case encouragement, completed, streak, incomplete

    var assetName: String {
        self == .encouragement ? "completed" : rawValue
    }

    var title: String {
        switch self {
        case .encouragement: "오늘도 이어서 필사를 해주세요!"
        case .completed: "필사 완료!"
        case .streak: "연속 필사 완료!"
        case .incomplete: "필사가 완료되지 않았어요."
        }
    }
}

/// Figma light 2988:23906/23962/24015; dark 2929:9801/9844/9884.
struct TypingResultPopup: View {
    let result: TypingSaveResult
    let confirm: () -> Void
    let cancel: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            FillsaColor.gray700.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 0) {
                Image("typing_result_\(result.assetName)_\(colorScheme == .dark ? "dark" : "light")")
                    .resizable().scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 20)
                    .accessibilityHidden(true)
                Text(result.title)
                    .font(FillsaTypography.heading4)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .frame(height: 30)
                HStack(spacing: 12) {
                    if result == .incomplete {
                        Button(action: cancel) {
                            Text("취소")
                                .frame(maxWidth: .infinity)
                                .frame(height: 49)
                                .foregroundStyle(colorScheme == .dark ? FillsaColor.purple01 : FillsaColor.gray700)
                                .background(.white, in: RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(colorScheme == .dark ? FillsaColor.purple01 : FillsaColor.gray700, lineWidth: 1)
                                }
                        }
                    }
                    Button(action: confirm) {
                        Text(result == .incomplete ? "필사하기" : "확인")
                            .frame(maxWidth: .infinity)
                            .frame(height: 49)
                            .foregroundStyle(colorScheme == .dark ? .white : FillsaColor.gray700)
                            .background(colorScheme == .dark ? FillsaColor.purple01 : FillsaColor.yellow02,
                                        in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .font(FillsaTypography.subtitle1)
                .buttonStyle(.plain)
                .padding(12)
            }
            .padding(.vertical, colorScheme == .dark ? 1 : 0)
            .frame(width: 320)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? FillsaColor.gray600 : .white)
                    .shadow(color: colorScheme == .dark ? .clear : Color(hex: 0xBDBDBD).opacity(0.25), radius: 7.1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colorScheme == .dark ? FillsaColor.gray500 : .clear, lineWidth: 1)
            }
            .accessibilityAddTraits(.isModal)
            .accessibilityIdentifier("typing.result")
        }
    }
}
