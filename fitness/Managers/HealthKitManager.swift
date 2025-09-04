
import Foundation
import HealthKit
import SwiftUI
import Combine

final class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var lastReadWeight: Double?
    @Published var lastSavedWeight: Double?

    
    // 请求授权
    func requestAuthorization() {
//        guard HKHealthStore.isHealthDataAvailable() else { return }
        print("xxx")
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let typesToRead: Set<HKObjectType> = [weightType]
        let typesToWrite: Set<HKSampleType> = [weightType]

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error)")
            } else {
                print("HealthKit authorization success: \(success)")
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
    
    // 读取最近体重
    func readMostRecentWeight() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            DispatchQueue.main.async {
                if let sample = results?.first as? HKQuantitySample {
                    let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    self.lastReadWeight = weight
                } else {
                    self.lastReadWeight = nil
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
            
            self?.readMostRecentWeight()
            completionHandler()
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
            if let error = error {
                print("HealthKit enable background delivery error: \(error)")
            }
        }
    }
}
