// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-calculator-modern",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "CalculatorApp", targets: ["CalculatorApp"]),
        .library(name: "CalculatorEngine", targets: ["CalculatorEngine"]),
        .executable(name: "CalculatorCLI", targets: ["CalculatorCLI"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CalculatorEngine",
            path: "Sources/CalculatorEngine"
        ),
        .executableTarget(
            name: "CalculatorCLI",
            dependencies: ["CalculatorEngine"],
            path: "Sources/CalculatorCLI"
        ),
        .executableTarget(
            name: "CalculatorApp",
            dependencies: ["CalculatorEngine"],
            path: "Sources/CalculatorApp"
        )
    ]
)
