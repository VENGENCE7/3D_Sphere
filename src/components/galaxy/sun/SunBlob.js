import * as THREE from 'three';
import { EclipseSphere } from '../../blob/EclipseSphere.js';

/**
 * SunBlob Class
 * Uses the original Blob/Eclipse sphere as the Sun
 * Scales it properly to maintain visual quality at larger sizes
 */
export class SunBlob {
    constructor(targetRadius = 4.5) {
        this.targetRadius = targetRadius;
        
        // Create the blob at its optimal size
        const optimalRadius = 1.5; // Radius where EclipseSphere looks best
        this.eclipseSphere = new EclipseSphere(optimalRadius);
        
        // Get the mesh and scale it to target size
        const mesh = this.eclipseSphere.getMesh();
        if (mesh) {
            const scaleFactor = targetRadius / optimalRadius;
            mesh.scale.setScalar(scaleFactor);
            mesh.position.set(0, 0, 0);
            mesh.frustumCulled = false;
        }
    }
    
    /**
     * Update the sun animation
     * @param {number} elapsedTime - Time in seconds
     * @param {THREE.Camera} camera - Camera for distance calculations
     */
    update(elapsedTime, camera) {
        this.eclipseSphere.update(elapsedTime, camera);
    }
    
    /**
     * Get the Three.js mesh group
     * @returns {THREE.Group} The sun mesh group
     */
    getMesh() {
        return this.eclipseSphere.getMesh();
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        if (this.eclipseSphere) {
            this.eclipseSphere.dispose();
        }
    }
}