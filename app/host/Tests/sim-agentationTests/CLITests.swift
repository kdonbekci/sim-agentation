import Testing
@testable import sim_agentation

@Suite struct CLITests {
    @Test(arguments: [
        ["help"], ["--help"], ["-h"], ["help", "extra"],
        ["serve", "--help"], ["serve", "-h"], ["--port", "1", "-h"], ["--open", "--help"],
        ["--help", "--version"], ["--version", "--help"], ["--bogus", "--help"], ["serve", "bogus", "-h"],
        ["mcp", "--help"],
    ])
    func help(_ arguments: [String]) {
        #expect(CLICommand.parse(arguments) == .help)
    }

    @Test(arguments: [
        ["version"], ["--version"], ["-v"], ["version", "--help"],
        ["serve", "--version"], ["--port", "1", "--version"], ["mcp", "-v"],
    ])
    func version(_ arguments: [String]) {
        #expect(CLICommand.parse(arguments) == .version)
    }

    /// Serve's own options without a command still mean serve: `sim-agentation --port N --open`.
    @Test(arguments: [
        [], ["serve"], ["serve", "--open"], ["serve", "--port", "1", "--open"],
        ["--port", "1", "--open"], ["--open", "--port", "1"], ["--open"], ["--port", "38470"],
    ])
    func serve(_ arguments: [String]) {
        #expect(CLICommand.parse(arguments) == .serve)
    }

    @Test func mcp() {
        #expect(CLICommand.parse(["mcp"]) == .mcp)
    }

    /// Each case and the argument it should name. Typed, so the compiler
    /// needn't infer the tuples' type.
    static let unknownCases: [([String], String)] = [
        (["bogus"], "bogus"), (["bogus", "--help"], "bogus"),
        (["--bogus"], "--bogus"), (["-x"], "-x"), (["-help"], "-help"), (["--Help"], "--Help"),
        (["-version"], "-version"), (["--port=1"], "--port=1"), (["--open", "--bogus"], "--bogus"),
        (["serve", "bogus"], "bogus"), (["serve", "--port", "1", "extra"], "extra"),
        (["serve", "serve"], "serve"), (["mcp", "bogus"], "bogus"), (["mcp", "--port", "1"], "--port"),
    ]

    /// Anything a command doesn't take is an error, never ignored: an ignored
    /// argument would start a server that never returns.
    @Test(arguments: unknownCases)
    func unknown(_ arguments: [String], _ argument: String) {
        #expect(CLICommand.parse(arguments) == .unknown(argument))
        #expect(CLICommand.parse(arguments).error == "unknown argument '\(argument)'")
    }

    @Test(arguments: [["--port"], ["serve", "--port"], ["--port", "--open"], ["serve", "--port", "-1"]])
    func missingValue(_ arguments: [String]) {
        #expect(CLICommand.parse(arguments) == .missingValue("--port"))
        #expect(CLICommand.parse(arguments).error == "--port needs a value")
    }

    @Test func onlyErrorsHaveAMessage() {
        for command in [CLICommand.serve, .mcp, .version, .help] {
            #expect(command.error == nil)
        }
    }

    @Test func usageNamesEveryCommandAndOption() {
        for word in ["serve", "mcp", "version", "help", "--help", "--version", "-h", "-v"] {
            #expect(CLICommand.usage.contains(word))
        }
        for option in CLICommand.serveOptions.keys {
            #expect(CLICommand.usage.contains(option))
        }
    }
}
