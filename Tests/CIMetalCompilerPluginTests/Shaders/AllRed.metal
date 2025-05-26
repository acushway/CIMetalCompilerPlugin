#include <CoreImage/CoreImage.h>
#include <metal_stdlib>
#include "Helper.h"

using namespace metal;
using namespace Helper;

extern "C" float4 allRed(coreimage::sampler src, coreimage::destination dest) {
    float4 srcColor = src.sample(src.coord());
    return makeAllRed(srcColor);
}
