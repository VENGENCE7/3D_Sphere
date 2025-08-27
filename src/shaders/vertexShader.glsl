uniform float uTime;

attribute vec3 initialPosition;
attribute float aRandom;

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

const float radius = 1.5;
const float PI = 3.14159265359;

// Create wave-like liquid motion with random origins and directions
float createFoldingWaves(vec3 p) {
    float r = length(p);
    float theta = atan(p.z, p.x);
    float phi = acos(p.y / max(r, 0.001));
    
    // Use the time uniform for animation
    float time = uTime;
    
    // Multiple wave sources with different origins and directions
    // Wave 1: Originating from top-left, moving diagonally
    vec3 origin1 = vec3(-0.8, 0.8, 0.5);
    float dist1 = length(p - origin1);
    float wave1 = sin(dist1 * 8.0 - time * 2.0) * exp(-dist1 * 0.8) * 0.12;
    
    // Wave 2: Originating from bottom-right, moving upward
    vec3 origin2 = vec3(0.9, -0.7, -0.4);
    float dist2 = length(p - origin2);
    float wave2 = cos(dist2 * 6.0 - time * 1.5 + 1.0) * exp(-dist2 * 0.6) * 0.10;
    
    // Wave 3: Originating from front-center, spreading outward
    vec3 origin3 = vec3(0.2, 0.1, 1.2);
    float dist3 = length(p - origin3);
    float wave3 = sin(dist3 * 10.0 - time * 2.5 + 2.0) * exp(-dist3 * 1.0) * 0.08;
    
    // Wave 4: Originating from back-left, moving right
    vec3 origin4 = vec3(-1.0, 0.3, -0.8);
    float dist4 = length(p - origin4);
    float wave4 = cos(dist4 * 7.0 - time * 1.8 + 3.5) * exp(-dist4 * 0.7) * 0.09;
    
    // Wave 5: Random circular wave from side
    vec3 origin5 = vec3(0.6, -0.9, 0.2);
    float dist5 = length(p - origin5);
    float wave5 = sin(dist5 * 9.0 - time * 2.2 + 4.8) * exp(-dist5 * 0.9) * 0.07;
    
    // Combine all waves with liquid-like interference
    float totalWave = wave1 + wave2 + wave3 + wave4 + wave5;
    
    // Add some overall gentle undulation
    float baseUndulation = sin(theta * 2.0 + time * 0.5) * cos(phi * 1.5 + time * 0.3) * 0.03;
    
    totalWave += baseUndulation;
    
    // Clamp to maintain spherical shape
    return clamp(totalWave, -0.15, 0.15);
}

// Create secondary ripples that follow the liquid motion
float createBendingWaves(vec3 p) {
    float theta = atan(p.z, p.x);
    float phi = acos(p.y / max(length(p), 0.001));
    float time = uTime;
    
    // Fast-moving surface ripples
    float ripple1 = sin(theta * 8.0 + time * 3.0) * cos(phi * 6.0 - time * 2.5) * 0.025;
    float ripple2 = cos(phi * 10.0 + time * 4.0) * sin(theta * 5.0 - time * 3.5) * 0.020;
    
    // Higher frequency surface texture that moves
    float texture = sin((p.x + p.y + p.z) * 15.0 + time * 5.0) * 0.015;
    
    return ripple1 + ripple2 + texture;
}

// Create very subtle random motion variations
float createAsymmetricDistortion(vec3 p) {
    float time = uTime;
    
    // Slow random drifting motion
    float drift1 = sin(p.x * 2.0 + time * 0.8) * cos(p.y * 1.5 + time * 0.6) * 0.008;
    float drift2 = cos(p.z * 2.5 + time * 0.4) * sin(p.x * 1.8 + time * 0.9) * 0.006;
    
    return drift1 + drift2;
}

// Main shape function - maintains spherical form with continuous folds
float createSphericalShape(vec3 p) {
    float r = length(p);
    float baseShape = radius - r;
    
    // Apply waves with controlled amplitude to maintain sphere shape
    float foldingWaves = createFoldingWaves(p); // Already normalized
    float bendingWaves = createBendingWaves(p); // Small secondary waves
    float asymmetric = createAsymmetricDistortion(p); // Very subtle
    
    // Combine all displacements
    float totalDisplacement = foldingWaves + bendingWaves + asymmetric;
    
    // Ensure we maintain spherical shape when zoomed out
    // by limiting the maximum displacement
    totalDisplacement = clamp(totalDisplacement, -0.35, 0.35);
    
    return baseShape + totalDisplacement;
}

// Calculate shadow occlusion from neighboring peaks
float calculateShadowOcclusion(vec3 pos, vec3 sunDir, float currentHeight) {
    float shadow = 1.0;
    
    // Sample neighboring points in the direction of the sun
    for(float i = 0.1; i <= 0.5; i += 0.1) {
        vec3 samplePos = pos + sunDir * i * 0.5;
        float sampleHeight = createSphericalShape(samplePos);
        
        // If neighbor is higher and blocks sun, create shadow
        if(sampleHeight > currentHeight + 0.02) {
            float blockAmount = (sampleHeight - currentHeight) * 5.0;
            shadow *= (1.0 - min(blockAmount, 0.8));
        }
    }
    
    return shadow;
}

void main() {
    vec3 pos = initialPosition;
    vec3 originalNormal = normalize(pos);
    
    // Get the main shape displacement
    float shapeDisplacement = createSphericalShape(pos);
    float surfaceDetail = sin(pos.x * 15.0 + pos.y * 12.0) * cos(pos.z * 14.0) * 0.02;
    float totalDisplacement = shapeDisplacement + surfaceDetail;
    
    // Apply displacement along the normal
    vec3 displaced = pos + originalNormal * totalDisplacement;
    
    // Store fold depth for fragment shader
    vFoldDepth = createFoldingWaves(pos);
    vRadialDist = length(displaced) / radius;
    
    // Calculate edge fade
    vec3 viewDir = normalize(cameraPosition - displaced);
    float edgeFactor = dot(originalNormal, viewDir);
    vEdgeFade = smoothstep(0.0, 0.8, abs(edgeFactor));
    
    // Extra fade in deep folds
    if (vFoldDepth < -0.15) {
        float foldFade = 1.0 + vFoldDepth * 3.0;
        vEdgeFade *= max(foldFade, 0.2);
    }
    
    vDistortion = totalDisplacement;
    
    // Calculate perturbed normal
    vec3 tangent1 = normalize(cross(originalNormal, vec3(0.0, 1.0, 0.0)));
    if (length(tangent1) < 0.01) {
        tangent1 = normalize(cross(originalNormal, vec3(1.0, 0.0, 0.0)));
    }
    vec3 tangent2 = normalize(cross(originalNormal, tangent1));
    
    float epsilon = 0.01;
    vec3 posT1 = pos + tangent1 * epsilon;
    vec3 posT2 = pos + tangent2 * epsilon;
    float dispT1 = createSphericalShape(posT1);
    float dispT2 = createSphericalShape(posT2);
    
    vec3 perturbedNormal = normalize(originalNormal + 
        tangent1 * (dispT1 - shapeDisplacement) * 30.0 + 
        tangent2 * (dispT2 - shapeDisplacement) * 30.0);
    
    vNormal = perturbedNormal;
    vWorldPos = displaced;
    
    // Transform to world space
    vec4 worldPos4 = modelMatrix * vec4(displaced, 1.0);
    vec3 worldPosition = worldPos4.xyz;
    vec3 worldNormal = normalize((modelMatrix * vec4(perturbedNormal, 0.0)).xyz);
    
    // SUN POSITION: Directly in front
    // In view space: 
    //  - X = 0.0: Centered horizontally (not left or right)
    //  - Y = 1.0: Slightly above center
    //  - Z = 3.0: In front of the sphere (toward the viewer)
    vec3 sunPosition = vec3(5.0, 6.0, 7.0);
    vec3 sunDir = normalize(sunPosition - worldPosition);
    
    // Calculate sun illumination with stronger base lighting
    float sunLight = max(dot(worldNormal, sunDir), 0.25);
    
    // Add ambient lighting to brighten overall appearance
    float ambientLight = 0.5; // Base ambient light
    
    // Calculate shadow occlusion from peaks (reduced effect)
    float shadowOcclusion = calculateShadowOcclusion(pos, sunDir, totalDisplacement);
    shadowOcclusion = max(shadowOcclusion, 0.3); // Never completely dark
    
    // Front-facing surfaces are less dark now
    float frontFacing = max(dot(originalNormal, vec3(0.0, 0.0, 1.0)), 0.0);
    shadowOcclusion *= (1.0 - frontFacing * 0.2); // Reduced darkening
    
    // Apply shadow occlusion to sun light
    sunLight = sunLight * shadowOcclusion + ambientLight;
    
    // Deep valleys get less extreme shadows
    if (totalDisplacement < -0.05) {
        float valleyDepth = abs(totalDisplacement + 0.05) * 10.0;
        sunLight *= (1.0 - min(valleyDepth, 1.0)); // Less darkening
    }
    
    vSunLight = sunLight;
    vShadow = 1.0 - shadowOcclusion;
    
    // Calculate peak visibility based on angle
    float peakAngle = dot(viewDir, worldNormal);
    float peakVisibility = smoothstep(-0.2, 0.8, peakAngle);
    
    // Color palette
    vec3 black = vec3(0.0, 0.0, 0.0);
    vec3 deepViolet = vec3(0.12, 0.0, 0.30);     // #260059
    vec3 purple = vec3(0.4, 0.0, 0.8);           // #8000FF
    vec3 magenta = vec3(0.6, 0.0, 0.6);
    vec3 pink = vec3(0.8, 0.1, 0.4);             // #FF1A80
    vec3 hotPink = vec3(1.0, 0.2, 0.4);
    vec3 red = vec3(1.0, 0.1, 0.2);
    vec3 orange = vec3(1.0, 0.33, 0.0);          // #FF5500
    vec3 yellow = vec3(1.0, 0.9, 0.0);
    vec3 brightYellow = vec3(1.0, 1.0, 0.2);     // #FFFF33
    
    // Color based on sun illumination and height
    vec3 color;
    float colorFactor = sunLight * 0.8; // Scale down slightly since we have more light
    
    // Peaks get yellow when illuminated
    if (totalDisplacement > 0.1) {
        float peakFactor = smoothstep(0.1, 0.3, totalDisplacement);
        colorFactor += peakFactor * 0.4; // Stronger peak coloring
    }
    
    // Apply peak visibility - peaks viewed from top show less body color
    colorFactor *= (0.5 + peakVisibility * 0.5); // Less extreme visibility effect
    
    colorFactor = clamp(colorFactor, 0.0, 1.0);
    
    // Gradient mapping based on illumination - adjusted thresholds for more color
    if (colorFactor < 0.02) {
        // Only deepest shadows are black
        color = black;
    } else if (colorFactor < 0.1) {
        // Shadow to deep violet
        float t = (colorFactor - 0.02) / 0.08;
        color = mix(black, deepViolet, t);
    } else if (colorFactor < 0.2) {
        // Deep violet to purple
        float t = (colorFactor - 0.1) / 0.1;
        color = mix(deepViolet, purple, t);
    } else if (colorFactor < 0.3) {
        // Purple to magenta
        float t = (colorFactor - 0.2) / 0.1;
        color = mix(purple, magenta, t);
    } else if (colorFactor < 0.4) {
        // Magenta to pink
        float t = (colorFactor - 0.3) / 0.1;
        color = mix(magenta, pink, t);
    } else if (colorFactor < 0.5) {
        // Pink to hot pink
        float t = (colorFactor - 0.4) / 0.1;
        color = mix(pink, hotPink, t);
    } else if (colorFactor < 0.6) {
        // Hot pink to red
        float t = (colorFactor - 0.5) / 0.1;
        color = mix(hotPink, red, t);
    } else if (colorFactor < 0.7) {
        // Red to orange
        float t = (colorFactor - 0.6) / 0.1;
        color = mix(red, orange, t);
    } else if (colorFactor < 0.85) {
        // Orange to yellow
        float t = (colorFactor - 0.7) / 0.15;
        color = mix(orange, yellow, t);
    } else {
        // Yellow to bright yellow on highest peaks
        float t = (colorFactor - 0.85) / 0.15;
        color = mix(yellow, brightYellow, t);
    }
    
    // Reduced shadow darkening
    if (vShadow > 0.5) {
        color = mix(color, color * 0.5, (vShadow - 0.5) * 0.6);
    }
    
    // Front-facing surfaces are only slightly darker
    color = mix(color, color * 0.7, frontFacing * 0.3);
    
    // Peak bodies get gradient based on angle
    if (totalDisplacement > 0.05 && peakVisibility < 0.7) {
        // Peak body visible from side - apply gradient
        float bodyGradient = 1.0 - peakVisibility;
        vec3 bodyColor = mix(color, mix(purple, magenta, bodyGradient), 0.4);
        color = mix(color, bodyColor, bodyGradient);
    }
    
    // Boost overall intensity for brighter appearance
    vIntensity = sunLight * 0.9 + 0.3;
    
    // Apply overall brightness boost to colors
    color = color * 1.2; // Make all colors brighter
    vColor = color;
    
    // Screen position
    vec4 mvPosition = modelViewMatrix * vec4(displaced, 1.0);
    
    // Point sizing - doubled
    float baseSize = 3.0; // Doubled from 1.5
    
    // Size variation based on folds
    float foldSize = 1.0;
    if (vFoldDepth < -0.1) {
        foldSize = 0.6 + (vFoldDepth + 0.3) * 2.0;
        foldSize = max(foldSize, 0.3);
    } else if (vFoldDepth > 0.1) {
        foldSize = 1.0 + vFoldDepth * 0.5;
    }
    
    // Smaller dots in shadows for depth
    float shadowSize = mix(0.7, 1.0, shadowOcclusion);
    
    float edgeSize = mix(0.4, 1.0, pow(vEdgeFade, 0.6)); // Increased minimum from 0.2 to 0.4
    float randomSize = 0.8 + aRandom * 0.4;
    float distSize = 1.0 + abs(totalDisplacement) * 0.8;
    
    gl_PointSize = baseSize * foldSize * shadowSize * edgeSize * randomSize * distSize * (300.0 / -mvPosition.z);
    gl_PointSize = clamp(gl_PointSize, 0.4, 14.0); // Doubled min and max sizes
    
    gl_Position = projectionMatrix * mvPosition;
}