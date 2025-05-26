//
//  ShikakuCalendarViewModel.swift
//  shikaku
//
//  ViewModel for calendar with intelligent streak strategy
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

  private let calendar = Calendar.current

  // MARK: - Streak Strategy Logic

  func calculateStrategicDays(levels: [ShikakuLevel]) -> [Date] {
    let completedDates = levels.filter { $0.isCompleted }.map { $0.date }
    var strategicDates: [Date] = []

    // Grouper les jours complétés en segments consécutifs
    let sortedCompletedDates = completedDates.sorted()
    let segments = findConsecutiveSegments(dates: sortedCompletedDates)

    // Trouver les jours stratégiques qui peuvent connecter les segments
    strategicDates.append(contentsOf: findConnectionDays(segments: segments))

    // Ajouter les jours qui étendent le segment le plus récent
    strategicDates.append(contentsOf: findExtensionDays(segments: segments))

    // Ajouter les jours qui créent de nouveaux segments près d'aujourd'hui
    strategicDates.append(contentsOf: findNearbyOpportunities(levels: levels))

    return Array(Set(strategicDates)) // Supprimer les doublons
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

          if daysBetween > 1 && daysBetween <= 8 { // Maximum 7 jours manqués
            for dayOffset in 1..<daysBetween {
              if let strategicDate = calendar.date(byAdding: .day, value: dayOffset, to: end1) {
                // Ajouter seulement si c'est dans le passé ou aujourd'hui
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

    // Ajouter seulement les jours jusqu'à aujourd'hui (pas dans le futur)
    var dayOffset = 1
    while dayOffset <= 5 {
      if let nextDate = calendar.date(byAdding: .day, value: dayOffset, to: lastDate) {
        // Arrêter si on dépasse aujourd'hui
        if calendar.compare(nextDate, to: today, toGranularity: .day) == .orderedDescending {
          break
        }
        extensionDays.append(nextDate)
      }
      dayOffset += 1
    }

    return extensionDays
  }

  func findNearbyOpportunities(levels: [ShikakuLevel]) -> [Date] {
    let today = Date()
    var nearbyDays: [Date] = []

    // Chercher des opportunités SEULEMENT dans le passé et aujourd'hui
    for dayOffset in -30...0 { // 30 jours dans le passé maximum, jusqu'à aujourd'hui
      if let candidateDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
        // Vérifier si ce jour n'est pas déjà complété
        let isCompleted = levels.contains { level in
          level.isCompleted && calendar.isDate(level.date, inSameDayAs: candidateDate)
        }

        if !isCompleted {
          // Vérifier s'il y a un niveau pour ce jour
          let hasLevel = levels.contains { level in
            calendar.isDate(level.date, inSameDayAs: candidateDate)
          }

          if hasLevel {
            nearbyDays.append(candidateDate)
          }
        }
      }
    }

    return nearbyDays
  }

  func calculateMaxPossibleStreak(levels: [ShikakuLevel]) -> Int {
    let completedDates = levels.filter { $0.isCompleted }.map { $0.date }
    let strategicDates = calculateStrategicDays(levels: levels)
    let allPotentialDates = Set(completedDates + strategicDates)

    // Calculer la streak maximale possible si tous les jours stratégiques sont joués
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

    // Vérifier si c'est un jour de connexion
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

    // Vérifier si c'est une extension du dernier segment (mais pas dans le futur)
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

    // Vérifier si c'est aujourd'hui
    if calendar.isDateInToday(date) {
      return StrategicPriority(
        title: "Today's Challenge",
        icon: "calendar.badge.clock",
        color: .red,
        streakPotential: 1
      )
    }

    // Vérifier si c'est récent (dans le passé)
    let daysFromToday = calendar.dateComponents([.day], from: date, to: today).day ?? 0
    if daysFromToday > 0 && daysFromToday <= 7 {
      return StrategicPriority(
        title: "Recent Miss",
        icon: "clock.arrow.circlepath",
        color: .orange,
        streakPotential: 0
      )
    }

    // Par défaut (plus ancien)
    return StrategicPriority(
      title: "Fill Gap",
      icon: "square.dashed",
      color: .blue,
      streakPotential: 0
    )
  }

  // MARK: - Helper Methods

  func generateCalendarDays() -> [CalendarDay] {
    let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
    let firstWeekday = calendar.component(.weekday, from: startOfMonth)
    let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30

    var days: [CalendarDay] = []

    // Add empty days for the start of the week avec des IDs uniques
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

  func levelForDate(_ date: Date, levels: [ShikakuLevel]) -> ShikakuLevel? {
    return levels.first { calendar.isDate($0.date, inSameDayAs: date) }
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
