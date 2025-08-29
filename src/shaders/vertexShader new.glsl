uniform float uTime;
uniform float uCameraDistance;

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
varying float vWaveDisplacement;  // For color flow with waves

const float radius = 1.5;
const float PI = 3.14159265359;

// ========================================
// WAVE SYSTEM - Creates animated liquid-like waves on sphere surface
// TO DISABLE ALL WAVES: Return 0.0 at the beginning of this function
// ========================================
float createFoldingWaves(vec3 p) {
    float time = uTime;
    
    // === COSMIC WAVE CONTROLS ===
    float WAVE_FREQUENCY = 5.0;       // Ripple frequency
    float WAVE_SPEED = 0.25;          // Wave expansion speed
    float WAVE_THICKNESS = 0.35;      // Wave ring thickness  
    float WAVE_AMPLITUDE = 0.25;      // Base wave amplitude
    float WAVE_DECAY = 1.2;           // How fast waves fade with distance
    float ORIGIN_SPEED = 0.2;         // How fast origins orbit the sphere
    float MIN_ORIGIN_DISTANCE = 0.7;  // Minimum distance between origins
    
    // === THREE MOVING WAVE ORIGINS ===
    // Origins orbit the sphere creating dynamic, ever-changing patterns
    
    // Origin 1: Horizontal orbit with slight vertical oscillation
    float orbit1 = time * ORIGIN_SPEED;
    vec3 origin1 = normalize(vec3(
        cos(orbit1) * 1.2,
        sin(orbit1 * 0.7) * 0.6,  // Vertical wobble
        sin(orbit1) * 1.2
    ));
    
    // Origin 2: Diagonal orbit, offset from origin 1
    float orbit2 = time * ORIGIN_SPEED * 0.8 + 2.094;  // Different speed and phase
    vec3 origin2 = normalize(vec3(
        cos(orbit2 * 1.3) * 1.1,
        sin(orbit2) * 0.9,
        sin(orbit2 * 1.1) * 1.1
    ));
    
    // Origin 3: Vertical orbit with complex motion
    float orbit3 = time * ORIGIN_SPEED * 1.2 + 4.189;  // Fastest orbit
    vec3 origin3 = normalize(vec3(
        sin(orbit3 * 0.9) * 0.8,
        cos(orbit3 * 0.7) * 1.3,
        cos(orbit3 * 1.2) * 0.8
    ));
    
    // Ensure minimum distance between origins (push apart if too close)
    vec3 separation12 = origin2 - origin1;
    vec3 separation13 = origin3 - origin1;
    vec3 separation23 = origin3 - origin2;
    
    float dist12 = length(separation12);
    float dist13 = length(separation13);
    float dist23 = length(separation23);
    
    // Adjust origins if they're too close
    if (dist12 < MIN_ORIGIN_DISTANCE) {
        origin2 = normalize(origin1 + normalize(separation12) * MIN_ORIGIN_DISTANCE);
    }
    if (dist13 < MIN_ORIGIN_DISTANCE) {
        origin3 = normalize(origin1 + normalize(separation13) * MIN_ORIGIN_DISTANCE);
    }
    
    // === CONTINUOUS WAVE GENERATION FROM ALL THREE ORIGINS ===
    float totalWave = 0.0;
    
    // Wave from Origin 1
    float dist1 = length(p - origin1);
    for (float i = 0.0; i < 3.0; i++) {
        float waveTime = time + i * 2.5;  // Offset each wave
        float waveRadius = mod(waveTime * WAVE_SPEED, 2.5);  // Waves continuously expand to radius 2.5
        float ringDist = abs(dist1 - waveRadius);
        
        if (ringDist < WAVE_THICKNESS) {
            float decay = exp(-waveRadius * WAVE_DECAY);  // Waves fade with distance
            float intensity = (1.0 - ringDist / WAVE_THICKNESS) * decay;
            float waveShape = sin(ringDist * WAVE_FREQUENCY + waveTime * 2.0);
            totalWave += waveShape * intensity * WAVE_AMPLITUDE;
        }
    }
    
    // Wave from Origin 2
    float dist2 = length(p - origin2);
    for (float i = 0.0; i < 3.0; i++) {
        float waveTime = time + i * 2.5 + 1.0;  // Different phase offset
        float waveRadius = mod(waveTime * WAVE_SPEED * 0.9, 2.5);  // Slightly different speed
        float ringDist = abs(dist2 - waveRadius);
        
        if (ringDist < WAVE_THICKNESS) {
            float decay = exp(-waveRadius * WAVE_DECAY);
            float intensity = (1.0 - ringDist / WAVE_THICKNESS) * decay;
            float waveShape = sin(ringDist * WAVE_FREQUENCY * 1.1 + waveTime * 2.2);
            totalWave += waveShape * intensity * WAVE_AMPLITUDE;
        }
    }
    
    // Wave from Origin 3
    float dist3 = length(p - origin3);
    for (float i = 0.0; i < 3.0; i++) {
        float waveTime = time + i * 2.5 + 2.0;  // Another phase offset
        float waveRadius = mod(waveTime * WAVE_SPEED * 1.1, 2.5);  // Fastest waves
        float ringDist = abs(dist3 - waveRadius);
        
        if (ringDist < WAVE_THICKNESS) {
            float decay = exp(-waveRadius * WAVE_DECAY);
            float intensity = (1.0 - ringDist / WAVE_THICKNESS) * decay;
            float waveShape = sin(ringDist * WAVE_FREQUENCY * 0.9 + waveTime * 1.8);
            totalWave += waveShape * intensity * WAVE_AMPLITUDE;
        }
    }
    
    // === WAVE INTERFERENCE AND CLASH EFFECTS ===
    // Where waves meet, they create complex interference patterns
    
    // Check for wave overlaps (clash zones)
    float overlap12 = max(0.0, 1.0 - dist12 / (WAVE_THICKNESS * 4.0));
    float overlap13 = max(0.0, 1.0 - dist13 / (WAVE_THICKNESS * 4.0));
    float overlap23 = max(0.0, 1.0 - dist23 / (WAVE_THICKNESS * 4.0));
    
    // Amplify waves at clash points
    float clashBoost = 1.0 + (overlap12 + overlap13 + overlap23) * 0.8;
    totalWave *= clashBoost;
    
    // Add turbulence at clash zones
    if (overlap12 > 0.1 || overlap13 > 0.1 || overlap23 > 0.1) {
        float turbulence = sin(dist1 * 15.0 + time * 5.0) * 0.03;
        turbulence += cos(dist2 * 12.0 - time * 4.0) * 0.02;
        totalWave += turbulence * (overlap12 + overlap13 + overlap23);
    }
    
    // === COSMIC UNSTABLE SHAPE ===
    // Add low-frequency deformation for organic, unstable appearance
    float cosmicDeform = sin(p.x * 2.0 + time * 0.5) * cos(p.y * 1.5 - time * 0.3) * 0.03;
    cosmicDeform += sin(p.z * 1.8 + time * 0.4) * sin(p.x * 2.2 + time * 0.6) * 0.02;
    totalWave += cosmicDeform;
    
    // Edge behavior - maintain roughly spherical shape
    float edgeFactor = smoothstep(1.2, 1.5, length(p));
    totalWave *= (1.0 - edgeFactor * 0.5);  // Reduce displacement at edges
    
    // Store wave displacement for color flow (will be used later)
    vWaveDisplacement = totalWave;
    
    // Clamp to maintain recognizable sphere shape while allowing dramatic deformation
    return clamp(totalWave, -0.2, 0.25);
}


// ========================================
// SECONDARY RIPPLES - Small fast-moving surface details
// TO DISABLE: Return 0.0 at the beginning of this function
// ========================================
float createBendingWaves(vec3 p) {
    // === RIPPLE TOGGLE - UNCOMMENT TO DISABLE ===
    return 0.0;  // <-- UNCOMMENT THIS LINE TO TURN OFF RIPPLES
    
    // Convert position to spherical coordinates for wave patterns
    float theta = atan(p.z, p.x);  // Horizontal angle
    float phi = acos(p.y / max(length(p), 0.001));  // Vertical angle
    float time = uTime;
    
    // === FAST-MOVING SURFACE RIPPLES ===
    // These create small, quick waves across the surface
    // Amplitude: 0.025 and 0.020 (very small)
    float ripple1 = sin(theta * 8.0 + time * 3.0) * cos(phi * 6.0 - time * 2.5) * 0.025;
    float ripple2 = cos(phi * 10.0 + time * 4.0) * sin(theta * 5.0 - time * 3.5) * 0.020;
    
    // === HIGH-FREQUENCY TEXTURE ===
    // Creates a fine, animated surface texture
    // Frequency: 15.0 (very tight pattern), Speed: 5.0, Amplitude: 0.015
    float texture = sin((p.x + p.y + p.z) * 15.0 + time * 5.0) * 0.015;
    
    return ripple1 + ripple2 + texture;
}

// ========================================
// ASYMMETRIC DISTORTION - Subtle random organic motion
// TO DISABLE: Return 0.0 at the beginning of this function
// ========================================
float createAsymmetricDistortion(vec3 p) {
    // === DISTORTION TOGGLE - UNCOMMENT TO DISABLE ===
    // return 0.0;  // <-- UNCOMMENT THIS LINE TO TURN OFF DISTORTION
    
    float time = uTime;
    
    // === SLOW DRIFTING MOTION ===
    // Creates organic, non-uniform movement across the sphere
    // Very small amplitudes (0.008 and 0.006) for subtlety
    float drift1 = sin(p.x * 2.0 + time * 0.8) * cos(p.y * 1.5 + time * 0.6) * 0.008;
    float drift2 = cos(p.z * 2.5 + time * 0.4) * sin(p.x * 1.8 + time * 0.9) * 0.006;
    
    return drift1 + drift2;
}

// ========================================
// MAIN SHAPE FUNCTION - Combines all wave effects
// This is the master function that creates the final sphere deformation
// ========================================
float createSphericalShape(vec3 p) {
    float r = length(p);
    float baseShape = radius - r;  // Basic sphere shape (radius = 1.5)
    
    // === COMBINE ALL WAVE SYSTEMS ===
    // Each function can be disabled individually by returning 0.0 in that function
    float foldingWaves = createFoldingWaves(p);        // Main animated waves (largest effect)
    float bendingWaves = createBendingWaves(p);        // Fast surface ripples (medium effect)
    float asymmetric = createAsymmetricDistortion(p);  // Organic drift (smallest effect)
    
    // Sum all wave displacements
    float totalDisplacement = foldingWaves + bendingWaves + asymmetric;
    
    // === DISPLACEMENT LIMITER ===
    // Prevents extreme deformation to maintain recognizable sphere shape
    // Range: -0.35 to +0.35 units from base sphere surface
    totalDisplacement = clamp(totalDisplacement, -0.35, 0.35);
    
    return baseShape + totalDisplacement;
}

// Removed shadow occlusion calculation - no shadows needed

void main() {
    vec3 pos = initialPosition;
    vec3 originalNormal = normalize(pos);
    
    // Get the main shape displacement
    float shapeDisplacement = createSphericalShape(pos);
    float totalDisplacement = shapeDisplacement;
    
    // Apply displacement along the normal
    vec3 displaced = pos + originalNormal * totalDisplacement;
    
    // Store fold depth for fragment shader
    vFoldDepth = createFoldingWaves(pos);
    vRadialDist = length(displaced) / radius;
    
    // Calculate edge fade - ensure no black at meridian
    vec3 viewDir = normalize(cameraPosition - displaced);
    float edgeFactor = abs(dot(originalNormal, viewDir)); 
    // Minimum fade of 0.7 to prevent black strips
    vEdgeFade = max(0.7, smoothstep(0.1, 0.9, edgeFactor));
    
    // For a complete sphere with colors on both sides, we don't want to make back faces black
    // Instead, we'll treat both sides the same
    float isBackFacing = 0.0; // Disabled - treat all surfaces the same
    
    // Reduced fade in deep folds to maintain visibility
    if (vFoldDepth < -0.15) {
        float foldFade = 1.0 + vFoldDepth * 1.5; // Reduced from 3.0
        vEdgeFade *= max(foldFade, 0.6); // Minimum 0.6 (was 0.2)
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
    
   
    
    // === ECLIPSE-STYLE RADIAL GRADIENT ===
    // Eclipse color palette with smooth blending colors
    vec3 centerBlack = vec3(0.078, 0.098, 0.086); // #141916 - Center black
    vec3 deepViolet = vec3(0.12, 0.0, 0.30);      // #1F004D - Deep violet core
    vec3 purple = vec3(0.35, 0.0, 0.7);           // #5900B3 - Rich purple
    vec3 darkBlue = vec3(0.1, 0.0, 0.59);         // #190096 - Dark blue
    vec3 blue = vec3(0.26, 0.0, 0.93);            // #4200EE - Blue
    vec3 magenta = vec3(0.6, 0.0, 0.6);           // #9900CC - True magenta
    vec3 pink = vec3(0.85, 0.15, 0.45);           // #D9266B - Vivid pink
    vec3 red = vec3(1.0, 0.1, 0.2);               // #FF1A33 - Bright red
    vec3 orange = vec3(1.0, 0.4, 0.0);            // #FF6600 - Pure orange
    vec3 goldenYellow = vec3(1.0, 0.8, 0.2);      // #FFCC33 - Golden yellow
    vec3 brightGold = vec3(1.0, 0.9, 0.4);        // #FFE566 - Bright gold corona
    vec3 coronaGlow = vec3(1.0, 1.0, 0.5);        // Light golden corona
    
    // Additional colors for lower half gradient
    vec3 whiteStripe = vec3(1.0, 1.0, 1.0);       // White thin band
    vec3 brightRed = vec3(1.0, 0.106, 0.09);      // #ff1b17 - Bright red
    vec3 deepPurple = vec3(0.11, 0.0, 0.204);     // rgba(28,0,52) - Deep purple
    vec3 winePurple = vec3(0.318, 0.063, 0.188);  // #511030 - Wine purple
    
    // === CORONA & WARM GRADIENT CONFIGURATION ===
    // ADJUST THESE VALUES TO CHANGE CORONA AND WARM COLOR COVERAGE:
    float CORONA_TOP_COVERAGE = 0.10;    // 10% coverage at top (Y-axis) - full thickness
    float CORONA_BOTTOM_COVERAGE = 0.02; // 2% coverage at bottom (Y-axis) - full thickness
    float CORONA_EQUATOR_THINNING = 0.01; // Corona thickness at equator sides (1% of rim = extremely thin line)
    
    // Warm gradient (red/orange/golden) thickness configuration
    float WARM_GRADIENT_TOP_START = 0.68;    // Where warm colors start on top (68% = more cool colors)
    float WARM_GRADIENT_BOTTOM_START = 0.70; // Where warm colors start on bottom (70% = even more cool colors)
    float WARM_GRADIENT_EQUATOR_COMPRESSION = 0.5; // How much to compress warm colors at equator (0.5 = 50% thinner)
    // =============================
    
    // Calculate rim factor for eclipse effect
    vec3 worldViewDir = normalize(cameraPosition - worldPosition);
    float rimFactor = 1.0 - abs(dot(perturbedNormal, worldViewDir)); // 0 at center, 1 at edges
    
    // Smooth rim detection for gradient
    float eclipseRim = pow(rimFactor, 1.0); // Balanced power for symmetric gradient
    
    // Calculate vertical position
    float verticalPosition = worldNormal.y; // -1 at bottom, 0 at equator, 1 at top
    
    // Check if we're viewing from the front
    float frontFacing = max(0.0, dot(worldViewDir, vec3(0.0, 0.0, 1.0)));
    
    // Simple symmetric eclipse factor - same for both halves
    // Only the corona band will have variable thickness
    float eclipseFactor = eclipseRim;
    
    // Smooth the eclipse factor to prevent banding
    eclipseFactor = smoothstep(0.0, 1.0, eclipseFactor);
    
    // === ASYMMETRIC COLOR GRADIENT WITH SMOOTH EQUATOR BLENDING ===
    vec3 color = centerBlack; // Start with center black color
    
    // Calculate smooth blending factor for equator transition
    // -0.3 to 0.3 is the blending zone
    float equatorBlend = smoothstep(-0.3, 0.3, verticalPosition); // 0 = lower, 1 = upper
    
    // Calculate warm gradient compression based on position
    float equatorProximity = 1.0 - abs(verticalPosition); // 1 at equator, 0 at poles
    float warmGradientCompression = mix(1.0, WARM_GRADIENT_EQUATOR_COMPRESSION, 
                                       smoothstep(0.0, 0.8, equatorProximity));
    
    // Calculate both color gradients
    vec3 upperColor = centerBlack;
    vec3 lowerColor = centerBlack;
    
    // === UPPER GRADIENT - Full color spectrum ===
    // Center Black → Deep Violet (0.0-0.25)
    if (eclipseFactor > 0.0) {
        float t = smoothstep(0.0, 0.25, eclipseFactor);
        upperColor = mix(centerBlack, deepViolet, t);
    }
    
    // Deep Violet → Purple (0.20-0.35)
    if (eclipseFactor > 0.20) {
        float t = smoothstep(0.20, 0.35, eclipseFactor);
        upperColor = mix(upperColor, purple, t * 0.9);
    }
    
    // Purple → Dark Blue (0.30-0.45)
    if (eclipseFactor > 0.30) {
        float t = smoothstep(0.30, 0.45, eclipseFactor);
        upperColor = mix(upperColor, darkBlue, t * 0.85);
    }
    
    // Dark Blue → Blue (0.40-0.55)
    if (eclipseFactor > 0.40) {
        float t = smoothstep(0.40, 0.55, eclipseFactor);
        upperColor = mix(upperColor, blue, t * 0.9);
    }
    
    // Blue → Magenta (0.50-0.65)
    if (eclipseFactor > 0.50) {
        float t = smoothstep(0.50, 0.65, eclipseFactor);
        upperColor = mix(upperColor, magenta, t * 0.95);
    }
    
    // Magenta → Pink (0.60-0.72)
    if (eclipseFactor > 0.60) {
        float t = smoothstep(0.60, 0.72, eclipseFactor);
        upperColor = mix(upperColor, pink, t * 0.9);
    }
    
    // Apply warm gradient compression for upper hemisphere
    float warmStartUpper = mix(WARM_GRADIENT_TOP_START, 0.85, 1.0 - warmGradientCompression);
    
    // Pink → Red (compressed based on position)
    if (eclipseFactor > warmStartUpper) {
        float redEnd = warmStartUpper + 0.10 * warmGradientCompression;
        float t = smoothstep(warmStartUpper, redEnd, eclipseFactor);
        upperColor = mix(upperColor, red, t * 0.95);
    }
    
    // Red → Orange (compressed)
    if (eclipseFactor > warmStartUpper + 0.06 * warmGradientCompression) {
        float orangeStart = warmStartUpper + 0.06 * warmGradientCompression;
        float orangeEnd = warmStartUpper + 0.11 * warmGradientCompression;
        float t = smoothstep(orangeStart, orangeEnd, eclipseFactor);
        upperColor = mix(upperColor, orange, t * 0.85);
    }
    
    // Orange → Golden Yellow (compressed)
    if (eclipseFactor > warmStartUpper + 0.11 * warmGradientCompression) {
        float goldenStart = warmStartUpper + 0.11 * warmGradientCompression;
        float goldenEnd = min(0.90, warmStartUpper + 0.22 * warmGradientCompression);
        float t = smoothstep(goldenStart, goldenEnd, eclipseFactor);
        upperColor = mix(upperColor, goldenYellow, t * 0.9);
    }
    
    // === LOWER GRADIENT - Linear from center to rim ===
    // When viewed from front in 2D, gradient goes from center outward to rim
    
    // Calculate front-center restriction for special bands
    // Bands should appear in front center, not at edges
    float frontCenterFactor = 1.0;
    
    // Check if point is in front (positive Z) and near center (low X)
    float frontness = smoothstep(-0.3, 0.3, worldNormal.z); // 1 when facing front, 0 at sides/back
    float centerness = 1.0 - smoothstep(0.0, 0.7, abs(worldNormal.x)); // 1 at center, 0 at sides
    
    // Combine to create bands that appear in front-center area only
    float bandVisibility = frontness * centerness;
    
    // For radial distance-based bands (appear at specific distance from center)
    float radialDistance = length(vec2(worldNormal.x, worldNormal.z)); // Distance from Y-axis
    float bandRadialFactor = smoothstep(0.2, 0.6, radialDistance) * (1.0 - smoothstep(0.7, 0.95, radialDistance));
    
    // Check if we're in the special band region (10 degrees below equator, covering 25% of lower half)
    float specialBandStart = -0.174; // 10 degrees below equator
    float specialBandEnd = -0.425;   // 25% into lower half
    float inSpecialBandRegion = smoothstep(specialBandEnd - 0.05, specialBandEnd, verticalPosition) * 
                                smoothstep(specialBandStart + 0.05, specialBandStart, verticalPosition);
    
    // Dark base: Center Black → Deep Violet (0.0-0.30)
    if (eclipseFactor > 0.0) {
        float t = smoothstep(0.0, 0.30, eclipseFactor);
        lowerColor = mix(centerBlack, deepViolet, t);
    }
    
    // === SPECIAL BANDS SECTION (positioned 10° below equator, 25% height) ===
    // These bands appear in front-center area, not at edges
    
    // Deep Violet → Magenta (0.30-0.40) - front-center only, in special region
    if (eclipseFactor > 0.30 && eclipseFactor < 0.40 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.30, 0.40, eclipseFactor);
        // Use bandRadialFactor to position bands at mid-radius, not edges
        float magentaStrength = t * bandRadialFactor * inSpecialBandRegion * bandVisibility;
        lowerColor = mix(lowerColor, magenta, magentaStrength * 0.9);
    }
    
    // Magenta → White thin stripe (0.40-0.42) - front-center only, very thin
    if (eclipseFactor > 0.40 && eclipseFactor < 0.42 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.40, 0.42, eclipseFactor);
        // Position in front-center area
        float whiteStrength = t * bandRadialFactor * inSpecialBandRegion * bandVisibility;
        lowerColor = mix(lowerColor, whiteStripe, whiteStrength * 0.85);
    }
    
    // White → Bright Red #ff1b17 (0.42-0.50) - front-center only
    if (eclipseFactor > 0.42 && eclipseFactor < 0.50 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.42, 0.50, eclipseFactor);
        // Position in front-center area
        float redStrength = t * bandRadialFactor * inSpecialBandRegion * bandVisibility;
        lowerColor = mix(lowerColor, brightRed, redStrength * 0.9);
    }
    
    // Bright Red → Deep Purple rgba(28,0,52) (0.50-0.58) - front-center area
    if (eclipseFactor > 0.50 && eclipseFactor < 0.58 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.50, 0.58, eclipseFactor);
        // Slightly wider coverage for purple
        float purpleStrength = t * inSpecialBandRegion * bandVisibility * 
                              (bandRadialFactor * 0.7 + 0.3);
        lowerColor = mix(lowerColor, deepPurple, purpleStrength * 0.85);
    }
    
    // === CONTINUE REGULAR GRADIENT ===
    
    // Deep Purple/Deep Violet → Wine Purple #511030 (0.58-0.68) - full width
    if (eclipseFactor > 0.58) {
        float t = smoothstep(0.58, 0.68, eclipseFactor);
        lowerColor = mix(lowerColor, winePurple, t * 0.9);
    }
    
    // Apply warm gradient compression for final corona colors
    float warmStartLower = mix(0.68, 0.88, 1.0 - warmGradientCompression);
    
    // Wine Purple → Red (transition to corona colors)
    if (eclipseFactor > warmStartLower) {
        float redEnd = warmStartLower + 0.10 * warmGradientCompression;
        float t = smoothstep(warmStartLower, redEnd, eclipseFactor);
        lowerColor = mix(lowerColor, red, t * 0.85);
    }
    
    // Red → Golden Yellow (approaching corona)
    if (eclipseFactor > warmStartLower + 0.10 * warmGradientCompression) {
        float goldenStart = warmStartLower + 0.10 * warmGradientCompression;
        float goldenEnd = min(0.98, warmStartLower + 0.28 * warmGradientCompression);
        float t = smoothstep(goldenStart, goldenEnd, eclipseFactor);
        lowerColor = mix(lowerColor, goldenYellow, t * 0.9);
    }
    
    // === SMOOTH BLENDING AT EQUATOR ===
    // Blend between upper and lower gradients based on vertical position
    if (verticalPosition > 0.3) {
        // Pure upper gradient
        color = upperColor;
    } else if (verticalPosition < -0.3) {
        // Pure lower gradient
        color = lowerColor;
    } else {
        // Smooth blend zone at equator
        color = mix(lowerColor, upperColor, equatorBlend);
    }
    
    // === GOLDEN CORONA BAND - VARIABLE THICKNESS ===
    // The corona band appears only at the rim with variable thickness
    // Top/Bottom: Full thickness | Sides: Thin line based on configuration
    
    // Calculate base corona width based on vertical position
    float baseCoronaWidth;
    if (verticalPosition > 0.0) {
        // TOP HALF - uses CORONA_TOP_COVERAGE
        baseCoronaWidth = CORONA_TOP_COVERAGE;
    } else {
        // BOTTOM HALF - uses CORONA_BOTTOM_COVERAGE
        baseCoronaWidth = CORONA_BOTTOM_COVERAGE;
    }
    
    // Calculate thinning based on both X position (sides) and proximity to equator
    float sidePosition = abs(worldNormal.x); // 0 at front/back, 1 at left/right sides
    float coronaEquatorProximity = 1.0 - abs(verticalPosition); // 1 at equator, 0 at poles
    
    // Combine side and equator factors for maximum thinning effect
    // More aggressive thinning near equator AND at sides
    float thinningFactor = max(sidePosition, coronaEquatorProximity * 0.8);
    
    // Calculate corona width with smooth transition
    float coronaWidth;
    if (thinningFactor > 0.2) {
        // Smooth transition from full thickness to thin line
        // Using CORONA_EQUATOR_THINNING as the target thickness
        float targetThinness = CORONA_EQUATOR_THINNING / baseCoronaWidth; // Convert to ratio
        float actualThinning = mix(1.0, targetThinness, smoothstep(0.2, 0.8, thinningFactor));
        coronaWidth = baseCoronaWidth * actualThinning;
    } else {
        // Full thickness away from equator and sides
        coronaWidth = baseCoronaWidth;
    }
    
    // Ensure minimum visibility
    coronaWidth = max(coronaWidth, 0.002); // Minimum 0.2% width for visibility
    
    // Calculate threshold
    float coronaStartThreshold = 1.0 - coronaWidth;
    
    // Orange → Golden Yellow (only in corona band)
    if (eclipseFactor > coronaStartThreshold) {
        float coronaProgress = (eclipseFactor - coronaStartThreshold) / coronaWidth;
        
        // First 40% of corona band: transition to golden yellow
        if (coronaProgress < 0.4) {
            float t = smoothstep(0.0, 0.4, coronaProgress);
            color = mix(color, goldenYellow, t);
        }
        
        // 40-70% of corona band: golden yellow to bright gold
        if (coronaProgress > 0.3) {
            float t = smoothstep(0.3, 0.7, coronaProgress);
            color = mix(color, brightGold, t);
        }
        
        // 70-100% of corona band: bright gold to corona glow
        if (coronaProgress > 0.6) {
            float t = smoothstep(0.6, 1.0, coronaProgress);
            vec3 enhancedCorona = coronaGlow * 1.2;
            color = mix(color, enhancedCorona, t);
        }
    }
    
    // === ADDITIONAL CORONA HIGHLIGHTS ===
    // Extra glow effects for wave peaks within the corona band
    if (eclipseFactor > coronaStartThreshold) {
        // Golden highlights on wave peaks
        if (totalDisplacement > 0.03) { 
            float peakBoost = smoothstep(0.03, 0.08, totalDisplacement);
            vec3 intenseGold = vec3(1.0, 0.9, 0.4);
            color = mix(color, intenseGold, peakBoost * 0.5);
        }
        
        // Extra brightness at the very edge
        if (eclipseFactor > 0.95) {
            float edgeGlow = smoothstep(0.95, 1.0, eclipseFactor);
            vec3 edgeColor = vec3(1.0, 0.95, 0.6);
            color = mix(color, edgeColor, edgeGlow * 0.4);
        }
    } 
    // No shadow modulation - keep colors at full brightness
    
    // Full intensity for brighter appearance (no shadow reduction)
    vIntensity = 1.0;
    
    // No brightness boost - keep original color values
    // color = color * 1.0;
    
    // Both sides of sphere get full color treatment
    vColor = color;
    
    // Screen position
    vec4 mvPosition = modelViewMatrix * vec4(displaced, 1.0);
    
    // Uniform point sizing - no variation to maintain coverage
    float baseSize = 6.0; // Increased from 8.0 to 16.0 for 2x larger dot diameter
    
    // No fold size variation - keep dots same size everywhere
    float foldSize = 1.0;
    
    // No shadow sizing - uniform dot size
    float shadowSize = 1.0;
    
    // No edge size reduction - keep full size at edges
    float edgeSize = 1.0;
    
    // Minimal random variation for organic look
    float randomSize = 0.95 + aRandom * 0.1; // Very slight variation (0.95-1.05)
    
    // No distance-based sizing - keep uniform
    float distSize = 1.0;
    
    // Dynamic perspective scaling based on camera distance
    // Dots get smaller when zoomed in (closer), larger when zoomed out (farther)
    float screenScale = 6.0; // Base scaling factor
    
    // Inverse relationship: closer camera = smaller dots, farther camera = larger dots
    // Using square root for more gradual scaling
    float zoomFactor = sqrt(uCameraDistance / 3.5); // 3.5 is default camera distance
    float perspectiveScale = screenScale * zoomFactor;
    
    // Apply all factors with camera-based perspective scaling
    gl_PointSize = baseSize * foldSize * shadowSize * edgeSize * randomSize * distSize * perspectiveScale;
    
    // Stricter clamping to prevent overlap at far distances
    gl_PointSize = clamp(gl_PointSize, 1.0, 12.0); // Increased from 1.5-12.0 to 3.0-24.0 for 2x larger dots
    
    gl_Position = projectionMatrix * mvPosition;
}