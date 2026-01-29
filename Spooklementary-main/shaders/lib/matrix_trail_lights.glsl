#ifndef MATRIX_TRAIL_LIGHTS
#define MATRIX_TRAIL_LIGHTS

// Must match the Java TEXTURE_UNIT (12)
const int MATRIX_TRAIL_MAX_LIGHTS = 64; // must match DynamicLightTextureManager.MAX_TRAIL_LIGHTS
const float MATRIX_TRAIL_RANGE = 256.0; // must match POSITION_RANGE in Java (blocks)

/*
  This file is safe to include from any shader stage.
  - When FRAGMENT_SHADER is defined we declare the sampler and implement full
    decoding + sampling logic.
  - Otherwise (vertex / geometry / compute) we provide stub functions so other
    stages can compile even if they include this file.
*/

// Utility: decode a texel (packed) -> world position. The full implementation
// requires sampling the texture (fragment shader only). For non-fragment we
// provide a stub that returns a far-away position and zero contribution.
#ifdef FRAGMENT_SHADER
uniform sampler2D matrixcraft_trail_lights;

// Camera/world position helpers are expected to be defined by your other includes
// (cameraPosition, etc). If you use cameraPositionBestFract + cameraPositionBestInt,
// adjust decode accordingly.

vec3 decodeTrailLightPosition(vec4 texel) {
    // texel.r/g/b are normalized 0..1 encoding offset from camera in [-R, R]
    vec3 rel;
    rel.x = (texel.r * 2.0 - 1.0) * MATRIX_TRAIL_RANGE;
    rel.y = (texel.g * 2.0 - 1.0) * MATRIX_TRAIL_RANGE;
    rel.z = (texel.b * 2.0 - 1.0) * MATRIX_TRAIL_RANGE;

    // cameraPosition should be available from /lib/uniforms.glsl (common.glsl)
    // Some packs expose cameraPosition as vec3; others expose cameraPositionBestFract + cameraPositionBestInt.
    // This code assumes a vec3 cameraPosition exists. If your pack uses cameraPositionBestFract + cameraPositionBestInt,
    // you can reconstruct `cameraPosition` in your shader before calling applyMatrixTrailLights.
    vec3 worldPos = cameraPosition + rel;
    return worldPos;
}

/*
 * Add trail lights' contribution to a lighting accumulator.
 *
 * fragPos: world-space fragment position
 * outColor: accumulator to add color into
 */
void applyMatrixTrailLights(vec3 fragPos, inout vec3 outColor) {
     // DEBUG: Force a visible color if texture has ANY data
    vec4 testTexel = texelFetch(matrixcraft_trail_lights, ivec2(0, 0), 0);
    if (testTexel.a > 0.001) {
        outColor += vec3(10.0, 0.0, 0.0); // BRIGHT RED if texture has data
        return;
    }
    
    // Loop through fixed-size texture width
    for (int i = 0; i < MATRIX_TRAIL_MAX_LIGHTS; i++) {
        // Row 0: position + intensity
        vec4 posTexel = texelFetch(matrixcraft_trail_lights, ivec2(i, 0), 0);
        // alpha encodes intensity/presence, skip zero
        if (posTexel.a <= 0.0039) continue; // ~1/255 threshold

        // reconstruct pos and intensity
        vec3 lightPos = decodeTrailLightPosition(posTexel);
        float intensity = posTexel.a; // 0..1

        // Row 1: RGB color data
        vec4 colorTexel = texelFetch(matrixcraft_trail_lights, ivec2(i, 1), 0);
        vec3 lightColor = colorTexel.rgb * intensity;

        float dist = distance(fragPos, lightPos);
        // simple smooth falloff radius (tweakable)
        float radius = 3.0 + intensity * 5.0; // base 3 -> up to ~8 blocks
        if (dist > radius) continue;
        // cubic falloff
        float att = 1.0 - (dist / radius);
        att = att * att * att;

        // contribution
        outColor += lightColor * att * intensity * 0.9; // tweak multiplier as needed
    }
}

#else // non-fragment: provide stubs so other stages don't break

// Provide a stub sampler declaration? Not necessary — avoid declaring sampler in non-fragment.
// Provide no-op functions with same signatures so includes and calls compile.

vec3 decodeTrailLightPosition(vec4 texel) {
    // return some safe default; we won't actually use it in non-fragment stages.
    return vec3(1e6, 1e6, 1e6);
}

void applyMatrixTrailLights(vec3 fragPos, inout vec3 outColor) {
    // no-op in non-fragment stages
    // This ensures the function exists even if mainLighting.glsl is included in vertex/other stages.
    // The fragment stage will use the real implementation above.
}

#endif // FRAGMENT_SHADER

#endif // MATRIX_TRAIL_LIGHTS