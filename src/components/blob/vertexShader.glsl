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
    vec3 softPink = vec3(0.894, 0.792, 0.863);      // #E4CADC - Soft pink
    vec3 darkViolet = vec3(0.102, 0.0, 0.212);      // #1A0036 - Dark violet (replaces magentaPink)
    vec3 deepDark = vec3(0.039, 0.0, 0.129);        // #0A0021 - Deep dark (final color)
    vec3 deepIndigo2 = vec3(0.137, 0.024, 0.212);   // #230636 - Deep indigo 2
    vec3 brightRedOrange = vec3(0.973, 0.271, 0.153); // #F84527 - Bright red-orange (before golden glow)
    vec3 redOrange = vec3(1.0, 0.325, 0.184);       // #FF532F - Red-orange for south pole
    vec3 transitionBlack = vec3(0.051, 0.0, 0.137); // #0D0023 - Transition black for lower hemisphere
    
    // === NEW WAVE GRADIENT COLORS ===
    vec3 deepEquatorPurple = vec3(0.098, 0.0, 0.22); // #190038 - Deep purple for equator transition
    vec3 brightMagenta = vec3(0.733, 0.129, 0.612);  // #BB219C - Top of wave gradient
    vec3 vibrantPink = vec3(0.863, 0.298, 0.647);   // #DC4CA5 - Vibrant pink before red
    vec3 waveRed = vec3(1.0, 0.102, 0.176);          // #FF1A2D - Main dip color (left side)
    vec3 deepWine = vec3(0.396, 0.067, 0.216);       // #651137 - Deep wine after red
    vec3 darkPurple = vec3(0.2, 0.043, 0.239);       // #330B3D - Transition from red
    vec3 mediumPurple = vec3(0.416, 0.075, 0.545);   // #6A138B - Lower gradient
    vec3 lighterPurple = vec3(0.537, 0.176, 0.706);  // #892DB4 - Right side dip color
    vec3 equatorViolet = vec3(0.533, 0.016, 1.0);    // #8804FF - Bright violet for equator rim
    
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
    float WAVE_END_WIDTH = 0.3;      // Final width at wave end (as fraction of PI)
    
    // === WAVE MOVEMENT CONTROLS ===
    // UP/DOWN MOVEMENT CONTROLS
    float WAVE_VERTICAL_ENABLED = 0.0;      // Master control: 0.0 = no vertical movement, 1.0 = full vertical movement
    float WAVE_VERTICAL_SPEED = 0.3;        // Speed of up/down oscillation (optimized for 60fps)
    float WAVE_VERTICAL_AMPLITUDE = 0.01;   // How far wave moves up/down (0.0 = none, 0.2 = large)
    float WAVE_VERTICAL_COMPLEXITY = 1.0;   // Complexity of vertical movement (1.0 = simple, 4.0 = complex)
    
    // HORIZONTAL OSCILLATION CONTROLS (wave stays in front, oscillates left-right)
    float WAVE_HORIZONTAL_ENABLED = 1.0;    // Enable horizontal oscillation (0.0 = off, 1.0 = on)
    float WAVE_HORIZONTAL_SPEED = 0.2;      // Speed of left-right oscillation (smooth 60fps)
    float WAVE_HORIZONTAL_AMPLITUDE = 0.08; // How far wave moves left-right (as fraction of front area)
    float WAVE_HORIZONTAL_WAVINESS = 2.0;   // Number of waves in the oscillation pattern
    
    // LATERAL/HORIZONTAL MOVEMENT CONTROLS  
    float WAVE_LATERAL_SPEED = 0.35;         // Speed of side-to-side flow (optimized for 60fps)
    float WAVE_LATERAL_AMPLITUDE = 0.06;    // How far wave shifts laterally (reduced for smoothness)
    
    // ORGANIC FLOW CONTROLS (optimized for 60fps)
    float WAVE_ORGANIC_INTENSITY = 0.9;     // Overall organic movement intensity (reduced for smoothness)
    float WAVE_FLOW_SPEED_1 = 0.25;         // Primary organic flow speed (halved for 60fps)
    float WAVE_FLOW_SPEED_2 = 0.15;         // Secondary organic flow speed (optimized)  
    float WAVE_PULSE_SPEED = 0.4;           // Pulsing rhythm speed (reduced for smoothness)
    
    // BREATHING/PULSING CONTROLS (60fps optimized)
    float WAVE_BREATHING_SPEED = 0.5;       // Speed of breathing effect (much slower for smoothness)
    float WAVE_BREATHING_INTENSITY = 0.15;  // Intensity of breathing (reduced for subtlety)
    
    // WIDTH VARIATION CONTROLS (60fps optimized)
    float WAVE_WIDTH_VARIATION = 0.2;       // How much wave width varies (reduced)
    float WAVE_WIDTH_SPEED = 0.3;           // Speed of width changes (much slower)
    
    // === WAVE COVERAGE AND POSITION CONTROL ===
    float WAVE_COVERAGE = 0.8;        // How much of front hemisphere to cover (0.8 = 80%)
    float WAVE_MID_LATITUDE = 0.5;   // Base mid-latitude for wave (0.5=equator, 1.0=south pole)
    float WAVE_LATITUDE_RANGE = 0.575;  // How much wave oscillates around mid-latitude
    float WAVE_ANGULAR_START = 0.215;  // 8 o'clock front-visible position
    float WAVE_ANGULAR_END = 0.75;    // 3.5 o'clock front-visible position
    
    // === WAVE LATITUDE CONTROL ===
    // Create smile shape: left → dips toward south pole → rises right (flipped)
    float WAVE_LAT_START = 0.35;       // Starting latitude (left side now, closer to equator)
    float WAVE_LAT_END = 0.45;         // Ending latitude (right side now, back toward equator)
    float WAVE_LAT_MIDDLE = 0.65;      // Middle latitude (deepest point toward south pole)
    
    // === INDIVIDUAL DIP/RISE CONTROL ===
    // Control each dip and rise amplitude (positive = down toward south, negative = up toward equator)
    float WAVE_DIP_1_AMPLITUDE = 0.15;   // First dip depth
    float WAVE_RISE_1_AMPLITUDE = 0.13;  // First rise height  
    float WAVE_DIP_2_AMPLITUDE = 0.175;    // Second dip depth
    float WAVE_RISE_2_AMPLITUDE = 0.05; // Second rise height
    float WAVE_DIP_3_AMPLITUDE = 0.05;    // Third dip depth
    float WAVE_RISE_3_AMPLITUDE = 0.06;  // Third rise height (new)
    
    // === WAVE SEGMENT WIDTH CONTROL ===
    // Control the width/duration of each segment (0.0 to 1.0 of total wave)
    float WAVE_SEG_1_WIDTH = 0.175;   // First dip width
    float WAVE_SEG_2_WIDTH = 0.4;   // First rise width
    float WAVE_SEG_3_WIDTH = 0.05;   // Second dip width
    float WAVE_SEG_4_WIDTH = 0.5;   // Second rise width
    float WAVE_SEG_5_WIDTH = 0.35;   // Third dip width
    float WAVE_SEG_6_WIDTH = 0.8;   // Third rise width (new)
    
    // Calculate spherical coordinates using reference pattern
    vec3 pointDir = normalize(originalWorldPos);
    
    // === CAMERA-FACING WAVE ===
    // Calculate angle relative to camera to make wave always visible from front
    vec3 cameraViewDir = normalize(cameraPosition);  // Camera direction from origin
    vec3 toPoint = normalize(originalWorldPos);
    
    // Calculate angle in camera space
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), cameraViewDir));
    vec3 up = cross(cameraViewDir, right);
    
    // Get angle around sphere relative to camera view
    float x = dot(toPoint, right);
    float z = dot(toPoint, cameraViewDir);
    float angle = atan(x, z);
    float normalizedAngle = (angle + PI) / (2.0 * PI);  // Camera-relative angle
    
    // Eclipse factor (distance from rim)
    float theta = acos(originalWorldPos.y / radius);  // Angle from north pole (0 to PI)
    
    // === CAMERA-FACING VISIBILITY ===
    // Wave is always visible from camera's perspective
    // Calculate if this point is facing the camera
    float facingCamera = dot(toPoint, cameraViewDir);
    
    // Show wave on front-facing side (facing camera)
    float cameraFacingWeight = smoothstep(-0.2, 0.4, facingCamera);
    
    // Keep some spatial variation for organic look
    float spatialVariation = sin(normalizedAngle * PI * 2.0) * 0.2 + 0.8;
    
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
    
    // === HORIZONTAL OSCILLATION (LEFT-RIGHT IN FRONT) ===
    // Wave oscillates left-right within the visible front area with wave-like motion
    // Create complex wave-like horizontal movement
    float primaryWave = sin(uTime * WAVE_HORIZONTAL_SPEED) * 0.7;
    float secondaryWave = sin(uTime * WAVE_HORIZONTAL_SPEED * 1.7 + PI * 0.3) * 0.3;
    float wavePattern = sin(waveProgress * PI * WAVE_HORIZONTAL_WAVINESS); // Wave shape along the band
    
    // Combine waves for organic left-right movement
    float horizontalOscillation = (primaryWave + secondaryWave + wavePattern * 0.2) * WAVE_HORIZONTAL_AMPLITUDE * WAVE_HORIZONTAL_ENABLED;
    
    // Adjust the angular boundaries to oscillate within front area
    float animatedStartAngle = WAVE_ANGULAR_START + horizontalOscillation;
    float animatedEndAngle = WAVE_ANGULAR_END + horizontalOscillation;
    
    // Check if we're in the wave's angular coverage area (with oscillation)
    if (normalizedAngle >= animatedStartAngle && normalizedAngle <= animatedEndAngle) {
        // Calculate progress along the wave path (normal: 0.0 at start, 1.0 at end)
        // This will flip the wave so right side is mainly visible
        waveProgress = (normalizedAngle - animatedStartAngle) / (animatedEndAngle - animatedStartAngle);
        
        // Only apply wave in lower hemisphere, within coverage area, AND facing camera
        if (verticalPosition < 0.0 && cameraFacingWeight > 0.1) {  // Lower hemisphere and camera-facing
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
        
        // === EQUATOR RIM VIOLET EFFECT ===
        // Add bright violet near the equator rim, similar to upper hemisphere
        vec3 baseGradient;
        
        if (depth < 0.2) {
            // Near equator - darker purples
            baseGradient = mix(centerBlack, deepPurple, depth / 0.2);
        } else if (depth < 0.5) {
            // Mid region - transition through purples
            float t = (depth - 0.2) / 0.3;
            baseGradient = mix(deepPurple, winePurple, t);
        } else if (depth < 0.8) {
            // Lower region - wine to pink transition
            float t = (depth - 0.5) / 0.3;
            baseGradient = mix(winePurple, darkViolet * 0.5, t);
        } else {
            // Near south pole - darker for corona to stand out
            float t = (depth - 0.8) / 0.2;
            baseGradient = mix(darkViolet * 0.5, deepIndigo2, t);
        }
        
        // Apply equator violet on the rim for lower hemisphere
        if (depth < 0.3 && eclipseFactor > 0.6) {
            // Calculate how strong the rim color should be based on rim distance and depth
            float rimIntensity = smoothstep(0.6, 0.95, eclipseFactor);
            float depthFade = 1.0 - smoothstep(0.0, 0.3, depth);  // Stronger at equator
            
            // Create smooth gradient from center black → blue → violet on rim
            vec3 rimColor;
            
            if (eclipseFactor < 0.75) {
                // Smooth transition zone: black to blue (60% to 75%)
                float t = smoothstep(0.6, 0.75, eclipseFactor);
                rimColor = mix(centerBlack, blue, t);
            } else if (eclipseFactor < 0.88) {
                // Smooth transition zone: blue to violet (75% to 88%)
                float t = smoothstep(0.75, 0.88, eclipseFactor);
                rimColor = mix(blue, equatorViolet, t);
            } else {
                // Full violet at the rim edge (88% to 95%)
                // Add subtle glow intensification at the very edge
                float edgeGlow = smoothstep(0.88, 0.95, eclipseFactor);
                rimColor = mix(equatorViolet, equatorViolet * 1.2, edgeGlow * 0.5);
            }
            
            // Apply the rim color with depth-based fading
            float blendFactor = rimIntensity * depthFade * 0.8;  // Max 80% blend
            lowerColor = mix(baseGradient, rimColor, blendFactor);
        } else {
            lowerColor = baseGradient;
        }
    } else {
        lowerColor = centerBlack;
    }
    
    // Apply wave band only in inner region (below rim gradient)
    // Wave should not appear where rim gradient is active (eclipseFactor > 0.6)
    if (inWaveBand && eclipseFactor < 0.6) {
        // Calculate wave shape following the spherical curvature
        // Wave undulates along the surface as it travels radially
        
        // === ORGANIC WAVE MOVEMENT (LIQUID-LIKE) ===
        // Add liquid-like flow patterns for smooth, fluid movement
        float liquidFlow1 = sin(uTime * WAVE_FLOW_SPEED_1 + normalizedAngle * PI * 2.5) * 0.08 * WAVE_ORGANIC_INTENSITY;
        float liquidFlow2 = cos(uTime * WAVE_FLOW_SPEED_2 * 0.7 - waveProgress * PI * 1.5) * 0.06 * WAVE_ORGANIC_INTENSITY;
        float liquidPulse = sin(uTime * WAVE_PULSE_SPEED * 0.8 + theta * 1.5) * 0.04 * WAVE_ORGANIC_INTENSITY;
        
        // Combine for organic flow (renamed from organicFlow to avoid conflicts)
        float organicFlow1 = liquidFlow1;
        float organicFlow2 = liquidFlow2;
        float organicPulse = liquidPulse;
        
        // Calculate width interpolation based on progress with organic variation
        float widthVariation = 1.0 + sin(uTime * WAVE_WIDTH_SPEED + waveProgress * PI * 4.0) * WAVE_WIDTH_VARIATION;
        float currentWidth = mix(WAVE_START_WIDTH, WAVE_END_WIDTH, waveProgress) * widthVariation;
        
        // Declare wave variables
        float waveCenterTheta;
        float waveWidthTheta;
        
        // Manual control for precise ribbon-like wave
        // 5-point path: 3.5→5→3.5→6→8 o'clock in mid-latitudes
        
        // Controlled wave with individual dip/rise segments
        
        // === ANIMATED WAVE MOVEMENT ===
        // Add time-based movement using control parameters
        
        // VERTICAL (UP/DOWN) MOVEMENT
        float verticalOscillation = sin(uTime * WAVE_VERTICAL_SPEED + normalizedAngle * PI * WAVE_VERTICAL_COMPLEXITY) * WAVE_VERTICAL_AMPLITUDE;
        
        // LATERAL MOVEMENT
        float lateralOffset = sin(uTime * WAVE_LATERAL_SPEED + waveProgress * PI) * WAVE_LATERAL_AMPLITUDE;
        
        // Add the organic flow components
        float organicOffset = organicFlow1 + organicFlow2 + organicPulse;
        
        // Combine all vertical movements with master control
        float totalVerticalMovement = (verticalOscillation + organicOffset * 0.5) * WAVE_VERTICAL_ENABLED;
        
        // === SMILE-SHAPED WAVE PATH WITH LIQUID FLOW ===
        // Create a smooth smile curve that flows like liquid
        // waveProgress: 1.0 at right (start), 0.0 at left (end)
        
        // Enhanced smile curve with smoother transition
        float smileCurve = pow(4.0 * waveProgress * (1.0 - waveProgress), 1.2); // Smoother parabola
        
        // Add asymmetry for more natural smile (slightly deeper on one side)
        float asymmetry = sin(waveProgress * PI) * 0.1;
        smileCurve = smileCurve * (1.0 + asymmetry);
        
        // Interpolate latitude: starts near equator, dips to south pole, rises back
        float baseLat = mix(WAVE_LAT_START, WAVE_LAT_MIDDLE, smileCurve);
        
        // Multi-layered liquid flow for realistic fluid dynamics
        float liquidFlow = sin(uTime * 0.12 + waveProgress * PI * 2.0) * 0.04;
        float liquidWave = cos(uTime * 0.18 - waveProgress * PI * 3.0) * 0.025;
        float liquidRipple = sin(uTime * 0.25 + waveProgress * PI * 4.0) * 0.015;
        
        // Apply all movements with liquid-like flow
        baseLat = baseLat + 
                  lateralOffset * 0.3 +  // Reduced lateral for stable smile shape
                  totalVerticalMovement + 
                  liquidFlow + liquidWave + liquidRipple;
        
        // Calculate cumulative segment positions
        float seg1End = WAVE_SEG_1_WIDTH;
        float seg2End = seg1End + WAVE_SEG_2_WIDTH;
        float seg3End = seg2End + WAVE_SEG_3_WIDTH;
        float seg4End = seg3End + WAVE_SEG_4_WIDTH;
        float seg5End = seg4End + WAVE_SEG_5_WIDTH;
        float seg6End = seg5End + WAVE_SEG_6_WIDTH;  // Add 6th segment
        
        // Normalize progress based on actual segment widths
        float normalizedProgress = waveProgress * seg6End;  // Use seg6End instead of seg5End
        
        float waveOffset = 0.0;
        float segmentWidth = WAVE_START_WIDTH;  // Renamed to avoid redefinition
        
        // Add breathing effect to segment amplitudes with organic variation
        float breathingAmplitude = sin(uTime * WAVE_BREATHING_SPEED + normalizedProgress * PI * 0.5) * WAVE_BREATHING_INTENSITY + 1.0;
        
        // Add secondary organic breathing patterns with controls
        float organicBreathing = sin(uTime * WAVE_FLOW_SPEED_2 + waveProgress * PI * 3.0) * 0.15 * WAVE_ORGANIC_INTENSITY;
        float waveUndulation = cos(uTime * WAVE_PULSE_SPEED - normalizedAngle * PI * 4.0) * 0.1 * WAVE_ORGANIC_INTENSITY;
        breathingAmplitude += organicBreathing + waveUndulation;
        
        if (normalizedProgress < seg1End) {
            // First DIP with animation
            float t = normalizedProgress / seg1End;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth dip curve
            float animatedAmplitude = WAVE_DIP_1_AMPLITUDE * breathingAmplitude;
            waveOffset = animatedAmplitude * smoothT;
            float widthPulse = 1.0 + sin(uTime * 0.4 + t * PI) * 0.05; // Reduced speed and amplitude for 60fps
            segmentWidth = mix(WAVE_START_WIDTH, WAVE_START_WIDTH * 1.2, smoothT) * widthPulse;
            
        } else if (normalizedProgress < seg2End) {
            // First RISE with flow
            float t = (normalizedProgress - seg1End) / WAVE_SEG_2_WIDTH;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth rise curve
            float animatedDip = WAVE_DIP_1_AMPLITUDE * (0.9 + sin(uTime * 0.3) * 0.1); // 60fps optimized
            float animatedRise = WAVE_RISE_1_AMPLITUDE * breathingAmplitude;
            waveOffset = mix(animatedDip, animatedRise, smoothT);
            segmentWidth = mix(WAVE_START_WIDTH * 1.2, WAVE_START_WIDTH, smoothT);
            
        } else if (normalizedProgress < seg3End) {
            // Second DIP with stronger animation
            float t = (normalizedProgress - seg2End) / WAVE_SEG_3_WIDTH;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth dip curve
            float animatedRise = WAVE_RISE_1_AMPLITUDE * (0.9 + sin(uTime * 0.25) * 0.1); // 60fps optimized
            float animatedDip2 = WAVE_DIP_2_AMPLITUDE * (breathingAmplitude * 1.2);
            waveOffset = mix(animatedRise, animatedDip2, smoothT);
            float widthOscillation = 1.0 + cos(uTime * 0.3 + t * PI) * 0.08; // Reduced for smoothness
            segmentWidth = mix(WAVE_START_WIDTH, WAVE_START_WIDTH * 1.3, smoothT) * widthOscillation;
            
        } else if (normalizedProgress < seg4End) {
            // Second RISE with wave motion
            float t = (normalizedProgress - seg3End) / WAVE_SEG_4_WIDTH;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth rise curve
            float flowingDip = WAVE_DIP_2_AMPLITUDE * (1.0 + sin(uTime * 0.35 - t * PI) * 0.15); // 60fps smooth
            float flowingRise = WAVE_RISE_2_AMPLITUDE * breathingAmplitude;
            waveOffset = mix(flowingDip, flowingRise, smoothT);
            segmentWidth = mix(WAVE_START_WIDTH * 1.3, WAVE_START_WIDTH * 1.1, smoothT);
            
        } else if (normalizedProgress < seg5End) {
            // Third DIP with subtle movement
            float t = (normalizedProgress - seg4End) / WAVE_SEG_5_WIDTH;
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth dip curve
            float animatedRise2 = WAVE_RISE_2_AMPLITUDE * (0.95 + sin(uTime * 0.3) * 0.05); // Subtle 60fps
            float animatedDip3 = WAVE_DIP_3_AMPLITUDE * breathingAmplitude;
            waveOffset = mix(animatedRise2, animatedDip3, smoothT);
            segmentWidth = mix(WAVE_START_WIDTH * 1.1, WAVE_START_WIDTH * 1.15, smoothT);
            
        } else {
            // Third RISE (final) with fade animation
            float t = min((normalizedProgress - seg5End) / WAVE_SEG_6_WIDTH, 1.0);
            float smoothT = 0.5 * (1.0 - cos(t * PI));  // Smooth rise curve
            float fadingDip = WAVE_DIP_3_AMPLITUDE * (1.0 + sin(uTime * 0.25) * 0.08); // Smooth fade
            float fadingRise = WAVE_RISE_3_AMPLITUDE * (breathingAmplitude * (1.0 - t * 0.3));
            waveOffset = mix(fadingDip, fadingRise, smoothT);
            float endWidthAnimation = 1.0 + sin(uTime * 0.2 - t * PI) * 0.05; // Gentle end animation
            segmentWidth = mix(WAVE_START_WIDTH * 1.15, WAVE_END_WIDTH, smoothstep(0.0, 1.0, t)) * endWidthAnimation;
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
            
            // === VERTICAL RADIAL GRADIENT WITHIN WAVE BAND ===
            // radialFactor: 0.0 = top of wave band, 1.0 = bottom of wave band
            vec3 verticalGradient;
            
            // === DYNAMIC COLOR MOVEMENT ===
            // Add time-based animation to make colors flow and shift
            float colorFlowSpeed = 0.8; // Speed of color movement
            float colorPulseSpeed = 2.0; // Speed of pulsing effects
            
            // Create flowing offset that moves colors through the wave
            float flowOffset = sin(uTime * colorFlowSpeed + waveProgress * 3.0) * 0.15;
            float pulseOffset = sin(uTime * colorPulseSpeed + radialFactor * PI) * 0.05;
            
            // Adjust radialFactor with animation
            float animatedRadial = radialFactor + flowOffset + pulseOffset;
            animatedRadial = clamp(animatedRadial, 0.0, 1.0);
            
            // Color shifting animation - colors morph between adjacent colors
            float colorShift = sin(uTime * 1.2 + waveProgress * 2.0) * 0.5 + 0.5;
            float breathingEffect = sin(uTime * 1.5 + normalizedAngle * PI * 2.0) * 0.3 + 0.7;
            
            // Create vertical gradient from top to bottom with animation
            if (animatedRadial < 0.08) {
                // Very top: deepEquatorPurple to brightMagenta for clean equator transition
                float t = animatedRadial / 0.08;
                // Animate between colors
                vec3 animatedPurple = mix(deepEquatorPurple, deepEquatorPurple * 1.3, colorShift);
                vec3 animatedMagenta = mix(brightMagenta, brightMagenta * breathingEffect, colorShift);
                verticalGradient = mix(animatedPurple, animatedMagenta, t);
            } else if (animatedRadial < 0.2) {
                // brightMagenta to softPink with pulsing
                float t = (animatedRadial - 0.08) / 0.12;
                vec3 animatedMagenta = brightMagenta * (0.9 + sin(uTime * 2.5) * 0.2);
                vec3 animatedPink = mix(softPink, pinkMagenta, colorShift * 0.4);
                verticalGradient = mix(animatedMagenta, animatedPink, t);
            } else if (animatedRadial < 0.33) {
                // softPink to vibrantPink with color morphing
                float t = (animatedRadial - 0.2) / 0.13;
                vec3 morphedPink = mix(softPink, vibrantPink, breathingEffect);
                vec3 morphedVibrant = mix(vibrantPink, waveRed * 0.8, colorShift * 0.3);
                verticalGradient = mix(morphedPink, morphedVibrant, t);
            } else if (animatedRadial < 0.48) {
                // vibrantPink to waveRed with pulsing intensity
                float t = (animatedRadial - 0.33) / 0.15;
                float redPulse = 1.0 + sin(uTime * 3.0 + waveProgress * PI) * 0.2;
                vec3 animatedVibrant = vibrantPink * breathingEffect;
                vec3 animatedRed = waveRed * redPulse;
                verticalGradient = mix(animatedVibrant, animatedRed, t);
            } else if (animatedRadial < 0.68) {
                // waveRed to deepWine with flowing transition
                float t = (animatedRadial - 0.48) / 0.2;
                float flowEffect = sin(uTime * 1.8 + radialFactor * PI * 2.0) * 0.15 + 1.0;
                vec3 flowingRed = mix(waveRed, brightRed, colorShift * 0.3) * flowEffect;
                vec3 flowingWine = deepWine * (0.8 + breathingEffect * 0.3);
                verticalGradient = mix(flowingRed, flowingWine, t);
            } else {
                // Rest of band: deepWine expands and smoothly fades with animation
                float t = (animatedRadial - 0.68) / 0.32;
                float fadeAnimation = sin(uTime * 1.0 + waveProgress * PI) * 0.2 + 0.8;
                vec3 animatedWine = deepWine * fadeAnimation;
                verticalGradient = mix(animatedWine, baseGradientColor * breathingEffect, t);
            }
            
            // === HORIZONTAL TRANSITIONS AND SEGMENT-SPECIFIC COLORS ===
            vec3 waveColor = verticalGradient;
            
            // Determine if we're in a dip or rise segment
            bool isDip = (normalizedProgress < seg1End) ||  // First DIP
                        (normalizedProgress >= seg2End && normalizedProgress < seg3End) ||  // Second DIP
                        (normalizedProgress >= seg4End && normalizedProgress < seg5End);    // Third DIP
            
            // === ANIMATED COLOR ZONES WITH MOVEMENT ===
            // Add time-based morphing to segment colors
            float segmentAnimation = sin(uTime * 1.5 + normalizedProgress * PI) * 0.3 + 0.7;
            float waveColorFlow = sin(uTime * 2.0 - waveProgress * PI * 2.0) * 0.5 + 0.5;
            
            // RIGHT SIDE (beginning of wave, 3.5 o'clock)
            if (waveProgress < 0.3) {
                if (isDip) {
                    // Animate lighter purple for dips on right side
                    vec3 animatedLighterPurple = mix(lighterPurple, violetPurple, waveColorFlow * 0.4);
                    waveColor = mix(verticalGradient, animatedLighterPurple * segmentAnimation, 0.6);
                    // Transition to base color below with animation
                    if (radialFactor > 0.6) {
                        float fadeT = (radialFactor - 0.6) / 0.4;
                        float fadeAnimation = sin(uTime * 1.8) * 0.2 + 0.8;
                        waveColor = mix(waveColor, baseGradientColor * fadeAnimation, fadeT * 0.5);
                    }
                }
            }
            // LEFT SIDE AND NEAR SOUTH (middle to end)
            else if (waveProgress > 0.5 && waveProgress < 0.85) {
                if (isDip && waveCenterTheta > PI * 0.7) {  // Near south pole
                    // Animated waveRed color for dips very close to south pole
                    float redIntensity = 1.0 + sin(uTime * 3.5 + waveProgress * PI) * 0.25;
                    vec3 animatedWaveRed = waveRed * redIntensity;
                    
                    if (waveCenterTheta > PI * 0.8) {  // Very close to south pole
                        // Override with animated waveRed in the middle band
                        if (radialFactor > 0.25 && radialFactor < 0.6) {
                            waveColor = mix(animatedWaveRed, brightRed, waveColorFlow * 0.2);
                        } else if (radialFactor >= 0.6) {
                            // Transition to deepWine below with flow
                            float t = (radialFactor - 0.6) / 0.4;
                            vec3 flowingWine = mix(deepWine, winePurple, sin(uTime * 2.2) * 0.3);
                            waveColor = mix(animatedWaveRed, flowingWine, t);
                        }
                    } else {
                        // Regular near-south behavior with animation
                        if (radialFactor > 0.3 && radialFactor < 0.7) {
                            waveColor = mix(verticalGradient, animatedWaveRed, 0.7 * segmentAnimation);
                            // Transition to deepWine
                            if (radialFactor > 0.5) {
                                float t = (radialFactor - 0.5) / 0.2;
                                vec3 morphingWine = deepWine * (0.8 + waveColorFlow * 0.4);
                                waveColor = mix(animatedWaveRed, morphingWine, t);
                            }
                        }
                    }
                }
            }
            // FINAL 15% - HORIZONTAL FADE (85-100%)
            else if (waveProgress >= 0.85) {
                // Animated horizontal transition
                float t = (waveProgress - 0.85) / 0.15;
                float fadeFlow = sin(uTime * 1.2 + t * PI) * 0.3 + 0.7;
                vec3 animatedDeepPurple = deepPurple * fadeFlow;
                vec3 animatedWinePurple = mix(winePurple, darkViolet, waveColorFlow * 0.5);
                vec3 horizontalColor = mix(animatedDeepPurple, animatedWinePurple, t);
                // 70% base color, 30% background gradient with animation
                waveColor = mix(horizontalColor, baseGradientColor * segmentAnimation, 0.3);
                // Fade out intensity with flow
                float fadeIntensity = (1.0 - t * 0.5) * fadeFlow;
                waveColor = mix(baseGradientColor, waveColor, fadeIntensity);
            }
            
            // === SMOOTH BLENDING FOR SPHERE BENDING ILLUSION ===
            // Create smooth transitions at wave edges for seamless integration
            
            // Calculate smooth edge falloff based on vertical position in wave
            float verticalBlend = 1.0;
            if (radialFactor < 0.15) {
                // Top edge: smooth fade in
                verticalBlend = smoothstep(0.0, 0.15, radialFactor);
            } else if (radialFactor > 0.85) {
                // Bottom edge: smooth fade out
                verticalBlend = smoothstep(1.0, 0.85, radialFactor);
            }
            
            // Calculate horizontal blend for smooth transitions at wave ends
            float horizontalBlend = 1.0;
            if (waveProgress < 0.1) {
                // Right start: smooth fade in
                horizontalBlend = smoothstep(0.0, 0.1, waveProgress);
            } else if (waveProgress > 0.8) {
                // Left end: very smooth fade out
                float fadeStart = 0.8;
                float fadeEnd = 1.0;
                horizontalBlend = smoothstep(fadeEnd, fadeStart, waveProgress);
            }
            
            // Apply spherical bending effect - smoother in the middle, softer at edges
            float centerDistance = abs(radialFactor - 0.5) * 2.0;
            float bendingFactor = 1.0 - pow(centerDistance, 2.0); // Quadratic falloff
            
            // Combine all blending factors for ultra-smooth transition
            float totalBlend = verticalBlend * horizontalBlend * (0.4 + bendingFactor * 0.6);
            
            // Mix wave color with base more smoothly
            vec3 blendedColor = mix(baseGradientColor, waveColor, totalBlend);
            
            // Add subtle color interpolation for bending illusion
            vec3 sphereBendColor = mix(baseGradientColor * 1.1, blendedColor, totalBlend * 0.8);
            
            // Apply final color with smooth intensity
            float waveIntensity = 1.3 + bendingFactor * 0.4; // Gentler intensity variation
            
            // === FADE WAVE NEAR RIM GRADIENT BOUNDARY ===
            // Smoothly fade the wave as it approaches eclipseFactor = 0.6
            float rimFade = 1.0;
            if (eclipseFactor > 0.45) {
                // Start fading at 0.45, completely gone by 0.6
                rimFade = smoothstep(0.6, 0.45, eclipseFactor);
            }
            
            // Apply wave with rim fade
            lowerColor = mix(lowerColor, sphereBendColor * waveIntensity, totalBlend * 0.85 * rimFade);
            
            // Very subtle center enhancement for depth
            if (abs(radialFactor - 0.5) < 0.2) {
                float centerEnhance = 1.0 - abs(radialFactor - 0.5) * 5.0;
                lowerColor = mix(lowerColor, lowerColor * 1.15, centerEnhance * 0.3);
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
    
    float baseSize = 8.0;
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

