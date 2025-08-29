// ========================================
// WAVE SYSTEM MODULE
// Contains all wave generation and interaction logic
// ========================================

// === GLOBAL WAVE CONTROLS ===
// Control the frequency and form of all waves
uniform float WAVE_FREQUENCY; // Will be set from main shader (default: 6.0)
uniform float WAVE_SPEED; // Will be set from main shader (default: 0.25)
uniform float WAVE_THICKNESS; // Will be set from main shader (default: 0.5)
uniform float WAVE_AMPLITUDE; // Will be set from main shader (default: 0.8)
uniform float WAVE_MAX_AMPLITUDE; // Will be set from main shader (default: 2.2)
uniform float WAVE_FORM; // Will be set from main shader (default: 1.0)

// ========================================
// WAVE SYSTEM - Creates animated liquid-like waves on sphere surface
// TO DISABLE ALL WAVES: Return 0.0 at the beginning of this function
// ========================================
float createFoldingWaves(vec3 p, float time) {
    // === MASTER TOGGLE - UNCOMMENT TO DISABLE ALL WAVES ===
    // return 0.0;  // <-- UNCOMMENT THIS LINE TO TURN OFF ALL WAVES
    
    // === INDIVIDUAL WAVE TOGGLES ===
    // Set to 0.0 to disable specific waves, 1.0 to enable
    float enableWave1Main = 1.0;      // First circular wave (top-right)
    float enableWave1Secondary = 1.0; // Second circular wave (top-right)
    float enableWave2Main = 1.0;      // Opposite circular wave (bottom-left)
    float enableWave2Secondary = 1.0; // Opposite second wave (bottom-left)
    
    // Use passed parameters or defaults
    float waveFrequency = 6.0;      // Ripple frequency (5.0 = fewer ripples, 20.0 = many ripples)
    float waveSpeed = 0.25;         // Expansion speed (0.1 = slow, 0.5 = fast)
    float waveThickness = 0.5;      // Ring thickness (0.2 = thin, 0.8 = thick)
    float waveAmplitude = 0.8;      // Base wave height (0.1 = subtle, 0.5 = tall)
    float waveMaxAmplitude = 2.2;   // Maximum height at clash (0.5 = low, 2.0 = very tall)
    float waveForm = 1.0;           // Wave shape (0.5 = smooth, 1.0 = normal, 2.0 = sharp)
    
    // === WAVE TIMING SYSTEM ===
    // The waves appear in sequence, creating a choreographed animation
    float totalCycle = 20.0; // 4 waves × 20 seconds each
    float currentPhase = mod(time, totalCycle);
    
    float wave1_main = 0.0;
    float wave1_secondary = 0.0;
    float wave2_main = 0.0;        // Opposite wave from bottom-left
    float wave2_secondary = 0.0;   // Opposite secondary wave
    
    // === WAVE 1 MAIN: Circular expanding ring (repeats every 4 seconds) ===
    float mainWaveCycle = 4.0;  // Repeat every 4 seconds
    float mainWavePhase = mod(time, mainWaveCycle);
    
    // Calculate clash detection parameters
    vec3 origin1 = vec3(0.707, 0.707, 0.5);   // Wave 1 origin
    vec3 origin2 = vec3(-0.707, -0.707, 0.65); // Wave 2 origin (opposite)
    float clashDistance = length(origin1 - origin2); // Distance between origins
    float clashPoint = clashDistance * 0.5; // Middle point where waves meet
    
    if (enableWave1Main > 0.0) {
        // === WAVE PARAMETERS ===
        float expansionSpeed = waveSpeed;     // Units per second (higher = faster)
        float thickness = waveThickness;      // Ring thickness (higher = thicker ring)
        float frequency = waveFrequency;      // Oscillations (higher = more ripples)
        float baseAmplitude = waveAmplitude;  // Starting wave height
        float maxAmplitude = waveMaxAmplitude; // Maximum wave height at clash
        
        float distFromOrigin1 = length(p - origin1);
        float waveAge = mainWavePhase;
        float waveRadius = waveAge * expansionSpeed;
        
        // Check if wave has reached clash point and should dissolve
        float maxRadius = clashPoint + thickness * 0.5; // Vanish right after clash point
        
        if (waveRadius < maxRadius) { // Only show wave before it vanishes at clash
            float ringDistance = abs(distFromOrigin1 - waveRadius);
            if (ringDistance < thickness) {
                // Calculate growth factor - wave grows as it approaches clash point
                float progressToClash = waveRadius / clashPoint; // 0 at start, 1 at clash
                
                // Exponential growth as wave approaches clash point
                float growthFactor = baseAmplitude + (maxAmplitude - baseAmplitude) * pow(progressToClash, 2.0);
                
                // Sharp vanish at clash point
                float clashFade = 1.0;
                if (waveRadius > clashPoint * 0.95) { // Vanish very close to clash
                    clashFade = 1.0 - smoothstep(clashPoint * 0.95, maxRadius, waveRadius);
                }
                
                float intensity = (1.0 - ringDistance / thickness) * clashFade;
                // Apply wave form control (1.0 = sine wave, higher = sharper peaks)
                float waveShape = pow(abs(sin(ringDistance * frequency)), waveForm);
                wave1_main = waveShape * intensity * growthFactor * enableWave1Main;
            }
        }
    }
    
    // === WAVE 1 SECONDARY: Second ring from same origin (20-40 seconds) ===
    if (currentPhase >= 20.0 && currentPhase < 40.0 && enableWave1Secondary > 0.0) {
        vec3 origin1 = vec3(0.707, 0.707, 0.5);  // Same as Wave 1 Main
        
        // === WAVE PARAMETERS ===
        float expansionSpeed = waveSpeed;
        float thickness = waveThickness;
        float frequency = waveFrequency;
        float baseAmplitude = waveAmplitude * 0.67; // Starting amplitude for secondary (2/3 of main)
        float maxAmplitude = waveMaxAmplitude * 0.67; // Maximum height at clash (2/3 of main)
        
        float distFromOrigin1 = length(p - origin1);
        float waveAge = currentPhase - 20.0;
        float waveRadius = waveAge * expansionSpeed;
        
        // Vanish at clash point
        float maxRadius = clashPoint + thickness * 0.5;
        
        if (waveRadius < maxRadius) {
            float ringDistance = abs(distFromOrigin1 - waveRadius);
            if (ringDistance < thickness) {
                // Growth factor - wave grows as it approaches clash
                float progressToClash = waveRadius / clashPoint;
                float growthFactor = baseAmplitude + (maxAmplitude - baseAmplitude) * pow(progressToClash, 2.0);
                
                // Sharp vanish at clash
                float clashFade = 1.0;
                if (waveRadius > clashPoint * 0.95) {
                    clashFade = 1.0 - smoothstep(clashPoint * 0.95, maxRadius, waveRadius);
                }
                
                float intensity = (1.0 - ringDistance / thickness) * clashFade;
                // Apply wave form control
                float waveShape = pow(abs(sin(ringDistance * frequency)), waveForm);
                wave1_secondary = waveShape * intensity * growthFactor * enableWave1Secondary;
            }
        }
    }
    
    // === WAVE 2 MAIN: Opposite circular wave (repeats every 4 seconds) ===
    if (enableWave2Main > 0.0) {
        // === WAVE PARAMETERS ===
        float expansionSpeed = waveSpeed;
        float thickness = waveThickness;
        float frequency = waveFrequency;
        float baseAmplitude = waveAmplitude;
        float maxAmplitude = waveMaxAmplitude;
        
        float distFromOrigin2 = length(p - origin2);
        float waveAge = mainWavePhase;  // Use same cycle as Wave 1 Main
        float waveRadius = waveAge * expansionSpeed;
        
        // Check if wave has reached clash point and should dissolve
        float maxRadius = clashPoint + thickness * 0.5;
        
        if (waveRadius < maxRadius) {
            float ringDistance = abs(distFromOrigin2 - waveRadius);
            if (ringDistance < thickness) {
                // Calculate growth factor - wave grows as it approaches clash point
                float progressToClash = waveRadius / clashPoint;
                
                // Exponential growth as wave approaches clash point
                float growthFactor = baseAmplitude + (maxAmplitude - baseAmplitude) * pow(progressToClash, 2.0);
                
                // Sharp vanish at clash point
                float clashFade = 1.0;
                if (waveRadius > clashPoint * 0.95) {
                    clashFade = 1.0 - smoothstep(clashPoint * 0.95, maxRadius, waveRadius);
                }
                
                float intensity = (1.0 - ringDistance / thickness) * clashFade;
                // Apply wave form control
                float waveShape = pow(abs(sin(ringDistance * frequency)), waveForm);
                wave2_main = waveShape * intensity * growthFactor * enableWave2Main;
            }
        }
    }
    
    // === WAVE 2 SECONDARY: Opposite follow-up wave (20-40 seconds) ===
    if (currentPhase >= 20.0 && currentPhase < 40.0 && enableWave2Secondary > 0.0) {
        vec3 origin2 = vec3(-0.707, -0.707, -0.5);  // Bottom-left-back quadrant
        
        // === WAVE PARAMETERS ===
        float expansionSpeed = waveSpeed;
        float thickness = waveThickness;
        float frequency = waveFrequency;
        float baseAmplitude = waveAmplitude * 0.67; // Starting amplitude for secondary (2/3 of main)
        float maxAmplitude = waveMaxAmplitude * 0.67; // Maximum height at clash (2/3 of main)
        
        float distFromOrigin2 = length(p - origin2);
        float waveAge = currentPhase - 20.0;
        float waveRadius = waveAge * expansionSpeed;
        
        // Vanish at clash point
        float maxRadius = clashPoint + thickness * 0.5;
        
        if (waveRadius < maxRadius) {
            float ringDistance = abs(distFromOrigin2 - waveRadius);
            if (ringDistance < thickness) {
                // Growth factor - wave grows as it approaches clash
                float progressToClash = waveRadius / clashPoint;
                float growthFactor = baseAmplitude + (maxAmplitude - baseAmplitude) * pow(progressToClash, 2.0);
                
                // Sharp vanish at clash
                float clashFade = 1.0;
                if (waveRadius > clashPoint * 0.95) {
                    clashFade = 1.0 - smoothstep(clashPoint * 0.95, maxRadius, waveRadius);
                }
                
                float intensity = (1.0 - ringDistance / thickness) * clashFade;
                // Apply wave form control
                float waveShape = pow(abs(sin(ringDistance * frequency)), waveForm);
                wave2_secondary = waveShape * intensity * growthFactor * enableWave2Secondary;
            }
        }
    }
    
    // === WAVE INTERACTION: Detect when waves meet and create clash effects ===
    // Sum all active waves (including opposite waves for clash)
    float totalWave = wave1_main + wave1_secondary + wave2_main + wave2_secondary;
    
    // CLASH DETECTION: When multiple waves overlap, they interfere
    // This creates more dramatic effects where waves meet
    float activeWaves = 0.0;
    if (abs(wave1_main) > 0.01) activeWaves += 1.0;      // Count if wave is active
    if (abs(wave1_secondary) > 0.01) activeWaves += 1.0;  // Count if wave is active
    if (abs(wave2_main) > 0.01) activeWaves += 1.0;      // Count opposite wave
    if (abs(wave2_secondary) > 0.01) activeWaves += 1.0;  // Count opposite secondary
    
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
float createBendingWaves(vec3 p, float time) {
    // === RIPPLE TOGGLE - UNCOMMENT TO DISABLE ===
    return 0.0;  // <-- UNCOMMENT THIS LINE TO TURN OFF RIPPLES
    
    // Convert position to spherical coordinates for wave patterns
    float theta = atan(p.z, p.x);  // Horizontal angle
    float phi = acos(p.y / max(length(p), 0.001));  // Vertical angle
    
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
float createAsymmetricDistortion(vec3 p, float time) {
    // === DISTORTION TOGGLE - UNCOMMENT TO DISABLE ===
    // return 0.0;  // <-- UNCOMMENT THIS LINE TO TURN OFF DISTORTION
    
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
float createSphericalShape(vec3 p, float time, float radius) {
    float r = length(p);
    float baseShape = radius - r;  // Basic sphere shape (radius = 1.5)
    
    // === COMBINE ALL WAVE SYSTEMS ===
    // Each function can be disabled individually by returning 0.0 in that function
    float foldingWaves = createFoldingWaves(p, time);        // Main animated waves (largest effect)
    float bendingWaves = createBendingWaves(p, time);        // Fast surface ripples (medium effect)
    float asymmetric = createAsymmetricDistortion(p, time);  // Organic drift (smallest effect)
    
    // Sum all wave displacements
    float totalDisplacement = foldingWaves + bendingWaves + asymmetric;
    
    // === DISPLACEMENT LIMITER ===
    // Prevents extreme deformation to maintain recognizable sphere shape
    // Range: -0.35 to +0.35 units from base sphere surface
    totalDisplacement = clamp(totalDisplacement, -0.35, 0.35);
    
    return baseShape + totalDisplacement;
}