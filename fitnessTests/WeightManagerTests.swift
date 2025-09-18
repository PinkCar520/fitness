import XCTest
import Combine
import SwiftData
@testable import fitness

// MARK: - Mock HealthKitManager
class MockHealthKitManager: HealthKitManagerProtocol {
    var saveWeightCalled = false
    var savedWeight: Double?
    var savedDate: Date?

    // ObservableObject conformance for the protocol
    var objectWillChange = ObservableObjectPublisher()

    func saveWeight(_ weight: Double, date: Date) {
        saveWeightCalled = true
        savedWeight = weight
        savedDate = date
    }
}

// MARK: - WeightManager Tests
@MainActor
final class WeightManagerTests: XCTestCase {

    var weightManager: WeightManager!
    var mockHealthKitManager: MockHealthKitManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        
        // 1. Create an in-memory SwiftData container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: HealthMetric.self, configurations: config)
        modelContext = modelContainer.mainContext
        
        // 2. Initialize mocks and the manager
        mockHealthKitManager = MockHealthKitManager()
        weightManager = WeightManager(healthKitManager: mockHealthKitManager, modelContainer: modelContainer)
        
        cancellables = []
    }

    override func tearDown() {
        weightManager = nil
        mockHealthKitManager = nil
        modelContainer = nil
        modelContext = nil
        cancellables = nil
        super.tearDown()
    }

    private func fetchAllMetrics() throws -> [HealthMetric] {
        let descriptor = FetchDescriptor<HealthMetric>(sortBy: [SortDescriptor(\.date)])
        return try modelContext.fetch(descriptor)
    }

    func testAddValidWeightRecord() throws {
        let testWeight = 75.5
        let testDate = Date()

        // Pre-condition: No metrics in the store
        XCTAssertEqual(try fetchAllMetrics().count, 0)

        weightManager.add(weight: testWeight, date: testDate)

        // Verification
        let metrics = try fetchAllMetrics()
        XCTAssertEqual(metrics.count, 1)
        XCTAssertEqual(metrics.first?.value, testWeight)
        XCTAssertEqual(metrics.first?.date, testDate)

        // Verify HealthKitManager interaction
        XCTAssertTrue(mockHealthKitManager.saveWeightCalled)
        XCTAssertEqual(mockHealthKitManager.savedWeight, testWeight)
        XCTAssertEqual(mockHealthKitManager.savedDate, testDate)

        // Verify alert state
        XCTAssertFalse(weightManager.showAlert)
        XCTAssertTrue(weightManager.alertMessage.isEmpty)
    }

    func testAddInvalidWeightRecordTooLow() throws {
        let testWeight = 25.0 // Invalid weight

        // Pre-condition: No metrics in the store
        XCTAssertEqual(try fetchAllMetrics().count, 0)
        
        let expectation = XCTestExpectation(description: "Show alert for invalid weight")
        weightManager.$showAlert
            .dropFirst()
            .sink { showAlert in
                if showAlert {
                    XCTAssertTrue(self.weightManager.showAlert)
                    XCTAssertFalse(self.weightManager.alertMessage.isEmpty)
                    XCTAssertTrue(self.weightManager.alertMessage.contains("不在有效范围"))
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        weightManager.add(weight: testWeight)

        // Verify no metric was added
        XCTAssertEqual(try fetchAllMetrics().count, 0)

        // Verify HealthKitManager was not called
        XCTAssertFalse(mockHealthKitManager.saveWeightCalled)

        wait(for: [expectation], timeout: 1.0)
    }

    func testAddInvalidWeightRecordTooHigh() throws {
        let testWeight = 250.0 // Invalid weight

        // Pre-condition: No metrics in the store
        XCTAssertEqual(try fetchAllMetrics().count, 0)

        weightManager.add(weight: testWeight)

        // Verify no metric was added
        XCTAssertEqual(try fetchAllMetrics().count, 0)
        
        // Verify HealthKitManager was not called
        XCTAssertFalse(mockHealthKitManager.saveWeightCalled)

        // Verify alert state
        XCTAssertTrue(weightManager.showAlert)
        XCTAssertFalse(weightManager.alertMessage.isEmpty)
        XCTAssertTrue(weightManager.alertMessage.contains("不在有效范围"))
    }

    func testAddWeightRecordRoundsCorrectly() throws {
        let testWeight = 75.123
        weightManager.add(weight: testWeight)
        
        let metrics = try fetchAllMetrics()
        XCTAssertEqual(metrics.count, 1)
        XCTAssertEqual(metrics.first?.value, 75.1) // Should be rounded to one decimal place
    }

    func testAddMultipleRecords() throws {
        let date1 = Date(timeIntervalSinceNow: -3600 * 24 * 2) // 2 days ago
        let date2 = Date(timeIntervalSinceNow: -3600 * 24 * 1) // 1 day ago
        let date3 = Date() // Today

        weightManager.add(weight: 70.0, date: date2)
        weightManager.add(weight: 69.0, date: date1)
        weightManager.add(weight: 71.0, date: date3)

        let metrics = try fetchAllMetrics()
        XCTAssertEqual(metrics.count, 3)

        // Verify sorting (FetchDescriptor handles this)
        XCTAssertEqual(metrics[0].date, date1)
        XCTAssertEqual(metrics[1].date, date2)
        XCTAssertEqual(metrics[2].date, date3)
    }
    
    func testDeleteRecord() throws {
        let metric = HealthMetric(date: Date(), value: 70.0, type: .weight)
        modelContext.insert(metric)
        
        // Pre-condition: One metric in the store
        XCTAssertEqual(try fetchAllMetrics().count, 1)
        
        weightManager.delete(metric)
        
        // Verify metric was deleted
        XCTAssertEqual(try fetchAllMetrics().count, 0)
    }
    
    func testClearAll() throws {
        modelContext.insert(HealthMetric(date: Date(), value: 70.0, type: .weight))
        modelContext.insert(HealthMetric(date: Date(), value: 71.0, type: .weight))
        
        // Pre-condition: Two metrics in the store
        XCTAssertEqual(try fetchAllMetrics().count, 2)
        
        weightManager.clearAll()
        
        // Verify all metrics were deleted
        XCTAssertEqual(try fetchAllMetrics().count, 0)
    }
}