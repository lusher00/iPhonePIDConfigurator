import SwiftUI

struct ContentView: View {
    @State private var index = "0"
    @State private var hold = false
    @State private var angAdj = "0.0"
    @State private var p = "0.0"
    @State private var i = "0.0"
    @State private var d = "0.0"
    @State private var responseText = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                Text("IDX")
                    .frame(width: 80, alignment: .leading)
                    .font(.title2)

                Button("-") {
                    if let val = Int(index), val > 1 {
                        index = String(val - 1)
                    }
                }
                .font(.title2)
                .frame(width: 44, height: 44)

                Text(index)
                    .font(.title2)
                    .frame(width: 80)

                Button("+") {
                    if let val = Int(index), val < 3 {
                        index = String(val + 1)
                    }
                }
                .font(.title2)
                .frame(width: 44, height: 44)
            }

            paramRow(label: "ANG", value: $angAdj)
            paramRow(label: "P", value: $p)
            paramRow(label: "I", value: $i)
            paramRow(label: "D", value: $d)
            HStack {
                Text("HOLD")
                    .frame(width: 80, alignment: .leading)
                    .font(.title2)

                Toggle("", isOn: $hold)
                    .labelsHidden()
            }

            HStack {
                Button("Send") {
                    sendPID()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Receive") {
                    fetchData()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Text("Response:")
                .font(.headline)
                .padding(.top)

            ScrollView {
                Text(responseText)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }


    func sendPID() {
        guard let url = URL(string: "http://192.168.1.140:3334/params") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let body = "hold=\(hold ? "1" : "0")&angAdj=\(angAdj)&index=\(index)&P=\(p)&I=\(i)&D=\(d)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                responseText = String(decoding: data, as: UTF8.self)
            } else if let error = error {
                responseText = "Error: \(error.localizedDescription)"
            }
        }.resume()
    }

    func fetchData() {
        guard let url = URL(string: "http://192.168.1.140:3334/params?index=\(index)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let text = String(data: data, encoding: .utf8) {
                    responseText = text

                    // Try to parse format: PID[2]: angAdj=0.03 P=0.05 I=0.01 D=0.001
                    let pattern = #"PID\[\d+\]:\s*hold=(\d)\s+angAdj=([-\d.]+)\s+P=([-\d.]+)\s+I=([-\d.]+)\s+D=([-\d.]+)"#
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {

                        if let holdRange = Range(match.range(at: 1), in: text),
                           let angRange = Range(match.range(at: 2), in: text),
                           let pRange = Range(match.range(at: 3), in: text),
                           let iRange = Range(match.range(at: 4), in: text),
                           let dRange = Range(match.range(at: 5), in: text) {

                            hold = text[holdRange] == "1"
                            angAdj = String(text[angRange])
                            p = String(text[pRange])
                            i = String(text[iRange])
                            d = String(text[dRange])
                        }
                    }
                    else {
                        print("Regex match failed.")
                    }
                } else if let error = error {
                    responseText = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    @ViewBuilder
    func paramRow(label: String, value: Binding<String>) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(label)
                .frame(width: 80, alignment: .leading)
                .font(.title2)

            Button("-") {
                if let val = Double(value.wrappedValue) {
                    value.wrappedValue = String(format: "%.2f", val - 0.01)
                }
            }
            .font(.title2)
            .frame(width: 44, height: 44)

            TextField("", text: value)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .font(.title2)

            Button("+") {
                if let val = Double(value.wrappedValue) {
                    value.wrappedValue = String(format: "%.2f", val + 0.01)
                }
            }
            .font(.title2)
            .frame(width: 44, height: 44)
        }
    }


}

