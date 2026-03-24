//
//  ContentView.swift
//  ProteineCreatineApp
//
//  Created by New  on 2/7/26.
//

import SwiftUI
import Charts

// MARK: - User Profile Model
enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

struct UserProfile {
    let name: String
    let gender: Gender
    let age: Int
    let height: Double // in cm
    let weight: Double // in kg
    
    var bmi: Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
}

struct ContentView: View {
    @State private var userProfile = UserProfile(
        name: "MetaboSat",
        gender: .female,
        age: 28,
        height: 165,
        weight: 60
    )
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.top, 20)
                        
                        Text("Hello \(userProfile.name)! 💪")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        
                        // User Profile Card
                        UserProfileCard(profile: userProfile)
                            .padding(.horizontal, 30)
                            .padding(.top, 10)
                        
                        // Text("Ready to crush your fitness goals?")
                        //     .font(.headline)
                        //     .foregroundColor(.white.opacity(0.9))
                        //     .multilineTextAlignment(.center)
                        //     .padding(.horizontal)
                        //     .padding(.top, 5)
                        NavigationLink(destination: BiomarkerView(userProfile: userProfile)) {
                            HStack {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.title2)
                                Text("View Health Metrics")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

// MARK: - User Profile Card
struct UserProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                ProfileInfoItem(icon: "person.fill", label: "Gender", value: profile.gender.rawValue, color: .pink)
                ProfileInfoItem(icon: "calendar", label: "Age", value: "\(profile.age) yrs", color: .orange)
            }
            
            HStack(spacing: 20) {
                ProfileInfoItem(icon: "ruler", label: "Height", value: "\(Int(profile.height)) cm", color: .green)
                ProfileInfoItem(icon: "scalemass", label: "Weight", value: "\(Int(profile.weight)) kg", color: .blue)
            }
            
            // BMI
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.red)
                Text("Body Mass Index: \(String(format: "%.1f", profile.bmi))")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.top, 4)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10)
    }
}

struct ProfileInfoItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Biomarker Data Model
struct Biomarker: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let unit: String
    var normalRange: ClosedRange<Double>
    let icon: String
    let color: Color
    let description: String
    let function: String
    let highRisk: String
    let lowRisk: String
    
    var status: BiomarkerStatus {
        // Each biomarker has its own logic
        switch name {
        case "Glucose":
            // Low = concern, Normal = optimal, High = concern
            if value < normalRange.lowerBound {
                return value < normalRange.lowerBound * 0.85 ? .critical : .outOfRange
            } else if value > normalRange.upperBound {
                return value > normalRange.upperBound * 1.15 ? .critical : .outOfRange
            } else {
                return .optimal
            }
            
        case "Ketones":
            // Low = not bad (optimal for non-keto), Optimal = 0.5-3.0, High = maybe concern
            if value <= normalRange.upperBound {
                return .optimal  // Low ketones are fine
            } else if value <= 3.0 {
                return .optimal  // Nutritional ketosis range
            } else if value <= 5.0 {
                return .outOfRange  // High but not critical
            } else {
                return .critical  // Very high, potential ketoacidosis
            }
            
        case "Cortisol":
            // Low = good, Normal = good, High = concern
            if value <= normalRange.upperBound {
                return .optimal  // Low to normal is good
            } else if value <= normalRange.upperBound * 1.2 {
                return .outOfRange  // Slightly elevated
            } else {
                return .critical  // Very high, chronic stress
            }
            
        default:
            // Generic fallback
            if value < normalRange.lowerBound {
                return .outOfRange
            } else if value > normalRange.upperBound {
                return .outOfRange
            } else {
                return .optimal
            }
        }
    }
    
    var statusColor: Color {
        return status.color
    }
}

enum BiomarkerStatus {
    case optimal, outOfRange, critical
    
    var description: String {
        switch self {
        case .optimal: return "Optimal"
        case .outOfRange: return "Out of Range"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .optimal: return .green
        case .outOfRange: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Historical Reading Model
struct BiomarkerReading: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// Extension to generate historical data
extension Biomarker {
    func generateHistoricalData(days: Int = 30) -> [BiomarkerReading] {
        var readings: [BiomarkerReading] = []
        let calendar = Calendar.current
        
        for dayOffset in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                // Generate values that trend toward current value
                let midPoint = (normalRange.lowerBound + normalRange.upperBound) / 2
                let variation = Double.random(in: -0.15...0.15)
                let baseValue = midPoint + (value - midPoint) * Double(days - dayOffset) / Double(days)
                let readingValue = baseValue * (1 + variation)
                
                readings.append(BiomarkerReading(date: date, value: readingValue))
            }
        }
        
        return readings
    }
}

// MARK: - Biomarker View
struct BiomarkerView: View {
    let userProfile: UserProfile
    @State private var biomarkers: [Biomarker] = []
    @State private var lastUpdated = Date()
    @State private var isRefreshing = false
    @State private var selectedBiomarker: Biomarker?
    @State private var showingDetail = false
    @ObservedObject private var healthKitManager = HealthKitManager()
    @State private var sleepAuthRequested = false
    @State private var showingSleepDetail = false
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg.rectangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Biomarker Monitoring")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Last updated: \(formattedDate)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 10)
                    
                    // Overall Status Card
                    OverallStatusCard(biomarkers: biomarkers)
                        .padding(.horizontal)
                    
                    // Comparison Chart
                    if !biomarkers.isEmpty {
                        BiomarkerComparisonChart(biomarkers: biomarkers)
                            .padding(.horizontal)
                    }
                    
                    // Sleep Data Card
                    Button(action: {
                        if healthKitManager.isAuthorized && !healthKitManager.sleepData.isEmpty {
                            showingSleepDetail = true
                        }
                    }) {
                        SleepDataCard(healthKitManager: healthKitManager, sleepAuthRequested: $sleepAuthRequested)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    // Biomarker Cards
                    LazyVStack(spacing: 15) {
                        ForEach(biomarkers) { biomarker in
                            Button(action: {
                                selectedBiomarker = biomarker
                                showingDetail = true
                            }) {
                                BiomarkerCard(biomarker: biomarker)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Refresh Button
                    Button(action: refreshData) {
                        HStack {
                            Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                                .font(.title3)
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
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
                    .disabled(isRefreshing)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if biomarkers.isEmpty {
                biomarkers = createBiomarkers(for: userProfile)
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let biomarker = selectedBiomarker {
                BiomarkerDetailView(biomarker: biomarker, userProfile: userProfile)
            }
        }
        .sheet(isPresented: $showingSleepDetail) {
            NavigationStack {
                SleepView()
            }
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }
    
    func refreshData() {
        isRefreshing = true
        
        withAnimation(.linear(duration: 1.0)) {
            // Simulate data refresh with slight variations
            biomarkers = biomarkers.map { biomarker in
                let variation = Double.random(in: -0.1...0.1)
                let newValue = biomarker.value * (1 + variation)
                var updatedBiomarker = Biomarker(
                    name: biomarker.name,
                    value: newValue,
                    unit: biomarker.unit,
                    normalRange: biomarker.normalRange,
                    icon: biomarker.icon,
                    color: biomarker.color,
                    description: biomarker.description,
                    function: biomarker.function,
                    highRisk: biomarker.highRisk,
                    lowRisk: biomarker.lowRisk
                )
                updatedBiomarker.normalRange = biomarker.normalRange
                return updatedBiomarker
            }
            lastUpdated = Date()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
        }
    }
    
    func createBiomarkers(for profile: UserProfile) -> [Biomarker] {
        var biomarkers: [Biomarker] = []
        
        // Ketones - blood ketone bodies
        let ketonesRange: ClosedRange<Double> = 0.0...0.6
        biomarkers.append(Biomarker(
            name: "Ketones",
            value: Double.random(in: 0.0...1.2),
            unit: "mmol/L",
            normalRange: ketonesRange,
            icon: "bolt.fill",
            color: .yellow,
            description: "Molecules produced when the body burns fat for energy instead of glucose.",
            function: "Indicates fat metabolism and ketogenic state.",
            highRisk: "May indicate diabetic ketoacidosis, prolonged fasting, or very low carb intake.",
            lowRisk: "Normal for glucose-based metabolism. Not concerning."
        ))
        
        // Cortisol - varies by gender
        let cortisolRange: ClosedRange<Double> = profile.gender == .female ? 5...25 : 6...23
        biomarkers.append(Biomarker(
            name: "Cortisol",
            value: Double.random(in: 4...26),
            unit: "µg/dL",
            normalRange: cortisolRange,
            icon: "brain.head.profile",
            color: .purple,
            description: "A hormone released in response to stress and low blood sugar.",
            function: "Regulates metabolism, immune response, and stress levels.",
            highRisk: "May indicate Cushing's syndrome, chronic stress, or adrenal tumors.",
            lowRisk: "May indicate Addison's disease or adrenal insufficiency."
        ))
        
        // Glucose - fasting blood sugar
        let glucoseRange: ClosedRange<Double> = 70...100
        biomarkers.append(Biomarker(
            name: "Glucose",
            value: Double.random(in: 65...110),
            unit: "mg/dL",
            normalRange: glucoseRange,
            icon: "drop.fill",
            color: .blue,
            description: "Blood sugar level, the primary energy source for your body's cells.",
            function: "Indicates blood sugar control and risk for diabetes.",
            highRisk: "May indicate prediabetes, diabetes, or insulin resistance.",
            lowRisk: "May indicate hypoglycemia, overmedication, or insufficient food intake."
        ))
        
        return biomarkers
    }
}

// MARK: - Biomarker Trend Chart
struct BiomarkerTrendChart: View {
    let biomarker: Biomarker
    let readings: [BiomarkerReading]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(biomarker.color)
                Text("30-Day Trend")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Chart {
                // Normal range background
                RectangleMark(
                    xStart: .value("Start", readings.first?.date ?? Date()),
                    xEnd: .value("End", readings.last?.date ?? Date()),
                    yStart: .value("Lower", biomarker.normalRange.lowerBound),
                    yEnd: .value("Upper", biomarker.normalRange.upperBound)
                )
                .foregroundStyle(.green.opacity(0.1))
                .annotation(position: .top, alignment: .leading) {
                    Text("Normal Range")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(4)
                        .background(.green.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Line chart
                ForEach(readings) { reading in
                    LineMark(
                        x: .value("Date", reading.date),
                        y: .value("Value", reading.value)
                    )
                    .foregroundStyle(biomarker.color.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", reading.date),
                        y: .value("Value", reading.value)
                    )
                    .foregroundStyle(biomarker.color.opacity(0.1).gradient)
                }
                
                // Current value point
                if let lastReading = readings.last {
                    PointMark(
                        x: .value("Date", lastReading.date),
                        y: .value("Value", biomarker.value)
                    )
                    .foregroundStyle(biomarker.color)
                    .symbolSize(100)
                }
            }
            .frame(height: 200)
            //.padding(.bottom, 30) // extra space for X-axis labels
            .chartYAxis {
                AxisMarks(position: .leading)
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
                    Circle()
                        .fill(biomarker.color)
                        .frame(width: 10, height: 10)
                    Text("Current: \(String(format: "%.2f", biomarker.value)) \(biomarker.unit)")
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.green.opacity(0.3))
                        .frame(width: 10, height: 10)
                    Text("Normal Range")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// MARK: - Biomarker Comparison Chart
struct BiomarkerComparisonChart: View {
    let biomarkers: [Biomarker]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Current Levels Overview")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Chart(biomarkers) { biomarker in
    BarMark(
        x: .value("Biomarker", biomarker.name),
        y: .value("Percentage", percentageOfRange(biomarker))
    )
    .foregroundStyle(biomarker.statusColor.gradient)
    .cornerRadius(4)
    //.annotation(position: .overlay)
}
.frame(height: 200)
//.padding(.bottom, 5) // extra space for X-axis labels
.chartYAxis {
    AxisMarks(position: .leading) { value in
        AxisGridLine()
        AxisValueLabel {
            if let intValue = value.as(Int.self) {
                Text("\(intValue)%")
                    .font(.caption)
            }
        }
    }
}
.chartXAxis {
    AxisMarks { value in
        AxisValueLabel(anchor: .top, collisionResolution: .disabled) {
            if let name = value.as(String.self) {
                Text(name)
                    .font(.caption)
                    .fixedSize()
                    .padding(.top, 8)
            }
        }
    }
}
.chartYScale(domain: 0...100)
            
            // Legend
            HStack(spacing: 15) {
                LegendItem(color: .green, label: "Optimal")
                LegendItem(color: .orange, label: "Out of Range")
                LegendItem(color: .red, label: "Critical")
            }
            .font(.caption)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private func percentageOfRange(_ biomarker: Biomarker) -> Double {
        // Calculate percentage based on the biomarker's position within an extended range
        // This ensures values outside normal range are still visible but capped at 100%
        let rangeSpan = biomarker.normalRange.upperBound - biomarker.normalRange.lowerBound
        let extendedMax = biomarker.normalRange.upperBound + (rangeSpan * 0.5) // Add 50% above normal
        let extendedMin = biomarker.normalRange.lowerBound - (rangeSpan * 0.5) // Add 50% below normal
        let extendedRange = extendedMax - extendedMin
        
        // Calculate where the value falls in this extended range
        let normalizedValue = (biomarker.value - extendedMin) / extendedRange
        let percentage = normalizedValue * 100
        
        // Cap between 0 and 100 to prevent overflow
        return max(0, min(percentage, 100))
    }
}

// MARK: - Mini Trend Chart (for cards)
struct MiniTrendChart: View {
    let biomarker: Biomarker
    let readings: [BiomarkerReading]
    
    var body: some View {
        Chart {
            ForEach(readings.suffix(7)) { reading in
                LineMark(
                    x: .value("Date", reading.date),
                    y: .value("Value", reading.value)
                )
                .foregroundStyle(biomarker.color.gradient)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: biomarker.normalRange.lowerBound * 0.8...biomarker.normalRange.upperBound * 1.2)
        .frame(width: 60, height: 30)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Biomarker Detail View
struct BiomarkerDetailView: View {
    let biomarker: Biomarker
    let userProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(biomarker.color.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: biomarker.icon)
                                    .font(.system(size: 60))
                                    .foregroundColor(biomarker.color)
                            }
                            
                            Text(biomarker.name)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Current Value
                            HStack(spacing: 8) {
                                Text(String(format: "%.2f", biomarker.value))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(biomarker.unit)
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Status Badge
                            HStack {
                                Image(systemName: statusIcon)
                                    .font(.title3)
                                Text(biomarker.status.description)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(biomarker.statusColor)
                            .cornerRadius(20)
                        }
                        .padding(.top, 20)
                        
                        // Trend Chart
                        BiomarkerTrendChart(
                            biomarker: biomarker,
                            readings: biomarker.generateHistoricalData()
                        )
                        
                        // Normal Range for User
                        InfoCard(
                            title: "Your Normal Range",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        ) {
                            VStack(spacing: 8) {
                                Text("\(String(format: "%.1f", biomarker.normalRange.lowerBound)) - \(String(format: "%.1f", biomarker.normalRange.upperBound)) \(biomarker.unit)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Based on \(userProfile.gender.rawValue), age \(userProfile.age)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Description
                        InfoCard(
                            title: "What is \(biomarker.name)?",
                            icon: "info.circle.fill",
                            color: .blue
                        ) {
                            Text(biomarker.description)
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        
                        // Function
                        InfoCard(
                            title: "Function",
                            icon: "gear.circle.fill",
                            color: .orange
                        ) {
                            Text(biomarker.function)
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        
                        // High Risk
                        InfoCard(
                            title: "If High",
                            icon: "arrow.up.circle.fill",
                            color: .red
                        ) {
                            Text(biomarker.highRisk)
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        
                        // Low Risk
                        InfoCard(
                            title: "If Low",
                            icon: "arrow.down.circle.fill",
                            color: .blue
                        ) {
                            Text(biomarker.lowRisk)
                                .font(.body)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    var statusIcon: String {
        switch biomarker.status {
        case .optimal: return "checkmark.circle.fill"
        case .outOfRange: return "exclamationmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// MARK: - Overall Status Card
struct OverallStatusCard: View {
    let biomarkers: [Biomarker]
    
    var optimalCount: Int {
        biomarkers.filter { $0.status == .optimal }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: optimalCount == biomarkers.count ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(optimalCount == biomarkers.count ? .green : .orange)
                
                Text(optimalCount == biomarkers.count ? "All Systems Optimal" : "Attention Needed")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 20) {
                StatusBadge(count: optimalCount, total: biomarkers.count, label: "Optimal", color: .green)
                StatusBadge(count: biomarkers.count - optimalCount, total: biomarkers.count, label: "Flagged", color: .orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

struct StatusBadge: View {
    let count: Int
    let total: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)/\(total)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Biomarker Card
struct BiomarkerCard: View {
    let biomarker: Biomarker
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Icon
                ZStack {
                    Circle()
                        .fill(biomarker.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: biomarker.icon)
                        .font(.title2)
                        .foregroundColor(biomarker.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(biomarker.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.2f", biomarker.value))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(biomarker.unit)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text("Normal: \(String(format: "%.1f", biomarker.normalRange.lowerBound))-\(String(format: "%.1f", biomarker.normalRange.upperBound)) \(biomarker.unit)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Mini trend and status
                VStack(spacing: 8) {
                    MiniTrendChart(biomarker: biomarker, readings: biomarker.generateHistoricalData(days: 7))
                    
                    VStack(spacing: 2) {
                        Image(systemName: statusIcon(for: biomarker.status))
                            .font(.title3)
                            .foregroundColor(biomarker.statusColor)
                        
                        Text(biomarker.status.description)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(biomarker.statusColor)
                    }
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    func statusIcon(for status: BiomarkerStatus) -> String {
        switch status {
        case .optimal: return "checkmark.circle.fill"
        case .outOfRange: return "exclamationmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Sleep Data Card
struct SleepDataCard: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @Binding var sleepAuthRequested: Bool
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.blue)
                Text("Sleep Analysis")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if healthKitManager.isAuthorized && !healthKitManager.sleepData.isEmpty {
                    HStack(spacing: 4) {
                        Text("Last 7 days")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            if !healthKitManager.isAuthorized {
                // Authorization prompt
                VStack(spacing: 12) {
                    Text("Connect to Health app to track your sleep")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        Task {
                            do {
                                try await healthKitManager.requestAuthorization()
                                try await healthKitManager.fetchSleepData()
                                sleepAuthRequested = true
                            } catch {
                                print("Error: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                            Text("Connect")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.blue.gradient)
                        .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            } else if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding()
            } else if healthKitManager.sleepData.isEmpty {
                Text("No sleep data available. Start tracking in the Health app.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            } else {
                // Sleep data summary
                let recentSleep = Array(healthKitManager.sleepData.prefix(7))
                let avgHours = recentSleep.reduce(0.0) { $0 + $1.totalHours } / Double(recentSleep.count)
                
                HStack(spacing: 20) {
                    // Average hours
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", avgHours))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("hrs")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Text("Average")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Divider()
                        .background(.white.opacity(0.3))
                        .frame(height: 40)
                    
                    // Recent nights
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(recentSleep.prefix(3)) { sleep in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(sleepQualityColor(sleep.quality))
                                    .frame(width: 8, height: 8)
                                Text(sleep.date.formatted(.dateTime.month().day()))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                Text(String(format: "%.1fh", sleep.totalHours))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .onAppear {
            if healthKitManager.isAuthorized && healthKitManager.sleepData.isEmpty {
                isLoading = true
                Task {
                    do {
                        try await healthKitManager.fetchSleepData()
                        isLoading = false
                    } catch {
                        isLoading = false
                    }
                }
            }
        }
    }
    
    func sleepQualityColor(_ quality: SleepQuality) -> Color {
        switch quality {
        case .good: return .green
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

#Preview {
    ContentView()
}
