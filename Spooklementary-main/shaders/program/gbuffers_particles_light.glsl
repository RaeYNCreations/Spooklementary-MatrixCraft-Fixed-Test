/////////////////////////////////////
// Particle light buffer (additive)
// Renders particle sprites to a particle-light render target as additive light contribution
// Include common definitions to match pipeline
#include "/lib/common.glsl"

#ifdef FRAGMENT_SHADER

// Particle color provided via gl_FrontColor or varyings depending on particle renderer
in vec4 glColor;

// For point sprites: gl_PointCoord is available
void main() {
    // gl_PointCoord ranges 0..1 across the sprite
    vec2 coord = gl_PointCoord - vec2(0.5);
    float dist = length(coord) / 0.5;
    float falloff = clamp(1.0 - dist * dist, 0.0, 1.0);

    // HDR-friendly intensity (alpha used as intensity multiplier)
    vec3 light = glColor.rgb * (glColor.a) * falloff;

    // Output additive light RGB; alpha not used
    gl_FragData[0] = vec4(light, 1.0);
}

#endif

#ifdef VERTEX_SHADER

// Simple passthrough; particle size should be set by renderer via gl_PointSize
void main() {
    gl_Position = ftransform();
}

#endif