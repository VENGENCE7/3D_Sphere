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
    float MEMBRANE_SPEED = 0.25;        // Overall animation speed (0.1 = slow, 0.5 = fast, 1.0 = very fast)
    float BULGE_AMPLITUDE = 0.15;      // Maximum bulge height (0.05 = subtle, 0.2 = pronounced)
    float GROOVE_AMPLITUDE = -0.10;    // Maximum groove depth (-0.05 = shallow, -0.15 = deep)
    
    // === DEFORMATION SCALE CONTROLS ===
    float NOISE_SCALE = 2.5;           // Size of primary deformations (1.0 = large, 5.0 = small)
    float SECONDARY_SCALE = 2.0;       // Size of detail ripples (3.0 = large, 10.0 = tiny)
    
    // === MOTION CHARACTERISTICS ===
    float PULSE_INTENSITY = 0.1;       // Bulge pulsing strength (0.0 = none, 0.3 = strong)
    float BREATHE_INTENSITY = 0.1;     // Groove breathing strength (0.0 = none, 0.3 = strong)
    float VERTEX_VARIATION = 0.3;      // Per-vertex randomization (0.0 = uniform, 1.0 = highly varied)
    
    // === NOISE LAYER WEIGHTS ===
    float PRIMARY_WEIGHT = 0.5;        // Primary noise influence (0.0-1.0)
    float DETAIL_WEIGHT = 0.4;         // Detail noise influence (0.0-1.0)
    
    // =========================================
    // === END OF CONTROL PANEL ===
    // =========================================
    
    if (ENABLE_ORGANIC_MOVEMENT < 0.5) {
        return 0.0; // System disabled
    }
    
    // Primary organic movement - large smooth bulges
    vec3 noiseCoord = p * NOISE_SCALE;
    float primaryNoise = snoise(noiseCoord + vec3(time * MEMBRANE_SPEED, 0.0, 0.0));
    
    // Add temporal variation for continuous flow
    primaryNoise += snoise(noiseCoord + vec3(0.0, time * MEMBRANE_SPEED * 0.7, 0.0)) * 0.5;
    primaryNoise += snoise(noiseCoord + vec3(0.0, 0.0, time * MEMBRANE_SPEED * 0.5)) * 0.3;
    
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
    
    // === ECLIPSE-STYLE RADIAL GRADIENT WITH DEFORMATION-BASED SHIFTING ===
    // Eclipse color palette
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
    
    // Calculate rim factor for eclipse effect
    vec3 worldViewDir = normalize(cameraPosition - worldPosition);
    float rimFactor = 1.0 - abs(dot(perturbedNormal, worldViewDir));
    
    // === GRADIENT SHIFTING BASED ON DEFORMATION ===
    // When surface bulges outward (positive deformation), shift gradient toward rim (higher values)
    // When surface grooves inward (negative deformation), shift gradient toward center (lower values)
    float gradientShift = organicDeform * 2.0; // Scale the deformation effect on gradient
    
    // Apply shift to eclipse factor
    float eclipseFactor = rimFactor;
    
    // Shift the gradient based on deformation
    // Bulges: move gradient outward (toward corona colors)
    // Grooves: move gradient inward (toward center colors)
    eclipseFactor = clamp(eclipseFactor + gradientShift, 0.0, 1.0);
    
    // Smooth the eclipse factor
    eclipseFactor = smoothstep(0.0, 1.0, eclipseFactor);
    
    // Calculate vertical position for hemisphere detection
    float verticalPosition = worldNormal.y; // -1 at bottom, 0 at equator, 1 at top
    
    // Calculate smooth blending factor for equator transition
    float equatorBlend = smoothstep(-0.3, 0.3, verticalPosition);
    
    // Calculate both color gradients
    vec3 upperColor = centerBlack;
    vec3 lowerColor = centerBlack;
    
    // === UPPER GRADIENT - Full color spectrum ===
    // Modified to respond to deformation
    if (eclipseFactor > 0.0) {
        float t = smoothstep(0.0, 0.25, eclipseFactor);
        upperColor = mix(centerBlack, deepViolet, t);
    }
    
    if (eclipseFactor > 0.20) {
        float t = smoothstep(0.20, 0.35, eclipseFactor);
        upperColor = mix(upperColor, purple, t * 0.9);
    }
    
    if (eclipseFactor > 0.30) {
        float t = smoothstep(0.30, 0.45, eclipseFactor);
        upperColor = mix(upperColor, darkBlue, t * 0.85);
    }
    
    if (eclipseFactor > 0.40) {
        float t = smoothstep(0.40, 0.55, eclipseFactor);
        upperColor = mix(upperColor, blue, t * 0.9);
    }
    
    if (eclipseFactor > 0.50) {
        float t = smoothstep(0.50, 0.65, eclipseFactor);
        upperColor = mix(upperColor, magenta, t * 0.95);
    }
    
    if (eclipseFactor > 0.60) {
        float t = smoothstep(0.60, 0.72, eclipseFactor);
        upperColor = mix(upperColor, pink, t * 0.9);
    }
    
    if (eclipseFactor > 0.68) {
        float t = smoothstep(0.68, 0.78, eclipseFactor);
        upperColor = mix(upperColor, red, t * 0.95);
    }
    
    if (eclipseFactor > 0.75) {
        float t = smoothstep(0.75, 0.85, eclipseFactor);
        upperColor = mix(upperColor, orange, t * 0.85);
    }
    
    if (eclipseFactor > 0.82) {
        float t = smoothstep(0.82, 0.92, eclipseFactor);
        upperColor = mix(upperColor, goldenYellow, t * 0.9);
    }
    
    if (eclipseFactor > 0.90) {
        float t = smoothstep(0.90, 1.0, eclipseFactor);
        upperColor = mix(upperColor, brightGold, t);
    }
    
    // === LOWER GRADIENT ===
    // Modified to respond to deformation
    if (eclipseFactor > 0.0) {
        float t = smoothstep(0.0, 0.30, eclipseFactor);
        lowerColor = mix(centerBlack, deepViolet, t);
    }
    
    // Special bands in lower hemisphere
    float specialBandStart = -0.174;
    float specialBandEnd = -0.425;
    float inSpecialBandRegion = smoothstep(specialBandEnd - 0.05, specialBandEnd, verticalPosition) * 
                                smoothstep(specialBandStart + 0.05, specialBandStart, verticalPosition);
    
    if (eclipseFactor > 0.30 && eclipseFactor < 0.50 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.30, 0.50, eclipseFactor);
        lowerColor = mix(lowerColor, brightRed, t * inSpecialBandRegion * 0.8);
    }
    
    if (eclipseFactor > 0.50 && eclipseFactor < 0.58 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.50, 0.58, eclipseFactor);
        lowerColor = mix(lowerColor, deepPurple, t * inSpecialBandRegion * 0.85);
    }
    
    if (eclipseFactor > 0.58) {
        float t = smoothstep(0.58, 0.68, eclipseFactor);
        lowerColor = mix(lowerColor, winePurple, t * 0.9);
    }
    
    if (eclipseFactor > 0.68) {
        float t = smoothstep(0.68, 0.78, eclipseFactor);
        lowerColor = mix(lowerColor, red, t * 0.85);
    }
    
    if (eclipseFactor > 0.78) {
        float t = smoothstep(0.78, 0.98, eclipseFactor);
        lowerColor = mix(lowerColor, goldenYellow, t * 0.9);
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
    
    // === ADDITIONAL COLOR ENHANCEMENT FOR DEFORMATION ===
    // Brighten bulges slightly, darken grooves slightly
    if (organicDeform > 0.0) {
        // Bulge - slightly brighter and more saturated
        color = mix(color, color * 1.2, organicDeform * 2.0);
    } else {
        // Groove - slightly darker
        color = mix(color, color * 0.8, abs(organicDeform) * 2.0);
    }
    
    vIntensity = 0.5;
    vColor = color;
    
    // Screen position and point sizing
    vec4 mvPosition = modelViewMatrix * vec4(displaced, 1.0);
    
    float baseSize = 2.0;
    float randomSize = 0.95 + aRandom * 0.1;
    
    // Modified zoom scaling: stronger reduction when zoomed out
    float zoomFactor = uCameraDistance / 3.5;
    
    // Apply different scaling based on zoom level
    float perspectiveScale;
    if (zoomFactor <= 1.0) {
        // Zoomed in (closer than default) - keep current perfect size
        perspectiveScale = 6.0 * sqrt(zoomFactor);
    } else {
        // Zoomed out (farther than default) - reduce size more (25% extra reduction)
        perspectiveScale = 6.0 * sqrt(zoomFactor) * 0.75;  // 0.75 = 25% smaller
    }
    
    gl_PointSize = baseSize * randomSize * perspectiveScale;
    gl_PointSize = clamp(gl_PointSize, 0.05, 9.0);
    
    gl_Position = projectionMatrix * mvPosition;
}