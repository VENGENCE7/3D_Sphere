// ========================================
// SHADER LOADER UTILITY
// Loads and combines modular shader files
// ========================================

// Import all shader modules
import waveSystemGLSL from './waveSystem.glsl?raw';
import colorSystemGLSL from './colorSystem.glsl?raw';
import geometrySystemGLSL from './geometrySystem.glsl?raw';
import vertexShaderModularGLSL from './vertexShader-modular.glsl?raw';
import fragmentShaderGLSL from './fragmentShader.glsl?raw';

/**
 * Combines modular shader files by replacing #include directives
 * @param {string} mainShader - The main shader code with #include directives
 * @param {Object} modules - Object containing module names and their code
 * @returns {string} Combined shader code
 */
function combineShaders(mainShader, modules) {
    let combinedShader = mainShader;
    
    // Replace #include directives with actual module code
    Object.keys(modules).forEach(moduleName => {
        const includeDirective = `#include "${moduleName}"`;
        
        if (combinedShader.includes(includeDirective)) {
            // Add a comment header for the included module
            const moduleWithHeader = `
// === INCLUDED MODULE: ${moduleName} ===
${modules[moduleName]}
// === END OF MODULE: ${moduleName} ===
`;
            combinedShader = combinedShader.replace(includeDirective, moduleWithHeader);
        }
    });
    
    return combinedShader;
}

/**
 * Creates the complete vertex shader by combining all modules
 * @returns {string} Complete vertex shader code
 */
export function createVertexShader() {
    const modules = {
        'waveSystem.glsl': waveSystemGLSL,
        'colorSystem.glsl': colorSystemGLSL,
        'geometrySystem.glsl': geometrySystemGLSL
    };
    
    return combineShaders(vertexShaderModularGLSL, modules);
}

/**
 * Creates the complete fragment shader (no modules needed currently)
 * @returns {string} Complete fragment shader code
 */
export function createFragmentShader() {
    return fragmentShaderGLSL;
}

/**
 * Loads individual shader modules for direct access
 * @returns {Object} Object containing all shader modules
 */
export function getShaderModules() {
    return {
        waveSystem: waveSystemGLSL,
        colorSystem: colorSystemGLSL,
        geometrySystem: geometrySystemGLSL,
        vertexShaderModular: vertexShaderModularGLSL,
        fragmentShader: fragmentShaderGLSL
    };
}

/**
 * Configuration object for shader parameters
 * Allows easy adjustment of wave and visual parameters
 */
export const shaderConfig = {
    // Wave system parameters
    waveFrequency: 6.0,      // Ripple frequency (5.0 = fewer ripples, 20.0 = many ripples)
    waveSpeed: 0.25,         // Expansion speed (0.1 = slow, 0.5 = fast)
    waveThickness: 0.5,      // Ring thickness (0.2 = thin, 0.8 = thick)
    waveAmplitude: 0.8,      // Base wave height (0.1 = subtle, 0.5 = tall)
    waveMaxAmplitude: 2.2,   // Maximum height at clash (0.5 = low, 2.0 = very tall)
    waveForm: 1.0,           // Wave shape (0.5 = smooth, 1.0 = normal, 2.0 = sharp)
    
    // Geometry parameters
    sphereRadius: 1.5,       // Sphere radius
    pointBaseSize: 6.0,      // Base point size
    
    // Color system parameters
    coronaTopCoverage: 0.10,    // Corona coverage at top
    coronaBottomCoverage: 0.02, // Corona coverage at bottom
    warmGradientStart: 0.68,    // Where warm colors start
    
    // Camera parameters
    defaultCameraDistance: 3.5, // Default camera distance
};

/**
 * Updates shader with new configuration parameters
 * @param {THREE.ShaderMaterial} material - The shader material to update
 * @param {Object} newConfig - New configuration parameters
 */
export function updateShaderConfig(material, newConfig) {
    // Update the shader configuration
    Object.assign(shaderConfig, newConfig);
    
    // If the material has uniforms that correspond to config parameters,
    // update them here
    if (material && material.uniforms) {
        // Add uniform updates as needed
        // Example: material.uniforms.uWaveFrequency.value = shaderConfig.waveFrequency;
    }
}

// ========================================
// USAGE EXAMPLES
// ========================================
/*
// Basic usage in EclipseSphere.js:
import { createVertexShader, createFragmentShader } from '../shaders/shaderLoader.js';

const vertexShader = createVertexShader();
const fragmentShader = createFragmentShader();

// Advanced usage with configuration:
import { shaderConfig, updateShaderConfig } from '../shaders/shaderLoader.js';

// Modify wave parameters
updateShaderConfig(material, {
    waveSpeed: 0.5,
    waveAmplitude: 1.2
});

// Access individual modules:
import { getShaderModules } from '../shaders/shaderLoader.js';
const modules = getShaderModules();
console.log(modules.waveSystem); // Direct access to wave system code
*/