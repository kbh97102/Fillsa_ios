import ComposableArchitecture
import Lottie
import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    let store: StoreOf<SplashFeature>

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("나만의 필사로 채우다,")
                    .font(FillsaTypography.quote)
                    .foregroundStyle(isDarkMode ? FillsaColor.yellow01 : FillsaColor.gray700)

                SplashLottieView(animationName: animationName)
                    .frame(width: 192, height: 192)
                    .id(animationName)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((isDarkMode ? FillsaColor.gray700 : FillsaColor.white).ignoresSafeArea())
        .onAppear {
            store.send(.onAppear)
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            await store.send(.animationCompleted).finish()
        }
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var animationName: String {
        isDarkMode ? "lottie_splash_dark" : "lottie_splash"
    }
}

private struct SplashLottieView: UIViewRepresentable {
    let animationName: String

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        updateUIView(animationView, context: context)
        return animationView
    }

    func updateUIView(_ animationView: LottieAnimationView, context: Context) {
        guard context.coordinator.animationName != animationName else {
            if !animationView.isAnimationPlaying {
                animationView.play()
            }
            return
        }

        context.coordinator.animationName = animationName
        animationView.animation = LottieAnimation.named(
            animationName,
            bundle: .main
        )
        animationView.play()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var animationName: String?
    }
}

#Preview {
    SplashView(
        store: Store(initialState: SplashFeature.State()) {
            SplashFeature()
        }
    )
}
