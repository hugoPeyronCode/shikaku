//
//  ShikakuCalendarView.swift
//  shikaku
//
//  Enhanced calendar view with ViewModel
//

import SwiftUI
import SwiftData

struct ShikakuCalendarView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \ShikakuLevel.date, order: .reverse) private var levels: [ShikakuLevel]
  @Query private var progress: [GameProgress]
  
  @State private var viewModel = ShikakuCalendarViewModel()
  
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
      .sheet(isPresented: $viewModel.showLevelBuilder, content: {
        LevelBuilderView()
      })
      .sheet(isPresented: $viewModel.showingLevelEditor) {
        LevelEditorSheet(selectedDate: viewModel.selectedDate)
          .environment(\.modelContext, modelContext)
      }
      .fullScreenCover(isPresented: $viewModel.showingGameView) {
        ZStack {
          // Game content
          ShikakuGameView(game: viewModel.game)
            .onAppear {
              viewModel.loadSelectedLevel()
            }
            .onChange(of: viewModel.game.isGameComplete) { _, isComplete in
              if isComplete && viewModel.selectedLevel?.isCompleted == false {
                markLevelCompleted()
              }
            }
          
          // Close button overlay
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
      
      
      Button {
        viewModel.showLevelBuilder = true
      } label : {
        Text("Builder")
        
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
  
  // MARK: - Stats
  
  private var statsView: some View {
    HStack(spacing: 40) {
      StatItem(
        value: currentProgress.totalCompletedLevels,
        label: "Completed\ndays"
      )
      
      StatItem(
        value: viewModel.calculateMaxPossibleStreak(levels: levels),
        label: "Max possible\nstreak"
      )
      
      StatItem(
        value: currentProgress.maxStreak,
        label: "Best\nstreak"
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
        viewModel.navigateMonth(direction: -1)
      } label: {
        Image(systemName: "chevron.left")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.currentMonth)
      
      Spacer()
      
      Text(viewModel.monthTitle)
        .font(.title2)
        .fontWeight(.medium)
      
      Spacer()
      
      Button {
        viewModel.navigateMonth(direction: 1)
      } label: {
        Image(systemName: "chevron.right")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.currentMonth)
    }
  }
  
  private var calendarGrid: some View {
    let days = viewModel.generateCalendarDays()
    let strategicDays = viewModel.calculateStrategicDays(levels: levels)
    
    return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
      ForEach(Array(days.enumerated()), id: \.offset) { index, day in
        EnhancedCalendarDayView(
          day: day,
          isSelected: Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate),
          level: viewModel.levelForDate(day.date, levels: levels),
          isStrategic: strategicDays.contains { Calendar.current.isDate($0, inSameDayAs: day.date) },
          colorScheme: colorScheme,
          viewModel: viewModel,
          levels: levels
        ) {
          viewModel.selectDate(day.date)
        }
      }
    }
  }
  
  // MARK: - Daily Shikaku Section
  
  private var dailyShikakuSection: some View {
    VStack(spacing: 20) {
      HStack {
        Text(viewModel.selectedDateTitle)
          .font(.title2)
          .fontWeight(.medium)
        
        Spacer()
        
        // Indicateur stratégique avec priorité
        if viewModel.calculateStrategicDays(levels: levels).contains(where: { Calendar.current.isDate($0, inSameDayAs: viewModel.selectedDate) }) {
          let priority = viewModel.calculateStrategicPriority(for: viewModel.selectedDate, levels: levels)
          
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
  
  // MARK: - Helper Functions
  
  private func markLevelCompleted() {
    guard let level = viewModel.selectedLevel else { return }
    
    level.isCompleted = true
    level.completionTime = Date().timeIntervalSinceReferenceDate
    
    // Update progress with new streak logic
    let fetchDescriptor = FetchDescriptor<GameProgress>()
    if let progressArray = try? modelContext.fetch(fetchDescriptor),
       let progress = progressArray.first {
      progress.totalCompletedLevels += 1
      
      // Recalculer la streak maximale actuelle
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

// MARK: - Enhanced Calendar Day View

struct EnhancedCalendarDayView: View {
  let day: CalendarDay
  let isSelected: Bool
  let level: ShikakuLevel?
  let isStrategic: Bool
  let colorScheme: ColorScheme
  let viewModel: ShikakuCalendarViewModel
  let levels: [ShikakuLevel]
  let onTap: () -> Void
  
  private var isToday: Bool {
    Calendar.current.isDateInToday(day.date)
  }
  
  private var dayState: DayState {
    if !day.isCurrentMonth { return .inactive }
    if isToday { return .today } // Priorité maximale pour aujourd'hui
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
      VStack(spacing: 4) {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(backgroundColor)
            .frame(width: 44, height: 44)
            .overlay(
              // Progress ring pour les niveaux en cours
              progressRing
            )
            .overlay(
              // Indicateur stratégique
              strategicIndicator
            )
            .overlay(
              // Indicateur de sélection avec stroke animé
              selectionHighlight
            )
          
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
    .buttonStyle(.plain)
    .disabled(!day.isCurrentMonth)
    .sensoryFeedback(.impact(weight: .light), trigger: isSelected)
  }
  
  private var backgroundColor: Color {
    switch dayState {
    case .inactive, .noLevel:
      return Color.clear
    case .hasLevel:
      return Color.secondary.opacity(0.1)
    case .completed:
      return Color.primary
    case .today:
      return Color.red.opacity(0.6)  // Couleur rouge fixe pour aujourd'hui
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
    // Correction pour le checkmark en dark mode
    colorScheme == .dark ? .black : .white
  }
  
  private var progressRing: some View {
    Group {
      if let level = level, !level.isCompleted {
        // Ring de progression basé sur le temps passé ou rectangles placés
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
  
  private func calculateLevelProgress(_ level: ShikakuLevel) -> Double {
    // Simuler une progression basée sur la difficulté et le temps depuis création
    let daysSinceCreation = Calendar.current.dateComponents([.day], from: level.createdAt, to: Date()).day ?? 0
    let baseProgress = min(Double(daysSinceCreation) * 0.1, 0.8) // Max 80% par le temps
    
    // Ajouter de la randomness basée sur l'ID pour simuler une vraie progression
    let progressSeed = Double(level.id.hashValue % 100) / 100.0 * 0.6
    
    return min(baseProgress + progressSeed, 0.9) // Max 90%, jamais 100% sauf si complété
  }
  
  private var strategicIndicator: some View {
    Group {
      if isStrategic && dayState != .completed {
        VStack {
          HStack {
            Image(systemName: "star.fill")
              .font(.system(size: 8))
              .foregroundStyle(.orange)
              .shadow(color: .orange.opacity(0.3), radius: 2)
            Spacer()
          }
          Spacer()
        }
        .frame(width: 44, height: 44)
      }
    }
  }
  
  private var selectionHighlight: some View {
    Group {
      if isSelected {
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
    return day.isCurrentMonth ? formatter.string(from: day.date) : ""
  }
}

// MARK: - Supporting Views

struct DailyShikakuCard: View {
  let level: ShikakuLevel
  let onPlay: () -> Void
  
  private var gameStatus: GameStatus {
    if level.isCompleted {
      return .completed
    } else {
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
