import SwiftUI

struct SummaryDashboardView: View {
    @Binding var showInputSheet: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FitnessRingCard()
                    CurrentCardView(showInputSheet: $showInputSheet)
                    GoalProgressView()
                    HStack(spacing: 16) {
                        StepsCard()
                        DistanceCard()
                    }
                    MonthlyChallengeCard()
                    RecentActivityCard()
                }
                .padding()
            }
            .navigationTitle("概览")
        }
    }
}
