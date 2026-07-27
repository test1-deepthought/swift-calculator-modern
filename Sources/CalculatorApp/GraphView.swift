import SwiftUI
import Charts
import CalculatorEngine

struct GraphView: View {
    @EnvironmentObject var viewModel: CalculatorViewModel
    @State private var expression = ""
    @State private var xMin: Double = -10
    @State private var xMax: Double = 10
    @State private var yMin: Double?
    @State private var yMax: Double?
    @State private var points: [GraphPoint] = []
    @State private var errorMessage: String?
    @State private var sampleCount: Double = 200

    private var calculator = Calculator()

    var body: some View {
        VStack(spacing: 0) {
            // Top controls
            HStack {
                Text("GRAPH")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "58A6FF"))

                TextField("y = sin(x)", text: $expression)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "21262D"))
                    .cornerRadius(6)
                    .onSubmit { plot() }

                Button("Plot") { plot() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "1F6FEB"))
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(12)
            .background(Color(hex: "161B22"))

            // Range controls
            HStack(spacing: 16) {
                labeledField("X min", value: $xMin)
                labeledField("X max", value: $xMax)
                labeledField("Samples", value: $sampleCount)
                    .frame(width: 80)
                Spacer()
                if let ymin = yMin, let ymax = yMax {
                    Text("Y: [\(formatShort(ymin)), \(formatShort(ymax))]")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(hex: "484F58"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            // Chart area
            if let error = errorMessage {
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "F85149"))
                    Text(error)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(hex: "F85149"))
                    Spacer()
                }
            } else if points.isEmpty {
                VStack {
                    Spacer()
                    Text("Enter an expression using 'x' and press Plot")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(hex: "484F58"))
                    Text("e.g. sin(x), x^2, sqrt(abs(x))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "3B4148"))
                    Spacer()
                }
            } else {
                Chart {
                    ForEach(points) { pt in
                        LineMark(
                            x: .value("x", pt.x),
                            y: .value("y", pt.y)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "58A6FF"), Color(hex: "7EE787")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        // Zero axis
                        RuleMark(y: .value("zero", 0))
                            .foregroundStyle(Color(hex: "30363D"))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                        RuleMark(x: .value("zero", 0))
                            .foregroundStyle(Color(hex: "30363D"))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .chartXScale(domain: xMin...xMax)
                .chartYScale(domain: (yMin ?? -10)...(yMax ?? 10))
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(hex: "21262D"))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(hex: "484F58"))
                        AxisValueLabel()
                            .foregroundStyle(Color(hex: "484F58"))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(hex: "21262D"))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(hex: "484F58"))
                        AxisValueLabel()
                            .foregroundStyle(Color(hex: "484F58"))
                    }
                }
                .padding(12)
            }

            // Preset buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    presetButton("sin(x)")
                    presetButton("cos(x)")
                    presetButton("tan(x)")
                    presetButton("x^2")
                    presetButton("x^3")
                    presetButton("sqrt(abs(x))")
                    presetButton("exp(x)")
                    presetButton("ln(x)")
                    presetButton("sin(x)*cos(x)")
                    presetButton("1/x")
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 12)
        }
        .background(Color(hex: "0D1117"))
        .preferredColorScheme(.dark)
        .onAppear {
            expression = viewModel.graphExpression
            if !expression.isEmpty { plot() }
        }
    }

    private func labeledField(_ label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(hex: "484F58"))
            TextField("", value: value, format: .number)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 60)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(hex: "21262D"))
                .cornerRadius(4)
        }
    }

    private func presetButton(_ expr: String) -> some View {
        Button(expr) {
            expression = expr
            plot()
        }
        .buttonStyle(.plain)
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(Color(hex: "7EE787"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "1A2332"))
        .cornerRadius(6)
    }

    // MARK: - Plotting

    private func plot() {
        errorMessage = nil
        guard !expression.isEmpty else { points = []; return }

        var calc = Calculator()
        var pts: [GraphPoint] = []
        let n = max(Int(sampleCount), 10)
        let dx = (xMax - xMin) / Double(n - 1)

        for i in 0..<n {
            let x = xMin + Double(i) * dx
            // Replace 'x' in expression with the numeric value
            let exprWithValue = expression.replacingOccurrences(of: "x", with: "(\(formatNumber(x)))")
            let resultStr = calc.evaluate(exprWithValue)

            if resultStr.hasPrefix("Error:") {
                // Skip points that error out (e.g. sqrt of negative)
                continue
            }
            guard let y = Double(resultStr) else { continue }
            // Skip NaN / Inf
            guard y.isFinite else { continue }

            pts.append(GraphPoint(x: x, y: y))
        }

        if pts.isEmpty {
            errorMessage = "No valid points — check domain (e.g. ln(x) needs x>0)"
            points = []
            return
        }

        points = pts
        let ys = pts.map(\.y)
        let padding = max((ys.max()! - ys.min()!) * 0.1, 1)
        yMin = ys.min()! - padding
        yMax = ys.max()! + padding
    }

    private func formatNumber(_ x: Double) -> String {
        if x == floor(x) && abs(x) < 1e15 {
            return String(format: "%.0f", x)
        }
        return String(format: "%.12g", x)
    }

    private func formatShort(_ x: Double) -> String {
        String(format: "%.4g", x)
    }
}

// MARK: - Graph data point

struct GraphPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}

// Needed for Color(hex:) — reused from ContentView
// Already defined in ContentView.swift
