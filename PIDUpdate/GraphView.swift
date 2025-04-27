import SwiftUI

struct GraphView: View {
    var dataPoints: [DebugDataPoint]
    @Binding var showSettingsSheet: Bool

    @State private var showSetpoint = true
    @State private var showError = true
    @State private var showP = false
    @State private var showI = false
    @State private var showD = false
    @State private var showOutput = true

    @State private var showKeyPanel = false

    private let colors: [String: Color] = [
        "Setpoint": .blue,
        "Error": .red,
        "P": .green,
        "I": .purple,
        "D": .orange,
        "Output": .black
    ]

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {
                    Canvas { context, size in
                        let visiblePoints = dataPoints.suffix(1000)
                        let pointsArray = Array(visiblePoints)

                        let width = size.width
                        let height = size.height
                        let count = pointsArray.count

                        guard count > 1 else { return }

                        let xStep = width / CGFloat(count - 1)

                        let allValues = pointsArray.flatMap { point -> [Float] in
                            var vals: [Float] = []
                            if showSetpoint { vals.append(point.setpoint) }
                            if showError { vals.append(point.error) }
                            if showP { vals.append(point.p) }
                            if showI { vals.append(point.i) }
                            if showD { vals.append(point.d) }
                            if showOutput { vals.append(point.output) }
                            return vals
                        }

                        guard let minVal = allValues.min(), let maxVal = allValues.max(), maxVal - minVal > 0 else { return }

                        func yPosition(_ value: Float) -> CGFloat {
                            let norm = (value - minVal) / (maxVal - minVal)
                            return height * (1 - CGFloat(norm))
                        }

                        if showSetpoint {
                            drawLine(context: context, points: pointsArray.map { $0.setpoint }, color: colors["Setpoint"] ?? .blue, size: size, xStep: xStep, yFunc: yPosition)
                        }
                        if showError {
                            drawLine(context: context, points: pointsArray.map { $0.error }, color: colors["Error"] ?? .red, size: size, xStep: xStep, yFunc: yPosition)
                        }
                        if showP {
                            drawLine(context: context, points: pointsArray.map { $0.p }, color: colors["P"] ?? .green, size: size, xStep: xStep, yFunc: yPosition)
                        }
                        if showI {
                            drawLine(context: context, points: pointsArray.map { $0.i }, color: colors["I"] ?? .purple, size: size, xStep: xStep, yFunc: yPosition)
                        }
                        if showD {
                            drawLine(context: context, points: pointsArray.map { $0.d }, color: colors["D"] ?? .orange, size: size, xStep: xStep, yFunc: yPosition)
                        }
                        if showOutput {
                            drawLine(context: context, points: pointsArray.map { $0.output }, color: colors["Output"] ?? .black, size: size, xStep: xStep, yFunc: yPosition)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .gesture(DragGesture()
                        .onEnded { value in
                            if value.translation.width < -100 {
                                withAnimation { showKeyPanel = true }
                            } else if value.translation.width > 100 {
                                withAnimation { showKeyPanel = false }
                            }
                        })

                    Button(action: {
                        showSettingsSheet.toggle()
                    }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .padding(8)
                            .foregroundColor(.blue)
                    }
                    .padding([.top, .trailing], 12)

                    if showKeyPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(keyEntries(), id: \.0) { (label, color, value) in
                                HStack(spacing: 6) {
                                    Rectangle()
                                        .fill(color)
                                        .frame(width: 12, height: 12)
                                        .cornerRadius(2)

                                    Text(label)
                                        .font(.caption)

                                    Spacer()

                                    Text(String(format: "%.2f", value))
                                        .font(.caption)
                                        .frame(width: 50, alignment: .trailing)
                                }
                            }
                        }
                        .padding()
                        .frame(width: 160)
                        .background(Color(.systemGray6).opacity(0.95))
                        .cornerRadius(12)
                        .padding(.top, 50)
                        .padding(.trailing, 12)
                        .transition(.move(edge: .trailing))
                        .animation(.easeInOut(duration: 0.3), value: showKeyPanel)
                    }
                }
            }

            scrollableCheckboxes()  // <--- Put the checkboxes back below
                .padding(.bottom)
        }
    }

    @ViewBuilder
    func scrollableCheckboxes() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                checkbox(label: "Set", binding: $showSetpoint)
                checkbox(label: "Err", binding: $showError)
                checkbox(label: "P", binding: $showP)
                checkbox(label: "I", binding: $showI)
                checkbox(label: "D", binding: $showD)
                checkbox(label: "Out", binding: $showOutput)
            }
            .padding()
            .font(.headline)
        }
    }

    func checkbox(label: String, binding: Binding<Bool>) -> some View {
        Toggle(label, isOn: binding)
            .toggleStyle(CheckboxToggleStyle())
    }

    private func keyEntries() -> [(String, Color, Float)] {
        guard let lastPoint = dataPoints.last else { return [] }

        var entries: [(String, Color, Float)] = []

        if showSetpoint {
            entries.append(("Set", colors["Setpoint"] ?? .blue, lastPoint.setpoint))
        }
        if showError {
            entries.append(("Err", colors["Error"] ?? .red, lastPoint.error))
        }
        if showP {
            entries.append(("P", colors["P"] ?? .green, lastPoint.p))
        }
        if showI {
            entries.append(("I", colors["I"] ?? .purple, lastPoint.i))
        }
        if showD {
            entries.append(("D", colors["D"] ?? .orange, lastPoint.d))
        }
        if showOutput {
            entries.append(("Out", colors["Output"] ?? .black, lastPoint.output))
        }

        return entries
    }

    private func drawLine(context: GraphicsContext, points: [Float], color: Color, size: CGSize, xStep: CGFloat, yFunc: (Float) -> CGFloat) {
        var path = Path()
        for (i, value) in points.enumerated() {
            let x = CGFloat(i) * xStep
            let y = yFunc(value)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        context.stroke(path, with: .color(color), lineWidth: 2)
    }
}
