import SwiftUI

struct MealPlanCardView: View {
    let meal: Meal

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            iconBadge

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(meal.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    statusPill(text: timeString, color: .blue)
                }

                Text("\(meal.calories) 千卡 · \(meal.mealType.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                statusPill(text: meal.mealType.rawValue, color: tintColor.opacity(0.85))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tintColor.opacity(0.15))
                .frame(width: 52, height: 52)

            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(tintColor)
        }
    }

    private var tintColor: Color {
        switch meal.mealType {
        case .breakfast:
            return .yellow
        case .lunch:
            return .orange
        case .dinner:
            return .purple
        case .snack:
            return .green
        }
    }

    private var iconName: String {
        switch meal.mealType {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "fork.knife.circle.fill"
        case .dinner:
            return "moon.stars.fill"
        case .snack:
            return "leaf.fill"
        }
    }

    private var timeString: String {
        meal.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }

    private func statusPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .foregroundStyle(color)
    }
}

struct MealPlanCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMeal = Meal(name: "希腊酸奶水果碗", calories: 320, date: Date(), mealType: .breakfast)
        MealPlanCardView(meal: sampleMeal)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
