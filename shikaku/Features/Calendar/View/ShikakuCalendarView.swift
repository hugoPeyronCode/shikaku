//
//  ShikakuCalendarView.swift - Fixed version
//  shikaku
//

import SwiftUI
import SwiftData

struct ShikakuCalendarView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \ShikakuLevel.date, order: .reverse) private var levels: [ShikakuLevel]
  @Query private var progress: [GameProgress]

  @State private var coordinator = AppCoordinator()
  @State private var viewModel = ShikakuCalendarViewModel()
  @State private var isHorizontalMode = true
  @State private var isGeneratingLevels = false

  var body: some View {
    NavigationStack(path: $coordinator.navigationPath) {
      VStack(spacing: 0) {
        headerView

        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 32) {
            // Calendar section
            if isHorizontalMode {
              horizontalCalendarSection
            } else {
              fullCalendarSection
            }

            gameCardsSection
              .padding(.horizontal)

            // Combined stats section
            combinedStatsSection
              .padding(.horizontal)

            Spacer(minLength: 100)
          }
          .padding(.top)
        }
      }
      .background(Color(.systemBackground))
      .navigationTitle("")
      .environment(coordinator)
      .navigationDestination(for: AppCoordinator.NavigationDestination.self) { destination in
         navigationContent(for: destination)
       }
    }
    .sheet(item: $coordinator.presentedSheet) { destination in
      sheetContent(for: destination)
    }
    .fullScreenCover(item: $coordinator.presentedFullScreen) { destination in
      fullScreenContent(for: destination)
    }
    .onAppear {
      initializeProgressIfNeeded()
      if Calendar.current.dateComponents([.day], from: viewModel.selectedDate, to: Date()).day != 0 {
        viewModel.focusOnToday()
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
        coordinator.presentSheet(.levelBuilder)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: false)

      Button {
        coordinator.presentSheet(.levelEditor(date: viewModel.selectedDate))
      } label: {
        Image(systemName: "plus.circle")
          .font(.title2)
          .foregroundStyle(.primary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: false)
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

  // MARK: - Months Header

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

      // Focus on today button
      Button {
        viewModel.focusOnToday()
      } label: {
        Image(systemName: "location")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.selectedDate)

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

  // MARK: - Game Cards Section

  private var gameCardsSection: some View {
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

      VStack(spacing: 16) {
        // Daily Level Card
        GameCard(
          type: .daily,
          level: viewModel.levelForDate(viewModel.selectedDate, levels: levels),
          date: viewModel.selectedDate,
          progress: currentProgress
        ) {
          if let level = viewModel.levelForDate(viewModel.selectedDate, levels: levels) {
            playLevel(level, context: .daily(viewModel.selectedDate))
          } else {
            coordinator.presentSheet(.levelEditor(date: viewModel.selectedDate))
          }
        }

        // Practice Card
        GameCard(
          type: .practice,
          level: nil,
          date: viewModel.selectedDate,
          progress: currentProgress
        ) {
          coordinator.push(.practiceMode(levels))
        }
      }
    }
  }

  // MARK: - Combined Stats Section

  private var combinedStatsSection: some View {
    VStack(spacing: 20) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Progress Overview")
            .font(.headline)
            .fontWeight(.medium)

          Text("\(levels.count) levels • \(currentProgress.totalCompletedLevels) completed")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Prestige button (only show when all levels completed)
        if isEligibleForPrestige {
          Button {
            performPrestige()
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "crown.fill")
                .font(.caption)
              Text("Prestige")
                .font(.caption)
                .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
              LinearGradient(
                colors: [.purple, .pink],
                startPoint: .leading,
                endPoint: .trailing
              ),
              in: Capsule()
            )
            .shadow(color: .purple.opacity(0.3), radius: 4, y: 2)
          }
          .sensoryFeedback(.impact(weight: .medium), trigger: isGeneratingLevels)
        } else if levels.count < 100 {
          // Initial generation button (only for first time setup)
          Button {
            generateAllLevels()
          } label: {
            HStack(spacing: 8) {
              if isGeneratingLevels {
                ProgressView()
                  .scaleEffect(0.8)
                Text("Generating...")
                  .font(.caption)
              } else {
                Image(systemName: "plus.square.fill")
                  .font(.caption)
                Text("Generate Levels")
                  .font(.caption)
                  .fontWeight(.medium)
              }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.blue, in: Capsule())
          }
          .disabled(isGeneratingLevels)
          .sensoryFeedback(.impact(weight: .medium), trigger: isGeneratingLevels)
        }
      }

      // Main stats grid
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
        StatCard(
          value: currentProgress.totalCompletedLevels,
          label: "Completed",
          icon: "checkmark.circle.fill",
          color: .green
        )

        StatCard(
          value: viewModel.calculateMaxPossibleStreak(levels: levels),
          label: "Max Streak",
          icon: "flame.fill",
          color: .orange
        )

        StatCard(
          value: currentProgress.maxStreak,
          label: "Best Streak",
          icon: "star.fill",
          color: .yellow
        )
      }

      // Secondary stats
      if levels.count >= 100 {
        Divider()
          .opacity(0.5)

        HStack(spacing: 0) {
          let completedCount = levels.filter { $0.isCompleted }.count
          let totalLevels = levels.count
          let completionPercentage = totalLevels > 0 ? (completedCount * 100) / totalLevels : 0

          StatMini(value: completedCount, label: "Total Solved")

          Divider()
            .frame(height: 30)
            .opacity(0.3)

          StatMini(value: completionPercentage, label: "% Complete")

          Divider()
            .frame(height: 30)
            .opacity(0.3)

          StatMini(value: currentProgress.currentStreak, label: "Current Streak")
        }
      }

      // Prestige info (if applicable)
      if currentProgress.prestigeLevel > 0 {
        HStack(spacing: 8) {
          Image(systemName: "crown.fill")
            .font(.caption)
            .foregroundStyle(.purple)

          Text("Prestige Level \(currentProgress.prestigeLevel)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.purple)

          Spacer()

          Text("\(currentProgress.totalLifetimeCompletions) lifetime completions")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
          Capsule()
            .fill(.purple.opacity(0.1))
            .overlay(
              Capsule()
                .stroke(.purple.opacity(0.3), lineWidth: 1)
            )
        )
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.thinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    )
  }

  // MARK: - Sheet and FullScreen Content

  @ViewBuilder
  private func navigationContent(for destination: AppCoordinator.NavigationDestination) -> some View {
      switch destination {
      case .practiceMode(let levels):
          PracticeModeView(levels: levels, coordinator: coordinator)
              .environment(\.modelContext, modelContext)
              .environment(coordinator)
      }
  }

  @ViewBuilder
  private func sheetContent(for destination: AppCoordinator.SheetDestination) -> some View {
    switch destination {
    case .levelEditor(let date):
      LevelEditorSheet(selectedDate: date)
        .environment(\.modelContext, modelContext)
    case .levelBuilder:
      LevelBuilderView()
        .environment(\.modelContext, modelContext)
    }
  }

  @ViewBuilder
  private func fullScreenContent(for destination: AppCoordinator.FullScreenDestination) -> some View {
    switch destination {
    case .game(let session):
      ShikakuGameView(session: session)
        .environment(\.modelContext, modelContext)
        .environment(coordinator)
        .onChange(of: session.game.isGameComplete) { _, isComplete in
          if isComplete && !session.isCompleted {
            handleGameCompletion(session: session)
          }
        }
    }
  }

  // MARK: - Actions

  private func playLevel(_ level: ShikakuLevel, context: GameSession.GameContext) {
    let session = GameSession(level: level, context: context)
    coordinator.presentFullScreen(.game(session))
  }

  private func handleGameCompletion(session: GameSession) {
    session.complete()

    // Update level completion in database
    session.level.isCompleted = true
    session.level.completionTime = Date().timeIntervalSinceReferenceDate

    // Update progress stats
    let fetchDescriptor = FetchDescriptor<GameProgress>()
    if let progressArray = try? modelContext.fetch(fetchDescriptor),
       let progress = progressArray.first {
      progress.totalCompletedLevels += 1
      let newMaxStreak = viewModel.calculateCurrentMaxStreak(levels: levels)
      progress.maxStreak = max(progress.maxStreak, newMaxStreak)
      progress.lastPlayedDate = Date()
    }

    do {
      try modelContext.save()
    } catch {
      print("Failed to save game completion: \(error)")
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

  // MARK: - Prestige System

  private var isEligibleForPrestige: Bool {
    let totalLevels = levels.count
    let completedLevels = levels.filter { $0.isCompleted }.count
    return totalLevels > 0 && completedLevels == totalLevels && totalLevels >= 100
  }

  private func performPrestige() {
    isGeneratingLevels = true

    Task {
      // Update prestige stats
      await MainActor.run {
        let progress = currentProgress
        progress.prestigeLevel += 1
        progress.totalLifetimeCompletions += progress.totalCompletedLevels
        progress.currentStreak = 0 // Reset current streak, but keep max streak
      }

      // Reset all levels to uncompleted
      for level in levels {
        level.isCompleted = false
        level.completionTime = nil
      }

      // Generate new levels for variety
      let manager = LevelBuilderManager()
      let calendar = Calendar.current
      let today = Date()

      // Clear existing levels
      let fetchDescriptor = FetchDescriptor<ShikakuLevel>()
      if let existingLevels = try? modelContext.fetch(fetchDescriptor) {
        for level in existingLevels {
          modelContext.delete(level)
        }
      }

      // Generate fresh set of 500 levels
      guard let startDate = calendar.date(byAdding: .day, value: -250, to: today) else { return }

      await MainActor.run {
        for batchStart in stride(from: 0, to: 500, by: 50) {
          let batchEnd = min(batchStart + 50, 500)
          let batchLevels = manager.generateSampleLevels(count: batchEnd - batchStart)

          for (index, exportableLevel) in batchLevels.enumerated() {
            let dayOffset = batchStart + index
            guard let levelDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            let level = ShikakuLevel(
              date: levelDate,
              gridRows: exportableLevel.gridRows,
              gridCols: exportableLevel.gridCols,
              difficulty: exportableLevel.difficulty
            )

            let levelClues = exportableLevel.clues.map { clue in
              LevelClue(row: clue.row, col: clue.col, value: clue.value)
            }
            level.clues = levelClues

            modelContext.insert(level)
          }

          try? modelContext.save()
        }

        // Reset progress stats but keep prestige info
        currentProgress.totalCompletedLevels = 0
        try? modelContext.save()

        isGeneratingLevels = false
      }
    }
  }

  // MARK: - Level Generation

  private func generateAllLevels() {
    isGeneratingLevels = true

    Task {
      // Clear existing levels
      let fetchDescriptor = FetchDescriptor<ShikakuLevel>()
      if let existingLevels = try? modelContext.fetch(fetchDescriptor) {
        for level in existingLevels {
          modelContext.delete(level)
        }
      }

      // Generate 500 levels: 250 past + 250 future
      let manager = LevelBuilderManager()
      let calendar = Calendar.current
      let today = Date()

      // Start date: 250 days ago
      guard let startDate = calendar.date(byAdding: .day, value: -250, to: today) else { return }

      await MainActor.run {
        // Generate levels in batches to avoid blocking UI
        for batchStart in stride(from: 0, to: 500, by: 50) {
          let batchEnd = min(batchStart + 50, 500)
          let batchLevels = manager.generateSampleLevels(count: batchEnd - batchStart)

          for (index, exportableLevel) in batchLevels.enumerated() {
            let dayOffset = batchStart + index
            guard let levelDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            let level = ShikakuLevel(
              date: levelDate,
              gridRows: exportableLevel.gridRows,
              gridCols: exportableLevel.gridCols,
              difficulty: exportableLevel.difficulty
            )

            let levelClues = exportableLevel.clues.map { clue in
              LevelClue(row: clue.row, col: clue.col, value: clue.value)
            }
            level.clues = levelClues

            modelContext.insert(level)
          }

          try? modelContext.save()
        }

        isGeneratingLevels = false
      }
    }
  }

  // MARK: - Helper Functions

  private func initializeProgressIfNeeded() {
    if progress.isEmpty {
      let newProgress = GameProgress()
      modelContext.insert(newProgress)
      do {
        try modelContext.save()
      } catch {
        print("Failed to initialize progress: \(error)")
      }
    }
  }
}

// MARK: - Supporting Views

struct StatMini: View {
  let value: Int
  let label: String

  var body: some View {
    VStack(spacing: 4) {
      Text("\(value)")
        .font(.headline)
        .fontWeight(.medium)
        .monospacedDigit()

      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
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

    // Remove existing level for this date
    let fetchDescriptor = FetchDescriptor<ShikakuLevel>()
    if let existingLevels = try? modelContext.fetch(fetchDescriptor) {
      for existingLevel in existingLevels {
        if Calendar.current.isDate(existingLevel.date, inSameDayAs: selectedDate) {
          modelContext.delete(existingLevel)
        }
      }
    }

    modelContext.insert(level)
    do {
      try modelContext.save()
    } catch {
      print("Failed to save level: \(error)")
    }
  }
}
