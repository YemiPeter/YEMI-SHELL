#version 440

// Vertex stage for the Hyprland pill shadow (see PillOverlay.qml).
// Passes texcoords through; the uniform block layout must match
// shadow.frag exactly (shared binding 0).

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;   // 0..63
    float qt_Opacity; // 64
    vec4 uGeom;       // 80: xy = item size px, zw = pill rect size px
    vec4 uParams;     // 96: x = corner radius px, y = fade px, zw = offset px
    vec4 uColor;      // 112: rgb = shadow color, a = strength
} ubuf;

layout(location = 0) out vec2 vTexCoord;

void main() {
    vTexCoord = qt_MultiTexCoord0;
    gl_Position = ubuf.qt_Matrix * qt_Vertex;
}
