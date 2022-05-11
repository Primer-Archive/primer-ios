//
//  BackSwatchShader.metal
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
} BackSwatchVertexIn;

typedef struct {
    float4 position [[ position ]];
    float2 texcoord0;
} BackSwatchVertexOut;

constexpr sampler backSwatchSampler(address::repeat, min_filter::nearest, mag_filter::nearest, mip_filter::none);

vertex BackSwatchVertexOut back_swatch_vertex(BackSwatchVertexIn in [[ stage_in ]],
                                                        constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                                        constant NodeData& scn_node [[buffer(1)]]) {
    BackSwatchVertexOut out;

    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.texcoord0 = in.texcoord0;

    return out;
}

fragment half4 back_swatch_fragment(BackSwatchVertexOut in [[ stage_in ]],
                                         constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                         constant NodeData& scn_node [[buffer(1)]],
                                         texture2d<half, access::sample> diffuseTex [[texture(0)]],
                                         texture2d<half, access::sample> metalnessTex [[texture(1)]],
                                         texture2d<half, access::sample> roughnessTex [[texture(2)]]) {
    half4 out;

    const half4 diffuse = diffuseTex.sample(backSwatchSampler, in.texcoord0);
    const half4 metalness = metalnessTex.sample(backSwatchSampler, in.texcoord0);
    const half4 roughness = roughnessTex.sample(backSwatchSampler, in.texcoord0);

    const half contrib = saturate(length(roughness)) * 0.1;

    const half3 ambientContrib = half3(scn_frame.ambientLightingColor.rgb);
    const half3 diffuseContrib = diffuse.rgb * (1.0 - contrib);
    const half3 specularContrib = metalness.rgb * contrib;

    out.rgb = ambientContrib + diffuseContrib + specularContrib;
    out.a = min(min(diffuse.a, metalness.a), roughness.a);

    return out;
}
