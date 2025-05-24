//
//  ShikakuGameView.swift
//  shikaku
//
//  Created by Hugo Peyron on 24/05/2025.
//


import SwiftUI

struct ShikakuGameView: View {
  @State private var game = ShikakuGame()
  @State private var dragStart: GridPosition?
  @State private var dragEnd: GridPosition?
  @State private var isDragging = false
  @State private var gameWon = false
  @State private var currentSelectionSize = 0
  @State private var previewValidation: (isValid: Bool, color: Color) = (false, .gray)
  @State private var showClearConfirmation = false

  let cellSize: CGFloat = 60

  var body: some View {
    ZStack {
      VStack(spacing: 20) {
        headerView

        Spacer()

        gameGridSection
          .containerRelativeFrame([.horizontal, .vertical]) { length, axis in
            axis == .vertical ? length * 0.6 : length * 0.9
          }

        Spacer()

        bottomSection
      }
      .background(Color(.systemBackground))
      .blur(radius: showClearConfirmation ? 2 : 0)
      .animation(.easeInOut(duration: 0.2), value: showClearConfirmation)

      // Clear confirmation modal
      if showClearConfirmation {
        ClearConfirmationModal(
          onConfirm: {
            game.clearBoard()
            gameWon = false
            currentSelectionSize = 0
            showClearConfirmation = false
          },
          onCancel: {
            showClearConfirmation = false
          }
        )
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(duration: 0.3), value: showClearConfirmation)
      }
    }
  }

  // MARK: - Sous-vues décomposées

  private var headerView: some View {
    HStack {
      Button(action: {}) {
        Image(systemName: "chevron.left")
          .font(.title2)
          .foregroundColor(.primary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: UUID())

      Text("Shikaku")
        .font(.largeTitle)
        .fontWeight(.bold)

      Spacer()

      Button(action: {}) {
        Image(systemName: "questionmark.circle")
          .font(.title2)
          .foregroundColor(.secondary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: UUID())

      Button(action: {}) {
        Image(systemName: "gearshape")
          .font(.title2)
          .foregroundColor(.secondary)
      }
      .sensoryFeedback(.impact(weight: .light), trigger: UUID())
    }
    .padding(.horizontal)
  }

  private var gameGridSection: some View {
    VStack {
      gameGrid
        .onChange(of: game.isGameComplete) { oldValue, newValue in
          if newValue && !oldValue {
            gameWon.toggle()
            game.triggerWinHaptic()
          }
        }
    }
  }

  private var bottomSection: some View {
    VStack(spacing: 20) {
      if game.isGameComplete {
        completionText
      }

      clearButton
    }
  }

  private var completionText: some View {
    Text("🎉 Puzzle résolu !")
      .font(.title2)
      .foregroundColor(.green)
      .fontWeight(.semibold)
  }

  private var clearButton: some View {
    Button {
      showClearConfirmation = true
    } label: {
      Text("Clear board")
        .font(.headline)
        .foregroundColor(.secondary)
        .padding(.vertical, 12)
        .padding(.horizontal, 30)
        .background(
          RoundedRectangle(cornerRadius: 25)
            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
        )
    }
    .padding(.bottom, 30)
    .sensoryFeedback(.impact(weight: .light), trigger: showClearConfirmation)
  }

  private var gameGrid: some View {
    ZStack {
      gridBase
      gridOverlay
    }
    .background(.ultraThinMaterial)
    .gesture(dragGesture)
  }

  private var gridBase: some View {
    VStack(spacing: 0) {
      ForEach(0..<game.gridSize.rows, id: \.self) { row in
        HStack(spacing: 0) {
          ForEach(0..<game.gridSize.cols, id: \.self) { col in
            baseCellView(row: row, col: col)
          }
        }
      }
    }
  }

  private var gridOverlay: some View {
    VStack(spacing: 0) {
      ForEach(0..<game.gridSize.rows, id: \.self) { row in
        HStack(spacing: 0) {
          ForEach(0..<game.gridSize.cols, id: \.self) { col in
            overlayCellView(row: row, col: col)
          }
        }
      }
    }
  }

  private var dragGesture: some Gesture {
    DragGesture(coordinateSpace: .local)
      .onChanged { value in
        handleDrag(location: value.location, isStart: !isDragging)
        isDragging = true
      }
      .onEnded { _ in
        handleDragEnd()
      }
  }

  func baseCellView(row: Int, col: Int) -> some View {
    let position = GridPosition(row: row, col: col)
    let numberClue = game.numberClues.first { $0.position == position }
    let containingRect = game.rectangles.first { $0.contains(position: position) }

    let borderColor: HierarchicalShapeStyle = .primary
    let borderWidth: CGFloat = 1
    let borderOpacity: CGFloat = 0.2

    return ZStack {
      Rectangle()
        .fill(.thinMaterial)
        .frame(width: cellSize, height: cellSize)

      // Custom border logic - only draw borders at rectangle edges
      if let rect = containingRect, rect.isValid {
        // Draw colored borders only on the edges of the rectangle
        VStack(spacing: 0) {
          // Top border
          if position.row == rect.topLeft.row {
            Rectangle()
              .fill(borderColor)
              .frame(height: 2)
          }

          Spacer()

          // Bottom border
          if position.row == rect.bottomRight.row {
            Rectangle()
              .fill(borderColor)
              .frame(height: 2)
          }
        }
        .frame(width: cellSize, height: cellSize)

        HStack(spacing: 0) {
          // Left border
          if position.col == rect.topLeft.col {
            Rectangle()
              .fill(borderColor)
              .frame(width: 2)
          }

          Spacer()

          // Right border
          if position.col == rect.bottomRight.col {
            Rectangle()
              .fill(borderColor)
              .frame(width: 2)
          }
        }
        .frame(width: cellSize, height: cellSize)
      } else {
        // Default thin gray border for empty cells
        Rectangle()
          .stroke(.gray.opacity(1), lineWidth: 0.3)
          .frame(width: cellSize, height: cellSize)
      }

      if let clue = numberClue {
        Text("\(clue.value)")
          .font(.system(size: 26, weight: .bold))
          .foregroundColor(.primary)
      }

    }
    .onTapGesture {
      game.removeRectangle(at: position)
    }
    .sensoryFeedback(.impact(weight: .light), trigger: game.rectangles.count)
  }

  func overlayCellView(row: Int, col: Int) -> some View {
    let position = GridPosition(row: row, col: col)
    let isInPreviewRect = isPositionInPreviewRectangle(position)
    let containingRect = game.rectangles.first { $0.contains(position: position) }

    return Rectangle()
      .fill(overlayColor(position: position,
                         isInPreview: isInPreviewRect,
                         containingRect: containingRect))
      .frame(width: cellSize, height: cellSize)
      .allowsHitTesting(false)
  }

  func overlayColor(position: GridPosition, isInPreview: Bool, containingRect: GameRectangle?) -> Color {
    if isInPreview {
      // Use the validated preview color instead of always blue
      return previewValidation.color.opacity(previewValidation.isValid ? 0.7 : 0.3)
    } else if let rect = containingRect {
      if rect.isValid {
        return rect.color.opacity(0.8)
      } else {
        return Color.secondary.opacity(0.6)
      }
    } else {
      return Color.clear
    }
  }

  func handleDrag(location: CGPoint, isStart: Bool) {
    let row = Int(location.y / (cellSize + 1))
    let col = Int(location.x / (cellSize + 1))

    guard row >= 0 && row < game.gridSize.rows && col >= 0 && col < game.gridSize.cols else { return }

    let position = GridPosition(row: row, col: col)

    if isStart {
      dragStart = position
      currentSelectionSize = 1
    }
    dragEnd = position

    if let start = dragStart {
      let newSize = abs(row - start.row + 1) * abs(col - start.col + 1)
      if newSize != currentSelectionSize {
        currentSelectionSize = newSize
        game.triggerSelectionHaptic()
      }

      // NEW: Validate preview rectangle in real-time
      previewValidation = game.validatePreviewRectangle(from: start, to: position)
    }
  }

  func handleDragEnd() {
    guard let start = dragStart, let end = dragEnd else { return }

    game.addOrUpdateRectangle(from: start, to: end)

    dragStart = nil
    dragEnd = nil
    isDragging = false
    currentSelectionSize = 0
    previewValidation = (false, .gray) // Reset preview validation
  }

  func isPositionInPreviewRectangle(_ position: GridPosition) -> Bool {
    guard let start = dragStart, let end = dragEnd else { return false }

    let topLeft = GridPosition(
      row: min(start.row, end.row),
      col: min(start.col, end.col)
    )
    let bottomRight = GridPosition(
      row: max(start.row, end.row),
      col: max(start.col, end.col)
    )

    return position.row >= topLeft.row && position.row <= bottomRight.row &&
    position.col >= topLeft.col && position.col <= bottomRight.col
  }
}