#ifndef MATRIX_TRAIL_LIGHTS
#define MATRIX_TRAIL_LIGHTS

const int MATRIX_TRAIL_MAX_LIGHTS = 64;
const float MATRIX_TRAIL_RANGE = 256.0;

uniform sampler2D matrixcraft_trail_lights;

vec3 decodeTrailLightPosition(vec4 texel) {
    vec3 rel;
    rel.x = (texel.r * 2.0 - 1.0) * MATRIX_TRAIL_RANGE;
    rel.y = (texel.g * 2.0 - 1.0) * MATRIX_TRAIL_RANGE;
    rel.z = (texel.b * 2.0 - 1.0) * MATRIX_TRAIL_RANGE;
    vec3 worldPos = cameraPosition + rel;
    return worldPos;
}

void applyMatrixTrailLights(vec3 fragPos, inout vec3 outColor) {
    // DEBUG: Make EVERYTHING bright green to confirm this runs
    outColor += vec3(0.0, 0.5, 0.0);
    
    for (int i = 0; i < MATRIX_TRAIL_MAX_LIGHTS; i++) {
        vec4 posTexel = texelFetch(matrixcraft_trail_lights, ivec2(i, 0), 0);
        if (posTexel.a <= 0.0039) continue;

        vec3 lightPos = decodeTrailLightPosition(posTexel);
        float intensity = posTexel.a;

        vec4 colorTexel = texelFetch(matrixcraft_trail_lights, ivec2(i, 1), 0);
        vec3 lightColor = colorTexel.rgb * intensity;

        float dist = distance(fragPos, lightPos);
        float radius = 3.0 + intensity * 5.0;
        if (dist > radius) continue;
        
        float att = 1.0 - (dist / radius);
        att = att * att * att;

        outColor += lightColor * att * intensity * 0.9;
    }
}

#endif