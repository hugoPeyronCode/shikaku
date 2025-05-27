//
//  PracticeModeView.swift
//  shikaku
//
//  Minimalist practice mode with simplified difficulty selection
//

import SwiftUI
import SwiftData

struct PracticeModeView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let levels: [ShikakuLevel]

  @State private var selectedDifficulty: Int = 0 // 0 = all difficulties
  @State private var currentPracticeLevel: ShikakuLevel?
  @State private var showingGameView = false
  @State private var practiceGame = ShikakuGame()
  @State private var completedInSession = 0
  @State private var sessionStartTime = Date()

  // Filter levels by difficulty (0 = all)
  private var availableLevels: [ShikakuLevel] {
    if selectedDifficulty == 0 {
      return levels
    }
    return levels.filter { $0.difficulty == selectedDifficulty }
  }

  // Get a random level that hasn't been completed (or any if all completed)
  private var nextRandomLevel: ShikakuLevel? {
    let uncompletedLevels = availableLevels.filter { !$0.isCompleted }

    if !uncompletedLevels.isEmpty {
      return uncompletedLevels.randomElement()
    } else {
      // If all levels completed, pick any random level
      return availableLevels.randomElement()
    }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Header
        headerSection
          .padding(.horizontal)
          .padding(.top)

        ScrollView {
          VStack(spacing: 32) {
            // Difficulty selection
            difficultySelection
              .padding(.horizontal)

            // Stats overview
            if !availableLevels.isEmpty {
              statsOverview
                .padding(.horizontal)
            }

            // Practice controls
            if availableLevels.isEmpty {
              noLevelsView
                .padding(.horizontal)
            } else {
              practiceControls
                .padding(.horizontal)
            }

            // Session stats (only show if session active)
            if completedInSession > 0 || Date().timeIntervalSince(sessionStartTime) > 60 {
              sessionStatsSection
                .padding(.horizontal)
            }

            Spacer(minLength: 100)
          }
          .padding(.vertical, 32)
        }
      }
      .background(Color(.systemBackground))
      .navigationTitle("")
      .navigationBarBackButtonHidden()
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            HStack(spacing: 6) {
              Image(systemName: "chevron.left")
                .font(.caption)
                .fontWeight(.medium)
              Text("Back")
                .font(.body)
            }
            .foregroundStyle(.primary)
          }
        }
      }
      .fullScreenCover(isPresented: $showingGameView) {
        practiceGameView
      }
      .onAppear {
        sessionStartTime = Date()
      }
    }
  }

  // MARK: - Views

  private var headerSection: some View {
    VStack(spacing: 16) {
      Text("Practice")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Random puzzles to sharpen your skills")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }

  private var difficultySelection: some View {
    VStack(spacing: 20) {
      Text("Difficulty")
        .font(.headline)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
        // All difficulties option
        DifficultyCard(
          title: "Random",
          subtitle: "All levels",
          count: levels.count,
          isSelected: selectedDifficulty == 0,
          color: .primary
        ) {
          withAnimation(.easeInOut(duration: 0.2)) {
            selectedDifficulty = 0
            currentPracticeLevel = nil
          }
        }

        // Individual difficulties
        ForEach(1...5, id: \.self) { difficulty in
          let count = levels.filter { $0.difficulty == difficulty }.count
          DifficultyCard(
            title: "Level \(difficulty)",
            subtitle: difficultyName(difficulty),
            count: count,
            isSelected: selectedDifficulty == difficulty,
            color: difficultyColor(difficulty)
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              selectedDifficulty = difficulty
              currentPracticeLevel = nil
            }
          }
        }
      }
    }
  }

  private var statsOverview: some View {
    HStack(spacing: 0) {
      StatItem(
        value: availableLevels.count,
        label: "Available"
      )

      Divider()
        .frame(height: 40)

      StatItem(
        value: availableLevels.filter { $0.isCompleted }.count,
        label: "Completed"
      )

      Divider()
        .frame(height: 40)

      StatItem(
        value: availableLevels.filter { !$0.isCompleted }.count,
        label: "Remaining"
      )
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private var practiceControls: some View {
    VStack(spacing: 16) {
      // Main practice button
      Button {
        startRandomLevel()
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "play.fill")
            .font(.title3)

          VStack(alignment: .leading, spacing: 2) {
            Text("Start Practice")
              .font(.headline)
              .fontWeight(.medium)

            Text(selectedDifficulty == 0 ? "Random difficulty" : "Difficulty \(selectedDifficulty)")
              .font(.caption)
              .opacity(0.8)
          }

          Spacer()

          Image(systemName: "arrow.right")
            .font(.caption)
            .opacity(0.6)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary, in: RoundedRectangle(cornerRadius: 16))
      }
      .sensoryFeedback(.impact(weight: .medium), trigger: showingGameView)

      // Continue button (if level in progress)
      if currentPracticeLevel != nil {
        Button {
          showingGameView = true
        } label: {
          HStack(spacing: 12) {
            Image(systemName: "arrow.clockwise")
              .font(.title3)

            Text("Continue Current")
              .font(.headline)
              .fontWeight(.medium)

            Spacer()
          }
          .foregroundStyle(.primary)
          .padding(20)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .stroke(.primary.opacity(0.3), lineWidth: 1)
          )
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showingGameView)
      }
    }
  }

  private var noLevelsView: some View {
    VStack(spacing: 20) {
      Image(systemName: "puzzlepiece")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      VStack(spacing: 8) {
        Text("No levels available")
          .font(.headline)

        Text("Generate levels in the main calendar view to start practicing")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .padding(40)
    .frame(maxWidth: .infinity)
    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
  }

  private var sessionStatsSection: some View {
    VStack(spacing: 16) {
      Text("Session")
        .font(.headline)

      HStack(spacing: 0) {
        StatItem(
          value: completedInSession,
          label: "Solved"
        )

        Divider()
          .frame(height: 40)

        StatItem(
          value: Int(Date().timeIntervalSince(sessionStartTime) / 60),
          label: "Minutes"
        )

        if completedInSession > 0 {
          Divider()
            .frame(height: 40)

          StatItem(
            value: Int(Date().timeIntervalSince(sessionStartTime) / Double(completedInSession) / 60),
            label: "Avg/Level"
          )
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 20)
      .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
  }

  private var practiceGameView: some View {
    ZStack {
      ShikakuGameView(game: practiceGame)
        .onAppear {
          loadCurrentLevel()
        }
        .onChange(of: practiceGame.isGameComplete) { _, isComplete in
          if isComplete {
            handleLevelCompleted()
          }
        }

      VStack {
        HStack {
          // Level info
          if let level = currentPracticeLevel {
            VStack(alignment: .leading, spacing: 4) {
              Text("Practice")
                .font(.caption)
                .foregroundStyle(.secondary)
              Text("Difficulty \(level.difficulty) • \(level.gridRows)×\(level.gridCols)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
          }

          Spacer()

          Button {
            showingGameView = false
          } label: {
            Image(systemName: "xmark")
              .font(.title2)
              .fontWeight(.medium)
              .foregroundStyle(.primary)
              .frame(width: 32, height: 32)
              .background(.ultraThinMaterial, in: Circle())
          }
        }
        .padding(.horizontal)
        .padding(.top, 8)

        Spacer()

        // Next level button
        if practiceGame.isGameComplete {
          Button {
            startNextLevel()
          } label: {
            HStack(spacing: 12) {
              Image(systemName: "arrow.right")
              Text("Next Level")
                .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.primary, in: Capsule())
          }
          .padding(.bottom, 40)
          .sensoryFeedback(.success, trigger: practiceGame.isGameComplete)
        }
      }
    }
  }

  // MARK: - Actions

  private func startRandomLevel() {
    guard let randomLevel = nextRandomLevel else { return }

    currentPracticeLevel = randomLevel
    practiceGame = ShikakuGame()
    showingGameView = true
  }

  private func startNextLevel() {
    guard let nextLevel = nextRandomLevel else {
      showingGameView = false
      return
    }

    currentPracticeLevel = nextLevel
    practiceGame = ShikakuGame()
    loadCurrentLevel()
  }

  private func loadCurrentLevel() {
    guard let level = currentPracticeLevel else { return }

    practiceGame.gridSize = (level.gridRows, level.gridCols)
    practiceGame.numberClues = level.toNumberClues()
    practiceGame.rectangles = []
    practiceGame.validateGame()
  }

  private func handleLevelCompleted() {
    guard let level = currentPracticeLevel else { return }

    if !level.isCompleted {
      level.isCompleted = true
      level.completionTime = Date().timeIntervalSinceReferenceDate
      try? modelContext.save()
    }

    completedInSession += 1
  }

  // MARK: - Helper Functions

  private func difficultyName(_ difficulty: Int) -> String {
    switch difficulty {
    case 1: return "Easy"
    case 2: return "Medium"
    case 3: return "Hard"
    case 4: return "Expert"
    case 5: return "Master"
    default: return ""
    }
  }

  private func difficultyColor(_ difficulty: Int) -> Color {
    switch difficulty {
    case 1: return .green
    case 2: return .yellow
    case 3: return .orange
    case 4: return .red
    case 5: return .purple
    default: return .gray
    }
  }
}

struct DifficultyCard: View {
  let title: String
  let subtitle: String
  let count: Int
  let isSelected: Bool
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(isSelected ? .white : .primary)

        Text(subtitle)
          .font(.caption)
          .foregroundStyle(isSelected ? .primary : .secondary)

        Text("\(count)")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(isSelected ? .primary : .tertiary)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(
            (isSelected ? Color.white.opacity(0.2) : Color.secondary.opacity(0.1)),
            in: Capsule()
          )
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(isSelected ? color : color.opacity(0.1))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
          )
      )
    }
    .sensoryFeedback(.selection, trigger: isSelected)
  }
}

//struct StatItem: View {
//  let value: Int
//  let label: String
//
//  var body: some View {
//    VStack(spacing: 6) {
//      Text("\(value)")
//        .font(.title2)
//        .fontWeight(.medium)
//        .monospacedDigit()
//
//      Text(label)
//        .font(.caption)
//        .foregroundStyle(.secondary)
//    }
//    .frame(maxWidth: .infinity)
//  }
//}

#Preview {
  PracticeModeView(levels: [])
    .modelContainer(for: [ShikakuLevel.self, GameProgress.self, LevelClue.self])
}
