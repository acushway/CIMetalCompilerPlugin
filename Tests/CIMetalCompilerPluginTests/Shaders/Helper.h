#ifndef HELPER_H
#define HELPER_H

#ifdef __METAL_VERSION__
#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;
#endif /* __METAL_VERSION__ */

namespace Helper {
    METAL_FUNC float4 makeAllRed(float4 rgba) {
        return float4(1.0, 0.0, 0.0, 1.0);
    }
}
#endif /* Helper */
