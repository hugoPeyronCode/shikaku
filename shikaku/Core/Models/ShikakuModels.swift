//
//  ShikakuModels.swift
//  shikaku
//
//  SwiftData models for Shikaku levels and progress tracking
//

import SwiftData
import SwiftUI
import Foundation

// MARK: - JSON Structure for Levels

struct LevelData: Codable {
    let id: String
    let gridRows: Int
    let gridCols: Int
    let clues: [ClueData]
    let difficulty: Int

    struct ClueData: Codable {
        let row: Int
        let col: Int
        let value: Int
    }
}

struct LevelsContainer: Codable {
    let levels: [LevelData]
}

// MARK: - Level Manager

@Observable
class LevelManager {
    static let shared = LevelManager()

    private var baseLevels: [LevelData] = []
    private let calendar = Calendar.current
    private var isLoaded = false

    // Reference date for the level cycle
    private let referenceDate: Date

    private init() {
        self.referenceDate = Date()
        loadLevelsFromJSON()
    }

    private func loadLevelsFromJSON() {
        // Prevent multiple loads
        guard !isLoaded else {
            print("📋 Levels already loaded, skipping...")
            return
        }

        // First try to load from bundle
        if let url = Bundle.main.url(forResource: "levels", withExtension: "json"),
           let data = try? Data(contentsOf: url) {

            print("✅ Found levels.json, size: \(data.count) bytes")

            do {
                let container = try JSONDecoder().decode(LevelsContainer.self, from: data)
                self.baseLevels = container.levels
                self.isLoaded = true // Mark as loaded
                print("✅ Successfully loaded \(baseLevels.count) levels from JSON file")
                return
            } catch {
                print("❌ ERROR: Failed to decode levels.json: \(error)")
            }
        }
        print("⚠️ JSON file not found, no embedded levels available")
        loadEmbeddedLevels()
    }

    private func loadEmbeddedLevels() {
        // Simplified - no embedded levels as requested
        print("⚠️ No embedded levels - JSON file is required")
        self.baseLevels = []
        self.isLoaded = true // Mark as loaded even if empty
    }

    func getLevelForDate(_ date: Date) -> ShikakuLevel? {
        guard !baseLevels.isEmpty else {
            print("❌ No levels loaded from JSON!")
            return nil
        }

        // Calculate days from reference date (today)
        let dayOffset = calendar.dateComponents([.day], from: referenceDate, to: date).day ?? 0
        let adjustedOffset = dayOffset + 5
        let levelIndex = ((adjustedOffset % baseLevels.count) + baseLevels.count) % baseLevels.count // Handle negative numbers properly

        print("🔍 Date: \(date), dayOffset: \(dayOffset), levelIndex: \(levelIndex)")

        let levelData = baseLevels[levelIndex]
        let level = ShikakuLevel.from(levelData: levelData, date: date)

        print("✅ Generated level: \(levelData.id) for date \(date)")
        return level
    }

    func getAllLevelsInRange(from startDate: Date, to endDate: Date) -> [ShikakuLevel] {
        var levels: [ShikakuLevel] = []
        var currentDate = startDate

        while currentDate <= endDate {
            if let level = getLevelForDate(currentDate) {
                levels.append(level)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return levels
    }

    // Get levels for calendar display (past month to future month)
    func getCalendarLevels() -> [ShikakuLevel] {
        let startDate = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        let endDate = calendar.date(byAdding: .month, value: 1, to: referenceDate) ?? referenceDate
        return getAllLevelsInRange(from: startDate, to: endDate)
    }

    // Debug method to check if levels are loaded
    func getLoadedLevelsCount() -> Int {
        return baseLevels.count
    }
}
// MARK: - SwiftData Models

@Model
final class ShikakuLevel {
    var id: UUID
    var date: Date
    var gridRows: Int
    var gridCols: Int
    @Relationship(deleteRule: .cascade) var clues: [LevelClue]
    var isCompleted: Bool // This is now just for UI display, not persistent
    var difficulty: Int
    var levelDataId: String // Reference to JSON level
    var completionTime: TimeInterval? // ADDED - This was missing

    init(date: Date, gridRows: Int, gridCols: Int, clues: [LevelClue] = [], difficulty: Int = 3, levelDataId: String = "") {
        self.id = UUID()
        self.date = date
        self.gridRows = gridRows
        self.gridCols = gridCols
        self.clues = clues
        self.isCompleted = false // Never persisted to SwiftData
        self.difficulty = difficulty
        self.levelDataId = levelDataId
        self.completionTime = nil // ADDED
    }

    // Convert from LevelData and date
    static func from(levelData: LevelData, date: Date) -> ShikakuLevel {
        let level = ShikakuLevel(
            date: date,
            gridRows: levelData.gridRows,
            gridCols: levelData.gridCols,
            difficulty: levelData.difficulty,
            levelDataId: levelData.id
        )

        let levelClues = levelData.clues.map { clue in
            LevelClue(row: clue.row, col: clue.col, value: clue.value)
        }
        level.clues = levelClues

        return level
    }

    // Convert from NumberClue array (for level editor)
    static func from(numberClues: [NumberClue], date: Date, gridSize: (rows: Int, cols: Int)) -> ShikakuLevel {
        let level = ShikakuLevel(date: date, gridRows: gridSize.rows, gridCols: gridSize.cols, difficulty: 3)

        let levelClues = numberClues.map { clue in
            LevelClue(row: clue.position.row, col: clue.position.col, value: clue.value)
        }
        level.clues = levelClues

        return level
    }

    // Convert to NumberClue array
    func toNumberClues() -> [NumberClue] {
        return clues.map { clue in
            NumberClue(position: GridPosition(row: clue.row, col: clue.col), value: clue.value)
        }
    }
}

@Model
final class LevelClue {
    var row: Int
    var col: Int
    var value: Int

    init(row: Int, col: Int, value: Int) {
        self.row = row
        self.col = col
        self.value = value
    }
}

@Model
final class GameProgress {
    var id: UUID
    var currentStreak: Int
    var maxStreak: Int
    var totalCompletedLevels: Int
    var lastPlayedDate: Date?

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.maxStreak = 0
        self.totalCompletedLevels = 0
        self.lastPlayedDate = nil
    }
}
