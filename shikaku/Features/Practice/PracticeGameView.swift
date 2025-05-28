//
//  PracticeModeView.swift - Fixed for JSON-based levels
//  shikaku
//

import SwiftUI
import SwiftData

struct PracticeModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let levels: [ShikakuLevel] // This will be ignored, we'll use JSON levels
    let coordinator: AppCoordinator

    @State private var selectedDifficulty: Int = 0 // 0 = all difficulties
    @State private var completedInSession = 0
    @State private var sessionStartTime = Date()
    @State private var levelManager = LevelManager()

    // Query completed levels from SwiftData
    @Query(
        filter: #Predicate<ShikakuLevel> { $0.isCompleted == true },
        sort: \ShikakuLevel.date
    ) private var completedSwiftDataLevels: [ShikakuLevel]

    // Generate practice levels from JSON system
    private var availableLevels: [ShikakuLevel] {
        let allJsonLevels = generatePracticeLevels()

        if selectedDifficulty == 0 {
            return allJsonLevels
        }
        return allJsonLevels.filter { $0.difficulty == selectedDifficulty }
    }

    // Generate a larger set of levels for practice
    private func generatePracticeLevels() -> [ShikakuLevel] {
        var practiceLevels: [ShikakuLevel] = []
        let calendar = Calendar.current
        let today = Date()

        // Generate 50 practice levels using the JSON cycling system
        for i in -25...24 {
            if let practiceDate = calendar.date(byAdding: .day, value: i, to: today),
               let level = levelManager.getLevelForDate(practiceDate) {

                // Check if this level pattern has been completed before
                let isCompleted = completedSwiftDataLevels.contains { completedLevel in
                    completedLevel.levelDataId == level.levelDataId
                }
                level.isCompleted = isCompleted

                practiceLevels.append(level)
            }
        }

        return practiceLevels
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
        .onAppear {
            sessionStartTime = Date()
        }
        .onChange(of: coordinator.presentedFullScreen) { _, fullScreen in
            // Handle game completion when returning from full screen
            if fullScreen == nil {
                handlePotentialGameCompletion()
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
                    count: availableLevels.count,
                    isSelected: selectedDifficulty == 0,
                    color: .primary
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDifficulty = 0
                    }
                }

                // Individual difficulties
                ForEach(1...5, id: \.self) { difficulty in
                    let count = availableLevels.filter { $0.difficulty == difficulty }.count
                    DifficultyCard(
                        title: "Level \(difficulty)",
                        subtitle: difficultyName(difficulty),
                        count: count,
                        isSelected: selectedDifficulty == difficulty,
                        color: difficultyColor(difficulty)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDifficulty = difficulty
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
            .sensoryFeedback(.impact(weight: .medium), trigger: coordinator.presentedFullScreen != nil)
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

                Text("Unable to load practice levels from JSON")
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

    // MARK: - Actions

    private func startRandomLevel() {
        guard let randomLevel = nextRandomLevel else { return }

        let gameSession = GameSession(level: randomLevel, context: .practice)
        coordinator.presentFullScreen(.game(gameSession))
    }

    private func handlePotentialGameCompletion() {
        // Check if a practice game was just completed
        // This could be enhanced by having the GameSession communicate completion status
        // For now, we'll increment the session counter when returning from a game
        if coordinator.presentedFullScreen == nil {
            // Optionally increment completed count - you might want to make this more sophisticated
            // by actually checking if the game was completed rather than just closed
        }
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

struct StatItem: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.medium)
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PracticeModeView(levels: [], coordinator: AppCoordinator())
        .modelContainer(for: [ShikakuLevel.self, GameProgress.self, LevelClue.self])
}
