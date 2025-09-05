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
        this.ellipticalRatio = config.ellipticalRatio || 0.8; // Semi-minor axis ratio (0.8 = 80% of major axis)
        this.inclination = config.inclination || 0; // degrees
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
        
        // Apply rotation for sideways (left/right) tilting using Z-axis
        this.orbitGroup.rotation.z = inclinationRad;
    }
    
    
    /**
     * Create visual orbit path
     */
    createOrbitPath() {
        // Create an elliptical geometry for the orbit path
        const segments = 128;
        const positions = [];
        
        // Semi-major axis (a) and semi-minor axis (b)
        const a = this.radius; // Semi-major axis
        const b = this.radius * this.ellipticalRatio; // Semi-minor axis
        
        for (let i = 0; i <= segments; i++) {
            const angle = (i / segments) * Math.PI * 2;
            const x = Math.cos(angle) * a; // Major axis along X
            const z = Math.sin(angle) * b; // Minor axis along Z
            positions.push(x, 0, z); // Y is 0 in local space, displacement handled by group position
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
        // Ensure matrix is updated before using it
        this.orbitGroup.updateMatrixWorld(true);
        
        // Calculate elliptical position on the orbit
        const a = this.radius; // Semi-major axis
        const b = this.radius * this.ellipticalRatio; // Semi-minor axis
        
        const x = Math.cos(angle) * a; // Major axis along X
        const z = Math.sin(angle) * b; // Minor axis along Z
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