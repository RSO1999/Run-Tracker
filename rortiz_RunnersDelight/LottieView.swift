//
//  LottieView.swift
//  rortiz_RunnersDelight
//
//  Created by Ryan Ortiz on 1/23/26.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let vectorized: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        let animationView = LottieAnimationView(name: vectorized)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
