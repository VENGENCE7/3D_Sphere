// ========================================
// GEOMETRY SYSTEM MODULE
// Contains point sizing, normal calculations, and geometric transformations
// ========================================

// ========================================
// NORMAL CALCULATION
// Calculates perturbed normals for proper lighting with wave displacement
// ========================================
vec3 calculatePerturbedNormal(vec3 pos, vec3 originalNormal, float shapeDisplacement, float time, float radius) {
    // Calculate perturbed normal using gradient method
    vec3 tangent1 = normalize(cross(originalNormal, vec3(0.0, 1.0, 0.0)));
    if (length(tangent1) < 0.01) {
        tangent1 = normalize(cross(originalNormal, vec3(1.0, 0.0, 0.0)));
    }
    vec3 tangent2 = normalize(cross(originalNormal, tangent1));
    
    float epsilon = 0.01;
    vec3 posT1 = pos + tangent1 * epsilon;
    vec3 posT2 = pos + tangent2 * epsilon;
    
    // Sample neighboring displacements for gradient calculation
    // Note: This requires access to the createSphericalShape function
    // In the main shader, this will be handled by importing the wave system
    float dispT1 = shapeDisplacement; // Placeholder - will be calculated in main shader
    float dispT2 = shapeDisplacement; // Placeholder - will be calculated in main shader
    
    vec3 perturbedNormal = normalize(originalNormal + 
        tangent1 * (dispT1 - shapeDisplacement) * 30.0 + 
        tangent2 * (dispT2 - shapeDisplacement) * 30.0);
        
    return perturbedNormal;
}

// ========================================
// POINT SIZING CALCULATION
// Dynamic camera-based point sizing to maintain optimal visual density
// ========================================
float calculatePointSize(float baseSize, float foldDepth, float aRandom, float uCameraDistance, float vEdgeFade) {
    // Uniform point sizing - no variation to maintain coverage
    float size = baseSize; // Base size (typically 6.0)
    
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
    float finalSize = size * foldSize * shadowSize * edgeSize * randomSize * distSize * perspectiveScale;
    
    // Stricter clamping to prevent overlap at far distances
    finalSize = clamp(finalSize, 1.0, 12.0);
    
    return finalSize;
}

// ========================================
// EDGE FADE CALCULATION
// Calculates edge fade factor to prevent black strips at meridian
// ========================================
float calculateEdgeFade(vec3 originalNormal, vec3 displaced, vec3 cameraPosition, float vFoldDepth) {
    // Calculate edge fade - ensure no black at meridian
    vec3 viewDir = normalize(cameraPosition - displaced);
    float edgeFactor = abs(dot(originalNormal, viewDir)); 
    // Minimum fade of 0.7 to prevent black strips
    float edgeFade = max(0.7, smoothstep(0.1, 0.9, edgeFactor));
    
    // For a complete sphere with colors on both sides, we don't want to make back faces black
    // Instead, we'll treat both sides the same
    float isBackFacing = 0.0; // Disabled - treat all surfaces the same
    
    // Reduced fade in deep folds to maintain visibility
    if (vFoldDepth < -0.15) {
        float foldFade = 1.0 + vFoldDepth * 1.5; // Reduced from 3.0
        edgeFade *= max(foldFade, 0.6); // Minimum 0.6 (was 0.2)
    }
    
    return edgeFade;
}

// ========================================
// RADIAL DISTANCE CALCULATION
// Calculates normalized radial distance for effects
// ========================================
float calculateRadialDistance(vec3 displaced, float radius) {
    return length(displaced) / radius;
}

// ========================================
// FOLD DEPTH EXTRACTION
// Extracts fold depth value for fragment shader effects
// ========================================
float extractFoldDepth(vec3 pos, float time) {
    // This will need to call the wave system function
    // In the main shader, this will be handled by importing the wave system
    // For now, return a placeholder
    return 0.0; // Will be calculated in main shader using createFoldingWaves
}

// ========================================
// GEOMETRY TRANSFORMATION
// Handles the main geometric transformation pipeline
// ========================================
struct GeometryResult {
    vec3 displaced;
    vec3 perturbedNormal;
    float foldDepth;
    float radialDist;
    float edgeFade;
    float distortion;
    float pointSize;
};

GeometryResult processGeometry(
    vec3 initialPosition, 
    vec3 originalNormal,
    float aRandom,
    float uTime,
    float uCameraDistance,
    vec3 cameraPosition,
    float radius,
    float totalDisplacement,
    float shapeDisplacement
) {
    GeometryResult result;
    
    // Apply displacement along the normal
    result.displaced = initialPosition + originalNormal * totalDisplacement;
    
    // Calculate perturbed normal (will need wave system integration in main shader)
    result.perturbedNormal = calculatePerturbedNormal(initialPosition, originalNormal, shapeDisplacement, uTime, radius);
    
    // Store fold depth for fragment shader
    result.foldDepth = extractFoldDepth(initialPosition, uTime); // Will be replaced in main shader
    result.radialDist = calculateRadialDistance(result.displaced, radius);
    
    // Calculate edge fade
    result.edgeFade = calculateEdgeFade(originalNormal, result.displaced, cameraPosition, result.foldDepth);
    
    result.distortion = totalDisplacement;
    
    // Calculate dynamic point size
    result.pointSize = calculatePointSize(6.0, result.foldDepth, aRandom, uCameraDistance, result.edgeFade);
    
    return result;
}