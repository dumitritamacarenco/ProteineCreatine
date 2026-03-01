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
                                Text("View Biomarkers")
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
        if value < normalRange.lowerBound {
            return .low
        } else if value > normalRange.upperBound {
            return .high
        } else {
            return .normal
        }
    }
    
    var statusColor: Color {
        switch status {
        case .low: return .blue
        case .normal: return .green
        case .high: return .orange
        }
    }
}

enum BiomarkerStatus {
    case low, normal, high
    
    var description: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
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
        
        // Creatinine - varies by gender
        let creatinineRange: ClosedRange<Double> = profile.gender == .male ? 0.7...1.3 : 0.6...1.1
        biomarkers.append(Biomarker(
            name: "Creatinine",
            value: Double.random(in: 0.5...1.4),
            unit: "mg/dL",
            normalRange: creatinineRange,
            icon: "drop.fill",
            color: .blue,
            description: "A waste product from muscle metabolism filtered by the kidneys.",
            function: "Indicates kidney function and muscle mass.",
            highRisk: "May indicate kidney disease, dehydration, or excessive muscle breakdown.",
            lowRisk: "May indicate low muscle mass or liver disease."
        ))
        
        // Creatine
        let creatineRange: ClosedRange<Double> = 30...50
        biomarkers.append(Biomarker(
            name: "Creatine",
            value: Double.random(in: 25...55),
            unit: "µmol/L",
            normalRange: creatineRange,
            icon: "bolt.fill",
            color: .yellow,
            description: "An organic compound that helps supply energy to muscles.",
            function: "Supports muscle energy production and athletic performance.",
            highRisk: "Generally not harmful; often elevated in athletes.",
            lowRisk: "May indicate inadequate dietary intake or muscle disorders."
        ))
        
        // Urea - slightly varies by age and gender
        let ureaRange: ClosedRange<Double> = profile.age > 60 ? 8...23 : 7...20
        biomarkers.append(Biomarker(
            name: "Urea",
            value: Double.random(in: 6...24),
            unit: "mg/dL",
            normalRange: ureaRange,
            icon: "drop.triangle.fill",
            color: .cyan,
            description: "A waste product formed from protein breakdown in the liver.",
            function: "Indicates kidney function and protein metabolism.",
            highRisk: "May indicate kidney dysfunction, dehydration, or high protein intake.",
            lowRisk: "May indicate liver disease or low protein intake."
        ))
        
        // Cortisol - varies by age and gender
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
        
        // Uric Acid - significantly varies by gender
        let uricAcidRange: ClosedRange<Double> = profile.gender == .male ? 3.7...7.0 : 2.5...6.0
        biomarkers.append(Biomarker(
            name: "Uric Acid",
            value: Double.random(in: 2.0...7.5),
            unit: "mg/dL",
            normalRange: uricAcidRange,
            icon: "staroflife.fill",
            color: .pink,
            description: "A waste product from the breakdown of purines found in many foods.",
            function: "Acts as an antioxidant but excess can cause health issues.",
            highRisk: "May indicate gout, kidney stones, or metabolic syndrome.",
            lowRisk: "Generally not concerning; may indicate low purine diet."
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
}
.frame(height: 200)
.padding(.bottom, 30) // extra space for X-axis labels
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
        AxisValueLabel {
            if let name = value.as(String.self) {
                Text(name)
                    .font(.caption2)
                    .rotationEffect(.degrees(-30)) // less aggressive rotation
                    .fixedSize() // prevent clipping
                    .frame(maxWidth: 60, alignment: .trailing)
            }
        }
    }
}
.chartYScale(domain: 0...(biomarkers.map { percentageOfRange($0) }.max() ?? 150 * 1.2))
            
            // Legend
            HStack(spacing: 15) {
                LegendItem(color: .green, label: "Normal")
                LegendItem(color: .blue, label: "Low")
                LegendItem(color: .orange, label: "High")
            }
            .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private func percentageOfRange(_ biomarker: Biomarker) -> Double {
        let midPoint = (biomarker.normalRange.lowerBound + biomarker.normalRange.upperBound) / 2
        return (biomarker.value / midPoint) * 100
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
        case .low: return "arrow.down.circle.fill"
        case .normal: return "checkmark.circle.fill"
        case .high: return "arrow.up.circle.fill"
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
    
    var normalCount: Int {
        biomarkers.filter { $0.status == .normal }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: normalCount == biomarkers.count ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(normalCount == biomarkers.count ? .green : .orange)
                
                Text(normalCount == biomarkers.count ? "All Systems Normal" : "Attention Needed")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 20) {
                StatusBadge(count: normalCount, total: biomarkers.count, label: "Normal", color: .green)
                StatusBadge(count: biomarkers.count - normalCount, total: biomarkers.count, label: "Flagged", color: .orange)
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
        case .low: return "arrow.down.circle.fill"
        case .normal: return "checkmark.circle.fill"
        case .high: return "arrow.up.circle.fill"
        }
    }
}

#Preview {
    ContentView()
}
