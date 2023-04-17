//
// Created by Yelshat Duskaliyev on 17.04.2023.
//

import Foundation
import Network

class UDPSender {
    var connection: NWConnection
    var host: NWEndpoint.Host
    var port: NWEndpoint.Port

    init(hostPort: String) {
        let parts = hostPort.split(separator: ":")
        self.host = NWEndpoint.Host(String(parts[0]))
        self.port = NWEndpoint.Port(String(parts[1]))!

        NSLog("[DEBUG] starting broadcaster to host: \(host), port: \(port)")
        connection = NWConnection(host: host, port: port, using: .udp)
        connection.stateUpdateHandler = { newState in
            switch (newState) {
            case .ready:
                NSLog("[DEBUG] connection state: ready")
            case .setup:
                NSLog("[DEBUG] connection state: setup")
            case .cancelled:
                NSLog("[DEBUG] connection state: canceled")
            case .preparing:
                NSLog("[DEBUG] connection state: preparing")
            default:
                NSLog("[ERROR] connection state is not defined")
            }
        }
        connection.start(queue: .global())
    }

    deinit {
        connection.cancel()
    }

    func start() {
        connection.start(queue: .main)
    }

    func send(packet: Packet) {
        let bytes = packet.toBytes()
        connection.send(content: bytes, completion: .contentProcessed({ error in
            NSLog("[DEBUG] sent completed")
            if let error = error {
                NSLog("[ERROR] sending packet: \(error)")
            }
        }))
    }
}

struct Packet {
    var arucos: [ArucoPacket]
    var timeElapsed: Double
    var ts: Double

    func toBytes() -> [UInt8] {
        var bytes = [UInt8]()
        bytes.append(contentsOf: arucos.count.toBytes())
        for aruco in arucos {
            bytes.append(contentsOf: aruco.toBytes())
        }
        bytes.append(contentsOf: timeElapsed.toBytes())
        bytes.append(contentsOf: ts.toBytes())
        return bytes
    }
}

struct ArucoPacket {
    var id: Int
    var position: FloatTriple
    var orientation: FloatTriple

    func toBytes() -> [UInt8] {
        var bytes = [UInt8]()
        bytes.append(contentsOf: id.toBytes())
        bytes.append(contentsOf: position.toBytes())
        bytes.append(contentsOf: orientation.toBytes())
        return bytes
    }
}

struct FloatTriple {
    var x: Float
    var y: Float
    var z: Float

    func toBytes() -> [UInt8] {
        var bytes = [UInt8]()
        bytes.append(contentsOf: x.toBytes())
        bytes.append(contentsOf: y.toBytes())
        bytes.append(contentsOf: z.toBytes())
        return bytes
    }
}
extension Double {
    func toBytes() -> [UInt8] {
        var value = self
        return withUnsafeBytes(of: &value) { Array($0) }
    }
}

extension Float {
    func toBytes() -> [UInt8] {
        var value = self
        return withUnsafeBytes(of: &value) { Array($0) }
    }
}

extension Int {
    func toBytes() -> [UInt8] {
        var value = self
        return withUnsafeBytes(of: &value) { Array($0) }
    }
}

