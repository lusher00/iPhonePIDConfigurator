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

    private let colors: [String: Color] = [
        "Setpoint": .blue,
        "Error": .red,
        "P": .green,
        "I": .purple,
        "D": .orange,
        "Output": .black
    ]

    let sampleRateHz: Double = 100.0 // 100Hz

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Canvas { context, size in
                    let pointsArray = Array(dataPoints.suffix(1000))

                    guard pointsArray.count > 1 else { return }

                    let width = size.width
                    let height = size.height
                    let count = pointsArray.count
                    let xStep = width / CGFloat(count - 1)

                    // Find maximum absolute value for Y scaling
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

                    guard let maxAbsValue = allValues.map({ abs($0) }).max(), maxAbsValue > 0 else { return }

                    func yPosition(_ value: Float) -> CGFloat {
                        let norm = CGFloat(value) / CGFloat(maxAbsValue)
                        return height/2 - norm * height/2
                    }

                    func xPosition(index: Int) -> CGFloat {
                        return CGFloat(index) * xStep
                    }

                    // Draw Y=0 axis
                    var zeroAxis = Path()
                    zeroAxis.move(to: CGPoint(x: 0, y: height/2))
                    zeroAxis.addLine(to: CGPoint(x: width, y: height/2))
                    context.stroke(zeroAxis, with: .color(.gray), lineWidth: 1)

                    // Draw Y ticks
                    let yTickValues: [Float] = [-1.0, -0.5, 0.0, 0.5, 1.0]
                    for v in yTickValues {
                        let y = yPosition(v * Float(maxAbsValue))
                        var tick = Path()
                        tick.move(to: CGPoint(x: 0, y: y))
                        tick.addLine(to: CGPoint(x: 10, y: y))
                        context.stroke(tick, with: .color(.gray), lineWidth: 1)

                        let text = Text(String(format: "%.1f", v * maxAbsValue))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        context.draw(text, at: CGPoint(x: 15, y: y - 6))
                    }

                    // Draw X ticks based on total seconds
                    let totalSeconds = Double(dataPoints.count) / sampleRateHz
                    let numSeconds = Int(totalSeconds) + 1

                    for sec in 0...numSeconds {
                        let indexAtSecond = Int(Double(sec) * sampleRateHz)
                        if indexAtSecond < count {
                            let x = xPosition(index: indexAtSecond)
                            var tick = Path()
                            tick.move(to: CGPoint(x: x, y: height - 10))
                            tick.addLine(to: CGPoint(x: x, y: height))
                            context.stroke(tick, with: .color(.gray), lineWidth: 1)

                            let text = Text("\(sec)")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            context.draw(text, at: CGPoint(x: x + 2, y: height - 18))
                        }
                    }

                    // Draw graph lines
                    if showSetpoint {
                        drawLine(context: context, points: pointsArray.map { $0.setpoint }, color: colors["Setpoint"] ?? .blue, xFunc: xPosition, yFunc: yPosition)
                    }
                    if showError {
                        drawLine(context: context, points: pointsArray.map { $0.error }, color: colors["Error"] ?? .red, xFunc: xPosition, yFunc: yPosition)
                    }
                    if showP {
                        drawLine(context: context, points: pointsArray.map { $0.p }, color: colors["P"] ?? .green, xFunc: xPosition, yFunc: yPosition)
                    }
                    if showI {
                        drawLine(context: context, points: pointsArray.map { $0.i }, color: colors["I"] ?? .purple, xFunc: xPosition, yFunc: yPosition)
                    }
                    if showD {
                        drawLine(context: context, points: pointsArray.map { $0.d }, color: colors["D"] ?? .orange, xFunc: xPosition, yFunc: yPosition)
                    }
                    if showOutput {
                        drawLine(context: context, points: pointsArray.map { $0.output }, color: colors["Output"] ?? .black, xFunc: xPosition, yFunc: yPosition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)

                Button(action: {
                    showSettingsSheet.toggle()
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .padding(8)
                        .padding(.trailing, 12)
                        .foregroundColor(.blue)
                }
            }

            scrollableCheckboxes()
                .padding(.bottom)
        }
    }

    @ViewBuilder
    func scrollableCheckboxes() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                Toggle("Set", isOn: $showSetpoint)
                    .toggleStyle(CheckboxToggleStyle())
                Toggle("Err", isOn: $showError)
                    .toggleStyle(CheckboxToggleStyle())
                Toggle("P", isOn: $showP)
                    .toggleStyle(CheckboxToggleStyle())
                Toggle("I", isOn: $showI)
                    .toggleStyle(CheckboxToggleStyle())
                Toggle("D", isOn: $showD)
                    .toggleStyle(CheckboxToggleStyle())
                Toggle("Out", isOn: $showOutput)
                    .toggleStyle(CheckboxToggleStyle())
            }
            .padding()
            .font(.headline)
        }
    }

    func drawLine(context: GraphicsContext, points: [Float], color: Color, xFunc: (Int) -> CGFloat, yFunc: (Float) -> CGFloat) {
        var path = Path()
        for (i, value) in points.enumerated() {
            let x = xFunc(i)
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
