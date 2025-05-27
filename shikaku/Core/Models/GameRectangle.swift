//
//  GameRectangle.swift
//  shikaku
//
//  Created by Hugo Peyron on 24/05/2025.
//


import SwiftUI

struct GameRectangle: Identifiable, Hashable {
  let id = UUID()
  var topLeft: GridPosition
  var bottomRight: GridPosition
  var isValid: Bool = false
  var isSelected: Bool = false
  var color: Color = .blue

  var width: Int {
    bottomRight.col - topLeft.col + 1
  }

  var height: Int {
    bottomRight.row - topLeft.row + 1
  }

  var area: Int {
    width * height
  }

  func contains(position: GridPosition) -> Bool {
    position.row >= topLeft.row && position.row <= bottomRight.row &&
    position.col >= topLeft.col && position.col <= bottomRight.col
  }
}