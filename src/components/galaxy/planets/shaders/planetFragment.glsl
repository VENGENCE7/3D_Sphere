uniform vec3 uBaseColor;
uniform float uTime;
uniform float uGlowIntensity;
uniform vec3 uSunPosition;

varying vec3 vNormal;
varying vec3 vPosition;
varying float vDistortion;

void main() {
    // Normalized normal for lighting
    vec3 normal = normalize(vNormal);
    
    // View direction
    vec3 viewDir = normalize(cameraPosition - vPosition);
    
    // Simple gradient from base color to black
    vec3 gradientColors[5];
    gradientColors[0] = uBaseColor;
    gradientColors[1] = uBaseColor * 0.7;
    gradientColors[2] = uBaseColor * 0.4;
    gradientColors[3] = uBaseColor * 0.2;
    gradientColors[4] = vec3(0.0, 0.0, 0.0); // Black
    
    // Calculate gradient based on view angle and position
    float gradientFactor = dot(normal, viewDir);
    gradientFactor = pow(max(0.0, gradientFactor), 0.8);
    
    // Mix colors based on gradient
    vec3 color = mix(gradientColors[4], gradientColors[0], gradientFactor);
    
    // Add highlight on top
    vec3 up = vec3(0.0, 1.0, 0.0);
    float topLight = dot(normal, up) * 0.5 + 0.5;
    topLight = pow(topLight, 2.0);
    color = mix(color, color * 1.3, topLight * 0.5);
    
    // Fresnel effect for rim glow
    float fresnel = 1.0 - max(0.0, dot(normal, viewDir));
    fresnel = pow(fresnel, 2.0);
    
    // Add subtle glow
    vec3 glowColor = uBaseColor * 1.5;
    color = mix(color, glowColor, fresnel * uGlowIntensity);
    
    // Add variation based on distortion
    color *= 1.0 + vDistortion * 0.2;
    
    // Subtle animation to the colors
    float colorShift = sin(uTime * 0.5 + vPosition.x * 2.0) * 0.05 + 1.0;
    color *= colorShift;
    
    // Output final color
    gl_FragColor = vec4(color, 1.0);
}