// /Views/Onboarding/OnboardingFlowView.swift

import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]

    @State private var step: Int = 0

    private var appSettings: AppSettings {
        if let s = settings.first { return s }
        let s = AppSettings()
        context.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            switch step {
            case 0:
                OnboardingWelcomeView {
                    withAnimation(.easeInOut(duration: 0.35)) { step = 1 }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case 1:
                OnboardingAccountsView {
                    withAnimation(.easeInOut(duration: 0.35)) { step = 2 }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case 2:
                OnboardingDefaultAccountView {
                    withAnimation(.easeInOut(duration: 0.35)) { step = 3 }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case 3:
                OnboardingCarryOverView {
                    appSettings.hasOnboardingCompleted = true
                    try? context.save()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }
}
