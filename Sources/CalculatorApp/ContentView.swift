import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: CalculatorViewModel
    @State private var showHistory = false
    @State private var displayScale: CGFloat = 1.0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 500
            HStack(spacing: 0) {
                // Main calculator
                VStack(spacing: 0) {
                    displaySection
                    buttonGrid
                }
                .frame(minWidth: 340, maxWidth: isWide ? 420 : .infinity)

                // Side panel: history + graph
                if isWide {
                    sidePanel
                        .frame(width: 300)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
        .background(Color(hex: "0D1117"))
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showHistory) {
            historySheet
        }
        .sheet(isPresented: $viewModel.showGraph) {
            GraphView()
                .environmentObject(viewModel)
                .frame(minWidth: 600, idealWidth: 800, minHeight: 500, idealHeight: 600)
        }
        .onAppear { NSEvent.addLocalMonitorForEvents(matching: .keyDown) { handleKey($0) } }
    }

    // MARK: - Display

    private var displaySection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Expression line
            Text(viewModel.expressionText)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(Color(hex: "8B949E"))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)

            // Result line
            Text(viewModel.displayText)
                .font(.system(size: 48, weight: .thin, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .scaleEffect(displayScale)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: displayScale)

            // Memory indicator
            HStack {
                if viewModel.memoryLabel != "M" {
                    Text(viewModel.memoryLabel)
                        .font(.caption)
                        .foregroundColor(Color(hex: "58A6FF"))
                }
                Spacer()
                Text("DEG")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "484F58"))
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(hex: "161B22"))
    }

    // MARK: - Button Grid

    private var buttonGrid: some View {
        let rows: [[CalcButton]] = [
            // Row 0: function keys
            [
                CalcButton("C", .clear, color: .danger),
                CalcButton("⌫", .delete, color: .danger),
                CalcButton("(", .parenLeft, color: .function),
                CalcButton(")", .parenRight, color: .function),
                CalcButton("/", .operation("/"), color: .operator),
            ],
            // Row 1: scientific + multiply
            [
                CalcButton("x²", .function("²"), color: .function),
                CalcButton("√", .function("sqrt"), color: .function),
                CalcButton("^", .operation("^"), color: .function),
                CalcButton("log", .function("log"), color: .function),
                CalcButton("ln", .function("ln"), color: .function),
            ],
            // Row 2: trig + percent
            [
                CalcButton("sin", .function("sin"), color: .function),
                CalcButton("cos", .function("cos"), color: .function),
                CalcButton("tan", .function("tan"), color: .function),
                CalcButton("π", .digit("pi"), color: .function),
                CalcButton("e", .digit("e"), color: .function),
            ],
            // Row 3: digits + memory
            [
                CalcButton("7", .digit("7")),
                CalcButton("8", .digit("8")),
                CalcButton("9", .digit("9")),
                CalcButton("MS", .memoryStore, color: .memory),
                CalcButton("MR", .memoryRecall, color: .memory),
            ],
            // Row 4
            [
                CalcButton("4", .digit("4")),
                CalcButton("5", .digit("5")),
                CalcButton("6", .digit("6")),
                CalcButton("*", .operation("*"), color: .operator),
                CalcButton("%", .operation("%"), color: .operator),
            ],
            // Row 5
            [
                CalcButton("1", .digit("1")),
                CalcButton("2", .digit("2")),
                CalcButton("3", .digit("3")),
                CalcButton("-", .operation("-"), color: .operator),
                CalcButton("MC", .memoryClear, color: .memory),
            ],
            // Row 6
            [
                CalcButton("0", .digit("0"), span: 2),
                CalcButton(".", .decimal),
                CalcButton("+", .operation("+"), color: .operator),
                CalcButton("=", .equals, color: .equals),
            ],
        ]

        return VStack(spacing: 0) {
            // Tab bar: Calc / History / Graph
            HStack(spacing: 0) {
                tabButton("CALC", selected: true) {}
                tabButton("HIST", selected: false) { showHistory = true }
                tabButton("GRAPH", selected: false) { viewModel.handleGraph(); viewModel.showGraph = true }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(rows.flatMap { $0 }) { btn in
                    calcButtonView(btn)
                }
            }
            .padding(12)
        }
        .background(Color(hex: "0D1117"))
    }

    private func calcButtonView(_ btn: CalcButton) -> some View {
        Button(action: {
            handleTap(btn)
        }) {
            Text(btn.label)
                .font(.system(size: btn.label.count > 2 ? 14 : 20, weight: .medium, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 48)
                .background(btn.backgroundColor)
                .foregroundColor(btn.foregroundColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(btn.borderColor, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .gridCellColumns(btn.span)
    }

    private func handleTap(_ btn: CalcButton) {
        // Animate display
        displayScale = 1.05
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            displayScale = 1.0
        }

        switch btn.action {
        case .digit(let d):
            if d == "pi" {
                viewModel.input(.digit("3.14159265359"))
            } else if d == "e" {
                viewModel.input(.digit("2.71828182846"))
            } else {
                viewModel.input(.digit(d))
            }
        case .function(let fn):
            if fn == "²" {
                // Square: append ^2
                viewModel.input(.operation("^2"))
            } else {
                viewModel.input(.function(fn))
            }
        default:
            switch btn.action {
            case .operation(let op): viewModel.input(.operation(op))
            case .equals:            viewModel.input(.equals)
            case .clear:             viewModel.input(.clear)
            case .delete:            viewModel.input(.delete)
            case .parenLeft:         viewModel.input(.parenLeft)
            case .parenRight:        viewModel.input(.parenRight)
            case .memoryStore:       viewModel.input(.memoryStore)
            case .memoryRecall:      viewModel.input(.memoryRecall)
            case .memoryClear:       viewModel.input(.memoryClear)
            default: break
            }
        }
    }

    // MARK: - Tab bar

    private func tabButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(selected ? Color(hex: "58A6FF") : Color(hex: "484F58"))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Side panel (wide layout)

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("HISTORY")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "58A6FF"))
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.history.reversed()) { entry in
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(entry.expression)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Color(hex: "8B949E"))
                            Text(entry.result)
                                .font(.system(size: 20, weight: .light, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .onTapGesture {
                            // Replay expression
                            let expr = entry.expression
                            viewModel.input(.clear)
                            for ch in expr {
                                viewModel.input(.digit(String(ch)))
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            Spacer()
        }
    }

    // MARK: - History sheet (narrow layout)

    private var historySheet: some View {
        NavigationView {
            List(viewModel.history.reversed()) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.expression)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(entry.result)
                        .font(.system(size: 22, weight: .light, design: .monospaced))
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("History")
        }
        .frame(minWidth: 300, minHeight: 400)
    }

    // MARK: - Keyboard handling

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        guard event.type == .keyDown, let chars = event.characters else { return event }
        switch chars {
        case "0"..."9":
            viewModel.input(.digit(chars))
        case ".":              viewModel.input(.decimal)
        case "+":              viewModel.input(.operation("+"))
        case "-":              viewModel.input(.operation("-"))
        case "*":              viewModel.input(.operation("*"))
        case "/":              viewModel.input(.operation("/"))
        case "%":              viewModel.input(.operation("%"))
        case "^":              viewModel.input(.operation("^"))
        case "(":              viewModel.input(.parenLeft)
        case ")":              viewModel.input(.parenRight)
        case "\r", "\n":       viewModel.input(.equals)
        case "\u{7F}":         viewModel.input(.delete) // backspace
        case "\u{1B}":         viewModel.input(.clear)  // escape
        default: return event
        }
        return nil
    }
}

// MARK: - CalcButton model

struct CalcButton: Identifiable {
    let id = UUID()
    let label: String
    let action: ButtonAction
    let color: ButtonColor
    let span: Int

    init(_ label: String, _ action: ButtonAction, color: ButtonColor = .normal, span: Int = 1) {
        self.label = label
        self.action = action
        self.color = color
        self.span = span
    }

    var backgroundColor: Color {
        switch color {
        case .normal:   return Color(hex: "21262D")
        case .operator: return Color(hex: "1F2937")
        case .function: return Color(hex: "1A2332")
        case .equals:   return Color(hex: "1F6FEB")
        case .danger:   return Color(hex: "2D1B1B")
        case .memory:   return Color(hex: "1B2D1B")
        }
    }

    var foregroundColor: Color {
        switch color {
        case .normal:   return .white
        case .operator: return Color(hex: "58A6FF")
        case .function: return Color(hex: "7EE787")
        case .equals:   return .white
        case .danger:   return Color(hex: "F85149")
        case .memory:   return Color(hex: "3FB950")
        }
    }

    var borderColor: Color {
        switch color {
        case .equals: return Color(hex: "58A6FF")
        default:      return Color.white.opacity(0.06)
        }
    }
}

enum ButtonAction: Equatable {
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

enum ButtonColor {
    case normal, `operator`, function, equals, danger, memory
}

// MARK: - Color helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
