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
    void applyMatrixTrailLights(vec3 fragPos, inout vec3 outColor) {
    // DEBUG: Always add red to EVERYTHING to confirm function is called
    outColor += vec3(0.1, 0.0, 0.0); // Slight red tint
    
    for (int i = 0; i < MATRIX_TRAIL_MAX_LIGHTS; i++) {
        vec4 posTexel = texelFetch(matrixcraft_trail_lights, ivec2(i, 0), 0);
        if (posTexel.a <= 0.0039) continue;

        vec3 lightPos = decodeTrailLightPosition(posTexel);
        float intensity = posTexel.a;

        vec4 colorTexel = texelFetch(matrixcraft_trail_lights, ivec2(i, 1), 0);
        vec3 lightColor = colorTexel.rgb * intensity;

        float dist = distance(fragPos, lightPos);
        
        // DEBUG: MUCH larger radius to see if it's just a distance issue
        float radius = 50.0; // Was 3.0 + intensity * 5.0
        
        if (dist > radius) continue;
        
        float att = 1.0 - (dist / radius);
        att = att * att * att;

        outColor += lightColor * att * intensity * 2.0; // Boosted multiplier
        }
    }
}
#endif