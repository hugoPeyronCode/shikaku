//
//  GameCellView.swift
//  shikaku
//
//  Created by Hugo Peyron on 27/05/2025.
//

import SwiftUI

struct GameCellView: View {
    let position: GridPosition
    let game: ShikakuGame
    let cellSize: CGFloat
    let dragStart: GridPosition?
    let dragEnd: GridPosition?
    let isDragging: Bool

    private var numberClue: NumberClue? {
        game.numberClues.first { $0.position == position }
    }

    private var containingRect: GameRectangle? {
        game.rectangles.first { $0.contains(position: position) }
    }

    private var isInPreview: Bool {
        guard let start = dragStart, let end = dragEnd, isDragging else { return false }

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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                )

            if let clue = numberClue {
                Text("\(clue.value)")
                    .font(.system(size: cellSize * 0.4, weight: .bold))
                    .foregroundStyle(textColor)
            }
        }
    }

    private var backgroundColor: Color {
        if isInPreview && isDragging {
            return .primary.opacity(0.2)
        } else if let rect = containingRect, rect.isValid {
            return rect.color.opacity(0.6)
        } else {
            return .secondary.opacity(0.1)
        }
    }

    private var textColor: Color {
        if containingRect?.isValid == true {
            return .white
        } else {
            return .primary
        }
    }

    private var borderColor: Color {
        if isInPreview && isDragging {
            return .primary
        } else {
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        isInPreview && isDragging ? 2 : 0
    }
}

//#Preview {
//    GameCellView()
//}
