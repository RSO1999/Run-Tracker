//
//  SplashView.swift
//  rortiz_RunnersDelight
//
//  Created by Ryan Ortiz on 1/23/26.
//


import SwiftUI

struct SplashView: View {
    @State private var showMain = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            LottieView(vectorized: "vectorized", loopMode: .playOnce)
                .frame(width: 240, height: 240)
        }
        .onAppear {
            // Adjust this to match your animation length
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                showMain = true
            }
        }
        .fullScreenCover(isPresented: $showMain) {
            ContentView() // your main screen
        }
    }
}
