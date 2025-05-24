//
//  ShikakuModels.swift
//  shikaku
//
//  SwiftData models for Shikaku levels and progress tracking
//

import SwiftData
import SwiftUI
import Foundation

@Model
final class ShikakuLevel {
    var id: UUID
    var date: Date
    var gridRows: Int
    var gridCols: Int
    @Relationship(deleteRule: .cascade) var clues: [LevelClue]
    var isCompleted: Bool
    var completionTime: TimeInterval?
    var createdAt: Date
    var difficulty: Int // 1-5 scale

    init(date: Date, gridRows: Int, gridCols: Int, clues: [LevelClue] = [], difficulty: Int = 3) {
        self.id = UUID()
        self.date = date
        self.gridRows = gridRows
        self.gridCols = gridCols
        self.clues = clues
        self.isCompleted = false
        self.completionTime = nil
        self.createdAt = Date()
        self.difficulty = difficulty
    }

    // Convert from NumberClue array
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
