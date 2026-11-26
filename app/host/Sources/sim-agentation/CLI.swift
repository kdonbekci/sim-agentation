import Foundation

/// What the command line asks for. Kept apart from main.swift so it can be
/// tested without starting anything.
enum CLICommand: Equatable {
    case serve, mcp, version, help
    /// An argument no command takes: a misspelt command or flag, or a stray word.
    case unknown(String)
    /// An option given without its value, such as a trailing `--port`.
    case missingValue(String)

    static let helpFlags: Set<String> = ["--help", "-h"]
    static let versionFlags: Set<String> = ["--version", "-v"]

    /// The options each command takes, and whether each one takes a value.
    /// Anything else is an error rather than ignored: serve never returns, so
    /// an ignored typo such as `-help` or `--Help` would start a server that
    /// prints a banner and sleeps.
    static let serveOptions: [String: Bool] = ["--port": true, "--open": false]
    static let mcpOptions: [String: Bool] = [:]

    /// No command, or only serve's options (`--port N --open`), means serve.
    /// After serve or mcp, a help or version flag anywhere wins (help first),
    /// so `serve --port N --help` prints help instead of serving.
    static func parse(_ arguments: [String]) -> CLICommand {
        guard let first = arguments.first else { return .serve }
        switch first {
        case "help": return .help
        case "version": return .version
        case "serve": return check(.serve, arguments.dropFirst(), allowing: serveOptions)
        case "mcp": return check(.mcp, arguments.dropFirst(), allowing: mcpOptions)
        case _ where first.hasPrefix("-"): return check(.serve, arguments[...], allowing: serveOptions)
        default: return .unknown(first)
        }
    }

    private static func check(_ command: CLICommand, _ arguments: ArraySlice<String>, allowing options: [String: Bool]) -> CLICommand {
        if arguments.contains(where: helpFlags.contains) { return .help }
        if arguments.contains(where: versionFlags.contains) { return .version }
        var rest = arguments
        while let argument = rest.popFirst() {
            guard let takesValue = options[argument] else { return .unknown(argument) }
            if takesValue {
                guard let value = rest.popFirst(), !value.hasPrefix("-") else { return .missingValue(argument) }
            }
        }
        return command
    }

    /// What main prints, with the usage, before exiting 1. Nil for a command that runs.
    var error: String? {
        switch self {
        case .unknown(let argument): "unknown argument '\(argument)'"
        case .missingValue(let option): "\(option) needs a value"
        case .serve, .mcp, .version, .help: nil
        }
    }

    static let usage = """
    Usage:
      sim-agentation serve [--port N] [--open]   Start the browser UI on http://localhost:\(Config.defaultPort)
      sim-agentation mcp                         Run the MCP server over stdio (for Claude Code, Codex, …)
      sim-agentation version                     Print the version (also --version, -v)
      sim-agentation help                        Print this help (also --help, -h)
    """
}
