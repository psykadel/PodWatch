import Foundation
import IOBluetooth

protocol BluetoothBatteryProviding {
    func fetchSnapshots() async throws -> [BluetoothDeviceSnapshot]
}

struct BluetoothBatteryProvider: BluetoothBatteryProviding {
    private let parser = BluetoothBatteryParser()

    func fetchSnapshots() async throws -> [BluetoothDeviceSnapshot] {
        let result = try await ProcessRunner.run(
            executableURL: URL(fileURLWithPath: "/usr/sbin/system_profiler"),
            arguments: ["SPBluetoothDataType", "-json", "-timeout", "3"]
        )

        guard result.exitCode == 0 else {
            let message = String(data: result.stderr, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw BluetoothBatteryProviderError.commandFailed(message?.isEmpty == false ? message! : "system_profiler failed with exit code \(result.exitCode).")
        }

        let parsedSnapshots = try parser.parse(data: result.stdout)

        return parsedSnapshots.map { snapshot in
            let resolvedName = resolvedFriendlyName(for: snapshot.address)

            return BluetoothDeviceSnapshot(
                name: resolvedName ?? snapshot.name,
                address: snapshot.address,
                isConnected: snapshot.isConnected,
                leftBattery: snapshot.leftBattery,
                rightBattery: snapshot.rightBattery,
                caseBattery: snapshot.caseBattery,
                mainBattery: snapshot.mainBattery
            )
        }
    }

    private func resolvedFriendlyName(for address: String) -> String? {
        let normalizedAddress = normalize(address: address)
        let candidates = [
            normalizedAddress,
            normalizedAddress.replacingOccurrences(of: "-", with: ":")
        ]

        for candidate in candidates {
            guard let device = IOBluetoothDevice(addressString: candidate) else {
                continue
            }

            let preferredName = [device.name as String?, device.nameOrAddress as String?]
                .compactMap { $0?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .first { !$0.isEmpty && normalize(address: $0) != normalizedAddress }

            if let preferredName {
                return preferredName
            }
        }

        return nil
    }

    private func normalize(address: String) -> String {
        address
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: ":", with: "-")
    }
}

enum BluetoothBatteryProviderError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(message):
            return message
        }
    }
}

private struct ProcessExecutionResult {
    let stdout: Data
    let stderr: Data
    let exitCode: Int32
}

private enum ProcessRunner {
    static func run(executableURL: URL, arguments: [String]) async throws -> ProcessExecutionResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = executableURL
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            process.terminationHandler = { terminatedProcess in
                let stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                continuation.resume(returning: ProcessExecutionResult(stdout: stdout, stderr: stderr, exitCode: terminatedProcess.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
