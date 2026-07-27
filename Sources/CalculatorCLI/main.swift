import Foundation
import CalculatorEngine

var calc = Calculator()

let tests: [(String, String, String)] = [
    // (expression, expected, description)
    ("2+2", "4", "basic addition"),
    ("2+3*4", "14", "operator precedence"),
    ("(2+3)*4", "20", "paren grouping"),
    ("10/3", "3.33333333333", "division"),
    ("5%2", "1", "modulo"),
    ("-5+3", "-2", "unary minus"),
    ("2^10", "1024", "exponentiation"),
    ("sqrt(16)", "4", "sqrt"),
    ("sin(0)", "0", "sin(0)"),
    ("cos(0)", "1", "cos(0)"),
    ("sin(pi/2)", "1", "sin(pi/2)"),
    ("log(100)", "2", "log base 10"),
    ("ln(e)", "1", "natural log of e"),
    ("abs(-42)", "42", "absolute value"),
    ("5!", "120", "factorial"),
    ("2+3*4-8/2", "10", "compound expression"),
    ("(1+2)*(3+4)", "21", "nested parens"),
    ("-3*4", "-12", "negated multiply"),
    ("sqrt(2^2+3^2)", "3.60555127546", "pythagorean"),
    ("2^3^2", "512", "right-associative exp"),
    ("exp(1)", "2.71828182846", "exp"),
    ("0.1+0.2", "0.3", "floating point"),
    ("sin(pi)", "0", "sin(pi)"),
    ("tan(pi/4)", "1", "tan(pi/4)"),
]

var passed = 0
var failed = 0

print("=== CalculatorEngine Test Suite ===\n")

for (expr, expected, desc) in tests {
    let result = calc.evaluate(expr)
    if result.hasPrefix("Error:") {
        if expected.hasPrefix("Error:") {
            passed += 1
            print("PASS: \(desc) — \(expr) = \(result)")
        } else {
            failed += 1
            print("FAIL: \(desc) — \(expr) => \(result) (expected \(expected))")
        }
    } else if let r = Double(result), let e = Double(expected) {
        if abs(r - e) < 0.0001 || result == expected {
            passed += 1
            print("PASS: \(desc) — \(expr) = \(result)")
        } else {
            failed += 1
            print("FAIL: \(desc) — \(expr) => \(result) (expected \(expected))")
        }
    } else {
        if result == expected {
            passed += 1
            print("PASS: \(desc) — \(expr) = \(result)")
        } else {
            failed += 1
            print("FAIL: \(desc) — \(expr) => \(result) (expected \(expected))")
        }
    }
}

// Error tests
let errorTests: [(String, String)] = [
    ("1/0", "Division by zero"),
    ("sqrt(-1)", "sqrt of negative number"),
]
print("\n--- Error handling ---")
for (expr, expectedErr) in errorTests {
    let result = calc.evaluate(expr)
    if result.contains(expectedErr) {
        passed += 1
        print("PASS: \(expr) => \(result)")
    } else {
        failed += 1
        print("FAIL: \(expr) => \(result) (expected error containing '\(expectedErr)')")
    }
}

print("\n=== \(passed)/\(passed+failed) tests passed ===")
