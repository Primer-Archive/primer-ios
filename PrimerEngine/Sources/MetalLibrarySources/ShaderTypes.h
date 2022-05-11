//
//  ShaderTypes.h
//  PrimerEngine
//
//  Created by Eric Florenzano on 12/11/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef struct {
    matrix_float4x4 modelTransform;
    matrix_float4x4 inverseModelTransform;
    matrix_float4x4 modelViewTransform;
    matrix_float4x4 inverseModelViewTransform;
    matrix_float4x4 normalTransform;
    matrix_float4x4 modelViewProjectionTransform;
    matrix_float4x4 inverseModelViewProjectionTransform;
    matrix_float2x3 boundingBox;
    matrix_float2x3 worldBoundingBox;
} NodeData;

typedef struct {
    matrix_float3x3 viewToCamera;
    matrix_float4x4 swatchWorldTransform;
    matrix_float4x4 textureTransform;
    matrix_float4x4 modelViewProjectionTransform;
    simd_float4 color;
    uint hasColor;
    float blendPercent;
    float blendLighten;
} WallBlendData;

typedef struct {
    simd_float3 position;
    simd_float2 texcoord0;
} WallBlendVertex;

#endif /* ShaderTypes_h */
