//
//  ShikakuCalendarView.swift
//  shikaku
//
//  Fixed calendar view with direct game integration
//

import SwiftUI
import SwiftData

struct ShikakuCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShikakuLevel.date, order: .reverse) private var levels: [ShikakuLevel]
    @Query private var progress: [GameProgress]

    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingLevelEditor = false
    @State private var showingGameView = false
    @State private var selectedLevel: ShikakuLevel?
    @State private var game = ShikakuGame()

    private var calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 32) {
                        statsView
                        calendarView
                        dailyShikakuSection
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .sheet(isPresented: $showingLevelEditor) {
                LevelEditorSheet(selectedDate: selectedDate)
                    .environment(\.modelContext, modelContext)
            }
            .fullScreenCover(isPresented: $showingGameView) {
                ZStack {
                    // Game content
                    ShikakuGameView(game: game)
                        .onAppear {
                            loadSelectedLevel()
                        }
                        .onChange(of: game.isGameComplete) { _, isComplete in
                            if isComplete && selectedLevel?.isCompleted == false {
                                markLevelCompleted()
                            }
                        }

                    // Close button overlay
                    VStack {
                        HStack {
                            Spacer()

                            Button {
                                showingGameView = false
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
            Image(systemName: "puzzle.piece.extension.fill")
                .font(.title2)
                .foregroundStyle(.primary)

            Text("Shikaku")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            Button {
                showingLevelEditor = true
            } label: {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: showingLevelEditor)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Stats

    private var statsView: some View {
        HStack(spacing: 40) {
            StatItem(
                value: currentProgress.totalCompletedLevels,
                label: "Completed\ndays"
            )

            StatItem(
                value: currentProgress.currentStreak,
                label: "Current\nstreak"
            )

            StatItem(
                value: currentProgress.maxStreak,
                label: "Max\nstreak"
            )
        }
    }

    private var currentProgress: GameProgress {
        progress.first ?? GameProgress()
    }

    // MARK: - Calendar

    private var calendarView: some View {
        VStack(spacing: 24) {
            monthHeader
            calendarGrid
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: currentMonth)

            Spacer()

            Text(monthTitle)
                .font(.title2)
                .fontWeight(.medium)

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: currentMonth)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentMonth)
    }

    private var calendarGrid: some View {
        let days = generateCalendarDays()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(days, id: \.date) { day in
                CalendarDayView(
                    day: day,
                    isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate),
                    level: levelForDate(day.date)
                ) {
                    withAnimation(.spring(duration: 0.2)) {
                        selectedDate = day.date
                    }
                }
            }
        }
    }

    // MARK: - Daily Shikaku Section

    private var dailyShikakuSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text(selectedDateTitle)
                    .font(.title2)
                    .fontWeight(.medium)

                Spacer()
            }

            if let level = levelForDate(selectedDate) {
                DailyShikakuCard(level: level) {
                    selectedLevel = level
                    showingGameView = true
                }
            } else {
                NoDailyShikakuCard(date: selectedDate) {
                    showingLevelEditor = true
                }
            }
        }
    }

    private var selectedDateTitle: String {
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

    // MARK: - Game Loading Functions

    private func loadSelectedLevel() {
        guard let level = selectedLevel else { return }

        // Configure game with level data
        game.gridSize = (level.gridRows, level.gridCols)
        game.numberClues = level.toNumberClues()
        game.rectangles = []
        game.validateGame()
    }

    private func markLevelCompleted() {
        guard let level = selectedLevel else { return }

        level.isCompleted = true
        level.completionTime = Date().timeIntervalSinceReferenceDate

        // Update progress
        let fetchDescriptor = FetchDescriptor<GameProgress>()
        if let progressArray = try? modelContext.fetch(fetchDescriptor),
           let progress = progressArray.first {
            progress.totalCompletedLevels += 1

            // Update streak
            if let lastPlayed = progress.lastPlayedDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: lastPlayed, to: Date()).day ?? 0
                if daysBetween == 1 {
                    progress.currentStreak += 1
                    progress.maxStreak = max(progress.maxStreak, progress.currentStreak)
                } else if daysBetween > 1 {
                    progress.currentStreak = 1
                }
            } else {
                progress.currentStreak = 1
                progress.maxStreak = 1
            }

            progress.lastPlayedDate = Date()
        }

        try? modelContext.save()
    }

    // MARK: - Helper Methods

    private func generateCalendarDays() -> [CalendarDay] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30

        var days: [CalendarDay] = []

        // Add empty days for the start of the week
        for _ in 1..<firstWeekday {
            days.append(CalendarDay(date: Date.distantPast, dayNumber: 0, isCurrentMonth: false))
        }

        // Add days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date, dayNumber: day, isCurrentMonth: true))
            }
        }

        return days
    }

    private func levelForDate(_ date: Date) -> ShikakuLevel? {
        return levels.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func initializeProgressIfNeeded() {
        if progress.isEmpty {
            let newProgress = GameProgress()
            modelContext.insert(newProgress)
            try? modelContext.save()
        }
    }
}

// MARK: - Daily Shikaku Cards

struct DailyShikakuCard: View {
    let level: ShikakuLevel
    let onPlay: () -> Void

    private var gameStatus: GameStatus {
        if level.isCompleted {
            return .completed
        } else {
            // Check if there's any progress (in a real app, you'd store partial progress)
            return .new
        }
    }

    enum GameStatus {
        case new, inProgress, completed

        var title: String {
            switch self {
            case .new: return "Start Today's Puzzle"
            case .inProgress: return "Continue Puzzle"
            case .completed: return "Completed!"
            }
        }

        var subtitle: String {
            switch self {
            case .new: return "New puzzle available"
            case .inProgress: return "Pick up where you left off"
            case .completed: return "Play again or review solution"
            }
        }

        var icon: String {
            switch self {
            case .new: return "play.circle.fill"
            case .inProgress: return "clock.circle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .new: return .primary
            case .inProgress: return .orange
            case .completed: return .green
            }
        }
    }

    var body: some View {
        Button(action: onPlay) {
            VStack(spacing: 0) {
                // Mini grid preview
                miniGridPreview
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                Spacer()

                // Status section
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

                    // Difficulty indicator
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
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                )
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
        let maxDisplaySize = 8 // Limit display to 8x8 for preview
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

// MARK: - Supporting Views

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

struct CalendarDay {
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
}

struct CalendarDayView: View {
    let day: CalendarDay
    let isSelected: Bool
    let level: ShikakuLevel?
    let onTap: () -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    private var dayState: DayState {
        if !day.isCurrentMonth { return .inactive }
        if level == nil { return .noLevel }
        if level?.isCompleted == true { return .completed }
        if isToday { return .today }
        return .hasLevel
    }

    enum DayState {
        case inactive, noLevel, hasLevel, completed, today
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .frame(width: 44, height: 44)

                    if dayState == .completed {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    } else if day.isCurrentMonth {
                        Text("\(day.dayNumber)")
                            .font(.system(size: 16, weight: .medium))
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
        .buttonStyle(.plain)
        .disabled(!day.isCurrentMonth)
        .sensoryFeedback(.impact(weight: .light), trigger: isSelected)
    }

    private var backgroundColor: Color {
        switch dayState {
        case .inactive, .noLevel:
            return Color.clear
        case .hasLevel:
            return isSelected ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.1)
        case .completed:
            return Color.primary
        case .today:
            return isSelected ? Color.primary.opacity(0.8) : Color.primary.opacity(0.6)
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
            return .white
        case .today:
            return .white
        }
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return day.isCurrentMonth ? formatter.string(from: day.date) : ""
    }
}

// MARK: - Sheet Views

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

        // Set difficulty based on editor estimation
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
        try? modelContext.save()
    }
}

#Preview {
    ShikakuCalendarView()
        .modelContainer(for: [ShikakuLevel.self, GameProgress.self, LevelClue.self])
}
