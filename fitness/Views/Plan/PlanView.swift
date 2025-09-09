import SwiftUI

struct PlanView: View {
    @EnvironmentObject var weightManager: WeightManager
    @State private var trainingReminder = true
    @State private var recordingReminder = true
    @State private var restDayReminder = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    goalsAndPlansSection
                    weeklyPlanStatus
                    smartReminders
                }
                .padding()
            }
            .navigationTitle("计划")
        }
    }

    private var goalsAndPlansSection: some View {
        NavigationLink(destination: GoalDetailView()) {
            VStack(alignment: .leading, spacing: 12) {
                Text("减脂目标").font(.title2).bold().foregroundColor(.primary)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("当前进度")
                        Spacer()
                        Text("\(weightManager.records.last?.weight ?? 0, specifier: "%.1f")kg / 70kg")
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    
                    ProgressView(value: (weightManager.records.last?.weight ?? 0) / 70)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    
                    Text("已完成 \(Int(((weightManager.records.last?.weight ?? 0) / 70) * 100))% - 截止日期: 2024年12月")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            }
        }
        .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to remove the default button styling from NavigationLink
    }

    private var weeklyPlanStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周状态").font(.title2).bold()
            VStack(spacing: 12) {
                ForEach(DayStatus.mockData) { day in
                    HStack {
                        Circle()
                            .fill(day.status.color)
                            .frame(width: 10, height: 10)
                        Text(day.day)
                        Spacer()
                        Text(day.status.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var smartReminders: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智能提醒").font(.title2).bold()
            VStack(spacing: 12) {
                Toggle("训练提醒", isOn: $trainingReminder)
                Toggle("记录提醒", isOn: $recordingReminder)
                Toggle("休息日提醒", isOn: $restDayReminder)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}



struct DayStatus: Identifiable {
    let id = UUID()
    let day: String
    let status: Status

    enum Status: String {
        case completed = "已完成"
        case inProgress = "进行中"
        case notStarted = "未开始"

        var color: Color {
            switch self {
            case .completed: .green
            case .inProgress: .yellow
            case .notStarted: .gray
            }
        }
    }

    static let mockData = [
        DayStatus(day: "周一", status: .completed),
        DayStatus(day: "周二", status: .completed),
        DayStatus(day: "周三", status: .completed),
        DayStatus(day: "周四", status: .completed),
        DayStatus(day: "周五", status: .completed),
        DayStatus(day: "周六", status: .inProgress),
        DayStatus(day: "周日", status: .notStarted)
    ]
}