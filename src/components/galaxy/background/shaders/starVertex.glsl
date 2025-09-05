attribute float size;
varying vec3 vColor;
varying float vAlpha;

uniform float uTime;

void main() {
    vColor = color;
    
    // Subtle twinkling effect for stars
    float twinkle = sin(uTime * 2.0 + position.x * 10.0) * 0.5 + 0.5;
    vAlpha = 0.6 + twinkle * 0.4;
    
    vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
    gl_Position = projectionMatrix * mvPosition;
    
    // Size attenuation based on distance
    gl_PointSize = size * (300.0 / -mvPosition.z);
    gl_PointSize = clamp(gl_PointSize, 1.0, 15.0);
}