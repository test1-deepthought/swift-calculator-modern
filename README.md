# swift-calculator-modern

A modern SwiftUI scientific calculator with expression graphing, built on a recursive-descent parser engine.

## Features

- **Core engine** — Tokenizer → recursive-descent parser → evaluator with full PEMDAS precedence
- **Scientific functions** — `sqrt`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `log`, `ln`, `abs`, `exp`
- **Constants** — `pi`, `e`
- **Advanced operations** — Exponentiation (`^`), factorial (`!`), modulo (`%`), unary minus
- **Modern dark UI** — GitHub-dark color palette, monospaced display, smooth animations
- **History** — Full expression history with tap-to-replay (side panel on wide screens, sheet on compact)
- **Memory** — Store (`MS`), recall (`MR`), clear (`MC`) with visual indicator
- **Graphing** — Swift Charts-based expression plotter with pan controls and preset functions
- **Keyboard input** — Full keyboard support for rapid entry
- **Adaptive layout** — Side panel on wide screens, sheets on narrow windows

## Project Structure

```
Sources/
├── CalculatorEngine/       # Pure computation library (no UI deps)
│   └── Calculator.swift    # Tokenizer, parser, evaluator, formatter
├── CalculatorCLI/          # CLI test runner
│   └── main.swift
└── CalculatorApp/          # SwiftUI macOS app
    ├── CalculatorApp.swift         # @main entry
    ├── CalculatorViewModel.swift   # State + history + memory
    ├── ContentView.swift           # Button grid + display
    └── GraphView.swift             # Swift Charts expression plotter
```

## Build & Run

```bash
# Full build (macOS 14+ required for Swift Charts)
swift build

# Run the app
swift run CalculatorApp

# Run engine tests
swift run CalculatorCLI
```

## Engine API

```swift
import CalculatorEngine

var calc = Calculator()
print(calc.evaluate("2 + 3 * 4"))        // "14"
print(calc.evaluate("sin(pi/2)"))         // "1"
print(calc.evaluate("sqrt(2^2 + 3^2)"))  // "3.60555127546"
```

## Requirements

- macOS 14+ (Sonoma) or iOS 17+
- Swift 6.3+
- Xcode 16+

## License

MIT
