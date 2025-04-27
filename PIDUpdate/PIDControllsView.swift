import SwiftUI

struct PIDControlsView: View {
    @State private var pGain: Float = 0.0
    @State private var iGain: Float = 0.0
    @State private var dGain: Float = 0.0
    @State private var ang: Float = 0.0

    @State private var idx: Int = 1
    @State private var holdPosition: Int = 0

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.alwaysShowsDecimalSeparator = true
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                tuningRow(label: "P", binding: $pGain)
                tuningRow(label: "I", binding: $iGain)
                tuningRow(label: "D", binding: $dGain)
                tuningRow(label: "ANG", binding: $ang)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .frame(maxWidth: .infinity)

            HStack(spacing: 20) {
                Button("Send") {
                    sendPID()
                }
                .buttonStyle(.borderedProminent)

                Button("Receive") {
                    fetchData()
                }
                .buttonStyle(.bordered)
            }

            VStack {
                Text("IDX")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("IDX", selection: $idx) {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("3").tag(3)
                }
                .pickerStyle(.segmented)
            }
            .padding(.top, 4)
        }
        .padding()
    }

    private func tuningRow(label: String, binding: Binding<Float>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: 50, alignment: .leading)

            Button("-") {
                binding.wrappedValue -= 0.01
            }
            .frame(width: 28, height: 28)
            .buttonStyle(.bordered)

            TextField("0.00", value: binding, formatter: numberFormatter)
                .keyboardType(.decimalPad)
                .frame(width: 60, height: 28)
                .padding(.horizontal, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                .multilineTextAlignment(.trailing)

            Button("+") {
                binding.wrappedValue += 0.01
            }
            .frame(width: 28, height: 28)
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    private func sendPID() {
        guard (1...3).contains(idx) else {
            print("Invalid IDX: \(idx)")
            return
        }

        let urlString = String(format: "http://192.168.1.140:3334/params?hold=%d&angAdj=%.3f&index=%d&P=%.3f&I=%.3f&D=%.3f",
                               holdPosition, ang, idx, pGain, iGain, dGain)

        guard let url = URL(string: urlString) else {
            print("Bad URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("HTTP POST error: \(error)")
            } else {
                print("PID values sent successfully")
            }
        }.resume()
    }

    private func fetchData() {
        guard (1...3).contains(idx) else {
            print("Invalid IDX: \(idx)")
            return
        }

        let urlString = "http://192.168.1.140:3334/params?N=\(idx)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    let pairs = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "&")
                    for pair in pairs {
                        let parts = pair.split(separator: "=")
                        if parts.count == 2 {
                            let key = parts[0].lowercased()
                            let valueString = parts[1].trimmingCharacters(in: .whitespaces)
                            switch key {
                            case "pid":
                                if let newIdx = Int(valueString) {
                                    self.idx = newIdx
                                }
                            case "hold":
                                if let hold = Int(valueString) {
                                    self.holdPosition = hold
                                }
                            case "angadj":
                                self.ang = Float(valueString) ?? 0.0
                            case "p":
                                self.pGain = Float(valueString) ?? 0.0
                            case "i":
                                self.iGain = Float(valueString) ?? 0.0
                            case "d":
                                self.dGain = Float(valueString) ?? 0.0
                            default:
                                break
                            }
                        }
                    }
                }
            } else if let error = error {
                print("HTTP GET error: \(error)")
            }
        }.resume()
    }
}
