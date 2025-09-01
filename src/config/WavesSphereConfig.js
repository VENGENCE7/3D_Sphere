/**
 * WavesSphere Configuration Interface
 * Provides type definitions and validation for configuration options
 */

export const DEFAULT_CONFIG = {
    // === Container Settings ===
    width: null,                    // Auto-detect from container
    height: null,                   // Auto-detect from container
    
    // === Sphere Geometry ===
    radius: 1.5,                    // Sphere radius (0.5 - 5.0)
    pointCount: 28000,              // Approximate number of points (read-only)
    pointBaseSize: 6.0,             // Base point size (1.0 - 20.0)
    
    // === Wave System ===
    waveFrequency: 6.0,             // Ripple frequency within waves (1.0 - 20.0)
    waveSpeed: 0.25,                // Wave expansion speed (0.1 - 1.0)
    waveThickness: 0.5,             // Ring thickness (0.1 - 1.0)
    waveAmplitude: 0.8,             // Base wave height (0.1 - 2.0)
    waveMaxAmplitude: 2.2,          // Maximum height at clash (0.5 - 5.0)
    waveCycle: 4.0,                 // Wave repeat cycle in seconds (1.0 - 20.0)
    waveForm: 1.0,                  // Wave shape control (0.5 - 3.0)
    
    // === Visual Settings ===
    autoRotate: true,               // Enable auto-rotation
    autoRotateSpeed: 0.0008,        // Auto-rotation speed (0.0001 - 0.01)
    
    // === Camera Settings ===
    cameraDistance: 3.5,            // Default camera distance (1.0 - 20.0)
    minZoom: 2.0,                   // Minimum zoom distance (0.5 - 10.0)
    maxZoom: 15.0,                  // Maximum zoom distance (5.0 - 50.0)
    
    // === Controls ===
    enableControls: true,           // Enable mouse/touch controls
    damping: 0.1,                   // Rotation damping factor (0.01 - 0.5)
    
    // === Performance ===
    enableStats: false,             // Show performance statistics
    pixelRatio: null,               // Auto-detect device pixel ratio
    
    // === Advanced ===
    enableShadows: false,           // Enable shadow effects (experimental)
    enablePostProcessing: false,    // Enable post-processing effects (experimental)
    backgroundColor: 0x000000       // Background color (hex)
};

export const CONFIG_LIMITS = {
    radius: { min: 0.5, max: 5.0 },
    pointBaseSize: { min: 1.0, max: 20.0 },
    waveFrequency: { min: 1.0, max: 20.0 },
    waveSpeed: { min: 0.1, max: 1.0 },
    waveThickness: { min: 0.1, max: 1.0 },
    waveAmplitude: { min: 0.1, max: 2.0 },
    waveMaxAmplitude: { min: 0.5, max: 5.0 },
    waveCycle: { min: 1.0, max: 20.0 },
    waveForm: { min: 0.5, max: 3.0 },
    autoRotateSpeed: { min: 0.0001, max: 0.01 },
    cameraDistance: { min: 1.0, max: 20.0 },
    minZoom: { min: 0.5, max: 10.0 },
    maxZoom: { min: 5.0, max: 50.0 },
    damping: { min: 0.01, max: 0.5 }
};

export const PRESET_CONFIGS = {
    // Default configuration
    default: {
        ...DEFAULT_CONFIG
    },
    
    // Calm waves - slow and gentle
    calm: {
        ...DEFAULT_CONFIG,
        waveSpeed: 0.15,
        waveAmplitude: 0.4,
        waveMaxAmplitude: 1.0,
        waveCycle: 8.0,
        autoRotateSpeed: 0.0003
    },
    
    // Energetic waves - fast and dramatic
    energetic: {
        ...DEFAULT_CONFIG,
        waveSpeed: 0.4,
        waveAmplitude: 1.2,
        waveMaxAmplitude: 3.0,
        waveCycle: 2.0,
        waveFrequency: 8.0,
        autoRotateSpeed: 0.0015
    },
    
    // Large sphere - big and imposing
    large: {
        ...DEFAULT_CONFIG,
        radius: 2.0,
        cameraDistance: 5.0,
        pointBaseSize: 8.0,
        waveAmplitude: 1.0,
        waveMaxAmplitude: 2.5
    },
    
    // Small sphere - compact and detailed
    small: {
        ...DEFAULT_CONFIG,
        radius: 1.0,
        cameraDistance: 2.5,
        pointBaseSize: 4.0,
        waveAmplitude: 0.6,
        waveMaxAmplitude: 1.5
    },
    
    // Static sphere - no auto rotation
    static: {
        ...DEFAULT_CONFIG,
        autoRotate: false,
        waveSpeed: 0.2,
        waveCycle: 6.0
    },
    
    // Performance optimized - lower quality but faster
    performance: {
        ...DEFAULT_CONFIG,
        pointBaseSize: 4.0,
        waveFrequency: 4.0,
        pixelRatio: 1
    },
    
    // Quality optimized - higher quality but slower
    quality: {
        ...DEFAULT_CONFIG,
        pointBaseSize: 8.0,
        waveFrequency: 10.0,
        pixelRatio: 2
    }
};

/**
 * Validate and sanitize configuration object
 * @param {Object} config - Configuration to validate
 * @returns {Object} Validated and sanitized configuration
 */
export function validateConfig(config = {}) {
    const validatedConfig = { ...DEFAULT_CONFIG };
    
    Object.keys(config).forEach(key => {
        if (key in DEFAULT_CONFIG) {
            let value = config[key];
            
            // Apply limits if they exist
            if (key in CONFIG_LIMITS) {
                const limits = CONFIG_LIMITS[key];
                value = Math.max(limits.min, Math.min(limits.max, value));
            }
            
            // Type validation
            switch (typeof DEFAULT_CONFIG[key]) {
                case 'boolean':
                    value = Boolean(value);
                    break;
                case 'number':
                    value = Number(value);
                    if (isNaN(value)) value = DEFAULT_CONFIG[key];
                    break;
                case 'string':
                    value = String(value);
                    break;
            }
            
            validatedConfig[key] = value;
        } else {
            console.warn(`Unknown configuration option: ${key}`);
        }
    });
    
    // Post-validation logic
    if (validatedConfig.minZoom >= validatedConfig.maxZoom) {
        validatedConfig.maxZoom = validatedConfig.minZoom + 5.0;
        console.warn('maxZoom adjusted to be greater than minZoom');
    }
    
    if (!validatedConfig.width || !validatedConfig.height) {
        // These will be set by the container dimensions
        validatedConfig.width = null;
        validatedConfig.height = null;
    }
    
    if (!validatedConfig.pixelRatio) {
        validatedConfig.pixelRatio = Math.min(window.devicePixelRatio || 1, 2);
    }
    
    return validatedConfig;
}

/**
 * Get a preset configuration by name
 * @param {string} presetName - Name of the preset
 * @returns {Object} Preset configuration
 */
export function getPresetConfig(presetName) {
    if (presetName in PRESET_CONFIGS) {
        return { ...PRESET_CONFIGS[presetName] };
    } else {
        console.warn(`Unknown preset: ${presetName}. Using default.`);
        return { ...DEFAULT_CONFIG };
    }
}

/**
 * Merge multiple configuration objects with validation
 * @param {...Object} configs - Configuration objects to merge
 * @returns {Object} Merged and validated configuration
 */
export function mergeConfigs(...configs) {
    const merged = Object.assign({}, ...configs);
    return validateConfig(merged);
}

/**
 * Create configuration from URL parameters
 * @param {URLSearchParams|string} params - URL parameters
 * @returns {Object} Configuration object
 */
export function configFromParams(params) {
    if (typeof params === 'string') {
        params = new URLSearchParams(params);
    }
    
    const config = {};
    
    // Map URL parameter names to config keys
    const paramMap = {
        'sphere-radius': 'radius',
        'sphere-auto-rotate': 'autoRotate',
        'sphere-auto-rotate-speed': 'autoRotateSpeed',
        'sphere-camera-distance': 'cameraDistance',
        'sphere-wave-speed': 'waveSpeed',
        'sphere-wave-amplitude': 'waveAmplitude',
        'sphere-wave-frequency': 'waveFrequency',
        'sphere-preset': 'preset'
    };
    
    for (const [paramName, configKey] of Object.entries(paramMap)) {
        if (params.has(paramName)) {
            let value = params.get(paramName);
            
            // Handle special cases
            if (configKey === 'preset') {
                return getPresetConfig(value);
            }
            
            // Type conversion
            if (configKey in DEFAULT_CONFIG) {
                const defaultValue = DEFAULT_CONFIG[configKey];
                if (typeof defaultValue === 'boolean') {
                    value = value === 'true';
                } else if (typeof defaultValue === 'number') {
                    value = parseFloat(value);
                }
                
                config[configKey] = value;
            }
        }
    }
    
    return validateConfig(config);
}

/**
 * Configuration builder class for fluent interface
 */
export class ConfigBuilder {
    constructor(baseConfig = {}) {
        this.config = { ...DEFAULT_CONFIG, ...baseConfig };
    }
    
    // Sphere settings
    radius(value) {
        this.config.radius = value;
        return this;
    }
    
    pointSize(value) {
        this.config.pointBaseSize = value;
        return this;
    }
    
    // Wave settings
    waveSpeed(value) {
        this.config.waveSpeed = value;
        return this;
    }
    
    waveAmplitude(value) {
        this.config.waveAmplitude = value;
        return this;
    }
    
    waveFrequency(value) {
        this.config.waveFrequency = value;
        return this;
    }
    
    waveCycle(value) {
        this.config.waveCycle = value;
        return this;
    }
    
    // Camera settings
    cameraDistance(value) {
        this.config.cameraDistance = value;
        return this;
    }
    
    zoomRange(min, max) {
        this.config.minZoom = min;
        this.config.maxZoom = max;
        return this;
    }
    
    // Auto-rotation
    autoRotate(enabled = true, speed = null) {
        this.config.autoRotate = enabled;
        if (speed !== null) {
            this.config.autoRotateSpeed = speed;
        }
        return this;
    }
    
    // Controls
    enableControls(enabled = true) {
        this.config.enableControls = enabled;
        return this;
    }
    
    damping(value) {
        this.config.damping = value;
        return this;
    }
    
    // Performance
    pixelRatio(value) {
        this.config.pixelRatio = value;
        return this;
    }
    
    // Apply preset
    preset(name) {
        const presetConfig = getPresetConfig(name);
        this.config = { ...this.config, ...presetConfig };
        return this;
    }
    
    // Build final configuration
    build() {
        return validateConfig(this.config);
    }
}

/**
 * Create a new configuration builder
 * @param {Object} baseConfig - Base configuration to start with
 * @returns {ConfigBuilder} New configuration builder instance
 */
export function createConfig(baseConfig = {}) {
    return new ConfigBuilder(baseConfig);
}

// Export for TypeScript users
export const WavesSphereConfig = {
    DEFAULT_CONFIG,
    CONFIG_LIMITS,
    PRESET_CONFIGS,
    validateConfig,
    getPresetConfig,
    mergeConfigs,
    configFromParams,
    createConfig,
    ConfigBuilder
};

export default WavesSphereConfig;