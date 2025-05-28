//
//  ShikakuGameView.swift
//  shikaku
//
//  Updated game view with single tile selection and responsive grid
//

import SwiftUI

struct ShikakuGameView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(AppCoordinator.self) private var coordinator

  @State private var session: GameSession
  @State private var showExitConfirmation = false

  // Visual state
  @State private var dragStart: GridPosition?
  @State private var dragEnd: GridPosition?
  @State private var isDragging = false
  @State private var gameWon = false

  init(session: GameSession) {
    self._session = State(initialValue: session)
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        backgroundGradient

        VStack(spacing: 20) {
          headerView

          Spacer()

          gameGrid(in: geometry)

          Spacer()

          controlsView

        }
        .padding()

        if session.game.isGameComplete {
          completionView
        }

      }
    }
    .navigationBarHidden(true)
    .onChange(of: session.game.isGameComplete) { _, isComplete in
      if isComplete && !session.isCompleted {
        handleGameCompletion()
      }
    }
    .confirmationDialog("Exit Game", isPresented: $showExitConfirmation) {
      Button("Exit", role: .destructive) {
        coordinator.dismissFullScreen()
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("Are you sure you want to exit? Progress will be lost.")
    }
  }

  // MARK: - Views

  private var headerView: some View {
    HStack {
      Button {
        showExitConfirmation = true
      } label: {
        Image(systemName: "xmark")
          .font(.title2)
          .foregroundStyle(.primary)
          .frame(width: 44, height: 44)
          .background(.ultraThinMaterial, in: Circle())
      }
      .sensoryFeedback(.impact(weight: .light), trigger: showExitConfirmation)

      Spacer()

      VStack(spacing: 4) {
        Text(contextTitle)
          .font(.headline)
          .fontWeight(.medium)

        Text(contextSubtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Timer or level info
      VStack(alignment: .trailing, spacing: 2) {
        Text(formattedDuration)
          .font(.caption)
          .fontWeight(.medium)
          .monospacedDigit()

        Text("Level \(session.level.difficulty)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func gameGrid(in geometry: GeometryProxy) -> some View {
    let cellSize = calculateCellSize(in: geometry)

    return VStack(spacing: 2) {
      ForEach(0..<session.game.gridSize.rows, id: \.self) { row in
        HStack(spacing: 2) {
          ForEach(0..<session.game.gridSize.cols, id: \.self) { col in
            GameCellView(
              position: GridPosition(row: row, col: col),
              game: session.game,
              cellSize: cellSize,
              dragStart: dragStart,
              dragEnd: dragEnd,
              isDragging: isDragging
            )
          }
        }
      }
    }
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .gesture(createDragGesture(cellSize: cellSize))
  }

  private var completionView: some View {
    VStack(spacing: 20) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 48))
        .foregroundStyle(Color.primary)

      Text("Solved in \(formattedDuration)")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack {

        Button {
          coordinator.dismissFullScreen()
        } label: {
          Image(systemName: "house.fill")
          Text("Home")
            .font(.caption)
        }
        .fontWeight(.semibold)
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.primary, in: RoundedRectangle(cornerRadius: 12).stroke(lineWidth: 1))

        Button {
          // play again
        } label: {
            Image(systemName: "arrow.trianglehead.counterclockwise")
            Text("replay")
              .font(.caption)
        }
        .fontWeight(.semibold)
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.primary, in: RoundedRectangle(cornerRadius: 12).stroke(lineWidth: 1))

        Button {
          // Play next game logic. In practice mode would be to select a random level according to the selection done int he practice mode.
          // In the daily game it would open the calendar view as a modal
        } label: {
          Image(systemName: "chevron.forward.dotted.chevron.forward")
            Text("play next")
              .font(.caption)
        }
        .fontWeight(.semibold)
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.primary, in: RoundedRectangle(cornerRadius: 12).stroke(lineWidth: 1))

      }
    }
    .sensoryFeedback(.success, trigger: session.game.isGameComplete)
    .padding()
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
  }

  private var controlsView: some View {
    HStack {
      Button {
        withAnimation(.spring(duration: 0.3)) {
          session.game.clearBoard()
        }
      } label: {
        Text("Clear")
          .foregroundStyle(.secondary)
          .frame(width: 80, height: 44)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
      }
      .sensoryFeedback(.impact(weight: .medium), trigger: session.game.rectangles.isEmpty)

      Spacer()

      // Hint button for practice mode
      if case .practice = session.context {
        Button {
          // TODO: Implement hint system
        } label: {
          Image(systemName: "lightbulb")
            .foregroundStyle(.secondary)
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial, in: Circle())
        }
      }
    }
  }

  // MARK: - Helper Methods

  private var contextTitle: String {
    switch session.context {
    case .daily: return "Daily Puzzle"
    case .practice: return "Practice"
    case .custom: return "Custom Level"
    }
  }

  private var contextSubtitle: String {
    "\(session.level.gridRows)×\(session.level.gridCols) • \(session.level.clues.count) clues"
  }

  private var formattedDuration: String {
    let duration = session.duration
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  private func calculateCellSize(in geometry: GeometryProxy) -> CGFloat {
    let availableWidth = geometry.size.width - 30
    let availableHeight = geometry.size.height * 0.7

    let cellWidth = availableWidth / CGFloat(session.game.gridSize.cols + 1)
    let cellHeight = availableHeight / CGFloat(session.game.gridSize.rows + 1)

    return min(cellWidth, cellHeight, 70)
  }

  // FIXED: Updated completion handling
  private func handleGameCompletion() {
    session.complete()

    // Update level completion in database
    session.level.isCompleted = true
    session.level.completionTime = session.duration // FIXED: Use session duration instead of timeIntervalSinceReferenceDate

    try? modelContext.save()

    // Trigger victory animation
    withAnimation(.spring(duration: 0.8)) {
      gameWon = true
    }
  }

  // MARK: - Gesture Handling

  private func createDragGesture(cellSize: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        handleDragChanged(value, cellSize: cellSize)
      }
      .onEnded { _ in
        handleDragEnded()
      }
  }

  private func handleDragChanged(_ value: DragGesture.Value, cellSize: CGFloat) {
    if !isDragging {
      dragStart = positionFromLocation(value.startLocation, cellSize: cellSize)
      isDragging = true
    }

    dragEnd = positionFromLocation(value.location, cellSize: cellSize)
  }

  private func handleDragEnded() {
    guard let start = dragStart, let end = dragEnd else {
      resetDragState()
      return
    }

    let validation = session.game.validatePreviewRectangle(from: start, to: end)

    if validation.isValid {
      session.game.addOrUpdateRectangle(from: start, to: end)
    }

    resetDragState()
  }

  private func positionFromLocation(_ location: CGPoint, cellSize: CGFloat) -> GridPosition? {
    let col = Int(location.x / (cellSize + 2))
    let row = Int(location.y / (cellSize + 2))

    guard row >= 0 && row < session.game.gridSize.rows &&
            col >= 0 && col < session.game.gridSize.cols else {
      return nil
    }

    return GridPosition(row: row, col: col)
  }

  private func resetDragState() {
    dragStart = nil
    dragEnd = nil
    isDragging = false
  }

  private var backgroundGradient: some View {
    LinearGradient(
      colors: [.clear, .primary.opacity(0.05)],
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
}
