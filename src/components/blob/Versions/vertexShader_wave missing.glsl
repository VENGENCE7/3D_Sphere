uniform float uTime;
uniform float uCameraDistance;

attribute vec3 initialPosition;
attribute float aRandom;

varying vec3 vColor;
varying vec3 vWorldPos;
varying float vEdgeFade;

const float radius = 1.5;
const float PI = 3.14159265359;

// ========================================
// SIMPLEX NOISE FUNCTIONS - For organic membrane movement
// ========================================
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);
    
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);
    
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;
    
    i = mod289(i);
    vec4 p = permute(permute(permute(
        i.z + vec4(0.0, i1.z, i2.z, 1.0))
        + i.y + vec4(0.0, i1.y, i2.y, 1.0))
        + i.x + vec4(0.0, i1.x, i2.x, 1.0));
    
    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;
    
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);
    
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    
    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    
    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);
    
    vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// ========================================
// HELPER FUNCTIONS FOR SMOOTH COLOR BLENDING
// ========================================
// Quintic smoothstep for ultra-smooth transitions
float smootherstep(float edge0, float edge1, float x) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

// ========================================
// MODULAR COLOR BAND SYSTEM
// ========================================
// Structure to hold color band information
struct ColorBand {
    float startPos;
    float endPos;
    vec3 startColor;
    vec3 endColor;
};

// Select color within a single band - no bleeding between bands
vec3 getColorInBand(float factor, float bandStart, float bandEnd, vec3 colorStart, vec3 colorEnd) {
    // Ensure we're within this band
    if (factor < bandStart) return colorStart;
    if (factor > bandEnd) return colorEnd;
    
    // Smooth transition only within this band
    float t = smootherstep(bandStart, bandEnd, factor);
    return mix(colorStart, colorEnd, t);
}

// Apply deformation-based color modification within a band
// This keeps the color modification isolated to the current band
vec3 applyBandDeformation(vec3 baseColor, float deformValue, float deformIntensity) {
    vec3 modifiedColor = baseColor;
    
    if (deformValue > 0.0) {
        // Bulge: Brighten within the same hue
        float brightness = 1.0 + (deformValue * deformIntensity * 0.2); // Max 20% brighter
        modifiedColor = baseColor * brightness;
        modifiedColor = min(modifiedColor, vec3(1.1)); // Soft clamp
    } else if (deformValue < 0.0) {
        // Groove: Darken within the same hue
        float darkness = 1.0 + (deformValue * deformIntensity * 0.3); // Max 30% darker
        modifiedColor = baseColor * darkness;
        modifiedColor = max(modifiedColor, baseColor * 0.7); // Don't go too dark
    }
    
    return modifiedColor;
}

// Determine which color band we're in and return band index
int getColorBandIndex(float eclipseFactor, float band1, float band2, float band3, float band4, float band5, float band6, float band7, float band8) {
    if (eclipseFactor <= band1) return 0;
    else if (eclipseFactor <= band2) return 1;
    else if (eclipseFactor <= band3) return 2;
    else if (eclipseFactor <= band4) return 3;
    else if (eclipseFactor <= band5) return 4;
    else if (eclipseFactor <= band6) return 5;
    else if (eclipseFactor <= band7) return 6;
    else if (eclipseFactor <= band8) return 7;
    else return 8;
}

// ========================================
// ORGANIC MEMBRANE DEFORMATION - Soft, living surface movement
// ========================================
float createOrganicDeformation(vec3 p) {
    float time = uTime;
    
    // =========================================
    // === MASTER CONTROL PANEL ===
    // Adjust these values to control the organic membrane movement
    // =========================================
    
    // === TOGGLE SYSTEM ON/OFF ===
    float ENABLE_ORGANIC_MOVEMENT = 1.0; // Set to 0.0 to disable all organic movement
    
    // === PRIMARY MOVEMENT CONTROLS ===
    float MEMBRANE_SPEED = 0.3;         // Optimized for smooth 60fps movement
    float BULGE_AMPLITUDE = 0.2;      // Reduced for calmer appearance
    float GROOVE_AMPLITUDE = -0.05;    // Even shallower grooves to stay outside black sphere
    
    // === DEFORMATION SCALE CONTROLS ===
    float NOISE_SCALE = 2.5;           // Size of primary deformations (1.0 = large, 5.0 = small)
    float SECONDARY_SCALE = 2.0;       // Size of detail ripples (3.0 = large, 10.0 = tiny)
    
    // === MOTION CHARACTERISTICS ===
    float PULSE_INTENSITY = 0.3;       // Bulge pulsing strength (0.0 = none, 0.3 = strong)
    float BREATHE_INTENSITY = 0.3;     // Groove breathing strength (0.0 = none, 0.3 = strong)
    float VERTEX_VARIATION = 0.5;      // Per-vertex randomization (0.0 = uniform, 1.0 = highly varied)
    
    // === NOISE LAYER WEIGHTS ===
    float PRIMARY_WEIGHT = 0.3;        // Primary noise influence (0.0-1.0)
    float DETAIL_WEIGHT = 0.8;         // Detail noise influence (0.0-1.0)
    
    // =========================================
    // === END OF CONTROL PANEL ===
    // =========================================
    
    if (ENABLE_ORGANIC_MOVEMENT < 0.5) {
        return 0.0; // System disabled
    }
    
    // === FRONT-FACING DETECTION ===
    // Calculate if this point is on the front-facing side of the sphere
    // Using the camera direction to determine front vs back
    vec3 toCameraDir = normalize(cameraPosition); // Assuming sphere at origin
    float facingFactor = dot(normalize(p), toCameraDir);
    
    // Create smooth transition from front to back
    // 1.0 = fully front-facing, 0.0 = back-facing
    float frontMask = smoothstep(-0.3, 0.3, facingFactor);
    
    // If on the back side, return no deformation (smooth)
    if (frontMask < 0.01) {
        return 0.0;
    }
    
    // Primary organic movement - large smooth bulges with continuous flow
    vec3 noiseCoord = p * NOISE_SCALE;
    float primaryNoise = snoise(noiseCoord + vec3(time * MEMBRANE_SPEED * 1.2, time * MEMBRANE_SPEED * 0.5, 0.0));
    
    // Add temporal variation for continuous wave-like movement
    primaryNoise += snoise(noiseCoord + vec3(time * MEMBRANE_SPEED, time * MEMBRANE_SPEED * 0.7, 0.0)) * 0.5;
    primaryNoise += snoise(noiseCoord + vec3(0.0, time * MEMBRANE_SPEED * 0.8, time * MEMBRANE_SPEED * 0.6)) * 0.3;
    
    // Secondary detail - smaller ripples
    vec3 detailCoord = p * SECONDARY_SCALE;
    float detailNoise = snoise(detailCoord + vec3(time * MEMBRANE_SPEED * 1.5, 0.0, 0.0)) * 0.3;
    detailNoise += snoise(detailCoord + vec3(0.0, time * MEMBRANE_SPEED * 2.0, 0.0)) * 0.2;
    
    // Combine noises for organic movement with configurable weights
    float totalNoise = primaryNoise * PRIMARY_WEIGHT + detailNoise * DETAIL_WEIGHT;
    
    // Create smooth bulges and grooves
    float deformation = 0.0;
    if (totalNoise > 0.0) {
        // Bulge - smooth outward movement
        deformation = totalNoise * BULGE_AMPLITUDE;
        // Add configurable pulsing to bulges
        deformation *= (1.0 + sin(time * 2.0 + totalNoise * PI) * PULSE_INTENSITY);
    } else {
        // Groove - smooth inward movement
        deformation = totalNoise * abs(GROOVE_AMPLITUDE);
        // Add configurable breathing to grooves
        deformation *= (1.0 + cos(time * 1.5 + totalNoise * PI) * BREATHE_INTENSITY);
    }
    
    // Add per-vertex randomization for more organic feel
    float vertexVariation = sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 0.5 + 0.5;
    deformation *= (1.0 - VERTEX_VARIATION + vertexVariation * VERTEX_VARIATION);
    
    // Apply front-facing mask for smooth transition
    deformation *= frontMask;
    
    // Ensure smooth, continuous motion
    return deformation;
}

// ========================================
// MAIN SHAPE FUNCTION - Combines all deformation effects
// ========================================
float createSphericalShape(vec3 p) {
    float r = length(p);
    float baseShape = radius - r;  // Basic sphere shape (radius = 1.5)
    
    // === DEFORMATION SYSTEM SELECTION ===
    // Choose which systems to use (set to 1.0 to enable, 0.0 to disable)
    float USE_ORGANIC_MEMBRANE = 1.0;  // New organic membrane system
    
    // === GET ORGANIC DEFORMATION ===
    float organicDeform = createOrganicDeformation(p) * USE_ORGANIC_MEMBRANE;
    
    // Sum all active displacements
    float totalDisplacement = organicDeform;
    
    // === DISPLACEMENT LIMITER ===
    // Prevents extreme deformation to maintain recognizable sphere shape
    // Limit inward to -0.10 to keep dots outside black sphere (1.5 - 0.10 = 1.40 > 1.35)
    totalDisplacement = clamp(totalDisplacement, -0.10, 0.25);
    
    return baseShape + totalDisplacement;
}

void main() {
    vec3 pos = initialPosition;
    vec3 originalNormal = normalize(pos);
    
    // Get the organic deformation value
    float organicDeform = createOrganicDeformation(pos);
    
    // Get the main shape displacement
    float shapeDisplacement = createSphericalShape(pos);
    float totalDisplacement = shapeDisplacement;
    
    // Apply displacement along the normal
    vec3 displaced = pos + originalNormal * totalDisplacement;
    
    // Store deformation depth for fragment shader
    
    // Calculate edge fade
    vec3 viewDir = normalize(cameraPosition - displaced);
    float edgeFactor = abs(dot(originalNormal, viewDir)); 
    vEdgeFade = max(0.7, smoothstep(0.1, 0.9, edgeFactor));
    
    // Reduced fade in deep folds
    if (organicDeform < -0.05) {
        float foldFade = 1.0 + organicDeform * 1.5;
        vEdgeFade *= max(foldFade, 0.6);
    }
    
    // Calculate perturbed normal for lighting
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
    vWorldPos = displaced;
    
    // Transform to world space
    vec4 worldPos4 = modelMatrix * vec4(displaced, 1.0);
    vec3 worldPosition = worldPos4.xyz;
    vec3 worldNormal = normalize((modelMatrix * vec4(perturbedNormal, 0.0)).xyz);
    
    // === ECLIPSE-STYLE RADIAL GRADIENT WITH SMOOTH BLENDING ===
    // Simplified color palette (9 colors for cleaner eclipse spectrum)
    vec3 centerBlack = vec3(0.078, 0.098, 0.086);  // #14190F - Center black
    vec3 darkBlue = vec3(0.1, 0.0, 0.59);          // #1A0096 - Dark blue
    vec3 blue = vec3(0.1843, 0.0, 0.8353);         // #2F00D5 - Blue
    vec3 violetPurple = vec3(0.545,0.,0.875);      // #8B00DF - Violet Purple
    vec3 lightpink = vec3(0.98,0.067,0.961);       // #FA11F5 - Light Pink
    vec3 brightRed = vec3(1.,0.259,0.361);         // #FF425C - Orange-red for rims
    vec3 goldenYellow = vec3(1.0, 0.616, 0.0);     // #FF9D00 - Golden yellow
    vec3 brightGold = vec3(1.0, 0.9, 0.4);         // #FFE666 - Bright gold corona
    
    // Additional colors for lower hemisphere
    vec3 deepPurple = vec3(0.11, 0.0, 0.204);       // #1C0034 - Deep purple
    vec3 winePurple = vec3(0.318, 0.063, 0.188);    // #511030 - Wine purple
    vec3 brightPink = vec3(0.980, 0.067, 0.251);    // #FA1140 - Bright pink (new)
    vec3 pinkMagenta = vec3(0.902, 0.278, 0.694);   // #E647B1 - Pink magenta (updated)
    vec3 softPink = vec3(0.894, 0.792, 0.863);      // #E4CADC - Soft pink (replaces white)
    vec3 magentaPink = vec3(0.624, 0.086, 0.545);   // #9F168B - Magenta pink
    vec3 purpleViolet = vec3(0.443, 0.094, 0.584);  // #711895 - Purple violet
    vec3 deepIndigo2 = vec3(0.137, 0.024, 0.212);   // #230636 - Deep indigo 2
    vec3 redOrange = vec3(1.0, 0.325, 0.184);       // #FF532F - Red-orange for south pole
    vec3 transitionBlack = vec3(0.051, 0.0, 0.137); // #0D0023 - Transition black for lower hemisphere
    
    // === USE ORIGINAL NORMALS FOR COLOR CALCULATION ===
    // This prevents deformation from affecting color selection
    vec3 originalWorldNormal = normalize((modelMatrix * vec4(originalNormal, 0.0)).xyz);
    vec3 originalWorldPos = (modelMatrix * vec4(pos, 1.0)).xyz;
    
    // Calculate rim factor using ORIGINAL normal to prevent color bleeding
    vec3 worldViewDir = normalize(cameraPosition - originalWorldPos);
    float rimFactor = 1.0 - abs(dot(originalWorldNormal, worldViewDir));
    
    // === NO GRADIENT SHIFTING - Keep colors clean and separated ===
    // Remove gradient shifting to prevent color bleeding
    float eclipseFactor = rimFactor;
    
    // Smooth the eclipse factor
    eclipseFactor = smoothstep(0.0, 1.0, eclipseFactor);
    
    // Calculate vertical position using ORIGINAL normal for consistent hemisphere detection
    float verticalPosition = originalWorldNormal.y; // -1 at bottom, 0 at equator, 1 at top
    
    // Calculate smooth blending factor for equator transition (improved range)
    float equatorBlend = smoothstep(-0.15, 0.15, verticalPosition);
    
    // Calculate both color gradients
    vec3 upperColor = centerBlack;
    vec3 lowerColor = centerBlack;
    
    // === UPPER GRADIENT - Full color spectrum with latitude-based adjustments ===
    // Calculate latitude factor for gradient adjustments
    // 1.0 at north pole, 0.0 at equator
    float latitudeFactor = clamp(verticalPosition, 0.0, 1.0);
    
    // Vibrant gradient with latitude-based band expansion
    vec3 gradientColor = darkBlue;
    
    // Calculate how colors expand based on latitude
    // At equator: golden band is ultra-thin (1%), purple dominates
    // At mid-latitude: balanced gradient
    // At poles: pink-red gradient 35%, yellow reduced to 10% total (reduced by 5%)
    float goldenStart = mix(0.99, 0.97, latitudeFactor); // Golden starts at 99% at equator (1% band), 97% at pole (3% band)
    float yellowStart = mix(0.96, 0.90, latitudeFactor); // Yellow zone reduced to 7% at poles
    float redStart = mix(0.93, 0.73, latitudeFactor);    // Red zone reduced by 5% (was 0.70, now 0.73)
    float pinkStart = mix(0.90, 0.53, latitudeFactor);   // Pink zone reduced by 5% (was 0.50, now 0.53)
    float violetEnd = mix(0.85, 0.42, latitudeFactor);   // New violet purple end
    float purpleEnd = mix(0.80, 0.35, latitudeFactor);   // Magenta ends earlier to make room for violet
    
    // === CLEAN BAND TRANSITIONS - No overlapping ranges ===
    // Each band has exclusive range to prevent color bleeding
    
    if (eclipseFactor <= 0.08) {
        // Band 0: Black to Dark Blue (0.00 - 0.08)
        gradientColor = getColorInBand(eclipseFactor, 0.0, 0.08, centerBlack, darkBlue);
    }
    else if (eclipseFactor <= 0.25) {
        // Band 1: Dark Blue to Blue (0.08 - 0.25)
        gradientColor = getColorInBand(eclipseFactor, 0.08, 0.25, darkBlue, blue * 1.2);
    }
    else if (eclipseFactor <= purpleEnd) {
        // Band 2: Blue to Violet Purple (0.25 - purpleEnd) - smooth gradient
        gradientColor = getColorInBand(eclipseFactor, 0.25, purpleEnd, blue * 1.2, violetPurple * 1.2);
    }
    else if (eclipseFactor <= violetEnd) {
        // Band 3: Violet Purple to Light Pink (purpleEnd - violetEnd)
        vec3 targetPink = (latitudeFactor < 0.2) ? lightpink * 0.9 : lightpink * 1.1;
        gradientColor = getColorInBand(eclipseFactor, purpleEnd, violetEnd, violetPurple * 1.2, targetPink);
    }
    else if (eclipseFactor <= redStart) {
        // Band 4-5: Pink to Red transition (reduced by 5%)
        if (latitudeFactor < 0.1) {
            // Equator stays in violet purple
            gradientColor = violetPurple * 1.1;
        } else if (latitudeFactor < 0.2) {
            // Near equator: lighter pink
            gradientColor = lightpink * 1.0;
        } else {
            // Poles: smooth pink to red gradient (reduced range)
            gradientColor = getColorInBand(eclipseFactor, violetEnd, redStart, lightpink * 1.1, brightRed);
        }
    }
    else if (eclipseFactor <= yellowStart) {
        // Band 6: Red to Yellow (redStart - yellowStart) - creates orange naturally
        if (latitudeFactor < 0.3) {
            // Near equator: lighter transition
            gradientColor = getColorInBand(eclipseFactor, redStart, yellowStart, brightRed * 0.8, goldenYellow * 0.9);
        } else {
            // Poles: full red to yellow creating natural orange
            gradientColor = getColorInBand(eclipseFactor, redStart, yellowStart, brightRed, goldenYellow);
        }
    }
    else if (eclipseFactor <= goldenStart) {
        // Band 7: Pure yellow zone approaching corona
        if (latitudeFactor < 0.1) {
            // At equator: fade from violet purple to black edge
            gradientColor = mix(violetPurple * 1.1, centerBlack, smootherstep(0.85, 0.98, eclipseFactor));
        } else {
            // All other latitudes: solid yellow transitioning to golden
            float t = smootherstep(yellowStart, goldenStart, eclipseFactor);
            gradientColor = mix(goldenYellow, goldenYellow * 1.1, t);
        }
    }
    else {
        // Band 8: Golden corona band - ultra-thin everywhere
        float t = smootherstep(goldenStart, 1.0, eclipseFactor);
        
        if (latitudeFactor < 0.1) {
            // At equator: ultra-thin 1% golden band after black
            gradientColor = mix(centerBlack, goldenYellow * 0.7, t);
        } else if (latitudeFactor < 0.5) {
            // Mid-latitude: 2% golden band
            gradientColor = mix(goldenYellow, goldenYellow * 1.05, t);
        } else {
            // Poles: 3% golden corona (97%-100%)
            vec3 brightGold = vec3(1.0, 0.85, 0.3); // Softer bright gold
            gradientColor = mix(goldenYellow, brightGold, t);
        }
    }
    
    // Apply the smooth gradient
    upperColor = gradientColor;
    
    // === ENHANCED NORTH POLE LIGHTING - Bright sun from top ===
    // Much stronger lighting effect to match reference
    float poleLight = pow(max(0.0, verticalPosition), 1.5); // Softer falloff for wider bright area
    float sunIntensity = 0.8 + poleLight * 0.5; // Base 80% brightness everywhere + extra at pole
    
    // Apply sun lighting - significantly brighten all colors
    upperColor = upperColor * sunIntensity;
    
    // Strong glow at the top half
    if (verticalPosition > 0.5) {
        float glowFactor = smoothstep(0.5, 1.0, verticalPosition);
        // Add white highlight at pole
        vec3 sunHighlight = vec3(1.0, 0.98, 0.9);
        upperColor = mix(upperColor, upperColor * 1.3 + sunHighlight * 0.2, glowFactor * 0.4);
    }
    
    // Corona is now integrated into the main gradient for cleaner transitions
    
    // === LOWER HEMISPHERE - ASYMMETRIC WAVE PATTERN ===
    
    // Calculate lower latitude factor (1.0 at south pole, 0.0 at equator)
    float lowerLatitudeFactor = clamp(-verticalPosition, 0.0, 1.0);
    
    // Configurable visibility variables
    float FRONT_VISIBILITY = 1.0;   // 100% visibility from front
    float RIGHT_VISIBILITY = 0.8;    // 80% visibility from right
    float LEFT_VISIBILITY = 0.5;     // 50% visibility from left
    float BACK_VISIBILITY = 1.0;     // 100% visibility from back (same as front)
    
    // === CONFIGURABLE WAVE PARAMETERS ===
    // Adjust these to control wave position and shape
    float WAVE_START_POS = 1.5;      // Starting position (1.0 = far right, 0.0 = far left)
    float WAVE_END_POS = 0.2;        // Ending position (0.2 = left side at 8 o'clock)
    float WAVE_START_WIDTH = 0.05;   // Initial width of wave (as fraction of PI)
    float WAVE_END_WIDTH = 0.2;      // Final width at wave end (as fraction of PI)
    float WAVE_FRONT_DEPTH = 0.3;    // How far around the sphere the wave extends (0.3 = front 30% of sphere)
    
    // Calculate spherical coordinates for radial wave pattern
    // The wave should follow the curvature of the sphere
    float theta = acos(originalWorldPos.y / radius);  // Angle from north pole (0 to PI)
    float phi = atan(originalWorldPos.z, originalWorldPos.x);  // Azimuthal angle (-PI to PI)
    
    // Normalize phi to 0-1 range 
    // When looking at front (positive Z): phi=0 is at +X (right), phi=PI/2 is at +Z (front), phi=PI is at -X (left)
    float normalizedPhi = (phi + PI) / (2.0 * PI);
    
    // Calculate if we're in lower hemisphere
    bool isLowerHemisphere = theta > PI * 0.5;  // Below equator
    
    // Wave on positive Z (FRONT) side only
    // Check if we're on front side (positive Z) - using configurable depth
    bool isFrontSide = originalWorldPos.z > -radius * WAVE_FRONT_DEPTH;  // Front hemisphere
    
    // For front view: right side is +X, left side is -X
    // Calculate horizontal angle from right (+X) to left (-X)
    float horizontalAngle = atan(originalWorldPos.x, abs(originalWorldPos.z));  // Angle in front plane
    
    // Normalize to 0-1 (0 = far left, 1 = far right)
    float wavePosition = (horizontalAngle + PI * 0.5) / PI;
    
    // Use configurable start and end positions
    float waveStart = WAVE_START_POS;    // Start position (configurable)
    float waveEnd = WAVE_END_POS;        // End position (configurable)
    
    float waveProgress = 0.0;
    bool inWaveBand = false;
    
    if (isFrontSide && wavePosition <= waveStart && wavePosition >= waveEnd) {
        // Calculate progress from right to left
        waveProgress = (waveStart - wavePosition) / (waveStart - waveEnd);
        inWaveBand = true;
    }
    
    // Initialize with base gradient for lower hemisphere
    if (verticalPosition < 0.0) {
        // Base gradient for entire lower hemisphere (when not in wave band)
        float depth = abs(verticalPosition); // 0 at equator, 1 at south pole
        
        if (depth < 0.2) {
            // Near equator - darker purples
            lowerColor = mix(centerBlack, deepPurple, depth / 0.2);
        } else if (depth < 0.5) {
            // Mid region - transition through purples
            float t = (depth - 0.2) / 0.3;
            lowerColor = mix(deepPurple, winePurple, t);
        } else if (depth < 0.8) {
            // Lower region - wine to pink transition
            float t = (depth - 0.5) / 0.3;
            lowerColor = mix(winePurple, magentaPink * 0.5, t);
        } else {
            // Near south pole - darker for corona to stand out
            float t = (depth - 0.8) / 0.2;
            lowerColor = mix(magentaPink * 0.5, deepIndigo2, t);
        }
    } else {
        lowerColor = centerBlack;
    }
    
    // Apply wave band on top of base gradient (can extend to equator)
    if (inWaveBand) {
        // Calculate wave shape following the spherical curvature
        // Wave undulates along the surface as it travels radially
        
        // Calculate the wave center in terms of theta (latitude on sphere)
        // Equator is at theta = PI/2, South pole is at theta = PI
        float waveCenterTheta = PI * 0.5;  // Default at equator
        float waveWidthTheta = 0.0;
        
        // Calculate width interpolation based on progress
        float currentWidth = mix(WAVE_START_WIDTH, WAVE_END_WIDTH, waveProgress);
        
        if (waveProgress < 0.2) {
            // 3 to ~4 o'clock: Start AT EQUATOR, move toward SOUTH POLE
            float localProg = waveProgress / 0.2;
            waveCenterTheta = PI * 0.5 + sin(localProg * PI * 0.5) * PI * 0.3;  // Start at equator, dip to south
            waveWidthTheta = PI * mix(WAVE_START_WIDTH, currentWidth, localProg);
        } else if (waveProgress < 0.4) {
            // ~4 to 5 o'clock: First RISE back toward EQUATOR
            float localProg = (waveProgress - 0.2) / 0.2;
            waveCenterTheta = PI * 0.8 - sin(localProg * PI * 0.5) * PI * 0.25;  // Rise from south back to equator
            waveWidthTheta = PI * currentWidth;
        } else if (waveProgress < 0.6) {
            // 5 to 6 o'clock: Second DIP toward SOUTH POLE
            float localProg = (waveProgress - 0.4) / 0.2;
            waveCenterTheta = PI * 0.55 + sin(localProg * PI * 0.5) * PI * 0.25;  // Dip down again
            waveWidthTheta = PI * currentWidth;
        } else if (waveProgress < 0.8) {
            // 6 to 7 o'clock: Second RISE toward EQUATOR
            float localProg = (waveProgress - 0.6) / 0.2;
            waveCenterTheta = PI * 0.8 - sin(localProg * PI * 0.5) * PI * 0.2;  // Rise up again
            waveWidthTheta = PI * currentWidth;
        } else {
            // 7 to 8 o'clock: Final approach to MID-LATITUDE with configurable end width
            float localProg = (waveProgress - 0.8) / 0.2;
            waveCenterTheta = PI * 0.6 - localProg * PI * 0.05;  // End around PI*0.55 (mid-latitude)
            waveWidthTheta = PI * mix(currentWidth, WAVE_END_WIDTH, localProg);  // Reach final width
        }
        
        // Check if current position (theta) is within the wave band
        float waveBandTop = waveCenterTheta - waveWidthTheta * 0.5;  // Closer to north pole
        float waveBandBottom = waveCenterTheta + waveWidthTheta * 0.5;  // Closer to south pole
        
        if (theta >= waveBandTop && theta <= waveBandBottom) {
            // Radial gradient within the wave band (using spherical coordinates)
            float positionInWave = (theta - waveBandTop) / (waveBandBottom - waveBandTop);
            float radialFactor = clamp(positionInWave, 0.0, 1.0);
            
            // Color selection based on wave progress and radial position
            vec3 waveColor = deepPurple;
            
            if (waveProgress < 0.15) {
                // 3 to 4 o'clock: Deep Purple to Wine Purple
                waveColor = mix(deepPurple, winePurple, waveProgress / 0.15);
            } else if (waveProgress < 0.3) {
                // 4 to 5 o'clock: Wine Purple to Bright Pink (first rise)
                float t = (waveProgress - 0.15) / 0.15;
                waveColor = mix(winePurple, brightPink, t);
            } else if (waveProgress < 0.45) {
                // 5 to 6 o'clock: Bright Pink to Pink Magenta (approaching dip)
                float t = (waveProgress - 0.3) / 0.15;
                waveColor = mix(brightPink, pinkMagenta, t);
                // Add soft pink highlight at dip lowest point
                if (waveProgress > 0.4 && radialFactor < 0.3) {
                    waveColor = mix(waveColor, softPink, 1.0 - radialFactor * 3.0);
                }
            } else if (waveProgress < 0.6) {
                // 5 to 6 o'clock: Pink Magenta with Soft Pink (dip)
                float t = (waveProgress - 0.45) / 0.15;
                waveColor = mix(pinkMagenta, magentaPink, t * 0.5);
                // Soft pink highlight at lowest point
                if (radialFactor < 0.4) {
                    waveColor = mix(waveColor, softPink, (1.0 - radialFactor * 2.5) * 0.7);
                }
            } else if (waveProgress < 0.75) {
                // 6 to 7 o'clock: Magenta Pink to Purple Violet (second rise)
                float t = (waveProgress - 0.6) / 0.15;
                waveColor = mix(magentaPink, purpleViolet, t);
            } else {
                // 7 to 8 o'clock: Purple Violet dominance
                waveColor = purpleViolet;
                // Slight fade as approaching maximum width
                waveColor = mix(waveColor, deepIndigo2, (waveProgress - 0.75) * 0.3);
            }
            
            // Apply radial gradient effect
            waveColor = mix(waveColor, waveColor * 0.7, radialFactor * 0.3);
            
            // Override base gradient with brighter wave colors
            // Make wave highly visible
            lowerColor = waveColor * 1.3;
        }
    }
    
    // === SOUTH POLE TRANSITION ===
    // Add corona effect near south pole
    if (verticalPosition < -0.7 && eclipseFactor > 0.85) {
        float southPoleFactor = smoothstep(-0.7, -1.0, verticalPosition);
        float coronaFactor = smoothstep(0.85, 1.0, eclipseFactor);
        
        vec3 southPoleColor = redOrange;
        if (eclipseFactor > 0.92) {
            southPoleColor = mix(redOrange, goldenYellow, smoothstep(0.92, 0.96, eclipseFactor));
        }
        if (eclipseFactor > 0.96) {
            southPoleColor = mix(goldenYellow, brightGold, smoothstep(0.96, 1.0, eclipseFactor));
        }
        
        lowerColor = mix(lowerColor, southPoleColor, southPoleFactor * coronaFactor);
    }
    
    // === SOUTH POLE LIGHTING ===
    float southPoleLight = pow(max(0.0, -verticalPosition), 1.5);
    float southSunIntensity = 0.9 + southPoleLight * 0.3;
    
    // Apply lighting
    lowerColor = lowerColor * southSunIntensity;
    
    // === IMPROVED HEMISPHERE BLENDING - Prevent black bleeding ===
    vec3 color;
    
    // Create smoother, more colorful blending zones
    if (verticalPosition > 0.15) {
        // Upper hemisphere dominates higher up
        color = upperColor;
    } else if (verticalPosition < -0.15) {
        // Lower hemisphere dominates lower down
        color = lowerColor;
    } else {
        // Smooth equatorial blending zone (-0.15 to 0.15)
        // Favor brighter colors in the blend to prevent black dominance
        float blendFactor = smoothstep(-0.15, 0.15, verticalPosition);
        
        // Brighten both colors before blending to prevent dark bleeding
        vec3 brightLower = lowerColor * 1.3; // Brighten lower colors
        vec3 brightUpper = upperColor * 1.1; // Slight upper brighten
        
        color = mix(brightLower, brightUpper, blendFactor);
        
        // Ensure minimum brightness in blend zone
        color = max(color, vec3(0.1, 0.05, 0.15)); // Prevent total black
    }
    
    // === MODULAR DEFORMATION-BASED COLOR RESPONSE ===
    // Apply band-isolated color changes to prevent bleeding
    float deformIntensity = smoothstep(0.0, 0.15, abs(organicDeform));
    color = applyBandDeformation(color, organicDeform, deformIntensity);
    vColor = color;
    
    // Screen position and point sizing
    vec4 mvPosition = modelViewMatrix * vec4(displaced, 1.0);
    
    float baseSize = 6.0;
    float randomSize = 0.95 + aRandom * 0.1;
    
    // Zoom scaling with proper dot size adjustment
    // Camera distance ranges from 2.0 (close) to 15.0 (far)
    float zoomFactor = uCameraDistance / 3.5; // Normalize to default distance
    
    // Apply scaling based on zoom level (now relative to baseSize)
    float perspectiveScale;
    if (uCameraDistance <= 2.0) {
        // Maximum zoom in - make dots 200% larger (2x the default)
        perspectiveScale = 2.0;  // Will be multiplied by baseSize
    } else if (uCameraDistance <= 3.5) {
        // Zoomed in (closer than default) - scale up smoothly
        float t = (3.5 - uCameraDistance) / 1.5; // 0 at 3.5, 1 at 2.0
        perspectiveScale = 1.0 + (1.0 * t); // Interpolate from 1.0 to 2.0
    } else {
        // Zoomed out (farther than default) - scale down based on distance
        perspectiveScale = sqrt(3.5 / uCameraDistance) * 0.8;
    }
    
    gl_PointSize = baseSize * perspectiveScale * randomSize;
    gl_PointSize = clamp(gl_PointSize, 0.5, 20.0); // Increased max size for close zoom
    
    gl_Position = projectionMatrix * mvPosition;
}

