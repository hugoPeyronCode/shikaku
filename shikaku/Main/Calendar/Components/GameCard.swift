//
//  GameCard.swift
//  shikaku
//
//  Generic game card component for daily and practice modes
//

import SwiftUI
import SwiftData

enum GameCardType {
  case daily
  case practice

  var title: String {
    switch self {
    case .daily: return "Today's Puzzle"
    case .practice: return "Practice Mode"
    }
  }

  var icon: String {
    switch self {
    case .daily: return "calendar.circle.fill"
    case .practice: return "dumbbell.fill"
    }
  }

  var primaryColor: Color {
    switch self {
    case .daily: return .blue
    case .practice: return .green
    }
  }
}

struct GameCard: View {
  let type: GameCardType
  let level: ShikakuLevel?
  let date: Date
  let progress: GameProgress
  let onTap: () -> Void

  private var cardData: GameCardData {
    switch type {
    case .daily:
      return dailyCardData
    case .practice:
      return practiceCardData
    }
  }

  private var dailyCardData: GameCardData {
    if let level = level {
      if level.isCompleted {
        return GameCardData(
          status: .completed,
          title: "Completed!",
          subtitle: "Well done! Play again or review solution",
          actionText: "Review",
          stats: [
            ("Difficulty", "\(level.difficulty)/5"),
            ("Grid", "\(level.gridRows)×\(level.gridCols)"),
            ("Clues", "\(level.clues.count)")
          ]
        )
      } else {
        return GameCardData(
          status: .available,
          title: "Start Today's Puzzle",
          subtitle: "New puzzle available",
          actionText: "Play",
          stats: [
            ("Difficulty", "\(level.difficulty)/5"),
            ("Grid", "\(level.gridRows)×\(level.gridCols)"),
            ("Clues", "\(level.clues.count)")
          ]
        )
      }
    } else {
      return GameCardData(
        status: .unavailable,
        title: "No puzzle for today",
        subtitle: "Tap to create a new puzzle",
        actionText: "Create",
        stats: []
      )
    }
  }

  private var practiceCardData: GameCardData {
    let todayPracticeSessions = getTodayPracticeSessions()

    if todayPracticeSessions > 0 {
      return GameCardData(
        status: .inProgress,
        title: "Practice Session",
        subtitle: "\(todayPracticeSessions) levels completed today",
        actionText: "Continue",
        stats: [
          ("Today", "\(todayPracticeSessions)"),
          ("Streak", "\(progress.currentStreak)"),
          ("Total", "\(progress.totalCompletedLevels)")
        ]
      )
    } else {
      return GameCardData(
        status: .available,
        title: "Daily Practice",
        subtitle: "Sharpen your puzzle-solving skills",
        actionText: "Start",
        stats: [
          ("Best Streak", "\(progress.maxStreak)"),
          ("Total", "\(progress.totalCompletedLevels)"),
          ("Available", "∞")
        ]
      )
    }
  }

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 0) {
        // Top section with mini preview or icon
        topSection
          .padding(.top, 20)
          .padding(.horizontal, 20)

        Spacer()

        // Bottom section with info
        bottomSection
          .padding(20)
          .background(.ultraThinMaterial)
      }
    }
    .buttonStyle(.plain)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.thinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    )
    .sensoryFeedback(.impact(weight: .medium), trigger: false)
  }

  private var topSection: some View {
    VStack(spacing: 16) {
      if type == .daily, let level = level {
        // Mini grid preview for daily puzzles
        miniGridPreview(level: level)
      } else {
        // Icon for practice or no level
        Image(systemName: type.icon)
          .font(.system(size: 40))
          .foregroundStyle(cardData.status == .unavailable ? .secondary : type.primaryColor)
      }
    }
  }

  private var bottomSection: some View {
    VStack(spacing: 12) {
      // Main info
      HStack(spacing: 12) {
        Image(systemName: cardData.status.icon)
          .font(.title2)
          .foregroundStyle(cardData.status.color)

        VStack(alignment: .leading, spacing: 4) {
          Text(cardData.title)
            .font(.headline)
            .foregroundStyle(.primary)

          Text(cardData.subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Action indicator
        HStack(spacing: 4) {
          Text(cardData.actionText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(type.primaryColor)

          Image(systemName: "chevron.right")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }

      // Stats
      if !cardData.stats.isEmpty {
        HStack {
          ForEach(Array(cardData.stats.enumerated()), id: \.offset) { index, stat in
            VStack(spacing: 2) {
              Text(stat.1)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

              Text(stat.0)
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            if index < cardData.stats.count - 1 {
              Text("•")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }

          Spacer()
        }
      }
    }
  }

  private func miniGridPreview(level: ShikakuLevel) -> some View {
    let cellSize: CGFloat = 16
    let maxDisplaySize = 8
    let displayRows = min(level.gridRows, maxDisplaySize)
    let displayCols = min(level.gridCols, maxDisplaySize)

    return VStack(spacing: 1) {
      ForEach(0..<displayRows, id: \.self) { row in
        HStack(spacing: 1) {
          ForEach(0..<displayCols, id: \.self) { col in
            let position = GridPosition(row: row, col: col)
            let clue = level.clues.first { GridPosition(row: $0.row, col: $0.col) == position }

            ZStack {
              Rectangle()
                .fill(.background)
                .frame(width: cellSize, height: cellSize)

              Rectangle()
                .stroke(.secondary.opacity(0.3), lineWidth: 0.5)
                .frame(width: cellSize, height: cellSize)

              if let clue = clue {
                Text("\(clue.value)")
                  .font(.system(size: 8, weight: .bold))
                  .foregroundStyle(.primary)
              }
            }
          }
        }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private func getTodayPracticeSessions() -> Int {
    // TODO: Implement practice session tracking
    // For now, return a mock value based on date
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return Int.random(in: 0...5)
    }
    return 0
  }
}

// MARK: - Supporting Types

struct GameCardData {
  let status: GameCardStatus
  let title: String
  let subtitle: String
  let actionText: String
  let stats: [(String, String)] // (label, value) pairs
}

enum GameCardStatus {
  case available
  case completed
  case inProgress
  case unavailable

  var icon: String {
    switch self {
    case .available: return "play.circle.fill"
    case .completed: return "checkmark.circle.fill"
    case .inProgress: return "hourglass.circle.fill"
    case .unavailable: return "plus.circle.dashed"
    }
  }

  var color: Color {
    switch self {
    case .available: return .blue
    case .completed: return .green
    case .inProgress: return .orange
    case .unavailable: return .secondary
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    // Daily card with level
    GameCard(
      type: .daily,
      level: ShikakuLevel(date: Date(), gridRows: 6, gridCols: 8, difficulty: 3),
      date: Date(),
      progress: GameProgress()
    ) {
      print("Daily tapped")
    }

    // Practice card
    GameCard(
      type: .practice,
      level: nil,
      date: Date(),
      progress: GameProgress()
    ) {
      print("Practice tapped")
    }
  }
  .padding()
}
