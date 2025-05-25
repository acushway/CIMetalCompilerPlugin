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
        
        // First compile each input to .air files.
        // Equivelent to this command line:
        // xcrun metal -c -fcikernel MyKernel.metal -o MyKernel.air
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
        
        // Then, using metallib to link each .air file and output to a .metallib file.
        // Equivelent to this command line:
        // xcrun metallib --cikernel MyKernel.air -o MyKernel.metallib
        for airFile in airOutputs {
            let name = airFile.nameWithoutExtension
            
            print("linking \(airFile) to metallib")
            
            let metalLibOutput = "\(cache)/\(name).metallib"
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
        
        // Finally, merge all metallib files into one output file.
        // Equivelent to this command line:
        // xcrun metal -fcikernel -o MyKernel.metallib MyKernel1.metallib MyKernel2.metallib ...
        // NOTE: This command is different from the one that was first introduced in WWDC20:
        // https://developer.apple.com/videos/play/wwdc2020/10021
        // The old command is obsolete and no longer works.
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
