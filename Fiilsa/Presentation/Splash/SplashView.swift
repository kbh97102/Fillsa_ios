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
                    .clipped()
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

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.clipsToBounds = true

        let animationView = LottieAnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.clipsToBounds = true
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        containerView.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        context.coordinator.animationView = animationView
        updateUIView(containerView, context: context)
        return containerView
    }

    func updateUIView(_ containerView: UIView, context: Context) {
        guard let animationView = context.coordinator.animationView else {
            return
        }

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
        var animationView: LottieAnimationView?
    }
}

#Preview {
    SplashView(
        store: Store(initialState: SplashFeature.State()) {
            SplashFeature()
        }
    )
}
