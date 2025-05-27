////
////  ProductivityStatsViewModel.swift
////  shikaku
////
////  ViewModel for productivity-focused statistics and practice mode
////
//
//import SwiftUI
//import SwiftData
//import Foundation
//
//@Observable
//class ProductivityStatsViewModel {
//    // Practice session tracking
//    var dailyPracticeTime: TimeInterval = 0
//    var totalPracticeTime: TimeInterval = 0
//    var practiceStreak: Int = 0
//    var practiceSessionsToday: Int = 0
//    var averageSolveTime: TimeInterval = 0
//    var lastPracticeDate: Date?
//
//    // Mental fitness metrics
//    var focusScore: Double = 0.0 // 0-100 based on solve times and accuracy
//    var problemsSolvedToday: Int = 0
//    var weeklyGoal: Int = 7 // Problems per week
//    var mentalStamina: Double = 100.0 // Decreases with fatigue, resets daily
//
//    // Practice mode data
//    var availablePracticeLevels: [PracticeLevel] = []
//    var isGeneratingLevel = false
//    var currentPracticeLevel: PracticeLevel?
//
//    private let calendar = Calendar.current
//    private let levelBuilder = LevelBuilderManager()
//
//    init() {
//        loadStats()
//        generatePracticeLevels()
//    }
//
//    // MARK: - Statistics Calculation
//
//    func loadStats() {
//        // Load from UserDefaults or calculate from SwiftData
//        dailyPracticeTime = UserDefaults.standard.double(forKey: "daily_practice_time")
//        totalPracticeTime = UserDefaults.standard.double(forKey: "total_practice_time")
//        practiceStreak = UserDefaults.standard.integer(forKey: "practice_streak")
//        practiceSessionsToday = UserDefaults.standard.integer(forKey: "practice_sessions_today")
//        averageSolveTime = UserDefaults.standard.double(forKey: "average_solve_time")
//        focusScore = UserDefaults.standard.double(forKey: "focus_score")
//        problemsSolvedToday = UserDefaults.standard.integer(forKey: "problems_solved_today")
//        mentalStamina = UserDefaults.standard.double(forKey: "mental_stamina")
//
//        if let lastPracticeData = UserDefaults.standard.object(forKey: "last_practice_date") as? Data,
//           let date = try? JSONDecoder().decode(Date.self, from: lastPracticeData) {
//            lastPracticeDate = date
//        }
//
//        // Reset daily stats if new day
//        resetDailyStatsIfNeeded()
//    }
//
//    func saveStats() {
//        UserDefaults.standard.set(dailyPracticeTime, forKey: "daily_practice_time")
//        UserDefaults.standard.set(totalPracticeTime, forKey: "total_practice_time")
//        UserDefaults.standard.set(practiceStreak, forKey: "practice_streak")
//        UserDefaults.standard.set(practiceSessionsToday, forKey: "practice_sessions_today")
//        UserDefaults.standard.set(averageSolveTime, forKey: "average_solve_time")
//        UserDefaults.standard.set(focusScore, forKey: "focus_score")
//        UserDefaults.standard.set(problemsSolvedToday, forKey: "problems_solved_today")
//        UserDefaults.standard.set(mentalStamina, forKey: "mental_stamina")
//
//        if let encoded = try? JSONEncoder().encode(Date()) {
//            UserDefaults.standard.set(encoded, forKey: "last_practice_date")
//        }
//    }
//
//    private func resetDailyStatsIfNeeded() {
//        let today = Date()
//
//        if let lastDate = lastPracticeDate,
//           !calendar.isDate(lastDate, inSameDayAs: today) {
//            // New day - reset daily stats
//            dailyPracticeTime = 0
//            practiceSessionsToday = 0
//            problemsSolvedToday = 0
//            mentalStamina = 100.0
//
//            // Check if streak should continue
//            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
//               !calendar.isDate(lastDate, inSameDayAs: yesterday) {
//                practiceStreak = 0 // Streak broken
//            }
//        }
//    }
//
//    // MARK: - Productivity Metrics
//
//    var weeklyProgress: Double {
//        guard weeklyGoal > 0 else { return 0 }
//        return min(1.0, Double(problemsSolvedToday) / Double(weeklyGoal))
//    }
//
//    var productivityLevel: ProductivityLevel {
//        switch focusScore {
//        case 80...100: return .peak
//        case 60..<80: return .high
//        case 40..<60: return .moderate
//        case 20..<40: return .low
//        default: return .warming
//        }
//    }
//
//    var dailyMentalFitnessGoal: Double {
//        return 30.0 * 60.0 // 30 minutes in seconds
//    }
//
//    var dailyGoalProgress: Double {
//        guard dailyMentalFitnessGoal > 0 else { return 0 }
//        return min(1.0, dailyPracticeTime / dailyMentalFitnessGoal)
//    }
//
//    // MARK: - Practice Level Generation
//
//    func generatePracticeLevels() {
//        isGeneratingLevel = true
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            // Generate 200 levels with progressive difficulty
//            let generatedLevels = self.levelBuilder.generateSampleLevels(count: 200)
//
//            // Convert to practice levels with additional metadata
//            let practiceLevels = generatedLevels.enumerated().map { index, level in
//                PracticeLevel(
//                    id: UUID(),
//                    levelNumber: index + 1,
//                    exportableLevel: level,
//                    estimatedSolveTime: self.estimateSolveTime(for: level),
//                    category: self.determineCategory(for: level, index: index),
//                    tags: ["some tags"],
//                    isUnlocked: false
//                )
//            }
//
//            DispatchQueue.main.async {
//                self.availablePracticeLevels = practiceLevels
//                self.isGeneratingLevel = false
//            }
//        }
//    }
//
//    func getRandomPracticeLevel() -> PracticeLevel? {
//        // Weight selection based on current focus score and mental stamina
//        let appropriateLevels = availablePracticeLevels.filter { level in
//            switch productivityLevel {
//            case .warming, .low:
//                return level.exportableLevel.difficulty <= 2
//            case .moderate:
//                return level.exportableLevel.difficulty <= 3
//            case .high:
//                return level.exportableLevel.difficulty <= 4
//            case .peak:
//                return true // All levels available
//            }
//        }
//
//        return appropriateLevels.randomElement()
//    }
//
//    func getQuickPracticeLevel() -> PracticeLevel? {
//        // Get a level that can be solved in under 3 minutes
//        let quickLevels = availablePracticeLevels.filter { level in
//            level.estimatedSolveTime < 180 && level.exportableLevel.difficulty <= 3
//        }
//
//        return quickLevels.randomElement()
//    }
//
//    // MARK: - Session Tracking
//
//    func startPracticeSession(with level: PracticeLevel) {
//        currentPracticeLevel = level
//    }
//
//    func completePracticeSession(solveTime: TimeInterval, wasSuccessful: Bool) {
//        guard let level = currentPracticeLevel else { return }
//
//        // Update practice stats
//        practiceSessionsToday += 1
//        dailyPracticeTime += solveTime
//        totalPracticeTime += solveTime
//
//        if wasSuccessful {
//            problemsSolvedToday += 1
//
//            // Update focus score based on performance
//            let timeEfficiency = level.estimatedSolveTime / max(solveTime, 1)
//            let scoreBoost = min(5.0, timeEfficiency * 2.0)
//            focusScore = min(100.0, focusScore + scoreBoost)
//
//            // Update average solve time
//            let totalSessions = Double(practiceSessionsToday)
//            averageSolveTime = ((averageSolveTime * (totalSessions - 1)) + solveTime) / totalSessions
//        } else {
//            // Reduce focus score slightly for incomplete puzzles
//            focusScore = max(0.0, focusScore - 1.0)
//        }
//
//        // Reduce mental stamina
//        let staminaCost = min(10.0, Double(level.exportableLevel.difficulty) * 2.0)
//        mentalStamina = max(0.0, mentalStamina - staminaCost)
//
//        // Update streak
//        lastPracticeDate = Date()
//        if wasSuccessful {
//            practiceStreak += 1
//        }
//
//        currentPracticeLevel = nil
//        saveStats()
//    }
//
//    // MARK: - Helper Methods
//
//    private func estimateSolveTime(for level: ExportableLevel) -> TimeInterval {
//        // Base time estimation based on grid size and difficulty
//        let cellCount = level.gridRows * level.gridCols
//        let baseTime = Double(cellCount) * 3.0 // 3 seconds per cell base
//        let difficultyMultiplier = 1.0 + (Double(level.difficulty - 1) * 0.5)
//
//        return baseTime * difficultyMultiplier
//    }
//
//    private func determineCategory(for level: ExportableLevel, index: Int) -> PracticeCategory {
//        // Categorize levels for better organization
//        switch level.difficulty {
//        case 1: return .warmUp
//        case 2: return .focus
//        case 3: return .challenge
//        case 4: return .intense
//        case 5: return .mastery
//        default: return .focus
//        }
//    }
//}
//
//// MARK: - Supporting Types
//
//enum ProductivityLevel: String, CaseIterable {
//    case warming = "Warming Up"
//    case low = "Building Focus"
//    case moderate = "In The Zone"
//    case high = "Peak Performance"
//    case peak = "Mental Athlete"
//
//    var color: Color {
//        switch self {
//        case .warming: return .orange
//        case .low: return .yellow
//        case .moderate: return .green
//        case .high: return .blue
//        case .peak: return .purple
//        }
//    }
//
//    var icon: String {
//        switch self {
//        case .warming: return "flame"
//        case .low: return "eye"
//        case .moderate: return "target"
//        case .high: return "bolt.fill"
//        case .peak: return "crown.fill"
//        }
//    }
//}
//
//enum PracticeCategory: String, CaseIterable {
//    case warmUp = "Warm Up"
//    case focus = "Focus Builder"
//    case challenge = "Challenge"
//    case intense = "Intense"
//    case mastery = "Mastery"
//
//    var color: Color {
//        switch self {
//        case .warmUp: return .green
//        case .focus: return .blue
//        case .challenge: return .orange
//        case .intense: return .red
//        case .mastery: return .purple
//        }
//    }
//}
//
//struct PracticeLevel: Identifiable {
//    let id: UUID
//    let levelNumber: Int
//    let exportableLevel: ExportableLevel
//    let estimatedSolveTime: TimeInterval
//    let category: PracticeCategory
//    var tags: [String]
//    var isUnlocked: Bool
//
//    var formattedSolveTime: String {
//        let minutes = Int(estimatedSolveTime) / 60
//        let seconds = Int(estimatedSolveTime) % 60
//        return String(format: "%d:%02d", minutes, seconds)
//    }
//}
