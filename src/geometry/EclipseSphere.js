import * as THREE from 'three';
import vertexShader from '../shaders/vertexShader.glsl?raw';
import fragmentShader from '../shaders/fragmentShader.glsl?raw';

export class EclipseSphere {
    constructor(radius = 1.5) {
        this.radius = radius;
        this.sphere = null;
        this.material = null;
        this.geometry = null;
        
        this.createGeometry();
        this.createMaterial();
        this.createSphere();
    }
    
    createEclipseSpherePositions(radius) {
        const points = [];
        const latLines = 180;
        const lonLines = 180; // Make equal for perfect sphere
        
        // Use proper spherical coordinate system for perfect sphere
        for (let lat = 0; lat <= latLines; lat++) {
            // Theta from 0 to PI (north pole to south pole)
            const theta = (lat / latLines) * Math.PI;
            const sinTheta = Math.sin(theta);
            const cosTheta = Math.cos(theta);
            
            for (let lon = 0; lon < lonLines; lon++) { // Changed to < instead of <= to avoid overlap
                // Phi from 0 to 2*PI (around the equator) - not including 2*PI to avoid overlap
                const phi = (lon / lonLines) * 2 * Math.PI;
                const sinPhi = Math.sin(phi);
                const cosPhi = Math.cos(phi);
                
                // Standard spherical to Cartesian conversion
                const x = radius * sinTheta * cosPhi;
                const y = radius * cosTheta;
                const z = radius * sinTheta * sinPhi;
                
                points.push(x, y, z);
            }
        }
        
        return new Float32Array(points);
    }
    
    createGeometry() {
        const positions = this.createEclipseSpherePositions(this.radius);
        
        this.geometry = new THREE.BufferGeometry();
        this.geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        
        const initialPositions = new Float32Array(positions);
        this.geometry.setAttribute('initialPosition', new THREE.BufferAttribute(initialPositions, 3));
        
        const randoms = new Float32Array(positions.length / 3);
        for (let i = 0; i < randoms.length; i++) {
            randoms[i] = Math.random();
        }
        this.geometry.setAttribute('aRandom', new THREE.BufferAttribute(randoms, 1));
    }
    
    createMaterial() {
        this.material = new THREE.ShaderMaterial({
            vertexShader,
            fragmentShader,
            uniforms: {
                uTime: { value: 0.0 }
            },
            transparent: true,
            depthTest: true,
            depthWrite: false,
            blending: THREE.AdditiveBlending
        });
    }
    
    createSphere() {
        this.sphere = new THREE.Points(this.geometry, this.material);
    }
    
    update(elapsedTime) {
        // Update time uniform for wave animation
        if (this.material) {
            this.material.uniforms.uTime.value = elapsedTime;
        }
    }
    
    getMesh() {
        return this.sphere;
    }
    
    dispose() {
        if (this.geometry) {
            this.geometry.dispose();
        }
        if (this.material) {
            this.material.dispose();
        }
    }
}