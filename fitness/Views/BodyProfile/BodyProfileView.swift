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
    @Query(sort: \HealthMetric.date, order: .reverse) private var metrics: [HealthMetric]
    
    @State private var showInputSheet = false
    @State private var selectedChartMetric: ChartableMetric = .weight
    @State private var selectedRange: BodyProfileViewModel.TimeRange = .thirty
    @StateObject private var vm = BodyProfileViewModel()

    // Computed properties to get latest values
    private var latestWeight: Double {
        metrics.first(where: { $0.type == .weight })?.value ?? 0
    }
    private var latestBodyFat: Double {
        metrics.first(where: { $0.type == .bodyFatPercentage })?.value ?? 0
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

    private var chartData: [DateValuePoint] { vm.chartData }
    
    private var chartTitle: String {
        "\(selectedChartMetric.rawValue)趋势"
    }
    
    private var chartColor: Color {
        switch selectedChartMetric {
        case .weight: return .blue
        case .bodyFat: return .orange
        case .waist: return .purple
        case .heartRate: return .red
        case .vo2Max: return .teal
        }
    }
    
    private var chartUnit: String {
        switch selectedChartMetric {
        case .weight: return "kg"
        case .bodyFat: return "%"
        case .waist: return "cm"
        case .heartRate: return "bpm"
        case .vo2Max: return "ml/kg/min"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    permissionSection
                    emptyDataHintSection
                    currentIndicatorsSection
                    vo2QuickSection
                    chartSection
                    additionalMetricsSection
                    bodyCompositionSection
                    insightsSection
                    visualRecordsSection
                    Spacer(minLength: 80)
                }
                .padding(.vertical)
            }

            floatingActionButton
        }
        .onAppear { refreshVM() }
        .onChange(of: metrics.map(\.date)) { _ in refreshVM() }
        .onChange(of: selectedChartMetric) { _ in refreshVM() }
        .onChange(of: selectedRange) { _ in refreshVM() }
        .sheet(isPresented: $showInputSheet) {
            InputSheetView()
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
        return metricSection(title: "当前指标", items: items)
    }

    @ViewBuilder private var vo2QuickSection: some View {
        if let latest = metrics.first(where: { $0.type == .vo2Max })?.value, latest > 0 {
            let items = [MetricDisplay(title: "VO2max", value: formatted(latest, precision: 1), unit: "ml/kg/min", icon: "lungs.fill", color: .teal)]
            metricSection(title: "心肺耐力", items: items)
        }
    }

    private var chartSection: some View {
        VStack(spacing: 16) {
            Picker("Select Metric", selection: $selectedChartMetric) {
                ForEach(ChartableMetric.allCases) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Picker("Range", selection: $selectedRange) {
                ForEach(BodyProfileViewModel.TimeRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            let title = chartTitle
            let data = chartData
            let color = chartColor
            let unit = chartUnit
            let avg = vm.averageValue
            let goal = vm.goalValue
            GenericLineChartView(title: title, data: data, color: color, unit: unit, averageValue: avg, goalValue: goal)
                .frame(minHeight: 220)
        }
        .padding(.horizontal)
    }

    private var additionalMetricsSection: some View {
        let items: [MetricDisplay] = [
            .init(title: "腰围", value: formatted(latestWaistCircumference, precision: 1), unit: "cm", icon: "tape.measure", color: .purple),
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

    @ViewBuilder private var insightsSection: some View {
        if !vm.insights.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("建议与解读").font(.title3).bold().padding(.horizontal)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(vm.insights, id: \.self) { line in
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                            Text(line).font(.footnote)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

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

    private var floatingActionButton: some View {
        Button(action: { showInputSheet = true }) {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 10)
        }
        .padding()
    }

    // MARK: - Permission & Empty Data
    @ViewBuilder private var permissionSection: some View {
        // Check core read permissions for body data
        let required: [HealthKitDataTypeOption] = [.bodyMass, .bodyFatPercentage, .heartRate, .vo2Max]
        let unauthorized = required.filter { healthKitManager.getPublishedAuthorizationStatus(for: $0) != .sharingAuthorized }
        if !unauthorized.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("未授权读取健康数据")
                        .font(.headline)
                }
                Text("请在健康 App 中授权“体重、体脂率、心率、VO2max”等数据，便于生成完整的身体档案与趋势。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button(action: openHealthApp) {
                        Label("前往健康 App 授权", systemImage: "heart.fill")
                    }.buttonStyle(.borderedProminent)
                    Button(action: { showInputSheet = true }) {
                        Label("手动记录", systemImage: "plus")
                    }.buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    @ViewBuilder private var emptyDataHintSection: some View {
        if metrics.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("还没有身体指标记录")
                    .font(.headline)
                Text("可以先手动添加一条体重或体脂记录，或在健康 App 中开启数据同步。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button(action: { showInputSheet = true }) {
                        Label("添加记录", systemImage: "plus")
                    }.buttonStyle(.borderedProminent)
                    Button(action: openHealthApp) {
                        Label("打开健康 App", systemImage: "heart")
                    }.buttonStyle(.bordered)
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
    private func metricSection(title: String, items: [MetricDisplay]) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { item in
                    MetricCard(
                        title: item.title,
                        value: item.value,
                        unit: item.unit,
                        icon: item.icon,
                        color: item.color
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

private extension BodyProfileView {
    func refreshVM() {
        vm.selectedMetric = selectedChartMetric
        vm.timeRange = selectedRange
        vm.refresh(metrics: metrics, profile: profileViewModel.userProfile)
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
