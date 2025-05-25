import Foundation
import os
import PackagePlugin

@main
struct CIMetalPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        var paths: [Path] = []
        target.directory.walk { path in
            if path.pathExtension == "metal" {
                paths.append(path)
            }
        }
        
        let cache = context.pluginWorkDirectory.appending(subpath: "cache")
        let output = context.pluginWorkDirectory.appending(["default.metallib"])
        
        Diagnostics.remark("Running...for \(paths)")
        
        return [
            .buildCommand(
                displayName: "CIMetalCompilerTool",
                executable: try context.tool(named: "CIMetalCompilerTool").path,
                arguments: [
                    "--output", output.string,
                    "--cache", cache,
                ]
                + paths.map(\.string),

                environment: [:],
                inputFiles: paths,
                outputFiles: [
                    output
                ]
            ),
        ]
    }
}

extension Path {
    func walk(_ visitor: (Path) -> Void) {
        let errorHandler = { (_: URL, _: Swift.Error) -> Bool in
            true
        }
        guard let enumerator = FileManager().enumerator(at: url, includingPropertiesForKeys: nil, options: [], errorHandler: errorHandler) else {
            fatalError()
        }
        for url in enumerator {
            guard let url = url as? URL else {
                fatalError()
            }
            let path = Path(url.path)
            visitor(path)
        }
    }

    var url: URL {
        URL(fileURLWithPath: string)
    }

    var pathExtension: String {
        url.pathExtension
    }
}
