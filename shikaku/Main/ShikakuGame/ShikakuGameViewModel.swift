//
//  ShikakuGame.swift
//  shikaku
//
//  Created by Hugo Peyron on 24/05/2025.
//

import SwiftUI

@Observable
class ShikakuGame {
  var gridSize: (rows: Int, cols: Int) = (9, 6)
  var rectangles: [GameRectangle] = []
  var numberClues: [NumberClue] = []
  var selectedRectangle: GameRectangle?
  var isGameComplete: Bool = false

  // Panel de couleurs distinctes et contrastées
  private let colorPalette: [Color] = [
    .blue,
    .red,
    .green,
    .orange,
    .purple,
    .pink,
    .yellow,
    .brown,
    .cyan,
    .indigo,
    .mint,
    .teal
  ]
  private var colorIndex = 0

  // Haptic generators
  private let lightImpact = UIImpactFeedbackGenerator(style: .light)
  private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
  private let notificationFeedback = UINotificationFeedbackGenerator()

  init() {
    // Prepare haptics for better performance
    lightImpact.prepare()
    heavyImpact.prepare()
    notificationFeedback.prepare()

    generateScreenshotLevel()
  }

  func generateScreenshotLevel() {
    numberClues = [
      NumberClue(position: GridPosition(row: 0, col: 1), value: 8),
      NumberClue(position: GridPosition(row: 0, col: 5), value: 4),
      NumberClue(position: GridPosition(row: 2, col: 0), value: 3),
      NumberClue(position: GridPosition(row: 2, col: 2), value: 12),
      NumberClue(position: GridPosition(row: 4, col: 4), value: 3),
      NumberClue(position: GridPosition(row: 5, col: 0), value: 5),
      NumberClue(position: GridPosition(row: 5, col: 5), value: 5),
      NumberClue(position: GridPosition(row: 6, col: 2), value: 3),
      NumberClue(position: GridPosition(row: 8, col: 0), value: 3),
      NumberClue(position: GridPosition(row: 8, col: 4), value: 8)
    ]
    rectangles = []
    colorIndex = 0
    validateGame()
  }

  // NEW: Function to validate a preview rectangle during dragging
  func validatePreviewRectangle(from start: GridPosition, to end: GridPosition) -> (isValid: Bool, color: Color) {
    let topLeft = GridPosition(
      row: min(start.row, end.row),
      col: min(start.col, end.col)
    )
    let bottomRight = GridPosition(
      row: max(start.row, end.row),
      col: max(start.col, end.col)
    )

    let previewRect = GameRectangle(topLeft: topLeft, bottomRight: bottomRight)

    // Check if this rectangle would be valid
    let containedClues = numberClues.filter { clue in
      previewRect.contains(position: clue.position)
    }

    let isValid = containedClues.count == 1 && containedClues.first?.value == previewRect.area

    // Return the next color from palette if valid, gray if invalid
    let nextColor = colorPalette[colorIndex % colorPalette.count]
    return (isValid: isValid, color: isValid ? nextColor : .gray)
  }

  func addOrUpdateRectangle(from start: GridPosition, to end: GridPosition) {
    let topLeft = GridPosition(
      row: min(start.row, end.row),
      col: min(start.col, end.col)
    )
    let bottomRight = GridPosition(
      row: max(start.row, end.row),
      col: max(start.col, end.col)
    )

    let nextColor = colorPalette[colorIndex % colorPalette.count]
    colorIndex += 1

    var newRect = GameRectangle(topLeft: topLeft, bottomRight: bottomRight)
    newRect.color = nextColor

    rectangles.removeAll { rect in
      overlaps(rect1: rect, rect2: newRect)
    }

    rectangles.append(newRect)
    validateGame()

    // Trigger haptic based on validation result
    if let lastRect = rectangles.last {
      triggerValidationHaptic(isValid: lastRect.isValid)
    }
  }

  func removeRectangle(at position: GridPosition) {
    rectangles.removeAll { rect in
      rect.contains(position: position)
    }
    validateGame()
  }

  private func overlaps(rect1: GameRectangle, rect2: GameRectangle) -> Bool {
    !(rect1.bottomRight.col < rect2.topLeft.col ||
      rect2.bottomRight.col < rect1.topLeft.col ||
      rect1.bottomRight.row < rect2.topLeft.row ||
      rect2.bottomRight.row < rect1.topLeft.row)
  }

  func validateGame() {
    for i in rectangles.indices {
      rectangles[i].isValid = validateRectangle(rectangles[i])
    }

    for i in numberClues.indices {
      numberClues[i].isSatisfied = isNumberClueSatisfied(numberClues[i])
    }

    isGameComplete = numberClues.allSatisfy { $0.isSatisfied } &&
    rectangles.allSatisfy { $0.isValid } &&
    isGridFullyCovered()
  }

  private func validateRectangle(_ rectangle: GameRectangle) -> Bool {
    let containedClues = numberClues.filter { clue in
      rectangle.contains(position: clue.position)
    }
    return containedClues.count == 1 && containedClues.first?.value == rectangle.area
  }

  private func isNumberClueSatisfied(_ clue: NumberClue) -> Bool {
    let containingRectangles = rectangles.filter { rect in
      rect.contains(position: clue.position)
    }
    return containingRectangles.count == 1 &&
    containingRectangles.first?.area == clue.value
  }

  func clearBoard() {
    rectangles = []
    colorIndex = 0
    validateGame()
  }

  func triggerSelectionHaptic() {
    lightImpact.impactOccurred()
  }

  func triggerValidationHaptic(isValid: Bool) {
    notificationFeedback.notificationOccurred(isValid ? .success : .error)
  }

  func triggerWinHaptic() {
    heavyImpact.impactOccurred()
  }

  private func isGridFullyCovered() -> Bool {
    for row in 0..<gridSize.rows {
      for col in 0..<gridSize.cols {
        let position = GridPosition(row: row, col: col)
        let coveringRectangles = rectangles.filter { $0.contains(position: position) }
        if coveringRectangles.count != 1 {
          return false
        }
      }
    }
    return true
  }
}

