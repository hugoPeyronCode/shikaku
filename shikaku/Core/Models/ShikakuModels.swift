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
    private var baseLevels: [LevelData] = []
    private let calendar = Calendar.current

    // Reference date for the 10-level cycle (day 5 = today)
    private let referenceDate: Date

    init() {
        // Set reference date to today
        self.referenceDate = Date()
        loadLevelsFromJSON()
    }

    private func loadLevelsFromJSON() {
        // First try to load from bundle
        if let url = Bundle.main.url(forResource: "levels", withExtension: "json"),
           let data = try? Data(contentsOf: url) {

            print("✅ Found levels.json, size: \(data.count) bytes")

            do {
                let container = try JSONDecoder().decode(LevelsContainer.self, from: data)
                self.baseLevels = container.levels
                print("✅ Successfully loaded \(baseLevels.count) levels from JSON file")
                return
            } catch {
                print("❌ ERROR: Failed to decode levels.json: \(error)")
            }
        }

        // Fallback: Load from embedded data
        print("⚠️ JSON file not found, using embedded levels")
        loadEmbeddedLevels()
    }

    private func loadEmbeddedLevels() {
        // Embedded JSON as fallback
        let embeddedJSON = """
        {
          "levels": [
            {
              "id": "level_00",
              "gridRows": 5,
              "gridCols": 5,
              "difficulty": 2,
              "clues": [
                { "row": 0, "col": 1, "value": 3 },
                { "row": 1, "col": 3, "value": 4 },
                { "row": 2, "col": 0, "value": 2 },
                { "row": 3, "col": 2, "value": 6 },
                { "row": 4, "col": 4, "value": 2 }
              ]
            },
            {
              "id": "level_01",
              "gridRows": 6,
              "gridCols": 6,
              "difficulty": 3,
              "clues": [
                { "row": 0, "col": 2, "value": 4 },
                { "row": 1, "col": 0, "value": 3 },
                { "row": 2, "col": 4, "value": 6 },
                { "row": 3, "col": 1, "value": 2 },
                { "row": 4, "col": 3, "value": 8 },
                { "row": 5, "col": 5, "value": 2 }
              ]
            },
            {
              "id": "level_02",
              "gridRows": 5,
              "gridCols": 6,
              "difficulty": 2,
              "clues": [
                { "row": 0, "col": 0, "value": 6 },
                { "row": 1, "col": 2, "value": 3 },
                { "row": 2, "col": 4, "value": 4 },
                { "row": 3, "col": 1, "value": 5 },
                { "row": 4, "col": 5, "value": 3 }
              ]
            },
            {
              "id": "level_03",
              "gridRows": 7,
              "gridCols": 5,
              "difficulty": 4,
              "clues": [
                { "row": 0, "col": 3, "value": 4 },
                { "row": 1, "col": 1, "value": 6 },
                { "row": 2, "col": 4, "value": 3 },
                { "row": 3, "col": 0, "value": 8 },
                { "row": 4, "col": 2, "value": 2 },
                { "row": 5, "col": 4, "value": 5 },
                { "row": 6, "col": 1, "value": 4 }
              ]
            },
            {
              "id": "level_04",
              "gridRows": 6,
              "gridCols": 5,
              "difficulty": 3,
              "clues": [
                { "row": 0, "col": 2, "value": 5 },
                { "row": 1, "col": 4, "value": 3 },
                { "row": 2, "col": 0, "value": 4 },
                { "row": 3, "col": 3, "value": 6 },
                { "row": 4, "col": 1, "value": 2 },
                { "row": 5, "col": 4, "value": 4 }
              ]
            },
            {
              "id": "level_05",
              "gridRows": 6,
              "gridCols": 6,
              "difficulty": 4,
              "clues": [
                { "row": 0, "col": 1, "value": 4 },
                { "row": 1, "col": 3, "value": 6 },
                { "row": 2, "col": 0, "value": 3 },
                { "row": 2, "col": 5, "value": 2 },
                { "row": 3, "col": 2, "value": 8 },
                { "row": 4, "col": 4, "value": 5 },
                { "row": 5, "col": 1, "value": 3 }
              ]
            },
            {
              "id": "level_06",
              "gridRows": 5,
              "gridCols": 7,
              "difficulty": 3,
              "clues": [
                { "row": 0, "col": 3, "value": 6 },
                { "row": 1, "col": 0, "value": 4 },
                { "row": 1, "col": 6, "value": 2 },
                { "row": 2, "col": 2, "value": 5 },
                { "row": 3, "col": 4, "value": 8 },
                { "row": 4, "col": 1, "value": 3 }
              ]
            },
            {
              "id": "level_07",
              "gridRows": 7,
              "gridCols": 6,
              "difficulty": 5,
              "clues": [
                { "row": 0, "col": 2, "value": 3 },
                { "row": 1, "col": 5, "value": 4 },
                { "row": 2, "col": 0, "value": 6 },
                { "row": 3, "col": 3, "value": 9 },
                { "row": 4, "col": 1, "value": 2 },
                { "row": 5, "col": 4, "value": 7 },
                { "row": 6, "col": 2, "value": 5 }
              ]
            },
            {
              "id": "level_08",
              "gridRows": 6,
              "gridCols": 7,
              "difficulty": 4,
              "clues": [
                { "row": 0, "col": 4, "value": 5 },
                { "row": 1, "col": 1, "value": 3 },
                { "row": 2, "col": 6, "value": 4 },
                { "row": 3, "col": 0, "value": 8 },
                { "row": 4, "col": 3, "value": 6 },
                { "row": 5, "col": 5, "value": 2 }
              ]
            },
            {
              "id": "level_09",
              "gridRows": 8,
              "gridCols": 6,
              "difficulty": 5,
              "clues": [
                { "row": 0, "col": 3, "value": 4 },
                { "row": 1, "col": 0, "value": 6 },
                { "row": 2, "col": 5, "value": 3 },
                { "row": 3, "col": 2, "value": 10 },
                { "row": 4, "col": 4, "value": 2 },
                { "row": 5, "col": 1, "value": 8 },
                { "row": 6, "col": 3, "value": 5 },
                { "row": 7, "col": 0, "value": 4 }
              ]
            }
          ]
        }
        """

        guard let data = embeddedJSON.data(using: .utf8) else {
            print("❌ ERROR: Could not convert embedded JSON to data")
            return
        }

        do {
            let container = try JSONDecoder().decode(LevelsContainer.self, from: data)
            self.baseLevels = container.levels
            print("✅ Successfully loaded \(baseLevels.count) levels from embedded data")

            // Log first few levels for verification
            for (index, level) in baseLevels.prefix(3).enumerated() {
                print("Level \(index): \(level.id), grid: \(level.gridRows)x\(level.gridCols), clues: \(level.clues.count)")
            }
        } catch {
            print("❌ ERROR: Failed to decode embedded JSON: \(error)")
        }
    }

    func getLevelForDate(_ date: Date) -> ShikakuLevel? {
        guard !baseLevels.isEmpty else {
            print("❌ No levels loaded from JSON!")
            return nil
        }

        // Calculate days from reference date (today)
        let dayOffset = calendar.dateComponents([.day], from: referenceDate, to: date).day ?? 0

        // Map to 10-level cycle (levels 0-9)
        // Day -5 to -1 = levels 0-4 (past)
        // Day 0 = level 5 (today)
        // Day 1 to 4 = levels 6-9 (future)
        let adjustedOffset = dayOffset + 5 // Shift so today (0) becomes index 5
        let levelIndex = ((adjustedOffset % 10) + 10) % 10 // Handle negative numbers properly

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

    // Get levels for calendar display with completion status
    func getCalendarLevels(completedLevels: [ShikakuLevel]) -> [ShikakuLevel] {
        let startDate = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        let endDate = calendar.date(byAdding: .month, value: 1, to: referenceDate) ?? referenceDate

        var levels: [ShikakuLevel] = []
        var currentDate = startDate

        while currentDate <= endDate {
            if let level = getLevelForDate(currentDate, completedLevels: completedLevels) {
                levels.append(level)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return levels
    }
}

// MARK: - SwiftData Models (Level Templates - No completion tracking)

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

    init(date: Date, gridRows: Int, gridCols: Int, clues: [LevelClue] = [], difficulty: Int = 3, levelDataId: String = "") {
        self.id = UUID()
        self.date = date
        self.gridRows = gridRows
        self.gridCols = gridCols
        self.clues = clues
        self.isCompleted = false // Never persisted to SwiftData
        self.difficulty = difficulty
        self.levelDataId = levelDataId
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
