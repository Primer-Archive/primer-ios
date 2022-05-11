//
//  ResizeHandleShader.metal
//  Primer
//
//  Created by Eric Florenzano on 12/11/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

#include <SceneKit/scn_metal>

#import "ShaderTypes.h"

typedef struct {
    float3 position     [[attribute(SCNVertexSemanticPosition)]];
    float3 normal       [[attribute(SCNVertexSemanticNormal)]];
} ResizeHandleVertexIn;

typedef struct {
    float4 position [[ position ]];
    
    float3 normal;
} ResizeHandleVertexOut;

vertex ResizeHandleVertexOut resize_handle_vertex(ResizeHandleVertexIn in [[ stage_in ]],
                                 constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                 constant NodeData& scn_node [[buffer(1)]]) {
    ResizeHandleVertexOut out;

    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.normal = normalize((scn_node.normalTransform * float4(in.normal, 1.0)).xyz);

    return out;
}

fragment half4 resize_handle_fragment(ResizeHandleVertexOut in [[ stage_in ]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant NodeData& scn_node [[buffer(1)]],
                             constant float& opacity [[buffer(2)]],
                             constant float4& diffuseColor [[buffer(3)]],
                             constant float4& emissionColor [[buffer(4)]]) {
    if (opacity <= 1e-10) {
        discard_fragment();
    }
    
    half4 out;
    
    // Use normal direction to fake lighting contribution
    const half fakeLighting = length(in.normal);
    
    // Mostly let the diffuse color shine through
    const half diffuseStrength = 0.90;
    const half emissionStrength = (1.0 - diffuseStrength) * fakeLighting;

    const half4 diffuse = half4(diffuseColor) * diffuseStrength;
    const half4 emission = half4(emissionColor) * emissionStrength;

    out.rgb = diffuse.rgb + emission.rgb;
    out.a = opacity;

    return out;
}
