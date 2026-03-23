//
//  HealthKitManager.swift
//  ProteineCreatineApp
//
//  Created on 3/20/26.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var sleepData: [SleepDataPoint] = []
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    
    init() {
        checkAuthorization()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let typesToRead: Set<HKObjectType> = [sleepType]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        await MainActor.run {
            self.isAuthorized = true
        }
    }
    
    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "Health data not available on this device"
            return
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let status = healthStore.authorizationStatus(for: sleepType)
        
        DispatchQueue.main.async {
            self.isAuthorized = status == .sharingAuthorized
        }
    }
    
    // MARK: - Fetch Sleep Data
    func fetchSleepData(days: Int = 30) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Create date range
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(throwing: HealthKitError.invalidData)
                    return
                }
                
                // Process sleep data
                let sleepDataPoints = self.processSleepSamples(samples, days: days)
                
                DispatchQueue.main.async {
                    self.sleepData = sleepDataPoints
                }
                
                continuation.resume()
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Process Sleep Samples
    private func processSleepSamples(_ samples: [HKCategorySample], days: Int) -> [SleepDataPoint] {
        let calendar = Calendar.current
        var sleepByDate: [Date: SleepDataPoint] = [:]
        
        for sample in samples {
            let startOfDay = calendar.startOfDay(for: sample.endDate)
            
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600 // hours
            
            // Determine sleep stage
            let stage: SleepStage
            if #available(iOS 16.0, *) {
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                     HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    stage = .core
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    stage = .deep
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    stage = .rem
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    stage = .awake
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    stage = .inBed
                default:
                    stage = .core
                }
            } else {
                // iOS 15 and earlier
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleep.rawValue:
                    stage = .core
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    stage = .awake
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    stage = .inBed
                default:
                    stage = .core
                }
            }
            
            // Aggregate by date
            if var existingData = sleepByDate[startOfDay] {
                existingData.totalHours += duration
                
                switch stage {
                case .core:
                    existingData.coreHours += duration
                case .deep:
                    existingData.deepHours += duration
                case .rem:
                    existingData.remHours += duration
                case .awake:
                    existingData.awakeHours += duration
                case .inBed:
                    existingData.inBedHours += duration
                }
                
                sleepByDate[startOfDay] = existingData
            } else {
                var dataPoint = SleepDataPoint(date: startOfDay)
                dataPoint.totalHours = duration
                
                switch stage {
                case .core:
                    dataPoint.coreHours = duration
                case .deep:
                    dataPoint.deepHours = duration
                case .rem:
                    dataPoint.remHours = duration
                case .awake:
                    dataPoint.awakeHours = duration
                case .inBed:
                    dataPoint.inBedHours = duration
                }
                
                sleepByDate[startOfDay] = dataPoint
            }
        }
        
        return sleepByDate.values.sorted { $0.date > $1.date }
    }
}

// MARK: - Models
struct SleepDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    var totalHours: Double = 0
    var coreHours: Double = 0
    var deepHours: Double = 0
    var remHours: Double = 0
    var awakeHours: Double = 0
    var inBedHours: Double = 0
    
    var quality: SleepQuality {
        if totalHours >= 7 && totalHours <= 9 {
            return .good
        } else if totalHours >= 6 || totalHours <= 10 {
            return .fair
        } else {
            return .poor
        }
    }
}

enum SleepStage {
    case core, deep, rem, awake, inBed
}

enum SleepQuality {
    case good, fair, poor
    
    var color: String {
        switch self {
        case .good: return "green"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
}

enum HealthKitError: Error {
    case notAvailable
    case invalidData
    case authorizationDenied
    
    var description: String {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .invalidData:
            return "Invalid health data received"
        case .authorizationDenied:
            return "Authorization denied for health data"
        }
    }
}
