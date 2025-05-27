//
//  ShikakuLevelEditorView.swift
//  shikaku
//
//  Updated level editor with SwiftData integration
//

import SwiftUI

@Observable
class LevelEditor {
    var gridSize: (rows: Int, cols: Int) = (9, 6)
    var numberClues: [NumberClue] = []
    var selectedNumber: Int = 2
    var editMode: EditMode = .addClue
    var isDirty: Bool = false

    enum EditMode {
        case addClue
        case removeClue
    }

    func addClue(at position: GridPosition, value: Int) {
        // Remove existing clue at position
        numberClues.removeAll { $0.position == position }

        // Add new clue
        numberClues.append(NumberClue(position: position, value: value))
        isDirty = true
    }

    func removeClue(at position: GridPosition) {
        numberClues.removeAll { $0.position == position }
        isDirty = true
    }

    func clearAll() {
        numberClues.removeAll()
        isDirty = true
    }

    func validateLevel() -> (isValid: Bool, message: String) {
        if numberClues.isEmpty {
            return (false, "Add some number clues")
        }

        if numberClues.count < 3 {
            return (false, "Add at least 3 clues")
        }

        // Check if all clues have reasonable values
        let totalCells = gridSize.rows * gridSize.cols
        let sumOfClues = numberClues.reduce(0) { $0 + $1.value }

        if sumOfClues != totalCells {
            return (false, "Clue sum (\(sumOfClues)) doesn't match grid size (\(totalCells))")
        }

        return (true, "Level looks good!")
    }

    func estimateDifficulty() -> Int {
        // Simple difficulty estimation based on grid size and clue density
        let totalCells = gridSize.rows * gridSize.cols
        let clueCount = numberClues.count
        let clueRatio = Double(clueCount) / Double(totalCells)

        if clueRatio > 0.4 { return 1 } // Very easy
        if clueRatio > 0.3 { return 2 } // Easy
        if clueRatio > 0.2 { return 3 } // Medium
        if clueRatio > 0.15 { return 4 } // Hard
        return 5 // Very hard
    }

    func exportLevel() -> String {
        let clueData = numberClues.map { clue in
            "\(clue.position.row),\(clue.position.col),\(clue.value)"
        }.joined(separator: ";")

        return "shikaku://\(gridSize.rows)x\(gridSize.cols)/\(clueData)"
    }

    func importLevel(from string: String) -> Bool {
        // Simple import format: "shikaku://9x6/0,1,8;0,5,4;..."
        guard string.hasPrefix("shikaku://") else { return false }

        let content = String(string.dropFirst(10))
        let components = content.components(separatedBy: "/")

        guard components.count == 2 else { return false }

        // Parse grid size
        let sizeComponents = components[0].components(separatedBy: "x")
        guard sizeComponents.count == 2,
              let rows = Int(sizeComponents[0]),
              let cols = Int(sizeComponents[1]) else { return false }

        // Parse clues
        let clueString = components[1]
        var newClues: [NumberClue] = []

        if !clueString.isEmpty {
            let clueComponents = clueString.components(separatedBy: ";")
            for clueData in clueComponents {
                let parts = clueData.components(separatedBy: ",")
                guard parts.count == 3,
                      let row = Int(parts[0]),
                      let col = Int(parts[1]),
                      let value = Int(parts[2]) else { return false }

                newClues.append(NumberClue(
                    position: GridPosition(row: row, col: col),
                    value: value
                ))
            }
        }

        // Apply changes
        gridSize = (rows, cols)
        numberClues = newClues
        isDirty = true

        return true
    }
}

struct ShikakuLevelEditorView: View {
    @State var editor: LevelEditor
    @State private var showingGridSizeSheet = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingClearConfirmation = false
    @State private var importText = ""
    @State private var exportedLevel = ""

    let cellSize: CGFloat = 50

    var body: some View {
        VStack(spacing: 20) {
            headerControls

            Spacer()

            editorGrid
                .containerRelativeFrame([.horizontal, .vertical]) { length, axis in
                    axis == .vertical ? length * 0.6 : length * 0.9
                }

            Spacer()

            bottomControls
        }
        .padding()
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingGridSizeSheet) {
            GridSizeSheet(gridSize: $editor.gridSize)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(levelData: exportedLevel)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportSheet(importText: $importText, editor: editor)
        }
    }

    // MARK: - Header Controls

    private var headerControls: some View {
        VStack(spacing: 16) {
            // Grid size and mode selector
            HStack {
                Button {
                    showingGridSizeSheet = true
                } label: {
                    Text("\(editor.gridSize.rows)×\(editor.gridSize.cols)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .sensoryFeedback(.impact(weight: .light), trigger: showingGridSizeSheet)

                Spacer()

                // Difficulty indicator
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= editor.estimateDifficulty() ? Color.primary : Color.secondary.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                // Edit mode toggle
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            editor.editMode = .addClue
                        }
                    } label: {
                        Text("Add")
                            .font(.caption)
                            .foregroundStyle(editor.editMode == .addClue ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(editor.editMode == .addClue ? Color.primary : Color.clear)
                            )
                    }
                    .sensoryFeedback(.selection, trigger: editor.editMode)

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            editor.editMode = .removeClue
                        }
                    } label: {
                        Text("Remove")
                            .font(.caption)
                            .foregroundStyle(editor.editMode == .removeClue ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(editor.editMode == .removeClue ? Color.primary : Color.clear)
                            )
                    }
                    .sensoryFeedback(.selection, trigger: editor.editMode)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }

            // Number selector (only show in add mode)
            if editor.editMode == .addClue {
                HStack {
                    Text("Number:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(2...20, id: \.self) { number in
                                Button {
                                    withAnimation(.spring(duration: 0.2)) {
                                        editor.selectedNumber = number
                                    }
                                } label: {
                                    Text("\(number)")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(editor.selectedNumber == number ? .white : .primary)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(editor.selectedNumber == number ? Color.primary : Color.secondary.opacity(0.1))
                                        )
                                }
                                .sensoryFeedback(.selection, trigger: editor.selectedNumber)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Editor Grid

    private var editorGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<editor.gridSize.rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<editor.gridSize.cols, id: \.self) { col in
                        editorCellView(row: row, col: col)
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func editorCellView(row: Int, col: Int) -> some View {
        let position = GridPosition(row: row, col: col)
        let clue = editor.numberClues.first { $0.position == position }

        return Button {
            handleCellTap(at: position)
        } label: {
            ZStack {
                Rectangle()
                    .fill(.thinMaterial)
                    .frame(width: cellSize, height: cellSize)

                Rectangle()
                    .stroke(.gray.opacity(0.3), lineWidth: 0.5)
                    .frame(width: cellSize, height: cellSize)

                if let clue = clue {
                    Text("\(clue.value)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                } else if editor.editMode == .addClue {
                    Text("\(editor.selectedNumber)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: editor.numberClues.count)
    }

    private func handleCellTap(at position: GridPosition) {
        switch editor.editMode {
        case .addClue:
            editor.addClue(at: position, value: editor.selectedNumber)
        case .removeClue:
            editor.removeClue(at: position)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Validation status
            let validation = editor.validateLevel()
            HStack {
                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(validation.isValid ? .green : .orange)

                Text(validation.message)
                    .font(.caption)
                    .foregroundStyle(validation.isValid ? .green : .orange)

                Spacer()
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showingImportSheet = true
                } label: {
                    Text("Import")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .sensoryFeedback(.impact(weight: .light), trigger: showingImportSheet)

                Button {
                    exportedLevel = editor.exportLevel()
                    showingExportSheet = true
                } label: {
                    Text("Export")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .disabled(editor.numberClues.isEmpty)
                .sensoryFeedback(.impact(weight: .light), trigger: showingExportSheet)

                Spacer()

                Button {
                    showingClearConfirmation = true
                } label: {
                    Text("Clear")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .disabled(editor.numberClues.isEmpty)
                .confirmationDialog("Clear all clues?", isPresented: $showingClearConfirmation) {
                    Button("Clear", role: .destructive) {
                        withAnimation(.spring(duration: 0.3)) {
                            editor.clearAll()
                        }
                    }
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: editor.numberClues.isEmpty)
            }
        }
    }
}

// MARK: - Supporting Views

struct GridSizeSheet: View {
    @Binding var gridSize: (rows: Int, cols: Int)
    @Environment(\.dismiss) private var dismiss
    @State private var tempRows: Int
    @State private var tempCols: Int

    init(gridSize: Binding<(rows: Int, cols: Int)>) {
        self._gridSize = gridSize
        self._tempRows = State(initialValue: gridSize.wrappedValue.rows)
        self._tempCols = State(initialValue: gridSize.wrappedValue.cols)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Rows: \(tempRows)")
                            .font(.headline)

                        Slider(value: Binding(
                            get: { Double(tempRows) },
                            set: { tempRows = Int($0) }
                        ), in: 4...12, step: 1)
                        .tint(.primary)
                    }

                    VStack(spacing: 12) {
                        Text("Columns: \(tempCols)")
                            .font(.headline)

                        Slider(value: Binding(
                            get: { Double(tempCols) },
                            set: { tempCols = Int($0) }
                        ), in: 4...10, step: 1)
                        .tint(.primary)
                    }
                }

                Text("\(tempRows)×\(tempCols) = \(tempRows * tempCols) cells")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Grid Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        gridSize = (tempRows, tempCols)
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct ExportSheet: View {
    let levelData: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Level Export")
                    .font(.headline)

                Text("Copy this code to share your level:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(levelData)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .textSelection(.enabled)

                Button {
                    UIPasteboard.general.string = levelData
                } label: {
                    Text("Copy to Clipboard")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .sensoryFeedback(.success, trigger: false)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ImportSheet: View {
    @Binding var importText: String
    let editor: LevelEditor
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Import Level")
                    .font(.headline)

                Text("Paste a level code below:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("shikaku://9x6/0,1,8;0,5,4;...", text: $importText, axis: .vertical)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .lineLimit(3...6)

                Button {
                    if editor.importLevel(from: importText) {
                        dismiss()
                    } else {
                        errorMessage = "Invalid level format"
                        showingError = true
                    }
                } label: {
                    Text("Import")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(importText.isEmpty ? Color.secondary.opacity(0.3) : Color.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(importText.isEmpty)
                .sensoryFeedback(.success, trigger: false)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    ShikakuLevelEditorView(editor: LevelEditor())
}
