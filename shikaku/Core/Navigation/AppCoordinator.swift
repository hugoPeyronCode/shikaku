//
//  AppCoordinator.swift
//  shikaku
//
//  Created by Hugo Peyron on 27/05/2025.
//

import SwiftUI

@Observable
class AppCoordinator {
    var navigationPath = NavigationPath()
    var presentedSheet: SheetDestination?
    var presentedFullScreen: FullScreenDestination?

  enum NavigationDestination: Hashable {
         case practiceMode([ShikakuLevel])

         // Implement Hashable
         static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
             switch (lhs, rhs) {
             case (.practiceMode(let lhsLevels), .practiceMode(let rhsLevels)):
                 return lhsLevels.map { $0.id } == rhsLevels.map { $0.id }
             }
         }

         func hash(into hasher: inout Hasher) {
             switch self {
             case .practiceMode(let levels):
                 hasher.combine("practiceMode")
                 hasher.combine(levels.map { $0.id })
             }
         }
     }

    enum SheetDestination: Identifiable {
        case levelEditor(date: Date)
        case levelBuilder

        var id: String {
            switch self {
            case .levelEditor: return "levelEditor"
            case .levelBuilder: return "levelBuilder"
            }
        }
    }

  enum FullScreenDestination: Identifiable, Equatable {
      case game(GameSession)

      var id: String {
          switch self {
          case .game: return "game"
          }
      }

      // Equatable conformance
      static func == (lhs: FullScreenDestination, rhs: FullScreenDestination) -> Bool {
          switch (lhs, rhs) {
          case (.game(let lhsSession), .game(let rhsSession)):
              return lhsSession.id == rhsSession.id
          }
      }
  }
    // Navigation actions
    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }

    func presentFullScreen(_ destination: FullScreenDestination) {
        presentedFullScreen = destination
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }

  func push(_ destination: NavigationDestination) {
       navigationPath.append(destination)
   }

    func pop() {
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }
}


@Observable
class GameSession {
    let id = UUID()
    let level: ShikakuLevel
    let context: GameContext
    var game: ShikakuGame
    var startTime = Date()
    var endTime: Date?
    var isCompleted = false

    enum GameContext {
        case daily(Date)
        case practice
        case custom
    }

    init(level: ShikakuLevel, context: GameContext) {
        self.level = level
        self.context = context
        self.game = ShikakuGame()
        setupGame()
    }

    private func setupGame() {
        game.gridSize = (level.gridRows, level.gridCols)
        game.numberClues = level.toNumberClues()
        game.rectangles = []
        game.validateGame()
    }

    func complete() {
        guard !isCompleted else { return }
        isCompleted = true
        endTime = Date()
    }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}
