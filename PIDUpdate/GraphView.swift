//
//  GraphView.swift
//  
//
//  Created by Ryan Lush on 4/26/25.
//

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

    var body: some View {
        VStack(spacing: 0) {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)  // <-- FORCE canvas to fill
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
                Toggle("Err", isOn: $showError)
                Toggle("P", isOn: $showP)
                Toggle("I", isOn: $showI)
                Toggle("D", isOn: $showD)
                Toggle("Out", isOn: $showOutput)
            }
            .padding()
            .font(.headline)  // << MOVE IT HERE attached to the HStack!
        }
    }

    func drawLine(context: GraphicsContext, points: [Float], color: Color, size: CGSize, xStep: CGFloat, yFunc: (Float) -> CGFloat) {
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
