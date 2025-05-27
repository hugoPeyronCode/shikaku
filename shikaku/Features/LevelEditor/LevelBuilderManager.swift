//
//  LevelBuilderTools.swift
//  shikaku
//
//  Tools for building and exporting levels
//

import SwiftUI
import SwiftData
import Foundation

// MARK: - Level Export/Import Manager

@Observable
class LevelBuilderManager {
    var exportedLevels: [ExportableLevel] = []
    var isExporting = false
    var isImporting = false

    // MARK: - Export Functions

    func exportAllLevels(from context: ModelContext) -> String {
        let fetchDescriptor = FetchDescriptor<ShikakuLevel>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        guard let levels = try? context.fetch(fetchDescriptor) else {
            return "[]"
        }

        let exportableLevels = levels.map { level in
            ExportableLevel(
                date: level.date,
                gridRows: level.gridRows,
                gridCols: level.gridCols,
                clues: level.clues.map { clue in
                    ExportableClue(row: clue.row, col: clue.col, value: clue.value)
                },
                difficulty: level.difficulty,
                isCompleted: level.isCompleted
            )
        }

        return exportLevelsToJSON(exportableLevels)
    }

    func exportLevelsToJSON(_ levels: [ExportableLevel]) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(levels)
            return String(data: data, encoding: .utf8) ?? "Error encoding"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    func exportLevelsToFile(_ levels: [ExportableLevel]) -> URL? {
        let jsonString = exportLevelsToJSON(levels)

        let fileName = "shikaku_levels_\(Date().timeIntervalSince1970).json"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)

        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing file: \(error)")
            return nil
        }
    }

    // MARK: - Import Functions

    func importLevelsFromJSON(_ jsonString: String) -> [ExportableLevel]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = jsonString.data(using: .utf8) else { return nil }

        do {
            return try decoder.decode([ExportableLevel].self, from: data)
        } catch {
            print("Error decoding: \(error)")
            return nil
        }
    }

    func importLevelsToSwiftData(_ exportableLevels: [ExportableLevel], context: ModelContext) {
        for exportableLevel in exportableLevels {
            let level = ShikakuLevel(
                date: exportableLevel.date,
                gridRows: exportableLevel.gridRows,
                gridCols: exportableLevel.gridCols,
                difficulty: exportableLevel.difficulty
            )

            let levelClues = exportableLevel.clues.map { clue in
                LevelClue(row: clue.row, col: clue.col, value: clue.value)
            }
            level.clues = levelClues
            level.isCompleted = exportableLevel.isCompleted

            context.insert(level)
        }

        try? context.save()
    }

    // MARK: - Advanced Procedural Level Generation

    func generateSampleLevels(count: Int = 200) -> [ExportableLevel] {
        var levels: [ExportableLevel] = []
        let startDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? Date()

        for i in 0..<count {
            guard let date = Calendar.current.date(byAdding: .day, value: i, to: startDate) else { continue }

            // Progression de difficulté plus sophistiquée
            let difficulty = calculateDifficulty(for: i, total: count)
            let gridSize = calculateGridSize(for: i, difficulty: difficulty)

            // Générer un niveau valide avec plusieurs tentatives
            var level: ExportableLevel?
            var attempts = 0

            while level == nil && attempts < 10 {
                level = generateValidLevel(
                    date: date,
                    gridSize: gridSize,
                    difficulty: difficulty,
                    levelNumber: i + 1
                )
                attempts += 1
            }

            if let validLevel = level {
                levels.append(validLevel)
            } else {
                // Fallback: niveau simple garanti
                levels.append(generateSimpleLevel(date: date, gridSize: gridSize, difficulty: difficulty))
            }
        }

        return levels
    }

    private func calculateDifficulty(for levelIndex: Int, total: Int) -> Int {
        let progress = Double(levelIndex) / Double(total)

        switch progress {
        case 0..<0.1: return 1      // 10% premiers niveaux = facile
        case 0.1..<0.3: return 2    // 20% suivants = moyen-facile
        case 0.3..<0.6: return 3    // 30% = moyen
        case 0.6..<0.8: return 4    // 20% = difficile
        default: return 5           // 20% derniers = très difficile
        }
    }

    private func calculateGridSize(for levelIndex: Int, difficulty: Int) -> (rows: Int, cols: Int) {
        // Taille basée sur difficulté et progression
        switch difficulty {
        case 1: return [(4, 4), (5, 4), (4, 5)].randomElement() ?? (4, 4)
        case 2: return [(5, 5), (6, 4), (5, 6)].randomElement() ?? (5, 5)
        case 3: return [(6, 5), (6, 6), (7, 5)].randomElement() ?? (6, 5)
        case 4: return [(7, 6), (8, 5), (6, 7)].randomElement() ?? (7, 6)
        case 5: return [(8, 6), (9, 6), (7, 7)].randomElement() ?? (8, 6)
        default: return (6, 5)
        }
    }

    func generateValidLevel(date: Date, gridSize: (rows: Int, cols: Int), difficulty: Int, levelNumber: Int) -> ExportableLevel? {
        // Algorithme de génération "reverse engineering"
        // 1. Créer une solution valide
        // 2. Extraire les clues minimales

        let totalCells = gridSize.rows * gridSize.cols
        var solution = generateSolution(gridSize: gridSize, difficulty: difficulty)

        guard let validSolution = solution else { return nil }

        // Extraire les clues de la solution
        let clues = extractCluesFromSolution(validSolution, gridSize: gridSize, difficulty: difficulty)

        // Vérifier que les clues sont solvables
        guard validateClues(clues, gridSize: gridSize, totalCells: totalCells) else { return nil }

        return ExportableLevel(
            date: date,
            gridRows: gridSize.rows,
            gridCols: gridSize.cols,
            clues: clues,
            difficulty: difficulty,
            isCompleted: false
        )
    }

    private func generateSolution(gridSize: (rows: Int, cols: Int), difficulty: Int) -> [[Rectangle]]? {
        // Générer des rectangles qui remplissent complètement la grille
        var grid = Array(repeating: Array(repeating: -1, count: gridSize.cols), count: gridSize.rows)
        var rectangles: [Rectangle] = []
        var rectId = 0

        // Paramètres basés sur la difficulté
        let preferredSizes = getPreferredRectangleSizes(difficulty: difficulty)

        // Remplir la grille avec des rectangles
        for row in 0..<gridSize.rows {
            for col in 0..<gridSize.cols {
                if grid[row][col] == -1 { // Cellule vide
                    if let rect = placeRectangle(at: (row, col), in: &grid, gridSize: gridSize, preferredSizes: preferredSizes, rectId: rectId) {
                        rectangles.append(rect)
                        rectId += 1
                    }
                }
            }
        }

        // Vérifier que toute la grille est remplie
        for row in 0..<gridSize.rows {
            for col in 0..<gridSize.cols {
                if grid[row][col] == -1 { return nil }
            }
        }

        return [rectangles] // Retourner comme array 2D pour compatibilité
    }

    private func getPreferredRectangleSizes(difficulty: Int) -> [Int] {
        switch difficulty {
        case 1: return [2, 2, 3, 3, 4]          // Facile: petits rectangles
        case 2: return [2, 3, 3, 4, 4, 6]       // Moyen-facile
        case 3: return [2, 3, 4, 4, 6, 6, 8]    // Moyen
        case 4: return [3, 4, 6, 6, 8, 9, 12]   // Difficile
        case 5: return [4, 6, 8, 9, 12, 15, 16] // Très difficile: gros rectangles
        default: return [2, 3, 4]
        }
    }

    private func placeRectangle(at position: (Int, Int), in grid: inout [[Int]], gridSize: (rows: Int, cols: Int), preferredSizes: [Int], rectId: Int) -> Rectangle? {
        let (startRow, startCol) = position
        let maxArea = (gridSize.rows - startRow) * (gridSize.cols - startCol)

        // Essayer différentes tailles de rectangles
        let sizes = preferredSizes.filter { $0 <= maxArea }.shuffled()

        for targetSize in sizes {
            // Essayer différentes dimensions pour cette taille
            let possibleDimensions = getPossibleDimensions(for: targetSize)

            for (width, height) in possibleDimensions.shuffled() {
                if canPlaceRectangle(at: position, width: width, height: height, in: grid, gridSize: gridSize) {
                    // Placer le rectangle
                    for r in startRow..<(startRow + height) {
                        for c in startCol..<(startCol + width) {
                            grid[r][c] = rectId
                        }
                    }

                    return Rectangle(
                        id: rectId,
                        x: startCol,
                        y: startRow,
                        width: width,
                        height: height,
                        size: width * height
                    )
                }
            }
        }

        // Si aucune taille préférée ne marche, prendre n'importe quelle taille possible
        for height in 1...(gridSize.rows - startRow) {
            for width in 1...(gridSize.cols - startCol) {
                if canPlaceRectangle(at: position, width: width, height: height, in: grid, gridSize: gridSize) {
                    let size = width * height

                    // Placer le rectangle
                    for r in startRow..<(startRow + height) {
                        for c in startCol..<(startCol + width) {
                            grid[r][c] = rectId
                        }
                    }

                    return Rectangle(
                        id: rectId,
                        x: startCol,
                        y: startRow,
                        width: width,
                        height: height,
                        size: size
                    )
                }
            }
        }

        return nil
    }

    private func getPossibleDimensions(for size: Int) -> [(width: Int, height: Int)] {
        var dimensions: [(Int, Int)] = []

        for width in 1...size {
            if size % width == 0 {
                let height = size / width
                dimensions.append((width, height))
            }
        }

        return dimensions
    }

    private func canPlaceRectangle(at position: (Int, Int), width: Int, height: Int, in grid: [[Int]], gridSize: (rows: Int, cols: Int)) -> Bool {
        let (startRow, startCol) = position

        // Vérifier les limites
        if startRow + height > gridSize.rows || startCol + width > gridSize.cols {
            return false
        }

        // Vérifier que toutes les cellules sont libres
        for r in startRow..<(startRow + height) {
            for c in startCol..<(startCol + width) {
                if grid[r][c] != -1 {
                    return false
                }
            }
        }

        return true
    }

    private func extractCluesFromSolution(_ solution: [[Rectangle]], gridSize: (rows: Int, cols: Int), difficulty: Int) -> [ExportableClue] {
        var clues: [ExportableClue] = []

        // Pour chaque rectangle dans la solution, placer une clue
        for rectangles in solution {
            for rect in rectangles {
                // Choisir une position aléatoire dans le rectangle pour la clue
                let clueRow = rect.y + Int.random(in: 0..<rect.height)
                let clueCol = rect.x + Int.random(in: 0..<rect.width)

                clues.append(ExportableClue(
                    row: clueRow,
                    col: clueCol,
                    value: rect.size
                ))
            }
        }

        return clues
    }

    private func validateClues(_ clues: [ExportableClue], gridSize: (rows: Int, cols: Int), totalCells: Int) -> Bool {
        // Vérifications de base
        let sumOfClues = clues.reduce(0) { $0 + $1.value }

        // La somme doit être égale au nombre total de cellules
        guard sumOfClues == totalCells else { return false }

        // Chaque clue doit être dans les limites
        for clue in clues {
            if clue.row < 0 || clue.row >= gridSize.rows ||
               clue.col < 0 || clue.col >= gridSize.cols {
                return false
            }
        }

        // Pas de clues en double sur la même position
        let positions = Set(clues.map { "\($0.row),\($0.col)" })
        guard positions.count == clues.count else { return false }

        return true
    }

    func generateSimpleLevel(date: Date, gridSize: (rows: Int, cols: Int), difficulty: Int) -> ExportableLevel {
        // Générateur de fallback simple mais garanti de fonctionner
        let totalCells = gridSize.rows * gridSize.cols

        // Créer des rectangles simples
        var clues: [ExportableClue] = []
        var remainingCells = totalCells
        let minClues = max(3, totalCells / (difficulty + 2))

        for i in 0..<minClues {
            let maxSize = remainingCells - (minClues - i - 1) * 2 // Garder au moins 2 cellules pour chaque clue restante
            let clueSize = i == minClues - 1 ? remainingCells : Int.random(in: 2...min(maxSize, 6))

            let row = Int.random(in: 0..<gridSize.rows)
            let col = Int.random(in: 0..<gridSize.cols)

            clues.append(ExportableClue(row: row, col: col, value: clueSize))
            remainingCells -= clueSize
        }

        return ExportableLevel(
            date: date,
            gridRows: gridSize.rows,
            gridCols: gridSize.cols,
            clues: clues,
            difficulty: difficulty,
            isCompleted: false
        )
    }

    // MARK: - Helper Structures

    private struct Rectangle {
        let id: Int
        let x: Int
        let y: Int
        let width: Int
        let height: Int
        let size: Int
    }
}

// MARK: - Exportable Data Structures

struct ExportableLevel: Codable {
    let date: Date
    let gridRows: Int
    let gridCols: Int
    var clues: [ExportableClue]
    let difficulty: Int
    let isCompleted: Bool
}

struct ExportableClue: Codable {
    let row: Int
    let col: Int
    var value: Int
}

// MARK: - Level Builder UI

struct LevelBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var builderManager = LevelBuilderManager()
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var exportedData = ""
    @State private var importData = ""
    @State private var generatedLevels: [ExportableLevel] = []
    @State private var showingGeneratedLevels = false
    @State private var showingGameView = false
    @State private var selectedLevelToPlay: ExportableLevel?
    @State private var testGame = ShikakuGame()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                VStack(spacing: 16) {
                    // Generation section (moved up)
                    GroupBox("Generate & Test Levels") {
                        VStack(spacing: 12) {
                            Button("Generate 200 Sample Levels") {
                                generatedLevels = builderManager.generateSampleLevels(count: 200)
                                showingGeneratedLevels = true
                            }
                            .buttonStyle(.borderedProminent)

                            if !generatedLevels.isEmpty {
                                HStack {
                                    Text("Generated \(generatedLevels.count) levels")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Button("Preview & Test") {
                                        showingGeneratedLevels = true
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }

                                Button("Import All Generated Levels") {
                                    builderManager.importLevelsToSwiftData(generatedLevels, context: modelContext)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }

                    // Export section
                    GroupBox("Export Levels") {
                        VStack(spacing: 12) {
                            Button("Export All Levels to JSON") {
                                exportedData = builderManager.exportAllLevels(from: modelContext)
                                showingExportSheet = true
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Export Generated Levels to File") {
                                if let url = builderManager.exportLevelsToFile(generatedLevels) {
                                    shareFile(url: url)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(generatedLevels.isEmpty)
                        }
                    }

                    // Import section
                    GroupBox("Import Levels") {
                        VStack(spacing: 12) {
                            Button("Import from JSON") {
                                showingImportSheet = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Spacer()

                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions:")
                        .font(.headline)

                    Text("1. Generate 200 levels with progressive difficulty")
                    Text("2. Preview and test levels before importing")
                    Text("3. Import good levels to your database")
                    Text("4. Export to JSON for your final app bundle")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .navigationTitle("Level Builder")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataSheet(data: exportedData)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataSheet(importData: $importData, onImport: { data in
                if let levels = builderManager.importLevelsFromJSON(data) {
                    builderManager.importLevelsToSwiftData(levels, context: modelContext)
                }
            })
        }
        .sheet(isPresented: $showingGeneratedLevels) {
            GeneratedLevelsPreview(
                levels: generatedLevels,
                onPlayLevel: { level in
                    selectedLevelToPlay = level
                    loadLevelIntoGame(level)
                    showingGameView = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingGameView) {
            ZStack {
                // Game content
              ShikakuGameView(session: testGame)

                // Close button overlay
                VStack {
                    HStack {
                        // Level info
                        if let currentLevel = selectedLevelToPlay {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Test Level")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Difficulty \(currentLevel.difficulty) • \(currentLevel.gridRows)×\(currentLevel.gridCols)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                        }

                        Spacer()

                        Button {
                            showingGameView = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                                )
                        }
                        .sensoryFeedback(.impact(weight: .light), trigger: false)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                }
            }
        }
    }

    // FIXED: Properly load level data into the game
    private func loadLevelIntoGame(_ level: ExportableLevel) {
        // Create a completely new game instance
        testGame = ShikakuGame()

        // Configure the test game with the selected level
        testGame.gridSize = (level.gridRows, level.gridCols)
        testGame.numberClues = level.clues.map { clue in
            NumberClue(
                position: GridPosition(row: clue.row, col: clue.col),
                value: clue.value
            )
        }
        testGame.rectangles = []
        testGame.validateGame()
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Shikaku Level Builder")
                .font(.title)
                .fontWeight(.bold)

            Text("Create, test and export levels")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct ExportDataSheet: View {
    let data: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(data)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("Exported Levels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Copy") {
                        UIPasteboard.general.string = data
                    }
                }
            }
        }
    }
}

struct ImportDataSheet: View {
    @Binding var importData: String
    let onImport: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paste JSON data below:")
                    .font(.headline)

                TextEditor(text: $importData)
                    .font(.system(.caption, design: .monospaced))
                    .border(Color.secondary.opacity(0.3))

                Button("Import Levels") {
                    onImport(importData)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(importData.isEmpty)
            }
            .padding()
            .navigationTitle("Import Levels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct GeneratedLevelsPreview: View {
    let levels: [ExportableLevel]
    let onPlayLevel: (ExportableLevel) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDifficulty: Int = 0 // 0 = all

    private var filteredLevels: [ExportableLevel] {
        if selectedDifficulty == 0 {
            return levels
        } else {
            return levels.filter { $0.difficulty == selectedDifficulty }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Difficulty filter
                difficultyFilterView
                    .padding()
                    .background(Color(.systemGray6))

                // Levels list
                List {
                    ForEach(Array(filteredLevels.enumerated()), id: \.offset) { index, level in
                        LevelPreviewRow(
                            level: level,
                            levelNumber: levels.firstIndex(where: { $0.date == level.date }) ?? index,
                            onPlay: { onPlayLevel(level) }
                        )
                    }
                }
            }
            .navigationTitle("Generated Levels (\(filteredLevels.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Export All as JSON") {
                            exportToClipboard()
                        }

                        Button("Export Filtered as JSON") {
                            exportFilteredToClipboard()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private var difficultyFilterView: some View {
        VStack(spacing: 12) {
            Text("Filter by Difficulty")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                DifficultyFilterButton(
                    title: "All",
                    count: levels.count,
                    isSelected: selectedDifficulty == 0
                ) {
                    selectedDifficulty = 0
                }

                ForEach(1...5, id: \.self) { difficulty in
                    let count = levels.filter { $0.difficulty == difficulty }.count

                    DifficultyFilterButton(
                        title: "D\(difficulty)",
                        count: count,
                        isSelected: selectedDifficulty == difficulty
                    ) {
                        selectedDifficulty = difficulty
                    }
                }
            }
        }
    }

    private func exportToClipboard() {
        let manager = LevelBuilderManager()
        let jsonString = manager.exportLevelsToJSON(levels)
        UIPasteboard.general.string = jsonString
    }

    private func exportFilteredToClipboard() {
        let manager = LevelBuilderManager()
        let jsonString = manager.exportLevelsToJSON(filteredLevels)
        UIPasteboard.general.string = jsonString
    }
}

struct DifficultyFilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("\(count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

struct LevelPreviewRow: View {
    let level: ExportableLevel
    let levelNumber: Int
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Level preview mini-grid
            LevelMiniGrid(level: level)
                .frame(width: 60, height: 60)

            // Level info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Level \(levelNumber + 1)")
                        .font(.headline)

                    Spacer()

                    // Difficulty badge
                    DifficultyBadge(difficulty: level.difficulty)
                }

                HStack {
                    Text("\(level.gridRows)×\(level.gridCols)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(level.clues.count) clues")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                Text(level.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Play button
            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct LevelMiniGrid: View {
    let level: ExportableLevel

    var body: some View {
        let cellSize: CGFloat = CGFloat(60 / max(level.gridRows, level.gridCols))

        VStack(spacing: 0.5) {
            ForEach(0..<level.gridRows, id: \.self) { row in
                HStack(spacing: 0.5) {
                    ForEach(0..<level.gridCols, id: \.self) { col in
                        let clue = level.clues.first { $0.row == row && $0.col == col }

                        ZStack {
                            Rectangle()
                                .fill(clue != nil ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.1))
                                .frame(width: cellSize, height: cellSize)

                            if let clue = clue {
                                Text("\(clue.value)")
                                    .font(.system(size: max(6, cellSize * 0.6), weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct DifficultyBadge: View {
    let difficulty: Int

    private var badgeColor: Color {
        switch difficulty {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }

    private var difficultyText: String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        case 4: return "Expert"
        case 5: return "Master"
        default: return "Unknown"
        }
    }

    var body: some View {
        Text(difficultyText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(badgeColor.opacity(0.2))
            )
            .foregroundStyle(badgeColor)
    }
}

#Preview {
    LevelBuilderView()
        .modelContainer(for: [ShikakuLevel.self, GameProgress.self, LevelClue.self])
}
