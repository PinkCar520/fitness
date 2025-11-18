import SwiftUI
import SwiftData

enum ChartableMetric: String, CaseIterable, Identifiable {
    case weight = "体重"
    case bodyFat = "体脂率"
    case waist = "腰围"
    case heartRate = "心率"
    case vo2Max = "VO2max"

    var id: String { self.rawValue }
}

struct BodyProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var weightManager: WeightManager
    @Query(sort: \HealthMetric.date, order: .reverse) private var metrics: [HealthMetric]
    private let zhLocale = Locale(identifier: "zh-Hans")
    
    @State private var showInputSheet = false
    @State private var showTrajectorySheet = false
    @State private var showBMIDetailSheet = false
    @State private var showBodyFatDetailSheet = false
    @StateObject private var vm = BodyProfileViewModel()
    // Lines always shown by default (no toggles)

    // Computed properties to get latest values
    private var latestWeight: Double {
        metrics.first(where: { $0.type == .weight })?.value ?? 0
    }
    private var latestBodyFat: Double {
        metrics.first(where: { $0.type == .bodyFatPercentage })?.value ?? 0
    }
    private var latestBodyFatRecordDate: Date? {
        metrics.first(where: { $0.type == .bodyFatPercentage })?.date
    }
    private var bmi: Double { vm.bmi }
    private var latestWaistCircumference: Double {
        latestValue(for: .waistCircumference) ?? 0
    }
    private var latestChestCircumference: Double {
        latestValue(for: .chestCircumference) ?? 0
    }
    private var latestHeartRate: Double {
        latestValue(for: .heartRate) ?? 0
    }
    private var latestBodyFatMass: Double {
        latestValue(for: .bodyFatMass) ?? 0
    }
    private var latestSkeletalMuscleMass: Double {
        latestValue(for: .skeletalMuscleMass) ?? 0
    }
    private var latestBodyWaterPercentage: Double {
        latestValue(for: .bodyWaterPercentage) ?? 0
    }
    private var latestBasalMetabolicRate: Double {
        latestValue(for: .basalMetabolicRate) ?? 0
    }
    private var latestWaistToHipRatio: Double {
        latestValue(for: .waistToHipRatio) ?? 0
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    emptyDataHintSection
                    currentIndicatorsSection
                    vo2QuickSection
                    additionalMetricsSection
                    bodyCompositionSection
                    visualRecordsSection
                    Spacer(minLength: 80)
                }
                .padding(.vertical)
            }

        }
        .onAppear { refreshVM() }
        .onChange(of: metrics.map(\.date)) { _, _ in refreshVM() }
        .sheet(isPresented: $showTrajectorySheet) {
            HistoryListView()
                .environmentObject(weightManager)
        }
        .sheet(isPresented: $showBMIDetailSheet) {
            BMIDetailSheet(
                bmi: bmi,
                height: profileViewModel.userProfile.height,
                latestWeight: vm.latestWeight,
                category: vm.bmiCategory
            )
            .presentationDetents([.fraction(0.5), .fraction(0.9)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBodyFatDetailSheet) {
            BodyFatDetailSheet(
                bodyFat: vm.latestBodyFat,
                gender: profileViewModel.userProfile.gender,
                recordDate: latestBodyFatRecordDate
            )
            .presentationDetents([.fraction(0.5), .fraction(0.9)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews (split to reduce type-checking complexity)
    private var currentIndicatorsSection: some View {
        let items: [MetricDisplay] = [
            .init(title: "体重", value: formatted(latestWeight, precision: 1), unit: "公斤", icon: "scalemass.fill", color: .blue),
            .init(title: "BMI", value: formatted(bmi, precision: 1), unit: "", icon: "figure.walk", color: .green),
            .init(title: "体脂率", value: formatted(latestBodyFat, precision: 1), unit: "%", icon: "flame.fill", color: .orange),
            .init(title: "静息心率", value: formatted(latestHeartRate, precision: 0), unit: "bpm", icon: "heart.fill", color: .red)
        ]
        return metricSection(title: nil, items: items)
    }

    @ViewBuilder private var vo2QuickSection: some View {
        if !healthKitManager.isVO2MaxAvailableOnThisDevice() {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle").foregroundStyle(.secondary)
                    Text("VO2max 需要支持的设备（通常为 Apple Watch）")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        } else if let latest = metrics.first(where: { $0.type == .vo2Max })?.value, latest > 0 {
            let items = [MetricDisplay(title: "VO2max", value: formatted(latest, precision: 1), unit: "ml/kg/min", icon: "lungs.fill", color: .teal)]
            metricSection(title: "心肺耐力", items: items)
        }
    }

    private var additionalMetricsSection: some View {
        let items: [MetricDisplay] = [
            .init(title: "腰围", value: formatted(latestWaistCircumference, precision: 1), unit: "cm", icon: "figure", color: .purple),
            .init(title: "胸围", value: formatted(latestChestCircumference, precision: 1), unit: "cm", icon: "figure.stand", color: .pink),
            .init(title: "腰臀比", value: formatted(latestWaistToHipRatio, precision: 2), unit: "", icon: "circle.grid.cross", color: .teal)
        ]
        return metricSection(title: "身体围度", items: items)
    }

    private var bodyCompositionSection: some View {
        let items: [MetricDisplay] = [
            .init(title: "体脂肪量", value: formatted(latestBodyFatMass, precision: 1), unit: "kg", icon: "scalemass.fill", color: .orange),
            .init(title: "骨骼肌量", value: formatted(latestSkeletalMuscleMass, precision: 1), unit: "kg", icon: "figure.strengthtraining.traditional", color: .purple),
            .init(title: "身体水分率", value: formatted(latestBodyWaterPercentage, precision: 1), unit: "%", icon: "drop.fill", color: .blue),
            .init(title: "基础代谢率", value: formatted(latestBasalMetabolicRate, precision: 0), unit: "kcal", icon: "flame.circle.fill", color: .red)
        ]
        return Group {
            metricSection(title: "身体成分", items: items)
            BodyCompositionSummary(bmi: bmi, bodyFat: latestBodyFat)
                .padding(.horizontal)
        }
    }

    // insightsSection removed per design requirements

    private var visualRecordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("视觉记录")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(alignment: .center) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
                Text("记录你的蜕变，见证每一次进步")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("点击添加照片 (即将推出)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // Floating action removed (no manual record entry here)

    // MARK: - Empty Data (authorization banner removed by design)

    @ViewBuilder private var emptyDataHintSection: some View {
        if metrics.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("还没有身体指标记录")
                    .font(.headline)
                Text("可在健康 App 中开启数据同步。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: openHealthApp) {
                    Label("打开健康 App", systemImage: "heart")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func openHealthApp() {
        if let url = URL(string: "x-apple-health://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Helpers

    private func latestValue(for type: MetricType) -> Double? {
        metrics.first(where: { $0.type == type })?.value
    }

    private func formatted(_ value: Double, precision: Int) -> String {
        guard value > 0 else { return "--" }
        return String(format: "%.\(precision)f", value)
    }

    @ViewBuilder
    private func metricSection(title: String?, items: [MetricDisplay]) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        VStack(alignment: .leading, spacing: 12) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { item in
                    MetricCard(
                        title: item.title,
                        value: item.value,
                        unit: item.unit,
                        icon: item.icon,
                        color: item.color
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .onTapGesture {
                        handleMetricTap(item)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

}

private extension BodyProfileView {
    func refreshVM() {
        vm.refresh(metrics: metrics, profile: profileViewModel.userProfile)
    }

    func handleMetricTap(_ item: MetricDisplay) {
        if item.title == "体重" {
            showTrajectorySheet = true
        } else if item.title == "BMI" {
            showBMIDetailSheet = true
        } else if item.title == "体脂率" {
            showBodyFatDetailSheet = true
        }
    }
}

private struct BMIDetailSheet: View {
    let bmi: Double
    let height: Double
    let latestWeight: Double?
    let category: HealthStandards.BMICategory
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    private var formattedBMI: String {
        bmi > 0 ? String(format: "%.1f", bmi) : "--"
    }
    
    private var heightText: String {
        height > 0 ? "\(Int(round(height))) cm" : "--"
    }
    
    private var weightText: String {
        if let latestWeight, latestWeight > 0 {
            return String(format: "%.1f kg", latestWeight)
        }
        return "--"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("BMI 详情")
                        .font(.title3.bold())
                    Text("根据身高与体重即时计算")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedBMI)
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                    Text(category.displayTitle)
                        .font(.headline)
                        .foregroundColor(category.accentColor)
                    Text(category.guidance)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(category.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                LazyVGrid(columns: columns, spacing: 12) {
                    infoTile(title: "最新体重", value: weightText, icon: "scalemass.fill")
                    infoTile(title: "身高设置", value: heightText, icon: "ruler")
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHO 区间")
                        .font(.headline)
                    ForEach(HealthStandards.BMICategory.allCases) { band in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(band.displayTitle)
                                    .font(.subheadline.bold())
                                Text(band.rangeDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if band == category {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(band.accentColor)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(band == category ? band.accentColor.opacity(0.12) : Color.gray.opacity(0.08))
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("计算方式")
                        .font(.headline)
                    Text("BMI = 体重(kg) ÷ 身高(m)²。建议结合体脂率等指标综合判断。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
    
    private func infoTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

private struct BodyFatDetailSheet: View {
    let bodyFat: Double?
    let gender: Gender
    let recordDate: Date?
    
    private var category: HealthStandards.BodyFatBand? {
        guard let bodyFat, bodyFat > 0 else { return nil }
        return HealthStandards.bodyFatBand(gender: gender, value: bodyFat)
    }
    
    private var valueText: String {
        guard let bodyFat, bodyFat > 0 else { return "--" }
        return String(format: "%.1f%%", bodyFat)
    }
    
    private var recordDateText: String {
        guard let recordDate else { return "暂无记录" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: recordDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("体脂率详情")
                        .font(.title3.bold())
                    Text("结合性别差异的健康区间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(valueText)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                    Text(category?.displayTitle ?? "等待记录")
                        .font(.headline)
                        .foregroundColor(category?.accentColor ?? .secondary)
                    Text(category?.guidance ?? "记录体脂率，解锁更精确的身体成分分析。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill((category?.accentColor ?? .gray).opacity(0.12))
                )
                
                HStack(spacing: 12) {
                    infoTile(title: "最近记录", value: recordDateText, icon: "calendar")
                    infoTile(title: "性别设定", value: gender.rawValue, icon: "figure.stand")
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("参考区间 (\(gender.rawValue))")
                        .font(.headline)
                    ForEach(HealthStandards.BodyFatBand.allCases) { band in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(band.displayTitle)
                                    .font(.subheadline.bold())
                                Text(band.rangeDescription(for: gender))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if band == category {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(band.accentColor)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(band == category ? band.accentColor.opacity(0.12) : Color.gray.opacity(0.08))
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("提示")
                        .font(.headline)
                    Text("体脂率受水分、饮食、测量方式影响，建议固定时间点测量，并结合围度、体重等指标综合判断。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
    
    private func infoTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

struct BodyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        
        // Add sample data for preview
        let sampleData = [
            HealthMetric(date: Date().addingTimeInterval(-86400*6), value: 70.5, type: .weight),
            HealthMetric(date: Date().addingTimeInterval(-86400*3), value: 70.1, type: .weight),
            HealthMetric(date: Date(), value: 69.5, type: .weight),
            HealthMetric(date: Date(), value: 22.5, type: .bodyFatPercentage)
        ]
        sampleData.forEach { container.mainContext.insert($0) }

        return BodyProfileView()
            .modelContainer(container)
            .environmentObject(ProfileViewModel())
    }
}

// MARK: - Supporting Models & Views

struct MetricDisplay: Identifiable {
    let id: String
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    init(title: String, value: String, unit: String, icon: String, color: Color) {
        self.id = title
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.color = color
    }
}

extension HealthStandards.BMICategory: CaseIterable, Identifiable {
    static var allCases: [HealthStandards.BMICategory] { [.underweight, .normal, .overweight, .obese] }
    var id: HealthStandards.BMICategory { self }
}

private extension HealthStandards.BMICategory {
    var displayTitle: String {
        switch self {
        case .underweight: return "偏瘦"
        case .normal: return "标准"
        case .overweight: return "超重"
        case .obese: return "肥胖"
        }
    }
    
    var rangeDescription: String {
        switch self {
        case .underweight: return "< 18.5"
        case .normal: return "18.5 – 24.9"
        case .overweight: return "25 – 29.9"
        case .obese: return "≥ 30"
        }
    }
    
    var guidance: String {
        switch self {
        case .underweight: return "适度增加热量与力量训练，帮助提升瘦体重。"
        case .normal: return "保持当前饮食与训练节奏，继续跟踪体脂等指标。"
        case .overweight: return "结合控热与耐力训练，逐步回到健康区间。"
        case .obese: return "建议循序渐进调整饮食，并搭配低冲击训练。"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .underweight: return .teal
        case .normal: return .green
        case .overweight: return .orange
        case .obese: return .red
        }
    }
}

extension HealthStandards.BodyFatBand: CaseIterable, Identifiable {
    static var allCases: [HealthStandards.BodyFatBand] { [.athletic, .fit, .average, .high] }
    var id: HealthStandards.BodyFatBand { self }
}

private extension HealthStandards.BodyFatBand {
    var displayTitle: String {
        switch self {
        case .athletic: return "运动型"
        case .fit: return "良好"
        case .average: return "平均"
        case .high: return "偏高"
        }
    }
    
    func rangeDescription(for gender: Gender) -> String {
        switch (gender, self) {
        case (.male, .athletic): return "< 10%"
        case (.male, .fit): return "10% – 16%"
        case (.male, .average): return "17% – 24%"
        case (.male, .high): return "≥ 25%"
        case (.female, .athletic): return "< 18%"
        case (.female, .fit): return "18% – 24%"
        case (.female, .average): return "25% – 31%"
        case (.female, .high): return "≥ 32%"
        case (.preferNotToSay, _):
            switch self {
            case .athletic: return "< 15%"
            case .fit: return "15% – 22%"
            case .average: return "23% – 30%"
            case .high: return "≥ 31%"
            }
        }
    }
    
    var guidance: String {
        switch self {
        case .athletic: return "训练状态良好，注意补充能量并保持恢复。"
        case .fit: return "身体成分优秀，可持续当前训练节奏。"
        case .average: return "处于正常范围，可搭配力量+有氧稳步优化。"
        case .high: return "建议关注饮食结构，并循序渐进增加活动量。"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .athletic: return .teal
        case .fit: return .green
        case .average: return .orange
        case .high: return .red
        }
    }
}

struct BodyCompositionSummary: View {
    let bmi: Double
    let bodyFat: Double

    private var bmiStatus: CompositionCategory? { CompositionCategory.bmiCategory(for: bmi) }
    private var bodyFatStatus: CompositionCategory? { CompositionCategory.bodyFatCategory(for: bodyFat) }

    private var bmiValue: String {
        guard bmi > 0 else { return "--" }
        return String(format: "%.1f", bmi)
    }

    private var bodyFatValue: String {
        guard bodyFat > 0 else { return "--" }
        return String(format: "%.1f", bodyFat)
    }

    private var bmiProgress: Double {
        guard bmi > 0 else { return 0 }
        return progress(for: bmi, in: 15...32)
    }

    private var bodyFatProgress: Double {
        guard bodyFat > 0 else { return 0 }
        return progress(for: bodyFat, in: 10...35)
    }

    private var subtitle: String {
        switch (bmiStatus, bodyFatStatus) {
        case let (bmi?, fat?):
            return "\(bmi.title) · \(fat.title)"
        case let (bmi?, nil):
            return "BMI：\(bmi.title)，体脂待记录"
        case let (nil, fat?):
            return "体脂：\(fat.title)，BMI 待记录"
        default:
            return "记录体重与体脂即可生成分析"
        }
    }

    private var adviceLines: [String] {
        var lines: [String] = []
        if let bmiStatus {
            lines.append("BMI：\(bmiStatus.subtitle)")
        }
        if let bodyFatStatus {
            lines.append("体脂：\(bodyFatStatus.subtitle)")
        }
        return lines
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.functional")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .padding(10)
                    .background(Color.accentColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("体型分析")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 16) {
                metricRow(
                    title: "BMI",
                    value: bmiValue,
                    unit: "",
                    status: bmiStatus,
                    progress: bmiProgress,
                    defaultRange: "理想区间 18.5 - 23.9"
                )

                metricRow(
                    title: "体脂率",
                    value: bodyFatValue,
                    unit: "%",
                    status: bodyFatStatus,
                    progress: bodyFatProgress,
                    defaultRange: "参考范围 15% - 24%"
                )
            }

            if adviceLines.isEmpty {
                Text("记录体重与体脂后，将为你生成专属建议。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("建议")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    ForEach(adviceLines, id: \.self) { line in
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.accentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.16), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func metricRow(
        title: String,
        value: String,
        unit: String,
        status: CompositionCategory?,
        progress: Double,
        defaultRange: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                        if !unit.isEmpty {
                            Text(unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
                StatusChip(status: status)
            }

            LinearProgressBar(progress: progress, tint: status?.color ?? Color.secondary.opacity(0.4))

            Text(status?.rangeHint ?? defaultRange)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func progress(for value: Double, in range: ClosedRange<Double>) -> Double {
        guard value > 0 else { return 0 }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        let normalized = (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
        return normalized
    }
}

struct CompositionCategory {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let rangeHint: String

    static func bmiCategory(for bmi: Double) -> CompositionCategory? {
        guard bmi > 0 else { return nil }
        let hint = "理想区间 18.5 - 23.9"
        switch bmi {
        case ..<18.5:
            return CompositionCategory(
                title: "偏瘦",
                subtitle: "适当增加能量摄入，并配合力量训练提升肌肉量。",
                color: .blue,
                icon: "arrow.down.circle.fill",
                rangeHint: hint
            )
        case 18.5..<24:
            return CompositionCategory(
                title: "理想",
                subtitle: "持续保持当前的饮食节奏与训练频率。",
                color: .green,
                icon: "checkmark.circle.fill",
                rangeHint: hint
            )
        case 24..<28:
            return CompositionCategory(
                title: "超重倾向",
                subtitle: "适度控制热量摄入，并增加有氧训练时间。",
                color: .orange,
                icon: "exclamationmark.triangle.fill",
                rangeHint: hint
            )
        default:
            return CompositionCategory(
                title: "肥胖风险",
                subtitle: "建议结合力量与有氧训练，分阶段降低体重。",
                color: .red,
                icon: "flame.fill",
                rangeHint: hint
            )
        }
    }

    static func bodyFatCategory(for bodyFat: Double) -> CompositionCategory? {
        guard bodyFat > 0 else { return nil }
        let hint = "参考范围 15% - 24%"
        switch bodyFat {
        case ..<15:
            return CompositionCategory(
                title: "偏低",
                subtitle: "确保摄入足够的蛋白质与碳水，避免能量不足。",
                color: .blue,
                icon: "arrow.down.circle.fill",
                rangeHint: hint
            )
        case 15..<24:
            return CompositionCategory(
                title: "理想",
                subtitle: "维持目前的训练节奏与营养结构。",
                color: .green,
                icon: "checkmark.circle.fill",
                rangeHint: hint
            )
        case 24..<30:
            return CompositionCategory(
                title: "偏高",
                subtitle: "控制精制碳水摄入，并提升力量+有氧训练组合。",
                color: .orange,
                icon: "exclamationmark.triangle.fill",
                rangeHint: hint
            )
        default:
            return CompositionCategory(
                title: "较高",
                subtitle: "建议与教练/营养师协作，分阶段优化体脂率。",
                color: .red,
                icon: "flame.fill",
                rangeHint: hint
            )
        }
    }
}

struct StatusChip: View {
    let status: CompositionCategory?

    var body: some View {
        if let status {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                Text(status.title)
            }
            .font(.caption.weight(.semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(status.color.opacity(0.15), in: Capsule())
            .foregroundStyle(status.color)
        } else {
            Text("未记录")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.secondary.opacity(0.12), in: Capsule())
        }
    }
}

struct LinearProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * CGFloat(max(0, min(1, progress))))
            }
        }
        .frame(height: 8)
    }
}
