import Foundation

// MARK: - Error Types

public enum CalculatorError: Error, Equatable {
    case divisionByZero
    case moduloByZero
    case invalidNumber(String)
    case invalidExpression(String)
    case mismatchedParentheses
    case unknownFunction(String)

    public var description: String {
        switch self {
        case .divisionByZero:
            return "Division by zero"
        case .moduloByZero:
            return "Modulo by zero"
        case .invalidNumber(let text):
            return "Invalid number: \(text)"
        case .invalidExpression(let text):
            return "Invalid expression: \(text)"
        case .mismatchedParentheses:
            return "Mismatched parentheses"
        case .unknownFunction(let name):
            return "Unknown function: \(name)"
        }
    }
}

// MARK: - Token Types

enum Token: Equatable, CustomStringConvertible {
    case number(Double)
    case plus
    case minus
    case multiply
    case divide
    case modulo
    case power
    case leftParen
    case rightParen
    case function(String)      // sqrt, sin, cos, tan, log, ln, abs, exp
    case constant(String)      // pi, e
    case factorial

    var description: String {
        switch self {
        case .number(let n):  return "\(n)"
        case .plus:           return "+"
        case .minus:          return "-"
        case .multiply:       return "*"
        case .divide:         return "/"
        case .modulo:         return "%"
        case .power:          return "^"
        case .leftParen:      return "("
        case .rightParen:     return ")"
        case .function(let f): return "\(f)("
        case .constant(let c): return c
        case .factorial:      return "!"
        }
    }
}

// MARK: - Tokenizer

struct Tokenizer {
    private let input: String
    private var index: String.Index

    init(input: String) {
        self.input = input
        self.index = input.startIndex
    }

    private var isAtEnd: Bool { index >= input.endIndex }

    private func peek() -> Character? {
        guard !isAtEnd else { return nil }
        return input[index]
    }

    private mutating func advance() -> Character? {
        guard !isAtEnd else { return nil }
        let c = input[index]
        index = input.index(after: index)
        return c
    }

    private mutating func skipWhitespace() {
        while let c = peek(), c.isWhitespace { _ = advance() }
    }

    mutating func tokenize() throws -> [Token] {
        var tokens: [Token] = []
        var expectInfix = false  // tracks whether we expect a binary op or a value

        while let c = peek() {
            skipWhitespace()
            guard let c = peek() else { break }

            if c.isNumber || c == "." {
                tokens.append(try readNumber())
                expectInfix = true
            } else if c.isLetter {
                // Could be: function name (sin, cos, etc.) or constant (pi, e)
                let word = readWord()
                switch word.lowercased() {
                case "pi":
                    tokens.append(.constant("pi"))
                case "e":
                    tokens.append(.constant("e"))
                case "sqrt", "sin", "cos", "tan", "log", "ln", "abs", "exp", "asin", "acos", "atan":
                    tokens.append(.function(word.lowercased()))
                    // function token is a prefix — don't set expectInfix yet
                default:
                    throw CalculatorError.unknownFunction(word)
                }
                expectInfix = true
            } else {
                switch c {
                case "+":
                    if !expectInfix {
                        // unary plus — just skip it
                        _ = advance()
                        continue
                    }
                    tokens.append(.plus)
                    _ = advance()
                    expectInfix = false
                case "-":
                    if !expectInfix {
                        // unary minus — insert -1 * ...
                        _ = advance()
                        tokens.append(.number(-1))
                        tokens.append(.multiply)
                        continue
                    }
                    tokens.append(.minus)
                    _ = advance()
                    expectInfix = false
                case "*":
                    tokens.append(.multiply)
                    _ = advance()
                    expectInfix = false
                case "/":
                    tokens.append(.divide)
                    _ = advance()
                    expectInfix = false
                case "%":
                    tokens.append(.modulo)
                    _ = advance()
                    expectInfix = false
                case "^":
                    tokens.append(.power)
                    _ = advance()
                    expectInfix = false
                case "(":
                    tokens.append(.leftParen)
                    _ = advance()
                    expectInfix = false
                case ")":
                    tokens.append(.rightParen)
                    _ = advance()
                    expectInfix = true
                case "!":
                    tokens.append(.factorial)
                    _ = advance()
                    expectInfix = true
                default:
                    throw CalculatorError.invalidExpression("Unexpected character: '\(c)'")
                }
            }
        }
        return tokens
    }

    private mutating func readNumber() throws -> Token {
        var text = ""
        while let c = peek(), c.isNumber || c == "." {
            text.append(advance()!)
        }
        // Handle scientific notation: 1.5e10
        if let c = peek(), c.lowercased() == "e" {
            text.append(advance()!)
            if let c = peek(), c == "+" || c == "-" { text.append(advance()!) }
            while let c = peek(), c.isNumber { text.append(advance()!) }
        }
        guard let value = Double(text) else {
            throw CalculatorError.invalidNumber(text)
        }
        return .number(value)
    }

    private mutating func readWord() -> String {
        var text = ""
        while let c = peek(), c.isLetter { text.append(advance()!) }
        return text
    }
}

// MARK: - Parser / Evaluator

public struct Calculator {
    private var tokens: [Token]
    private var position: Int

    public init() {
        self.tokens = []
        self.position = 0
    }

    /// Evaluate a mathematical expression string. Returns the result as a formatted string,
    /// or an error description.
    public mutating func evaluate(_ expression: String) -> String {
        do {
            var tokenizer = Tokenizer(input: expression)
            let toks = try tokenizer.tokenize()
            self.tokens = toks
            self.position = 0

            guard !tokens.isEmpty else { return "0" }

            let result = try parseExpression()
            guard position >= tokens.count else {
                throw CalculatorError.invalidExpression("Unexpected token '\(tokens[position])' at position \(position)")
            }
            return formatResult(result)
        } catch let error as CalculatorError {
            return "Error: \(error.description)"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Expression parser (handles + and -)

    private mutating func parseExpression() throws -> Double {
        var left = try parseTerm()
        while position < tokens.count {
            let tok = tokens[position]
            switch tok {
            case .plus:
                position += 1
                left += try parseTerm()
            case .minus:
                position += 1
                left -= try parseTerm()
            default:
                return left
            }
        }
        return left
    }

    // MARK: - Term parser (handles *, /, %, and implicit multiplication after constants)

    private mutating func parseTerm() throws -> Double {
        var left = try parseFactor()
        while position < tokens.count {
            let tok = tokens[position]
            switch tok {
            case .multiply:
                position += 1
                left *= try parseFactor()
            case .divide:
                position += 1
                let rhs = try parseFactor()
                guard rhs != 0 else { throw CalculatorError.divisionByZero }
                left /= rhs
            case .modulo:
                position += 1
                let rhs = try parseFactor()
                guard rhs != 0 else { throw CalculatorError.moduloByZero }
                left = left.truncatingRemainder(dividingBy: rhs)
            default:
                return left
            }
        }
        return left
    }

    // MARK: - Factor parser (handles ^ and !)

    private mutating func parseFactor() throws -> Double {
        var base = try parseExponential()
        while position < tokens.count {
            let tok = tokens[position]
            switch tok {
            case .power:
                position += 1
                let exp = try parseFactor()
                base = pow(base, exp)
            case .factorial:
                position += 1
                guard base >= 0, base == floor(base), base <= 170 else {
                    throw CalculatorError.invalidExpression("Factorial requires non-negative integer ≤ 170")
                }
                base = factorial(Int(base))
            default:
                return base
            }
        }
        return base
    }

    // MARK: - Exponential (handles implicit "^" for scientific notation like 2e5)

    private mutating func parseExponential() throws -> Double {
        return try parsePrimary()
    }

    // MARK: - Primary parser (numbers, parens, functions, constants, unary minus)

    private mutating func parsePrimary() throws -> Double {
        guard position < tokens.count else {
            throw CalculatorError.invalidExpression("Unexpected end of expression")
        }
        let tok = tokens[position]
        switch tok {
        case .number(let n):
            position += 1
            return n

        case .constant(let name):
            position += 1
            switch name {
            case "pi": return Double.pi
            case "e":  return M_E
            default:   throw CalculatorError.unknownFunction(name)
            }

        case .function(let name):
            position += 1
            // Expect '(' value ')'
            guard position < tokens.count, tokens[position] == .leftParen else {
                throw CalculatorError.invalidExpression("Expected '(' after function '\(name)'")
            }
            position += 1
            let arg = try parseExpression()
            guard position < tokens.count, tokens[position] == .rightParen else {
                throw CalculatorError.mismatchedParentheses
            }
            position += 1
            return try applyFunction(name, arg)

        case .leftParen:
            position += 1
            let value = try parseExpression()
            guard position < tokens.count, tokens[position] == .rightParen else {
                throw CalculatorError.mismatchedParentheses
            }
            position += 1
            return value

        default:
            throw CalculatorError.invalidExpression("Unexpected token '\(tok)'")
        }
    }
}

// MARK: - Scientific functions

private func applyFunction(_ name: String, _ arg: Double) throws -> Double {
    switch name {
    case "sqrt":  guard arg >= 0 else { throw CalculatorError.invalidExpression("sqrt of negative number") }; return sqrt(arg)
    case "sin":   return sin(arg)
    case "cos":   return cos(arg)
    case "tan":   return tan(arg)
    case "asin":  guard abs(arg) <= 1 else { throw CalculatorError.invalidExpression("asin requires |x| ≤ 1") }; return asin(arg)
    case "acos":  guard abs(arg) <= 1 else { throw CalculatorError.invalidExpression("acos requires |x| ≤ 1") }; return acos(arg)
    case "atan":  return atan(arg)
    case "log":   guard arg > 0 else { throw CalculatorError.invalidExpression("log of non-positive number") }; return log10(arg)
    case "ln":    guard arg > 0 else { throw CalculatorError.invalidExpression("ln of non-positive number") }; return log(arg)
    case "abs":   return abs(arg)
    case "exp":   return exp(arg)
    default:      throw CalculatorError.unknownFunction(name)
    }
}

// MARK: - Factorial

private func factorial(_ n: Int) -> Double {
    if n <= 1 { return 1 }
    var result: Double = 1
    for i in 2...n { result *= Double(i) }
    return result
}

// MARK: - Result formatting

private func formatResult(_ value: Double) -> String {
    if value.isNaN { return "NaN" }
    if value.isInfinite { return value > 0 ? "Infinity" : "-Infinity" }
    // If it's a whole number, show without decimal
    if value == floor(value) && value.isFinite && abs(value) < 1e15 {
        return String(format: "%.0f", value)
    }
    // Trim trailing zeros
    let s = String(format: "%.12g", value)
    return s
}
