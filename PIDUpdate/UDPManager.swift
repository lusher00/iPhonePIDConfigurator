import Foundation
import Network

struct DebugPacket {
    var magic: UInt32
    var seq: UInt32
    var setpoint: Float
    var error: Float
    var p: Float
    var i: Float
    var d: Float
    var output: Float
}

struct DebugDataPoint: Identifiable {
    let id = UUID()
    let seq: UInt32
    let timestamp: Date
    let setpoint: Float
    let error: Float
    let p: Float
    let i: Float
    let d: Float
    let output: Float
}

class UDPManager: ObservableObject {
    @Published var dataPoints: [DebugDataPoint] = []
    @Published var rawPackets: [Data] = []
    @Published var lostPackets: Int = 0
    @Published var connectionAlive: Bool = false

    private var socketFD: Int32 = -1
    private var listeningQueue = DispatchQueue(label: "udp-listener")
    private var lastSeq: UInt32?
    private let maxPoints = 10000

    private let port: UInt16 = 3333

    init() {
        startListening()
    }

    deinit {
        stopListening()
    }

    private func startListening() {
        socketFD = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socketFD >= 0 else {
            print("Failed to create socket")
            return
        }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr = in_addr(s_addr: INADDR_ANY)

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.stride))
            }
        }

        guard bindResult >= 0 else {
            print("Failed to bind socket")
            close(socketFD)
            socketFD = -1
            return
        }

        connectionAlive = true
        listenForPackets()
        print("Started real UDP listener on port \(port)")
    }

    private func listenForPackets() {
        listeningQueue.async { [weak self] in
            guard let self = self else { return }

            var buffer = [UInt8](repeating: 0, count: 1024)
            while self.socketFD >= 0 {
                let bytesRead = recv(self.socketFD, &buffer, buffer.count, 0)
                if bytesRead > 0 {
                    let packetData = Data(buffer[0..<bytesRead])
                    DispatchQueue.main.async {
                        self.handlePacket(packetData)
                    }
                } else if bytesRead < 0 {
                    print("Socket read error")
                    break
                }
            }
            self.connectionAlive = false
        }
    }

    private func stopListening() {
        if socketFD >= 0 {
            close(socketFD)
            socketFD = -1
        }
    }

    private func handlePacket(_ data: Data) {
        guard data.count == 32 else {
            print("Unexpected packet size: \(data.count)")
            return
        }

        rawPackets.append(data)
        print("dataPoints count: \(self.dataPoints.count)")
        if rawPackets.count > maxPoints {
            rawPackets.removeFirst()
        }

        let packet = data.withUnsafeBytes { ptr -> DebugPacket in
            let values = ptr.bindMemory(to: UInt32.self)
            return DebugPacket(
                magic: UInt32(littleEndian: values[0]),
                seq: UInt32(littleEndian: values[1]),
                setpoint: Float(bitPattern: UInt32(littleEndian: values[2])),
                error: Float(bitPattern: UInt32(littleEndian: values[3])),
                p: Float(bitPattern: UInt32(littleEndian: values[4])),
                i: Float(bitPattern: UInt32(littleEndian: values[5])),
                d: Float(bitPattern: UInt32(littleEndian: values[6])),
                output: Float(bitPattern: UInt32(littleEndian: values[7]))
            )
        }

        guard packet.magic == 0xDEADBEEF else {
            print("Invalid packet magic: \(packet.magic)")
            return
        }

        if let last = self.lastSeq, packet.seq != last + 1 {
            self.lostPackets += Int(packet.seq - last - 1)
        }
        self.lastSeq = packet.seq

        let point = DebugDataPoint(
            seq: packet.seq,
            timestamp: Date(),
            setpoint: packet.setpoint,
            error: packet.error,
            p: packet.p,
            i: packet.i,
            d: packet.d,
            output: packet.output
        )

        self.dataPoints.append(point)
        if self.dataPoints.count > self.maxPoints {
            self.dataPoints.removeFirst()
        }
    }

    func clearData() {
        DispatchQueue.main.async {
            self.dataPoints.removeAll()
            self.rawPackets.removeAll()
            self.lostPackets = 0
            self.lastSeq = nil
        }
    }

    func saveData() -> URL? {
        let header = "seq,timestamp,setpoint,error,p,i,d,output\n"
        let csv = dataPoints.map {
            "\($0.seq),\($0.timestamp.timeIntervalSince1970),\($0.setpoint),\($0.error),\($0.p),\($0.i),\($0.d),\($0.output)"
        }.joined(separator: "\n")

        let finalString = header + csv

        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("debug_data.csv")
            try finalString.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to save CSV: \(error)")
            return nil
        }
    }
}
