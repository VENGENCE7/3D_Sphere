import * as THREE from 'three';
import { Line2 } from 'three/examples/jsm/lines/Line2.js';
import { LineMaterial } from 'three/examples/jsm/lines/LineMaterial.js';
import { LineGeometry } from 'three/examples/jsm/lines/LineGeometry.js';

/**
 * Orbit Class
 * Represents a single orbital path with rotation and position calculations
 */
export class Orbit {
    constructor(config) {
        // Orbital configuration
        this.radius = config.radius || 10;
        this.inclination = config.inclination || 0; // Degrees
        this.index = config.index || 0;
        
        // Orbit visual configuration
        this.orbitColor = config.orbitColor || 0x546074; // Default to #546074
        this.orbitThickness = config.orbitThickness || 1.0; // Line thickness
        this.orbitOpacity = config.orbitOpacity || 0.3; // Line opacity
        
        // Orbital group for rotation
        this.orbitGroup = new THREE.Group();
        
        
        // Visual orbit path (optional)
        this.orbitPath = null;
        this.showPath = config.showPath !== false;
        
        // Initialize orbit
        this.init();
    }
    
    /**
     * Initialize the orbit
     */
    init() {
        this.setupInclination();
        if (this.showPath) {
            this.createOrbitPath();
        }
    }
    
    /**
     * Setup orbital inclination
     */
    setupInclination() {
        // Convert inclination from degrees to radians
        const inclinationRad = THREE.MathUtils.degToRad(this.inclination);
        
        // Apply rotation to achieve the specified inclination
        // Using different axes for variety in orbital planes
        if (this.index === 0) {
            // First orbit - flat on XZ plane
            this.orbitGroup.rotation.x = 0;
        } else if (this.index === 1) {
            // Second orbit - rotated around Z axis
            this.orbitGroup.rotation.z = inclinationRad;
        } else if (this.index === 2) {
            // Third orbit - rotated around X axis
            this.orbitGroup.rotation.x = inclinationRad;
        } else {
            // Fourth orbit - combination rotation
            this.orbitGroup.rotation.x = inclinationRad * 0.7;
            this.orbitGroup.rotation.z = inclinationRad * 0.3;
        }
    }
    
    
    /**
     * Create visual orbit path
     */
    createOrbitPath() {
        // Create a circle geometry for the orbit path
        const segments = 128;
        const positions = [];
        
        for (let i = 0; i <= segments; i++) {
            const angle = (i / segments) * Math.PI * 2;
            const x = Math.cos(angle) * this.radius;
            const z = Math.sin(angle) * this.radius;
            positions.push(x, 0, z);
        }
        
        // Use Line2 geometry for thick lines
        const geometry = new LineGeometry();
        geometry.setPositions(positions);
        
        // Use LineMaterial for proper thickness support
        const material = new LineMaterial({
            color: this.orbitColor,
            opacity: this.orbitOpacity,
            transparent: true,
            linewidth: this.orbitThickness, // This works with LineMaterial
            worldUnits: false // Use screen units for consistent thickness
        });
        
        this.orbitPath = new Line2(geometry, material);
        this.orbitGroup.add(this.orbitPath);
    }
    
    
    /**
     * Update orbit group matrix
     */
    updateMatrix() {
        this.orbitGroup.updateMatrixWorld();
    }
    
    /**
     * Update material resolution for Line2
     * @param {number} width - Canvas width
     * @param {number} height - Canvas height
     */
    updateResolution(width, height) {
        if (this.orbitPath && this.orbitPath.material && this.orbitPath.material.resolution) {
            this.orbitPath.material.resolution.set(width, height);
        }
    }
    
    /**
     * Get position at a specific angle on the orbit
     * @param {number} angle - Angle in radians
     * @returns {THREE.Vector3} Position on orbit
     */
    getPositionAtAngle(angle) {
        // Calculate position on the orbit
        const x = Math.cos(angle) * this.radius;
        const z = Math.sin(angle) * this.radius;
        const localPosition = new THREE.Vector3(x, 0, z);
        
        // Transform to world position considering inclination
        const worldPosition = localPosition.clone();
        worldPosition.applyMatrix4(this.orbitGroup.matrixWorld);
        
        return worldPosition;
    }
    
    /**
     * Get the orbit line for visual display
     * @returns {THREE.Line|null} Orbit path line
     */
    getOrbitLine() {
        return this.orbitPath;
    }
    
    /**
     * Get the orbit group for adding to scene
     * @returns {THREE.Group} Orbit group
     */
    getGroup() {
        return this.orbitGroup;
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        if (this.orbitPath) {
            this.orbitPath.geometry.dispose();
            this.orbitPath.material.dispose();
        }
    }
}