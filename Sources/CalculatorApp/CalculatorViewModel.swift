import SwiftUI
import CalculatorEngine

final class CalculatorViewModel: ObservableObject {
    @Published var displayText = "0"
    @Published var expressionText = ""
    @Published var history: [HistoryEntry] = []
    @Published var showGraph = false
    @Published var graphExpression = ""
    @Published var graphError: String?

    private var calculator = Calculator()
    private var memoryValue: Double?
    private var currentInput = ""
    private var lastResult: String = "0"
    private var isShowingResult = false

    var memoryLabel: String {
        if let m = memoryValue {
            return "M=\(formatDisplay(m))"
        }
        return "M"
    }

    // MARK: - Input handling

    func input(_ key: CalculatorKey) {
        switch key {
        case .digit(let d):
            handleDigit(d)
        case .decimal:
            handleDecimal()
        case .operation(let op):
            handleOperation(op)
        case .function(let fn):
            handleFunction(fn)
        case .equals:
            handleEquals()
        case .clear:
            handleClear()
        case .delete:
            handleDelete()
        case .parenLeft:
            handleParen("(")
        case .parenRight:
            handleParen(")")
        case .memoryStore:
            handleMemoryStore()
        case .memoryRecall:
            handleMemoryRecall()
        case .memoryClear:
            handleMemoryClear()
        case .graph:
            handleGraph()
        }
    }

    // MARK: - Private handlers

    private func handleDigit(_ digit: String) {
        if isShowingResult {
            currentInput = digit
            isShowingResult = false
        } else if currentInput == "0" && digit != "0" {
            currentInput = digit
        } else if currentInput == "0" && digit == "0" {
            return
        } else {
            currentInput += digit
        }
        expressionText = currentInput
        displayText = currentInput
    }

    private func handleDecimal() {
        if isShowingResult {
            currentInput = "0."
            isShowingResult = false
        } else if !currentInput.contains(".") {
            if currentInput.isEmpty { currentInput = "0" }
            currentInput += "."
        }
        expressionText = currentInput
        displayText = currentInput
    }

    private func handleOperation(_ op: String) {
        if isShowingResult {
            currentInput = lastResult
            isShowingResult = false
        }
        if let last = currentInput.last, "+-*/%^".contains(last) {
            currentInput.removeLast()
        }
        currentInput += op
        expressionText = currentInput
        displayText = currentInput
    }

    private func handleFunction(_ fn: String) {
        if isShowingResult {
            currentInput = lastResult
            isShowingResult = false
        }
        currentInput += "\(fn)("
        expressionText = currentInput
        displayText = currentInput
    }

    private func handleParen(_ p: String) {
        if isShowingResult {
            currentInput = lastResult
            isShowingResult = false
        }
        currentInput += p
        expressionText = currentInput
        displayText = currentInput
    }

    private func handleEquals() {
        guard !currentInput.isEmpty else { return }
        let result = calculator.evaluate(currentInput)
        displayText = result
        expressionText = currentInput + " ="
        history.append(HistoryEntry(expression: currentInput, result: result))
        lastResult = result
        currentInput = ""
        isShowingResult = true
    }

    private func handleClear() {
        currentInput = ""
        displayText = "0"
        expressionText = ""
        isShowingResult = false
    }

    private func handleDelete() {
        guard !currentInput.isEmpty else { return }
        let funcPatterns = ["sqrt(", "sin(", "cos(", "tan(", "log(", "ln(", "abs(", "exp(", "asin(", "acos(", "atan("]
        for fp in funcPatterns {
            if currentInput.hasSuffix(fp) {
                currentInput.removeLast(fp.count)
                expressionText = currentInput
                displayText = currentInput.isEmpty ? "0" : currentInput
                return
            }
        }
        currentInput.removeLast()
        expressionText = currentInput
        displayText = currentInput.isEmpty ? "0" : currentInput
    }

    private func handleMemoryStore() {
        if let val = Double(lastResult) {
            memoryValue = val
        }
    }

    private func handleMemoryRecall() {
        if let m = memoryValue {
            let repr = formatDisplay(m)
            if isShowingResult {
                currentInput = repr
                isShowingResult = false
            } else {
                currentInput += repr
            }
            expressionText = currentInput
            displayText = currentInput
        }
    }

    private func handleMemoryClear() {
        memoryValue = nil
    }

    func handleGraph() {
        graphExpression = lastResult
        showGraph = true
    }

    // MARK: - Formatting

    func formatDisplay(_ value: Double) -> String {
        if value.isNaN { return "NaN" }
        if value.isInfinite { return value > 0 ? "Infinity" : "-Infinity" }
        if value == floor(value) && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.12g", value)
    }
}

// MARK: - Supporting types

enum CalculatorKey: Equatable {
    case digit(String)
    case decimal
    case operation(String)
    case function(String)
    case equals
    case clear
    case delete
    case parenLeft
    case parenRight
    case memoryStore
    case memoryRecall
    case memoryClear
    case graph
}

struct HistoryEntry: Identifiable, Equatable {
    let id = UUID()
    let expression: String
    let result: String

    var display: String { "\(expression) = \(result)" }
}
