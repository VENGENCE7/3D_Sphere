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
    vec3 darkViolet = vec3(0.102, 0.0, 0.212);      // #1A0036 - Dark violet (replaces magentaPink)
    vec3 deepDark = vec3(0.039, 0.0, 0.129);        // #0A0021 - Deep dark (final color)
    vec3 deepIndigo2 = vec3(0.137, 0.024, 0.212);   // #230636 - Deep indigo 2
    vec3 brightRedOrange = vec3(0.973, 0.271, 0.153); // #F84527 - Bright red-orange (before golden glow)
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
    
    // === CONFIGURABLE WAVE PARAMETERS ===
    // Adjust these to control wave position and shape
    float WAVE_START_WIDTH = 0.1;   // Initial width of wave (as fraction of PI)
    float WAVE_END_WIDTH = 0.8;      // Final width at wave end (as fraction of PI)
    
    // === WAVE COVERAGE AND POSITION CONTROL ===
    float WAVE_COVERAGE = 0.5;        // How much of front hemisphere to cover (0.8 = 80%)
    float WAVE_MID_LATITUDE = 0.5;   // Base mid-latitude for wave (0.5=equator, 1.0=south pole)
    float WAVE_LATITUDE_RANGE = 0.25;  // How much wave oscillates around mid-latitude
    float WAVE_ANGULAR_START = 0.4;  // 8 o'clock front-visible position
    float WAVE_ANGULAR_END = 0.65;    // 3.5 o'clock front-visible position
    
    // === WAVE LATITUDE CONTROL ===
    float WAVE_LAT_START = 0.35;       // Starting latitude 
    float WAVE_LAT_END = 0.7;         // Ending latitude
    
    // === INDIVIDUAL DIP/RISE CONTROL ===
    // Control each dip and rise amplitude (positive = down toward south, negative = up toward equator)
    float WAVE_DIP_1_AMPLITUDE = 0.15;   // First dip depth
    float WAVE_RISE_1_AMPLITUDE = 0.125;  // First rise height  
    float WAVE_DIP_2_AMPLITUDE = 0.2;    // Second dip depth
    float WAVE_RISE_2_AMPLITUDE = 0.05; // Second rise height
    float WAVE_DIP_3_AMPLITUDE = 0.1;    // Third dip depth
    
    // === WAVE SEGMENT WIDTH CONTROL ===
    // Control the width/duration of each segment (0.0 to 1.0 of total wave)
    float WAVE_SEG_1_WIDTH = 0.1;   // First dip width
    float WAVE_SEG_2_WIDTH = 0.2;   // First rise width
    float WAVE_SEG_3_WIDTH = 0.05;   // Second dip width
    float WAVE_SEG_4_WIDTH = 0.4;   // Second rise width
    float WAVE_SEG_5_WIDTH = 0.6;   // Third dip width
    
    // Calculate spherical coordinates using reference pattern
    vec3 pointDir = normalize(originalWorldPos);
    float angle = atan(pointDir.x, pointDir.z);  // Angular position around sphere
    float normalizedAngle = (angle + PI) / (2.0 * PI);  // 0=back, 0.25=left, 0.5=front, 0.75=right, 1=back
    
    // Eclipse factor (distance from rim)
    float theta = acos(originalWorldPos.y / radius);  // Angle from north pole (0 to PI)
    
    // Spatial visibility weights (from reference)
    // Front is at normalizedAngle = 0.5
    // Right is at normalizedAngle = 0.75
    // Left is at normalizedAngle = 0.25
    float frontWeight = pow(max(0.0, cos((normalizedAngle - 0.5) * 2.0 * PI)), 2.0);
    float rightWeight = pow(max(0.0, cos((normalizedAngle - 0.75) * 2.0 * PI)), 1.5);
    float leftWeight = pow(max(0.0, cos((normalizedAngle - 0.25) * 2.0 * PI)), 3.0);
    
    // Combine weights for asymmetric visibility (stronger on front-right)
    float spatialWeight = max(frontWeight, rightWeight * 0.8) + leftWeight * 0.3;
    
    // Wave band calculation based on angular position
    // Wave travels from 3 o'clock (right) to 8 o'clock (left-bottom)
    // 3 o'clock = normalizedAngle ~0.625 (between front 0.5 and right 0.75)
    // 8 o'clock = normalizedAngle ~0.35 (between left 0.25 and front 0.5)
    
    float waveProgress = 0.0;
    bool inWaveBand = false;
    
    // Wave ribbon in mid-latitude band of lower hemisphere
    // Constrained to front-visible area only (avoid going behind sphere)
    float waveStartAngle = WAVE_ANGULAR_START;  // 8 o'clock front
    float waveEndAngle = WAVE_ANGULAR_END;      // 3.5 o'clock front
    
    // Check if we're in the wave's angular coverage area (right to left)
    if (normalizedAngle >= waveStartAngle && normalizedAngle <= waveEndAngle) {
        // Calculate progress along the wave path (reversed: 1.0 at start, 0.0 at end)
        waveProgress = 1.0 - (normalizedAngle - waveStartAngle) / (waveEndAngle - waveStartAngle);
        
        // Only apply wave in lower hemisphere and within coverage area
        if (verticalPosition < 0.0) {  // Lower hemisphere only
            // Check if we're in the mid-latitude band
            float currentLatitude = theta / PI;  // 0.5 = equator, 1.0 = south pole
            float latitudeDiff = abs(currentLatitude - WAVE_MID_LATITUDE);
            
            if (latitudeDiff < WAVE_LATITUDE_RANGE) {
                inWaveBand = true;
            }
        }
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
            lowerColor = mix(winePurple, darkViolet * 0.5, t);
        } else {
            // Near south pole - darker for corona to stand out
            float t = (depth - 0.8) / 0.2;
            lowerColor = mix(darkViolet * 0.5, deepIndigo2, t);
        }
    } else {
        lowerColor = centerBlack;
    }
    
    // Apply wave band with high visibility for debugging
    if (inWaveBand) {
        // Calculate wave shape following the spherical curvature
        // Wave undulates along the surface as it travels radially
        
        // Calculate width interpolation based on progress
        float currentWidth = mix(WAVE_START_WIDTH, WAVE_END_WIDTH, waveProgress);
        
        // Declare wave variables
        float waveCenterTheta;
        float waveWidthTheta;
        
        // Manual control for precise ribbon-like wave
        // 5-point path: 3.5→5→3.5→6→8 o'clock in mid-latitudes
        
        // Controlled wave with individual dip/rise segments
        
        // Base latitude that moves from start to end
        float baseLat = mix(WAVE_LAT_START, WAVE_LAT_END, waveProgress);
        
        // Calculate cumulative segment positions
        float seg1End = WAVE_SEG_1_WIDTH;
        float seg2End = seg1End + WAVE_SEG_2_WIDTH;
        float seg3End = seg2End + WAVE_SEG_3_WIDTH;
        float seg4End = seg3End + WAVE_SEG_4_WIDTH;
        float seg5End = seg4End + WAVE_SEG_5_WIDTH;
        
        // Normalize progress based on actual segment widths
        float normalizedProgress = waveProgress * seg5End;
        
        float waveOffset = 0.0;
        float segmentWidth = WAVE_START_WIDTH;  // Renamed to avoid redefinition
        
        if (normalizedProgress < seg1End) {
            // First DIP
            float t = normalizedProgress / seg1End;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth dip curve
            waveOffset = WAVE_DIP_1_AMPLITUDE * smoothT;
            segmentWidth = mix(WAVE_START_WIDTH, WAVE_START_WIDTH * 1.2, smoothT);
            
        } else if (normalizedProgress < seg2End) {
            // First RISE
            float t = (normalizedProgress - seg1End) / WAVE_SEG_2_WIDTH;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth rise curve
            waveOffset = mix(WAVE_DIP_1_AMPLITUDE, WAVE_RISE_1_AMPLITUDE, smoothT);
            segmentWidth = mix(WAVE_START_WIDTH * 1.2, WAVE_START_WIDTH, smoothT);
            
        } else if (normalizedProgress < seg3End) {
            // Second DIP
            float t = (normalizedProgress - seg2End) / WAVE_SEG_3_WIDTH;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth dip curve
            waveOffset = mix(WAVE_RISE_1_AMPLITUDE, WAVE_DIP_2_AMPLITUDE, smoothT);
            segmentWidth = mix(WAVE_START_WIDTH, WAVE_START_WIDTH * 1.3, smoothT);
            
        } else if (normalizedProgress < seg4End) {
            // Second RISE
            float t = (normalizedProgress - seg3End) / WAVE_SEG_4_WIDTH;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth rise curve
            waveOffset = mix(WAVE_DIP_2_AMPLITUDE, WAVE_RISE_2_AMPLITUDE, smoothT);
            segmentWidth = mix(WAVE_START_WIDTH * 1.3, WAVE_START_WIDTH * 1.1, smoothT);
            
        } else {
            // Third DIP (final)
            float t = min((normalizedProgress - seg4End) / WAVE_SEG_5_WIDTH, 1.0);
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth dip curve
            waveOffset = mix(WAVE_RISE_2_AMPLITUDE, WAVE_DIP_3_AMPLITUDE, smoothT);
            segmentWidth = mix(WAVE_START_WIDTH * 1.1, WAVE_END_WIDTH, smoothstep(0.0, 1.0, t));
        }
        
        // Apply the calculated offset to base latitude
        float targetLat = baseLat + waveOffset;
        
        // Ensure latitude stays within reasonable bounds
        targetLat = clamp(targetLat, 0.3, 0.9);
        
        waveCenterTheta = PI * targetLat;
        waveWidthTheta = PI * segmentWidth;
            
        
        // Check if current position (theta) is within the wave band
        float waveBandTop = waveCenterTheta - waveWidthTheta * 0.5;  // Closer to north pole
        float waveBandBottom = waveCenterTheta + waveWidthTheta * 0.5;  // Closer to south pole
        
        if (theta >= waveBandTop && theta <= waveBandBottom) {
            // Radial gradient within the wave band (using spherical coordinates)
            float positionInWave = (theta - waveBandTop) / (waveBandBottom - waveBandTop);
            float radialFactor = clamp(positionInWave, 0.0, 1.0);
            
            // Sample the base gradient color at this position for blending
            vec3 baseGradientColor = lowerColor;  // Current background color at this position
            
            // Color selection based on wave progress and position
            // Wave colors blend with surrounding gradient
            vec3 waveColor = deepPurple;
            
            if (waveProgress < 0.25) {
                // 3 to 5 o'clock: Blend with mid-latitude colors
                float t = waveProgress / 0.25;
                vec3 baseColor = mix(deepPurple, winePurple, t);
                // Blend with surrounding gradient for natural transition
                waveColor = mix(baseGradientColor * 1.2, baseColor, 0.7);
            } else if (waveProgress < 0.4) {
                // Rise to center-left: Transition through wine to pink
                float t = (waveProgress - 0.25) / 0.15;
                vec3 baseColor = mix(winePurple, brightPink, t);
                // Stronger color but still influenced by surroundings
                waveColor = mix(baseGradientColor * 1.1, baseColor, 0.75);
            } else if (waveProgress < 0.6) {
                // Dip toward south: Gradual transition to warmer colors
                float t = (waveProgress - 0.4) / 0.2;
                vec3 redOrange = vec3(1.0, 0.325, 0.184);  // #FF532F - Red-orange
                
                // Blend based on latitude - more red-orange as we go south
                if (waveCenterTheta > PI * 0.75) {  // Approaching south region
                    float southBlend = smoothstep(PI * 0.75, PI * 0.85, waveCenterTheta);
                    vec3 baseColor = mix(pinkMagenta, redOrange, southBlend);
                    // Merge with background gradient
                    waveColor = mix(baseGradientColor, baseColor * 1.1, 0.8);
                } else {
                    waveColor = mix(baseGradientColor * 1.1, mix(brightPink, pinkMagenta, t), 0.75);
                }
            } else if (waveProgress < 0.75) {
                // Rise from south: Transition back through pink tones
                float t = (waveProgress - 0.6) / 0.15;
                vec3 redOrange = vec3(1.0, 0.325, 0.184);
                // Blend red-orange with magenta based on position
                vec3 baseColor = mix(mix(redOrange, pinkMagenta, 0.6), darkViolet, t);
                waveColor = mix(baseGradientColor * 1.1, baseColor, 0.75);
            } else {
                // 8 o'clock: Fade into dark violet before south pole glow
                float t = (waveProgress - 0.75) / 0.25;
                vec3 baseColor = mix(darkViolet, deepDark, t);
                // Gradually merge with background as wave ends
                float mergeFactor = 0.75 - t * 0.3;  // Fade from 0.75 to 0.45
                waveColor = mix(baseGradientColor, baseColor, mergeFactor);
            }
            
            // Apply radial gradient within the wave band
            // Edges blend more with background, center is more prominent
            float edgeBlend = 1.0 - pow(abs(radialFactor - 0.5) * 2.0, 1.5);
            waveColor = mix(baseGradientColor, waveColor, 0.5 + edgeBlend * 0.5);
            
            // Maximum visibility for debugging
            float waveIntensity = 2.0;  // Very high intensity
            
            // Force high visibility
            float debugVisibility = 0.95;  // Nearly complete override
            
            // Apply wave with maximum visibility for testing
            lowerColor = mix(lowerColor, waveColor * waveIntensity, debugVisibility);
            
            // Add bright center line for visibility
            if (abs(radialFactor - 0.5) < 0.1) {
                lowerColor += waveColor * 0.5;  // Bright center stripe
            }
        }
    }
    
    // === SOUTH POLE RIM GLOW CONTROLS ===
    float SOUTH_GLOW_START = 0.75;         // Where glow starts on rim (0.8 = closer to center)
    float SOUTH_GLOW_WIDTH = 0.2;         // Total width of glow (0.2 = 20% of rim)
    float SOUTH_GLOW_POLE_THICKNESS = 1.0; // Thickness at pole (1.0 = full)
    float SOUTH_GLOW_EQUATOR_THICKNESS = 0.2; // Thickness at equator (0.2 = thin)
    float SOUTH_GLOW_VERTICAL_START = 0.11; // Where glow starts vertically (-0.5 = mid lower hemisphere)
    
    // === SOUTH POLE RIM GLOW ===
    // Only on rim, thicker at pole, thinner toward equator
    if (verticalPosition < SOUTH_GLOW_VERTICAL_START && eclipseFactor > SOUTH_GLOW_START) {
        // Calculate vertical factor (1.0 at south pole, 0.0 at glow start)
        float verticalFactor = smoothstep(SOUTH_GLOW_VERTICAL_START, -1.0, verticalPosition);
        
        // Calculate thickness based on latitude (thicker at pole)
        float glowThickness = mix(SOUTH_GLOW_EQUATOR_THICKNESS, SOUTH_GLOW_POLE_THICKNESS, verticalFactor);
        
        // Calculate glow intensity based on rim distance
        float glowEnd = SOUTH_GLOW_START + SOUTH_GLOW_WIDTH;
        float rimGlowFactor = smoothstep(SOUTH_GLOW_START, min(glowEnd, 1.0), eclipseFactor);
        
        vec3 southPoleColor;
        
        // Color transitions within the glow band
        float glowProgress = (eclipseFactor - SOUTH_GLOW_START) / SOUTH_GLOW_WIDTH;
        
        if (glowProgress < 0.4) {
            // DeepDark to Bright Red-Orange transition
            float t = glowProgress / 0.4;
            southPoleColor = mix(deepDark, brightRedOrange, t);
        } else if (glowProgress < 0.7) {
            // Bright Red-Orange to Golden Yellow
            float t = (glowProgress - 0.4) / 0.3;
            southPoleColor = mix(brightRedOrange, goldenYellow, t);
        } else {
            // Golden Yellow stays golden (no white transition)
            float t = (glowProgress - 0.7) / 0.3;
            // Use a deeper golden color instead of bright gold to avoid white
            vec3 deepGolden = vec3(1.0, 0.7, 0.1);  // Deeper, more saturated gold
            southPoleColor = mix(goldenYellow, deepGolden, t);
        }
        
        // Apply the glow with thickness modulation
        float finalGlowIntensity = rimGlowFactor * glowThickness * verticalFactor;
        lowerColor = mix(lowerColor, southPoleColor, finalGlowIntensity);
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

