import Foundation
import Testing

@Suite("Script sinh token")
struct GeneratorCheckTests {
    @Test("--check không lệch với tokens.json")
    func checkModeReportsNoDrift() throws {
        let process = Process()
        process.executableURL = RepositoryPaths.python
        process.arguments = [RepositoryPaths.generatorScript.path, "--check"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        let log = String(bytes: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        #expect(process.terminationStatus == 0, "\(log)")
    }
}
