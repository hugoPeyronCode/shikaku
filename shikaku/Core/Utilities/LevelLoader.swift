////
////  LevelService.swift
////  shikaku
////
////  Service ultra-performant avec JSON
////
//
//import SwiftUI
//import SwiftData
//import Foundation
//
//@Observable
//class LevelService {
//    private let modelContext: ModelContext
//
//    // Cache pour éviter les requêtes répétées
//    private var completionCache: [String: LevelCompletionState] = [:]
//    private var monthCache: [String: [ShikakuLevel]] = [:]
//
//    private let dateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter
//    }()
//
//    init(modelContext: ModelContext) {
//        self.modelContext = modelContext
//    }
//
//    // CRÉER UN NIVEAU COMPLET À PARTIR DU JSON
//    func getLevelForDate(_ date: Date) -> ShikakuLevel? {
//        guard let staticData = LevelLoader.shared.levelForDate(date) else {
//            return nil
//        }
//
//        // Créer le niveau à partir des données JSON
//        let level = ShikakuLevel(
//            date: date,
//            gridRows: staticData.gridRows,
//            gridCols: staticData.gridCols,
//            difficulty: staticData.difficulty
//        )
//
//        // Ajouter les clues
//        let levelClues = staticData.clues.map { clue in
//            LevelClue(row: clue.row, col: clue.col, value: clue.value)
//        }
//        level.clues = levelClues
//
//        // Charger l'état de completion
//        loadCompletionState(for: level)
//
//        return level
//    }
//
//    // OBTENIR TOUS LES NIVEAUX D'UN MOIS (AVEC CACHE)
//    func getLevelsForMonth(_ date: Date) -> [ShikakuLevel] {
//        let monthKey = self.monthKey(for: date)
//
//        // Vérifier le cache
//        if let cachedLevels = monthCache[monthKey] {
//            return cachedLevels
//        }
//
//        // Charger depuis le JSON
//        let staticLevels = LevelLoader.shared.levelsForMonth(date)
//
//        let levels = staticLevels.compactMap { staticData -> ShikakuLevel? in
//            guard let levelDate = dateFormatter.date(from: staticData.date) else { return nil }
//
//            let level = ShikakuLevel(
//                date: levelDate,
//                gridRows: staticData.gridRows,
//                gridCols: staticData.gridCols,
//                difficulty: staticData.difficulty
//            )
//
//            let levelClues = staticData.clues.map { clue in
//                LevelClue(row: clue.row, col: clue.col, value: clue.value)
//            }
//            level.clues = levelClues
//
//            loadCompletionState(for: level)
//            return level
//        }
//
//        // Mettre en cache
//        monthCache[monthKey] = levels
//
//        return levels
//    }
//
//    // OBTENIR DES NIVEAUX ALÉATOIRES POUR LA PRATIQUE
//    func getRandomLevelsForPractice(count: Int = 50, difficulty: Int? = nil) -> [ShikakuLevel] {
//        let staticLevels = LevelLoader.shared.randomLevelsForPractice(count: count, difficulty: difficulty)
//
//        return staticLevels.compactMap { staticData -> ShikakuLevel? in
//            guard let date = dateFormatter.date(from: staticData.date) else { return nil }
//
//            let level = ShikakuLevel(
//                date: date,
//                gridRows: staticData.gridRows,
//                gridCols: staticData.gridCols,
//                difficulty: staticData.difficulty
//            )
//
//            let levelClues = staticData.clues.map { clue in
//                LevelClue(row: clue.row, col: clue.col, value: clue.value)
//            }
//            level.clues = levelClues
//
//            loadCompletionState(for: level)
//            return level
//        }
//    }
//
//    // MARQUER UN NIVEAU COMME COMPLÉTÉ
//    func markLevelCompleted(_ level: ShikakuLevel, completionTime: TimeInterval) {
//        let dateString = dateFormatter.string(from: level.date)
//
//        // Mettre à jour ou créer l'état de completion
//        let completionState: LevelCompletionState
//        if let cached = completionCache[dateString] {
//            completionState = cached
//        } else {
//            // Chercher dans SwiftData
//            let descriptor = FetchDescriptor<LevelCompletionState>(
//                predicate: #Predicate<LevelCompletionState> { state in
//                    state.date == level.date
//                }
//            )
//
//            if let existing = try? modelContext.fetch(descriptor).first {
//                completionState = existing
//                completionCache[dateString] = existing
//            } else {
//                // Créer nouveau
//                completionState = LevelCompletionState(date: level.date)
//                modelContext.insert(completionState)
//                completionCache[dateString] = completionState
//            }
//        }
//
//        completionState.isCompleted = true
//        completionState.completionTime = completionTime
//        completionState.attempts += 1
//
//        // Mettre à jour le niveau
//        level.isCompleted = true
//        level.completionTime = completionTime
//
//        // Sauvegarder
//        try? modelContext.save()
//
//        // Invalider le cache du mois
//        invalidateMonthCache(for: level.date)
//
//        // Mettre à jour les statistiques globales
//        updateProgressStats()
//    }
//
//    // STATISTIQUES RAPIDES
//    func getStats() -> (total: Int, completed: Int, byDifficulty: [Int: Int]) {
//        // Stats totales depuis le JSON (instantané)
//        let (total, difficultyStats) = LevelLoader.shared.getLevelStats()
//
//        // Stats de completion depuis SwiftData
//        let completionDescriptor = FetchDescriptor<LevelCompletionState>(
//            predicate: #Predicate<LevelCompletionState> { state in
//                state.isCompleted == true
//            }
//        )
//
//        let completedCount = (try? modelContext.fetchCount(completionDescriptor)) ?? 0
//
//        return (total: total, completed: completedCount, byDifficulty: difficultyStats)
//    }
//
//    // MARK: - Private Methods
//
//    private func loadCompletionState(for level: ShikakuLevel) {
//        let dateString = dateFormatter.string(from: level.date)
//
//        // Vérifier le cache d'abord
//        if let cached = completionCache[dateString] {
//            level.isCompleted = cached.isCompleted
//            level.completionTime = cached.completionTime
//            return
//        }
//
//        // Chercher dans SwiftData
//        let descriptor = FetchDescriptor<LevelCompletionState>(
//            predicate: #Predicate<LevelCompletionState> { state in
//                state.date == level.date
//            }
//        )
//
//        if let completionState = try? modelContext.fetch(descriptor).first {
//            level.isCompleted = completionState.isCompleted
//            level.completionTime = completionState.completionTime
//            completionCache[dateString] = completionState
//        } else {
//            level.isCompleted = false
//            level.completionTime = nil
//        }
//    }
//
//    private func updateProgressStats() {
//        let descriptor = FetchDescriptor<GameProgress>()
//        let progressArray = (try? modelContext.fetch(descriptor)) ?? []
//
//        let progress = progressArray.first ?? {
//            let newProgress = GameProgress()
//            modelContext.insert(newProgress)
//            return newProgress
//        }()
//
//        // Compter les niveaux complétés
//        let completionDescriptor = FetchDescriptor<LevelCompletionState>(
//            predicate: #Predicate<LevelCompletionState> { state in
//                state.isCompleted == true
//            }
//        )
//
//        let completedCount = (try? modelContext.fetchCount(completionDescriptor)) ?? 0
//        progress.totalCompletedLevels = completedCount
//        progress.lastPlayedDate = Date()
//
//        try? modelContext.save()
//    }
//
//    private func monthKey(for date: Date) -> String {
//        let calendar = Calendar.current
//        let year = calendar.component(.year, from: date)
//        let month = calendar.component(.month, from: date)
//        return "\(year)-\(month)"
//    }
//
//    private func invalidateMonthCache(for date: Date) {
//        let key = monthKey(for: date)
//        monthCache.removeValue(forKey: key)
//    }
//}
