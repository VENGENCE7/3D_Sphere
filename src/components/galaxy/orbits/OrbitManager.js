import { Orbit } from './Orbit.js';

/**
 * OrbitManager Class
 * Manages all 4 orbital paths in the solar system
 */
export class OrbitManager {
  constructor() {
    // Global orbit styling
    this.orbitColor = 0x546074; // #546074
    this.orbitThickness = 2.0; // Line thickness
    this.orbitOpacity = 0.7; // Line opacity

    // Global orbit geometry
    this.orbitRadius = 11; // Same radius for all orbits
    this.orbitEllipticalRatio = 0.8; // Same elliptical ratio for all orbits

    // Orbital configurations with Z-axis inclination and Y-axis tilt
    this.orbitConfigs = [
      {
        index: 0,
        inclination: 8,   // Z-axis rotation (sideways)
        tiltY: 0,         // Y-axis rotation (horizontal)
        showPath: true,
      },
      {
        index: 1,
        inclination: -10, // Z-axis rotation (sideways)
        tiltY: 0,        // Y-axis rotation (horizontal)
        showPath: true,
      },
      {
        index: 2,
        inclination: -20, // Z-axis rotation (sideways)
        tiltY: 0,       // Y-axis rotation (horizontal)
        showPath: true,
      },
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
        radius: this.orbitRadius,
        ellipticalRatio: this.orbitEllipticalRatio,
        orbitColor: this.orbitColor,
        orbitThickness: this.orbitThickness,
        orbitOpacity: this.orbitOpacity,
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
    this.orbits.forEach((orbit) => {
      orbit.updateMatrix();
    });
  }

  /**
   * Update resolution for all orbits (required for Line2)
   * @param {number} width - Canvas width
   * @param {number} height - Canvas height
   */
  updateResolution(width, height) {
    this.orbits.forEach((orbit) => {
      orbit.updateResolution(width, height);
    });
  }

  /**
   * Clean up resources
   */
  dispose() {
    this.orbits.forEach((orbit) => {
      orbit.dispose();
    });
    this.orbits = [];
  }
}
