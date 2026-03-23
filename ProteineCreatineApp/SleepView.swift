//
//  SleepView.swift
//  ProteineCreatineApp
//
//  Created on 3/20/26.
//

import SwiftUI
import Charts

struct SleepView: View {
    @ObservedObject private var healthKitManager = HealthKitManager()
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedDataPoint: SleepDataPoint?
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15)
                .ignoresSafeArea()
            
            if healthKitManager.isAuthorized {
                sleepDataView
            } else {
                authorizationView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Authorization View
    private var authorizationView: some View {
        VStack(spacing: 30) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Sleep Tracking")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Allow access to your sleep data\nfrom the Health app")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    do {
                        try await healthKitManager.requestAuthorization()
                        try await healthKitManager.fetchSleepData()
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                    Text("Connect to Health")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.blue.gradient)
                .cornerRadius(15)
                .shadow(radius: 5)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Sleep Data View
    private var sleepDataView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    Text("Sleep Analysis")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if !healthKitManager.sleepData.isEmpty {
                        Text("Last 30 days")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.bottom, 10)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                        .padding(40)
                } else if healthKitManager.sleepData.isEmpty {
                    emptyStateView
                } else {
                    // Average Sleep Card
                    averageSleepCard
                    
                    // Sleep Trend Chart
                    sleepTrendChart
                    
                    // Sleep Quality Distribution
                    sleepQualityChart
                    
                    // Recent Sleep Data
                    recentSleepList
                }
                
                // Refresh Button
                Button(action: refreshData) {
                    HStack {
                        Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .font(.title3)
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                        Text("Refresh Data")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                .disabled(isLoading)
            }
        }
        .onAppear {
            if healthKitManager.sleepData.isEmpty {
                refreshData()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "zzz")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No Sleep Data")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Start tracking your sleep in the\nHealth app to see your data here")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Average Sleep Card
    private var averageSleepCard: some View {
        let averageHours = healthKitManager.sleepData.reduce(0.0) { $0 + $1.totalHours } / Double(healthKitManager.sleepData.count)
        
        return VStack(spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Average Sleep")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 8) {
                Text(String(format: "%.1f", averageHours))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("hours")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(averageHours >= 7 && averageHours <= 9 ? "Great!" : "Could be improved")
                .font(.subheadline)
                .foregroundColor(averageHours >= 7 && averageHours <= 9 ? .green : .orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((averageHours >= 7 && averageHours <= 9 ? Color.green : Color.orange).opacity(0.2))
                .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
        .padding(.horizontal)
    }
    
    // MARK: - Sleep Trend Chart
    private var sleepTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Sleep Duration Trend")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Chart {
                // Target range (7-9 hours)
                RectangleMark(
                    xStart: .value("Start", healthKitManager.sleepData.last?.date ?? Date()),
                    xEnd: .value("End", healthKitManager.sleepData.first?.date ?? Date()),
                    yStart: .value("Lower", 7.0),
                    yEnd: .value("Upper", 9.0)
                )
                .foregroundStyle(.green.opacity(0.1))
                
                ForEach(healthKitManager.sleepData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Hours", dataPoint.totalHours)
                    )
                    .foregroundStyle(.blue.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Hours", dataPoint.totalHours)
                    )
                    .foregroundStyle(.blue.opacity(0.2).gradient)
                }
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.green.opacity(0.3))
                        .frame(width: 10, height: 10)
                    Text("Target (7-9 hrs)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 10, height: 10)
                    Text("Your Sleep")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Sleep Quality Chart
    private var sleepQualityChart: some View {
        let qualityCounts = Dictionary(grouping: healthKitManager.sleepData) { $0.quality }
            .mapValues { $0.count }
        
        let chartData = [
            QualityData(quality: "Good", count: qualityCounts[.good] ?? 0, color: .green),
            QualityData(quality: "Fair", count: qualityCounts[.fair] ?? 0, color: .orange),
            QualityData(quality: "Poor", count: qualityCounts[.poor] ?? 0, color: .red)
        ]
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.purple)
                Text("Sleep Quality Distribution")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Chart(chartData) { data in
                BarMark(
                    x: .value("Quality", data.quality),
                    y: .value("Count", data.count)
                )
                .foregroundStyle(data.color.gradient)
                .cornerRadius(8)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Recent Sleep List
    private var recentSleepList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundColor(.cyan)
                Text("Recent Sleep Sessions")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            ForEach(Array(healthKitManager.sleepData.prefix(10))) { dataPoint in
                SleepSessionCard(dataPoint: dataPoint)
            }
        }
    }
    
    // MARK: - Refresh Data
    func refreshData() {
        isLoading = true
        Task {
            do {
                try await healthKitManager.fetchSleepData()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                isLoading = false
            }
        }
    }
}

// MARK: - Sleep Session Card
struct SleepSessionCard: View {
    let dataPoint: SleepDataPoint
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Date icon
                VStack(spacing: 2) {
                    Text(dataPoint.date.formatted(.dateTime.month(.abbreviated)))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(dataPoint.date.formatted(.dateTime.day()))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(width: 50)
                
                // Sleep info
                VStack(alignment: .leading, spacing: 4) {
                    Text(dataPoint.date.formatted(.dateTime.weekday(.wide)))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.caption)
                        Text(String(format: "%.1f hours", dataPoint.totalHours))
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Quality badge
                VStack(spacing: 4) {
                    Image(systemName: qualityIcon(for: dataPoint.quality))
                        .font(.title2)
                        .foregroundColor(qualityColor(for: dataPoint.quality))
                    
                    Text(dataPoint.quality.description)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(qualityColor(for: dataPoint.quality))
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    func qualityIcon(for quality: SleepQuality) -> String {
        switch quality {
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .poor: return "xmark.circle.fill"
        }
    }
    
    func qualityColor(for quality: SleepQuality) -> Color {
        switch quality {
        case .good: return .green
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - Quality Data
struct QualityData: Identifiable {
    let id = UUID()
    let quality: String
    let count: Int
    let color: Color
}

#Preview {
    NavigationStack {
        SleepView()
    }
}
