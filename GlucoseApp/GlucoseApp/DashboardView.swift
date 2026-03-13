//
//  DashboardView.swift
//  GlucoseApp
//
//  Created by Joy Li on 10/30/25.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var activityVM: ActivityViewModel
    @EnvironmentObject var foodVM: FoodViewModel
    @EnvironmentObject var sleepVM: SleepViewModel
    
    // Selected date for the dashboard (defaults to today)
    @State private var selectedDate: Date = Date()
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Computed Stats (for selectedDate)
    
    private var todayActivityDuration: Int {
        activityVM.entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .reduce(0) { $0 + $1.duration }
    }
    
    private var todayCalories: Int {
        foodVM.entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .reduce(0) { $0 + $1.carbs * 4 + $1.protein * 4 + $1.fat * 9 } // simple macro calories
    }
    
    private var todaySleepHours: Double {
        sleepVM.entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .reduce(0) { $0 + $1.duration / 3600 } // in hours
    }
    
    private var todayBloodGlucose: String {
        let activityBG = activityVM.entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .compactMap { $0.bloodGlucoseAfter }
        
        let foodBG = foodVM.entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .compactMap { $0.bloodGlucoseAfter }
        
        let sleepBG = sleepVM.entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .compactMap { $0.bloodGlucoseWaking }
        
        let allBGs = activityBG + foodBG + sleepBG
        
        guard !allBGs.isEmpty else { return "--" }
        let avg = allBGs.reduce(0, +) / allBGs.count
        return "\(avg) mg/dL"
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Date Picker (simple calendar at top)
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding(.top)
                    
                    // Header
                    Text("📊 Overview for \(formattedDate(selectedDate))")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Stat Cards
                    HStack(spacing: 16) {
                        StatBadge(
                            icon: "drop.fill",
                            value: todayBloodGlucose,
                            label: "Glucose",
                            color: .red
                        )
                        StatBadge(
                            icon: "moon.fill",
                            value: String(format: "%.1f", todaySleepHours),
                            label: "hrs sleep",
                            color: .purple
                        )
                    }
                    
                    HStack(spacing: 16) {
                        StatBadge(
                            icon: "flame.fill",
                            value: "\(todayCalories)",
                            label: "calories",
                            color: .orange
                        )
                        StatBadge(
                            icon: "figure.run",
                            value: "\(todayActivityDuration)",
                            label: "min activity",
                            color: .green
                        )
                    }
                    
                    // Charts (still show recent entries, independent of selected date)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activity Duration (min)")
                            .font(.headline)
                        Chart {
                            ForEach(activityVM.entries.prefix(7), id: \.id) { entry in
                                BarMark(
                                    x: .value("Date", entry.date, unit: .day),
                                    y: .value("Duration", entry.duration)
                                )
                                .foregroundStyle(.green.gradient)
                            }
                        }
                        .frame(height: 150)
                        
                        Text("Calories Intake")
                            .font(.headline)
                        Chart {
                            ForEach(foodVM.entries.prefix(7), id: \.id) { entry in
                                BarMark(
                                    x: .value("Date", entry.date, unit: .day),
                                    y: .value("Calories", entry.carbs * 4 + entry.protein * 4 + entry.fat * 9)
                                )
                                .foregroundStyle(.orange.gradient)
                            }
                        }
                        .frame(height: 150)
                        
                        Text("Sleep Hours")
                            .font(.headline)
                        Chart {
                            ForEach(sleepVM.entries.prefix(7), id: \.id) { entry in
                                BarMark(
                                    x: .value("Date", entry.date, unit: .day),
                                    y: .value("Hours", entry.duration / 3600)
                                )
                                .foregroundStyle(.purple.gradient)
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding(.top)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("🏠 Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                }
            }
        }
    }
}

