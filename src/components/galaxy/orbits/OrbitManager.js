import { Orbit } from './Orbit.js';

/**
 * OrbitManager Class
 * Manages all 4 orbital paths in the solar system
 */
export class OrbitManager {
    constructor() {
        // Global orbit styling
        this.orbitColor = 0x546074;        // #546074
        this.orbitThickness = 2.0;         // Line thickness
        this.orbitOpacity = 0.7;           // Line opacity
        
        // Orbital configurations from GALAXY.md
        this.orbitConfigs = [
            {
                index: 0,
                radius: 5,              // Closest to sun
                inclination: 0,         // Flat on XZ plane
                showPath: true
            },
            {
                index: 1,
                radius: 8,              // Inner-middle
                inclination: -162.171,  // Specific angle
                showPath: true
            },
            {
                index: 2,
                radius: 11,             // Outer-middle
                inclination: 14.37,     // Specific angle
                showPath: true
            },
            {
                index: 3,
                radius: 14,             // Farthest
                inclination: 45,        // 45 degree tilt
                showPath: true
            }
        ];
        
        // Array of orbit instances
        this.orbits = [];
        
        
        // Initialize all orbits
        this.init();
    }
    
    /**
     * Initialize all orbital paths
     */
    init() {
        this.orbitConfigs.forEach((config) => {
            const orbit = new Orbit({
                ...config,
                orbitColor: this.orbitColor,
                orbitThickness: this.orbitThickness,
                orbitOpacity: this.orbitOpacity
            });
            this.orbits.push(orbit);
        });
    }
    
    /**
     * Get orbit by index
     * @param {number} index - Orbit index (0-3)
     * @returns {Orbit} Orbit instance
     */
    getOrbit(index) {
        return this.orbits[index] || null;
    }
    
    /**
     * Get all orbits
     * @returns {Array} Array of Orbit instances
     */
    getAllOrbits() {
        return this.orbits;
    }
    
    /**
     * Update all orbit matrices
     */
    update() {
        this.orbits.forEach(orbit => {
            orbit.updateMatrix();
        });
    }
    
    /**
     * Update resolution for all orbits (required for Line2)
     * @param {number} width - Canvas width
     * @param {number} height - Canvas height
     */
    updateResolution(width, height) {
        this.orbits.forEach(orbit => {
            orbit.updateResolution(width, height);
        });
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        this.orbits.forEach(orbit => {
            orbit.dispose();
        });
        this.orbits = [];
    }
}