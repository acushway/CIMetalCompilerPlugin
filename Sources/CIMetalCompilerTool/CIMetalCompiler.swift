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
        print("=== run MetalCompilerTool===")
        
        let xcRunURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        let sdk = "iphoneos"
        
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
                "--sdk",
                sdk,
                "metal",
                "-c",
                "-fcikernel",
                input,
                "-o",
                airOutput,
                "-fmodules=none"
            ]
            
            try p.run()
            p.waitUntilExit()
            let status = p.terminationStatus

            if status != 0 {
                throw CompileError(message: "Failed to compile \(input) with exit code \(status)")
            } else {
                print("compiled \(input) to \(airOutput)")
            }
            
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
                "--sdk",
                sdk,
                "metallib",
                "--cikernel",
                airFile,
                "-o",
                metalLibOutput
            ]
            
            try p.run()
            p.waitUntilExit()
            
            let status = p.terminationStatus
            
            if status != 0 {
                throw CompileError(message: "Failed to link \(airFile) with exit code \(status)")
            } else {
                print("compiled \(airFile) to \(metalLibOutput)")
            }
            
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
            "--sdk",
            sdk,
            "metal",
            "-fcikernel",
            "-o",
            output,
        ] + airOutputs
        
        try p.run()
        p.waitUntilExit()
        
        let status = p.terminationStatus
        
        if status != 0 {
            throw CompileError(message: "Failed to merge to \(output) with exit code \(status)")
        } else {
            print("====CIMetalCompilerTool completed!")
        }
    }
}

struct CompileError: Error {
    let message: String
}

extension String {
    var nameWithoutExtension: String {
        let url = URL(string: self)!
        let name = url.deletingPathExtension().lastPathComponent
        return name
    }
}
