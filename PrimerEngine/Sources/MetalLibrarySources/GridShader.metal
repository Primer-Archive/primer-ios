//
//  GridShader.metal
//  PrimerEngine
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
    float2 texcoord0    [[attribute(SCNVertexSemanticTexcoord0)]];
} GridVertexIn;

typedef struct {
    float4 position [[ position ]];
    float2 texcoord0;
    float2 texcoord1;
} GridVertexOut;

constexpr sampler gridSampler(address::repeat, min_filter::nearest, mag_filter::nearest, mip_filter::none);

vertex GridVertexOut grid_vertex(GridVertexIn in [[ stage_in ]],
                                 constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                 constant NodeData& scn_node [[buffer(1)]],
                                 constant float& tileSize [[buffer(2)]],
                                 constant float3& swatchPosition [[buffer(3)]],
                                 constant float3& swatchScale [[buffer(4)]]) {
    GridVertexOut out;

    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.position.z = 0.0;

    const float2 coordOffset = float2(swatchPosition.x, -swatchPosition.y) / swatchScale.xy;
    const float2 scale = swatchScale.xy / tileSize;
    const float2 coords = ((in.texcoord0 + coordOffset) * scale) - (scale * 0.5);

    out.texcoord0 = in.texcoord0;
    out.texcoord1 = coords;

    return out;
}

fragment half4 grid_fragment(GridVertexOut in [[ stage_in ]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant NodeData& scn_node [[buffer(1)]],
                             constant float& opacity [[buffer(2)]],
                             texture2d<half, access::sample> diffuseTex [[texture(0)]],
                             texture2d<half, access::sample> transparentTex [[texture(1)]]) {
    if (opacity <= 1e-10) {
        discard_fragment();
    }

    half4 out;

    const half4 transparent = transparentTex.sample(gridSampler, in.texcoord0);
    const half4 diffuse = diffuseTex.sample(gridSampler, in.texcoord1);

    out.rgb = diffuse.rgb;
    out.a = min(transparent.a, diffuse.a) * opacity * 0.6;

    return out;
}
