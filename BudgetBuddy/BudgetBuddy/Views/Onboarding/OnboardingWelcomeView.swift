// /Views/Onboarding/OnboardingWelcomeView.swift

import SwiftUI

struct OnboardingWelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top: gradient + stacked cards

            ZStack(alignment: .bottom) {
                // Achtergrond gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.82, green: 0.80, blue: 0.96),
                        Color(red: 0.88, green: 0.86, blue: 0.98),
                        Color(red: 0.94, green: 0.93, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    // App naam
                    Text("GELD IN ZICHT.")
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .kerning(2.5)
                        .foregroundStyle(Color(red: 0.35, green: 0.30, blue: 0.55))
                        .padding(.top, 56)

                    Spacer()

                    // Gestapelde kaarten
                    stackedCards
                        .padding(.bottom, 32)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.52)

            // MARK: - Bottom: wit vlak

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("Financiële vrijheid")
                        .font(.system(size: 30, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Beheer je rekeningen, volg uitgaven op en bouw spaardoelen — alles op één plek.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 36)

                Spacer()

                // Aan de slag knop
                Button(action: onNext) {
                    HStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.28))
                                .frame(width: 46, height: 46)
                            Image(systemName: "chevron.right.2")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.leading, 6)

                        Text("Aan de slag")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.trailing, 52)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.10, green: 0.12, blue: 0.18))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Gestapelde kaarten

    private var stackedCards: some View {
        ZStack {
            // Kaart 3 (achterste) – donker
            cardShape(
                gradient: [Color(red: 0.12, green: 0.14, blue: 0.22), Color(red: 0.20, green: 0.22, blue: 0.32)],
                name: "PHOENIX BAKER",
                number: "1234 1234 1234 1234"
            )
            .rotationEffect(.degrees(-14), anchor: .bottom)
            .offset(x: -10, y: 0)

            // Kaart 2 (midden) – blauw/paars
            cardShape(
                gradient: [Color(red: 0.35, green: 0.40, blue: 0.90), Color(red: 0.55, green: 0.45, blue: 0.95)],
                name: "OLIVIA RHYE",
                number: "1234 1234 1234 1234"
            )
            .rotationEffect(.degrees(-4), anchor: .bottom)
            .offset(x: 4, y: -10)

            // Kaart 1 (voorste) – licht/glassy
            cardShape(
                gradient: [Color(red: 0.75, green: 0.72, blue: 0.95), Color(red: 0.60, green: 0.55, blue: 0.90), Color(red: 0.80, green: 0.78, blue: 0.98)],
                name: "LANA STEINER",
                number: "1234 1234 1234 1234"
            )
            .rotationEffect(.degrees(8), anchor: .bottom)
            .offset(x: 18, y: -20)
        }
        .frame(height: 220)
    }

    private func cardShape(gradient: [Color], name: String, number: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .kerning(0.5)
                Text(number)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(16)

            // Contactless mark
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                        .frame(width: CGFloat(5 + i * 4), height: CGFloat(14 + i * 4))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 14)
            .padding(.bottom, 14)
        }
        .frame(width: 260, height: 162)
    }
}
