/**
 * Planet configurations for the solar system
 * 8 planets across 4 orbits (2 planets per orbit)
 * Each orbit has planets of the same color placed 180° apart
 */

export const planetsConfig = [
    // Orbit 1 - Gray planets (closest to sun)
    {
        id: 'planet1',
        orbitIndex: 0,
        angle: 0,
        text: 'Alpha',
        color: {
            base: '#B9B9B9',
            glowIntensity: 0.3
        },
        size: 0.4,
        blobness: 0.15,
        textColor: '#FFFFFF',
        textSize: 0.1,
        liquidMovement: {
            enabled: true,
            waveSpeed: 0.4,
            waveAmplitude: 0.12,
            breathingSpeed: 0.3,
            breathingScale: 0.04,
            noiseScale: 2.5,
            flowSpeed: 0.2
        },
        rotation: {
            speed: 0.005,
            axis: { x: 0, y: 1, z: 0.2 }
        }
    },
    {
        id: 'planet2',
        orbitIndex: 0,
        angle: Math.PI, // 180° opposite
        text: 'Beta',
        color: {
            base: '#B9B9B9',
            glowIntensity: 0.3
        },
        size: 0.42,
        blobness: 0.18,
        textColor: '#FFFFFF',
        textSize: 0.1,
        liquidMovement: {
            enabled: true,
            waveSpeed: 0.45,
            waveAmplitude: 0.14,
            breathingSpeed: 0.35,
            breathingScale: 0.05,
            noiseScale: 2.8,
            flowSpeed: 0.25
        },
        rotation: {
            speed: 0.004,
            axis: { x: 0.1, y: 1, z: 0 }
        }
    },
    
    // Orbit 2 - Cyan planets
    {
        id: 'planet3',
        orbitIndex: 1,
        angle: 0,
        text: 'Gamma',
        color: {
            base: '#00C5C5',
            glowIntensity: 0.4
        },
        size: 0.5,
        blobness: 0.2,
        textColor: '#FFFFFF',
        textSize: 0.12,
        liquidMovement: {
            enabled: true,
            waveSpeed: 0.5,
            waveAmplitude: 0.15,
            breathingSpeed: 0.4,
            breathingScale: 0.06,
            noiseScale: 3.0,
            flowSpeed: 0.3
        },
        rotation: {
            speed: 0.006,
            axis: { x: 0, y: 1, z: 0.3 }
        }
    },
    {
        id: 'planet4',
        orbitIndex: 1,
        angle: Math.PI,
        text: 'Delta',
        color: {
            base: '#00C5C5',
            glowIntensity: 0.35,
        },
        size: 0.48,
        blobness: 0.16,
        textColor: '#FFFFFF',
        textSize: 0.11,
        liquidMovement: {
            enabled: true,
            waveSpeed: 0.48,
            waveAmplitude: 0.13,
            breathingSpeed: 0.38,
            breathingScale: 0.055,
            noiseScale: 2.7,
            flowSpeed: 0.28
        },
        rotation: {
            speed: 0.0055,
            axis: { x: 0.2, y: 1, z: 0.1 }
        }
    },
    
    // Orbit 3 - Orange planets
    {
        id: 'planet5',
        orbitIndex: 2,
        angle: 0,
        text: 'Epsilon',
        color: {
            base: '#CE7F01',
            glowIntensity: 0.45
        },
        size: 0.55,
        blobness: 0.22,
        textColor: '#FFFFFF',
        textSize: 0.13,
        liquidMovement: {
            enabled: true,
            waveSpeed: 0.55,
            waveAmplitude: 0.18,
            breathingSpeed: 0.45,
            breathingScale: 0.07,
            noiseScale: 3.2,
            flowSpeed: 0.35
        },
        rotation: {
            speed: 0.007,
            axis: { x: 0.1, y: 1, z: 0.2 }
        }
    },
    {
        id: 'planet6',
        orbitIndex: 2,
        angle: Math.PI,
        text: 'Zeta',
        color: {
            base: '#CE7F01',
            glowIntensity: 0.4
        },
        size: 0.52,
        blobness: 0.19,
        textColor: '#FFFFFF',
        textSize: 0.12,
        liquidMovement: {
            enabled: true,
            waveSpeed: 0.52,
            waveAmplitude: 0.16,
            breathingSpeed: 0.42,
            breathingScale: 0.065,
            noiseScale: 2.9,
            flowSpeed: 0.32
        },
        rotation: {
            speed: 0.0065,
            axis: { x: 0, y: 1, z: 0.15 }
        }
    },
    
    // Orbit 4 - Green planets (farthest from sun)
    {
        id: 'planet7',
        orbitIndex: 3,
        angle: 0,
        text: 'Eta',
        color: {
            base: '#00C77F',
            glowIntensity: 0.5
        },
        size: 0.6,
        blobness: 0.25,
        textColor: '#FFFFFF',
        textSize: 0.14,
        liquidMovement: {
            enabled: true,
            waveSpeed: 0.6,
            waveAmplitude: 0.2,
            breathingSpeed: 0.5,
            breathingScale: 0.08,
            noiseScale: 3.5,
            flowSpeed: 0.4
        },
        rotation: {
            speed: 0.008,
            axis: { x: 0.15, y: 1, z: 0.25 }
        }
    },
    {
        id: 'planet8',
        orbitIndex: 3,
        angle: Math.PI,
        text: 'Theta',
        color: {
            base: '#00C77F',
            glowIntensity: 0.45
        },
        size: 0.58,
        blobness: 0.23,
        textColor: '#FFFFFF',
        textSize: 0.13,
        liquidMovement: {
            enabled: true,
            waveSpeed: 0.58,
            waveAmplitude: 0.19,
            breathingSpeed: 0.48,
            breathingScale: 0.075,
            noiseScale: 3.3,
            flowSpeed: 0.38
        },
        rotation: {
            speed: 0.0075,
            axis: { x: 0.05, y: 1, z: 0.3 }
        }
    }
];

/**
 * Get planets by orbit index
 * @param {number} orbitIndex - The orbit index (0-3)
 * @returns {Array} Array of planet configs for that orbit
 */
export function getPlanetsByOrbit(orbitIndex) {
    return planetsConfig.filter(planet => planet.orbitIndex === orbitIndex);
}

/**
 * Get planet by ID
 * @param {string} planetId - The planet ID
 * @returns {Object|null} Planet configuration or null if not found
 */
export function getPlanetById(planetId) {
    return planetsConfig.find(planet => planet.id === planetId) || null;
}