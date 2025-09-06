/**
 * Planet configurations for the solar system
 * 8 stationary planets across 3 orbits
 * Orbit 0: 3 planets at fixed positions
 * Orbit 1: 2 planets at fixed positions
 * Orbit 2: 3 planets at fixed positions
 */

// Global liquid movement settings for all planets (optimized for 60FPS)
export const globalLiquidMovement = {
  enabled: true,
  waveSpeed: 0.3, // Slower for smooth 60FPS
  waveAmplitude: 0.08, // Subtle deformation
  breathingSpeed: 0.25, // Gentle breathing
  breathingScale: 0.03, // Small scale changes
  noiseScale: 2.0, // Noise frequency
  flowSpeed: 0.15, // Organic flow speed
};

// Global transparency for all planets (0.0 = fully transparent, 1.0 = fully opaque)
export const globalTransparency = 0.7; // 85% transparency

// Global blobness for all planets (controls deformation amount)
export const globalBlobness = 0.3; // Default blob deformation

// Global color coverage from rim (0.1 = 10% colored rim, 0.9 = 90% colored)
export const globalColorCoverage = 0.65; // 65% of sphere is colored from rim

// Global shader controls for glow and effects
export const globalShaderControls = {
  rimGlowIntensity: 1.8, // Rim glow strength
  rimGlowWidth: 4.0, // Rim glow width (higher = tighter)
  auraIntensity: 1.5, // Aura glow strength
  auraWidth: 2.0, // Aura width (higher = tighter)
  specularIntensity: 0.8, // Specular highlight strength
  specularSharpness: 24.0, // Specular sharpness (higher = sharper)
  boundaryGlow: 0.8, // Glow at color/black boundary
  surfaceGlow: 0.4, // Glow from surface distortion
  shimmerIntensity: 0.1, // Shimmer animation strength
  overallBoost: 1.3, // Overall brightness multiplier
  blackTint: 0.003, // Color bleed into black areas
  breathingIntensity: 0.15, // Breathing effect strength (reduced for smoothness)
  pulseIntensity: 0.08, // Pulse effect strength (subtle for 60FPS)
};

export const planetsConfig = [
  {
    id: '1',
    orbitIndex: 1,
    angle: 320,
    text: '',
    seed: 42.7,
    color: {
      base: '#B9B9B9',
      glowIntensity: 0.7,
    },
    size: 0.8,
    textColor: '#FFFFFF',
    textSize: 1.6,
  },
  {
    id: '2',
    orbitIndex: 0,
    angle: (Math.PI * 2) / 4.75,
    text: 'Integration and\nAutomation',
    color: {
      base: '#00C77F',
      glowIntensity: 0.7,
    },
    size: 0.7,
    textColor: '#FFFFFF',
    textSize: 1.5,
  },
  {
    id: '3',
    orbitIndex: 1,
    angle: (Math.PI * 5) / 7,
    text: 'AI-Native Product\nDevelopment',
    color: {
      base: '#B9B9B9',
      glowIntensity: 0.7,
    },
    size: 0.75,
    textColor: '#FFFFFF',
    textSize: 2.5,
  },
  {
    id: '4',
    orbitIndex: 0,
    angle: Math.PI / 1.6,
    text: 'AI Solutions &\nWorkflow\nProductization',
    color: {
      base: '#5AC1CC',
      glowIntensity: 0.7,
    },
    size: 0.8,
    textColor: '#FFFFFF',
    textSize: 2.0,
  },
  {
    id: '5',
    orbitIndex: 2,
    angle: Math.PI,
    text: '',
    color: {
      base: '#00C77F',
      glowIntensity: 0.7,
    },
    size: 0.5,
    textColor: '#FFFFFF',
    textSize: 0,
  },
  {
    id: '6',
    orbitIndex: 2,
    angle: (Math.PI * 2) / 6,
    text: 'Business-facing\nCustom Solutions',
    color: {
      base: '#59C1CC',
      glowIntensity: 0.7,
    },
    size: 0.95,
    textColor: '#FFFFFF',
    textSize: 2.5,
  },
  {
    id: '7',
    orbitIndex: 1,
    angle: (Math.PI * 5) / 4.5,
    text: 'Data Intelligence\n& Architecture',
    color: {
      base: '#FFA100',
      glowIntensity: 0.6,
    },
    size: 1.5,
    textColor: '#FFFFFF',
    textSize: 2.5,
  },
  {
    id: '8',
    orbitIndex: 0,
    angle: Math.PI / 18,
    text: 'Product and AI\nStrategy Consulting',
    color: {
      base: '#FFFF77',
      glowIntensity: 0.7,
    },
    size: 1.25,
    textColor: '#FFFFFF',
    textSize: 2.0,
  },
];

/**
 * Get planets by orbit index
 * @param {number} orbitIndex - The orbit index (0-2)
 * @returns {Array} Array of planet configs for that orbit
 */
export function getPlanetsByOrbit(orbitIndex) {
  return planetsConfig.filter((planet) => planet.orbitIndex === orbitIndex);
}

/**
 * Get planet by ID
 * @param {string} planetId - The planet ID
 * @returns {Object|null} Planet configuration or null if not found
 */
export function getPlanetById(planetId) {
  return planetsConfig.find((planet) => planet.id === planetId) || null;
}
