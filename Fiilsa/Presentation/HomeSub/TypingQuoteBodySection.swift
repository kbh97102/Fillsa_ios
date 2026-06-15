//
//  TypingQuoteBodySection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct TypingQuoteBodySection: View {
    let quote: String
    @Binding var write: String

    var body: some View {
        ZStack(alignment: .center) {
            Text(highlightedText)
                .font(FillsaTypography.body1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            TextEditor(text: $write)
                .font(FillsaTypography.body1)
                .foregroundStyle(.clear)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .tint(FillsaColor.gray700)
                .onChange(of: write) { _, newValue in
                    if newValue.count > quote.count {
                        write = String(newValue.prefix(quote.count))
                    }
                }
        }
    }

    private var highlightedText: AttributedString {
        var result = AttributedString()
        let quoteCharacters = Array(quote)
        let writeCharacters = Array(write)

        for index in quoteCharacters.indices {
            let expected = quoteCharacters[index]
            let displayed = index < writeCharacters.count ? writeCharacters[index] : expected
            var character = AttributedString(String(displayed))

            if index < writeCharacters.count {
                character.foregroundColor = displayed == expected ? FillsaColor.gray700 : .red
            } else {
                character.foregroundColor = Color(hex: 0xCACACA)
            }

            result += character
        }

        return result
    }
}

#Preview {
    @Previewable @State var write = "상황"

    TypingQuoteBodySection(
        quote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        write: $write
    )
    .padding()
}
