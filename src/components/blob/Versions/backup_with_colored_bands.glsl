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
varying float vOrganicDeform;

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
    float BULGE_AMPLITUDE = 0.15;      // Reduced for calmer appearance
    float GROOVE_AMPLITUDE = -0.05;    // Shallower grooves for smoother surface
    
    // === DEFORMATION SCALE CONTROLS ===
    float NOISE_SCALE = 2.5;           // Size of primary deformations (1.0 = large, 5.0 = small)
    float SECONDARY_SCALE = 1.0;       // Size of detail ripples (3.0 = large, 10.0 = tiny)
    
    // === MOTION CHARACTERISTICS ===
    float PULSE_INTENSITY = 0.1;       // Bulge pulsing strength (0.0 = none, 0.3 = strong)
    float BREATHE_INTENSITY = 0.3;     // Groove breathing strength (0.0 = none, 0.3 = strong)
    float VERTEX_VARIATION = 0.1;      // Per-vertex randomization (0.0 = uniform, 1.0 = highly varied)
    
    // === NOISE LAYER WEIGHTS ===
    float PRIMARY_WEIGHT = 0.4;        // Primary noise influence (0.0-1.0)
    float DETAIL_WEIGHT = 0.4;         // Detail noise influence (0.0-1.0)
    
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
    // Range: -0.25 to +0.25 units for organic movement
    totalDisplacement = clamp(totalDisplacement, -0.25, 0.25);
    
    return baseShape + totalDisplacement;
}

void main() {
    vec3 pos = initialPosition;
    vec3 originalNormal = normalize(pos);
    
    // Get the organic deformation value
    float organicDeform = createOrganicDeformation(pos);
    vOrganicDeform = organicDeform; // Pass to fragment shader for gradient shifting
    
    // Get the main shape displacement
    float shapeDisplacement = createSphericalShape(pos);
    float totalDisplacement = shapeDisplacement;
    
    // Apply displacement along the normal
    vec3 displaced = pos + originalNormal * totalDisplacement;
    
    // Store deformation depth for fragment shader
    vFoldDepth = organicDeform;
    vRadialDist = length(displaced) / radius;
    
    // Calculate edge fade
    vec3 viewDir = normalize(cameraPosition - displaced);
    float edgeFactor = abs(dot(originalNormal, viewDir)); 
    vEdgeFade = max(0.7, smoothstep(0.1, 0.9, edgeFactor));
    
    // Reduced fade in deep folds
    if (vFoldDepth < -0.05) {
        float foldFade = 1.0 + vFoldDepth * 1.5;
        vEdgeFade *= max(foldFade, 0.6);
    }
    
    vDistortion = totalDisplacement;
    
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
    
    vNormal = perturbedNormal;
    vWorldPos = displaced;
    
    // Transform to world space
    vec4 worldPos4 = modelMatrix * vec4(displaced, 1.0);
    vec3 worldPosition = worldPos4.xyz;
    vec3 worldNormal = normalize((modelMatrix * vec4(perturbedNormal, 0.0)).xyz);
    
    // === ECLIPSE-STYLE RADIAL GRADIENT WITH SMOOTH BLENDING ===
    // Simplified color palette (9 colors for cleaner eclipse spectrum)
    vec3 centerBlack = vec3(0.078, 0.098, 0.086);  // #141916 - Center black
    vec3 darkBlue = vec3(0.1, 0.0, 0.59);          // #1A0096 - Dark blue
    vec3 blue = vec3(0.1843, 0.0, 0.8353);         // #2F00D5 - Blue
    vec3 magenta = vec3(0.592, 0.0, 0.863);        // #9700DC - Magenta
    vec3 neonPurple = vec3(0.749, 0.278, 1.0);     // #BF47FF - Neon purple
    vec3 lightpink = vec3(1.0, 0.208, 0.694);      // #FF35B1 - Light Pink
    vec3 brightRed = vec3(0.992, 0.384, 0.192);    // #FD6231 - Orange-red for rims
    vec3 goldenYellow = vec3(1.0, 0.8, 0.2);       // #FFCC33 - Golden yellow
    vec3 brightGold = vec3(1.0, 0.9, 0.4);         // #FFE666 - Bright gold corona
    
    // Additional colors for lower hemisphere
    vec3 deepPurple = vec3(0.11, 0.0, 0.204);      // #1C0034 - Deep purple
    vec3 winePurple = vec3(0.318, 0.063, 0.188);   // #511030 - Wine purple
    vec3 pinkMagenta = vec3(0.854, 0.345, 0.698);  // #DA58B2 - Pink magenta
    vec3 pureWhite = vec3(1.0, 1.0, 1.0);          // #FFFFFF - White
    vec3 darkMaroon = vec3(0.49, 0.039, 0.157);    // #7D0A28 - Dark maroon
    vec3 darkRose = vec3(0.455, 0.106, 0.188);     // #741B30 - Dark rose
    vec3 deepVioletFill = vec3(0.165, 0.0, 0.373); // #2A005F - Deep violet filler
    vec3 darkIndigo = vec3(0.024, 0.0, 0.141);     // #060024 - Darker transition color
    
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
    
    // Calculate smooth blending factor for equator transition
    float equatorBlend = smoothstep(-0.3, 0.3, verticalPosition);
    
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
    // At poles: pink-red gradient 40%, yellow reduced to 10% total
    float goldenStart = mix(0.99, 0.97, latitudeFactor); // Golden starts at 99% at equator (1% band), 97% at pole (3% band)
    float yellowStart = mix(0.96, 0.90, latitudeFactor); // Yellow zone reduced to 7% at poles
    float redStart = mix(0.93, 0.70, latitudeFactor);    // Red zone expanded to 20% at poles
    float pinkStart = mix(0.90, 0.50, latitudeFactor);   // Pink zone expanded to 20% at poles
    float purpleEnd = mix(0.85, 0.50, latitudeFactor);   // Purple ends at 50% at poles
    
    // === CLEAN BAND TRANSITIONS - No overlapping ranges ===
    // Each band has exclusive range to prevent color bleeding
    
    if (eclipseFactor <= 0.08) {
        // Band 0: Black to Dark Blue (0.00 - 0.08)
        gradientColor = getColorInBand(eclipseFactor, 0.0, 0.08, centerBlack, darkBlue);
    }
    else if (eclipseFactor <= 0.15) {
        // Band 1: Dark Blue to Blue (0.08 - 0.15)
        gradientColor = getColorInBand(eclipseFactor, 0.08, 0.15, darkBlue, blue * 1.2);
    }
    else if (eclipseFactor <= 0.30) {
        // Band 2: Blue to Magenta (0.15 - 0.30)
        gradientColor = getColorInBand(eclipseFactor, 0.15, 0.30, blue * 1.2, magenta * 1.3);
    }
    else if (eclipseFactor <= purpleEnd) {
        // Band 3: Magenta to Purple (0.30 - purpleEnd)
        vec3 targetPurple = (latitudeFactor < 0.2) ? neonPurple * 1.1 : neonPurple * 1.2;
        gradientColor = getColorInBand(eclipseFactor, 0.30, purpleEnd, magenta * 1.3, targetPurple);
    }
    else if (eclipseFactor <= redStart) {
        // Band 4-5: Purple/Pink to Red transition
        if (latitudeFactor < 0.1) {
            // Equator stays in purple
            gradientColor = neonPurple * 1.1;
        } else if (latitudeFactor < 0.2) {
            // Near equator: lighter pink
            gradientColor = lightpink * 1.0;
        } else {
            // Poles: smooth pink to red gradient (0.50 - 0.70)
            gradientColor = getColorInBand(eclipseFactor, purpleEnd, redStart, lightpink * 1.1, brightRed);
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
            // At equator: fade from purple to black edge
            gradientColor = mix(neonPurple * 1.1, centerBlack, smootherstep(0.85, 0.98, eclipseFactor));
        } else {
            // All other latitudes: solid yellow transitioning to golden
            float t = smootherstep(yellowStart, goldenStart, eclipseFactor);
            gradientColor = mix(goldenYellow, goldenYellow * 1.1, t);
        }
    }
    else {
        // Golden corona band - ultra-thin everywhere
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
    
    // === LOWER HEMISPHERE GRADIENT - Asymmetric spatial distribution ===
    // Color sequence: Black → Deep Purple → #2A005F (filler) → Gradient bands (front-right only) → Red → Yellow
    
    // Calculate lower latitude factor (1.0 at south pole, 0.0 at equator)
    float lowerLatitudeFactor = clamp(-verticalPosition, 0.0, 1.0);
    
    // Calculate angular position for front-right restriction
    vec3 pointDir = normalize(originalWorldPos);
    float angle = atan(pointDir.x, pointDir.z); // -PI to PI
    float normalizedAngle = (angle + PI) / (2.0 * PI); // 0 to 1
    
    // Define spatial regions (0 = back, 0.25 = left, 0.5 = front, 0.75 = right)
    float frontWeight = smoothstep(0.3, 0.7, normalizedAngle) * smoothstep(0.7, 0.3, abs(normalizedAngle - 0.5));
    float rightWeight = smoothstep(0.5, 0.9, normalizedAngle);
    float leftWeight = smoothstep(0.1, 0.35, normalizedAngle) * smoothstep(0.35, 0.1, normalizedAngle);
    
    // Combined visibility for gradient bands (strong on front-right, half on left, none on back)
    float bandVisibility = max(frontWeight, rightWeight * 0.8) + leftWeight * 0.5;
    bandVisibility = clamp(bandVisibility, 0.0, 1.0);
    
    // Wave-responsive thickness modulation
    float waveModulation = sin(uTime * 2.0 + verticalPosition * 4.0 + angle * 2.0) * 0.03;
    
    // Aggressive thickness reduction for yellow and red
    float rimThickness = lowerLatitudeFactor * lowerLatitudeFactor * lowerLatitudeFactor; // Cubic reduction
    
    // Band positions - shifted 10 degrees higher from rim
    float degreeShift = 0.174; // ~10 degrees in radians (doubled from 5)
    float lowerGoldenStart = mix(1.0, 0.99 - degreeShift, rimThickness); // Minimal yellow
    float lowerYellowStart = mix(1.0, 0.97 - degreeShift, rimThickness); // Aggressive reduction
    float lowerRedStart = mix(0.99, 0.93 - degreeShift, rimThickness);   // Red band
    
    // Main gradient bands (5 degrees higher, thick at pole, thin at equator)
    float bandThickness = lowerLatitudeFactor; // Linear thickness variation
    float lowerDarkRoseStart = mix(0.90, 0.75 - degreeShift, bandThickness);
    float lowerMaroonStart = mix(0.85, 0.65 - degreeShift, bandThickness);
    float lowerPinkEnd = mix(0.80, 0.55 - degreeShift, bandThickness);
    float lowerWhiteStart = mix(0.75, 0.45 - degreeShift, bandThickness);
    float lowerPinkStart = mix(0.70, 0.35 - degreeShift, bandThickness);
    float lowerWineStart = mix(0.60, 0.25 - degreeShift, bandThickness);
    float lowerDeepEnd = mix(0.45, 0.15 - degreeShift, bandThickness);
    
    // Initialize with blend of dark indigo and deep violet for smoother base gradient
    lowerColor = mix(darkIndigo, deepVioletFill, 0.5);
    
    // Band transitions with spatial visibility control
    if (eclipseFactor <= 0.08) {
        // Band 0: Black core (always visible)
        lowerColor = getColorInBand(eclipseFactor, 0.0, 0.08, centerBlack, centerBlack * 1.2);
    }
    else if (eclipseFactor <= lowerDeepEnd) {
        // Band 1: Black to Deep Purple (always visible)
        lowerColor = getColorInBand(eclipseFactor, 0.08, lowerDeepEnd, centerBlack, deepPurple);
    }
    else if (eclipseFactor <= lowerWineStart) {
        // Transition zone - use both filler colors for smoother gradient
        vec3 baseColor = getColorInBand(eclipseFactor, lowerDeepEnd, lowerWineStart, deepPurple, winePurple);
        vec3 fillerMix = mix(darkIndigo, deepVioletFill, eclipseFactor * 2.0);
        lowerColor = mix(fillerMix, baseColor, bandVisibility * 0.7);
    }
    else if (eclipseFactor <= lowerPinkStart) {
        // Pink Magenta band (front-right only, wave-modulated)
        if (bandVisibility > 0.1) {
            float modifiedEnd = lowerPinkStart + waveModulation;
            vec3 bandColor = getColorInBand(eclipseFactor, lowerWineStart, modifiedEnd, winePurple, pinkMagenta);
            vec3 fillerGradient = mix(darkIndigo, deepVioletFill, smoothstep(0.0, 1.0, eclipseFactor * 1.5));
            lowerColor = mix(fillerGradient, bandColor, bandVisibility);
        }
    }
    else if (eclipseFactor <= lowerWhiteStart) {
        // White center (front-right only, strongest visibility)
        if (bandVisibility > 0.1) {
            float modifiedEnd = lowerWhiteStart + waveModulation;
            vec3 bandColor = getColorInBand(eclipseFactor, lowerPinkStart, modifiedEnd, pinkMagenta, pureWhite);
            vec3 fillerGradient = mix(darkIndigo, deepVioletFill, 0.8);
            lowerColor = mix(fillerGradient, bandColor, bandVisibility * 1.2);
        }
    }
    else if (eclipseFactor <= lowerPinkEnd) {
        // Pink Magenta return (front-right only)
        if (bandVisibility > 0.1) {
            float modifiedEnd = lowerPinkEnd + waveModulation;
            vec3 bandColor = getColorInBand(eclipseFactor, lowerWhiteStart, modifiedEnd, pureWhite, pinkMagenta);
            vec3 fillerGradient = mix(darkIndigo, deepVioletFill, smoothstep(0.0, 1.0, eclipseFactor * 1.5));
            lowerColor = mix(fillerGradient, bandColor, bandVisibility);
        }
    }
    else if (eclipseFactor <= lowerMaroonStart) {
        // Dark Maroon (front-right with reduced visibility on left)
        if (bandVisibility > 0.05) {
            vec3 bandColor = getColorInBand(eclipseFactor, lowerPinkEnd, lowerMaroonStart, pinkMagenta, darkMaroon);
            vec3 fillerGradient = mix(darkIndigo, deepVioletFill, 0.5);
            lowerColor = mix(fillerGradient, bandColor, bandVisibility * 0.9);
        }
    }
    else if (eclipseFactor <= lowerDarkRoseStart) {
        // Dark Rose (front-right with minimal left visibility)
        if (bandVisibility > 0.02) {
            vec3 bandColor = getColorInBand(eclipseFactor, lowerMaroonStart, lowerDarkRoseStart, darkMaroon, darkRose);
            vec3 fillerGradient = mix(darkIndigo, deepVioletFill, 0.4);
            lowerColor = mix(fillerGradient, bandColor, bandVisibility * 0.8);
        }
    }
    else if (eclipseFactor <= lowerRedStart) {
        // Red band (aggressive thickness reduction)
        vec3 bandColor = getColorInBand(eclipseFactor, lowerDarkRoseStart, lowerRedStart, darkRose, brightRed);
        float redVisibility = rimThickness * bandVisibility;
        vec3 fillerGradient = mix(darkIndigo, deepVioletFill, 0.3);
        lowerColor = mix(fillerGradient, bandColor, redVisibility);
    }
    else if (eclipseFactor <= lowerYellowStart && rimThickness > 0.1) {
        // Yellow band (extremely reduced, only at pole)
        if (lowerLatitudeFactor > 0.7) {
            vec3 bandColor = getColorInBand(eclipseFactor, lowerRedStart, lowerYellowStart, brightRed, goldenYellow * 0.6);
            vec3 fillerGradient = mix(darkIndigo, deepVioletFill, 0.2);
            lowerColor = mix(fillerGradient, bandColor, rimThickness);
        } else {
            // No yellow below 70% latitude
            vec3 fillerGradient = mix(darkIndigo, deepVioletFill, 0.1);
            lowerColor = mix(fillerGradient, brightRed * 0.5, rimThickness * 0.3);
        }
    }
    else if (eclipseFactor <= lowerGoldenStart && lowerLatitudeFactor > 0.8) {
        // Minimal golden corona (only at extreme south pole)
        vec3 bandColor = goldenYellow * 0.8;
        lowerColor = mix(darkIndigo, bandColor, rimThickness * 0.5);
    }
    else {
        // Gradient transition after bands end: bands → #060024 → bright red → yellow
        if (eclipseFactor > lowerGoldenStart && eclipseFactor <= 0.993) {
            // Transition to dark indigo (#060024)
            float transitionFactor = (eclipseFactor - lowerGoldenStart) / (0.993 - lowerGoldenStart);
            lowerColor = mix(mix(darkIndigo, deepVioletFill, 0.1), darkIndigo, transitionFactor);
        }
        else if (eclipseFactor > 0.993 && eclipseFactor <= 0.997) {
            // Transition from dark indigo to bright red
            float transitionFactor = (eclipseFactor - 0.993) / 0.004;
            lowerColor = mix(darkIndigo, brightRed, transitionFactor);
        }
        else if (eclipseFactor > 0.997) {
            // Final transition from bright red to yellow at rim
            float transitionFactor = (eclipseFactor - 0.997) / 0.003;
            lowerColor = mix(brightRed, goldenYellow, transitionFactor);
        }
    }
    
    // === BLEND BETWEEN UPPER AND LOWER GRADIENTS ===
    vec3 color;
    if (verticalPosition > 0.25) {
        color = upperColor;
    } else if (verticalPosition < -0.3) {
        color = lowerColor;
    } else {
        color = mix(lowerColor, upperColor, equatorBlend);
    }
    
    // === MODULAR DEFORMATION-BASED COLOR RESPONSE ===
    // Apply band-isolated color changes to prevent bleeding
    float deformIntensity = smoothstep(0.0, 0.15, abs(organicDeform));
    color = applyBandDeformation(color, organicDeform, deformIntensity);
    
    vIntensity = 0.5;
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