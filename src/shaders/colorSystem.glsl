// ========================================
// COLOR SYSTEM MODULE
// Contains all eclipse color gradient and lighting calculations
// ========================================

const float PI = 3.14159265359;

// ========================================
// COLOR GRADIENT CALCULATION
// Eclipse-style radial gradient with vertical position mapping
// ========================================
vec3 calculateEclipseColor(vec3 worldPosition, vec3 worldNormal, vec3 perturbedNormal, vec3 cameraPosition, float totalDisplacement) {
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
    float CORONA_TOP_COVERAGE = 0.10;    // 10% coverage at top (Y-axis) - full thickness
    float CORONA_BOTTOM_COVERAGE = 0.02; // 2% coverage at bottom (Y-axis) - full thickness
    float CORONA_EQUATOR_THINNING = 0.01; // Corona thickness at equator sides (1% of rim = extremely thin line)
    
    // Warm gradient (red/orange/golden) thickness configuration
    float WARM_GRADIENT_TOP_START = 0.68;    // Where warm colors start on top (68% = more cool colors)
    float WARM_GRADIENT_BOTTOM_START = 0.70; // Where warm colors start on bottom (70% = even more cool colors)
    float WARM_GRADIENT_EQUATOR_COMPRESSION = 0.5; // How much to compress warm colors at equator (0.5 = 50% thinner)
    
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
    // Calculate front-center restriction for special bands
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
    // Deep Violet → Magenta (0.30-0.40) - front-center only, in special region
    if (eclipseFactor > 0.30 && eclipseFactor < 0.40 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.30, 0.40, eclipseFactor);
        float magentaStrength = t * bandRadialFactor * inSpecialBandRegion * bandVisibility;
        lowerColor = mix(lowerColor, magenta, magentaStrength * 0.9);
    }
    
    // Magenta → White thin stripe (0.40-0.42) - front-center only, very thin
    if (eclipseFactor > 0.40 && eclipseFactor < 0.42 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.40, 0.42, eclipseFactor);
        float whiteStrength = t * bandRadialFactor * inSpecialBandRegion * bandVisibility;
        lowerColor = mix(lowerColor, whiteStripe, whiteStrength * 0.85);
    }
    
    // White → Bright Red #ff1b17 (0.42-0.50) - front-center only
    if (eclipseFactor > 0.42 && eclipseFactor < 0.50 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.42, 0.50, eclipseFactor);
        float redStrength = t * bandRadialFactor * inSpecialBandRegion * bandVisibility;
        lowerColor = mix(lowerColor, brightRed, redStrength * 0.9);
    }
    
    // Bright Red → Deep Purple rgba(28,0,52) (0.50-0.58) - front-center area
    if (eclipseFactor > 0.50 && eclipseFactor < 0.58 && inSpecialBandRegion > 0.0) {
        float t = smoothstep(0.50, 0.58, eclipseFactor);
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
    
    // Apply warm gradient compression for lower hemisphere
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
    float thinningFactor = max(sidePosition, coronaEquatorProximity * 0.8);
    
    // Calculate corona width with smooth transition
    float coronaWidth;
    if (thinningFactor > 0.2) {
        // Smooth transition from full thickness to thin line
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
    
    return color;
}