//
//  WorldGeometryShader.metal
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
    //float2 texcoord0    [[attribute(SCNVertexSemanticTexcoord0)]];
} WorldGeometryVertexIn;

typedef struct {
    float4 position [[ position ]];
    
    float3 normal;
    float2 texcoord0;
} WorldGeometryVertexOut;

vertex WorldGeometryVertexOut world_geometry_vertex(WorldGeometryVertexIn in [[ stage_in ]],
                                                    constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                                    constant NodeData& scn_node [[buffer(1)]]) {
    WorldGeometryVertexOut out;

    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.normal = normalize((scn_node.normalTransform * float4(in.normal, 1.0)).xyz);
    //out.texcoord0 = in.texcoord0;

    return out;
}

fragment half4 world_geometry_fragment(WorldGeometryVertexOut in [[ stage_in ]],
                                       constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                       constant NodeData& scn_node [[buffer(1)]]) {
    /*
    half4 out;

    float3 bBoxMin = scn_node.boundingBox[0];
    float3 bBoxMax = scn_node.boundingBox[1];
    float3 size = bBoxMax - bBoxMin;
    
    float lineThickness = 0.02;
    float u = in.texcoord0.x;
    float v = in.texcoord0.y;
    
    float2 scale;
    if (abs((scn_node.inverseModelViewTransform * float4(in.normal, 0.0)).x) > 0.5) {
        scale = size.zy;
    } else if (abs((scn_node.inverseModelViewTransform * float4(in.normal, 0.0)).y) > 0.5) {
        scale = size.xz;
    } else {
        scale = size.xy;
    }
    
    float2 thresh = float2(lineThickness) / scale;
    if (u > thresh[0] && u < (1.0 - thresh[0]) && v > thresh[1] && v < (1.0 - thresh[1])) {
        discard_fragment();
    }

    out = half4(1, 1, 1, 1);

    return out;
    */
    return half4(1, 1, 1, 1);
}
