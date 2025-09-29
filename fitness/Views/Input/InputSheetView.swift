import SwiftUI
import SwiftData

struct InputSheetView: View {
    @EnvironmentObject var weightManager: WeightManager
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \HealthMetric.date, order: .reverse) private var records: [HealthMetric]

    @State private var selectedMetric: MetricType = .weight
    @State private var currentWeight: Double?
    @State private var bodyFatPercentage: Double?
    @State private var waistCircumference: Double?
    @State private var date: Date = Date()
    @FocusState private var focused: Bool

    var baseWeight: Double {
        records.first(where: { $0.type == .weight })?.value ?? 70.0
    }
    
    var baseBodyFat: Double {
        records.first(where: { $0.type == .bodyFatPercentage })?.value ?? 20.0
    }
    
    var baseWaistCircumference: Double {
        records.first(where: { $0.type == .waistCircumference })?.value ?? 80.0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) { // Increased spacing
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(MetricType.allCases.filter { [.weight, .bodyFatPercentage, .waistCircumference].contains($0) }, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    switch selectedMetric {
                    case .weight:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("体重").font(.headline)
                            WeightSlider(weight: $currentWeight, initialWeight: baseWeight)
                            if !isWeightValid(currentWeight) {
                                Text("体重必须在30到200公斤之间。")
                                    .foregroundColor(.red).font(.footnote)
                            } else {
                                Text("测量建议：晨起空腹，以保证数据一致性")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    case .bodyFatPercentage:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("体脂率").font(.headline)
                            BodyFatSlider(percentage: $bodyFatPercentage, initialPercentage: baseBodyFat)
                            if !isBodyFatValid(bodyFatPercentage) {
                                Text("体脂率必须在3%到50%之间。")
                                    .foregroundColor(.red).font(.footnote)
                            } else {
                                Text("读数建议：读数易受水分影响，关注长期趋势更佳")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    case .waistCircumference:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("腰围").font(.headline)
                            WaistCircumferenceSlider(circumference: $waistCircumference, initialCircumference: baseWaistCircumference)
                            if !isWaistValid(waistCircumference) {
                                Text("腰围必须在50到150cm之间。")
                                    .foregroundColor(.red).font(.footnote)
                            } else {
                                Text("测量标准：参考世界卫生组织(WHO) STEPS 方案")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    default:
                        EmptyView()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("日期").font(.headline)
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }

                    .buttonStyle(.borderedProminent)
                    .disabled(isSaveButtonDisabled())
                    .padding(.top)
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .onAppear { 
            currentWeight = baseWeight
            bodyFatPercentage = baseBodyFat
            waistCircumference = baseWaistCircumference
        }
        .presentationDetents([.fraction(0.45)]) // Adjusted height
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }

    private func isSaveButtonDisabled() -> Bool {
        switch selectedMetric {
        case .weight:
            return !isWeightValid(currentWeight)
        case .bodyFatPercentage:
            return !isBodyFatValid(bodyFatPercentage)
        case .waistCircumference:
            return !isWaistValid(waistCircumference)
        default:
            return true
        }
    }

    private func isWeightValid(_ w: Double?) -> Bool {
        guard let weightValue = w else { return false } 
        return (30...200).contains(weightValue)
    }
    
    private func isBodyFatValid(_ p: Double?) -> Bool {
        guard let percentageValue = p else { return false } 
        return (3...50).contains(percentageValue)
    }
    
    private func isWaistValid(_ c: Double?) -> Bool {
        guard let circumferenceValue = c else { return false } 
        return (50...150).contains(circumferenceValue)
    }

    private func save() {
        var metricToSave: HealthMetric? = nil
        
        switch selectedMetric {
        case .weight:
            if let value = currentWeight, isWeightValid(value) {
                metricToSave = HealthMetric(date: date, value: value, type: .weight)
            }
        case .bodyFatPercentage:
            if let value = bodyFatPercentage, isBodyFatValid(value) {
                metricToSave = HealthMetric(date: date, value: value, type: .bodyFatPercentage)
            }
        case .waistCircumference:
            if let value = waistCircumference, isWaistValid(value) {
                metricToSave = HealthMetric(date: date, value: value, type: .waistCircumference)
            }
        default:
            break
        }
        
        if let metric = metricToSave {
            weightManager.addMetric(metric)
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}