uniform vec3 uBaseColor;
uniform float uTime;
uniform float uGlowIntensity;
uniform float uTransparency;
uniform float uSeed;
uniform float uColorCoverage; // 0.0 to 1.0 - percentage of sphere that's colored from rim

// Glow control uniforms
uniform float uRimGlowIntensity;    // Controls rim glow strength (default: 1.8)
uniform float uRimGlowWidth;        // Controls rim glow width (default: 3.0 = pow exponent)
uniform float uAuraIntensity;       // Controls aura glow strength (default: 1.2)
uniform float uAuraWidth;           // Controls aura width (default: 2.0 = pow exponent)
uniform float uSpecularIntensity;   // Controls specular highlight strength (default: 0.8)
uniform float uSpecularSharpness;   // Controls specular sharpness (default: 24.0)
uniform float uBoundaryGlow;        // Controls boundary glow strength (default: 0.4)
uniform float uSurfaceGlow;         // Controls surface distortion glow (default: 0.2)
uniform float uShimmerIntensity;    // Controls shimmer effect (default: 0.08)
uniform float uOverallBoost;        // Overall brightness multiplier (default: 1.1)
uniform float uBlackTint;           // How much color bleeds into black areas (default: 0.03)
uniform float uBreathingIntensity;  // Breathing effect strength (default: 0.2)
uniform float uPulseIntensity;      // Pulse effect strength (default: 0.1)

uniform vec3 uSunPosition;

varying vec3 vNormal;
varying vec3 vPosition;
varying float vDistortion;

void main() {
    // Normalized normal for lighting
    vec3 normal = normalize(vNormal);
    
    // View direction
    vec3 viewDir = normalize(cameraPosition - vPosition);
    
    // Calculate radial distance from rim (0) to center (1) when viewed from front
    float rimToCenter = dot(normal, viewDir);
    rimToCenter = max(0.0, rimToCenter);
    
    // Create unique random patterns for each planet using seed
    float seedOffset1 = uSeed * 1.234;
    float seedOffset2 = uSeed * 5.678;
    float seedOffset3 = uSeed * 9.012;
    float seedOffset4 = uSeed * 3.456;
    float seedOffset5 = uSeed * 7.890;
    
    // Unique speed multipliers for each planet
    float speedMult1 = 0.5 + mod(uSeed * 0.123, 1.0); // 0.5 to 1.5
    float speedMult2 = 0.3 + mod(uSeed * 0.456, 1.2); // 0.3 to 1.5
    float speedMult3 = 0.4 + mod(uSeed * 0.789, 1.1); // 0.4 to 1.5
    
    // Random distortion for organic edge variation with unique speeds
    float edgeDistortion1 = sin(vPosition.x * (3.0 + seedOffset1) + uTime * speedMult1 + seedOffset1) * 
                            cos(vPosition.y * (4.0 - seedOffset2) - uTime * speedMult2 + seedOffset2);
    float edgeDistortion2 = sin(vPosition.z * (5.0 + seedOffset3) - uTime * speedMult3 + seedOffset3) * 
                            cos(vPosition.x * (3.5 - seedOffset4) + uTime * speedMult1 * 0.7 + seedOffset1);
    float edgeDistortion3 = sin(vPosition.y * (4.5 + seedOffset5) + uTime * speedMult2 * 0.8 + seedOffset4) * 
                            cos(vPosition.z * (3.0 + seedOffset1) - uTime * speedMult3 * 0.6 + seedOffset5);
    
    // Combine distortions for complex, unique edge movement
    float edgeVariation = (edgeDistortion1 + edgeDistortion2 * 0.7 + edgeDistortion3 * 0.5) * 0.08 + vDistortion * 0.1;
    
    // Apply color coverage from rim inward (controlled by uColorCoverage)
    // 0.1 = 10% colored from rim, 0.5 = 50% colored, etc.
    float colorThreshold = 1.0 - uColorCoverage;
    
    // Add distortion to the color boundary for organic movement
    float distortedBoundary = rimToCenter - colorThreshold + edgeVariation;
    
    // Create smooth gradient transition zone (softer edge)
    float gradientZone = 0.15; // Width of gradient transition
    float gradientFactor = smoothstep(0.0, gradientZone, distortedBoundary);
    
    // Much more varied breathing and pulse speeds for distinct timing
    // Wide speed ranges to ensure visible differences
    float breathSpeed = 0.1 + mod(uSeed * 0.234, 0.5); // 0.1 to 0.6 (6x variation)
    float pulseSpeed = 0.2 + mod(uSeed * 0.567, 0.8); // 0.2 to 1.0 (5x variation)
    // More dramatic phase differences
    float breathPhase = mod(uSeed * 7.891, 6.28318); // Full 2π range
    float pulsePhase = mod(uSeed * 4.567, 6.28318); // Full 2π range
    
    // Combine multiple sine waves for more organic movement
    float breathBase = sin(uTime * breathSpeed + breathPhase);
    float breathHarmonic = sin(uTime * breathSpeed * 2.1 + breathPhase) * 0.3;
    float breathingGlow = (breathBase + breathHarmonic) * uBreathingIntensity * 0.5 + 1.0;
    
    // Smoother pulse with harmonics
    float pulseBase = sin(uTime * pulseSpeed + pulsePhase);
    float pulseHarmonic = sin(uTime * pulseSpeed * 1.7 + pulsePhase) * 0.2;
    float pulseGlow = (pulseBase + pulseHarmonic) * uPulseIntensity * 0.6 + 1.0;
    
    // Glowing color with breathing effect
    vec3 glowingColor = uBaseColor * uGlowIntensity * breathingGlow;
    
    // Dynamic color bleeding in black areas with unique movement for each planet
    float bleedSpeed1 = 0.2 + mod(uSeed * 0.345, 0.8); // 0.2 to 1.0
    float bleedSpeed2 = 0.3 + mod(uSeed * 0.678, 0.9); // 0.3 to 1.2
    
    // Complex color bleeding pattern unique to each planet
    float colorBleed1 = sin(vPosition.x * (2.0 + seedOffset3) + uTime * bleedSpeed1 + seedOffset4) * 
                       cos(vPosition.y * (3.0 - seedOffset1) - uTime * bleedSpeed2 * 0.7);
    float colorBleed2 = sin(vPosition.z * (2.5 + seedOffset5) - uTime * bleedSpeed1 * 1.2 + seedOffset2) * 
                       cos(vPosition.x * (3.5 - seedOffset3) + uTime * bleedSpeed2);
    
    // Animated color bleed that moves differently for each planet
    float dynamicBleedAmount = uBlackTint * (1.0 + (colorBleed1 + colorBleed2) * 0.5);
    dynamicBleedAmount = max(0.0, dynamicBleedAmount);
    
    vec3 blackColor = uBaseColor * dynamicBleedAmount;
    
    // Create radial gradient from colored rim to black center
    vec3 color = mix(blackColor, glowingColor, 1.0 - gradientFactor);
    
    // Controllable fresnel for rim effects
    float fresnel = 1.0 - max(0.0, dot(normal, viewDir));
    float auraFresnel = pow(fresnel, uAuraWidth);
    float rimFresnel = pow(fresnel, uRimGlowWidth);
    
    // Colored rim glow with controllable intensity
    vec3 rimGlow = uBaseColor * uRimGlowIntensity * pulseGlow;
    color = mix(color, rimGlow, rimFresnel * 0.5);
    
    // Controllable aura glow
    vec3 auraGlow = uBaseColor * uAuraIntensity * breathingGlow;
    color += auraGlow * auraFresnel * 0.2;
    
    // Controllable specular highlights
    vec3 reflectDir = reflect(-viewDir, normal);
    vec3 lightDir = normalize(vec3(0.5, 1.0, 0.5));
    float specular = pow(max(0.0, dot(reflectDir, lightDir)), uSpecularSharpness);
    vec3 specularColor = uBaseColor * specular * uSpecularIntensity;
    color += specularColor * breathingGlow * 0.5;
    
    // Controllable boundary glow
    float boundaryGlowFactor = 1.0 - abs(distortedBoundary - gradientZone * 0.5);
    boundaryGlowFactor = pow(max(0.0, boundaryGlowFactor), 3.0);
    color += uBaseColor * boundaryGlowFactor * uBoundaryGlow * pulseGlow;
    
    // Controllable surface glow
    float surfaceGlowFactor = abs(vDistortion) * 1.5;
    color += uBaseColor * surfaceGlowFactor * uSurfaceGlow;
    
    // Smooth organic shimmer optimized for 60FPS
    float shimmerSpeed1 = 0.8 + mod(uSeed * 0.891, 0.5); // 0.8 to 1.3 (smooth speed)
    float shimmerSpeed2 = 0.6 + mod(uSeed * 0.432, 0.4); // 0.6 to 1.0 (gentle variation)
    
    // Multi-layer shimmer for organic feel
    float shimmerBase = sin(uTime * shimmerSpeed1 + vPosition.x * (5.0 + seedOffset3) + seedOffset1) * 
                       sin(uTime * shimmerSpeed2 - vPosition.y * (4.0 + seedOffset4) + seedOffset2);
    
    // Add subtle secondary shimmer for complexity
    float shimmerSecondary = sin(uTime * shimmerSpeed1 * 0.7 + vPosition.z * 3.0 + seedOffset5) * 0.3;
    
    // Combine and smooth the shimmer
    float shimmerCombined = (shimmerBase + shimmerSecondary) * uShimmerIntensity * 0.6;
    float shimmer = shimmerCombined + 1.0;
    
    // Apply smooth shimmer
    color *= shimmer;
    
    // Controllable overall boost
    color *= uOverallBoost;
    
    // Transparency with slight variation
    float alpha = min(uTransparency * (0.9 + fresnel * 0.1), 1.0);
    
    // Output shiny glowing color
    gl_FragColor = vec4(color, alpha);
}