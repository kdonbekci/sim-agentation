import Testing
@testable import sim_agentation

@Suite struct CLITests {
    @Test(arguments: [["help"], ["--help"], ["-h"], ["serve", "--help"], ["--port", "1", "-h"]])
    func help(_ arguments: [String]) {
        #expect(CLICommand.parse(arguments) == .help)
    }

    @Test(arguments: [["version"], ["--version"], ["-v"], ["--port", "1", "--version"]])
    func version(_ arguments: [String]) {
        #expect(CLICommand.parse(arguments) == .version)
    }

    /// Flags without a command still mean serve: `sim-agentation --port N --open`.
    @Test(arguments: [[], ["serve"], ["serve", "--port", "1", "--open"], ["--port", "1", "--open"], ["--open"]])
    func serve(_ arguments: [String]) {
        #expect(CLICommand.parse(arguments) == .serve)
    }

    @Test func mcp() {
        #expect(CLICommand.parse(["mcp"]) == .mcp)
    }

    @Test func unknown() {
        #expect(CLICommand.parse(["bogus"]) == .unknown("bogus"))
        #expect(CLICommand.parse(["bogus", "--help"]) == .unknown("bogus"))
    }

    @Test func usageNamesEveryCommand() {
        for word in ["serve", "mcp", "version", "help", "--help", "--version"] {
            #expect(CLICommand.usage.contains(word))
        }
    }
}
