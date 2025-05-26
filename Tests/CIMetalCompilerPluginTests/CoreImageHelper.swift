import CoreImage

extension CIContext {
    func renderToBitmap(outputImage: CIImage) -> Data {
        var outputBitmapData = Data(repeating: 0, count: 4)
        
        withUnsafeMutablePointer(to: &outputBitmapData) { pointer in
            CIContext().render(
                outputImage,
                toBitmap: pointer,
                rowBytes: 4,
                bounds: CGRect(origin: .zero, size: CGSize(width: 1, height: 1)),
                format: .RGBA8,
                colorSpace: nil // Disable Color Management
            )
        }
        
        return outputBitmapData
    }
}

func createInputImage() -> CIImage {
    return CIImage(
        bitmapData: Data(repeating: 255, count: 4),
        bytesPerRow: 4,
        size: CGSize(width: 1, height: 1),
        format: .RGBA8,
        colorSpace: nil // Disable Color Management
    )
}

func createCIKernel(functionName: String) -> CIKernel? {
    let shadersBundleURL = Bundle(for: BundleLocator.self).resourceURL!
        .appendingPathComponent("CIMetalCompilerPlugin_CIMetalCompilerPluginTests.bundle")
    
    let bundle = Bundle(url: shadersBundleURL)!
    let libraryURL = bundle.url(forResource: "default", withExtension: "metallib")!
    let data = try! Data(contentsOf: libraryURL)
    let kernel = try? CIKernel(functionName: functionName, fromMetalLibraryData: data)
    return kernel
}
