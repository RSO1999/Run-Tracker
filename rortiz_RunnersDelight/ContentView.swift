
// filename: ContentView.swift
// 
import SwiftUI
import SwiftData
import CoreLocation
import Charts

struct ContentView: View {
    @StateObject private var manager = LocationDataManager()
    
    @State private var selection: Int = 0  
    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "figure.run")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        .environmentObject(manager)
    }
}



struct HistoryView: View {
    @Query(sort: \RunLog.startDate, order: .reverse) private var runs: [RunLog]

    var body: some View {
        NavigationStack {
            List {
                ForEach(runs) { run in
                    NavigationLink {
                        RunDetailView(run: run)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(run.totalDistanceMiles, specifier: "%.2f") miles")
                                .font(.headline)

                            let duration = Duration.seconds(run.totalDurationSeconds)
                            Text("Time: \(duration.formatted(.time(pattern: .hourMinuteSecond)))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(run.startDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct RunDetailView: View {
    @Bindable var run: RunLog

    // ✅ NEW: cached chart data (primitive-only, downsampled)
    @State private var pacePoints: [PacePoint] = []
    @State private var isBuildingChart = false

    // ✅ NEW: build once, not in body recomputes
    @MainActor
    private func buildChartPoints(from samples: [RunSample]) -> [PacePoint] {
        // Filter out “junk” points (e.g., pace 0 when speed is ~0)
        let filtered = samples.filter { $0.distanceMiles >= 0 && $0.paceMinPerMile > 0.1 }

        // Sort once
        let sorted = filtered.sorted { $0.sampleIndex < $1.sampleIndex }

        // Map to primitives
        let points = sorted.map {
            PacePoint(distanceMiles: $0.distanceMiles, paceMinPerMile: $0.paceMinPerMile)
        }

        // Downsample to cap chart cost
        return downsample(points, maxPoints: 600)
    }

    // ✅ UPDATED: use cached points instead of run.samples work inside body
    private var maxMiles: Double {
        max(run.totalDistanceMiles, pacePoints.last?.distanceMiles ?? 0, 0.1)
    }

    // Clean tick spacing on X axis
    private var xStepMiles: Double {
        switch maxMiles {
        case ..<1.0:  return 0.25
        case ..<3.0:  return 0.5
        case ..<6.0:  return 1.0
        case ..<12.0: return 2.0
        default:      return 5.0
        }
    }

    private var xMaxRounded: Double {
        ceil(maxMiles / xStepMiles) * xStepMiles
    }

    private var paceRange: (min: Double, max: Double) {
        let paces = pacePoints.map(\.paceMinPerMile)
        guard let minP = paces.min(), let maxP = paces.max() else {
            return (6, 14)
        }

        // Add some padding so the line isn’t glued to edges
        let pad = max(0.5, (maxP - minP) * 0.15)
        return (max(0, minP - pad), maxP + pad)
    }

    // Clean tick spacing on Y axis (minutes)
    private var yStepMinutes: Double {
        let range = paceRange.max - paceRange.min
        switch range {
        case ..<4:  return 0.5   // 30s
        case ..<8:  return 1.0
        case ..<16: return 2.0
        default:    return 5.0
        }
    }

    private func paceLabel(_ minutes: Double) -> String {
        let totalSeconds = Int((minutes * 60.0).rounded())
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func milesLabel(_ miles: Double) -> String {
        if miles.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", miles)
        } else {
            return String(format: "%.2f", miles)
        }
    }

    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Distance")
                    Spacer()
                    Text("\(run.totalDistanceMiles, specifier: "%.2f") mi")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Duration")
                    Spacer()
                    let duration = Duration.seconds(run.totalDurationSeconds)
                    Text(duration.formatted(.time(pattern: .hourMinuteSecond)))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Avg pace")
                    Spacer()
                    Text("\(run.averagePaceMinPerMile, specifier: "%.2f") min/mi")
                        .foregroundStyle(.secondary)
                }

            
            }

            Section("Pace vs Distance") {
                if isBuildingChart {
                    ProgressView("Building chart…")
                } else if pacePoints.count >= 2 {
                    Chart {
                        // Area fill underneath
                        ForEach(pacePoints) { p in
                            AreaMark(
                                x: .value("Distance (mi)", p.distanceMiles),
                                yStart: .value("Baseline", paceRange.max),
                                yEnd: .value("Pace (min/mi)", p.paceMinPerMile)
                            )
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.35),
                                    Color.brandPrimary.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line on top
                        ForEach(pacePoints) { p in
                            LineMark(
                                x: .value("Distance (mi)", p.distanceMiles),
                                y: .value("Pace (min/mi)", p.paceMinPerMile)
                            )
                        }
                        .foregroundStyle(Color.brandPrimary)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    .chartXScale(domain: 0...xMaxRounded)
                    .chartYScale(domain: paceRange.min...paceRange.max)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: xStepMiles)) { value in
                            AxisGridLine().foregroundStyle(.gray.opacity(0.25))
                            AxisTick()
                            AxisValueLabel {
                                if let miles = value.as(Double.self) {
                                    Text(milesLabel(miles))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .stride(by: yStepMinutes)) { value in
                            AxisGridLine().foregroundStyle(.gray.opacity(0.25))
                            AxisTick()
                            AxisValueLabel {
                                if let paceMin = value.as(Double.self) {
                                    Text(paceLabel(paceMin))
                                }
                            }
                        }
                    }
                    .frame(height: 220)
                } else {
                    Text("Not enough samples to chart yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Run Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard pacePoints.isEmpty else { return }
            isBuildingChart = true
            pacePoints = buildChartPoints(from: run.samples)
            isBuildingChart = false
        }
    }
}

func downsample<T>(_ items: [T], maxPoints: Int) -> [T] {
    guard maxPoints > 0, items.count > maxPoints else { return items }
    let stride = max(1, items.count / maxPoints)
    return items.enumerated().compactMap { (i, item) in
        (i % stride == 0) ? item : nil
    }
}

struct PacePoint: Identifiable {
    let id = UUID()
    let distanceMiles: Double
    let paceMinPerMile: Double
}



struct ProfileView: View {
    var body: some View {
        Text("PROFILE")
    }
}
