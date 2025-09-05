import { Orbit } from './Orbit.js';
import * as THREE from 'three';

/**
 * OrbitManager Class
 * Manages all 4 orbital paths in the solar system
 */
export class OrbitManager {
    constructor() {
        // Orbital configurations from GALAXY.md
        this.orbitConfigs = [
            {
                index: 0,
                radius: 5,              // Closest to sun
                speed: 0.003,           // Fastest
                inclination: 0,         // Flat on XZ plane
                showPath: true,
                orbitColor: 0x546074,   // #546074
                orbitThickness: 2.0,    // Adjust thickness as needed
                orbitOpacity: 0.4
            },
            {
                index: 1,
                radius: 8,              // Inner-middle
                speed: 0.002,           // Fast
                inclination: -162.171,  // Specific angle
                showPath: true,
                orbitColor: 0x546074,   // #546074
                orbitThickness: 2.0,
                orbitOpacity: 0.4
            },
            {
                index: 2,
                radius: 11,             // Outer-middle
                speed: 0.0015,          // Slow
                inclination: 14.37,     // Specific angle
                showPath: true,
                orbitColor: 0x546074,   // #546074
                orbitThickness: 2.0,
                orbitOpacity: 0.4
            },
            {
                index: 3,
                radius: 14,             // Farthest
                speed: 0.001,           // Slowest
                inclination: 45,        // 45 degree tilt
                showPath: true,
                orbitColor: 0x546074,   // #546074
                orbitThickness: 2.0,
                orbitOpacity: 0.4
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
        this.orbitConfigs.forEach((config, index) => {
            const orbit = new Orbit(config);
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
     * Clean up resources
     */
    dispose() {
        this.orbits.forEach(orbit => {
            orbit.dispose();
        });
        this.orbits = [];
    }
}