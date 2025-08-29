// ========================================
// MODULAR VERTEX SHADER
// Main vertex shader that imports and coordinates all modules
// ========================================

// === SHADER INPUTS ===
uniform float uTime;
uniform float uCameraDistance;

attribute vec3 initialPosition;
attribute float aRandom;

// === SHADER OUTPUTS ===
varying vec3 vColor;
varying float vIntensity;
varying vec3 vNormal;
varying vec3 vWorldPos;
varying float vEdgeFade;
varying float vDistortion;
varying float vRadialDist;
varying float vFoldDepth;

// === CONSTANTS ===
const float radius = 1.5;
const float PI = 3.14159265359;

// ========================================
// MODULE IMPORTS
// Note: In a real WebGL implementation, these would be included via string concatenation
// For now, we'll replicate the essential functions here with modular structure
// ========================================

// === WAVE SYSTEM MODULE FUNCTIONS ===
#include "waveSystem.glsl"  // Contains: createFoldingWaves, createBendingWaves, createAsymmetricDistortion, createSphericalShape

// === COLOR SYSTEM MODULE FUNCTIONS ===  
#include "colorSystem.glsl"  // Contains: calculateEclipseColor

// === GEOMETRY SYSTEM MODULE FUNCTIONS ===
#include "geometrySystem.glsl"  // Contains: calculatePerturbedNormal, calculatePointSize, processGeometry

// ========================================
// MAIN VERTEX SHADER FUNCTION
// ========================================
void main() {
    vec3 pos = initialPosition;
    vec3 originalNormal = normalize(pos);
    
    // === WAVE SYSTEM PROCESSING ===
    // Get the main shape displacement using wave system
    float shapeDisplacement = createSphericalShape(pos, uTime, radius);
    float totalDisplacement = shapeDisplacement;
    
    // Get fold depth specifically for fragment shader effects
    vFoldDepth = createFoldingWaves(pos, uTime);
    
    // === GEOMETRY PROCESSING ===
    // Apply displacement along the normal
    vec3 displaced = pos + originalNormal * totalDisplacement;
    
    // Calculate perturbed normal using actual wave system
    vec3 tangent1 = normalize(cross(originalNormal, vec3(0.0, 1.0, 0.0)));
    if (length(tangent1) < 0.01) {
        tangent1 = normalize(cross(originalNormal, vec3(1.0, 0.0, 0.0)));
    }
    vec3 tangent2 = normalize(cross(originalNormal, tangent1));
    
    float epsilon = 0.01;
    vec3 posT1 = pos + tangent1 * epsilon;
    vec3 posT2 = pos + tangent2 * epsilon;
    float dispT1 = createSphericalShape(posT1, uTime, radius);
    float dispT2 = createSphericalShape(posT2, uTime, radius);
    
    vec3 perturbedNormal = normalize(originalNormal + 
        tangent1 * (dispT1 - shapeDisplacement) * 30.0 + 
        tangent2 * (dispT2 - shapeDisplacement) * 30.0);
    
    vNormal = perturbedNormal;
    vWorldPos = displaced;
    
    // Calculate radial distance
    vRadialDist = length(displaced) / radius;
    
    // Calculate edge fade - ensure no black at meridian
    vec3 viewDir = normalize(cameraPosition - displaced);
    float edgeFactor = abs(dot(originalNormal, viewDir)); 
    // Minimum fade of 0.7 to prevent black strips
    vEdgeFade = max(0.7, smoothstep(0.1, 0.9, edgeFactor));
    
    // Reduced fade in deep folds to maintain visibility
    if (vFoldDepth < -0.15) {
        float foldFade = 1.0 + vFoldDepth * 1.5; // Reduced from 3.0
        vEdgeFade *= max(foldFade, 0.6); // Minimum 0.6 (was 0.2)
    }
    
    vDistortion = totalDisplacement;
    
    // === WORLD SPACE TRANSFORMATION ===
    // Transform to world space
    vec4 worldPos4 = modelMatrix * vec4(displaced, 1.0);
    vec3 worldPosition = worldPos4.xyz;
    vec3 worldNormal = normalize((modelMatrix * vec4(perturbedNormal, 0.0)).xyz);
    
    // === COLOR SYSTEM PROCESSING ===
    // Calculate eclipse colors using color system module
    vec3 color = calculateEclipseColor(worldPosition, worldNormal, perturbedNormal, cameraPosition, totalDisplacement);
    
    // Full intensity for brighter appearance (no shadow reduction)
    vIntensity = 1.0;
    
    // Both sides of sphere get full color treatment
    vColor = color;
    
    // === POINT SIZE CALCULATION ===
    // Screen position for point size calculation
    vec4 mvPosition = modelViewMatrix * vec4(displaced, 1.0);
    
    // Use geometry system for point size calculation
    gl_PointSize = calculatePointSize(6.0, vFoldDepth, aRandom, uCameraDistance, vEdgeFade);
    
    // === FINAL POSITION ===
    gl_Position = projectionMatrix * mvPosition;
}

// ========================================
// MODULE INTEGRATION NOTES
// ========================================
// 
// This modular approach separates concerns:
//
// 1. WAVE SYSTEM (waveSystem.glsl):
//    - createFoldingWaves(): Main wave animation logic
//    - createBendingWaves(): Secondary ripple effects  
//    - createAsymmetricDistortion(): Organic motion
//    - createSphericalShape(): Master shape function
//
// 2. COLOR SYSTEM (colorSystem.glsl):
//    - calculateEclipseColor(): Eclipse gradient calculation
//    - All color palette definitions and blending logic
//    - Corona effects and special band handling
//
// 3. GEOMETRY SYSTEM (geometrySystem.glsl):
//    - calculatePerturbedNormal(): Normal vector calculation
//    - calculatePointSize(): Dynamic point sizing
//    - calculateEdgeFade(): Edge fade effects
//    - processGeometry(): Main geometry pipeline
//
// 4. MAIN SHADER (this file):
//    - Coordinates all modules
//    - Handles uniforms and attributes
//    - Manages varying outputs
//    - Controls execution flow
//
// USAGE:
// To modify wave behavior: Edit waveSystem.glsl
// To modify colors: Edit colorSystem.glsl  
// To modify geometry: Edit geometrySystem.glsl
// To change coordination: Edit this main file
//
// ========================================