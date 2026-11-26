import Foundation
import SimBridge

// sim-agentation: the browser UI's server and the MCP server, in one binary.
//
//   sim-agentation serve [--port 38470] [--open]
//   sim-agentation mcp
//   sim-agentation version
//   sim-agentation help

let arguments = Array(CommandLine.arguments.dropFirst())

func option(_ name: String) -> String? {
    guard let i = arguments.firstIndex(of: name), i + 1 < arguments.count else { return nil }
    return arguments[i + 1]
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(1)
}

let command = CLICommand.parse(arguments)

switch command {
case .serve:
    var port = Config.defaultPort
    if let value = option("--port") {
        guard let parsed = UInt16(value) else { fail("sim-agentation: bad --port \(value)") }
        port = parsed
    }
    let store = Store(home: Config.home)
    // Served per request, so `pnpm build` (or `pnpm dev`) shows up on reload.
    let dist = Config.webDirectory.map { Path.join($0, "dist") }
    let app = AppServer(port: port, store: store, chrome: ChromeService(cache: Path.join(Config.cacheDirectory, "chrome")), dist: dist)
    let server: HTTPServer
    do {
        server = try HTTPServer(port: port) { request in await app.handle(request) }
        try await server.start()
    } catch {
        fail("sim-agentation: could not listen on 127.0.0.1:\(port) (\(error)). Is the port in use?")
    }
    if Config.webDirectory == nil {
        FileHandle.standardError.write(Data("sim-agentation: no web/ directory found; set SIM_AGENTATION_WEB\n".utf8))
    } else if let dist, !FileManager.default.fileExists(atPath: Path.join(dist, "index.html")) {
        FileHandle.standardError.write(Data("sim-agentation: the UI isn't built; run `pnpm build` in the repo\n".utf8))
    }
    FileHandle.standardError.write(Data("sim-agentation: http://localhost:\(port)  (data in \(store.home))\n".utf8))
    if arguments.contains("--open") {
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["http://localhost:\(port)"]
        try? open.run()
    }
    // Accessibility (DeviceSession) runs on the main queue, which top-level
    // async code keeps serviced while it sleeps here.
    while true { try await Task.sleep(for: .seconds(3600)) }

case .mcp:
    await MCPServer(port: Config.defaultPort).run()
    exit(0)

case .version:
    // Exactly the version: app/scripts/mcp-launch.sh compares it.
    print(Config.version)

case .help:
    print(CLICommand.usage)

case .unknown, .missingValue:
    fail("sim-agentation: \(command.error ?? "bad arguments")\n\(CLICommand.usage)")
}
