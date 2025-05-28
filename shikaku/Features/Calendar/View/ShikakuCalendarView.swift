//
//  ShikakuCalendarView.swift - Updated for JSON-based levels
//  shikaku
//

import SwiftUI
import SwiftData

struct ShikakuCalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    // Only query completed levels from SwiftData for progress tracking
    @Query(
        filter: #Predicate<ShikakuLevel> { $0.isCompleted == true },
        sort: \ShikakuLevel.date
    ) private var completedLevels: [ShikakuLevel]

    @Query private var progress: [GameProgress]

    @State private var coordinator = AppCoordinator()
    @State private var viewModel = ShikakuCalendarViewModel()
    @State private var isHorizontalMode = true

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

                        // Simplified stats section
                        statsSection
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
            print("📱 CalendarView appeared")
            initializeProgressIfNeeded()
            if Calendar.current.dateComponents([.day], from: viewModel.selectedDate, to: Date()).day != 0 {
                viewModel.focusOnToday()
            }

            // Test level loading
            let testLevel = viewModel.getLevelForDate(Date())
            print("🧪 Test level for today: \(testLevel?.levelDataId ?? "nil")")
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
                            level: viewModel.getLevelForDate(day.date, completedLevels: completedLevels),
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
                        level: viewModel.getLevelForDate(day.date, completedLevels: completedLevels),
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

    // MARK: - Month Header

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
                    level: viewModel.getLevelForDate(viewModel.selectedDate, completedLevels: completedLevels),
                    date: viewModel.selectedDate,
                    progress: currentProgress
                ) {
                    if let level = viewModel.getLevelForDate(viewModel.selectedDate, completedLevels: completedLevels) {
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
                    // Pass empty array since practice mode will generate its own levels
                    coordinator.push(.practiceMode([]))
                }
            }
        }
    }

    // MARK: - Simplified Stats Section

    private var statsSection: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress Overview")
                        .font(.headline)
                        .fontWeight(.medium)

                    Text("Daily challenges • \(currentProgress.totalCompletedLevels) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
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
                    value: viewModel.calculateMaxPossibleStreak(levels: completedLevels),
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

            // Current streak info
            HStack(spacing: 0) {
                StatMini(value: currentProgress.currentStreak, label: "Current Streak")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }

    // MARK: - Navigation Content

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

        // Find or create a SwiftData record for this completion
        let calendar = Calendar.current
        let sessionLevelId = session.level.levelDataId
        let sessionDate = session.level.date

        // Use a simpler approach to find existing level
        let fetchDescriptor = FetchDescriptor<ShikakuLevel>()
        var completedLevel: ShikakuLevel?

        if let existingLevels = try? modelContext.fetch(fetchDescriptor) {
            completedLevel = existingLevels.first { level in
                level.levelDataId == sessionLevelId &&
                calendar.isDate(level.date, inSameDayAs: sessionDate)
            }
        }

        if completedLevel == nil {
            // Create new SwiftData record for this completion
            completedLevel = ShikakuLevel(
                date: session.level.date,
                gridRows: session.level.gridRows,
                gridCols: session.level.gridCols,
                difficulty: session.level.difficulty,
                levelDataId: session.level.levelDataId
            )
            completedLevel?.clues = session.level.clues
            if let level = completedLevel {
                modelContext.insert(level)
            }
        }

        // Mark as completed
        completedLevel?.isCompleted = true
        completedLevel?.completionTime = Date().timeIntervalSinceReferenceDate

        // Update progress stats
        let progressFetchDescriptor = FetchDescriptor<GameProgress>()
        if let progressArray = try? modelContext.fetch(progressFetchDescriptor),
           let progress = progressArray.first {
            progress.totalCompletedLevels += 1
            let newMaxStreak = viewModel.calculateCurrentMaxStreak(levels: completedLevels)
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
        viewModel.calculateStrategicDays(levels: completedLevels)
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
            return viewModel.calculateStrategicPriority(for: viewModel.selectedDate, levels: completedLevels)
        }
        return nil
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
