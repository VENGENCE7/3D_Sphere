varying vec3 vColor;
varying float vIntensity;
varying vec3 vNormal;
varying vec3 vWorldPos;
varying float vEdgeFade;
varying float vDistortion;
varying float vRadialDist;
varying float vFoldDepth;
varying float vSunLight;
varying float vShadow;

void main() {
    vec2 center = gl_PointCoord - vec2(0.5);
    float dist = length(center);
    
    // Base threshold for dots
    float edgeThreshold = 0.45 + vEdgeFade * 0.05;
    
    // Modify threshold based on fold depth
    if (vFoldDepth < -0.1) {
        edgeThreshold *= (0.7 + vFoldDepth);
    }
    
    // Create scattered dots at edges and in deep shadows
    if (vEdgeFade < 0.35 || vFoldDepth < -0.15 || vShadow > 0.5) {
        float scatter = fract(sin(dot(vWorldPos.xy, vec2(12.9898, 78.233))) * 43758.5453);
        float scatter2 = fract(cos(dot(vWorldPos.yz, vec2(67.345, 45.233))) * 28374.8273);
        float finalScatter = mix(scatter, scatter2, 0.5);
        
        // More aggressive scattering in shadows
        float scatterThreshold = vShadow > 0.5 ? 0.3 : (vFoldDepth < -0.15 ? 0.4 : 0.6);
        if (finalScatter > vEdgeFade * 2.5 && finalScatter > scatterThreshold) {
            discard;
        }
        
        edgeThreshold *= (0.3 + finalScatter * 0.7);
    }
    
    if (dist > edgeThreshold) discard;
    
    // Smooth alpha falloff
    float alpha = smoothstep(edgeThreshold, edgeThreshold * 0.3, dist);
    
    // Apply edge fade
    alpha *= pow(vEdgeFade, 0.7);
    
    // Additional fade for extreme radial distance
    if (vRadialDist > 0.85) {
        float radialFade = 1.0 - (vRadialDist - 0.85) * 4.0;
        alpha *= max(radialFade, 0.0);
    }
    
    // Reduce alpha in deep shadows for depth
    if (vShadow > 0.6) {
        alpha *= (1.0 - (vShadow - 0.6) * 0.5);
    }
    
    // Reduce alpha in deep folds
    if (vFoldDepth < -0.15) {
        float foldAlpha = 1.0 + vFoldDepth * 2.0;
        alpha *= max(foldAlpha, 0.1);
    }
    
    vec3 dotColor = vColor;
    
    // Sun illumination creates bright highlights on peaks
    if (vSunLight > 0.5 && vDistortion > 0.05) {
        float sunHighlight = (vSunLight - 0.5) / 0.5;
        float glowIntensity = sunHighlight * min((vDistortion - 0.05) / 0.15, 1.0);
        
        // Sun creates warm yellow glow on illuminated peaks
        vec3 sunGlow = vec3(1.0, 0.95, 0.3);
        dotColor = mix(dotColor, sunGlow, glowIntensity * 0.4);
        
        // Bright core for directly lit peaks
        if (dist < 0.2 && vSunLight > 0.7) {
            float coreGlow = (0.2 - dist) / 0.2;
            coreGlow *= (vSunLight - 0.7) / 0.3;
            dotColor = mix(dotColor, vec3(1.0, 1.0, 0.5), coreGlow * 0.5);
        }
    }
    
    // Shadows are less dark now
    if (vShadow > 0.6) {
        float shadowDepth = (vShadow - 0.6) / 0.4;
        vec3 shadowColor = vColor * 0.3; // Not pure black, just darker version of color
        dotColor = mix(dotColor, shadowColor, shadowDepth * 0.5);
    }
    
    // Valley shadows are softer
    if (vFoldDepth < -0.08) {
        float valleyShadow = abs(vFoldDepth) / 0.25;
        valleyShadow = min(valleyShadow, 1.0);
        dotColor *= (1.0 - valleyShadow * 0.25); // Less darkening
        
        // Deep areas are dark but not black
        if (vFoldDepth < -0.2) {
            vec3 darkColor = vColor * 0.2; // Dark version of the color
            float darkMix = min(abs(vFoldDepth + 0.2) * 3.0, 0.7);
            dotColor = mix(dotColor, darkColor, darkMix);
        }
    }
    
    // Sun intensity boost for illuminated areas
    if (vSunLight > 0.3) {
        float boost = (vSunLight - 0.3) / 0.7;
        dotColor = mix(dotColor, dotColor * 1.3, boost * 0.3);
    }
    
    // Rim glow only on illuminated edges
    if (vEdgeFade > 0.7 && vSunLight > 0.2) {
        float rimGlow = (vEdgeFade - 0.7) / 0.3;
        rimGlow *= vSunLight;
        vec3 rimColor = mix(dotColor, vec3(1.0, 0.8, 0.3), 0.4);
        dotColor = mix(dotColor, rimColor, rimGlow * 0.3);
    }
    
    // Subtle color variation
    float colorVar = sin(vWorldPos.x * 10.0) * cos(vWorldPos.y * 9.0) * sin(vWorldPos.z * 11.0);
    colorVar = colorVar * 0.03 + 1.0;
    dotColor *= colorVar;
    
    // Final depth adjustment - less in shadows for contrast
    float depthFactor = 1.0 - dist * 0.3;
    depthFactor *= (1.0 - vShadow * 0.3);
    dotColor *= (0.8 + depthFactor * 0.2);
    
    gl_FragColor = vec4(dotColor, alpha);
}