varying vec3 vColor;
varying vec3 vWorldPos;
varying float vEdgeFade;

void main() {
    vec2 center = gl_PointCoord - vec2(0.5);
    float dist = length(center);
    
    // Sharper, cleaner dots with consistent size
    float edgeThreshold = 0.48; // Fixed threshold for crisp edges
    
    // Hard edge cutoff for clarity
    if (dist > 0.5) discard;
    
    // Sharper alpha falloff for cleaner dots
    float alpha;
    if (dist < 0.35) {
        // Solid center
        alpha = 1.0;
    } else {
        // Sharp falloff at edges
        alpha = smoothstep(0.5, 0.35, dist);
    }
    
    // Strong edge fade for better definition
    alpha *= pow(vEdgeFade, 0.05); // Much less fade for clarity
    
    // No additional fading - keep dots fully visible everywhere
    
    vec3 dotColor = vColor;
    
    // No sun illumination - keep original colors
    // Removed all sun effects to prevent white/bright spots
    
    // No rim glow - keep colors pure
    
    // Minimal color variation for cleaner look
    float colorVar = sin(vWorldPos.x * 10.0) * cos(vWorldPos.y * 9.0) * sin(vWorldPos.z * 11.0);
    colorVar = colorVar * 0.01 + 1.0; // Very subtle variation
    dotColor *= colorVar;
    
    // Crisp dot with subtle darkening at edges
    if (dist > 0.4) {
        // Subtle darkening for depth
        float edgeDarkening = smoothstep(0.4, 0.5, dist);
        dotColor = mix(dotColor, dotColor * 0.7, edgeDarkening);
    }
    
    // No depth adjustment - keep colors consistent
    
    gl_FragColor = vec4(dotColor, alpha);
}