#version 440

// Shadow-only rounded-box SDF for the Hyprland pill shadow
// (see PillOverlay.qml). Renders ONLY the soft shadow:
//
//   - Zero alpha inside the pill frame. The translucent pill sits on a
//     separate surface above this one, so any shadow alpha under it would
//     tint the pill's own frost — the shadow must start at the border.
//   - Gaussian-ish falloff outward over uParams.y pixels.
//   - Output is premultiplied (scene graph convention).
//
// This exists because MultiEffect always draws its source silhouette along
// with the shadow, and an opaque silhouette on this surface would show
// through the translucent pill above.

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;   // 0..63
    float qt_Opacity; // 64
    vec4 uGeom;       // 80: xy = item size px, zw = pill rect size px
    vec4 uParams;     // 96: x = corner radius px, y = fade px, zw = offset px
    vec4 uColor;      // 112: rgb = shadow color, a = strength
} ubuf;

float sdRoundedBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 itemSize = ubuf.uGeom.xy;
    vec2 rectSize = ubuf.uGeom.zw;

    // Item-local pixels, centered, shifted by the shadow offset: the offset
    // moves the SHADOW away from the pill, so we sample the distance field
    // of the pill frame displaced by -offset.
    vec2 p = (vTexCoord - 0.5) * itemSize - ubuf.uParams.zw;

    float d = sdRoundedBox(p, rectSize * 0.5, max(ubuf.uParams.x, 0.0));

    float fade = max(ubuf.uParams.y, 1.0);
    float outside = max(d, 0.0);
    float a = ubuf.uColor.a * ubuf.qt_Opacity
            * exp(-3.0 * outside / fade)
            * smoothstep(-1.0, 0.0, d);

    fragColor = vec4(ubuf.uColor.rgb * a, a);
}
