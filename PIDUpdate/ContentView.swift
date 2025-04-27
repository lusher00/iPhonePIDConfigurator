import SwiftUI

struct ContentView: View {
    @StateObject private var udpManager = UDPManager()

    @State private var showPIDEditor = true
    @State private var showSettingsSheet = false
    @State private var showRawPackets = false
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    if sizeClass == .regular && showPIDEditor {
                        pidEditor
                            .frame(width: 220)
                            .background(Color(.secondarySystemGroupedBackground))  // <-- FULL gray background for left side
                            .transition(.move(edge: .leading))
                    }

                    graphAndControls
                        .frame(width: sizeClass == .regular && showPIDEditor ? geometry.size.width - 220 : geometry.size.width)
                        .background(Color.white)
                }
                .gesture(dragGesture)
            }
        }
        .background(Color.clear)
        .sheet(isPresented: $showSettingsSheet) {
            settingsSheet
        }
        .sheet(isPresented: $showRawPackets) {
            rawPacketSheet
        }
        .ignoresSafeArea(.container, edges: .horizontal)
    }

    var pidEditor: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                Text("Controls")
                    .font(.title3)
                    .fontWeight(.semibold)

                PIDControlsView()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground)) // Gray box around controls
            .cornerRadius(16)

            Spacer()
        }
    }

    var graphAndControls: some View {
        ZStack(alignment: .topTrailing) {
            GraphView(dataPoints: udpManager.dataPoints, showSettingsSheet: $showSettingsSheet)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .ignoresSafeArea(.container, edges: .horizontal)
        }
    }

    var settingsSheet: some View {
        VStack(spacing: 16) {
            Button("Clear Graph") {
                udpManager.clearData()
                showSettingsSheet = false
            }

            Button("Save CSV") {
                if let url = udpManager.saveData() {
                    let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true)
                }
                showSettingsSheet = false
            }

            Button("View Raw Packets") {
                showRawPackets = true
                showSettingsSheet = false
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    var rawPacketSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(udpManager.rawPackets, id: \.self) { packet in
                    Text(packet.map { String(format: "%02X", $0) }.joined(separator: " "))
                        .font(.system(.caption, design: .monospaced))
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(5)
                }
            }
            .padding()
        }
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                if sizeClass == .regular {
                    if value.translation.width < -100 {
                        withAnimation { showPIDEditor = false }
                    } else if value.translation.width > 100 {
                        withAnimation { showPIDEditor = true }
                    }
                }
            }
    }
}
