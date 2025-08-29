varying vec3 vColor;
varying float vIntensity;
varying vec3 vNormal;
varying vec3 vWorldPos;
varying float vEdgeFade;
varying float vDistortion;
varying float vRadialDist;
varying float vFoldDepth;

void main() {
    vec2 center = gl_PointCoord - vec2(0.5);
    float dist = length(center);
    
    // Base threshold for dots
    float edgeThreshold = 0.45 + vEdgeFade * 0.05;
    
    // No modification based on fold depth - keep dots uniform
    // edgeThreshold stays constant
    
    // No scattering - keep all dots visible for full coverage
    
    if (dist > edgeThreshold) discard;
    
    // Smooth alpha falloff
    float alpha = smoothstep(edgeThreshold, edgeThreshold * 0.3, dist);
    
    // Minimal edge fade to maintain visibility
    alpha *= pow(vEdgeFade, 0.1); // Very gentle fade
    
    // No additional fading - keep dots fully visible everywhere
    
    vec3 dotColor = vColor;
    
    // No sun illumination - keep original colors
    // Removed all sun effects to prevent white/bright spots
    
    // No rim glow - keep colors pure
    
    // Very subtle color variation for organic look
    float colorVar = sin(vWorldPos.x * 10.0) * cos(vWorldPos.y * 9.0) * sin(vWorldPos.z * 11.0);
    colorVar = colorVar * 0.02 + 1.0; // Reduced from 0.03
    dotColor *= colorVar;
    
    // Add black border effect
    float borderWidth = 0.16; // Width of the black border
    float borderStart = edgeThreshold - borderWidth;
    
    if (dist > borderStart) {
        // Create smooth transition to black at the edge
        float borderFactor = smoothstep(borderStart, edgeThreshold, dist);
        dotColor = mix(dotColor, vec3(0.0, 0.0, 0.0), borderFactor * 0.8); // 80% black blend
    }
    
    // No depth adjustment - keep colors consistent
    
    gl_FragColor = vec4(dotColor, alpha);
}