import SwiftUI

struct GoalDetailView: View {
    @State private var selectedSegment: PlanType = .exercise

    enum PlanType: String, CaseIterable {
        case exercise = "运动"
        case diet = "饮食"
    }

    var body: some View {
        NavigationStack {
            VStack {
                goalSummaryCard
                
                Picker("Plan Type", selection: $selectedSegment) {
                    ForEach(PlanType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedSegment == .exercise {
                    exerciseSection
                } else {
                    dietSection
                }

                Spacer()
            }
            .navigationTitle("减脂目标")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var goalSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目标: 减脂").font(.title2).bold()
            HStack {
                VStack(alignment: .leading) {
                    Text("当前体重").font(.subheadline).foregroundColor(.secondary)
                    Text("66.7 kg").font(.title).bold()
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("目标体重").font(.subheadline).foregroundColor(.secondary)
                    Text("65.0 kg").font(.title).bold()
                }
            }
            ProgressView(value: 0.8)
            HStack {
                Text("起始日期: 2024-01-01")
                Spacer()
                Text("截止日期: 2024-12-31")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding()
    }

    private var dietSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("饮食计划").font(.title3).bold().padding(.horizontal)
            ScrollView {
                VStack(spacing: 16) {
                    MealCardView(meal: .breakfast, recommendedCalories: "400-500", foodItems: ["燕麦片 (50g)", "牛奶 (200ml)", "鸡蛋 (1个)"])
                    MealCardView(meal: .lunch, recommendedCalories: "600-700", foodItems: ["鸡胸肉 (150g)", "西兰花 (100g)", "糙米饭 (1碗)"])
                    MealCardView(meal: .dinner, recommendedCalories: "500-600", foodItems: ["三文鱼 (100g)", "芦笋 (100g)", "红薯 (1个)"])
                    MealCardView(meal: .snacks, recommendedCalories: "200-300", foodItems: ["坚果 (30g)", "酸奶 (150g)"])
                }
                .padding()
            }
        }
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("运动计划").font(.title3).bold().padding(.horizontal)
            ScrollView {
                VStack(spacing: 16) {
                    PlanRow(name: "力量提升", progress: 0.30, color: .orange)
                    PlanRow(name: "有氧", progress: 0.50, color: .cyan)
                    PlanRow(name: "游泳", progress: 0.20, color: .blue)
                    PlanRow(name: "跑步", progress: 0.80, color: .green)
                    PlanRow(name: "羽毛球", progress: 0.10, color: .purple)
                    PlanRow(name: "晨间瑜伽", progress: 0.90, color: .pink)
                }
                .padding()
            }
        }
    }
}

enum Meal: String {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snacks = "加餐"

    var icon: String {
        switch self {
        case .breakfast: return "sun.and.horizon"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snacks: return "cup.and.saucer"
        }
    }
}

struct MealCardView: View {
    let meal: Meal
    let recommendedCalories: String
    let foodItems: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: meal.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(meal.rawValue)
                    .font(.title2).bold()
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            Text("建议: \(recommendedCalories)千卡")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(foodItems, id: \.self) { item in
                    Text(item)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}