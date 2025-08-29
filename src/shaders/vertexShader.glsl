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
varying float vSunLight;
varying float vShadow;

const float radius = 1.5;
const float PI = 3.14159265359;

// ========================================
// WAVE SYSTEM - Creates animated liquid-like waves on sphere surface
// TO DISABLE ALL WAVES: Return 0.0 at the beginning of this function
// ========================================
float createFoldingWaves(vec3 p) {
    float time = uTime;
    
    // === MASTER TOGGLE - UNCOMMENT TO DISABLE ALL WAVES ===
    // return 0.0;  // <-- UNCOMMENT THIS LINE TO TURN OFF ALL WAVES
    
    // === INDIVIDUAL WAVE TOGGLES ===
    // Set to 0.0 to disable specific waves, 1.0 to enable
    float enableWave1Main = 0.0;      // First circular wave
    float enableWave1Secondary = 0.0; // Second circular wave
    float enableBranch1 = 1.0;        // C-shaped wave (bottom-left to top-left)
    float enableBranch2 = 1.0;        // C-shaped wave (bottom-left to bottom-right)
    
    // === WAVE TIMING SYSTEM ===
    // The waves appear in sequence, creating a choreographed animation
    // Total cycle: 80 seconds, then repeats
    // - Wave 1 Main: 0-20 seconds (circular expanding ring)
    // - Wave 1 Secondary: 20-40 seconds (another ring from same origin)
    // - Branch Wave 1: 40-60 seconds (C-shaped wave)
    // - Branch Wave 2: 60-80 seconds (C-shaped wave)
    float totalCycle = 20.0; // 4 waves × 20 seconds each
    float currentPhase = mod(time, totalCycle);
    
    float wave1_main = 0.0;
    float wave1_secondary = 0.0;
    float branch1_wave = 0.0;
    float branch2_wave = 0.0;
    
    // === WAVE 1 MAIN: Circular expanding ring (repeats every 10 seconds) ===
    // This wave operates on its own 10-second cycle, independent of other waves
    float mainWaveCycle = 10.0;  // Repeat every 10 seconds
    float mainWavePhase = mod(time, mainWaveCycle);
    
    if (enableWave1Main > 0.0) {
        // === ORIGIN CONFIGURATION ===
        // Change these values to move the wave origin:
        // X: -1.0 (left) to 1.0 (right)
        // Y: -1.0 (bottom) to 1.0 (top)
        // Z: -1.0 (back) to 1.0 (front)
        vec3 origin1 = vec3(0.707, 0.707, 0.5);  // Current: top-right-front quadrant
        
        // === WAVE PARAMETERS ===
        float expansionSpeed = 0.3;  // Units per second (higher = faster)
        float waveThickness = 0.4;   // Ring thickness (higher = thicker ring)
        float waveFrequency = 10.0;  // Oscillations (higher = more ripples)
        float maxAmplitude = 0.8;   // Maximum wave height
        float decayRate = 0.07;       // Fade speed (higher = faster fade)
        
        float distFromOrigin1 = length(p - origin1);
        float waveAge = mainWavePhase;  // Use independent 10-second cycle
        float waveRadius = waveAge * expansionSpeed;
        
        float ringDistance = abs(distFromOrigin1 - waveRadius);
        if (ringDistance < waveThickness) {
            float intensity = (1.0 - ringDistance / waveThickness) * exp(-waveAge * decayRate);
            wave1_main = sin(ringDistance * waveFrequency) * intensity * maxAmplitude * enableWave1Main;
        }
    }
    
    // === WAVE 1 SECONDARY: Second ring from same origin (20-40 seconds) ===
    else if (currentPhase >= 20.0 && currentPhase < 40.0 && enableWave1Secondary > 0.0) {
        // === ORIGIN CONFIGURATION ===
        // Uses same origin as Wave 1 Main for follow-up effect
        // To use different origin, change these values:
        vec3 origin1 = vec3(0.707, 0.707, 0.5);  // Same as Wave 1 Main
        
        // === WAVE PARAMETERS ===
        float expansionSpeed = 0.3;  // Same speed as main wave
        float waveThickness = 0.4;   // Same thickness
        float waveFrequency = 10.0;  // Same frequency
        float maxAmplitude = 0.07;   // 75% of main wave amplitude
        float decayRate = 0.09;       // Same fade speed
        
        float distFromOrigin1 = length(p - origin1);
        float waveAge = currentPhase - 20.0;
        float waveRadius = waveAge * expansionSpeed;
        
        float ringDistance = abs(distFromOrigin1 - waveRadius);
        if (ringDistance < waveThickness) {
            float intensity = (1.0 - ringDistance / waveThickness) * exp(-waveAge * decayRate);
            wave1_secondary = sin(ringDistance * waveFrequency) * intensity * maxAmplitude * enableWave1Secondary;
        }
    }
    
    // === BRANCH WAVE 1: C-shaped curved wave (40-60 seconds) ===
    else if (currentPhase >= 40.0 && currentPhase < 60.0 && enableBranch1 > 0.0) {
        // === PATH CONFIGURATION ===
        // Start point - change these to move wave origin:
        vec3 origin2 = vec3(-0.707, -0.707, 0.3);  // Current: bottom-left-back
        // End point - change these to alter wave destination:
        vec3 target1 = vec3(-0.866, 0.5, 0.2);      // Current: top-left-front
        
        // === WAVE PARAMETERS ===
        float travelSpeed = 0.25;    // Speed along path (units/second)
        float waveLength = 0.3;      // Length of wave front
        float waveWidth = 0.2;       // Width of wave band
        float curveAmount = 0.15;    // How much the path curves (0 = straight)
        float curveFreq = 1.2;       // Curve oscillations
        float waveFrequency = 15.0;  // Wave ripple frequency
        float maxAmplitude = 0.9;   // Maximum wave height
        float decayRate = 0.08;      // Fade speed
        
        vec3 direction1 = normalize(target1 - origin2);
        float waveAge = currentPhase - 40.0;
        float waveProgress = waveAge * travelSpeed;
        
        float progressAlongPath = dot(p - origin2, direction1);
        float pathLength = length(target1 - origin2);
        
        if (progressAlongPath >= 0.0 && progressAlongPath <= pathLength) {
            vec3 perpendicular1 = normalize(cross(direction1, vec3(0.0, 0.0, 1.0)));
            float curveOffset = sin(progressAlongPath * curveFreq) * curveAmount;
            vec3 curvedPoint = origin2 + direction1 * progressAlongPath + perpendicular1 * curveOffset;
            
            float distToCurvedPath = length(p - curvedPoint);
            float waveFrontDistance = abs(progressAlongPath - waveProgress);
            
            if (waveFrontDistance < waveLength && distToCurvedPath < waveWidth) {
                float intensity = (1.0 - waveFrontDistance / waveLength) * 
                                (1.0 - distToCurvedPath / waveWidth) * exp(-waveAge * decayRate);
                branch1_wave = sin(waveFrontDistance * waveFrequency) * intensity * maxAmplitude * enableBranch1;
            }
        }
    }
    
    // === BRANCH WAVE 2: C-shaped curved wave (60-80 seconds) ===
    else if (currentPhase >= 60.0 && currentPhase < 80.0 && enableBranch2 > 0.0) {
        // === PATH CONFIGURATION ===
        // Start point - change these to move wave origin:
        vec3 origin2 = vec3(-0.707, -0.707, -0.3);  // Current: bottom-left-back (same as Branch 1)
        // End point - change these to alter wave destination:
        vec3 target2 = vec3(0.866, -0.5, 0.2);      // Current: bottom-right-front
        
        // === WAVE PARAMETERS ===
        float travelSpeed = 0.25;    // Speed along path (units/second)
        float waveLength = 0.3;      // Length of wave front
        float waveWidth = 0.2;       // Width of wave band
        float curveAmount = 0.15;    // How much the path curves (0 = straight)
        float curveFreq = 1.2;       // Curve oscillations
        float waveFrequency = 15.0;  // Wave ripple frequency
        float maxAmplitude = 0.08;   // Maximum wave height
        float decayRate = 0.08;      // Fade speed
        
        vec3 direction2 = normalize(target2 - origin2);
        float waveAge = currentPhase - 60.0;
        float waveProgress = waveAge * travelSpeed;
        
        float progressAlongPath = dot(p - origin2, direction2);
        float pathLength = length(target2 - origin2);
        
        if (progressAlongPath >= 0.0 && progressAlongPath <= pathLength) {
            vec3 perpendicular2 = normalize(cross(direction2, vec3(0.0, 0.0, 1.0)));
            float curveOffset = sin(progressAlongPath * curveFreq) * curveAmount;
            vec3 curvedPoint = origin2 + direction2 * progressAlongPath + perpendicular2 * curveOffset;
            
            float distToCurvedPath = length(p - curvedPoint);
            float waveFrontDistance = abs(progressAlongPath - waveProgress);
            
            if (waveFrontDistance < waveLength && distToCurvedPath < waveWidth) {
                float intensity = (1.0 - waveFrontDistance / waveLength) * 
                                (1.0 - distToCurvedPath / waveWidth) * exp(-waveAge * decayRate);
                branch2_wave = sin(waveFrontDistance * waveFrequency) * intensity * maxAmplitude * enableBranch2;
            }
        }
    }
    
    // === WAVE INTERACTION: Detect when waves meet and create clash effects ===
    // Sum all active waves
    float totalWave = wave1_main + wave1_secondary + branch1_wave + branch2_wave;
    
    // CLASH DETECTION: When multiple waves overlap, they interfere
    // This creates more dramatic effects where waves meet
    float activeWaves = 0.0;
    if (abs(wave1_main) > 0.01) activeWaves += 1.0;      // Count if wave is active
    if (abs(wave1_secondary) > 0.01) activeWaves += 1.0;  // Count if wave is active
    if (abs(branch1_wave) > 0.01) activeWaves += 1.0;     // Count if wave is active
    if (abs(branch2_wave) > 0.01) activeWaves += 1.0;     // Count if wave is active
    
    // Amplify where waves clash (interference pattern)
    // TO DISABLE CLASH AMPLIFICATION: Comment out this if block
    if (activeWaves >= 2.0) {
        totalWave *= 1.5; // 50% amplitude boost at intersection points
    }
    
    // === EDGE BEHAVIOR: Makes sphere edges pull inward slightly ===
    // TO DISABLE EDGE EFFECT: Comment out these 3 lines
    float distanceFromCenter = length(p);
    if (distanceFromCenter > 1.4) {  // Near the sphere edge (radius = 1.5)
        totalWave *= -0.2; // Negative value creates inward pull
    }
    
    // Clamp final displacement to maintain sphere shape
    // -0.05 to 0.1 range keeps deformation subtle
    return clamp(totalWave, -0.05, 0.1);
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
    
    // Calculate rim factor for eclipse effect
    vec3 worldViewDir = normalize(cameraPosition - worldPosition);
    float rimFactor = 1.0 - abs(dot(perturbedNormal, worldViewDir)); // 0 at center, 1 at edges
    
    // Enhanced rim detection with gentler eclipse edge effect
    float eclipseRim = pow(rimFactor, 1.2); // Reduced from 1.5 for smoother rim
    
    // Fixed world-space position for consistent eclipse orientation
    float worldOrientation = dot(perturbedNormal, normalize(vec3(1.0, 0.5, 0.0))); // Fixed light direction
    float eclipsePosition = (worldOrientation + 1.0) * 0.5; // Normalize to 0-1
    
    // More gradual combination for smoother transitions
    float eclipseFactor = eclipseRim * 0.6 + eclipsePosition * 0.4; // More balanced mix
    
    // === ULTRA-SMOOTH COLOR GRADIENT WITH WIDE TRANSITION ZONES ===
    // Using overlapping transition zones and gentle smoothstep for seamless blending
    vec3 color = centerBlack; // Start with center black color
    
    // Center Black → Deep Violet (0.0-0.10)
    if (eclipseFactor > 0.0) {
        float t = smoothstep(0.0, 0.10, eclipseFactor);
        color = mix(centerBlack, deepViolet, t);
    }
    
    // Deep Violet → Purple (Overlapping: 0.08-0.28)
    if (eclipseFactor > 0.08) {
        float t = smoothstep(0.08, 0.28, eclipseFactor);
        color = mix(color, purple, t * 0.85);
    }
    
    // Purple → Dark Blue #190096 (Overlapping: 0.18-0.38)
    if (eclipseFactor > 0.18) {
        float t = smoothstep(0.18, 0.38, eclipseFactor);
        color = mix(color, darkBlue, t * 0.8);
    }
    
    // Dark Blue → Blue #4200EE (Overlapping: 0.28-0.48)
    if (eclipseFactor > 0.28) {
        float t = smoothstep(0.28, 0.48, eclipseFactor);
        color = mix(color, blue, t * 0.85);
    }
    
    // Blue #4200EE → Magenta (Overlapping: 0.38-0.58)
    if (eclipseFactor > 0.38) {
        float t = smoothstep(0.38, 0.58, eclipseFactor);
        color = mix(color, magenta, t * 0.9);
    }
    
    // Magenta → Pink (Overlapping: 0.48-0.68)
    if (eclipseFactor > 0.48) {
        float t = smoothstep(0.48, 0.68, eclipseFactor);
        color = mix(color, pink, t * 0.85);
    }
    
    // Pink → Red (Wide transition: 0.58-0.78)
    if (eclipseFactor > 0.58) {
        float t = smoothstep(0.58, 0.78, eclipseFactor);
        color = mix(color, red, t * 0.9);
    }
    
    // Red → Orange (Gradual: 0.68-0.83)
    if (eclipseFactor > 0.68) {
        float t = smoothstep(0.68, 0.83, eclipseFactor);
        color = mix(color, orange, t * 0.6);
    }
    
    // Orange → Golden Yellow (Wide: 0.73-0.88)
    if (eclipseFactor > 0.73) {
        float t = smoothstep(0.73, 0.88, eclipseFactor);
        color = mix(color, goldenYellow, t * 0.8);
    }
    
    // Golden Yellow → Bright Gold (Gentle: 0.78-0.94)
    if (eclipseFactor > 0.78) {
        float t = smoothstep(0.78, 0.94, eclipseFactor);
        color = mix(color, brightGold, t * 0.9);
    }
    
    // Bright Gold → Corona Glow (Extended: 0.83-1.0)
    if (eclipseFactor > 0.83) {
        float t = smoothstep(0.83, 1.0, eclipseFactor);
        color = mix(color, coronaGlow, t * 0.7);
    }
    
    // Enhanced edge highlighting for golden corona effect
    if (eclipseFactor > 0.75) {
        // Golden highlights on wave peaks at circumference
        if (totalDisplacement > 0.04) {
            float peakBoost = smoothstep(0.04, 0.08, totalDisplacement);
            color = mix(color, brightGold, peakBoost * 0.6);
        }
        
        // Extra glow for extreme edges
        if (eclipseRim > 0.85) {
            float glowStrength = (eclipseRim - 0.85) / 0.15;
            vec3 sunGlow = vec3(1.0, 0.95, 0.6); // Bright corona glow
            color = mix(color, sunGlow, glowStrength * 0.4);
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