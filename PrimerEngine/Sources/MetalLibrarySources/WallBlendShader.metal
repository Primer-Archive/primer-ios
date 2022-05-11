//
//  WallBlendShader.metal
//  Primer
//
//  Created by Eric Florenzano on 2/18/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

#include <SceneKit/scn_metal>

#import "ShaderTypes.h"

constexpr sampler wallBlendSampler(address::repeat, mip_filter::linear, mag_filter::linear, min_filter::linear);

constant auto yCbCrToRGB = float4x4(float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
                                    float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
                                    float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
                                    float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f));

constant float4 CLEAR_COLOR = float4(0, 0, 0, 0);

constant float4 RGB2HSV_K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
constant float2 RGB2HSV_K_WZ = RGB2HSV_K.wz;
constant float2 RGB2HSV_K_XY = RGB2HSV_K.xy;
constant float RGB2HSV_E = 1.0e-10;

constant float4 HSV2RGB_K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
constant float3 HSV2RGB_K_XYZ = HSV2RGB_K.xyz;
constant float3 HSV2RGB_K_XXX = HSV2RGB_K.xxx;
constant float3 HSV2RGB_K_WWW = HSV2RGB_K.www;

float3 rgb2hsv(float3 c) {
    const float4 p = mix(float4(c.bg, RGB2HSV_K_WZ), float4(c.gb, RGB2HSV_K_XY), step(c.b, c.g));
    const float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    const float d = q.x - min(q.w, q.y);
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + RGB2HSV_E)), d / (q.x + RGB2HSV_E), q.x);
}

float3 hsv2rgb(float3 c) {
    const float3 p = abs(fract(c.xxx + HSV2RGB_K_XYZ) * 6.0 - HSV2RGB_K_WWW);
    return c.z * mix(HSV2RGB_K_XXX, saturate(p - HSV2RGB_K_XXX), c.y);
}

typedef struct {
    float4 position [[ position ]];
    float4 swatchVertex;
    float2 texcoord0;
} WallBlendVertexOut;

vertex WallBlendVertexOut wall_blend_vertex(unsigned int vid [[vertex_id]],
                                            constant WallBlendVertex *vertices [[buffer(0)]],
                                            constant WallBlendData &wallBlendData [[buffer(1)]]) {
    WallBlendVertexOut out;

    const WallBlendVertex vtx = vertices[vid];
    out.position = float4(vtx.position, 1.0);
    out.swatchVertex = float4(vtx.position * 0.5, 1.0);

    const auto tx0tmp = wallBlendData.textureTransform * float4(vtx.texcoord0, 1, 1);
    out.texcoord0 = tx0tmp.xy / tx0tmp.w;

    return out;
}

fragment float4 wall_blend_fragment(WallBlendVertexOut in [[ stage_in ]],
                                    constant WallBlendData &wallBlendData [[buffer(0)]],
                                    texture2d<float, access::sample> sourceImageTexture [[texture(0)]],
                                    texture2d<float, access::sample> capturedImageTextureY [[texture(1)]],
                                    texture2d<float, access::sample> capturedImageTextureCbCr [[texture(2)]]) {
    const bool hasColor = wallBlendData.hasColor != 0;
    if (hasColor && all(wallBlendData.color == CLEAR_COLOR)) {
        return CLEAR_COLOR;
    }

    const float4 sourceColor = hasColor ? wallBlendData.color : sourceImageTexture.sample(wallBlendSampler, in.texcoord0);

    const float4 swatchVertex = wallBlendData.modelViewProjectionTransform * in.swatchVertex;
    const auto texTemp = (((swatchVertex.xyz / swatchVertex.w) + 1) * 0.5) * wallBlendData.viewToCamera;
    const auto texcoord = float2(1.0 - texTemp.x, texTemp.y);
    const auto ycbcr = float4(capturedImageTextureY.sample(wallBlendSampler, texcoord).r, capturedImageTextureCbCr.sample(wallBlendSampler, texcoord).rg, 1);
    auto backgroundColorHSV = rgb2hsv(pow((yCbCrToRGB * ycbcr).xyz, 2));
    backgroundColorHSV.y = 0;
    backgroundColorHSV.z = saturate(backgroundColorHSV.z + wallBlendData.blendLighten);
    const auto backgroundColor = float4(hsv2rgb(backgroundColorHSV), 1);

    const auto out = mix(sourceColor, backgroundColor, wallBlendData.blendPercent);
    return out;
}
