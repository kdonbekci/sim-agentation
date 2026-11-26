import Foundation

/// What the command line asks for. Kept apart from main.swift so it can be
/// tested without starting anything.
enum CLICommand: Equatable {
    case serve, mcp, version, help
    case unknown(String)

    static let helpFlags: Set<String> = ["--help", "-h"]
    static let versionFlags: Set<String> = ["--version", "-v"]

    /// No command, or only flags (`--port N --open`), means serve. A help or
    /// version flag wins over serve, so that `--help` never starts a server.
    static func parse(_ arguments: [String]) -> CLICommand {
        guard let first = arguments.first, !first.hasPrefix("-") else {
            return serveUnlessAsked(arguments)
        }
        switch first {
        case "serve": return serveUnlessAsked(arguments)
        case "mcp": return .mcp
        case "version": return .version
        case "help": return .help
        default: return .unknown(first)
        }
    }

    private static func serveUnlessAsked(_ arguments: [String]) -> CLICommand {
        if arguments.contains(where: helpFlags.contains) { return .help }
        if arguments.contains(where: versionFlags.contains) { return .version }
        return .serve
    }

    static let usage = """
    Usage:
      sim-agentation serve [--port N] [--open]   Start the browser UI on http://localhost:\(Config.defaultPort)
      sim-agentation mcp                         Run the MCP server over stdio (for Claude Code, Codex, …)
      sim-agentation version                     Print the version (also --version, -v)
      sim-agentation help                        Print this help (also --help, -h)
    """
}
