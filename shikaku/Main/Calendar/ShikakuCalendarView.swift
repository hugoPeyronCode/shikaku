//
//  ShikakuCalendarView.swift
//  shikaku
//
//  Enhanced calendar view with horizontal scroll and transition - Cleaned up
//

import SwiftUI
import SwiftData

struct ShikakuCalendarView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \ShikakuLevel.date, order: .reverse) private var levels: [ShikakuLevel]
  @Query private var progress: [GameProgress]

  @State private var viewModel = ShikakuCalendarViewModel()
  @State private var isHorizontalMode = true

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        headerView

        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 32) {
            if isHorizontalMode {
              horizontalCalendarSection
            } else {
              fullCalendarSection
            }

            dailyShikakuSection
              .padding(.horizontal)

            Spacer(minLength: 100)
          }
          .padding(.top)
        }
      }
      .background(Color(.systemBackground))
      .navigationTitle("")
      .sheet(isPresented: $viewModel.showLevelBuilder) {
        LevelBuilderView()
      }
      .sheet(isPresented: $viewModel.showingLevelEditor) {
        LevelEditorSheet(selectedDate: viewModel.selectedDate)
          .environment(\.modelContext, modelContext)
      }
      .fullScreenCover(isPresented: $viewModel.showingGameView) {
        ZStack {
          ShikakuGameView(game: viewModel.game)
            .onAppear {
              viewModel.loadSelectedLevel()
            }
            .onChange(of: viewModel.game.isGameComplete) { _, isComplete in
              if isComplete && viewModel.selectedLevel?.isCompleted == false {
                markLevelCompleted()
              }
            }

          VStack {
            HStack {
              Spacer()
              Button {
                viewModel.showingGameView = false
              } label: {
                Image(systemName: "xmark")
                  .font(.title2)
                  .fontWeight(.medium)
                  .foregroundStyle(.primary)
                  .frame(width: 32, height: 32)
                  .background(
                    Circle()
                      .fill(.ultraThinMaterial)
                      .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                  )
              }
              .sensoryFeedback(.impact(weight: .light), trigger: false)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            Spacer()
          }
        }
      }
      .onAppear {
        initializeProgressIfNeeded()
      }
    }
  }

  // MARK: - Header

  private var headerView: some View {
    HStack {
      Image(systemName: "puzzlepiece.extension.fill")
        .font(.title2)
        .foregroundStyle(.primary)

      Text("Shikaku")
        .font(.title)
        .fontWeight(.bold)

      Spacer()

      Button("Builder") {
        viewModel.showLevelBuilder = true
      }

      Button {
        viewModel.showingLevelEditor = true
      } label: {
        Image(systemName: "plus.circle")
          .font(.title2)
          .foregroundStyle(.primary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.showingLevelEditor)
    }
    .padding(.horizontal)
    .padding(.top, 8)
  }

  // MARK: - Calendar Sections

  private var horizontalCalendarSection: some View {
    VStack(spacing: 16) {
      monthNavigationHeader(showExpandButton: true)

      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 12) {
          ForEach(currentMonthDays, id: \.date) { day in
            CalendarDayView(
              day: day,
              isSelected: Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate),
              level: viewModel.levelForDate(day.date, levels: levels),
              isStrategic: strategicDays.contains { Calendar.current.isDate($0, inSameDayAs: day.date) },
              colorScheme: colorScheme,
              isCompact: true
            ) {
              viewModel.selectDate(day.date)
            }
          }
        }
        .padding(.horizontal)
      }
    }
    .transition(.asymmetric(
      insertion: .move(edge: .top).combined(with: .opacity),
      removal: .move(edge: .top).combined(with: .opacity)
    ))
  }

  private var fullCalendarSection: some View {
    VStack(spacing: 24) {
      // Stats
      HStack(spacing: 40) {
        StatItem(value: currentProgress.totalCompletedLevels, label: "Completed\ndays")
        StatItem(value: viewModel.calculateMaxPossibleStreak(levels: levels), label: "Max possible\nstreak")
        StatItem(value: currentProgress.maxStreak, label: "Best\nstreak")
      }

      monthNavigationHeader(showExpandButton: false)

      // Calendar grid
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
        ForEach(Array(viewModel.generateCalendarDays().enumerated()), id: \.offset) { index, day in
          CalendarDayView(
            day: day,
            isSelected: Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate),
            level: viewModel.levelForDate(day.date, levels: levels),
            isStrategic: strategicDays.contains { Calendar.current.isDate($0, inSameDayAs: day.date) },
            colorScheme: colorScheme,
            isCompact: false
          ) {
            viewModel.selectDate(day.date)
          }
        }
      }
      .padding(.horizontal)
    }
    .transition(.asymmetric(
      insertion: .move(edge: .bottom).combined(with: .opacity),
      removal: .move(edge: .bottom).combined(with: .opacity)
    ))
  }

  // MARK: - Shared Components

  private func monthNavigationHeader(showExpandButton: Bool) -> some View {
    HStack {
      Button {
        viewModel.navigateMonth(direction: -1)
      } label: {
        Image(systemName: "chevron.left")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.currentMonth)

      Spacer()

      Text(viewModel.monthTitle)
        .font(showExpandButton ? .headline : .title2)
        .fontWeight(.medium)

      Spacer()

      if showExpandButton {
        Button {
          withAnimation(.easeInOut(duration: 0.3)) {
            isHorizontalMode = false
          }
        } label: {
          Image(systemName: "rectangle.grid.3x2")
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: !isHorizontalMode)
      } else {
        Button {
          withAnimation(.easeInOut(duration: 0.3)) {
            isHorizontalMode = true
          }
        } label: {
          Image(systemName: "rectangle.compress.vertical")
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isHorizontalMode)
      }

      Button {
        viewModel.navigateMonth(direction: 1)
      } label: {
        Image(systemName: "chevron.right")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.currentMonth)
    }
    .padding(.horizontal)
  }

  private var dailyShikakuSection: some View {
    VStack(spacing: 20) {
      HStack {
        Text(viewModel.selectedDateTitle)
          .font(.title2)
          .fontWeight(.medium)

        Spacer()

        if let priority = currentDayPriority {
          HStack(spacing: 6) {
            Image(systemName: priority.icon)
              .font(.caption)
              .foregroundStyle(priority.color)
            Text(priority.title)
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(priority.color)

            if priority.streakPotential > 0 {
              Text("(+\(priority.streakPotential))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(priority.color.opacity(0.7))
            }
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(
            Capsule()
              .fill(priority.color.opacity(0.1))
              .overlay(
                Capsule()
                  .stroke(priority.color.opacity(0.3), lineWidth: 1)
              )
          )
        }
      }

      if let level = viewModel.levelForDate(viewModel.selectedDate, levels: levels) {
        DailyShikakuCard(level: level) {
          viewModel.selectedLevel = level
          viewModel.showingGameView = true
        }
      } else {
        NoDailyShikakuCard(date: viewModel.selectedDate) {
          viewModel.showingLevelEditor = true
        }
      }
    }
  }

  // MARK: - Computed Properties

  private var currentProgress: GameProgress {
    progress.first ?? GameProgress()
  }

  private var strategicDays: [Date] {
    viewModel.calculateStrategicDays(levels: levels)
  }

  private var currentMonthDays: [CalendarDay] {
    let calendar = Calendar.current
    let currentMonth = viewModel.currentMonth

    guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
          let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth) else {
      return []
    }

    return daysInMonth.compactMap { dayNumber in
      if let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthInterval.start) {
        return CalendarDay(date: date, dayNumber: dayNumber, isCurrentMonth: true)
      }
      return nil
    }
  }

  private var currentDayPriority: StrategicPriority? {
    if strategicDays.contains(where: { Calendar.current.isDate($0, inSameDayAs: viewModel.selectedDate) }) {
      return viewModel.calculateStrategicPriority(for: viewModel.selectedDate, levels: levels)
    }
    return nil
  }

  // MARK: - Helper Functions

  private func markLevelCompleted() {
    guard let level = viewModel.selectedLevel else { return }

    level.isCompleted = true
    level.completionTime = Date().timeIntervalSinceReferenceDate

    let fetchDescriptor = FetchDescriptor<GameProgress>()
    if let progressArray = try? modelContext.fetch(fetchDescriptor),
       let progress = progressArray.first {
      progress.totalCompletedLevels += 1
      let newMaxStreak = viewModel.calculateCurrentMaxStreak(levels: levels)
      progress.maxStreak = max(progress.maxStreak, newMaxStreak)
      progress.lastPlayedDate = Date()
    }

    try? modelContext.save()
  }

  private func initializeProgressIfNeeded() {
    if progress.isEmpty {
      let newProgress = GameProgress()
      modelContext.insert(newProgress)
      try? modelContext.save()
    }
  }
}

// MARK: - Unified Calendar Day View

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

// MARK: - Supporting Views

struct DailyShikakuCard: View {
  let level: ShikakuLevel
  let onPlay: () -> Void

  private var gameStatus: GameStatus {
    level.isCompleted ? .completed : .new
  }

  enum GameStatus {
    case new, completed

    var title: String {
      switch self {
      case .new: return "Start Today's Puzzle"
      case .completed: return "Completed!"
      }
    }

    var subtitle: String {
      switch self {
      case .new: return "New puzzle available"
      case .completed: return "Play again or review solution"
      }
    }

    var icon: String {
      switch self {
      case .new: return "play.circle.fill"
      case .completed: return "checkmark.circle.fill"
      }
    }

    var color: Color {
      switch self {
      case .new: return .primary
      case .completed: return .green
      }
    }
  }

  var body: some View {
    Button(action: onPlay) {
      VStack(spacing: 0) {
        miniGridPreview
          .padding(.top, 20)
          .padding(.horizontal, 20)

        Spacer()

        VStack(spacing: 12) {
          HStack(spacing: 12) {
            Image(systemName: gameStatus.icon)
              .font(.title2)
              .foregroundStyle(gameStatus.color)

            VStack(alignment: .leading, spacing: 4) {
              Text(gameStatus.title)
                .font(.headline)
                .foregroundStyle(.primary)

              Text(gameStatus.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          HStack {
            Text("Difficulty:")
              .font(.caption)
              .foregroundStyle(.secondary)

            HStack(spacing: 4) {
              ForEach(1...5, id: \.self) { level in
                Circle()
                  .fill(level <= self.level.difficulty ? Color.primary : Color.secondary.opacity(0.2))
                  .frame(width: 6, height: 6)
              }
            }

            Spacer()

            Text("\(level.gridRows)×\(level.gridCols)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(20)
        .background(Rectangle().fill(.ultraThinMaterial))
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

  private var miniGridPreview: some View {
    let cellSize: CGFloat = 20
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
                  .font(.system(size: 10, weight: .bold))
                  .foregroundStyle(.primary)
              }
            }
          }
        }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

struct NoDailyShikakuCard: View {
  let date: Date
  let onCreate: () -> Void

  var body: some View {
    Button(action: onCreate) {
      VStack(spacing: 20) {
        Image(systemName: "plus.circle.dashed")
          .font(.system(size: 40))
          .foregroundStyle(.secondary)

        VStack(spacing: 8) {
          Text("No puzzle for this day")
            .font(.headline)
            .foregroundStyle(.primary)

          Text("Tap to create a new puzzle")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 200)
    }
    .buttonStyle(.plain)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.thinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    )
    .sensoryFeedback(.impact(weight: .light), trigger: false)
  }
}

struct StatItem: View {
  let value: Int
  let label: String

  var body: some View {
    VStack(spacing: 8) {
      Text("\(value)")
        .font(.title)
        .fontWeight(.medium)
        .monospacedDigit()

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
  }
}

struct LevelEditorSheet: View {
  let selectedDate: Date
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @State private var editor = LevelEditor()

  var body: some View {
    NavigationStack {
      ShikakuLevelEditorView(editor: editor)
        .navigationTitle("Create Level")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
              dismiss()
            }
          }

          ToolbarItem(placement: .topBarTrailing) {
            Button("Save") {
              saveLevel()
              dismiss()
            }
            .fontWeight(.medium)
            .disabled(!editor.validateLevel().isValid)
          }
        }
    }
  }

  private func saveLevel() {
    let level = ShikakuLevel.from(
      numberClues: editor.numberClues,
      date: selectedDate,
      gridSize: editor.gridSize
    )

    level.difficulty = editor.estimateDifficulty()

    let fetchDescriptor = FetchDescriptor<ShikakuLevel>()
    if let existingLevels = try? modelContext.fetch(fetchDescriptor) {
      for existingLevel in existingLevels {
        if Calendar.current.isDate(existingLevel.date, inSameDayAs: selectedDate) {
          modelContext.delete(existingLevel)
        }
      }
    }

    modelContext.insert(level)
    try? modelContext.save()
  }
}

#Preview {
  ShikakuCalendarView()
    .modelContainer(for: [ShikakuLevel.self, GameProgress.self, LevelClue.self])
}
