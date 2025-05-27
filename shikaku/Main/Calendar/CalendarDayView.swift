//
//  CalendarDayView.swift
//  shikaku
//
//  Created by Hugo Peyron on 27/05/2025.
//


import SwiftUI
import SwiftData

struct CalendarDayView: View {
  let day: CalendarDay
  let isSelected: Bool
  let level: ShikakuLevel?
  let isStrategic: Bool
  let colorScheme: ColorScheme
  let isCompact: Bool
  let onTap: () -> Void

  private var isToday: Bool {
    Calendar.current.isDateInToday(day.date)
  }

  private var dayState: DayState {
    if !day.isCurrentMonth && !isCompact { return .inactive }
    if isToday { return .today }
    if level == nil { return .noLevel }
    if level?.isCompleted == true { return .completed }
    if isStrategic { return .strategic }
    return .hasLevel
  }

  enum DayState {
    case inactive, noLevel, hasLevel, completed, today, strategic
  }

  var body: some View {
    Button(action: onTap) {
      if isCompact {
        compactDayView
      } else {
        fullDayView
      }
    }
    .buttonStyle(.plain)
    .disabled(!day.isCurrentMonth && !isCompact)
    .sensoryFeedback(.impact(weight: .light), trigger: isSelected)
  }

  private var compactDayView: some View {
    VStack(spacing: 8) {
      Text("\(day.dayNumber)")
        .font(.system(size: 16, weight: isSelected ? .bold : .medium))
        .foregroundStyle(textColor)
        .frame(width: 36, height: 36)
        .background(
          Circle()
            .fill(backgroundColor)
            .overlay(
              Circle()
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        )
        .overlay(strategicIndicator)

      Text(dayLabel)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
    }
  }

  private var fullDayView: some View {
    VStack(spacing: 4) {
      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(backgroundColor)
          .frame(width: 44, height: 44)
          .overlay(progressRing)
          .overlay(strategicIndicator)
          .overlay(selectionHighlight)

        if dayState == .completed {
          Image(systemName: "checkmark")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(checkmarkColor)
        } else if day.isCurrentMonth {
          Text("\(day.dayNumber)")
            .font(.system(size: 16, weight: dayState == .today ? .bold : .medium))
            .foregroundStyle(textColor)
        }

        if level?.difficulty != nil && dayState != .completed {
          VStack {
            Spacer()
            HStack {
              Spacer()
              Text("\(level?.difficulty ?? 1)/5")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
            }
          }
          .frame(width: 44, height: 44)
        }
      }

      Text(dayLabel)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
    }
  }

  // MARK: - Shared Computed Properties

  private var backgroundColor: Color {
    switch dayState {
    case .inactive, .noLevel:
      return Color.clear
    case .hasLevel:
      return Color.secondary.opacity(0.1)
    case .completed:
      return Color.primary
    case .today:
      return Color.red.opacity(0.6)
    case .strategic:
      return Color.orange.opacity(0.2)
    }
  }

  private var textColor: Color {
    switch dayState {
    case .inactive:
      return .clear
    case .noLevel:
      return .secondary.opacity(0.3)
    case .hasLevel:
      return .primary
    case .completed:
      return colorScheme == .dark ? .black : .white
    case .today:
      return .white
    case .strategic:
      return .primary
    }
  }

  private var checkmarkColor: Color {
    colorScheme == .dark ? .black : .white
  }

  private var strategicIndicator: some View {
    Group {
      if isStrategic && dayState != .completed {
        VStack {
          HStack {
            Image(systemName: "star.fill")
              .font(.system(size: isCompact ? 6 : 8))
              .foregroundStyle(.orange)
              .shadow(color: .orange.opacity(0.3), radius: 2)
            Spacer()
          }
          Spacer()
        }
        .frame(width: isCompact ? 36 : 44, height: isCompact ? 36 : 44)
      }
    }
  }

  private var progressRing: some View {
    Group {
      if let level = level, !level.isCompleted && !isCompact {
        let progress = calculateLevelProgress(level)

        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            LinearGradient(
              colors: [.blue, .cyan],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
          .frame(width: 48, height: 48)
          .animation(.easeInOut(duration: 0.3), value: progress)
      }
    }
  }

  private var selectionHighlight: some View {
    Group {
      if isSelected && !isCompact {
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            LinearGradient(
              colors: [.blue, .cyan],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 3
          )
          .frame(width: 48, height: 48)
          .shadow(color: .blue.opacity(0.3), radius: 4)
          .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isSelected)
      }
    }
  }

  private var dayLabel: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "E"
    return day.isCurrentMonth || isCompact ? formatter.string(from: day.date) : ""
  }

  private func calculateLevelProgress(_ level: ShikakuLevel) -> Double {
    let daysSinceCreation = Calendar.current.dateComponents([.day], from: level.createdAt, to: Date()).day ?? 0
    let baseProgress = min(Double(daysSinceCreation) * 0.1, 0.8)
    let progressSeed = Double(level.id.hashValue % 100) / 100.0 * 0.6
    return min(baseProgress + progressSeed, 0.9)
  }
}