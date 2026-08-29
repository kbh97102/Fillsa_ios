import ComposableArchitecture
import SwiftUI

struct HomeAnswerEditorView: View {
    let store: StoreOf<HomeAnswerEditorFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                HStack {
                    Button {
                        viewStore.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(FillsaColor.onBackground1)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("답변 편집기 닫기")

                    Spacer()

                    Text("오늘의 답변")
                        .font(FillsaTypography.subtitle1)
                        .foregroundStyle(FillsaColor.onBackground1)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 7)

                VStack(alignment: .leading, spacing: 12) {
                    Text(viewStore.question)
                        .font(FillsaTypography.body3)
                        .foregroundStyle(FillsaColor.onBackground1)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: Binding(
                            get: { viewStore.answer },
                            set: { viewStore.send(.answerChanged($0)) }
                        ))
                        .font(FillsaTypography.body3)
                        .foregroundStyle(FillsaColor.onBackground1)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .accessibilityLabel("오늘의 답변")
                        .accessibilityHint("최대 200자까지 입력할 수 있습니다.")

                        if viewStore.answer.isEmpty {
                            Text("오늘의 질문을 보고 떠오른 생각을 자유롭게 기록해보세요.")
                                .font(FillsaTypography.body3)
                                .foregroundStyle(FillsaColor.gray400)
                                .padding(.horizontal, 12)
                                .padding(.top, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(FillsaColor.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .overlay {
                        RoundedRectangle(cornerRadius: 17)
                            .stroke(Color(hex: 0xDED4BD), lineWidth: 1)
                    }

                    Text("\(viewStore.answer.count) / \(HomeAnswerInput.maximumCharacterCount)")
                        .font(FillsaTypography.body4)
                        .foregroundStyle(Color(hex: 0x8D877D))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Button {
                        viewStore.send(.saveTapped)
                    } label: {
                        Text(viewStore.isSaving ? "저장 중..." : "답변 저장하기")
                            .font(FillsaTypography.subtitle1)
                            .foregroundStyle(FillsaColor.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 49)
                            .background(FillsaColor.purple01)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewStore.isSaving)
                    .accessibilityLabel("답변 저장하기")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear { viewStore.send(.onAppear) }
            .overlay(alignment: .bottom) {
                if let message = viewStore.toastMessage {
                    Text(message)
                        .font(FillsaTypography.body2)
                        .foregroundStyle(FillsaColor.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(FillsaColor.black0C.opacity(0.84)))
                        .padding(.bottom, 28)
                        .onAppear {
                            Task {
                                try? await Task.sleep(nanoseconds: 1_600_000_000)
                                await viewStore.send(.toastDismissed).finish()
                            }
                        }
                }
            }
        }
    }
}
