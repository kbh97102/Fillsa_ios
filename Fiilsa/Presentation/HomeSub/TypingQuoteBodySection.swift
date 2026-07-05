//
//  TypingQuoteBodySection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import Combine
import SwiftUI
import UIKit

struct TypingQuoteBodySection: View {
    let quote: String
    @Binding var write: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var composingWrite: String?
    @State private var cursorVisible = true

    private let cursorTimer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            Text(displayText)
                .font(FillsaTypography.body1)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(maxWidth: .infinity)

            TypingQuoteInputView(
                quote: quote,
                write: $write,
                composingWrite: $composingWrite
            )
            .frame(width: 1, height: 1)
            .clipped()
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .top)
        .onReceive(cursorTimer) { _ in
            cursorVisible.toggle()
        }
        .onChange(of: write) { _, _ in
            cursorVisible = true
        }
        .onChange(of: composingWrite) { _, _ in
            cursorVisible = true
        }
    }

    private var displayText: AttributedString {
        let currentWrite = composingWrite ?? write
        var result = AttributedString()
        let quoteCharacters = Array(quote)
        let writeCharacters = Array(currentWrite)

        for index in 0...quoteCharacters.count {
            if index == writeCharacters.count {
                var cursor = AttributedString("|")
                cursor.foregroundColor = cursorVisible ? cursorColor : .clear
                result += cursor
            }

            guard index < quoteCharacters.count else { break }

            let expected = quoteCharacters[index]
            let displayed = index < writeCharacters.count ? writeCharacters[index] : expected
            var character = AttributedString(String(displayed))

            if index >= writeCharacters.count {
                character.foregroundColor = Color(hex: 0xCACACA)
            } else if displayed == expected {
                character.foregroundColor = typedTextColor
            } else {
                character.foregroundColor = .red
            }

            result += character
        }

        return result
    }

    private var typedTextColor: Color {
        colorScheme == .dark ? FillsaColor.yellow02 : FillsaColor.gray700
    }

    private var cursorColor: Color {
        colorScheme == .dark ? FillsaColor.yellow02 : FillsaColor.gray700
    }
}

private struct TypingQuoteInputView: UIViewRepresentable {
    let quote: String
    @Binding var write: String
    @Binding var composingWrite: String?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = .clear
        textView.tintColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.font = UIFont(name: "Pretendard-Regular", size: 20) ?? .systemFont(ofSize: 20)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self

        DispatchQueue.main.async {
            if !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
        }

        guard textView.markedTextRange == nil else { return }

        let limitedWrite = String(write.prefix(quote.count))
        if limitedWrite != write {
            DispatchQueue.main.async {
                write = limitedWrite
            }
        }

        if textView.text != limitedWrite {
            textView.text = limitedWrite
        }

        let selectedLocation = (limitedWrite as NSString).length
        if textView.selectedRange.location != selectedLocation || textView.selectedRange.length != 0 {
            textView.selectedRange = NSRange(location: selectedLocation, length: 0)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TypingQuoteInputView

        init(parent: TypingQuoteInputView) {
            self.parent = parent
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            let replacement = text.replacingOccurrences(of: "\n", with: "")
            let currentText = textView.text as NSString
            let proposedText = currentText.replacingCharacters(in: range, with: replacement)
            return proposedText.count <= parent.quote.count
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView.markedTextRange != nil {
                parent.composingWrite = textView.text
                return
            }

            parent.composingWrite = nil
            parent.write = textView.text
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard textView.markedTextRange == nil else { return }

            let location = (textView.text as NSString).length
            guard textView.selectedRange.location != location || textView.selectedRange.length != 0 else {
                return
            }

            textView.selectedRange = NSRange(location: location, length: 0)
        }
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
