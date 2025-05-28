//
//  ShikakuCalendarViewModel.swift
//  shikaku
//
//  ViewModel for calendar with JSON-based levels
//

import SwiftUI
import SwiftData
import Foundation

@Observable
class ShikakuCalendarViewModel {
    var selectedDate = Date()
    var currentMonth = Date()
    var showingLevelEditor = false
    var showingDayLabel = false
    var showLevelBuilder = false
    var showingGameView = false
    var selectedLevel: ShikakuLevel?
    var game = ShikakuGame()

    // Level manager for JSON-based levels
    private let levelManager = LevelManager.shared
    private let calendar = Calendar.current

    // MARK: - Level Access (FIXED)

    func getLevelForDate(_ date: Date) -> ShikakuLevel? {
        return levelManager.getLevelForDate(date)
    }

    // FIXED: Updated to use SwiftData levels instead of LevelCompletion
    func getLevelForDate(_ date: Date, completedLevels: [ShikakuLevel]) -> ShikakuLevel? {
        let level = levelManager.getLevelForDate(date)

        // Check if this level pattern has been completed in SwiftData
        if let level = level {
            let isCompleted = completedLevels.contains { completedLevel in
                completedLevel.levelDataId == level.levelDataId &&
                Calendar.current.isDate(completedLevel.date, inSameDayAs: date)
            }
            level.isCompleted = isCompleted

            // Also set completion time if available
            if let completedLevel = completedLevels.first(where: { completedLevel in
                completedLevel.levelDataId == level.levelDataId &&
                Calendar.current.isDate(completedLevel.date, inSameDayAs: date)
            }) {
                level.completionTime = completedLevel.completionTime
            }
        }

        return level
    }

    func getCalendarLevels() -> [ShikakuLevel] {
        return levelManager.getCalendarLevels()
    }

    // FIXED: Updated to use SwiftData levels
    func getCalendarLevels(completedLevels: [ShikakuLevel]) -> [ShikakuLevel] {
        let calendarLevels = levelManager.getCalendarLevels()

        // Mark levels as completed based on SwiftData
        for level in calendarLevels {
            let isCompleted = completedLevels.contains { completedLevel in
                completedLevel.levelDataId == level.levelDataId &&
                Calendar.current.isDate(completedLevel.date, inSameDayAs: level.date)
            }
            level.isCompleted = isCompleted

            // Also set completion time if available
            if let completedLevel = completedLevels.first(where: { completedLevel in
                completedLevel.levelDataId == level.levelDataId &&
                Calendar.current.isDate(completedLevel.date, inSameDayAs: level.date)
            }) {
                level.completionTime = completedLevel.completionTime
            }
        }

        return calendarLevels
    }

    // For backward compatibility with existing view code
    func levelForDate(_ date: Date, levels: [ShikakuLevel]) -> ShikakuLevel? {
        return getLevelForDate(date, completedLevels: levels)
    }

    // MARK: - Streak Strategy Logic (Updated for JSON approach)

    func calculateStrategicDays(levels: [ShikakuLevel]) -> [Date] {
        // Get completion status from SwiftData (what's actually been played)
        let completedDates = levels.filter { $0.isCompleted }.map { $0.date }
        var strategicDates: [Date] = []

        // Group completed days into consecutive segments
        let sortedCompletedDates = completedDates.sorted()
        let segments = findConsecutiveSegments(dates: sortedCompletedDates)

        // Find strategic days that can connect segments
        strategicDates.append(contentsOf: findConnectionDays(segments: segments))

        // Add days that extend the most recent segment
        strategicDates.append(contentsOf: findExtensionDays(segments: segments))

        // Add nearby opportunities (past and today only)
        strategicDates.append(contentsOf: findNearbyOpportunities())

        return Array(Set(strategicDates)) // Remove duplicates
    }

    func findConsecutiveSegments(dates: [Date]) -> [[Date]] {
        guard !dates.isEmpty else { return [] }

        var segments: [[Date]] = []
        var currentSegment: [Date] = [dates[0]]

        for i in 1..<dates.count {
            let daysBetween = calendar.dateComponents([.day], from: dates[i-1], to: dates[i]).day ?? 0
            if daysBetween == 1 {
                currentSegment.append(dates[i])
            } else {
                segments.append(currentSegment)
                currentSegment = [dates[i]]
            }
        }
        segments.append(currentSegment)

        return segments
    }

    func findConnectionDays(segments: [[Date]]) -> [Date] {
        let today = Date()
        var connectionDays: [Date] = []

        for i in 0..<segments.count {
            for j in (i+1)..<segments.count {
                if let end1 = segments[i].last, let start2 = segments[j].first {
                    let daysBetween = calendar.dateComponents([.day], from: end1, to: start2).day ?? 0

                    if daysBetween > 1 && daysBetween <= 8 { // Maximum 7 missing days
                        for dayOffset in 1..<daysBetween {
                            if let strategicDate = calendar.date(byAdding: .day, value: dayOffset, to: end1) {
                                // Only add if it's in the past or today (not future)
                                if calendar.compare(strategicDate, to: today, toGranularity: .day) != .orderedDescending {
                                    connectionDays.append(strategicDate)
                                }
                            }
                        }
                    }
                }
            }
        }

        return connectionDays
    }

    func findExtensionDays(segments: [[Date]]) -> [Date] {
        guard let lastSegment = segments.last, let lastDate = lastSegment.last else { return [] }

        let today = Date()
        var extensionDays: [Date] = []

        // Only add days up to today (not in future)
        var dayOffset = 1
        while dayOffset <= 5 {
            if let nextDate = calendar.date(byAdding: .day, value: dayOffset, to: lastDate) {
                // Stop if we exceed today
                if calendar.compare(nextDate, to: today, toGranularity: .day) == .orderedDescending {
                    break
                }
                extensionDays.append(nextDate)
            }
            dayOffset += 1
        }

        return extensionDays
    }

    func findNearbyOpportunities() -> [Date] {
        let today = Date()
        var nearbyDays: [Date] = []

        // Look for opportunities ONLY in the past and today
        for dayOffset in -30...0 { // 30 days in the past maximum, up to today
            if let candidateDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                // Since every day has a level in our JSON system, add all non-completed days
                nearbyDays.append(candidateDate)
            }
        }

        return nearbyDays
    }

    func calculateMaxPossibleStreak(levels: [ShikakuLevel]) -> Int {
        let completedDates = levels.filter { $0.isCompleted }.map { $0.date }
        let strategicDates = calculateStrategicDays(levels: levels)
        let allPotentialDates = Set(completedDates + strategicDates)

        // Calculate maximum possible streak if all strategic days are played
        let sortedDates = allPotentialDates.sorted()
        var maxStreak = 0
        var currentStreak = 0

        for i in 0..<sortedDates.count {
            if i == 0 {
                currentStreak = 1
            } else {
                let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
                if daysBetween == 1 {
                    currentStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            }
        }
        maxStreak = max(maxStreak, currentStreak)

        return maxStreak
    }

    // MARK: - Strategic Priority System

    func calculateStrategicPriority(for date: Date, levels: [ShikakuLevel]) -> StrategicPriority {
        let today = Date()
        let completedDates = levels.filter { $0.isCompleted }.map { $0.date }.sorted()
        let segments = findConsecutiveSegments(dates: completedDates)

        // Check if it's a connection day
        for i in 0..<segments.count {
            for j in (i+1)..<segments.count {
                if let end1 = segments[i].last, let start2 = segments[j].first {
                    let daysBetween = calendar.dateComponents([.day], from: end1, to: start2).day ?? 0

                    if daysBetween > 1 && daysBetween <= 8 {
                        let daysFromEnd1 = calendar.dateComponents([.day], from: end1, to: date).day ?? 0
                        let daysToStart2 = calendar.dateComponents([.day], from: date, to: start2).day ?? 0

                        if daysFromEnd1 > 0 && daysToStart2 > 0 {
                            let potentialStreak = segments[i].count + (daysBetween - 1) + segments[j].count
                            return StrategicPriority(
                                title: "Bridge Gap",
                                icon: "link",
                                color: .purple,
                                streakPotential: potentialStreak - max(segments[i].count, segments[j].count)
                            )
                        }
                    }
                }
            }
        }

        // Check if it's an extension of the last segment (but not in future)
        if let lastSegment = segments.last, let lastDate = lastSegment.last {
            let daysFromLast = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0
            if daysFromLast > 0 && daysFromLast <= 5 &&
                calendar.compare(date, to: today, toGranularity: .day) != .orderedDescending {
                return StrategicPriority(
                    title: "Extend Streak",
                    icon: "arrow.up.right",
                    color: .green,
                    streakPotential: daysFromLast
                )
            }
        }

        // Check if it's today
        if calendar.isDateInToday(date) {
            return StrategicPriority(
                title: "Today's Challenge",
                icon: "calendar.badge.clock",
                color: .red,
                streakPotential: 1
            )
        }

        // Check if it's recent (in the past)
        let daysFromToday = calendar.dateComponents([.day], from: date, to: today).day ?? 0
        if daysFromToday > 0 && daysFromToday <= 7 {
            return StrategicPriority(
                title: "Recent Miss",
                icon: "clock.arrow.circlepath",
                color: .orange,
                streakPotential: 0
            )
        }

        // Default (older)
        return StrategicPriority(
            title: "Fill Gap",
            icon: "square.dashed",
            color: .blue,
            streakPotential: 0
        )
    }

    // MARK: - Helper Methods

    func focusOnToday() {
        let today = Date()
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = today
            currentMonth = today
        }
    }

    func generateCalendarDays() -> [CalendarDay] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30

        var days: [CalendarDay] = []

        // Add empty days for the start of the week with unique IDs
        for i in 1..<firstWeekday {
            let emptyDate = calendar.date(byAdding: .day, value: -i, to: startOfMonth) ?? Date.distantPast
            days.append(CalendarDay(date: emptyDate, dayNumber: 0, isCurrentMonth: false))
        }

        // Add days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date, dayNumber: day, isCurrentMonth: true))
            }
        }

        return days
    }

    func calculateCurrentMaxStreak(levels: [ShikakuLevel]) -> Int {
        let completedDates = levels.filter { $0.isCompleted }.map { $0.date }.sorted()
        var maxStreak = 0
        var currentStreak = 0

        for i in 0..<completedDates.count {
            if i == 0 {
                currentStreak = 1
            } else {
                let daysBetween = calendar.dateComponents([.day], from: completedDates[i-1], to: completedDates[i]).day ?? 0
                if daysBetween == 1 {
                    currentStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            }
        }
        return max(maxStreak, currentStreak)
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentMonth)
    }

    var selectedDateTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Game Actions

    func loadSelectedLevel() {
        guard let level = selectedLevel else { return }

        // Configure game with level data
        game.gridSize = (level.gridRows, level.gridCols)
        game.numberClues = level.toNumberClues()
        game.rectangles = []
        game.validateGame()
    }

    func navigateMonth(direction: Int) {
        withAnimation(.spring(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: direction, to: currentMonth) ?? currentMonth
        }
    }

    func selectDate(_ date: Date) {
        withAnimation(.spring(duration: 0.2)) {
            selectedDate = date
        }
    }
}

// MARK: - Supporting Types

struct StrategicPriority {
    let title: String
    let icon: String
    let color: Color
    let streakPotential: Int
}

struct CalendarDay {
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
}
