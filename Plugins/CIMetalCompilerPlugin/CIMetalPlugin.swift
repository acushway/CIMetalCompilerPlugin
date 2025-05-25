import Foundation
import os
import PackagePlugin

@main
struct CIMetalPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        var paths: [URL] = []
        target.directory.walk { path in
            if path.pathExtension == "metal" {
                paths.append(path)
            }
        }
        
        let cache = context.pluginWorkDirectoryURL.appending(path: "cache")
        let output = context.pluginWorkDirectoryURL.appending(path: "default.metallib")
                
        Diagnostics.remark("Running...for \(paths)")
        
        return [
            .buildCommand(
                displayName: "CIMetalCompilerTool",
                executable: try context.tool(named: "CIMetalCompilerTool").url,
                arguments: [
                    "--output", output.path(),
                    "--cache", cache.path(),
                ]
                + paths.map(\.path),
                environment: [:],
                inputFiles: paths,
                outputFiles: [
                    output
                ]
            )
        ]
    }
}

extension Path {
    func walk(_ visitor: (URL) -> Void) {
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
            visitor(url)
        }
    }
    
    var url: URL {
        URL(fileURLWithPath: string)
    }
    
    var pathExtension: String {
        url.pathExtension
    }
}
