//
//  ShikakuGameView.swift
//  shikaku
//
//  Updated game view with single tile selection and responsive grid
//

import SwiftUI
//
//struct ShikakuGameView: View {
//    @Environment(\.colorScheme) var colorScheme
//    @State var game: ShikakuGame
//    @State private var dragStart: GridPosition?
//    @State private var dragEnd: GridPosition?
//    @State private var isDragging = false
//    @State private var dragLocation: CGPoint = .zero
//    @State private var gameWon = false
//    @State private var currentSelectionSize = 0
//    @State private var previewValidation: (isValid: Bool, color: Color) = (false, .gray)
//    @State private var showClearConfirmation = false
//    @State private var showingCalendar = false
//
//    // Responsive grid properties
//    private let cornerRadius: CGFloat = 16
//    private let cellSpacing: CGFloat = 4
//    private let minCellSize: CGFloat = 40
//    private let maxCellSize: CGFloat = 80
//    private let gridPadding: CGFloat = 20
//
//    init(game: ShikakuGame = ShikakuGame()) {
//        self._game = State(initialValue: game)
//    }
//
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                adaptiveBackgroundColor.ignoresSafeArea()
//
//                VStack(spacing: 20) {
//                    headerView
//
//                    Spacer()
//
//                    gameGridSection(in: geometry)
//
//                    Spacer()
//
//                    bottomSection
//                }
//            }
//        }
//        .sheet(isPresented: $showingCalendar) {
//            ShikakuCalendarView()
//        }
//    }
//
//    // MARK: - Responsive Grid Calculation
//
//    private func calculateCellSize(in geometry: GeometryProxy) -> CGFloat {
//        let availableWidth = geometry.size.width - (gridPadding * 2)
//        let availableHeight = geometry.size.height * 0.6 - (gridPadding * 2)
//
//        let totalSpacingWidth = CGFloat(game.gridSize.cols - 1) * cellSpacing
//        let totalSpacingHeight = CGFloat(game.gridSize.rows - 1) * cellSpacing
//
//        let maxCellWidth = (availableWidth - totalSpacingWidth) / CGFloat(game.gridSize.cols)
//        let maxCellHeight = (availableHeight - totalSpacingHeight) / CGFloat(game.gridSize.rows)
//
//        let calculatedSize = min(maxCellWidth, maxCellHeight)
//
//        return max(minCellSize, min(maxCellSize, calculatedSize))
//    }
//
//    // MARK: - Adaptive Colors
//
//    private var adaptiveBackgroundColor: Color {
//        colorScheme == .dark ? .black : Color(.systemBackground)
//    }
//
//    private var adaptiveTextColor: Color {
//        colorScheme == .dark ? .white : .primary
//    }
//
//    private var adaptiveSecondaryTextColor: Color {
//        colorScheme == .dark ? .white.opacity(0.7) : .secondary
//    }
//
//    private var adaptiveCellBackgroundColor: Color {
//        colorScheme == .dark ?
//            Color(red: 0.25, green: 0.25, blue: 0.3) :
//            Color(.systemGray6)
//    }
//
//    private var adaptiveGlowColor: Color {
//        colorScheme == .dark ? Color.white : Color.black
//    }
//
//    private var adaptiveStripeColor: Color {
//        colorScheme == .dark ?
//            Color.white.opacity(0.15) :
//            Color.black.opacity(0.08)
//    }
//
//    // MARK: - Header
//
//    private var headerView: some View {
//        HStack {
//            Button {
//                showingCalendar = true
//            } label: {
//                Image(systemName: "calendar")
//                    .font(.title2)
//                    .foregroundColor(adaptiveSecondaryTextColor)
//            }
//            .sensoryFeedback(.impact(weight: .light), trigger: showingCalendar)
//
//            Spacer()
//
//            Text("Shikaku")
//                .font(.largeTitle)
//                .fontWeight(.bold)
//                .foregroundColor(adaptiveTextColor)
//
//            Spacer()
//
//            Button(action: {}) {
//                Image(systemName: "questionmark.circle")
//                    .font(.title2)
//                    .foregroundColor(adaptiveSecondaryTextColor)
//            }
//            .sensoryFeedback(.impact(weight: .light), trigger: false)
//
//            Button(action: {}) {
//                Image(systemName: "gearshape")
//                    .font(.title2)
//                    .foregroundColor(adaptiveSecondaryTextColor)
//            }
//            .sensoryFeedback(.impact(weight: .light), trigger: false)
//        }
//        .padding(.horizontal)
//    }
//
//    // MARK: - Game Grid Section
//
//    private func gameGridSection(in geometry: GeometryProxy) -> some View {
//        let cellSize = calculateCellSize(in: geometry)
//
//        return VStack {
//            gameGrid(cellSize: cellSize)
//                .onChange(of: game.isGameComplete) { oldValue, newValue in
//                    if newValue && !oldValue {
//                        triggerVictoryAnimation()
//                    }
//                }
//        }
//    }
//
//    private func gameGrid(cellSize: CGFloat) -> some View {
//        VStack(spacing: cellSpacing) {
//            ForEach(0..<game.gridSize.rows, id: \.self) { row in
//                HStack(spacing: cellSpacing) {
//                    ForEach(0..<game.gridSize.cols, id: \.self) { col in
//                        modernCellView(row: row, col: col, cellSize: cellSize)
//                    }
//                }
//            }
//        }
//        .background(Color.clear)
//        .gesture(dragGesture(cellSize: cellSize))
//    }
//
//    private func modernCellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
//        let position = GridPosition(row: row, col: col)
//        let numberClue = game.numberClues.first { $0.position == position }
//        let containingRect = game.rectangles.first { $0.contains(position: position) }
//        let isInPreview = isPositionInPreviewRectangle(position)
//        let isStartCell = dragStart == position && !isDragging
//
//        return ZStack {
//            // Base cell
//            RoundedRectangle(cornerRadius: cornerRadius)
//                .fill(cellBackgroundColor(containingRect: containingRect, isInPreview: isInPreview, isStartCell: isStartCell))
//                .frame(width: cellSize, height: cellSize)
//                .overlay(
//                    RoundedRectangle(cornerRadius: cornerRadius)
//                        .stroke(adaptiveGlowColor, lineWidth: gameWon ? 2 : 0)
//                        .opacity(gameWon ? 0.8 : 0)
//                        .animation(.easeInOut(duration: 0.6), value: gameWon)
//                )
//                .shadow(
//                    color: gameWon ? adaptiveGlowColor.opacity(0.4) : Color.clear,
//                    radius: gameWon ? 8 : 0
//                )
//                .animation(.easeInOut(duration: 0.6), value: gameWon)
//
//            // Preview border
//            if isInPreview && isDragging {
//                previewBorderOverlay(for: position, cellSize: cellSize)
//            }
//
//            // Invalid preview stripes
//            if isInPreview && !previewValidation.isValid && isDragging {
//                stripePattern(cellSize: cellSize)
//                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
//                    .frame(width: cellSize, height: cellSize)
//            }
//
//            // Number clue
//            if let clue = numberClue {
//                Text("\(clue.value)")
//                    .font(.system(size: min(cellSize * 0.4, 26), weight: .bold))
//                    .foregroundColor(numberClueTextColor(containingRect: containingRect, isInPreview: isInPreview, isStartCell: isStartCell))
//            }
//        }
//        .onTapGesture {
//            game.removeRectangle(at: position)
//        }
//        .sensoryFeedback(.impact(weight: .light), trigger: game.rectangles.count)
//    }
//
//    // MARK: - Cell Styling
//
//    private func cellBackgroundColor(containingRect: GameRectangle?, isInPreview: Bool, isStartCell: Bool) -> Color {
//        if isStartCell {
//            return Color(red: 0.4, green: 0.5, blue: 0.9).opacity(0.4)
//        } else if isInPreview && isDragging {
//            return adaptiveCellBackgroundColor
//        } else if let rect = containingRect, rect.isValid {
//            return rect.color.opacity(0.8)
//        } else {
//            return adaptiveCellBackgroundColor
//        }
//    }
//
//    private func numberClueTextColor(containingRect: GameRectangle?, isInPreview: Bool, isStartCell: Bool) -> Color {
//        if isStartCell || (containingRect != nil && containingRect!.isValid) {
//            return .white
//        } else {
//            return adaptiveTextColor
//        }
//    }
//
//    // MARK: - Preview Border
//
//    private func previewBorderOverlay(for position: GridPosition, cellSize: CGFloat) -> some View {
//        guard let start = dragStart, let end = dragEnd else {
//            return AnyView(EmptyView())
//        }
//
//        let topLeft = GridPosition(
//            row: min(start.row, end.row),
//            col: min(start.col, end.col)
//        )
//        let bottomRight = GridPosition(
//            row: max(start.row, end.row),
//            col: max(start.col, end.col)
//        )
//
//        let borderColor = Color(red: 0.4, green: 0.5, blue: 0.9)
//        let borderWidth: CGFloat = 3
//
//        return AnyView(
//            ZStack {
//                // Top border
//                if position.row == topLeft.row {
//                    VStack {
//                        Rectangle()
//                            .fill(borderColor)
//                            .frame(height: borderWidth)
//                        Spacer()
//                    }
//                }
//
//                // Bottom border
//                if position.row == bottomRight.row {
//                    VStack {
//                        Spacer()
//                        Rectangle()
//                            .fill(borderColor)
//                            .frame(height: borderWidth)
//                    }
//                }
//
//                // Left border
//                if position.col == topLeft.col {
//                    HStack {
//                        Rectangle()
//                            .fill(borderColor)
//                            .frame(width: borderWidth)
//                        Spacer()
//                    }
//                }
//
//                // Right border
//                if position.col == bottomRight.col {
//                    HStack {
//                        Spacer()
//                        Rectangle()
//                            .fill(borderColor)
//                            .frame(width: borderWidth)
//                    }
//                }
//            }
//            .frame(width: cellSize, height: cellSize)
//        )
//    }
//
//    private func stripePattern(cellSize: CGFloat) -> some View {
//        GeometryReader { geometry in
//            Path { path in
//                let width = geometry.size.width
//                let height = geometry.size.height
//                let stripeWidth: CGFloat = 6
//                let spacing: CGFloat = 6
//
//                var x: CGFloat = -height
//                while x < width + height {
//                    path.move(to: CGPoint(x: x, y: 0))
//                    path.addLine(to: CGPoint(x: x + height, y: height))
//                    path.addLine(to: CGPoint(x: x + height + stripeWidth, y: height))
//                    path.addLine(to: CGPoint(x: x + stripeWidth, y: 0))
//                    path.closeSubpath()
//
//                    x += stripeWidth + spacing
//                }
//            }
//            .fill(adaptiveStripeColor)
//        }
//    }
//
//    // MARK: - Drag Gesture (Updated for Single Tile Selection)
//
//    private func dragGesture(cellSize: CGFloat) -> some Gesture {
//        DragGesture(minimumDistance: 0, coordinateSpace: .local)
//            .onChanged { value in
//                if !isDragging {
//                    // Start of drag
//                    let startPos = positionFromLocation(value.startLocation, cellSize: cellSize)
//                    dragStart = startPos
//                    dragEnd = startPos
//
//                    if startPos != nil {
//                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
//                        impactFeedback.impactOccurred()
//                        currentSelectionSize = 1
//
//                        // Mark as dragging after small delay
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                            self.isDragging = true
//                        }
//                    }
//                } else {
//                    // Ongoing drag
//                    let currentPos = positionFromLocation(value.location, cellSize: cellSize)
//
//                    if let newEnd = currentPos, newEnd != dragEnd {
//                        dragEnd = newEnd
//                        updatePreviewValidation()
//                    }
//                }
//
//                dragLocation = value.location
//            }
//            .onEnded { value in
//                handleDragEnd()
//            }
//    }
//
//    private func positionFromLocation(_ location: CGPoint, cellSize: CGFloat) -> GridPosition? {
//        let adjustedX = location.x + cellSpacing / 2
//        let adjustedY = location.y + cellSpacing / 2
//
//        let col = Int(adjustedX / (cellSize + cellSpacing))
//        let row = Int(adjustedY / (cellSize + cellSpacing))
//
//        guard row >= 0 && row < game.gridSize.rows && col >= 0 && col < game.gridSize.cols else {
//            return nil
//        }
//
//        return GridPosition(row: row, col: col)
//    }
//
//    private func updatePreviewValidation() {
//        guard let start = dragStart, let end = dragEnd else {
//            previewValidation = (false, .gray)
//            currentSelectionSize = 0
//            return
//        }
//
//        let newSize = abs(end.row - start.row + 1) * abs(end.col - start.col + 1)
//        if newSize != currentSelectionSize {
//            currentSelectionSize = newSize
//            game.triggerSelectionHaptic()
//        }
//
//        previewValidation = game.validatePreviewRectangle(from: start, to: end)
//    }
//
//    private func handleDragEnd() {
//        guard let start = dragStart, let end = dragEnd else {
//            resetDragState()
//            return
//        }
//
//        // Haptic feedback based on validity
//        let feedbackGenerator = UINotificationFeedbackGenerator()
//        feedbackGenerator.notificationOccurred(previewValidation.isValid ? .success : .error)
//
//        // Add rectangle if preview was valid (including single tile)
//        if previewValidation.isValid {
//            game.addOrUpdateRectangle(from: start, to: end)
//        }
//
//        resetDragState()
//    }
//
//    private func resetDragState() {
//        dragStart = nil
//        dragEnd = nil
//        isDragging = false
//        currentSelectionSize = 0
//        previewValidation = (false, .gray)
//        dragLocation = .zero
//    }
//
//    private func isPositionInPreviewRectangle(_ position: GridPosition) -> Bool {
//        guard let start = dragStart, let end = dragEnd else { return false }
//
//        let topLeft = GridPosition(
//            row: min(start.row, end.row),
//            col: min(start.col, end.col)
//        )
//        let bottomRight = GridPosition(
//            row: max(start.row, end.row),
//            col: max(start.col, end.col)
//        )
//
//        return position.row >= topLeft.row && position.row <= bottomRight.row &&
//        position.col >= topLeft.col && position.col <= bottomRight.col
//    }
//
//    // MARK: - Victory Animation
//
//    private func triggerVictoryAnimation() {
//        game.triggerWinHaptic()
//        gameWon = true
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            gameWon = false
//        }
//    }
//
//    // MARK: - Bottom Section
//
//    private var bottomSection: some View {
//        VStack(spacing: 20) {
//            clearButton
//        }
//    }
//
//    private var clearButton: some View {
//        HStack(spacing: 0) {
//            if showClearConfirmation {
//                Button {
//                    withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
//                        showClearConfirmation = false
//                    }
//                } label: {
//                    Text("Cancel")
//                        .font(.headline)
//                        .foregroundColor(adaptiveSecondaryTextColor)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 12)
//                        .background(
//                            Rectangle()
//                                .fill(Color.clear)
//                                .overlay(
//                                    HStack {
//                                        Rectangle()
//                                            .fill(adaptiveSecondaryTextColor.opacity(0.5))
//                                            .frame(width: 0)
//                                        Spacer()
//                                        Rectangle()
//                                            .fill(adaptiveSecondaryTextColor.opacity(0.5))
//                                            .frame(width: 1)
//                                            .frame(height: 10)
//                                    }
//                                )
//                        )
//                }
//                .sensoryFeedback(.impact(weight: .light), trigger: !showClearConfirmation)
//                .transition(.asymmetric(
//                    insertion: .move(edge: .leading).combined(with: .opacity),
//                    removal: .move(edge: .leading).combined(with: .opacity)
//                ))
//
//                Button {
//                    withAnimation(.bouncy) {
//                        game.clearBoard()
//                        currentSelectionSize = 0
//                        showClearConfirmation = false
//                        gameWon = false
//                    }
//                } label: {
//                    Text("Clear")
//                        .font(.headline)
//                        .foregroundColor(.red)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 12)
//                        .background(
//                            Rectangle()
//                                .fill(Color.clear)
//                                .overlay(
//                                    HStack {
//                                        Spacer()
//                                        Rectangle()
//                                            .fill(adaptiveSecondaryTextColor.opacity(0.5))
//                                            .frame(width: 0)
//                                    }
//                                )
//                        )
//                }
//                .sensoryFeedback(.impact(weight: .medium), trigger: game.rectangles.isEmpty)
//                .transition(.asymmetric(
//                    insertion: .move(edge: .trailing).combined(with: .opacity),
//                    removal: .move(edge: .trailing).combined(with: .opacity)
//                ))
//            } else {
//                Button {
//                    withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
//                        showClearConfirmation = true
//                    }
//                } label: {
//                    Text("Clear board")
//                        .font(.headline)
//                        .foregroundColor(adaptiveSecondaryTextColor)
//                        .padding(.vertical, 12)
//                        .padding(.horizontal, 30)
//                }
//                .sensoryFeedback(.impact(weight: .light), trigger: showClearConfirmation)
//                .transition(.asymmetric(
//                    insertion: .scale.combined(with: .opacity),
//                    removal: .scale.combined(with: .opacity)
//                ))
//            }
//        }
//        .background(
//            RoundedRectangle(cornerRadius: 0)
//                .stroke(adaptiveSecondaryTextColor.opacity(0.5), lineWidth: 1)
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 0))
//        .padding(.bottom, 30)
//        .frame(maxWidth: 200)
//    }
//}

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

                    if session.game.isGameComplete {
                        completionView
                    } else {
                        controlsView
                    }
                }
                .padding()
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
                .foregroundStyle(.green)

            Text("Puzzle Complete!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Solved in \(formattedDuration)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                coordinator.dismissFullScreen()
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .sensoryFeedback(.success, trigger: session.game.isGameComplete)
        }
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
        let availableWidth = geometry.size.width - 40
        let availableHeight = geometry.size.height * 0.6

        let cellWidth = availableWidth / CGFloat(session.game.gridSize.cols + 1)
        let cellHeight = availableHeight / CGFloat(session.game.gridSize.rows + 1)

        return min(cellWidth, cellHeight, 60)
    }

    private func handleGameCompletion() {
        session.complete()

        // Update level completion in database
        session.level.isCompleted = true
        session.level.completionTime = Date().timeIntervalSinceReferenceDate

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

//#Preview {
//  ShikakuGameView(session: GameSession(level: ShikakuLevel(date: Date(), gridRows: 3, gridCols: 3), context: GameContext))
//}
