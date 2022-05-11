//
//  PlacementSwatchShader.metal
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
    float2 texcoord0    [[attribute(SCNVertexSemanticTexcoord0)]];
} PlacementSwatchVertexIn;

typedef struct {
    float4 position [[ position ]];
    float2 texcoord0;
} PlacementSwatchVertexOut;

constexpr sampler placementSwatchSampler(address::repeat, min_filter::nearest, mag_filter::nearest, mip_filter::none);

vertex PlacementSwatchVertexOut placement_swatch_vertex(PlacementSwatchVertexIn in [[ stage_in ]],
                                                        constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                                        constant NodeData& scn_node [[buffer(1)]]) {
    PlacementSwatchVertexOut out;

    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.texcoord0 = in.texcoord0;

    return out;
}

fragment half4 placement_swatch_fragment(PlacementSwatchVertexOut in [[ stage_in ]],
                                         constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                         constant NodeData& scn_node [[buffer(1)]],
                                         texture2d<half, access::sample> diffuseTex [[texture(0)]],
                                         texture2d<half, access::sample> metalnessTex [[texture(1)]]) {
    half4 out;

    const half4 diffuse = diffuseTex.sample(placementSwatchSampler, in.texcoord0);
    const half4 metalness = metalnessTex.sample(placementSwatchSampler, in.texcoord0);

    out.rgb = (diffuse.rgb * 0.9) + (metalness.rgb * 0.1);
    out.a = min(diffuse.a, metalness.a);

    return out;
}
