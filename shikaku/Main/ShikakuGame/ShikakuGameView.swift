//
//  ShikakuGameView.swift
//  shikaku
//
//  Updated game view to work with both calendar and standalone modes
//

import SwiftUI

struct ShikakuGameView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var game: ShikakuGame
    @State private var dragStart: GridPosition?
    @State private var dragEnd: GridPosition?
    @State private var isDragging = false
    @State private var dragLocation: CGPoint = .zero
    @State private var gameWon = false
    @State private var currentSelectionSize = 0
    @State private var previewValidation: (isValid: Bool, color: Color) = (false, .gray)
    @State private var showClearConfirmation = false
    @State private var showingCalendar = false

    let cellSize: CGFloat = 60
    let cornerRadius: CGFloat = 16
    let cellSpacing: CGFloat = 4

    init(game: ShikakuGame = ShikakuGame()) {
        self._game = State(initialValue: game)
    }

    var body: some View {
        ZStack {
            // Background adaptatif
            adaptiveBackgroundColor.ignoresSafeArea()

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
        }
        .sheet(isPresented: $showingCalendar) {
            ShikakuCalendarView()
        }
    }

    // MARK: - Couleurs et styles adaptatifs

    private var adaptiveBackgroundColor: Color {
        colorScheme == .dark ? .black : Color(.systemBackground)
    }

    private var adaptiveTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var adaptiveSecondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .secondary
    }

    private var adaptiveCellBackgroundColor: Color {
        colorScheme == .dark ?
            Color(red: 0.25, green: 0.25, blue: 0.3) :
            Color(.systemGray6)
    }

    private var adaptiveGlowColor: Color {
        colorScheme == .dark ?
            Color.white :
            Color.black
    }

    // MARK: - Sous-vues décomposées (gardées identiques)

    private var headerView: some View {
        HStack {
            Button {
                showingCalendar = true
            } label: {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(adaptiveSecondaryTextColor)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: showingCalendar)

            Spacer()

            Text("Shikaku")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(adaptiveTextColor)

            Spacer()

            Button(action: {}) {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
                    .foregroundColor(adaptiveSecondaryTextColor)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: false)

            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(adaptiveSecondaryTextColor)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: false)
        }
        .padding(.horizontal)
    }

    private var gameGridSection: some View {
        VStack {
            gameGrid
                .onChange(of: game.isGameComplete) { oldValue, newValue in
                    if newValue && !oldValue {
                        triggerVictoryAnimation()
                    }
                }
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Plus de texte simple - l'animation se passe sur la grille
            clearButton
        }
    }

    // MARK: - Victory Animation (simplifié)

    private func triggerVictoryAnimation() {
        // Haptic feedback de victoire
        game.triggerWinHaptic()

        // Animation de glow simple sur toutes les tiles
        gameWon = true

        // Reset après 2 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            gameWon = false
        }
    }

    private var clearButton: some View {
        HStack(spacing: 0) {
            if showClearConfirmation {
                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                        showClearConfirmation = false
                    }
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(adaptiveSecondaryTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(Color.clear)
                                .overlay(
                                    HStack {
                                        Rectangle()
                                            .fill(adaptiveSecondaryTextColor.opacity(0.5))
                                            .frame(width: 0)
                                        Spacer()
                                        Rectangle()
                                            .fill(adaptiveSecondaryTextColor.opacity(0.5))
                                            .frame(width: 1)
                                            .frame(height: 10)
                                    }
                                )
                        )
                }
                .sensoryFeedback(.impact(weight: .light), trigger: !showClearConfirmation)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                // Clear button
                Button {
                    withAnimation(.bouncy) {
                        game.clearBoard()
                        currentSelectionSize = 0
                        showClearConfirmation = false
                        // Reset animation
                        gameWon = false
                    }
                } label: {
                    Text("Clear")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(Color.clear)
                                .overlay(
                                    HStack {
                                        Spacer()
                                        Rectangle()
                                            .fill(adaptiveSecondaryTextColor.opacity(0.5))
                                            .frame(width: 0)
                                    }
                                )
                        )
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: game.rectangles.isEmpty)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                // Single clear board button
                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                        showClearConfirmation = true
                    }
                } label: {
                    Text("Clear board")
                        .font(.headline)
                        .foregroundColor(adaptiveSecondaryTextColor)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                }
                .sensoryFeedback(.impact(weight: .light), trigger: showClearConfirmation)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .stroke(adaptiveSecondaryTextColor.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .padding(.bottom, 30)
        .frame(maxWidth: 200)
    }

    // MARK: - Modern Game Grid

    private var gameGrid: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<game.gridSize.rows, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<game.gridSize.cols, id: \.self) { col in
                        modernCellView(row: row, col: col)
                    }
                }
            }
        }
        .background(Color.clear)
        .gesture(dragGesture)
    }

    private func modernCellView(row: Int, col: Int) -> some View {
        let position = GridPosition(row: row, col: col)
        let numberClue = game.numberClues.first { $0.position == position }
        let containingRect = game.rectangles.first { $0.contains(position: position) }
        let isInPreview = isPositionInPreviewRectangle(position)
        let isStartCell = dragStart == position && !isDragging

        return ZStack {
            // Base cell avec corners arrondis
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(cellBackgroundColor(containingRect: containingRect, isInPreview: isInPreview, isStartCell: isStartCell))
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    // Effet de glow de victoire - apparaît et reste
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(adaptiveGlowColor, lineWidth: gameWon ? 2 : 0)
                        .opacity(gameWon ? 0.8 : 0)
                        .animation(.easeInOut(duration: 0.6), value: gameWon)
                )
                .shadow(
                    color: gameWon ? adaptiveGlowColor.opacity(0.4) : Color.clear,
                    radius: gameWon ? 8 : 0
                )
                .animation(.easeInOut(duration: 0.6), value: gameWon)

            // Contour de la zone en cours de sélection
            if isInPreview && isDragging {
                previewBorderOverlay(for: position)
            }

            // Stripe pattern for invalid preview (seulement si invalide)
            if isInPreview && !previewValidation.isValid && isDragging {
                stripePattern
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .frame(width: cellSize, height: cellSize)
            }

            if let clue = numberClue {
                Text("\(clue.value)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(numberClueTextColor(containingRect: containingRect, isInPreview: isInPreview, isStartCell: isStartCell))
            }
        }
        .onTapGesture {
            game.removeRectangle(at: position)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: game.rectangles.count)
    }

    private func cellBackgroundColor(containingRect: GameRectangle?, isInPreview: Bool, isStartCell: Bool) -> Color {
        if isStartCell {
            // Cellule de départ activée mais pas encore en drag
            return Color(red: 0.4, green: 0.5, blue: 0.9).opacity(0.4)
        } else if isInPreview && isDragging {
            // Zone en cours de sélection - transparent pour voir le contour
            return adaptiveCellBackgroundColor
        } else if let rect = containingRect, rect.isValid {
            // Rectangle validé - couleur pleine
            return rect.color.opacity(0.8)
        } else {
            return adaptiveCellBackgroundColor
        }
    }

    private func numberClueTextColor(containingRect: GameRectangle?, isInPreview: Bool, isStartCell: Bool) -> Color {
        if isStartCell || (containingRect != nil && containingRect!.isValid) {
            return .white // Blanc sur fond coloré
        } else {
            return adaptiveTextColor // Couleur adaptative sur fond neutre
        }
    }

    // MARK: - Preview Border Overlay

    private func previewBorderOverlay(for position: GridPosition) -> some View {
        guard let start = dragStart, let end = dragEnd else {
            return AnyView(EmptyView())
        }

        let topLeft = GridPosition(
            row: min(start.row, end.row),
            col: min(start.col, end.col)
        )
        let bottomRight = GridPosition(
            row: max(start.row, end.row),
            col: max(start.col, end.col)
        )

        // Toujours bleu, pas de rouge
        let borderColor = Color(red: 0.4, green: 0.5, blue: 0.9)
        let borderWidth: CGFloat = 3

        return AnyView(
            ZStack {
                // Top border
                if position.row == topLeft.row {
                    VStack {
                        Rectangle()
                            .fill(borderColor)
                            .frame(height: borderWidth)
                        Spacer()
                    }
                }

                // Bottom border
                if position.row == bottomRight.row {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(borderColor)
                            .frame(height: borderWidth)
                    }
                }

                // Left border
                if position.col == topLeft.col {
                    HStack {
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: borderWidth)
                        Spacer()
                    }
                }

                // Right border
                if position.col == bottomRight.col {
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: borderWidth)
                    }
                }
            }
            .frame(width: cellSize, height: cellSize)
        )
    }

    private var stripePattern: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let stripeWidth: CGFloat = 6
                let spacing: CGFloat = 6

                // Lignes diagonales plus fines et plus espacées
                var x: CGFloat = -height
                while x < width + height {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + height, y: height))
                    path.addLine(to: CGPoint(x: x + height + stripeWidth, y: height))
                    path.addLine(to: CGPoint(x: x + stripeWidth, y: 0))
                    path.closeSubpath()

                    x += stripeWidth + spacing
                }
            }
            .fill(adaptiveStripeColor)
        }
    }

    private var adaptiveStripeColor: Color {
        colorScheme == .dark ?
            Color.white.opacity(0.15) :
            Color.black.opacity(0.08)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if !isDragging {
                    // Début du drag - activation immédiate de la première cellule
                    let startPos = positionFromLocation(value.startLocation)
                    dragStart = startPos
                    dragEnd = startPos // Important : même position au début

                    if startPos != nil {
                        // Haptic feedback immédiat
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        currentSelectionSize = 1

                        // Marquer comme en cours de drag après un petit délai
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.isDragging = true
                        }
                    }
                } else {
                    // Drag en cours - mise à jour de la position finale
                    let currentPos = positionFromLocation(value.location)

                    if let newEnd = currentPos, newEnd != dragEnd {
                        dragEnd = newEnd
                        updatePreviewValidation()
                    }
                }

                dragLocation = value.location
            }
            .onEnded { value in
                handleDragEnd()
            }
    }

    private func positionFromLocation(_ location: CGPoint) -> GridPosition? {
        let adjustedX = location.x + cellSpacing / 2
        let adjustedY = location.y + cellSpacing / 2

        let col = Int(adjustedX / (cellSize + cellSpacing))
        let row = Int(adjustedY / (cellSize + cellSpacing))

        guard row >= 0 && row < game.gridSize.rows && col >= 0 && col < game.gridSize.cols else {
            return nil
        }

        return GridPosition(row: row, col: col)
    }

    private func updatePreviewValidation() {
        guard let start = dragStart, let end = dragEnd else {
            previewValidation = (false, .gray)
            currentSelectionSize = 0
            return
        }

        let newSize = abs(end.row - start.row + 1) * abs(end.col - start.col + 1)
        if newSize != currentSelectionSize {
            currentSelectionSize = newSize
            game.triggerSelectionHaptic()
        }

        previewValidation = game.validatePreviewRectangle(from: start, to: end)
    }

    func handleDragEnd() {
        guard let start = dragStart, let end = dragEnd else {
            resetDragState()
            return
        }

        // Haptic feedback based on validity
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(previewValidation.isValid ? .success : .error)

        // Only add rectangle if preview was valid
        if previewValidation.isValid {
            game.addOrUpdateRectangle(from: start, to: end)
        }

        resetDragState()
    }

    private func resetDragState() {
        dragStart = nil
        dragEnd = nil
        isDragging = false
        currentSelectionSize = 0
        previewValidation = (false, .gray)
        dragLocation = .zero
    }

    func handleDrag(location: CGPoint, startLocation: CGPoint, isStart: Bool) {
        // Cette fonction n'est plus utilisée - remplacée par le nouveau dragGesture
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

#Preview {
    ShikakuGameView()
}
