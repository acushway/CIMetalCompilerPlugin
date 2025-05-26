#include <CoreImage/CoreImage.h>
#include <metal_stdlib>

using namespace metal;

extern "C" float4 passthrough(coreimage::sampler src, coreimage::destination dest) {
    return src.sample(src.coord());
}
