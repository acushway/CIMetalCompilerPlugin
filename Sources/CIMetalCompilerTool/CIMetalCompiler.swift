import ArgumentParser
import Foundation
import os

#if !targetEnvironment(macCatalyst)
/// Useful links:
/// https://clang.llvm.org/docs/Modules.html#problems-with-the-current-model
/// https://keith.github.io/xcode-man-pages/xcrun.1.html
/// https://developer.apple.com/documentation/metal/building-a-shader-library-by-precompiling-source-files
@main
@available(macOS 13.0, *)
struct CIMetalCompilerTool: ParsableCommand {
    @Option(name: .long)
    var output: String
    
    @Option(name: .long)
    var cache: String
    
    @Argument
    var inputs: [String]
    
    mutating func run() throws {
        print("=== run MetalCompilerTool ===")
        
        let xcRunURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        
        try FileManager.default.createDirectory(atPath: cache, withIntermediateDirectories: true)
        
        var airOutputs = [String]()

        // First compile each input to .air files.
        // For stitchable shaders, use -std=ios-metal2.4 instead of -fcikernel
        // Equivalent to: xcrun metal -std=ios-metal2.4 -c MyKernel.metal -o MyKernel.air
        for input in inputs {
            let name = input.nameWithoutExtension

            let p = Process()
            p.executableURL = xcRunURL

            let airOutput = "\(cache)/\(name).air"

            p.arguments = [
                "metal",
                "-std=ios-metal2.4",
                "-c",
                input,
                "-o",
                airOutput,
                "-fmodules=none" // Must disable fmodules to avoid issues when building in Xcode Cloud.
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
        
        // Link all .air files into a single metallib with CoreImage framework support.
        // For stitchable shaders, we need to link with the CoreImage framework.
        // Equivalent to: xcrun metal *.air -o default.metallib -framework CoreImage
        print("linking \(airOutputs.count) air file(s) to \(output) with CoreImage framework")

        let p = Process()
        p.executableURL = xcRunURL
        p.arguments = [
            "metal"
        ] + airOutputs + [
            "-o",
            output,
            "-framework",
            "CoreImage"
        ]

        try p.run()
        p.waitUntilExit()

        let status = p.terminationStatus

        if status != 0 {
            throw CompileError(message: "Failed to link air files to \(output) with exit code \(status)")
        } else {
            print("====CIMetalCompilerTool completed!")
        }
    }
}
#else
@main
struct CIMetalCompilerTool: ParsableCommand {
    @Option(name: .long)
    var output: String
    
    @Option(name: .long)
    var cache: String
    
    @Argument
    var inputs: [String]
    
    mutating func run() throws {
        throw CompileError(message: "CIMetalCompilerTool is not supported on macOS Catalyst. But this code won't run anyway.")
    }
}
#endif
