import SwiftUI

struct PIDControlsView: View {
    @State private var index = "0"
    @State private var angAdj = "0.0"
    @State private var p = "0.0"
    @State private var i = "0.0"
    @State private var d = "0.0"
    @State private var responseText = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Text("IDX")
                    .frame(width: 50, alignment: .leading)
                    .font(.title3)

                Button("-") {
                    if let val = Int(index), val > 1 {
                        index = String(val - 1)
                    }
                }
                .font(.title3)
                .frame(width: 32, height: 32)

                Text(index)
                    .frame(width: 40)
                    .font(.title3)

                Button("+") {
                    if let val = Int(index), val < 3 {
                        index = String(val + 1)
                    }
                }
                .font(.title3)
                .frame(width: 32, height: 32)
            }

            paramRow(label: "ANG", value: $angAdj)
            paramRow(label: "P", value: $p)
            paramRow(label: "I", value: $i)
            paramRow(label: "D", value: $d)

            HStack(spacing: 20) {
                Button("Send") {
                    sendPID()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Receive") {
                    fetchData()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            Spacer()
        }
        //.padding()
    }

    func sendPID() {
        guard let url = URL(string: "http://192.168.1.140:3334/params") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let body = "angAdj=\(angAdj)&index=\(index)&P=\(p)&I=\(i)&D=\(d)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                DispatchQueue.main.async {
                    responseText = String(decoding: data, as: UTF8.self)
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    responseText = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func fetchData() {
        guard let url = URL(string: "http://192.168.1.140:3334/params?index=\(index)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let text = String(data: data, encoding: .utf8) {
                    responseText = text

                    let pattern = #"PID\[\d+\]:\s*angAdj=([-\d.]+)\s+P=([-\d.]+)\s+I=([-\d.]+)\s+D=([-\d.]+)"#
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {

                        if let angRange = Range(match.range(at: 1), in: text),
                           let pRange = Range(match.range(at: 2), in: text),
                           let iRange = Range(match.range(at: 3), in: text),
                           let dRange = Range(match.range(at: 4), in: text) {

                            angAdj = String(text[angRange])
                            p = String(text[pRange])
                            i = String(text[iRange])
                            d = String(text[dRange])
                        }
                    }
                } else if let error = error {
                    responseText = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    @ViewBuilder
    func paramRow(label: String, value: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: 50, alignment: .leading)
                .font(.title3)

            Button("-") {
                if let val = Double(value.wrappedValue) {
                    value.wrappedValue = String(format: "%.2f", val - 0.01)
                }
            }
            .font(.title3)
            .frame(width: 32, height: 32)

            TextField("", text: value)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
                .font(.title3)

            Button("+") {
                if let val = Double(value.wrappedValue) {
                    value.wrappedValue = String(format: "%.2f", val + 0.01)
                }
            }
            .font(.title3)
            .frame(width: 32, height: 32)
        }
    }
}
