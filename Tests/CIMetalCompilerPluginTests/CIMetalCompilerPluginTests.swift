import Testing
import Foundation
import CoreImage

class BundleLocator {
    // ignored
}

@Test
func passthroughShader() async throws {
    let kernel = createCIKernel(functionName: "passthrough")
    #expect(kernel != nil)
    
    let ciImage = createInputImage()
    let outputImage = kernel!.apply(extent: ciImage.extent, roiCallback: { $1 }, arguments: [ciImage])!
    let outputBitmapData = CIContext().renderToBitmap(outputImage: outputImage)
    
    #expect(outputBitmapData[0] == 255)
    #expect(outputBitmapData[1] == 255)
    #expect(outputBitmapData[2] == 255)
    #expect(outputBitmapData[3] == 255)
}

@Test
func allRedShader() async throws {
    let kernel = createCIKernel(functionName: "allRed")
    #expect(kernel != nil)
    
    let ciImage = createInputImage()
    let outputImage = kernel!.apply(extent: ciImage.extent, roiCallback: { $1 }, arguments: [ciImage])!
    let outputBitmapData = CIContext().renderToBitmap(outputImage: outputImage)
    
    #expect(outputBitmapData[0] == 255)
    #expect(outputBitmapData[1] == 0)
    #expect(outputBitmapData[2] == 0)
    #expect(outputBitmapData[3] == 255)
}

@Test
func nonExistedShader() async throws {
    let kernel = createCIKernel(functionName: "foo")
    #expect(kernel == nil)
}
