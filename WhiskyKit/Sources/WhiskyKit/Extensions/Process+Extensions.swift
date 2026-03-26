//
//  Process+Extensions.swift
//  WhiskyKit
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import Foundation
import os.log

public enum ProcessOutput: Hashable {
    case started(Process)
    case message(String)
    case error(String)
    case terminated(Process)
}

public extension Process {
    /// Run the process returning a stream output
    func runStream(name: String, fileHandle: FileHandle?, stealth: Bool = false) throws -> AsyncStream<ProcessOutput> {
        let stream = makeStream(name: name, fileHandle: fileHandle, stealth: stealth)
        self.logProcessInfo(name: name)
        fileHandle?.writeInfo(for: self)
        try run()
        return stream
    }

    private func makeStream(name: String, fileHandle: FileHandle?, stealth: Bool) -> AsyncStream<ProcessOutput> {
        let pipe = Pipe()
        let errorPipe = Pipe()

        if !stealth {
            standardOutput = pipe
            standardError = errorPipe
        } else {
            standardOutput = FileHandle.nullDevice
            standardError = FileHandle.nullDevice
        }

        return AsyncStream<ProcessOutput> { continuation in
            continuation.onTermination = { termination in
                switch termination {
                case .finished:
                    break
                case .cancelled:
                    guard self.isRunning else { return }
                    self.terminate()
                @unknown default:
                    break
                }
            }

            continuation.yield(.started(self))

            if !stealth {
                self.setupReadability(for: pipe, continuation: continuation, isError: false, fileHandle: fileHandle)
                self.setupReadability(for: errorPipe, continuation: continuation, isError: true, fileHandle: fileHandle)
            }

            terminationHandler = { (process: Process) in
                do {
                    if !stealth {
                        _ = try pipe.fileHandleForReading.readToEnd()
                        _ = try errorPipe.fileHandleForReading.readToEnd()
                    }
                    try fileHandle?.close()
                } catch {
                    Logger.wineKit.error("Error while clearing data: \(error)")
                }

                process.logTermination(name: name)
                continuation.yield(.terminated(process))
                continuation.finish()
            }
        }
    }

    private func setupReadability(
        for pipe: Pipe, continuation: AsyncStream<ProcessOutput>.Continuation,
        isError: Bool, fileHandle: FileHandle?
    ) {
        pipe.fileHandleForReading.readabilityHandler = { pipe in
            guard let line = pipe.nextLine() else { return }
            continuation.yield(isError ? .error(line) : .message(line))
            guard !line.isEmpty else { return }
            if isError {
                Logger.wineKit.warning("\(line, privacy: .public)")
            } else {
                Logger.wineKit.info("\(line, privacy: .public)")
            }
            fileHandle?.write(line: line)
        }
    }

    private func logTermination(name: String) {
        if terminationStatus == 0 {
            Logger.wineKit.info(
                "Terminated \(name) with status code '\(self.terminationStatus, privacy: .public)'"
            )
        } else {
            Logger.wineKit.warning(
                "Terminated \(name) with status code '\(self.terminationStatus, privacy: .public)'"
            )
        }
    }

    private func logProcessInfo(name: String) {
        Logger.wineKit.info("Running process \(name)")

        if let arguments = arguments {
            Logger.wineKit.info("Arguments: `\(arguments.joined(separator: " "))`")
        }
        if let executableURL = executableURL {
            Logger.wineKit.info("Executable: `\(executableURL.path(percentEncoded: false))`")
        }
        if let directory = currentDirectoryURL {
            Logger.wineKit.info("Directory: `\(directory.path(percentEncoded: false))`")
        }
        if let environment = environment {
            Logger.wineKit.info("Environment: \(environment)")
        }
    }
}

extension FileHandle {
    func nextLine() -> String? {
        guard let line = String(data: availableData, encoding: .utf8) else { return nil }
        if !line.isEmpty {
            return line
        } else {
            return nil
        }
    }
}
