import Foundation
import HealthKit
import SwiftUI
import Combine

struct DailyStepData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Double
}

struct DailyDistanceData: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double
}

protocol HealthKitManagerProtocol: ObservableObject {
    func saveWeight(_ weight: Double, date: Date)
    func saveBodyFatPercentage(_ percentage: Double, date: Date)
    func saveWaistCircumference(_ circumference: Double, date: Date)
    func saveHeartRate(_ rate: Double, date: Date)
    func deleteWeight(date: Date) async -> Bool
    // Add other methods that WeightManager directly calls on HealthKitManager if needed
}

enum HealthKitAuthorizationStatus {
    case authorized
    case denied
    case notDetermined
}

enum HealthDataType {
    case steps
    case distance
}

final class HealthKitManager: ObservableObject, HealthKitManagerProtocol, @unchecked Sendable {
    private let healthStore = HKHealthStore()
#if !os(watchOS)
    private weak var weightManager: WeightManager?
#endif
    @Published var lastWeightSample: HKQuantitySample?
    @Published var lastBodyFatSample: HKQuantitySample?
    @Published var lastWaistCircumferenceSample: HKQuantitySample?
    @Published var lastVO2MaxSample: HKQuantitySample?
    @Published var lastSavedWeight: Double?
    @Published var stepCount: Double = 0
    @Published var distance: Double = 0
    @Published var activitySummary: HKActivitySummary?
    @Published var weeklyStepData: [DailyStepData] = []
    @Published var weeklyDistanceData: [DailyDistanceData] = []
        @Published var authorizationStatus: [HealthKitDataTypeOption: HKAuthorizationStatus] = [:]


    
    // 请求授权
        func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        print("xxx")
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let bodyFatPercentageType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let waistCircumferenceType = HKQuantityType.quantityType(forIdentifier: .waistCircumference)!
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let activitySummaryType = HKObjectType.activitySummaryType()
        let activeEnergyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let workoutType = HKObjectType.workoutType()
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!

        let typesToRead: Set<HKObjectType> = [weightType, bodyFatPercentageType, waistCircumferenceType, stepType, distanceType, activitySummaryType, activeEnergyBurnedType, workoutType, heartRateType, sleepAnalysisType, vo2MaxType]
        let typesToWrite: Set<HKSampleType> = [weightType, bodyFatPercentageType, waistCircumferenceType, workoutType, sleepAnalysisType, heartRateType]

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error)")
                completion(false)
            } else {
                print("HealthKit authorization success: \(success)")
                completion(success)
            }
        }
    }
    
    // 保存体重
    func saveWeight(_ weight: Double, date: Date = Date()) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weight)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit save error: \(error)")
                } else {
                    print("Saved to HealthKit: \(weight) kg")
                    self.lastSavedWeight = weight
                }
            }
        }
    }
    
    // 保存体脂率
    func saveBodyFatPercentage(_ percentage: Double, date: Date = Date()) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        let quantity = HKQuantity(unit: .percent(), doubleValue: percentage / 100.0) // HealthKit expects value between 0-1
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit save body fat error: \(error)")
                } else {
                    print("Saved to HealthKit: \(percentage)%")
                }
            }
        }
    }
    
    // 保存腰围
    func saveWaistCircumference(_ circumference: Double, date: Date = Date()) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .waistCircumference) else { return }
        let quantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: circumference)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit save waist circumference error: \(error)")
                } else {
                    print("Saved to HealthKit: \(circumference) cm")
                }
            }
        }
    }
    
    // 保存心率
    func saveHeartRate(_ rate: Double, date: Date = Date()) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let quantity = HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: rate)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit save heart rate error: \(error)")
                } else {
                    print("Saved to HealthKit: \(rate) bpm")
                }
            }
        }
    }
    
    // 读取最近体重
    func readMostRecentWeight() async -> HKQuantitySample? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: Date(), options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
                continuation.resume(returning: results?.first as? HKQuantitySample)
            }
            healthStore.execute(query)
        }
    }

    // 读取最近体脂率
    func readMostRecentBodyFat() async -> HKQuantitySample? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: Date(), options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
                continuation.resume(returning: results?.first as? HKQuantitySample)
            }
            healthStore.execute(query)
        }
    }

    // 读取最近 VO2max
    func readMostRecentVO2Max() async -> HKQuantitySample? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return nil }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: Date(), options: .strictEndDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
                continuation.resume(returning: results?.first as? HKQuantitySample)
            }
            healthStore.execute(query)
        }
    }

    // 读取最近腰围
    func readMostRecentWaistCircumference() async -> HKQuantitySample? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .waistCircumference) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: Date(), options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
                continuation.resume(returning: results?.first as? HKQuantitySample)
            }
            healthStore.execute(query)
        }
    }

    // 读取最近体重 for widget
    func fetchMostRecentWeight(completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard error == nil, let sample = results?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            completion(weight)
        }
        healthStore.execute(query)
    }

    // 读取所有体重样本
    func readAllWeightSamples(completion: @escaping ([HKQuantitySample]?, Error?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil, NSError(domain: "HealthKitManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Body Mass Type not available"]))
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true) // Ascending for chronological order
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error reading all weight samples: \(error.localizedDescription)")
                    completion(nil, error)
                } else {
                    completion(samples as? [HKQuantitySample], nil)
                }
            }
        }
        healthStore.execute(query)
    }
    
    // 开始监听体重变化
    func startWeightObserver() {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("HealthKit observer query error: \(error)")
                completionHandler()
                return
            }
            
            Task { @MainActor in
                guard let self = self else { return }
                let sample = await self.readMostRecentWeight()
                self.lastWeightSample = sample
#if !os(watchOS)
                if let sample {
                    self.weightManager?.syncHealthKitSample(sample)
                }
#endif
            }
            completionHandler()
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
            if let error = error {
                print("HealthKit enable background delivery error: \(error)")
            }
        }
    }

    // 读取当天步数
    func readStepCount() async -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: .count()))
            }
            healthStore.execute(query)
        }
    }

    // 读取过去7天的每日步数
    func readWeeklyStepCounts() async -> [DailyStepData] {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }

        let calendar = Calendar.current
        var dailyStepData: [DailyStepData] = []
        let dispatchGroup = DispatchGroup() // Use DispatchGroup to wait for all queries

        for i in 0..<7 {
            dispatchGroup.enter()
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else {
                dispatchGroup.leave()
                continue
            }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)! // 结束日期是下一天的开始

            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                // Ensure thread safety when appending to dailyStepData
                DispatchQueue.main.async {
                    dailyStepData.append(DailyStepData(date: startOfDay, steps: steps))
                    dispatchGroup.leave()
                }
            }
            healthStore.execute(query)
        }

        // Wait for all queries to complete
        return await withCheckedContinuation { continuation in
            dispatchGroup.notify(queue: .main) {
                continuation.resume(returning: dailyStepData.sorted { $0.date < $1.date })
            }
        }
    }

    // 读取过去7天的每日距离
    func readWeeklyDistance() async -> [DailyDistanceData] {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return [] }

        let calendar = Calendar.current
        var dailyDistanceData: [DailyDistanceData] = []
        let dispatchGroup = DispatchGroup() // Use DispatchGroup to wait for all queries

        for i in 0..<7 {
            dispatchGroup.enter()
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else {
                dispatchGroup.leave()
                continue
            }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)! // 结束日期是下一天的开始

            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let distance = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                // Ensure thread safety when appending to dailyDistanceData
                DispatchQueue.main.async {
                    dailyDistanceData.append(DailyDistanceData(date: startOfDay, distance: distance))
                    dispatchGroup.leave()
                }
            }
            healthStore.execute(query)
        }

        // Wait for all queries to complete
        return await withCheckedContinuation { continuation in
            dispatchGroup.notify(queue: .main) {
                continuation.resume(returning: dailyDistanceData.sorted { $0.date < $1.date })
            }
        }
    }

    // 读取当天距离
    func readDistance() async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: .meter()))
            }
            healthStore.execute(query)
        }
    }

    // 读取当天活动总结
    func readActivitySummary() async -> HKActivitySummary? {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.calendar = calendar
        
        let predicate = HKQuery.predicateForActivitySummary(with: components)
        
        return await withCheckedContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, _ in
                continuation.resume(returning: summaries?.first)
            }
            healthStore.execute(query)
        }
    }

    // New function to fetch monthly activity summaries
    func fetchMonthlyActivitySummaries(completion: @escaping ([Int: Bool]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now),
              let numberOfDays = calendar.range(of: .day, in: .month, for: now)?.count else {
            completion([:])
            return
        }

        var dailyResults: [Int: Bool] = [:]
        let dispatchGroup = DispatchGroup()

        for dayOffset in 0..<numberOfDays {
            dispatchGroup.enter()
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start) else {
                dispatchGroup.leave()
                continue
            }

            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.calendar = calendar

            let predicate = HKQuery.predicateForActivitySummary(with: components)
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                let day = calendar.component(.day, from: date)
                if let summary = summaries?.first {
                    let energyGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
                    let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
                    let standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())

                    let energyMet = energyGoal > 0 && summary.activeEnergyBurned.doubleValue(for: .kilocalorie()) >= energyGoal
                    let exerciseMet = exerciseGoal > 0 && summary.appleExerciseTime.doubleValue(for: .minute()) >= exerciseGoal
                    let standMet = standGoal > 0 && summary.appleStandHours.doubleValue(for: .count()) >= standGoal

                    dailyResults[day] = energyMet && exerciseMet && standMet
                } else {
                    dailyResults[day] = false
                }
                dispatchGroup.leave()
            }
            healthStore.execute(query)
        }

        dispatchGroup.notify(queue: .main) {
            completion(dailyResults)
        }
    }

    func fetchTotalActiveEnergy(for days: Int, completion: @escaping (Double) -> Void) {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    completion(0)
                    return
                }
                completion(sum.doubleValue(for: .kilocalorie()))
            }
        }
        healthStore.execute(query)
    }

    func fetchWorkoutDays(for days: Int, completion: @escaping (Int) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            DispatchQueue.main.async {
                guard let workouts = samples as? [HKWorkout] else {
                    completion(0)
                    return
                }
                let distinctDays = Set(workouts.map { Calendar.current.startOfDay(for: $0.startDate) })
                completion(distinctDays.count)
            }
        }
        healthStore.execute(query)
    }

    #if !os(watchOS)
    // New method to encapsulate HealthKit setup and initial data import
    func setupHealthKitData(weightManager: WeightManager) async {
        self.weightManager = weightManager
        requestAuthorization { [weak self] success in
            guard let self = self else { return }
            if success {
                self.startWeightObserver()
                let hasPerformedInitialHealthKitImport = UserDefaults.standard.bool(forKey: "hasPerformedInitialHealthKitImport")

                if !hasPerformedInitialHealthKitImport {
                    print("Performing initial HealthKit import...")
                    self.readAllWeightSamples { samples, error in
                        if let samples = samples {
                            Task { @MainActor in
                                self.weightManager?.importHealthKitSamples(samples)
                                UserDefaults.standard.set(true, forKey: "hasPerformedInitialHealthKitImport")
                            }
                        } else if let error = error {
                            print("Failed to import HealthKit samples: \(error.localizedDescription)")
                            UserDefaults.standard.set(true, forKey: "hasPerformedInitialHealthKitImport")
                        }
                        // After import (or failure), proceed with regular data fetching
                        Task { @MainActor in
                            self.lastWeightSample = await self.readMostRecentWeight()
#if !os(watchOS)
                            if let sample = self.lastWeightSample {
                                self.weightManager?.syncHealthKitSample(sample)
                            }
#endif
                            self.lastBodyFatSample = await self.readMostRecentBodyFat()
                            self.lastWaistCircumferenceSample = await self.readMostRecentWaistCircumference()
                            self.stepCount = await self.readStepCount()
                            self.distance = await self.readDistance()
                            self.activitySummary = await self.readActivitySummary()
                            self.weeklyStepData = await self.readWeeklyStepCounts()
                            self.weeklyDistanceData = await self.readWeeklyDistance()
                        }
                    }
                } else {
                    // If import already performed, just do regular data fetching
                    Task { @MainActor in
                        self.lastWeightSample = await self.readMostRecentWeight()
#if !os(watchOS)
                        if let sample = self.lastWeightSample {
                            self.weightManager?.syncHealthKitSample(sample)
                        }
#endif
                        self.lastBodyFatSample = await self.readMostRecentBodyFat()
                        self.lastWaistCircumferenceSample = await self.readMostRecentWaistCircumference()
                        self.stepCount = await self.readStepCount()
                        self.distance = await self.readDistance()
                        self.activitySummary = await self.readActivitySummary()
                        self.weeklyStepData = await self.readWeeklyStepCounts()
                        self.weeklyDistanceData = await self.readWeeklyDistance()
                    }
                }
            }
        }
    }
#endif

    func getPublishedAuthorizationStatus(for dataType: HealthKitDataTypeOption) -> HKAuthorizationStatus {
        return authorizationStatus[dataType] ?? .notDetermined
    }

    func updateAuthorizationStatuses() {
        for dataType in HealthKitDataTypeOption.allCases {
            if let hkObjectType = dataType.hkObjectType {
                if let sampleType = hkObjectType as? HKSampleType {
                    let status = self.healthStore.authorizationStatus(for: sampleType)
                    print("HealthKitManager: Checking status for \(dataType.title) (\(sampleType.identifier)): \(status.rawValue)")
                    DispatchQueue.main.async {
                        self.authorizationStatus[dataType] = status
                    }
                } else {
                    print("HealthKitManager: \(dataType.title) (\(hkObjectType.identifier)) is not an HKSampleType. Setting status to notDetermined.")
                    DispatchQueue.main.async {
                        self.authorizationStatus[dataType] = .notDetermined
                    }
                }
            }
        }
    }

    // Fetches the most recent workout
    func fetchMostRecentWorkout() async -> HKWorkout? {
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: Date(), options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard error == nil, let mostRecentWorkout = samples?.first as? HKWorkout else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: mostRecentWorkout)
            }
            healthStore.execute(query)
        }
    }

    func deleteWeight(date: Date) async -> Bool {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }

        // Use a very small interval around the date to account for potential floating point inaccuracies.
        let predicate = HKQuery.predicateForSamples(withStart: date.addingTimeInterval(-1), end: date.addingTimeInterval(1), options: [])

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [self] _, samples, error in
                guard let samplesToDelete = samples, error == nil else {
                    continuation.resume(returning: false)
                    return
                }

                if samplesToDelete.isEmpty {
                    continuation.resume(returning: true) // Nothing to delete
                    return
                }
                
                self.healthStore.delete(samplesToDelete) { success, error in
                    Task { @MainActor in
                        if let error = error {
                            print("Error deleting from HealthKit: \(error.localizedDescription)")
                        }
                        continuation.resume(returning: success)
                    }
                }
            }
            healthStore.execute(query)
        }
    }

#if os(iOS) && !targetEnvironment(macCatalyst)
    // 打开健康 App
//    func openHealthApp() {
//        if let url = URL(string: "x-health-app://"), UIApplication.shared.canOpenURL(url) {
//            UIApplication.shared.open(url)
//        } else if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
//            UIApplication.shared.open(url)
//        }
//    }
#endif

}
