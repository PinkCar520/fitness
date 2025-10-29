import Foundation
import Combine
import SwiftData
import HealthKit
import WidgetKit

final class WeightManager: ObservableObject {
    // @Published var records: [WeightRecord] = [] // This will be replaced by @Query in views
    // @Published var latestRecord: WeightRecord? = nil // This will be replaced by @Query in views
    
    // Alert 信息供 UI 绑定
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    private let modelContainer: ModelContainer
    private let healthKitManager: any HealthKitManagerProtocol

    init(healthKitManager: any HealthKitManagerProtocol, modelContainer: ModelContainer) {
        self.healthKitManager = healthKitManager
        self.modelContainer = modelContainer
    }
    
    // `load()` is no longer needed with SwiftData.

    // MARK: - CRUD
#if !os(watchOS)
    @MainActor
    func add(weight: Double, date: Date = Date()) {
        guard (30...200).contains(weight) else {
            alertMessage = "⚠️ 体重 \(weight)kg 不在有效范围 30~200kg"
            showAlert = true
            return
        }
        let newMetric = HealthMetric(date: date, value: round(weight * 10)/10, type: .weight)
        addMetric(newMetric)
    }

    @MainActor
    func addMetric(_ metric: HealthMetric) {
        let context = modelContainer.mainContext
        context.insert(metric)
        
        // Persist to HealthKit and notify widgets
        switch metric.type {
        case .weight:
            healthKitManager.saveWeight(metric.value, date: metric.date)
        case .bodyFatPercentage:
            healthKitManager.saveBodyFatPercentage(metric.value, date: metric.date)
        case .waistCircumference:
            healthKitManager.saveWaistCircumference(metric.value, date: metric.date)
        case .heartRate:
            healthKitManager.saveHeartRate(metric.value, date: metric.date)
        default:
            // Not all types are saved to HealthKit
            break
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // The update logic will be handled directly by modifying the object in the view,
    // as SwiftData tracks changes automatically.

    @MainActor
    func delete(_ metric: HealthMetric) {
        let context = modelContainer.mainContext
        let dateToDelete = metric.date
        context.delete(metric)
        
        Task {
            let success = await healthKitManager.deleteWeight(date: dateToDelete)
            if !success {
                print("Warning: Could not delete corresponding weight from HealthKit.")
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    func clearAll() {
        let context = modelContainer.mainContext
        do {
            try context.delete(model: HealthMetric.self)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to clear all HealthMetrics: \(error)")
        }
    }
    
    @MainActor
    func importHealthKitSamples(_ samples: [HKQuantitySample]) {
        let context = modelContainer.mainContext
        
        // Fetch existing metrics to prevent duplicates
        let existingMetrics = (try? context.fetch(FetchDescriptor<HealthMetric>())) ?? []
        let existingDates = Set(existingMetrics.map { $0.date })

        for sample in samples {
            let date = sample.endDate
            // Check for duplicates before adding
            if !existingDates.contains(date) {
                let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                let newMetric = HealthMetric(date: date, value: round(weight * 10)/10, type: .weight)
                context.insert(newMetric)
            }
        }
        
        // Notify widgets to reload their timelines
        WidgetCenter.shared.reloadAllTimelines()
    }
#endif

#if !os(watchOS)
    @MainActor
    func syncHealthKitSample(_ sample: HKQuantitySample) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
              sample.quantityType == weightType else {
            return
        }

        let context = modelContainer.mainContext
        let start = sample.endDate.addingTimeInterval(-1)
        let end = sample.endDate.addingTimeInterval(1)

        let descriptor = FetchDescriptor<HealthMetric>(
            predicate: #Predicate { metric in
                metric.date >= start && metric.date <= end
            }
        )

        let existing = (try? context.fetch(descriptor)) ?? []
        guard !existing.contains(where: { $0.type == .weight }) else { return }

        let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        let newMetric = HealthMetric(date: sample.endDate, value: round(weight * 10) / 10, type: .weight)
        context.insert(newMetric)
        WidgetCenter.shared.reloadAllTimelines()
    }
#endif

    // MARK: - 派生数据
    // The derived data functions (weightChange, averageWeight) will be
    // re-implemented directly in the UI layer using SwiftData's @Query property wrapper,
    // which is more efficient.
    
}

private extension String {
    var nilIfEmpty: String? { self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}
