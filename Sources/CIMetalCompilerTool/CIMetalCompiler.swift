import ArgumentParser
import Foundation
import os

@main
struct CIMetalCompilerTool: ParsableCommand {
    @Option(name: .long)
    var output: String
    
    @Option(name: .long)
    var cache: String
    
    @Argument
    var inputs: [String]
    
    mutating func run() throws {
        let first = inputs.first!
        
        print("=== run MetalCompilerTool===")
        
        let xcRunURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        
        try FileManager.default.createDirectory(atPath: cache, withIntermediateDirectories: true)
        
        var airOutputs = [String]()
        
        for input in inputs {
            let name = input.nameWithoutExtension
            
            let p = Process()
            p.executableURL = xcRunURL
            
            let airOutput = "\(cache)/\(name).air"
            
            p.arguments = [
                "metal",
                "-c",
                "-fcikernel",
                input,
                "-o",
                airOutput
            ]
            
            try p.run()
            try p.waitUntilExit()
            
            airOutputs.append(airOutput)
        }
        
        var metalLibs = [String]()
        
        for airFile in airOutputs {
            let name = airFile.nameWithoutExtension
            
            print("linking \(airFile) to metallib")
            
            let metalLibOutput = "\(cache)/\(name).cimetallib"
            let p = Process()
            p.executableURL = xcRunURL
            p.arguments = [
                "metallib",
                "--cikernel",
                airFile,
                "-o",
                metalLibOutput
            ]
            
            try p.run()
            try p.waitUntilExit()
            
            metalLibs.append(metalLibOutput)
        }
        
        print("merging \(metalLibs) to \(output)")
        
        let p = Process()
        p.executableURL = xcRunURL
        p.arguments = [
            "metal",
            "-fcikernel",
            "-o",
            output,
        ] + airOutputs
        
        try p.run()
        try p.waitUntilExit()
    }
}

extension String {
    var nameWithoutExtension: String {
        let url = URL(string: self)!
        let name = url.deletingPathExtension().lastPathComponent
        return name
    }
}
